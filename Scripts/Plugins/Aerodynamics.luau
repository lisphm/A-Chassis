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
local Slipstream		= false		-- Slipstream may lag on larger maps

local WindVolume       	= .6		-- Volume of wind at 200 km/h.
local BodyVolume		= .1		-- Volume of body sounds at 200 km/h.

local Drag				= .38		-- Drag coefficient of the car. (You will have to tinker with this value to get the actual top speed, as the calculations are inaccurate.)
local DragMult			= .8		-- Multiplier for drag. This is so that the Drag value is accurate to your car. This value will need trial and error.
local Slipstream		= 60		-- How much drag is reduced in slipstream (in percent)
local SlipstreamTime	= .7		-- Maximum amount of time you can be behind a car to gain slipstream.
local DownforceF		= 50		-- Front downforce in kgf at 200 km/h. 
local DownforceR		= 70		-- Rear downforce in kgf at 200 km/h. 

local Directory			= car.Body:FindFirstChild("Aerodynamics")
local SimulationRate 	= 1/30

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

local CenterValue = values.Center
local VelocityValue = values.Velocity

task.wait() -- Add waits to try and reduce load on the client on startup.
-- Create our sounds, or use existing ones.
local wind = weight:FindFirstChild("WindSound") or Instance.new("Sound")
wind.Name = "WindSound"
wind.RollOffMaxDistance = 100
wind.RollOffMinDistance = 10
wind.RollOffMode = Enum.RollOffMode.InverseTapered
wind.Looped = true
wind.SoundId = "rbxassetid://188608071"
wind.Volume = 0
wind.Parent = weight
local eq = wind:FindFirstChild("EQ") or Instance.new("EqualizerSoundEffect")
eq.Name = "EQ"
eq.HighGain = 0
eq.LowGain = 5
eq.MidGain = -10
eq.Parent = wind
local body = weight:FindFirstChild("BodySound") or Instance.new("Sound")
body.Name = "BodySound"
body.RollOffMaxDistance = 100
body.RollOffMinDistance = 10
body.RollOffMode = Enum.RollOffMode.InverseTapered
body.Looped = true
body.SoundId = "rbxassetid://4471836491"
body.Volume = 0
body.Parent = weight

local dragPart = UseWeight and weight or Directory.Drag
local dfPart = UseWeight and weight or Directory.DownforceF
local drPart = UseWeight and weight or Directory.DownforceR

local dragAttach = dragPart:FindFirstChild("DragAttachment") or Instance.new("Attachment", dragPart)
dragAttach.Name = "DragAttachment"
local dfAttach = dfPart:FindFirstChild("DownforceFAttachment") or Instance.new("Attachment", dfPart)
dfAttach.Name = "DownforceFAttachment"
dfAttach.Position = Vector3.new(0, 0, UseWeight and -weight.Size.Z/2 or 0)
local drAttach = drPart:FindFirstChild("DownforceRAttachment") or Instance.new("Attachment", drPart)
drAttach.Name = "DownforceRAttachment"
drAttach.Position = Vector3.new(0, 0, UseWeight and weight.Size.Z/2 or 0)
local dragForce = dragPart:FindFirstChild("DragForce") or Instance.new("VectorForce", dragPart)
dragForce.Name = "DragForce"
dragForce.Attachment0 = dragAttach
dragForce.RelativeTo = Enum.ActuatorRelativeTo.World
local dfForce = dfPart:FindFirstChild("DownforceFForce") or Instance.new("VectorForce", dfPart)
dfForce.Name = "DownforceFForce"
dfForce.Attachment0 = dfAttach
dfForce.RelativeTo = Enum.ActuatorRelativeTo.World
local drForce = drPart:FindFirstChild("DownforceRForce") or Instance.new("VectorForce", drPart)
drForce.Name = "DownforceRForce"
drForce.Attachment0 = drAttach
drForce.RelativeTo = Enum.ActuatorRelativeTo.World

wind:Play()
body:Play()

-- Create our raycast parameters for slipstream.
local aeroParams = RaycastParams.new()
aeroParams.FilterDescendantsInstances = {car, player.Character}
aeroParams.FilterType = Enum.RaycastFilterType.Exclude
local aeroParamsFrom = RaycastParams.new()
aeroParamsFrom.FilterDescendantsInstances = {}
aeroParamsFrom.FilterType = Enum.RaycastFilterType.Exclude

task.wait()
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
		dragForce.Force = Vector3.new()
		dfForce.Force = Vector3.new()
		drForce.Force = Vector3.new()
		script:Destroy()
	end
end)

-- Loop
while task.wait(SimulationRate or 1/30) do
	if (VelocityValue.Value-workspace.GlobalWind).Magnitude < 1 then continue end

	local AirPressurePercent = math.exp((-9.80665 * 0.0289644 * (CenterValue.Value.Position.Y * Units.Length_mm / 1000)) / (8.3142 * ((workspace:GetAttribute("GlobalTemperature") or 22) + 273.15))) * (workspace.AirDensity/0.001)

	-- Slipstream
	_DragFactor = 1
	if Slipstream then
		local toRay = workspace:Raycast(weight.Position, weight.CFrame.LookVector*1000, aeroParams)
		if toRay then
			aeroParamsFrom.FilterDescendantsInstances = toRay.Instance:GetConnectedParts()
			local fromRay = workspace:Raycast(toRay.Position, -toRay.Instance.Velocity*SlipstreamTime, aeroParamsFrom)
			if fromRay and fromRay.Instance:IsDescendantOf(car) then
				_DragFactor = (1-(Slipstream/100))+(fromRay.Distance/(toRay.Instance.Velocity*SlipstreamTime).Magnitude*(Slipstream/100))
			end
		end
	end

	-- Apply forces
	local carVel = VelocityValue.Value * toKMH
	local windVel = workspace.GlobalWind * toKMH
	local diff = (carVel - windVel) * toKMH
	local objectVel = weight.CFrame:VectorToObjectSpace(carVel-windVel)

	local df = math.sign(objectVel.Z)*(objectVel.Z^2/(200)^2)*(DownforceF)*_DragFactor
	local dr = math.sign(objectVel.Z)*(objectVel.Z^2/(200)^2)*(DownforceR)*_DragFactor
	local combinedForce = -diff.Unit*diff.Magnitude^2*((Drag*DragMult)/100) * AirPressurePercent

	dfForce.Force = weight.CFrame.UpVector*df*fromKGF
	drForce.Force = weight.CFrame.UpVector*dr*fromKGF
	dragForce.Force = combinedForce*fromKGF

	-- Apply sounds
	wind.Volume = diff.Magnitude^2 * WindVolume / (200)^2
	body.Volume = diff.Magnitude^2 * BodyVolume / (200)^2
end
