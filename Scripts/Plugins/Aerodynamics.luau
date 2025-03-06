--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

local car = script.Parent.Car.Value

-- [[Editable Values]]
local UseWeight			= false		-- If true, does not use body parts to apply drag and downforce.

local WindVolume       	= .6		-- Volume of wind at 200 km/h.
local BodyVolume		= .1		-- Volume of body sounds at 200 km/h.

local Drag				= .31		-- Drag coefficient of the car.
local DragMult			= 1.5		-- Multiplier for drag. This is so that the Drag value is accurate to your car. This value will need trial and error.
local Slipstream		= 70		-- How much drag is reduced in slipstream (in percent)
local SlipstreamTime	= .7		-- Maximum amount of time you can be behind a car to gain slipstream.
local DownforceF		= 306		-- Front downforce in kgf at 200 km/h. 
local DownforceR		= 503		-- Rear downforce in kgf at 200 km/h. 

local Directory			= car.Body:FindFirstChild("Aerodynamics")

--[[END]]
-- Probably don't touch stuff down here
local values = script.Parent.Values
local player = game.Players.LocalPlayer
local Units = require(car["A-Chassis Tune"].README.Units)
local RunService = game:GetService("RunService")
local weight = car.Body["#Weight"]

local _DragFactor = 1
local toKMH = (Units.Length_mm/1000) * 3.6
local fromKGF = 9.81*Units.Force_N

wait() -- Add waits to try and reduce load on the client on startup.
-- Create our sounds, or use existing ones.
local wind = weight:FindFirstChild("WindSound") or Instance.new("Sound", weight)
wind.Name = "WindSound"
wind.RollOffMaxDistance = 100
wind.RollOffMinDistance = 10
wind.RollOffMode = Enum.RollOffMode.InverseTapered
wind.Looped = true
wind.SoundId = "rbxassetid://188608071"
wind.Volume = 0
local eq = wind:FindFirstChild("EQ") or Instance.new("EqualizerSoundEffect", wind)
eq.Name = "EQ"
eq.HighGain = 0
eq.LowGain = 0
eq.MidGain = 0
local body = weight:FindFirstChild("BodySound") or Instance.new("Sound", weight)
body.Name = "BodySound"
body.RollOffMaxDistance = 100
body.RollOffMinDistance = 10
body.RollOffMode = Enum.RollOffMode.InverseTapered
body.Looped = true
body.SoundId = "rbxassetid://4471836491"
body.Volume = 0
wind:Play()
body:Play()

-- Create our raycast parameters for slipstream.
local aeroParams = RaycastParams.new()
aeroParams.FilterDescendantsInstances = {car, player.Character}
aeroParams.FilterType = Enum.RaycastFilterType.Exclude
local aeroParamsFrom = RaycastParams.new()
aeroParamsFrom.FilterDescendantsInstances = {}
aeroParamsFrom.FilterType = Enum.RaycastFilterType.Exclude

wait()
for _, v in next, car:GetDescendants() do
	if v:IsA("BasePart") then
		v.EnableFluidForces = false
	end
end

-- On player leave
car.DriveSeat.ChildRemoved:Connect(function(child)
	if child.Name=="SeatWeld" and child:IsA("Weld") then
		wind:Destroy()
		body:Destroy()
	end
end)

-- Loop
RunService.Heartbeat:Connect(function(dt)
	
	local AirPressurePercent = math.exp((-9.80665 * 0.0289644 * (values.Center.Value.Position.Y * Units.Length_mm / 1000)) / (8.3142 * ((workspace:GetAttribute("GlobalTemperature") or 22) + 273.15)))
	
	-- Slipstream
	local toRay = workspace:Raycast(weight.Position, weight.CFrame.LookVector*1000, aeroParams)
	_DragFactor = 1
	if toRay then
		aeroParamsFrom.FilterDescendantsInstances = toRay.Instance:GetConnectedParts()
		local fromRay = workspace:Raycast(toRay.Position, -toRay.Instance.Velocity*SlipstreamTime, aeroParamsFrom)
		if fromRay and fromRay.Instance:IsDescendantOf(car) then
			_DragFactor = (1-(Slipstream/100))+(fromRay.Distance/(toRay.Instance.Velocity*SlipstreamTime).Magnitude*(Slipstream/100))
		end
	end

	-- Apply forces
	local carVel = values.Velocity.Value * toKMH
	local windVel = workspace.GlobalWind * toKMH
	local diff = (carVel - windVel) * toKMH
	local objectVel = weight.CFrame:VectorToObjectSpace(carVel-windVel)

	local df = math.sign(objectVel.Z)*(objectVel.Z^2/(200)^2)*(DownforceF)*_DragFactor
	local dr = math.sign(objectVel.Z)*(objectVel.Z^2/(200)^2)*(DownforceR)*_DragFactor
	local combinedForce = -diff.Unit*diff.Magnitude^2*((Drag*DragMult)/100) * AirPressurePercent

	if UseWeight then
		weight:ApplyImpulseAtPosition(weight.CFrame.UpVector*dt*(df)*fromKGF, (weight.CFrame*CFrame.new(0,0,-weight.Size.Z/2)).Position)
		weight:ApplyImpulseAtPosition(weight.CFrame.UpVector*dt*(dr)*fromKGF, (weight.CFrame*CFrame.new(0,0,weight.Size.Z/2)).Position)
		weight:ApplyImpulseAtPosition(dt*combinedForce*fromKGF, weight.Position)
		weight:SetAttribute("DownforceF", df)
		weight:SetAttribute("DownforceR", dr)
		weight:SetAttribute("DragForce", combinedForce.Magnitude)
	else
		weight:ApplyImpulseAtPosition(weight.CFrame.UpVector*dt*(df)*fromKGF, Directory.DownforceF.Position)
		weight:ApplyImpulseAtPosition(weight.CFrame.UpVector*dt*(dr)*fromKGF, Directory.DownforceR.Position)
		weight:ApplyImpulseAtPosition(dt*combinedForce*fromKGF, Directory.Drag.Position)
		Directory.DownforceF:SetAttribute("Downforce", df)
		Directory.DownforceR:SetAttribute("Downforce", dr)
		Directory.Drag:SetAttribute("DragForce", combinedForce.Magnitude)
	end

	-- Apply sounds
	wind.Volume = diff.Magnitude^2 * WindVolume / (200)^2
	body.Volume = diff.Magnitude^2 * BodyVolume / (200)^2
end)
