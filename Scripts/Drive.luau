--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

-- Dependencies
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer :: Player
local mouse = player:GetMouse()

local car = script.Parent.Car.Value
local values = script.Parent.Values

local _Tune = require(car["A-Chassis Tune"])
local Units = require(car["A-Chassis Tune"].README.Units)
local VirtualInput = script:FindFirstChild("VirtualInput")

if _Tune.Mobile then
	player.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	GuiService.TouchControlsEnabled = false
end

local MobileMode = "Tap"
local MobileModes = {"Tap", "Tilt"}
local MobileUI = script.Parent.Mobile
local MobileUIChildren = MobileUI:GetChildren()
local LastInputWasMobile = UserInputService:GetLastInputType() == Enum.UserInputType.Touch

local LastInputWasGamepad = string.find(UserInputService:GetLastInputType().Name, "Gamepad") and true or false
local ChatInputBarConfiguration = TextChatService.ChatInputBarConfiguration

local GlobalTemperature = workspace:GetAttribute("GlobalTemperature") or 22

-- Value Instance Caching
local Value = {
	Clutch = values.Clutch,
	Gear = values.Gear,
	TransmissionMode = values.TransmissionMode,
	CurrentRatio = values.CurrentRatio,
	RPM = values.RPM,
	Boost = values.Boost,
	BoostTurbo = values.BoostTurbo,
	BoostSuper = values.BoostSuper,
	HpNatural = values.HpNatural,
	HpElectric = values.HpElectric,
	HpTurbo = values.HpTurbo,
	HpSuper = values.HpSuper,
	HpBoosted = values.HpBoosted,
	Horsepower = values.Horsepower,
	TqNatural = values.TqNatural,
	TqElectric = values.TqElectric,
	TqTurbo = values.TqTurbo,
	TqSuper = values.TqSuper,
	TqBoosted = values.TqBoosted,
	Torque = values.Torque,
	Throttle = values.Throttle,
	InputThrottle = values.InputThrottle,
	Brake = values.Brake,
	InputBrake = values.InputBrake,
	SteerC = values.SteerC,
	SteerT = values.SteerT,
	PBrake = values.PBrake,
	Velocity = values.Velocity,
	AverageRotSpeed = values.AverageRotSpeed,
	Acceleration = values.Acceleration,
	Center = values.Center,
	TCS = values.TCS,
	TCSActive = values.TCSActive,
	TCSAmt = values.TCSAmt,
	ABS = values.ABS,
	ABSActive = values.ABSActive,
	ABSAmt = values.ABSAmt,
	ESC = values.ESC,
	ESCActive = values.ESCActive,
	ESCAmt = values.ESCAmt,
	CS = values.CS,
	CSActive = values.CSActive,
	CSAmt = values.CSAmt,
}

local TCSTrackerFolder = values.TCSTracker
local ABSTrackerFolder = values.ABSTracker
local ESCTrackerFolder = values.ESCTracker
local WheelSpeedsFolder = values.WheelSpeeds

-- Status Vars
local _IsOn = _Tune.AutoStart and (_Tune.Engine or _Tune.Electric)
local IsOnValue = script.Parent.IsOn
IsOnValue.Value = _IsOn
IsOnValue.Changed:Connect(function(value)
	_IsOn = value
end)

local _Starting = false
local StartingValue = IsOnValue.Starting
StartingValue.Value = _Starting
StartingValue.Changed:Connect(function(value)
	_Starting = value
end)

local _InControls = false
local ControlsOpenValue = script.Parent.ControlsOpen
ControlsOpenValue.Value = _InControls
ControlsOpenValue.Changed:Connect(function(value)
	_InControls = value
end)

local _AutoClutch = true
local AutoClutchValue = values.AutoClutch
AutoClutchValue.Value = _AutoClutch
AutoClutchValue.Changed:Connect(function(value)
	_AutoClutch = value
end)

local _MSteer = false
local MouseSteerValue = values.MouseSteerOn
MouseSteerValue.Value = _MSteer
MouseSteerValue.Changed:Connect(function(value)
	_MSteer = value
end)

-- Status Vars
local ParkingGearEnabled = _Tune.Ratios[1] == 0
local ParkingGearOffset = ParkingGearEnabled and 1 or 0

local _GSteerT = 0
local _GSteerC = 0

local _GThrot = 0
local _InThrot = 0
local _IThrot = 0
local _GBrake = 0
local _InBrake = 0
local _IBrake = 0

local _GClutch = 0
local _ClPressing = false
local _PlayerClutch = false
local _Clutch = 0
local _ClutchKick = 0
local _ClutchModulate = 0

local _RPM = _Tune.AutoStart and _Tune.IgnitionRPM or 0
local _OutTorque = 0
local _CGear = ParkingGearOffset == 1 and -2 or 0
local _ShiftUp = false
local _ShiftDn = false
local _Shifting = false
local _spLimit = 0

local engine = car["A-Chassis Tune"].README:FindFirstChild("CustomEngine") and require(car["A-Chassis Tune"].README:FindFirstChild("CustomEngine")) or nil

local _Boost = 0
local _TBoost = 0
local _SBoost = 0

local _HP = 0
local _TQ = 0
local _NH = 0
local _NT = 0
local _EH = 0
local _ET = 0
local _TH = 0
local _TT = 0
local _SH = 0
local _ST = 0
local _BH = 0
local _BT = 0

local _CurrentRatio = _Tune.Ratios[_CGear + 2 + ParkingGearOffset]
local _CVTRatio = 0
local _FlywheelEnergy = 0

local _TMode = _Tune.TransModes[1]
local _RevLimiting = false

local _SteerL = false
local _SteerR = false
local _PBrake = car["A-Chassis Tune"]["A-Chassis Interface"].Values.PBrake.Value

local _TCSTracker = {}
local _TCS = _Tune.TCSEnabled
local _TCSActive = false
local _TCSAmt = 0

local _ABSTracker = {}
local _ABS = _Tune.ABSEnabled
local _ABSActive = false
local _ABSAmt = 0

local _ESCTracker = {}
local _ESC = _Tune.ESCEnabled and _Tune.TCSEnabled
local _ESCActive = false
local _ESCAmt = 0

local _CS = _Tune.CSEnabled
local _CSActive = false
local _CSAmt = 0

local _FlipWait = tick()
local _FlipDB = false

local _WheelSpeedsTable = {}
local _WheelSpeeds = {}

local _AvgWheelSpeed = 0
local _DriveWheelSpeed = 0
local _MaxWheelSpin = 0

local _OldVelocity = Vector3.new()
local _Acceleration = Vector3.new()
local _Velocity = Vector3.new()
local _Center = CFrame.new()

local _InitialAutoShiftVers = _Tune.AutoShiftVers

local weightBrick = car.Body["#Weight"] :: Part
local driveSeat = car.DriveSeat :: VehicleSeat

-- Initialize Client
local FWheelCount = 0
local RWheelCount = 0

local wDia = 0
local wDRatio = 0

local Wheels = {}
local Drive = {}

for _, v in car.Wheels:GetChildren() :: { BasePart } do
	local name = v.Name
	if not v:IsA("BasePart") or not (name == "FL" or name == "FR" or name == "F" or name == "RL" or name == "RR" or name == "R") then 
		continue 
	end

	local size = v.Size
	local base = v:FindFirstChild("Base")
	local arm = v:FindFirstChild("Arm")

	local steer = arm and arm:FindFirstChild("Steer") or nil
	local steerAttach0 = _Tune.PowerSteeringType == "New" and steer and steer.Attachment0 or nil

	local av = v:FindFirstChild("#AV")
	local bv = v:FindFirstChild("#BV")

	FWheelCount += string.find(name, "F") and 1 or 0
	RWheelCount += (not string.find(name, "F")) and 1 or 0

	local isFront = string.find(name, "F") ~= nil
	local driven = ((_Tune.Config == "FWD" or _Tune.Config == "AWD") and isFront) or ((_Tune.Config == "RWD" or _Tune.Config == "AWD") and not isFront)

	local canSteer = 0
	if arm and steer then
		canSteer = v:GetAttribute("SteerDisabled") and 1 or 2
	end

	local WheelSpeedValue = Instance.new("NumberValue", WheelSpeedsFolder)
	WheelSpeedValue.Name = name
	local TCSTrackerValue = Instance.new("NumberValue", TCSTrackerFolder)
	TCSTrackerValue.Name = name
	local ABSTrackerValue = Instance.new("NumberValue", ABSTrackerFolder)
	ABSTrackerValue.Name = name
	local ESCTrackerValue = Instance.new("NumberValue", ESCTrackerFolder)
	ESCTrackerValue.Name = name

	local data = {}
	data.Name = name
	data.OppositeWheel = (name == "FL" and car.Wheels:FindFirstChild("FR")) or (name == "FR" and car.Wheels:FindFirstChild("FL")) or (name == "RL" and car.Wheels:FindFirstChild("RR")) or (name == "RR" and car.Wheels:FindFirstChild("RL"))
	data.Size = size
	data.Base = base
	data.Arm = arm
	data.Steer = steer
	data.SteerAttach0 = steerAttach0
	data.AV = av
	data.BV = bv
	data.isFront = isFront
	data.driven = driven
	data.WheelSpeedValue = WheelSpeedValue
	data.TCSTrackerValue = TCSTrackerValue
	data.ABSTrackerValue = ABSTrackerValue
	data.ESCTrackerValue = ESCTrackerValue
	data.RotVelocityMagnitude = 0
	data.WheelVelocityMagnitude = 0
	data.CanSteer = canSteer

	if driven then
		table.insert(Drive, v)
	end

	v:GetPropertyChangedSignal("Size"):Connect(function()
		Wheels[v].Size = v.Size

		local size = 0
		for name, data in Wheels do 
			size = math.max(size, data.Size.Y)
			wDia = size
		end

		wDRatio = wDia * math.pi / 60
	end)

	v:GetAttributeChangedSignal("SteerDisabled"):Connect(function()
		data.CanSteer = v:GetAttribute("SteerDisabled") and 1 or 2
	end)

	Wheels[v] = data
end

for name, data in Wheels do 
	wDia = math.max(wDia, data.Size.Y)
	wDRatio = wDia * math.pi / 60
end

-- Shutdown
driveSeat.ChildRemoved:Connect(function(child: Instance) 
	if child.Name=="SeatWeld" and child:IsA("Weld") then
		if _Tune.Mobile and LastInputWasMobile then
			_Tune.AutoShiftVers = _InitialAutoShiftVers
		end

		-- Remove Flip Force
		if driveSeat:FindFirstChild("Flip") then
			if _Tune.FlipType == "New" then
				driveSeat.Flip.Enabled = false
			else
				driveSeat.Flip.MaxTorque = Vector3.new()
			end
		end

		-- Save PBrake state
		car["A-Chassis Tune"]["A-Chassis Interface"].Values.PBrake.Value = _PBrake

		-- Remove Wheel Force
		for _, data in Wheels do
			if data.AV then
				data.AV.MotorMaxTorque = 0
				data.AV.AngularVelocity = 0
			end
			if data.BV then
				if ParkingGearEnabled then
					_CGear = -2
				else
					_PBrake = true
				end

				if data.isFront then
					local PBrakeForceF = _Tune.PBrakeForce * 9.80665 * Units.Force_N * _Tune.PBrakeBias
					data.BV.MotorMaxTorque = _Tune.ExitBrake and PBrakeForceF or 0
				else
					local PBrakeForceR = _Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.PBrakeBias)
					data.BV.MotorMaxTorque = _Tune.ExitBrake and PBrakeForceR or 0
				end
			end
		end

		-- Reintroduce touch controls
		if _Tune.Mobile then
			GuiService.TouchControlsEnabled = true
		end

		-- Tell server to remove
		car["A-Chassis Tune"].Shutdown:FireServer()
	end
end)

-- Controls
local Controls = script.Parent:FindFirstChild("Controls") :: Folder
if not Controls then
	Controls = Instance.new("Folder")
	Controls.Name = "Controls"
	Controls.Parent = script.Parent
end

local _CTRL = _Tune.Controls
for i, v in _CTRL do
	local a = Instance.new("StringValue")
	a.Name = i
	a.Value = v.Name
	a.Changed:Connect(function(value: string)
		if i == "MouseThrottle" or i == "MouseBrake" then
			if value == "MouseButton1" or value == "MouseButton2" then
				_CTRL[i] = Enum.UserInputType[value]
			else
				_CTRL[i] = Enum.KeyCode[value]
			end
		else
			_CTRL[i] = Enum.KeyCode[value]
		end
	end)
	a.Parent = Controls
end

-- Deadzone Adjust
local _PPH = _Tune.Peripherals
for i, v in _PPH do
	local a = Instance.new("IntValue")
	a.Name = i
	a.Value = v
	a.Changed:Connect(function(value: number) 
		a.Value = math.min(100, math.max(0, value))
		_PPH[i] = value
	end)
	a.Parent = Controls
end

-- Input Handler
local function DealWithInput(input: InputObject, gameProcessed: boolean)
	if not ChatInputBarConfiguration.IsFocused and not UserInputService:GetFocusedTextBox() and not _InControls then
		-- Shift Down [Manual Transmission]
		if (input.KeyCode ==_CTRL["ContlrShiftDown"] or (_MSteer and input.KeyCode==_CTRL["MouseShiftDown"]) or ((not _MSteer) and input.KeyCode==_CTRL["ShiftDown"])) and ((_IsOn and ((_TMode=="Auto" and _CGear<=1) and _Tune.AutoShiftVers == "New") or _TMode=="Semi") or _TMode=="Manual") and input.UserInputState == Enum.UserInputState.Begin then
			if not _ShiftDn then _ShiftDn = true end

			-- Shift Up [Manual Transmission]
		elseif (input.KeyCode ==_CTRL["ContlrShiftUp"] or (_MSteer and input.KeyCode==_CTRL["MouseShiftUp"]) or ((not _MSteer) and input.KeyCode==_CTRL["ShiftUp"])) and ((_IsOn and ((_TMode=="Auto" and _CGear<1) and _Tune.AutoShiftVers == "New") or _TMode=="Semi") or _TMode=="Manual") and input.UserInputState == Enum.UserInputState.Begin then
			if not _ShiftUp then _ShiftUp = true end

			-- Toggle Clutch
		elseif (input.KeyCode ==_CTRL["ContlrClutch"] or (_MSteer and input.KeyCode==_CTRL["MouseClutch"]) or ((not _MSteer) and input.KeyCode==_CTRL["Clutch"])) and _TMode=="Manual" then
			if input.UserInputState == Enum.UserInputState.Begin then
				_ClPressing = true
				_PlayerClutch = true
			elseif input.UserInputState == Enum.UserInputState.End then
				_ClPressing = false
				_PlayerClutch = false
			end

			-- Toggle PBrake
		elseif input.KeyCode ==_CTRL["ContlrPBrake"] or (_MSteer and input.KeyCode==_CTRL["MousePBrake"]) or ((not _MSteer) and input.KeyCode==_CTRL["PBrake"]) or ((not _MSteer) and input.KeyCode==_CTRL["PBrake2"]) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_PBrake = not _PBrake
			elseif input.UserInputState == Enum.UserInputState.End then
				if _Velocity.Magnitude>5 then _PBrake = false end
			end

			-- Toggle Transmission Mode
		elseif (input.KeyCode == _CTRL["ContlrToggleTMode"] or input.KeyCode==_CTRL["ToggleTransMode"]) and input.UserInputState == Enum.UserInputState.Begin then
			local n=1
			for i,v in _Tune.TransModes do
				if v==_TMode then n=i break end
			end
			n=n+1
			if n>#_Tune.TransModes then n=1 end
			_TMode = _Tune.TransModes[n]

			-- Throttle
		elseif ((not _MSteer) and (input.KeyCode==_CTRL["Throttle"] or input.KeyCode == _CTRL["Throttle2"])) or ((((_CTRL["MouseThrottle"]==Enum.UserInputType.MouseButton1 or _CTRL["MouseThrottle"]==Enum.UserInputType.MouseButton2) and input.UserInputType == _CTRL["MouseThrottle"]) or input.KeyCode == _CTRL["MouseThrottle"])and _MSteer) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IThrot = 1
			else
				_IThrot = 0
			end

			-- Brake
		elseif ((not _MSteer) and (input.KeyCode==_CTRL["Brake"] or input.KeyCode == _CTRL["Brake2"])) or ((((_CTRL["MouseBrake"]==Enum.UserInputType.MouseButton1 or _CTRL["MouseBrake"]==Enum.UserInputType.MouseButton2) and input.UserInputType == _CTRL["MouseBrake"]) or input.KeyCode == _CTRL["MouseBrake"])and _MSteer) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IBrake = 1
			else
				_IBrake = 0
			end

			-- Steer Left
		elseif (not _MSteer) and (input.KeyCode==_CTRL["SteerLeft"] or input.KeyCode == _CTRL["SteerLeft2"]) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_GSteerT = -1
				_SteerL = true
			else
				if _SteerR then
					_GSteerT = 1
				else
					_GSteerT = 0
				end
				_SteerL = false
			end

			-- Steer Right
		elseif (not _MSteer) and (input.KeyCode==_CTRL["SteerRight"] or input.KeyCode == _CTRL["SteerRight2"]) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_GSteerT = 1
				_SteerR = true
			else
				if _SteerL then
					_GSteerT = -1
				else
					_GSteerT = 0
				end
				_SteerR = false
			end

			-- Toggle Mouse Controls
		elseif input.KeyCode ==_CTRL["ToggleMouseDrive"] then
			if input.UserInputState == Enum.UserInputState.End then
				_MSteer = not _MSteer
				_IThrot = 0
				_IBrake = 0
				_GSteerT = 0
			end

			-- Toggle TCS and ESC
		elseif _Tune.TCSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleTCS"] or input.KeyCode == _CTRL["ContlrToggleTCS"]) then
			if input.UserInputState == Enum.UserInputState.End then 
				if _Tune.ESCEnabled then
					if _TCS and _ESC then
						_ESC = false
					elseif _TCS and not _ESC then
						_TCS = false
					elseif not _TCS and not _ESC then
						_TCS = true
						_ESC = true
					end
				else
					_TCS = not _TCS
				end
			end

			-- Toggle ABS
		elseif _Tune.ABSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleABS"] or input.KeyCode == _CTRL["ContlrToggleABS"]) then
			if input.UserInputState == Enum.UserInputState.End then _ABS = not _ABS end

			-- Toggle CS
		elseif _Tune.CSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleCS"] or input.KeyCode == _CTRL["ContlrToggleCS"]) then
			if input.UserInputState == Enum.UserInputState.End then _CS = not _CS end

		end

		-- Variable Controls
		if input.UserInputType and input.UserInputType.Name:find("Gamepad") then
			-- Gamepad Steering
			if input.KeyCode == _CTRL["ContlrSteer"] then
				if input.Position.X >= 0 then
					local cDZone = math.min(0.99, _Tune.Peripherals.ControlRDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						_GSteerT = (input.Position.X - cDZone) / (1 - cDZone)
					else
						_GSteerT = 0
					end
				else
					local cDZone = math.min(0.99, _Tune.Peripherals.ControlLDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						_GSteerT = (input.Position.X + cDZone) / (1 - cDZone)
					else
						_GSteerT = 0
					end
				end
				
				-- Gamepad Throttle
			elseif input.KeyCode == _CTRL["ContlrThrottle"] then
				_IThrot = math.max(0,input.Position.Z)

				-- Gamepad Brake
			elseif input.KeyCode == _CTRL["ContlrBrake"] then
				_IBrake = input.Position.Z
			end
		end
	else
		_IThrot = 0
		_GSteerT = 0
		_IBrake = 0
	end
end

UserInputService.InputBegan:Connect(DealWithInput)
UserInputService.InputChanged:Connect(DealWithInput)
UserInputService.InputEnded:Connect(DealWithInput)
VirtualInput.Event:Connect(DealWithInput)

local function DealWithMobileInput()
	local mobile = script.Parent.Mobile

	mobile.Jump.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		player.Character:FindFirstChildWhichIsA("Humanoid").Jump = true
	end)

	mobile.ModeSwitch.MouseButton1Click:Connect(function()
		MobileMode = MobileModes[(table.find(MobileModes, MobileMode) or 0) + 1]
		if not MobileMode then
			MobileMode = MobileModes[1]
		end
	end)

	-- Tap
	for _, button in mobile.Tap:GetChildren() do
		if not button:IsA("ImageButton") then continue end
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			button.ImageColor3 = Color3.fromRGB(178,178,178)
			button.ImageLabel.ImageColor3 = Color3.new(0,0,0)
			button.ImageLabel.ImageTransparency = .5
			if button.Name == "Throttle" then
				_IThrot = 1
			elseif button.Name == "Brake" then
				_IBrake = 1
			elseif button.Name == "Left" then
				_GSteerT = -1
				_SteerL = true
			elseif button.Name == "Right" then
				_GSteerT = 1
				_SteerR = true
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			button.ImageColor3 = Color3.new(0, 0, 0)
			button.ImageLabel.ImageColor3 = Color3.new(1,1,1)
			button.ImageLabel.ImageTransparency = .8
			if button.Name == "Throttle" then
				_IThrot = 0
			elseif button.Name == "Brake" then
				_IBrake = 0
			elseif button.Name == "Left" then
				if _SteerR then
					_GSteerT = 1
				else
					_GSteerT = 0
				end
				_SteerL = false
			elseif button.Name == "Right" then
				if _SteerL then
					_GSteerT = -1
				else
					_GSteerT = 0
				end
				_SteerR = false
			end
		end)
	end

	-- Tilt
	for _, button in mobile.Tilt:GetChildren() do
		if not button:IsA("TextButton") then continue end
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			if button.Name == "Throttle" then
				_IThrot = 1
			elseif button.Name == "Brake" then
				_IBrake = 1
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end
			if button.Name == "Throttle" then
				_IThrot = 0
			elseif button.Name == "Brake" then
				_IBrake = 0
			end
		end)
	end
	if UserInputService.GyroscopeEnabled then
		UserInputService.DeviceRotationChanged:Connect(function(rotation, cframe)
			if MobileMode == "Tilt" then
				_GSteerT = -math.clamp(rotation.Position.Z*2, -1, 1)
			end
		end)
	end
end

if _Tune.Mobile then
	DealWithMobileInput()
end

-- Throttle and Brake Input Smoothing
local function Inputs(dt: number)
	local deltaTime = dt * 60
	if _InThrot <= _IThrot then
		_InThrot = math.min(_IThrot,_InThrot+(_Tune.ThrotAccel*deltaTime))
	else
		_InThrot = math.max(_IThrot,_InThrot-(_Tune.ThrotDecel*deltaTime))
	end
	if _InBrake <= _IBrake then
		_InBrake = math.min(_IBrake,_InBrake+(_Tune.BrakeAccel*deltaTime))
	else
		_InBrake = math.max(_IBrake,_InBrake-(_Tune.BrakeDecel*deltaTime))
	end
end

-- Steering
local function Steering(dt: number)
	local deltaTime = dt * 60

	local SteerOuter = _Tune.SteerOuter
	local SteerInner = _Tune.SteerInner
	if _Tune.SteeringType == "Auto" or _Tune.SteeringType == nil then
		SteerOuter = (_Tune.LockToLock * 180) / _Tune.SteerRatio
		SteerInner = math.min(SteerOuter - (SteerOuter * (1 - _Tune.Ackerman)), SteerOuter * 1.2)
	end

	local controller = LastInputWasGamepad or (_Tune.MSteerUsesContlr and _MSteer or false)
	local SteerSpeed = controller and (_Tune.ContlrSteerSpeed>0 and _Tune.ContlrSteerSpeed or _Tune.Steerspeed) or _Tune.SteerSpeed * (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/_Tune.SteerSpeedDecay,1-(_Tune.MinSteerSpeed/100)))
	local ReturnSpeed = controller and (_Tune.ContlrReturnSpeed>0 and _Tune.ContlrReturnSpeed or _Tune.ReturnSpeed) or _Tune.ReturnSpeed * (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/_Tune.SteerSpeedDecay,1-(_Tune.MinSteerSpeed/100)))

	if _MSteer then
		local msWidth = math.max(1,mouse.ViewSizeX*_Tune.Peripherals.MSteerWidth/200)
		local mdZone = _Tune.Peripherals.MSteerDZone/100
		local mST = ((mouse.X-mouse.ViewSizeX/2)/msWidth)
		if math.abs(mST)<=mdZone then
			_GSteerT = 0
		else
			_GSteerT = (math.max(math.min((math.abs(mST)-mdZone),(1-mdZone)),0)/(1-mdZone))^_Tune.MSteerExp * (mST / math.abs(mST))
		end
	end

	-- Interpolate Steering
	if math.abs(_GSteerT) < _Tune.CSSteerThresh/100 and _CS and _Velocity.Magnitude * (Units.Length_mm/1000) * 3.6 > _Tune.CSSpeedThresh then
		_CSAmt = (_Center:VectorToObjectSpace(_Velocity):Dot(Vector3.new(1, 0, 0))/math.max(_Velocity.Magnitude * (Units.Length_mm/1000) * 3.6, _Tune.CSSpeedThresh)) * (_Tune.CSAmt/100)
	else
		_CSAmt = 0
	end
	if math.abs(_CSAmt) > (_Tune.CSAmt/100) * 0.01 then
		_CSActive = true
	else
		_CSActive = false
	end
	local SteerWithCounter = math.clamp(_GSteerT+_CSAmt, -1, 1)
	local SteerSmoothing = math.clamp(math.abs(SteerWithCounter-_GSteerC)^(1/math.max(_Tune.SteerSmoothing, 0.001)), 0, 1)
	if _GSteerC < SteerWithCounter then
		if _GSteerC<0 then
			_GSteerC = math.min(SteerWithCounter,_GSteerC+(ReturnSpeed*SteerSmoothing*deltaTime))
		else
			_GSteerC = math.min(SteerWithCounter,_GSteerC+(SteerSpeed*SteerSmoothing*deltaTime))
		end
	else
		if _GSteerC>0 then
			_GSteerC = math.max(SteerWithCounter,_GSteerC-(ReturnSpeed*SteerSmoothing*deltaTime))
		else
			_GSteerC = math.max(SteerWithCounter,_GSteerC-(SteerSpeed*SteerSmoothing*deltaTime))
		end
	end

	-- Steer Decay Multiplier
	local sDecay = (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/(_Tune.SteerDecay/(Units.Velocity_mdivs/3.6)),1-(_Tune.MinSteer/100)))
	local rsDecay = (1-math.min(_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)/(_Tune.RSteerDecay/(Units.Velocity_mdivs/3.6)),1-(_Tune.MinSteer/100)))

	-- Apply Steering
	for wheel, data in Wheels do
		if data.CanSteer == 0 then continue end

		local angle = 0
		local rsteerVariableAngle = 1
		if data.CanSteer == 2 then
			if data.Name == "FL" then
				angle = (_GSteerC<0 and SteerInner or SteerOuter)*sDecay
			elseif data.Name == "FR" then
				angle = (_GSteerC<0 and SteerOuter or SteerInner)*sDecay
			elseif data.Name == "F" then
				angle = SteerInner*sDecay
			elseif data.Name == "RL" then
				angle = (_GSteerC<0 and _Tune.RSteerInner or _Tune.RSteerOuter)*rsDecay
			elseif data.Name == "RR" then
				angle = (_GSteerC<0 and _Tune.RSteerOuter or _Tune.RSteerInner)*rsDecay
			elseif data.Name == "R" then
				angle = _Tune.RSteerInner*rsDecay
			end
			if not data.isFront then	
				if _Tune.FWSteer == "Static" then
					rsteerVariableAngle = -math.max(0,1-(_Velocity.Magnitude/_Tune.RSteerSpeed))
				elseif _Tune.FWSteer == "Speed" then
					rsteerVariableAngle = math.min(1,(_Velocity.Magnitude/_Tune.RSteerSpeed))
				elseif _Tune.FWSteer == "Both" then
					rsteerVariableAngle = -math.max(-1,1-(_Velocity.Magnitude/_Tune.RSteerSpeed))
				end
			end
		end

		if _Tune.PowerSteeringType == "New" then
			data.SteerAttach0.Orientation = Vector3.new(0, data.CanSteer==1 and 0 or _GSteerC*angle*rsteerVariableAngle, 0)
		else
			data.Steer.CFrame = data.Base.CFrame * (data.CanSteer == 1 and CFrame.new(0,0,0) or (CFrame.Angles(0, -math.rad(_GSteerC*angle*rsteerVariableAngle), 0)))
		end
	end
end

-- Engine
-- Electric Only Setup
if not _Tune.Engine and _Tune.Electric then 
	_Tune.Redline = _Tune.E_Redline 
	_Tune.ShiftRPM = _Tune.E_Redline
	_Tune.Turbochargers = 0
	_Tune.Superchargers = 0
	_Tune.Clutch = false 
	_Tune.IdleRPM = 0 
	_Tune.IdleThrottle = 0
	_Tune.ClutchType = "Clutch" 
	_Tune.AutoShiftType = "DCT"
end

-- Automatic Transmission
local function Auto()	
	if not _IsOn then 
		return 
	end

	local fFD = _Tune.FinalDrive * _Tune.FDMult
	local fFDr = fFD * 30 / math.pi

	if _Tune.AutoShiftVers == "Old" and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) then _CGear = 1 _ClPressing = false end
	if _CGear >= 1 then
		if (_CGear==1 and _InBrake > 0 and _Velocity.Magnitude < 5) and _Tune.AutoShiftVers == "Old" then
			_CGear = -1 _ClPressing = false
		elseif _Velocity.Magnitude > 5 and _Tune.ClutchType ~= "CVT" then
			if _Tune.AutoShiftMode == "RPM" then
				if _RPM>(_Tune.ShiftRPM+_Tune.AutoUpThresh) then
					if not _ShiftUp and not _Shifting then _ShiftUp = true end
				elseif math.max(math.min(_MaxWheelSpin*_Tune.Ratios[_CGear+1+ParkingGearOffset]*fFDr,_Tune.Redline+100),0)<(_Tune.ShiftRPM-_Tune.AutoDownThresh) and _CGear>1 then
					if not _ShiftDn and not _Shifting then _ShiftDn = true end 
				end
			else
				if _Velocity.Magnitude > math.ceil(wDRatio*(_Tune.ShiftRPM+_Tune.AutoUpThresh)/_CurrentRatio/fFD) then
					if not _ShiftUp and not _Shifting then _ShiftUp = true end
				elseif _Velocity.Magnitude < math.ceil(wDRatio*(_Tune.ShiftRPM-_Tune.AutoDownThresh)/_Tune.Ratios[_CGear+1+ParkingGearOffset]/fFD) and _CGear>1 then
					if not _ShiftDn and not _Shifting then _ShiftDn = true end
				end
			end
		end
	else
		if (_InThrot > 0 and _Velocity.Magnitude < 5) and _Tune.AutoShiftVers == "Old" then
			_CGear = 1 _ClPressing = false
		end
	end
end

local function Gear()
	local fFDr = (_Tune.FinalDrive * _Tune.FDMult) * 30 / math.pi
	
	if _ShiftUp and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or (_TMode == "Manual" and _Tune.ClutchRel and (_InThrot > 0)) or _CGear == #_Tune.Ratios - 2 - ParkingGearOffset or (_TMode ~= "Manual" and not _IsOn) then 
			_ShiftUp = false 
			return 
		end
		local NextGear = math.min(_CGear + 3 + ParkingGearOffset, #_Tune.Ratios)
		if _TMode ~= "Manual" and _Tune.ClutchType ~= "CVT" then
			_Shifting = true
			if _CGear > 0 then 
				if _Tune.AutoShiftType == "DCT" then 
					task.wait(_Tune.ShiftUpTime)
				elseif _Tune.AutoShiftType == "Rev" then
					repeat task.wait() until _RPM <= math.max(math.min(_MaxWheelSpin * _Tune.Ratios[NextGear] * fFDr, _Tune.Redline - _Tune.RevBounce), _Tune.IdleRPM) or not _IsOn or _ShiftDn 
				end
			end
		end
		_ShiftUp = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then 
			return 
		end
		if NextGear > 3 + ParkingGearOffset and _Tune.ClutchType == "CVT" then return end
		_CGear = math.min(_CGear + 1, #_Tune.Ratios - 2 - ParkingGearOffset)
		if _TMode ~= "Manual" or (_CGear == 1 and _IsOn) then 
			_ClPressing = (_TMode == "Manual" and _PlayerClutch) or false
		end
	end

	if _ShiftDn and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or _CGear == -1 - ParkingGearOffset or (_TMode ~= "Manual" and not _IsOn) then 
			_ShiftDn = false 
			return 
		end
		local PrevGear = math.min(_CGear + 1 + ParkingGearOffset, #_Tune.Ratios)
		if _TMode ~= "Manual" then
			_Shifting = true
			if _CGear > 1 then 
				if _Tune.AutoShiftType == "DCT" then 
					task.wait(_Tune.ShiftDnTime)
				elseif _Tune.AutoShiftType == "Rev" then
					repeat task.wait() until _RPM >= math.max(math.min(_MaxWheelSpin * _Tune.Ratios[PrevGear] * fFDr, _Tune.Redline - _Tune.RevBounce), _Tune.IdleRPM) or not _IsOn or _ShiftUp
				end
			end
		end
		_ShiftDn = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then 
			return 
		end
		_CGear = math.max(_CGear - 1, _Velocity.Magnitude > 5 and -1 or -2)
		if _TMode ~= "Manual" or (_CGear == -1 and _IsOn) then 
			_ClPressing = (_TMode == "Manual" and _PlayerClutch) or false
		end
	end
end

local goalRPM = 0
local tqTCS = 1
local stallOk = false
local ticc = tick()

-- Power calculation prerequesites
local function f(m: number, n: number, p: number, q: number, M: number, b: number, x: number): number
	return math.clamp(M - ( (q-n)/(b^p-b^m) * (b^x-b^m) + n), 0, M)
end

-- Apply Power
local function Engine(dt: number)
	local deltaTime = dt * 60

	local fFD = _Tune.FinalDrive * _Tune.FDMult
	local fFDr = fFD * 30 / math.pi
	local cGrav = (_Tune.GravComp > 0 and _Tune.GravComp or workspace.Gravity) * _Tune.InclineComp / 35

	local _WheelRPM = _DriveWheelSpeed * _CurrentRatio * fFDr

	-- CVT
	if _Tune.ClutchType == "CVT" then
		local denom = _DriveWheelSpeed * fFDr
		local targetRPM = _Tune.IdleRPM + (_Tune.CVTRPM - _Tune.IdleRPM) * _GThrot
		if math.abs(denom) > 1e-6 then
			_CVTRatio = math.clamp(targetRPM / denom, _Tune.CVTMinRatio, _Tune.CVTMaxRatio)
		else
			_CVTRatio = _Tune.CVTMaxRatio
		end
	end
	
	-- Update ratio
	_CurrentRatio = _Tune.ClutchType == "CVT" and _CVTRatio or _Tune.Ratios[_CGear+2+ParkingGearOffset]
	_spLimit = _Tune.Redline/(fFDr*_CurrentRatio)
	if _CurrentRatio*fFDr == 0 then
		_spLimit = 0
	end -- Prevents [nan] from dividing by 0

	-- Flywheel/clutch-dumping
	_FlywheelEnergy = math.max((_RPM-_WheelRPM)*_Tune.DumpMult,0) * (1-_Clutch) * 1.356*Units.Torque_nm

	-- Determine RPM
	local revMin = 0
	local goalMin = 0
	local goalMax = _Tune.Redline

	if _Shifting and _ShiftUp then 
		_GThrot = _Tune.IdleThrottle/100
	elseif _Shifting and _ShiftDn then
		_GThrot = _Tune.ShiftThrot/100
	else
		if (_Tune.AutoShiftVers == "Old" and _CGear==-1 and _TMode=="Auto") then
			_GThrot = _InBrake
		else
			_GThrot = math.max(_InThrot, _Tune.IdleThrottle/100)
		end
	end

	if (_Tune.AutoShiftVers == "Old" and _CGear==-1 and _TMode=="Auto") then
		_GBrake = _InThrot
	else
		_GBrake = _InBrake
	end

	if not _IsOn then 
		ticc = tick()
		if _AutoClutch then
			_Clutch = 1 
		end
		_GThrot = 0
	end

	if ((_ClPressing and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2))) or (_PlayerClutch and _CGear ~= 0)) and _Tune.NeutralLimit then
		if ((_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) and not _Tune.LimitClutch) or _Tune.LimitClutch then
			goalMax = _Tune.NeutralRevRPM
		end
	end

	-- Rev limiter/speed limiter
	if _RPM >= _Tune.Redline then
		_RevLimiting = true
	elseif _RPM < goalMax-_Tune.RevBounce then
		_RevLimiting = false
	end
	if _RevLimiting then
		_GThrot = _Tune.IdleThrottle/100
	end

	local limit = (_CGear<0 and _Tune.ReverseSpeed or _Tune.SpeedLimit)
	if limit > 0 then
		_GThrot = math.min(_GThrot, math.max(1 - math.clamp(((_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)) - (limit-_Tune.SLimitGradient))/_Tune.SLimitGradient, 0, 1), _Tune.IdleThrottle/100))
		if _Tune.SLimitBrake then
			_GBrake = math.max(_GBrake, math.clamp( (_Velocity.Magnitude/(Units.Velocity_mdivs/3.6) - limit)/_Tune.SLimitGradient, 0, 1))
		end
	end

	-- Idle
	if _RPM<_Tune.IdleRPM+(_Tune.IdlePadding or 0) and _IsOn then
		_GThrot = math.max(_GThrot, math.clamp((_Tune.IdleRPM+(_Tune.IdlePadding or 0)-_RPM)/(_Tune.IdleDamping or 400), 0, 1))
	end

	if (_Tune.Engine or _Tune.Electric) and (not _Starting) then
		goalRPM = math.clamp(_RPM - (_Tune.RevDecay*deltaTime) + (_Tune.RevAccel*_GThrot*deltaTime) - (math.clamp(math.max(_RPM-_Tune.IdleRPM,0)/math.max(_Tune.Redline-_Tune.IdleRPM,1),0,1)*_Tune.RevDecayRPM*deltaTime), goalMin, goalMax)
	end

	-- Starting
	if _Starting then
		goalRPM = math.clamp(goalRPM + _Tune.IgnitionAccel * deltaTime, 0, math.max(_Tune.IgnitionRPM, _WheelRPM))
		IsOnValue.Value = goalRPM > _Tune.IgnitionMinRPM
	end

	-- Set RPM
	local aRPM = math.max((goalRPM*(1-deltaTime) + _WheelRPM*deltaTime)*(1-_Clutch) + goalRPM*_Clutch, revMin)
	local clutchP = math.min(math.abs(aRPM-_RPM) / (_Tune.Flywheel*deltaTime), .9)
	if _ClPressing then 
		clutchP = 0 
	end
	_RPM = aRPM*(1-clutchP) + _RPM*clutchP

	if _Tune.OverRev == false and _RPM > _Tune.Redline then 
		_RPM = _Tune.Redline 
	end

	if _RPM<=(_Tune.IdleRPM/4) and stallOk and (tick()-ticc>=0.2) and _Tune.Stall then 
		IsOnValue.Value = false 
	end

	-- Clutch
	if _Shifting or (_AutoClutch and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2))) then
		_ClPressing = true
		_Clutch = 1
		stallOk = false
	end

	if _Tune.Clutch then
		if _AutoClutch then
			if _Tune.ClutchType == "Clutch" or _Tune.ClutchType == "CVT" then
				if _ClPressing then _ClutchKick = 1 end
				_ClutchKick = _ClutchKick*(_Tune.ClutchEngage/100)
				local ClRPMInfluence = math.max(_RPM*_Tune.ClutchRPMMult/_Tune.Redline,0)
				if _Tune.ClutchMode == "New" then ClRPMInfluence = 0 end
				_ClutchModulate = math.min(((((math.max(_Velocity.Magnitude, 0.001) / (Units.Velocity_mdivs / 3.6) / _Tune.SpeedEngage) / math.max(math.abs(_CGear), 1)) + ClRPMInfluence) - _ClutchKick), 1)
			elseif _Tune.ClutchType == "TorqueConverter" and _Tune.TQLock then
				if (_GThrot<=_Tune.IdleThrottle/100 and _Velocity.Magnitude/(Units.Velocity_mdivs/3.6)<_Tune.SpeedEngage) or (_GThrot>_Tune.IdleThrottle/100 and (_RPM < _Tune.RPMEngage and _WheelRPM < _Tune.RPMEngage)) then
					_ClutchModulate = math.min(_ClutchModulate*(_Tune.ClutchEngage/100), 1)
				else
					_ClutchModulate = math.min(_ClutchModulate*(_Tune.ClutchEngage/100)+(1-(_Tune.ClutchEngage/100)), 1)
				end
			elseif _Tune.ClutchType == "TorqueConverter" and not _Tune.TQLock then
				_ClutchModulate = math.min((_RPM/_Tune.Redline)*0.7, 1)
			end
			if not _ClPressing then _Clutch = math.min(1-_ClutchModulate,1) else _Clutch = 1 end
		else
			if _ClPressing then
				_Clutch = 1
			else
				_Clutch = 0
			end
		end
		stallOk = (_Clutch<=0.01) or stallOk
	else
		stallOk = false
		if not _ClPressing and not _Shifting then _Clutch = 0 else _Clutch = 1 end
	end

	-- Things that apply the clutch
	if _AutoClutch and (_Starting or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM+(_Tune.IdlePadding or 0) and _IThrot < .1) or (_RevLimiting and _Tune.OverRev == false)) then
		_Clutch = 1
	end

	-- Torque calculations (Detomiks)
	-- What you see here is mostly just ported over from Desmos.
	if not engine or _Tune.CustomEngineCalculations == false then
		local x = _RPM/1000
		local NTorque = 0
		local ETorque = 0
		local TTorque = 0
		local STorque = 0
		if _Tune.Engine then
			local NIdleTorque = f(_Tune.IdleRPM/1000, _Tune.IdleTorque, _Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.PeakTorque, _Tune.IdleTorqueCurve, x)
			local NRedlineTorque = f(_Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.Redline/1000, _Tune.RedlineTorque, _Tune.PeakTorque, 1/_Tune.RedlineTorqueCurve, x)
			local VVL = _Tune.VVLTorque > 0 and _Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, x) or 0
			local AirPressurePercent = math.exp((-9.80665 * 0.0289644 * (_Center.Y * Units.Length_mm / 1000)) / (8.3142 * (GlobalTemperature + 273.15))) -- look up the barometric formula 
			NTorque = 1 * (_Tune.PeakTorque - NIdleTorque - NRedlineTorque + VVL) * AirPressurePercent
			_NH, _NT = (NTorque*x)/5.252, NTorque

			if _Tune.Turbochargers > 0 then
				local _TBoostGoal = _Tune.Turbochargers * ((_GThrot^3) * (100/_Tune.T_Size) * ((NTorque*x)/5.252) - f(_Tune.IdleRPM/1000, _Tune.T_IdleBoost, _Tune.T_PeakRPM/1000, _Tune.T_Boost, (_GThrot^3) * (100/_Tune.T_Size) * ((NTorque*x)/5.252), 1/_Tune.T_Curve, x))
				if _TBoostGoal > _TBoost then
					_TBoost = _TBoost + math.min(_Tune.T_SpoolIncrease*(_TBoostGoal-_TBoost), _Tune.T_SpoolIncrease * (10/_Tune.T_Size) * _Tune.Turbochargers) * deltaTime -- i should probably base this off of the maximum horsepower instead of the RPM, but it's the same thing anyway
				elseif _TBoost > _TBoostGoal then
					_TBoost = _TBoost + _Tune.T_SpoolDecrease*(_TBoostGoal-_TBoost) * deltaTime
				end
				_TBoost = math.clamp(_TBoost, 0, _Tune.Turbochargers * _Tune.T_Boost)
				TTorque = _TBoost * _Tune.T_Efficiency
				_TH, _TT = (TTorque*x)/5.252, TTorque
			end
			if _Tune.Superchargers > 0 then
				local SIdleBoost = f(_Tune.IdleRPM/1000, _Tune.S_IdleBoost, _Tune.S_PeakRPM/1000, _Tune.S_Boost, _Tune.S_Boost, _Tune.S_IdleCurve, x)
				local SRedlineBoost = f(_Tune.S_PeakRPM/1000, _Tune.S_Boost, _Tune.Redline/1000, _Tune.S_RedlineBoost, _Tune.S_Boost, 1/_Tune.S_RedlineCurve, x)
				local _SBoostGoal = _Tune.Superchargers * _GThrot * (_Tune.S_Boost - SIdleBoost - SRedlineBoost)
				if _SBoostGoal > _SBoost then
					_SBoost = math.min(_SBoost + _Tune.S_Boost*_Tune.S_Response*deltaTime, _SBoostGoal)
				elseif _SBoost > _SBoostGoal then
					_SBoost = math.max(_SBoost - _Tune.S_Boost*_Tune.S_Response*deltaTime, _SBoostGoal)
				end
				STorque = _SBoost * _Tune.S_Efficiency
				_SH, _ST = (STorque*x)/5.252, STorque
			end
			if _Tune.Turbochargers > 0 or _Tune.Superchargers > 0 then
				_BH, _BT = ((TTorque+STorque)*x)/5.252, TTorque+STorque
			end
		end
		if _Tune.Electric then
			ETorque = 1 * (_Tune.E_Torque - f(_Tune.E_TransitionRPM/1000, _Tune.E_Torque, _Tune.E_Redline/1000, _Tune.E_RedlineTorque, _Tune.E_Torque, _Tune.E_Curve, x))
			_EH, _ET = (ETorque*x)/5.252, ETorque
		end
		local TotalTorque = math.clamp(NTorque + ETorque + TTorque + STorque, _Tune.Stall and 0 or _Tune.IdleTorque, (_Tune.HPLimit > 0 and _Tune.HPLimit or math.huge)*(5.252/x))
		_HP, _TQ = (TotalTorque*x)/5.252, TotalTorque
	else
		engine.run({
			-- Manually add environment variables here
			_RPM = _RPM,
			_GThrot = _GThrot,
			_IsOn = _IsOn,
			_CGear = _CGear,

		}, dt)

		_Boost = engine._Boost
		_TBoost = engine._TBoost
		_SBoost = engine._SBoost

		_HP = engine._HP
		_TQ = engine._TQ
		_NH = engine._NH
		_NT = engine._NT
		_EH = engine._EH
		_ET = engine._ET
		_TH = engine._TH
		_TT = engine._TT
		_SH = engine._SH
		_ST = engine._ST
		_BH = engine._BH
		_BT = engine._BT
	end

	-- Exit engine
	_OutTorque = _TQ * _CurrentRatio * fFD
	local iComp = (_Center.LookVector.Y)*cGrav*math.sign(_CGear)
	_OutTorque = _OutTorque*math.max(1,(1+iComp))

	-- Brakes
	local FBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N * _Tune.BrakeBias -- luaint edit, conversion to SI unit Detomiks
	local RBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.BrakeBias) -- luaint edit
	local PBrakeForceF = _Tune.PBrakeForce * 9.80665 * Units.Force_N * _Tune.PBrakeBias
	local PBrakeForceR = _Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.PBrakeBias)

	-- Update Wheels
	for wheel, data in Wheels do
		-- Apply Power
		local PBrakeV = (_PBrake == true or _CGear == -2) and 1 or 0
		local on = _IsOn and 1 or 0

		local throt = _GThrot
		local brake = _GBrake

		local clutch=1
		if _ClPressing or (_AutoClutch and (_Starting or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM+(_Tune.IdlePadding or 0) and _IThrot < .1))) then 
			clutch=0 
		end -- for some reason, the car still creeps forward when starting the car if i don't do this

		-- Apply ESC
		local tqESC = 0
		if not (data.Name == "F" or data.Name == "R") and _ESC and (_Velocity.Magnitude/(Units.Velocity_mdivs/3.6)) > _Tune.ESCSpeed then
			local g = weightBrick.CFrame:VectorToObjectSpace(_Acceleration/(Units.Velocity_mdivs)/((_Tune.GravComp>0 and _Tune.GravComp or workspace.Gravity)*(Units.Length_mm/1000)))
			if math.sign(_GSteerC) ~= math.sign(g.X) then
				local diff = _GSteerC-(g.X*-math.sign(_Center:VectorToObjectSpace(_Velocity).Z))
				if math.abs(diff) > _Tune.ESCThreshold then
					local escVector, escBias = 1, (_Tune.ESCVector+1)
					if data.isFront then 
						escVector = escVector*(2-escBias)
					else 
						escVector = escVector*escBias 
					end

					tqESC = ((data.Name == "FL" or data.Name == "RL") and 1 or -1) * math.sign(diff)*escVector
					throt = throt + (math.max(tqESC,0) - throt) * (_Tune.ESCThrottle/100)
					brake = brake + (-math.min(tqESC,0) - brake) * (_Tune.ESCBrake/100)
				end
			end
		end

		_ESCActive = tqESC ~= 0 or _ESCActive
		_ESCTracker[data.Name] = tqESC

		-- Apply ABS
		local tqABS = 1
		if _ABS and brake>0 then
			tqABS = 1-(math.min(math.max(0,math.abs(data.RotVelocityMagnitude*(data.Size.Y/2)/(Units.Velocity_mdivs/3.6) - data.WheelVelocityMagnitude/(Units.Velocity_mdivs/3.6))-_Tune.ABSThreshold)/_Tune.ABSGradient,1)*(1-(_Tune.ABSLimit/100)))
		end
		_ABSActive = tqABS < 1 or _ABSActive
		_ABSTracker[data.Name] = 1 - tqABS

		-- Apply Power
		if data.driven then
			-- Differential/Torque-Vectoring
			local RRdiffMult=1
			local RLdiffMult=1
			local FRdiffMult=1
			local FLdiffMult=1

			if data.Name=="FR" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.FDiffPreload/10)
				FRdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.FDiffPower/100)*avg*_GThrot) + ((_Tune.FDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				FLdiffMult=2-FRdiffMult
			elseif data.Name=="FL" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.FDiffPreload/10)
				FLdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.FDiffPower/100)*avg*_GThrot) + ((_Tune.FDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				FRdiffMult=2-FLdiffMult
			elseif data.Name=="RR" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.RDiffPreload/10)
				RRdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.RDiffPower/100)*avg*_GThrot) + ((_Tune.RDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				RLdiffMult=2-RRdiffMult
			elseif data.Name=="RL" then
				local avg=((data.RotVelocityMagnitude/data.OppositeWheel.RotVelocity.Magnitude)-1)*(_Tune.RDiffPreload/10)
				RLdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.RDiffPower/100)*avg*_GThrot) + ((_Tune.RDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
				RRdiffMult=2-RLdiffMult
			end

			-- Apply torque split
			-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
			local bias = (_Tune.Config == "AWD" and (_Tune.TorqueVector+1)/2) or (_Tune.Config == "FWD" and 0) or 1
			local tq = data.isFront and (_OutTorque * (1 - bias)) / FWheelCount or (_OutTorque * bias) / RWheelCount

			-- Apply TCS
			tqTCS = 1
			if _TCS and throt>_Tune.IdleThrottle/100 then
				tqTCS = 1-(math.min(math.max(0,math.abs(data.RotVelocityMagnitude*(data.Size.Y/2)/(Units.Velocity_mdivs/3.6) - data.WheelVelocityMagnitude/(Units.Velocity_mdivs/3.6))-_Tune.TCSThreshold)/_Tune.TCSGradient,1)*(1-(_Tune.TCSLimit/100)))
			end
			_TCSActive = tqTCS < 1 or _TCSActive
			_TCSTracker[data.Name] = 1-tqTCS

			-- Update Forces
			local tqOUT = (tq*1.356*Units.Torque_nm*throt*tqTCS*on*clutch) + (_FlywheelEnergy/#Drive)
			-- convert lb-ft to nm to roblox stuff
			-- if it reaches an absurdly high number, set it to 0 to try and prevent physics death

			if data.Name=='RR' then
				data.AV.MotorMaxTorque=tqOUT*RRdiffMult
			elseif data.Name=='RL' then
				data.AV.MotorMaxTorque=tqOUT*RLdiffMult
			elseif data.Name=='FR' then
				data.AV.MotorMaxTorque=tqOUT*FRdiffMult
			elseif data.Name=='FL' then
				data.AV.MotorMaxTorque=tqOUT*FLdiffMult
			else
				data.AV.MotorMaxTorque=tqOUT
			end
			data.AV.AngularVelocity = _spLimit * math.sign(_CGear)
			if data.isFront then
				data.BV.MotorMaxTorque = (FBrakeForce*brake*tqABS) + (_Tune.EBrakeForce*clutch*((1-throt)*(_RPM/_Tune.Redline))) + (PBrakeForceF*PBrakeV)
			else
				data.BV.MotorMaxTorque = (RBrakeForce*brake*tqABS) + (_Tune.EBrakeForce*clutch*((1-throt)*(_RPM/_Tune.Redline))) + (PBrakeForceR*PBrakeV)
			end
		else -- luaint edit
			data.AV.MotorMaxTorque=0
			data.AV.AngularVelocity=0
			if data.isFront then
				data.BV.MotorMaxTorque = (FBrakeForce*brake*tqABS) + (PBrakeForceF*PBrakeV)
			else
				data.BV.MotorMaxTorque = (RBrakeForce*brake*tqABS) + (PBrakeForceR*PBrakeV)
			end
		end
	end
end

-- Wheel output values
local function GetCenter()
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	for wheel, data in Wheels do
		if data.isFront then
			centerF = centerF + wheel.Position
			countF = countF + 1
		else
			centerR = centerR + wheel.Position
			countR = countR + 1
		end
	end
	centerF = centerF / countF
	centerR = centerR / countR
	local center = CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
	return center
end

local function WheelOutput(dt: number)
	local tcsCount = 0
	local absCount = 0
	local escCount = 0
	local rot = 0
	local count = 0
	local driveCount = 0

	_TCSAmt = 0
	_ABSAmt = 0
	_ESCAmt = 0

	_MaxWheelSpin = 0
	_DriveWheelSpeed = 0

	for wheel, data in Wheels do
		count += 1

		-- Wheel speeds
		if not _WheelSpeedsTable[data.Name] then
			_WheelSpeedsTable[data.Name] = {}
		end

		data.RotVelocityMagnitude = wheel.RotVelocity.Magnitude
		data.WheelVelocityMagnitude = wheel.Velocity.Magnitude

		table.insert(_WheelSpeedsTable[data.Name], data.RotVelocityMagnitude)
		if #_WheelSpeedsTable[data.Name] > 8 then
			table.remove(_WheelSpeedsTable[data.Name], 1)
		end

		local avg = 0
		local avgCount = 0

		for _, a in _WheelSpeedsTable[data.Name] do
			avg += a
			avgCount += 1
		end

		avg = avg / avgCount
		_WheelSpeeds[data.Name] = avg

		if data.driven then
			_DriveWheelSpeed = _DriveWheelSpeed + avg
			driveCount = driveCount + 1
			if avg > _MaxWheelSpin then
				_MaxWheelSpin = avg
			end
		end

		-- Output wheel speeds
		data.WheelSpeedValue.Value = _WheelSpeeds[data.Name] -- I'm not using the avg variable here for future-proofing if we change the calculation later and stuff
		rot += _WheelSpeeds[data.Name] * (data.Size.Y / 2)

		-- TCS
		if _TCSTracker[data.Name] then
			data.TCSTrackerValue.Value = _TCSTracker[data.Name]
			_TCSAmt += _TCSTracker[data.Name]
			tcsCount += 1
		end

		-- ABS
		if _ABSTracker[data.Name] then
			data.ABSTrackerValue.Value = _ABSTracker[data.Name]
			_ABSAmt += _ABSTracker[data.Name]
			absCount += 1
		end

		-- ESC
		if _ESCTracker[data.Name] then
			data.ESCTrackerValue.Value = _ESCTracker[data.Name]
			_ESCAmt += math.abs(_ESCTracker[data.Name])
			escCount += 1
		end
	end

	_DriveWheelSpeed = _DriveWheelSpeed / driveCount

	-- Wheel speeds
	_AvgWheelSpeed = rot / count
	-- TCS
	_TCSAmt = _TCSAmt / tcsCount
	_TCSActive = false
	-- ABS
	_ABSAmt = _ABSAmt / absCount
	_ABSActive = false
	-- ESC
	_ESCAmt = _ESCAmt / escCount
	_ESCActive = false
end

-- Mobile
local function Mobile()
	MobileUI.ModeSwitch.Visible = _Velocity.Magnitude < 5
	MobileUI.ModeSwitch.Text = MobileMode
	MobileUI.Jump.Visible = MobileUI.ModeSwitch.Visible
	for _, v in MobileUIChildren do
		if v:IsA("Frame") then
			v.Visible = MobileMode == v.Name
		end
	end
end

-- Flip
local function Flip()
	-- Detect Orientation
	if _FlipDB or (driveSeat.CFrame * CFrame.Angles(math.pi / 2, 0, 0)).LookVector.Y > 0.1 then
		_FlipWait = tick()
	else
		if tick() - _FlipWait >= 3 then
			_FlipDB = true
			if _Tune.FlipType == "New" then
				local gyro = driveSeat.Flip
				gyro.Enabled = true
				task.wait(1)
				gyro.Enabled = false
			else
				local gyro = driveSeat.Flip
				gyro.maxTorque = Vector3.new(10000, 0, 10000)
				gyro.P = 3000
				gyro.D = 500
				task.wait(1)
				gyro.maxTorque = Vector3.new(0, 0, 0)
				gyro.P = 0
				gyro.D = 0
			end
			_FlipDB = false
		end
	end
end

-- Last Input Type
local function onLastInputTypeChanged(inputType: Enum.UserInputType)
	LastInputWasGamepad = string.find(inputType.Name, "Gamepad") and true or false

	-- Mobile
	LastInputWasMobile = inputType == Enum.UserInputType.Touch
	MobileUI.Visible = LastInputWasMobile
	if LastInputWasMobile then
		_Tune.AutoShiftVers = "Old"
		_TMode = "Auto"
	else
		_Tune.AutoShiftVers = _InitialAutoShiftVers
	end
end

-- Run
-- In case of car death
driveSeat.AncestryChanged:Connect(function() 
	if driveSeat.Parent then return end 
	task.wait(10) 
	script.Parent:Destroy() 
end)

-- Changes
onLastInputTypeChanged(UserInputService:GetLastInputType())
UserInputService.LastInputTypeChanged:Connect(onLastInputTypeChanged)

-- Print Version
print("A-Chassis, Version " .. require(car["A-Chassis Tune"].README))

-- Runtime Loops
local function RuntimeLoop(dt: number)
	-- Update Internal Values
	-- Velocity
	_Velocity = weightBrick.AssemblyLinearVelocity
	_Acceleration = (_Velocity - _OldVelocity) / dt
	_OldVelocity = _Velocity
	_Center = GetCenter()

	-- Update External Values
	-- Transmission
	Value.Clutch.Value = _Clutch
	Value.Gear.Value = _CGear
	Value.TransmissionMode.Value = _TMode
	Value.CurrentRatio.Value = _CurrentRatio
	Value.RPM.Value = _RPM

	-- Boost
	Value.Boost.Value = _TBoost + _SBoost
	Value.BoostTurbo.Value = _TBoost
	Value.BoostSuper.Value = _SBoost

	-- Horsepower
	Value.HpNatural.Value = _NH
	Value.HpElectric.Value = _EH
	Value.HpTurbo.Value = _TH
	Value.HpSuper.Value = _SH
	Value.HpBoosted.Value = _BH
	Value.Horsepower.Value = _HP

	-- Torque
	Value.TqNatural.Value = _NT
	Value.TqElectric.Value = _ET
	Value.TqTurbo.Value = _TT
	Value.TqSuper.Value = _ST
	Value.TqBoosted.Value = _BT
	Value.Torque.Value = _TQ

	-- Inputs
	Value.Throttle.Value = _GThrot
	Value.InputThrottle.Value = _IThrot
	Value.Brake.Value = _GBrake
	Value.InputBrake.Value = _IBrake
	Value.SteerC.Value = _GSteerC
	Value.SteerT.Value = _GSteerT
	Value.PBrake.Value = _PBrake

	-- Velocity
	Value.Velocity.Value = _Velocity
	Value.AverageRotSpeed.Value = _AvgWheelSpeed
	Value.Acceleration.Value = _Acceleration

	-- Misc
	Value.Center.Value = _Center
	Value.TCS.Value = _TCS
	Value.TCSActive.Value = _TCSActive
	Value.TCSAmt.Value = _TCSAmt

	Value.ABS.Value = _ABS
	Value.ABSActive.Value = _ABSActive
	Value.ABSAmt.Value = _ABSAmt

	Value.ESC.Value = _ESC
	Value.ESCActive.Value = _ESCActive
	Value.ESCAmt.Value = _ESCAmt

	Value.CS.Value = _CS
	Value.CSActive.Value = _CSActive
	Value.CSAmt.Value = _CSAmt

	-- Wheel Output
	WheelOutput(dt)

	-- Inputs
	Inputs(dt)

	-- Steering
	Steering(dt)

	-- Gear
	Gear()

	-- Power
	Engine(dt)
end

local fixedDeltaTime = 1/60 -- Fixed to avoid rewriting old code causing different behaviours at different FPS
local accumulatedSimTime = 0

RunService.PreSimulation:Connect(function(deltaTimeSim: number) 
	accumulatedSimTime += deltaTimeSim
	while accumulatedSimTime >= fixedDeltaTime do
		accumulatedSimTime -= fixedDeltaTime
		RuntimeLoop(fixedDeltaTime) 
	end
end)

local function SlowRuntimeLoop()
	while true do
		local deltaTime = task.wait(1/8)

		-- Mobile UI
		if _Tune.Mobile and LastInputWasMobile then
			Mobile()
		end

		-- Automatic Transmission
		if _TMode == "Auto" then 
			Auto() 
		end

		-- Flip
		if _Tune.AutoFlip then 
			Flip() 
		end

		-- Set GlobalTemperature
		GlobalTemperature = workspace:GetAttribute("GlobalTemperature") or 22

	end
end

task.spawn(SlowRuntimeLoop)
