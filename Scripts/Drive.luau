--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

--[[START]]
script.Parent:WaitForChild("Car")
script.Parent:WaitForChild("IsOn")
script.Parent:WaitForChild("ControlsOpen")
script.Parent:WaitForChild("Values")

--[[Blocks]]

	local VirtualInputEnabled		= true

--[[Dependencies]]
	local player = game.Players.LocalPlayer
	local mouse = player:GetMouse()
	local UserInputService = game:GetService("UserInputService")
	local GuiService = game:GetService("GuiService")
	local RunService = game:GetService("RunService")
	local car = script.Parent.Car.Value
	local _Tune = require(car["A-Chassis Tune"])
	local Units = require(car["A-Chassis Tune"].README.Units)
	local values = script.Parent.Values
	
	local VirtualInput = script:FindFirstChild("VirtualInput")
	
	player.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	
	if _Tune.Mobile then
		GuiService.TouchControlsEnabled = false
	end
	local _MobileMode = "Tap"
	local _MobileModes = {"Tap", "Tilt"}
	
--[[Output Scaling Factor]]
	local FBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N*_Tune.BrakeBias--luaint edit, conversion to SI unit Detomiks
	local RBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N*(1-_Tune.BrakeBias)--luaint edit
	local PBrakeForceF = _Tune.PBrakeForce * 9.80665 * Units.Force_N*_Tune.PBrakeBias
	local PBrakeForceR = _Tune.PBrakeForce * 9.80665 * Units.Force_N*(1-_Tune.PBrakeBias)
	local EBrakeForce = _Tune.EBrakeForce
	local SteerOuter  = _Tune.SteerOuter--luaint edit
	local SteerInner  = _Tune.SteerInner--luaint edit
	local RSteerOuter = _Tune.RSteerOuter
	local RSteerInner = _Tune.RSteerInner

--[[Status Vars]]
	local boolToNum = {[true] = 1, [false] = 0}
	local min = math.min
	local max = math.max

	local _IsOn = _Tune.AutoStart
	if _Tune.AutoStart and (_Tune.Engine or _Tune.Electric) then script.Parent.IsOn.Value=true end

	local _GSteerT=0
	local _GSteerC=0
	
	local _GThrot=0
	local _InThrot=0
	local _IThrot=0
	local _GBrake=0
	local _InBrake=0
	local _IBrake=0

	local _GClutch = 0
	local _ClPressing = false
	local _PlayerClutch = false
	local _Clutch = 0
	local _ClutchKick = 0
	local _ClutchModulate = 0

	local _RPM = _Tune.IgnitionRPM
	local _OutTorque = 0
	local _CGear = 0
	local _PGear = _CGear
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

	local _CVTRatio = _Tune.CVTMaxRatio
	local _CurrentRatio = _Tune.Ratios[_CGear+2]
	local _FlywheelEnergy = 0
	local _TorqueVector = _Tune.TorqueVector

	local _TMode = _Tune.TransModes[1]

	local _MSteer = false
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

	local FlipWait=tick()
	local FlipDB=false

	local _InControls = false
	local _LastInputWasGamepad = false

	local revLimiting = false

	local _WheelSpeedsTable = {}
	local _WheelSpeeds = {}
	local _OldVelocity = Vector3.new()
	local _AvgWheelSpeed = 0
	local _Acceleration = Vector3.new()

	local _Center = CFrame.new()
	local autoshiftvers = _Tune.AutoShiftVers
	
	local FWheelCount = 0
	local RWheelCount = 0
	local Wheels = {}
	for _, v in car.Wheels:GetChildren() do
		if not ((v.Name == "FL" or v.Name == "FR" or v.Name == "F" or v.Name == "RL" or v.Name == "RR" or v.Name == "R") and v:IsA("BasePart")) then continue end
		table.insert(Wheels, v)
		FWheelCount += string.find(v.Name, "F") and 1 or 0
		RWheelCount += (not string.find(v.Name, "F")) and 1 or 0
	end

--[[Shutdown]]
car.DriveSeat.ChildRemoved:connect(function(child) 
	if child.Name=="SeatWeld" and child:IsA("Weld") then
		--Remove Flip Force
		if car.DriveSeat:FindFirstChild("Flip") then
			if _Tune.FlipType == "New" then
				car.DriveSeat.Flip.Enabled = false
			else
				car.DriveSeat.Flip.MaxTorque = Vector3.new()
			end
		end

		--Remove Wheel Force
		for _, wheel in Wheels do
			if wheel:FindFirstChild("#AV") then
				wheel["#AV"].MotorMaxTorque = 0
				wheel["#AV"].AngularVelocity = 0
			end
			if wheel:FindFirstChild("#BV") and _Tune.ExitBrake then
				if string.find(wheel.Name, "F") then
					wheel["#BV"].MotorMaxTorque = (_Tune.PBrakeForce * 9.80665 * Units.Force_N) * _Tune.PBrakeBias
				else
					wheel["#BV"].MotorMaxTorque = (_Tune.PBrakeForce * 9.80665 * Units.Force_N) * (1-_Tune.PBrakeBias)
				end
			end
		end

		-- Save PBrake state
		car["A-Chassis Tune"]["A-Chassis Interface"].Values.PBrake.Value = _PBrake
		
		-- Reintroduce touch controls
		if _Tune.Mobile then
			GuiService.TouchControlsEnabled = true
		end
		
		-- Remove for the client
		script.Parent:Destroy()
	end
end)

--[[Controls]]
local _CTRL = _Tune.Controls
local Controls = Instance.new("Folder",script.Parent)
Controls.Name = "Controls"
for i,v in _CTRL do
	local a=Instance.new("StringValue",Controls)
	a.Name=i
	a.Value=v.Name
	a.Changed:connect(function()
		if i=="MouseThrottle" or i=="MouseBrake" then
			if a.Value == "MouseButton1" or a.Value == "MouseButton2" then
				_CTRL[i]=Enum.UserInputType[a.Value]
			else
				_CTRL[i]=Enum.KeyCode[a.Value]
			end
		else
			_CTRL[i]=Enum.KeyCode[a.Value]
		end
	end)
end

--Deadzone Adjust
local _PPH = _Tune.Peripherals
	for i,v in _PPH do
	local a = Instance.new("IntValue",Controls)
	a.Name = i
	a.Value = v
	a.Changed:connect(function() 
		a.Value=math.min(100,math.max(0,a.Value))
		_PPH[i] = a.Value
	end)
end

function GetCenter()
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	for i,v in Wheels do
		if not v:IsA("BasePart") then continue end
		if v.Name=="FL" or v.Name=="FR" or v.Name=="F" then
			centerF = centerF+v.CFrame.p
			countF = countF+1
		else
			centerR = centerR+v.CFrame.p
			countR = countR+1
		end
	end
	centerF = centerF/countF
	centerR = centerR/countR
	local center = CFrame.lookAt(centerR:Lerp(centerF,.5),centerF)
	return center
end

values.AutoClutch.Value = true

--Input Handler
function DealWithInput(input,IsRobloxFunction)
	if (UserInputService:GetFocusedTextBox()==nil) and not _InControls then --Ignore when UI Focus
		--Shift Down [Manual Transmission]
		if (input.KeyCode ==_CTRL["ContlrShiftDown"] or (_MSteer and input.KeyCode==_CTRL["MouseShiftDown"]) or ((not _MSteer) and input.KeyCode==_CTRL["ShiftDown"])) and ((_IsOn and ((_TMode=="Auto" and _CGear<=1) and _Tune.AutoShiftVers == "New") or _TMode=="Semi") or _TMode=="Manual") and input.UserInputState == Enum.UserInputState.Begin then
			if not _ShiftDn then _ShiftDn = true end
			
		--Shift Up [Manual Transmission]
		elseif (input.KeyCode ==_CTRL["ContlrShiftUp"] or (_MSteer and input.KeyCode==_CTRL["MouseShiftUp"]) or ((not _MSteer) and input.KeyCode==_CTRL["ShiftUp"])) and ((_IsOn and ((_TMode=="Auto" and _CGear<1) and _Tune.AutoShiftVers == "New") or _TMode=="Semi") or _TMode=="Manual") and input.UserInputState == Enum.UserInputState.Begin then
			if not _ShiftUp then _ShiftUp = true end
			
		--Toggle Clutch
		elseif (input.KeyCode ==_CTRL["ContlrClutch"] or (_MSteer and input.KeyCode==_CTRL["MouseClutch"]) or ((not _MSteer) and input.KeyCode==_CTRL["Clutch"])) and _TMode=="Manual" then
			if input.UserInputState == Enum.UserInputState.Begin then
				_ClPressing = true
				_PlayerClutch = true
			elseif input.UserInputState == Enum.UserInputState.End then
				_ClPressing = false
				_PlayerClutch = false
			end
			
		--Toggle PBrake
		elseif input.KeyCode ==_CTRL["ContlrPBrake"] or (_MSteer and input.KeyCode==_CTRL["MousePBrake"]) or ((not _MSteer) and input.KeyCode==_CTRL["PBrake"]) or ((not _MSteer) and input.KeyCode==_CTRL["PBrake2"]) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_PBrake = not _PBrake
			elseif input.UserInputState == Enum.UserInputState.End then
				if car.DriveSeat.AssemblyLinearVelocity.Magnitude>5 then _PBrake = false end
			end
			
		--Toggle Transmission Mode
		elseif (input.KeyCode == _CTRL["ContlrToggleTMode"] or input.KeyCode==_CTRL["ToggleTransMode"]) and input.UserInputState == Enum.UserInputState.Begin then
			local n=1
			for i,v in _Tune.TransModes do
				if v==_TMode then n=i break end
			end
			n=n+1
			if n>#_Tune.TransModes then n=1 end
			_TMode = _Tune.TransModes[n]
			
		--Throttle
		elseif ((not _MSteer) and (input.KeyCode==_CTRL["Throttle"] or input.KeyCode == _CTRL["Throttle2"])) or ((((_CTRL["MouseThrottle"]==Enum.UserInputType.MouseButton1 or _CTRL["MouseThrottle"]==Enum.UserInputType.MouseButton2) and input.UserInputType == _CTRL["MouseThrottle"]) or input.KeyCode == _CTRL["MouseThrottle"])and _MSteer) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IThrot = 1
			else
				_IThrot = 0
			end
			
		--Brake
		elseif ((not _MSteer) and (input.KeyCode==_CTRL["Brake"] or input.KeyCode == _CTRL["Brake2"])) or ((((_CTRL["MouseBrake"]==Enum.UserInputType.MouseButton1 or _CTRL["MouseBrake"]==Enum.UserInputType.MouseButton2) and input.UserInputType == _CTRL["MouseBrake"]) or input.KeyCode == _CTRL["MouseBrake"])and _MSteer) then
			if input.UserInputState == Enum.UserInputState.Begin then
				_IBrake = 1
			else
				_IBrake = 0
			end
			
		--Steer Left
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
			
		--Steer Right
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
			
		--Toggle Mouse Controls
		elseif input.KeyCode ==_CTRL["ToggleMouseDrive"] then
			if input.UserInputState == Enum.UserInputState.End then
				_MSteer = not _MSteer
				_IThrot = 0
				_IBrake = 0
				_GSteerT = 0
			end
			
		--Toggle TCS and ESC
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
		
		--Toggle ABS
		elseif _Tune.ABSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleABS"] or input.KeyCode == _CTRL["ContlrToggleABS"]) then
			if input.UserInputState == Enum.UserInputState.End then _ABS = not _ABS end
			
		--Toggle CS
		elseif _Tune.CSEnabled and _IsOn and (input.KeyCode == _CTRL["ToggleCS"] or input.KeyCode == _CTRL["ContlrToggleCS"]) then
			if input.UserInputState == Enum.UserInputState.End then _CS = not _CS end
			
		end
		
		--Variable Controls
		if input.UserInputType and input.UserInputType.Name:find("Gamepad") then
			--Gamepad Steering
			if input.KeyCode == _CTRL["ContlrSteer"] then
				if input.Position.X>= 0 then
					local cDZone = math.min(.99,_Tune.Peripherals.ControlRDZone/100)
					if math.abs(input.Position.X)>cDZone then
						_GSteerT = (input.Position.X-cDZone)/(1-cDZone)
					else
						_GSteerT = 0
					end
				else
					local cDZone = math.min(.99,_Tune.Peripherals.ControlLDZone/100)
					if math.abs(input.Position.X)>cDZone then
						_GSteerT = (input.Position.X+cDZone)/(1-cDZone)
					else
						_GSteerT = 0
					end
				end
				
			--Gamepad Throttle
			elseif input.KeyCode == _CTRL["ContlrThrottle"] then
				_IThrot = math.max(0,input.Position.Z)
				
			--Gamepad Brake
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

UserInputService.InputBegan:connect(DealWithInput)
UserInputService.InputChanged:connect(DealWithInput)
UserInputService.InputEnded:connect(DealWithInput)
if VirtualInputEnabled then
	VirtualInput.Event:Connect(DealWithInput)
end

function DealWithMobileInput()
	local mobile = script.Parent.Mobile
	
	mobile.Jump.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		player.Character:FindFirstChildWhichIsA("Humanoid").Jump = true
	end)
	
	mobile.ModeSwitch.MouseButton1Click:Connect(function()
		_MobileMode = _MobileModes[(table.find(_MobileModes, _MobileMode) or 0) + 1]
		if not _MobileMode then
			_MobileMode = _MobileModes[1]
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
			if _MobileMode == "Tilt" then
				_GSteerT = -math.clamp(rotation.Position.Z*2, -1, 1)
			end
		end)
	end
end
if _Tune.Mobile then
	DealWithMobileInput()
end

--[[Drivetrain Initialize]]
local Drive={}

--Power Front Wheels
	if _Tune.Config == "FWD" or _Tune.Config == "AWD" then for i,v in Wheels do if v.Name=="FL" or v.Name=="FR" or v.Name=="F" then table.insert(Drive,v) end end end

--Power Rear Wheels
	if _Tune.Config == "RWD" or _Tune.Config == "AWD" then for i,v in Wheels do if v.Name=="RL" or v.Name=="RR" or v.Name=="R" then table.insert(Drive,v) end end end
	
--Don't use _Tune.Config for this, because this is not a runtime event

--Determine Wheel Size
local wDia = 0 for i,v in Drive do if v.Size.Y>wDia then wDia = v.Size.Y end end

--[[Throttle and Brake Input Smoothing]]
function Inputs(dt)
	local deltaTime = (60/(1/dt))
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

--[[Steering]]
if _Tune.SteeringType == "Auto" then -- We already set it to _Tune.SteerInner and _Tune.SteerOuter in the beginning of the script, so this is just here for Auto --#--
	SteerOuter = (_Tune.LockToLock*180)/_Tune.SteerRatio
	SteerInner = math.min(SteerOuter-(SteerOuter*(1-_Tune.Ackerman)),SteerOuter*1.2)
end

function Steering(dt)
	local deltaTime = (60/(1/dt))
	local controller = _LastInputWasGamepad or (_Tune.MSteerUsesContlr and _MSteer or false)
	local SteerSpeed = controller and (_Tune.ContlrSteerSpeed>0 and _Tune.ContlrSteerSpeed or _Tune.Steerspeed) or _Tune.SteerSpeed * (1-math.min(car.DriveSeat.AssemblyLinearVelocity.Magnitude/(Units.Velocity_mdivs/3.6)/_Tune.SteerSpeedDecay,1-(_Tune.MinSteerSpeed/100)))
	local ReturnSpeed = controller and (_Tune.ContlrReturnSpeed>0 and _Tune.ContlrReturnSpeed or _Tune.ReturnSpeed) or _Tune.ReturnSpeed * (1-math.min(car.DriveSeat.AssemblyLinearVelocity.Magnitude/(Units.Velocity_mdivs/3.6)/_Tune.SteerSpeedDecay,1-(_Tune.MinSteerSpeed/100)))
	
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
	
	--Interpolate Steering
	if math.abs(_GSteerT) < _Tune.CSSteerThresh/100 and _CS and values.Velocity.Value.Magnitude * (Units.Length_mm/1000) * 3.6 > _Tune.CSSpeedThresh then
		_CSAmt = (_Center:VectorToObjectSpace(values.Velocity.Value):Dot(Vector3.new(1, 0, 0))/math.max(values.Velocity.Value.Magnitude * (Units.Length_mm/1000) * 3.6, _Tune.CSSpeedThresh)) * (_Tune.CSAmt/100)
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
	
	--Steer Decay Multiplier
	local sDecay = (1-math.min(car.DriveSeat.AssemblyLinearVelocity.Magnitude/(Units.Velocity_mdivs/3.6)/(_Tune.SteerDecay/(Units.Velocity_mdivs/3.6)),1-(_Tune.MinSteer/100)))
	local rsDecay = (1-math.min(car.DriveSeat.AssemblyLinearVelocity.Magnitude/(Units.Velocity_mdivs/3.6)/(_Tune.RSteerDecay/(Units.Velocity_mdivs/3.6)),1-(_Tune.MinSteer/100)))
	
	--Apply Steering
	for i,v in Wheels do
		local angle = 0
		local rsteerVariableAngle = 1
		if v.Name == "FL" then
			angle = (_GSteerC<0 and SteerInner or SteerOuter)*sDecay
		elseif v.Name == "FR" then
			angle = (_GSteerC<0 and SteerOuter or SteerInner)*sDecay
		elseif v.Name == "F" then
			angle = SteerInner*sDecay
		elseif v.Name == "RL" then
			angle = (_GSteerC<0 and RSteerInner or RSteerOuter)*rsDecay
		elseif v.Name == "RR" then
			angle = (_GSteerC<0 and RSteerOuter or RSteerInner)*rsDecay
		elseif v.Name == "R" then
			angle = RSteerInner*rsDecay
		end
		if v.Name == "RL" or v.Name == "RR" or v.Name == "R" then	
			if _Tune.FWSteer == "Static" then
				rsteerVariableAngle = -math.max(0,1-(car.DriveSeat.Velocity.Magnitude/_Tune.RSteerSpeed))
			elseif _Tune.FWSteer == "Speed" then
				rsteerVariableAngle = math.min(1,(car.DriveSeat.Velocity.Magnitude/_Tune.RSteerSpeed))
			elseif _Tune.FWSteer == "Both" then
				rsteerVariableAngle = -math.max(-1,1-(car.DriveSeat.Velocity.Magnitude/_Tune.RSteerSpeed))
			end
		end
		
		if v.Arm:FindFirstChild("Steer") then
			if _Tune.PowerSteeringType == "New" then
				v.Arm.Steer.Attachment0.Orientation = Vector3.new(0, _GSteerC*angle*rsteerVariableAngle, 0)
			else
				v.Arm.Steer.CFrame = v.Base.CFrame * (v:GetAttribute("SteerDisabled") and CFrame.new(0,0,0) or (CFrame.Angles(0, -math.rad(_GSteerC*angle*rsteerVariableAngle), 0)))
			end
		end
	end
end

--[[Engine]]
local fFD = _Tune.FinalDrive*_Tune.FDMult
local fFDr = fFD*30/math.pi
local cGrav = (_Tune.GravComp > 0 and _Tune.GravComp or workspace.Gravity)*_Tune.InclineComp/35
local wDRatio = wDia*math.pi/60
local cfWRot = CFrame.Angles(math.pi/2,-math.pi/2,0)
local cfYRot = CFrame.Angles(0,math.pi,0)

--Electric Only Setup
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

--Powertrain
task.wait()

--Automatic Transmission
function Auto()
	local maxSpin=0
	for i,v in Drive do if _WheelSpeeds[v.Name]>maxSpin then maxSpin = _WheelSpeeds[v.Name] end end
	if _IsOn then
		if _Tune.AutoShiftVers == "Old" and _CGear == 0 then _CGear = 1 _ClPressing = false end
		if _CGear >= 1 then
			if (_CGear==1 and _InBrake > 0 and car.DriveSeat.AssemblyLinearVelocity.Magnitude < 5) and _Tune.AutoShiftVers == "Old" then
				_CGear = -1 _ClPressing = false
			elseif car.DriveSeat.AssemblyLinearVelocity.Magnitude > 5 and _Tune.ClutchType ~= "CVT" then
				if _Tune.AutoShiftMode == "RPM" then
					if _RPM>(_Tune.ShiftRPM+_Tune.AutoUpThresh) then
						if not _ShiftUp and not _Shifting then _ShiftUp = true end
					elseif math.max(math.min(maxSpin*_Tune.Ratios[_CGear+1]*fFDr,_Tune.Redline+100),0)<(_Tune.ShiftRPM-_Tune.AutoDownThresh) and _CGear>1 then
						if not _ShiftDn and not _Shifting then _ShiftDn = true end 
					end
				else
					if car.DriveSeat.AssemblyLinearVelocity.Magnitude > math.ceil(wDRatio*(_Tune.ShiftRPM+_Tune.AutoUpThresh)/_CurrentRatio/fFD) then
						if not _ShiftUp and not _Shifting then _ShiftUp = true end
					elseif car.DriveSeat.AssemblyLinearVelocity.Magnitude < math.ceil(wDRatio*(_Tune.ShiftRPM-_Tune.AutoDownThresh)/_Tune.Ratios[_CGear+1]/fFD) and _CGear>1 then
						if not _ShiftDn and not _Shifting then _ShiftDn = true end
					end
				end
			end
		else
			if (_InThrot > 0 and car.DriveSeat.AssemblyLinearVelocity.Magnitude < 5) and _Tune.AutoShiftVers == "Old" then
				_CGear = 1 _ClPressing = false
			end
		end
	end 
end

function Gear()
	local maxSpin=0
	for i,v in Drive do if _WheelSpeeds[v.Name]>maxSpin then maxSpin = _WheelSpeeds[v.Name] end end
	if _ShiftUp and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or (_TMode == "Manual" and _Tune.ClutchRel and (_InThrot>0)) or _CGear == #_Tune.Ratios-2 or (_TMode ~= "Manual" and not _IsOn) then _ShiftUp = false return end
		local NextGear = math.min(_CGear+3,#_Tune.Ratios)
		if _TMode~="Manual" and _Tune.ClutchType ~= "CVT" then
			_Shifting = true
			if _CGear>0 then 
				if _Tune.AutoShiftType=="DCT" then 
					task.wait(_Tune.ShiftUpTime)
				elseif _Tune.AutoShiftType=="Rev" then
					repeat RunService.Heartbeat:Wait() until _RPM<=math.max(math.min(maxSpin*_Tune.Ratios[NextGear]*fFDr,_Tune.Redline-_Tune.RevBounce),_Tune.IdleRPM) or not _IsOn or _ShiftDn 
				end
			end
		end
		_ShiftUp = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then return end
		if NextGear >= 4 and _Tune.ClutchType == "CVT" then return end  -- make sure it cannot go past 1st gear
		_CGear = math.min(_CGear+1,#_Tune.Ratios-2)
		if _TMode ~= "Manual" or (_TMode == "Manual" and _CGear == 1) and _IsOn then _ClPressing = false end
	end
	if _ShiftDn and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or _CGear == -1 or (_TMode ~= "Manual" and not _IsOn) then _ShiftDn = false return end
		local PrevGear = math.min(_CGear+1,#_Tune.Ratios)
		if _TMode~="Manual" then
			_Shifting = true
			if _CGear>1 then 
				if _Tune.AutoShiftType=="DCT" then 
					task.wait(_Tune.ShiftDnTime)
				elseif _Tune.AutoShiftType=="Rev" then
					repeat RunService.Heartbeat:Wait() until _RPM>=math.max(math.min(maxSpin*_Tune.Ratios[PrevGear]*fFDr,_Tune.Redline-_Tune.RevBounce),_Tune.IdleRPM) or not _IsOn or _ShiftUp
				end
			end
		end
		_ShiftDn = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then return end
		_CGear = math.max(_CGear-1,-1)
		if _TMode ~= "Manual" or (_TMode == "Manual" and _CGear == -1) and _IsOn then _ClPressing = false end
	end
end

_GoalRPM=0
tqTCS = 1
_StallOK = false
ticc = tick()

--Power calculation prerequesites
local function f(m, n, p, q, M, b, x)
	return math.clamp(M - ( (q-n)/(b^p-b^m) * (b^x-b^m) + n ), 0, M)
end

--Apply Power
function Engine(dt)
	local deltaTime = (60/(1/dt))
	
	local maxSpin=0
	local maxCount=0
	local revThrot=_GThrot
	for i,v in Drive do maxSpin = maxSpin + _WheelSpeeds[v.Name] maxCount = maxCount + 1 end
	maxSpin=maxSpin/maxCount
	local _WheelRPM = maxSpin*_CurrentRatio*fFDr
	
	--CVT
	if _Tune.ClutchType == "CVT" then
		_CVTRatio = math.clamp((_Tune.CVTRPM*_GThrot)/(maxSpin*fFDr), _Tune.CVTMinRatio, _Tune.CVTMaxRatio)
	end

	--Update ratio
	_CurrentRatio = _Tune.ClutchType == "CVT" and _CVTRatio or _Tune.Ratios[_CGear+2]
	_spLimit = _Tune.Redline/(fFDr*_CurrentRatio)
	if _CurrentRatio*fFDr == 0 then
		_spLimit = 0
	end -- Prevents [nan] from dividing by 0
	
	--Flywheel/clutch-dumping
	_FlywheelEnergy = math.max((_RPM-_WheelRPM)*_Tune.DumpMult,0) * (1-_Clutch) * 1.356*Units.Torque_nm
	
	--Determine RPM
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
		if values.AutoClutch.Value then
			_Clutch = 1 
		end
		_GThrot = 0
	end

	if ((_ClPressing and _CGear == 0) or (_PlayerClutch and _CGear ~= 0)) and _Tune.NeutralLimit then
		if (_CGear == 0 and not _Tune.LimitClutch) or _Tune.LimitClutch then
			goalMax = _Tune.NeutralRevRPM
		end
	end
	
	-- Rev limiter/speed limiter
	if _RPM >= _Tune.Redline then
		revLimiting = true
	elseif _RPM < goalMax-_Tune.RevBounce then
		revLimiting = false
	end
	if revLimiting then
		_GThrot = _Tune.IdleThrottle/100
	end
	
	local limit = (_CGear<0 and _Tune.ReverseSpeed or _Tune.SpeedLimit)
	if limit > 0 then
		_GThrot = math.min(_GThrot, math.max(1 - math.clamp(( (values.Velocity.Value.Magnitude/(Units.Velocity_mdivs/3.6)) - (limit-_Tune.SLimitGradient) )/_Tune.SLimitGradient, 0, 1), _Tune.IdleThrottle/100))
		if _Tune.SLimitBrake then
			_GBrake = math.max(_GBrake, math.clamp( (values.Velocity.Value.Magnitude/(Units.Velocity_mdivs/3.6) - limit)/_Tune.SLimitGradient, 0, 1))
		end
	end

	-- Idle
	if _RPM<_Tune.IdleRPM and _IsOn then
		_GThrot = math.max(_GThrot, math.clamp((_Tune.IdleRPM-_RPM)/_Tune.IdleDamping, 0, 1))
	end
	
	if (_Tune.Engine or _Tune.Electric) and (not script.Parent.IsOn.Starting.Value) then
		_GoalRPM = math.clamp(_RPM - (_Tune.RevDecay*deltaTime) + (_Tune.RevAccel*revThrot*deltaTime) - (math.clamp(math.max(_RPM-_Tune.IdleRPM,0)/math.max(_Tune.Redline-_Tune.IdleRPM,1),0,1)*_Tune.RevDecayRPM*deltaTime), goalMin, goalMax)
	end

	--Starting
	if script.Parent.IsOn.Starting.Value then
		_GoalRPM = math.clamp(_GoalRPM + _Tune.IgnitionAccel * deltaTime, 0, math.max(_Tune.IgnitionRPM, _WheelRPM))
		script.Parent.IsOn.Value = _GoalRPM > _Tune.IgnitionMinRPM
	end
	
	--Set RPM
	local aRPM = math.max(_GoalRPM*_Clutch + _WheelRPM*(1-_Clutch), revMin)
	local clutchP = math.min(math.abs(aRPM-_RPM) / (_Tune.Flywheel*deltaTime), .9)
	if _ClPressing then clutchP = 0 end
	_RPM = _RPM*clutchP + aRPM*(1-clutchP)
	
	if _Tune.OverRev == false and _RPM > _Tune.Redline then _RPM = _Tune.Redline end

	if _RPM<=(_Tune.IdleRPM/4) and _StallOK and (tick()-ticc>=0.2) and _Tune.Stall then script.Parent.IsOn.Value = false end
	
	--Clutch
	if _Shifting or _CGear == 0 then
		_ClPressing = true
		_Clutch = 1
		_StallOK = false
	end

	if _Tune.Clutch then
		if values.AutoClutch.Value then
			if _Tune.ClutchType == "Clutch" or _Tune.ClutchType == "CVT" then
				if _ClPressing then _ClutchKick = 1 end
				_ClutchKick = _ClutchKick*(_Tune.ClutchEngage/100)		
				local ClRPMInfluence = math.max(_RPM*_Tune.ClutchRPMMult/_Tune.Redline,0)
				if _Tune.ClutchMode == "New" then ClRPMInfluence = 0 end
				_ClutchModulate = math.min(((((script.Parent.Values.Velocity.Value.Magnitude/(Units.Velocity_mdivs/3.6)/_Tune.SpeedEngage)/math.abs(_CGear)) + ClRPMInfluence) - _ClutchKick), 1)
			elseif _Tune.ClutchType == "TorqueConverter" and _Tune.TQLock then
				if (_GThrot<=_Tune.IdleThrottle/100 and script.Parent.Values.Velocity.Value.Magnitude/(Units.Velocity_mdivs/3.6)<_Tune.SpeedEngage) or (_GThrot>_Tune.IdleThrottle/100 and (_RPM < _Tune.RPMEngage and _WheelRPM < _Tune.RPMEngage)) then
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
		_StallOK = (_Clutch<=0.01) or _StallOK
	else
		_StallOK = false
		if not _ClPressing and not _Shifting then _Clutch = 0 else _Clutch = 1 end
	end
	
	-- Things that apply the clutch
	if values.AutoClutch.Value and (script.Parent.IsOn.Starting.Value or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM and _IThrot < .1) or (revLimiting and _Tune.OverRev == false)) then
		_Clutch = 1
	end
	
	-- Torque calculations (Detomiks)
	-- What you see here is mostly just ported over from Desmos.
	if (not engine) or _Tune.CustomEngineCalculations == false then
		local x = _RPM/1000
		local NTorque = 0
		local ETorque = 0
		local TTorque = 0
		local STorque = 0
		if _Tune.Engine then
			local NIdleTorque = f(_Tune.IdleRPM/1000, _Tune.IdleTorque, _Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.PeakTorque, _Tune.IdleTorqueCurve, x)
			local NRedlineTorque = f(_Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.Redline/1000, _Tune.RedlineTorque, _Tune.PeakTorque, 1/_Tune.RedlineTorqueCurve, x)
			local VVL = _Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, x)
			local AirPressurePercent = math.exp((-9.80665 * 0.0289644 * (_Center.Position.Y * Units.Length_mm / 1000)) / (8.3142 * ((workspace:GetAttribute("GlobalTemperature") or 22) + 273.15))) -- look up the barometric formula --#--
			NTorque = boolToNum[_Tune.Engine] * (_Tune.PeakTorque - NIdleTorque - NRedlineTorque + VVL) * AirPressurePercent
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
			ETorque = boolToNum[_Tune.Electric] * (_Tune.E_Torque - f(_Tune.E_TransitionRPM/1000, _Tune.E_Torque, _Tune.E_Redline/1000, _Tune.E_RedlineTorque, _Tune.E_Torque, _Tune.E_Curve, x))
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
	local iComp = (_Center.LookVector.Y)*cGrav
	if _CGear==-1 then iComp=-iComp end
	_OutTorque = _OutTorque*math.max(1,(1+iComp))
	
	--Update Wheels
	for i,v in Wheels do
		--Reference Wheel Orientation
		local Ref=(CFrame.new(v.Position-((v.Arm.CFrame*cfWRot).lookVector),v.Position)*cfYRot).lookVector
		local aRef=1
		local RRdiffMult=1
		local RLdiffMult=1
		local FRdiffMult=1
		local FLdiffMult=1
		if v.Name=="FL" or v.Name=="RL" then aRef=-1 end
		
		--Differential/Torque-Vectoring
		if v.Name=="FR" then
			local avg=((_WheelSpeeds[v.Name]/_WheelSpeeds["FL"])-1)*(_Tune.FDiffPreload/10)
			FRdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.FDiffPower/100)*avg*_GThrot) + ((_Tune.FDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
			FLdiffMult=2-FRdiffMult
		elseif v.Name=="FL" then
			local avg=((_WheelSpeeds[v.Name]/_WheelSpeeds["FR"])-1)*(_Tune.FDiffPreload/10)
			FLdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.FDiffPower/100)*avg*_GThrot) + ((_Tune.FDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
			FRdiffMult=2-FLdiffMult
		elseif v.Name=="RR" then
			local avg=((_WheelSpeeds[v.Name]/_WheelSpeeds["RL"])-1)*(_Tune.RDiffPreload/10)
			RRdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.RDiffPower/100)*avg*_GThrot) + ((_Tune.RDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
			RLdiffMult=2-RRdiffMult
		elseif v.Name=="RL" then
			local avg=((_WheelSpeeds[v.Name]/_WheelSpeeds["RR"])-1)*(_Tune.RDiffPreload/10)
			RLdiffMult=math.ceil(math.max(0,math.min(2,1-( ((_Tune.RDiffPower/100)*avg*_GThrot) + ((_Tune.RDiffCoast/100)*avg*(1-_GThrot)))))*100)/100
			RRdiffMult=2-RLdiffMult
		end
		--Limit values to prevent physics death
		if RRdiffMult > 2 then RRdiffMult = 2 elseif RRdiffMult < 0 then RRdiffMult = 0 end
		if RLdiffMult > 2 then RLdiffMult = 2 elseif RLdiffMult < 0 then RLdiffMult = 0 end
		if FRdiffMult > 2 then FRdiffMult = 2 elseif FRdiffMult < 0 then FRdiffMult = 0 end
		if FLdiffMult > 2 then FLdiffMult = 2 elseif FLdiffMult < 0 then FLdiffMult = 0 end
		
		--Output
	
		--Apply Power
		local on=1
		if not script.Parent.IsOn.Value then on=0 end
		local throt = _GThrot
		local brake = _GBrake
		local clutch=1
		if _ClPressing or (values.AutoClutch.Value and (script.Parent.IsOn.Starting.Value or (_Tune.RemoveCreep and _RPM < _Tune.IdleRPM and _IThrot < .1))) then clutch=0 end --for some reason, the car still creeps forward when starting the car if i don't do this
		local tq = _OutTorque
		
		--Apply ESC
		local tqESC = 0
		if not (v.Name == "F" or v.Name == "R") and _ESC then
			local g = (car.Body["#Weight"].CFrame:VectorToObjectSpace(values.Acceleration.Value/(Units.Velocity_mdivs)/((_Tune.GravComp>0 and _Tune.GravComp or workspace.Gravity)*(Units.Length_mm/1000))))
			local diff = (_GSteerC-(g.X*-math.sign(_Center:VectorToObjectSpace(values.Velocity.Value).Z)))
			if (math.abs(diff) > _Tune.ESCThreshold) and (values.Velocity.Value.Magnitude/(Units.Velocity_mdivs/3.6)) > _Tune.ESCSpeed and (math.sign(_GSteerC) ~= math.sign(g.X)) then
				local escVector, escBias = 1, (_Tune.ESCVector+1)
				if string.find(v.Name,"F") then escVector = escVector*(2-escBias)
				elseif string.find(v.Name,"R") then escVector = escVector*escBias end
				 
				tqESC = (string.find(v.Name, "L") and 1 or -1) * math.sign(diff)*escVector
				throt = throt + (math.max(tqESC,0) - throt) * (_Tune.ESCThrottle/100)
				brake = brake + (-math.min(tqESC,0) - brake) * (_Tune.ESCBrake/100)
			end
		end
		if tqESC ~= 0 then
			_ESCActive = true
		end
		_ESCTracker[v.Name] = tqESC
		
		--Apply ABS
		local tqABS = 1
		if _ABS and brake>0 then
			tqABS = 1-(math.min(math.max(0,math.abs(v.RotVelocity.Magnitude*(v.Size.Y/2)/(Units.Velocity_mdivs/3.6) - v.Velocity.Magnitude/(Units.Velocity_mdivs/3.6))-_Tune.ABSThreshold)/_Tune.ABSGradient,1)*(1-(_Tune.ABSLimit/100)))
		end
		if tqABS<1 then
			_ABSActive = true
		end
		_ABSTracker[v.Name] = 1 - tqABS
	
		local PBrakeV=0
		if _PBrake==true then PBrakeV=1 else PBrakeV=0 end
		
		local driven = (table.find(Drive, v) ~= nil) and ((_Tune.Config == "FWD" and string.find(v.Name, "F")) or (_Tune.Config == "RWD" and string.find(v.Name, "R")) or _Tune.Config == "AWD")
		if driven then
			--Apply torque split
			-- This takes the total amount of torque alotted to the front or rear wheels, then divides it by how many wheels there are
			local bias = (_TorqueVector+1) / 2
			if _Tune.Config == "AWD" then -- What if there are more front wheels than rear wheels or vice versa?? --#--
				bias = (_TorqueVector+1) / 2
			elseif _Tune.Config == "FWD" then
				bias = 0
			elseif _Tune.Config == "RWD" then
				bias = 1
			end
			local frontTorque = (tq * (1 - bias))
			local rearTorque = (tq * bias)
			if string.find(v.Name, "F") then
				tq = frontTorque / FWheelCount
			else
				tq = rearTorque / RWheelCount
			end
			
			--Apply TCS
			tqTCS = 1
			if _TCS and throt>_Tune.IdleThrottle/100 then
				tqTCS = 1-(math.min(math.max(0,math.abs(v.RotVelocity.Magnitude*(v.Size.Y/2)/(Units.Velocity_mdivs/3.6) - v.Velocity.Magnitude/(Units.Velocity_mdivs/3.6))-_Tune.TCSThreshold)/_Tune.TCSGradient,1)*(1-(_Tune.TCSLimit/100)))
			end
			if tqTCS < 1 then
				_TCSActive = true
			end
			_TCSTracker[v.Name] = 1-tqTCS
			
			--Update Forces
			local tqOUT = (tq*1.356*Units.Torque_nm*(60/workspace:GetRealPhysicsFPS())*throt*tqTCS*on*clutch) + (_FlywheelEnergy/#Drive)
			if tqOUT < 0 then tqOUT = 0 elseif tqOUT > 1000000 then tqOUT = 0 end
			-- convert lb-ft to nm to roblox stuff
			-- if it reaches an absurdly high number, set it to 0 to try and prevent physics death
			
			if v.Name=='RR' then
				v["#AV"].MotorMaxTorque=tqOUT*RRdiffMult
			elseif v.Name=='RL' then
				v["#AV"].MotorMaxTorque=tqOUT*RLdiffMult
			elseif v.Name=='FR' then
				v["#AV"].MotorMaxTorque=tqOUT*FRdiffMult
			elseif v.Name=='FL' then
				v["#AV"].MotorMaxTorque=tqOUT*FLdiffMult
			else
				v["#AV"].MotorMaxTorque=tqOUT
			end
			v["#AV"].AngularVelocity = _spLimit * math.sign(_CGear)

			if string.find(v.Name,"F") then
				local force = (FBrakeForce*(60/workspace:GetRealPhysicsFPS())*brake*tqABS) + (EBrakeForce*clutch*((1-throt)*(_RPM/_Tune.Redline))) + (PBrakeForceF*PBrakeV)
				if force > 1000000 then force = 0 elseif force < 0 then force = 0 end
				v["#BV"].MotorMaxTorque = force
			else
				local force = (RBrakeForce*(60/workspace:GetRealPhysicsFPS())*brake*tqABS) + (EBrakeForce*clutch*((1-throt)*(_RPM/_Tune.Redline))) + (PBrakeForceR*PBrakeV)
				if force > 1000000 then force = 0 elseif force < 0 then force = 0 end
				v["#BV"].MotorMaxTorque = force
			end
		else--luaint edit
			v["#AV"].MotorMaxTorque=0
			v["#AV"].AngularVelocity=0
			if string.find(v.Name,"F") then
				local force = (FBrakeForce*(60/workspace:GetRealPhysicsFPS())*brake*tqABS) + (PBrakeForceF*PBrakeV)
				if force > 1000000 then force = 0 elseif force < 0 then force = 0 end
				v["#BV"].MotorMaxTorque = force
			else
				local force = (RBrakeForce*(60/workspace:GetRealPhysicsFPS())*brake*tqABS) + (PBrakeForceR*PBrakeV)
				if force > 1000000 then force = 0 elseif force < 0 then force = 0 end
				v["#BV"].MotorMaxTorque = force
			end
		end
	end
end

-- Wheel output values
function WheelOutput(dt)
	_TCSAmt = 0
	_ABSAmt = 0
	_ESCAmt = 0
	local tcsCount = 0
	local absCount = 0
	local escCount = 0
	local rot = 0
	for _, wheel in Wheels do
		-- Wheel speeds
		if not _WheelSpeedsTable[wheel.Name] then
			_WheelSpeedsTable[wheel.Name] = {}
		end
		table.insert(_WheelSpeedsTable[wheel.Name], wheel.RotVelocity.Magnitude)
		if #_WheelSpeedsTable[wheel.Name] > 8 then
			table.remove(_WheelSpeedsTable[wheel.Name], 1)
		end
		local avg = 0
		for _, a in _WheelSpeedsTable[wheel.Name] do
			avg += a
		end
		avg /= #_WheelSpeedsTable[wheel.Name]
		_WheelSpeeds[wheel.Name] = avg
		
		-- Output wheel speeds
		if not values.WheelSpeeds:FindFirstChild(wheel.Name) then
			Instance.new("NumberValue", values.WheelSpeeds).Name = wheel.Name
		end
		values.WheelSpeeds[wheel.Name].Value = _WheelSpeeds[wheel.Name] -- I'm not using the avg variable here for future-proofing if we change the calculation later and stuff
		rot += _WheelSpeeds[wheel.Name]*(wheel.Size.Y/2)
		
		-- TCS
		if _TCSTracker[wheel.Name] then
			if not values.TCSTracker:FindFirstChild(wheel.Name) then
				Instance.new("NumberValue", values.TCSTracker).Name = wheel.Name
			end
			values.TCSTracker[wheel.Name].Value = _TCSTracker[wheel.Name]
			_TCSAmt += _TCSTracker[wheel.Name]
			tcsCount += 1
		end
		
		-- ABS
		if _ABSTracker[wheel.Name] then
			if not values.ABSTracker:FindFirstChild(wheel.Name) then
				Instance.new("NumberValue", values.ABSTracker).Name = wheel.Name
			end
			values.ABSTracker[wheel.Name].Value = _ABSTracker[wheel.Name]
			_ABSAmt += _ABSTracker[wheel.Name]
			absCount += 1
		end
		
		-- ESC
		if _ESCTracker[wheel.Name] then
			if not values.ESCTracker:FindFirstChild(wheel.Name) then
				Instance.new("NumberValue", values.ESCTracker).Name = wheel.Name
			end
			values.ESCTracker[wheel.Name].Value = _ESCTracker[wheel.Name]
			_ESCAmt += math.abs(_ESCTracker[wheel.Name])
			escCount += 1
		end
	end
	-- Wheel speeds
	_AvgWheelSpeed = rot/#Wheels
	_Acceleration = (car.DriveSeat.AssemblyLinearVelocity-_OldVelocity)*(1/dt)
	_OldVelocity = car.DriveSeat.AssemblyLinearVelocity
	-- TCS
	_TCSAmt /= tcsCount
	_TCSActive = false
	-- ABS
	_ABSAmt /= absCount
	_ABSActive = false
	-- ESC
	_ESCAmt /= escCount
	_ESCActive = false
end

--Mobile
function Mobile()
	if _Tune.Mobile then
		local mobile = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
		script.Parent.Mobile.Visible = mobile
		script.Parent.Mobile.ModeSwitch.Visible = car.DriveSeat.AssemblyLinearVelocity.Magnitude < 5
		script.Parent.Mobile.ModeSwitch.Text = _MobileMode
		script.Parent.Mobile.Jump.Visible = script.Parent.Mobile.ModeSwitch.Visible
		if mobile then
			_Tune.AutoShiftVers = "Old"
			_TMode = "Auto"
		else
			_Tune.AutoShiftVers = autoshiftvers
		end
		for _, v in script.Parent.Mobile:GetChildren() do
			if v.ClassName ~= "Frame" then continue end
			v.Visible = _MobileMode == v.Name
		end
	end
end

--[[Flip]]
function Flip()
	--Detect Orientation
	if (car.DriveSeat.CFrame*CFrame.Angles(math.pi/2,0,0)).lookVector.y > .1 or FlipDB then
		FlipWait=tick()
		
	--Apply Flip
	else
		if tick()-FlipWait>=3 then
			FlipDB=true
			if _Tune.FlipType == "New" then
				local gyro = car.DriveSeat.Flip
				gyro.Enabled = true
				task.wait(1)
				gyro.Enabled = false
			else
				local gyro = car.DriveSeat.Flip
				gyro.maxTorque = Vector3.new(10000,0,10000)
				gyro.P=3000
				gyro.D=500
				task.wait(1)
				gyro.maxTorque = Vector3.new(0,0,0)
				gyro.P=0
				gyro.D=0
			end
			FlipDB=false
		end
	end
end

--[[Run]]

--Print Version
local ver=require(car["A-Chassis Tune"].README)
print("A-Chassis, Version "..ver)

--Runtime Loops
RunService.Heartbeat:Connect(function(dt)
	--Update Internal Values
	_IsOn = script.Parent.IsOn.Value
	_InControls = script.Parent.ControlsOpen.Value
	_LastInputWasGamepad = string.find(UserInputService:GetLastInputType().Name, "Gamepad") and true or false
	_Center = GetCenter()
	
	--Update External Values
	-- Transmission
	values.Clutch.Value = _Clutch
	values.Gear.Value = _CGear
	values.TransmissionMode.Value = _TMode
	values.CurrentRatio.Value = _CurrentRatio
	values.RPM.Value = _RPM
	-- Boost
	values.Boost.Value = _TBoost + _SBoost
	values.BoostTurbo.Value = _TBoost
	values.BoostSuper.Value = _SBoost
	-- Horsepower
	values.HpNatural.Value = _NH
	values.HpElectric.Value = _EH
	values.HpTurbo.Value = _TH
	values.HpSuper.Value = _SH
	values.HpBoosted.Value = _BH
	values.Horsepower.Value = _HP
	-- Torque
	values.TqNatural.Value = _NT
	values.TqElectric.Value = _ET
	values.TqTurbo.Value = _TT
	values.TqSuper.Value = _ST
	values.TqBoosted.Value = _BT
	values.Torque.Value = _TQ
	-- Inputs
	values.Throttle.Value = _GThrot
	values.InputThrottle.Value = _IThrot
	values.Brake.Value = _GBrake
	values.InputBrake.Value = _IBrake
	values.SteerC.Value = _GSteerC
	values.SteerT.Value = _GSteerT
	values.MouseSteerOn.Value = _MSteer
	values.PBrake.Value = _PBrake
	-- Velocity
	values.Velocity.Value = car.DriveSeat.AssemblyLinearVelocity
	values.AverageRotSpeed.Value = _AvgWheelSpeed
	values.Acceleration.Value = _Acceleration
	-- Misc
	values.Center.Value = _Center
	values.TCS.Value = _TCS
	values.TCSActive.Value = _TCSActive
	values.TCSAmt.Value = _TCSAmt
	values.ABS.Value = _ABS
	values.ABSActive.Value = _ABSActive
	values.ABSAmt.Value = _ABSAmt
	values.ESC.Value = _ESC
	values.ESCActive.Value = _ESCActive
	values.ESCAmt.Value = _ESCAmt
	values.CS.Value = _CS
	values.CSActive.Value = _CSActive
	values.CSAmt.Value = _CSAmt
	
	--Wheel Output
	WheelOutput(dt)
	
	--Inputs
	Inputs(dt)

	--Steering
	Steering(dt)

	--Gear
	Gear()

	--Power
	Engine(dt)

end)

while task.wait(1/24) do -- Runs at 24hz

	--Mobile UI
	Mobile()

	--Automatic Transmission
	if _TMode == "Auto" then Auto() end

	--Flip
	if _Tune.AutoFlip then Flip() end
	
end

--[[END]]