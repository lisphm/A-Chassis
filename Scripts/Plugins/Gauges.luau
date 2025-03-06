--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- Press "V" to cycle through gauges

local autoscaling	= true		--Estimates top speed
local Units = require(script.Parent.Parent.Car.Value["A-Chassis Tune"].README.Units)

local StartupAnimation		= true

local UNITS	= {								--Click on speed to change units
											--First unit is default	
	{
		units			= "mph"				,
		scaling			= (Units.Length_mm/1000) * 2.23693629	, -- 1 stud : 280 mm | m/s to mi/h
		maxSpeed		= 180				,
		spInc			= 20				, -- Increment between labelled notches
	},
	
	{
		units			= "km/h"			,
		scaling			= (Units.Length_mm/1000) * 3.6	, -- 1 stud : 280 mm | m/s to km/h
		maxSpeed		= 280				,
		spInc			= 30				, -- Increment between labelled notches
	},
	
	{
		units			= "sps"				,
		scaling			= 1					, -- Roblox standard
		maxSpeed		= 280				,
		spInc			= 30				, -- Increment between labelled notches
	}
}

-----------------------------------------------------------------------------------------------

local car = script.Parent.Parent.Car.Value
local values = script.Parent.Parent.Values
local _Tune = require(car:WaitForChild("A-Chassis Tune"))
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local VirtualInput: BindableEvent = script.Parent.Parent.Drive.VirtualInput
local Controls = script.Parent.Parent:WaitForChild("Controls")

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if not gameProcessedEvent then
		if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonL3 then
			script.Parent.Visible = not script.Parent.Visible
		end
	end
end)

local gauges = script.Parent.Advanced --use this if you want to add gauge modes later on
local currentUnit = 1

local _TCount = _Tune.Turbochargers
local _SCount = _Tune.Superchargers
local tboost = 0
local sboost = 0

local tachRot = 0
local speedoRot = 0
local boostRot = 0

local redlineLight = 0

local bold = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local boldItalic = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)

-- Initialize
car.DriveSeat.HeadsUpDisplay = false

if _Tune.Electric and not _Tune.Engine then
	_Tune.Redline = _Tune.E_Redline
	_Tune.ShiftRPM = _Tune.Redline
	_Tune.Turbochargers = 0
	_Tune.Superchargers = 0
end

--Automatic Gauge Scaling
if autoscaling then
	local Drive={}
	if _Tune.Config == "FWD" or _Tune.Config == "AWD" then
		if car.Wheels:FindFirstChild("FL")~= nil then
			table.insert(Drive,car.Wheels.FL)
		end
		if car.Wheels:FindFirstChild("FR")~= nil then
			table.insert(Drive,car.Wheels.FR)
		end
		if car.Wheels:FindFirstChild("F")~= nil then
			table.insert(Drive,car.Wheels.F)
		end
	end
	if _Tune.Config == "RWD" or _Tune.Config == "AWD" then
		if car.Wheels:FindFirstChild("RL")~= nil then
			table.insert(Drive,car.Wheels.RL)
		end
		if car.Wheels:FindFirstChild("RR")~= nil then
			table.insert(Drive,car.Wheels.RR)
		end
		if car.Wheels:FindFirstChild("R")~= nil then
			table.insert(Drive,car.Wheels.R)
		end
	end

	local wDia = 0
	for i,v in pairs(Drive) do
		if v.Size.Y>wDia then wDia = v.Size.Y end
	end
	Drive = nil
	for i,v in pairs(UNITS) do
		v.maxSpeed = math.ceil(v.scaling*wDia*math.pi*_Tune.Redline/60/(_Tune.ClutchType == "CVT" and _Tune.CVTMinRatio or _Tune.Ratios[#_Tune.Ratios])/_Tune.FinalDrive/_Tune.FDMult)
		v.spInc = math.max(math.ceil(v.maxSpeed/100)*10,10)
	end
end

-- Tach
local revScale = math.ceil(_Tune.Redline/12000) * 250
local revEnd = (math.ceil(_Tune.Redline/1000)*1000)/revScale
for i = 0, revEnd do
	local newln = gauges.ln:Clone()
	newln.Parent = gauges.TachBackground
	newln.Rotation = -135 + 225*(i/revEnd)
	newln.Num.Text = (i * revScale)/1000
	newln.Num.Rotation = -newln.Rotation
	if i%4 ~= 0 then
		newln.Num:Destroy()
	end
	if (i+1)%2 == 0 then
		newln.Frame.Size = UDim2.new(.005, 0, .02, 0)
	elseif (i+2)%4 == 0 then
		newln.Frame.Size = UDim2.new(.01, 0, .05, 0)
	end
	newln.Visible = true
end
local redlineRotation = ((1-_Tune.ShiftRPM/(revEnd*revScale)) * 225)
gauges.TachBackground.Redline.High.ImageLabel.Rotation = math.clamp(180-redlineRotation, 0, 180)
gauges.TachBackground.Redline.Low.ImageLabel.Rotation = math.clamp(180-redlineRotation, -45, 0)
gauges.TachBackground.Redline.High.ImageLabel.Visible = redlineRotation > 0
gauges.TachBackground.Redline.Low.ImageLabel.Visible = redlineRotation > 180
gauges.TachBackground.Redline.Alt.Rotation = 180-redlineRotation

-- Speedometer
for i, v in next, UNITS do
	local lnn = Instance.new("Frame",gauges.SpeedoBackground)
	lnn.BackgroundTransparency = 1
	lnn.BorderSizePixel = 0
	lnn.Size = UDim2.new(1,0,1,0)
	lnn.AnchorPoint = Vector2.new(.5,.5)
	lnn.Position = UDim2.new(.5, 0, .5, 0)
	lnn.Name = v.units
	if i ~= 1 then lnn.Visible = false end

	for i = 0, v.maxSpeed, v.spInc/4 do
		local ln = gauges.ln:Clone()
		ln.Parent = lnn
		ln.Rotation = -135 + 225*(i/v.maxSpeed)
		ln.Num.Text = i
		ln.Num.Size = UDim2.new(.2, 0, .07, 0)
		ln.Num.Position = UDim2.new(.5, 0, .06, 0)
		ln.Num.Rotation = -ln.Rotation
		if i%v.spInc ~= 0 then
			ln.Num:Destroy()
			if i%(v.spInc/2) == 0 then
				ln.Frame.Size = UDim2.new(.01, 0, .05, 0)
			end
		end
		ln.Visible=true
	end
end

if _TCount~=0 or _SCount~=0 then
	for i = 0, 12 do
		local newbln = gauges.bln:Clone()
		newbln.Parent = gauges.BoostBackground
		newbln.Rotation = -180 + 270*(i/12)
		newbln.Visible = true
		if i%4 ~= 0 then
			newbln.Frame.Size = UDim2.new(.03, 0, .05, 0)
		end
		newbln.Num.Text = "0"
		newbln.Num.Rotation = -newbln.Rotation
		if i ~= 4 then
			newbln.Num:Destroy()
		end
	end
else
	gauges.Boost.Visible = false
	gauges.PSI.Visible = false
	gauges.BoostBackground.Visible = false
	gauges.PSIUnit.Visible = false
end

--Unit switcher
gauges.Speed.MouseButton1Click:Connect(function()
	currentUnit += 1
	if currentUnit > #UNITS then
		currentUnit = 1
	end
	for _, v in next, gauges.SpeedoBackground:GetChildren() do
		if v:IsA("Frame") then
			v.Visible = false
		end
	end
	gauges.SpeedoBackground[UNITS[currentUnit].units].Visible = true
end)

--Auto Clutch Toggle
gauges.Gear.MouseButton1Click:Connect(function()
	values.AutoClutch.Value = not values.AutoClutch.Value
	if values.AutoClutch.Value then
		gauges.Gear.FontFace = bold
	else
		gauges.Gear.FontFace = boldItalic
	end
end)

-- Enable gauge light visibility
gauges.TCS.Visible = _Tune.TCSEnabled
gauges.ABS.Visible = _Tune.ABSEnabled
gauges.ESC.Visible = _Tune.ESCEnabled
gauges.CS.Visible = _Tune.CSEnabled
gauges.PBrake.Visible = _Tune.PBrakeForce > 0

-- VirtalInput button toggles
gauges.ABS.Button.MouseButton1Click:Connect(function()
	VirtualInput:Fire{KeyCode = Enum.KeyCode[Controls.ToggleABS.Value], UserInputState = Enum.UserInputState.End}
end)

gauges.CS.Button.MouseButton1Click:Connect(function()
	VirtualInput:Fire{KeyCode = Enum.KeyCode[Controls.ToggleCS.Value], UserInputState = Enum.UserInputState.End}
end)

gauges.ESC.Button.MouseButton1Click:Connect(function()
	VirtualInput:Fire{KeyCode = Enum.KeyCode[Controls.ToggleTCS.Value], UserInputState = Enum.UserInputState.End}
end)

gauges.TCS.Button.MouseButton1Click:Connect(function()
	VirtualInput:Fire{KeyCode = Enum.KeyCode[Controls.ToggleTCS.Value], UserInputState = Enum.UserInputState.End}
end)

gauges.PBrake.Button.MouseButton1Down:Connect(function()
	VirtualInput:Fire{KeyCode = Enum.KeyCode[Controls.PBrake.Value], UserInputState = Enum.UserInputState.Begin}
end)

gauges.PBrake.Button.MouseButton1Up:Connect(function()
	VirtualInput:Fire{KeyCode = Enum.KeyCode[Controls.PBrake.Value], UserInputState = Enum.UserInputState.End}
end)

gauges.TMode.Button.MouseButton1Click:Connect(function()
	VirtualInput:Fire{KeyCode = Enum.KeyCode[Controls.ToggleTransMode.Value], UserInputState = Enum.UserInputState.Begin}
end)

-- Startup Sweep
local starting = false
local startingPressed = false
local startAnimAlpha = 0 -- do it like this, since when we set it back to the original position, tweens make it jump to the rotation instead of smoothly
local startAnimStart = tick()
local startAnimTime = 0
local startAnimLength = .5
local startOldAlpha = 0
if StartupAnimation then
	local startupInfo = TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
	script.Parent.Parent.IsOn.Starting.Changed:Connect(function()
		if script.Parent.Parent.IsOn.Starting.Value then
			starting = true
			startingPressed = true
			startAnimStart = tick()
		else
			startingPressed = false
			startAnimStart = tick()
			startOldAlpha = startAnimAlpha
		end
	end)
end

-- Runtime loop
RunService.Heartbeat:Connect(function()
	--Starting animation values
	if StartupAnimation then
		startAnimTime = math.clamp((tick()-startAnimStart)/startAnimLength, 0, 1)
		local startAnimEquation = (math.sin(math.pi * (startAnimTime - 0.5)) + 1)/2
		if startingPressed then
			startAnimAlpha = startAnimEquation
		else
			startAnimAlpha = (1-(startAnimEquation))*startOldAlpha
			if startAnimTime == 1 then
				starting = false
			end
		end
	end
	
	--RPM
	tachRot = 225 * (values.RPM.Value/(revEnd*revScale))
	gauges.Tach.Needle.Rotation = math.max(tachRot + (225-tachRot) * startAnimAlpha, 0)
	gauges.Tach.Needle.Alt.Visible = not gauges.Tach.Needle.ImageLabel.IsLoaded
	gauges.TachBackground.Redline.Alt.Visible = not gauges.TachBackground.Redline.High.ImageLabel.IsLoaded
	--Speed
	speedoRot = 225 * ((values.Velocity.Value.Magnitude*UNITS[currentUnit].scaling)/UNITS[currentUnit].maxSpeed)
	gauges.Speedo.Needle.Rotation = math.max(speedoRot + (225-speedoRot) * startAnimAlpha, 0)
	gauges.Speedo.Needle.Alt.Visible = not gauges.Speedo.Needle.ImageLabel.IsLoaded
	gauges.Speed.Text = math.round(values.Velocity.Value.Magnitude*UNITS[currentUnit].scaling)
	gauges.Unit.Text = UNITS[currentUnit].units
	--Gear
	local gearText = values.Gear.Value
	if gearText == -1 then gearText = "R"
	elseif gearText == 0 then gearText = "N"
	elseif gearText == 1 and _Tune.ClutchType == "CVT" then gearText = "D"
	end
	gauges.Gear.Text = gearText
	gauges.Gear.TextTransparency = (values.Clutch.Value > .9 and starting == false) and .8 or 0
	local tmodetext = values.TransmissionMode.Value
	if tmodetext == "Auto" then tmodetext = "A/T"
	elseif tmodetext == "Semi" then tmodetext = "S/T"
	elseif tmodetext == "Manual" then tmodetext = "M/T"
	end
	gauges.TMode.Text = tmodetext
	--Boost
	local _T = 0
	local _S = 0
	if _TCount~=0 then _T = _Tune.T_Boost*_TCount end
	if _SCount~=0 then _S = _Tune.S_Boost*_SCount end
	tboost = (values.BoostTurbo.Value*1.2)-(_T/5)
	sboost = values.BoostSuper.Value
	boostRot = math.clamp(90 + 180*math.min(1,(tboost+sboost)/(_T+_S)), 0, 270)
	gauges.Boost.Needle.Rotation = boostRot + (270-boostRot) * startAnimAlpha
	gauges.Boost.Needle.Alt.Visible = not gauges.Boost.Needle.ImageLabel.IsLoaded
	gauges.PSI.Text = string.format("%.1f", tboost+sboost)
	--Warnings (yes I know it's not the best looking but at least its easy to understand)
	if values.TCS.Value or starting then
		if values.TCSActive.Value or starting then
			gauges.TCS.ImageColor3 = Color3.new(1,1,1)
			gauges.TCS.ImageTransparency = 0
		else
			gauges.TCS.ImageColor3 = Color3.new(0,0,0)
			gauges.TCS.ImageTransparency = .8
		end
	else
		if _Tune.TCSEnabled then
			gauges.TCS.ImageColor3 = Color3.new(1,0,0)
			gauges.TCS.ImageTransparency = 0
		else
			gauges.TCS.ImageColor3 = Color3.new(0,0,0)
			gauges.TCS.ImageTransparency = .8
		end
	end
	gauges.TCS.Alt.TextColor3 = gauges.TCS.ImageColor3
	gauges.TCS.Alt.TextTransparency = gauges.TCS.ImageTransparency
	gauges.TCS.Alt.Visible = not gauges.TCS.IsLoaded
	
	if values.ABS.Value or starting then
		if values.ABSActive.Value or starting then
			gauges.ABS.ImageColor3 = Color3.new(1,1,1)
			gauges.ABS.ImageTransparency = 0
		else
			gauges.ABS.ImageColor3 = Color3.new(0,0,0)
			gauges.ABS.ImageTransparency = .8
		end
	else
		if _Tune.ABSEnabled then
			gauges.ABS.ImageColor3 = Color3.new(1,0,0)
			gauges.ABS.ImageTransparency = 0
		else
			gauges.ABS.ImageColor3 = Color3.new(0,0,0)
			gauges.ABS.ImageTransparency = .8
		end
	end
	gauges.ABS.Alt.TextColor3 = gauges.ABS.ImageColor3
	gauges.ABS.Alt.TextTransparency = gauges.ABS.ImageTransparency
	gauges.ABS.Alt.Visible = not gauges.ABS.IsLoaded
	
	if values.ESC.Value or starting then
		if values.ESCActive.Value or starting then
			gauges.ESC.ImageColor3 = Color3.new(1,1,1)
			gauges.ESC.ImageTransparency = 0
		else
			gauges.ESC.ImageColor3 = Color3.new(0,0,0)
			gauges.ESC.ImageTransparency = .8
		end
	else
		if _Tune.ESCEnabled then
			gauges.ESC.ImageColor3 = Color3.new(1,0,0)
			gauges.ESC.ImageTransparency = 0
		else
			gauges.ESC.ImageColor3 = Color3.new(0,0,0)
			gauges.ESC.ImageTransparency = .8
		end
	end
	gauges.ESC.Alt.TextColor3 = gauges.ESC.ImageColor3
	gauges.ESC.Alt.TextTransparency = gauges.ESC.ImageTransparency
	gauges.ESC.Alt.Visible = not gauges.ESC.IsLoaded

	if values.CS.Value or starting then
		if values.CSActive.Value or starting then
			gauges.CS.ImageColor3 = Color3.new(1,.66,0)
			gauges.CS.ImageTransparency = 0
		else
			gauges.CS.ImageColor3 = Color3.new(0,0,0)
			gauges.CS.ImageTransparency = .8
		end
	else
		if _Tune.CSEnabled then
			gauges.CS.ImageColor3 = Color3.new(1,0,0)
			gauges.CS.ImageTransparency = 0
		else
			gauges.CS.ImageColor3 = Color3.new(0,0,0)
			gauges.CS.ImageTransparency = .8
		end
	end
	gauges.CS.Alt.TextColor3 = gauges.CS.ImageColor3
	gauges.CS.Alt.TextTransparency = gauges.CS.ImageTransparency
	gauges.CS.Alt.Visible = not gauges.CS.IsLoaded

	if values.PBrake.Value or starting then
		gauges.PBrake.ImageColor3 = Color3.new(1,1,1)
		gauges.PBrake.ImageTransparency = 0
	else
		gauges.PBrake.ImageColor3 = Color3.new(0,0,0)
		gauges.PBrake.ImageTransparency = .8
	end
	gauges.PBrake.Alt.TextColor3 = gauges.PBrake.ImageColor3
	gauges.PBrake.Alt.TextTransparency = gauges.PBrake.ImageTransparency
	gauges.PBrake.Alt.Visible = not gauges.PBrake.IsLoaded

	-- MISC
	gauges.RedlineLight.BackgroundColor3 = Color3.new(.15, .15, .15)
	if values.RPM.Value > _Tune.ShiftRPM then
		redlineLight += 1
		if redlineLight <= 5 then
			gauges.RedlineLight.BackgroundColor3 = Color3.new(1, 0, 0)
		end
		if redlineLight == 10 then
			redlineLight = 0
		end
	end
	if starting then
		gauges.RedlineLight.BackgroundColor3 = Color3.new(1, 0, 0)
	end
	
end)

-- Set ui for animations
