--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
--------------------------------------------------------------------------

local UserInputService = game:GetService("UserInputService")
local HapticService = game:GetService("HapticService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local car = script.Parent.Parent.Car.Value
local values = script.Parent.Parent.Values
local event = car.Friction
local player= Players.LocalPlayer

local _WheelTune = require(script.Parent.Tune)
local _Tune = require(car["A-Chassis Tune"])
local Units = require(car["A-Chassis Tune"].README.Units)

local SimulationRate = 1/24

local VelocityValue = values.Velocity

-- Rumble
local isVibrationSupported = HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)
UserInputService.GamepadConnected:Connect(function()
	isVibrationSupported = HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)
end)

-- Hide UI
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if not gameProcessedEvent then
		if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonL3 then
			script.Parent.Visible = not script.Parent.Visible
		end
	end
end)

task.wait()

--Wheels Array
--Wheels Array
-- Wheels Array
local WheelData = {}

local wheelsFolder = car:FindFirstChild("Wheels")
if not wheelsFolder then
	return -- vehicle is not valid anymore (seat detached / rebuild state)
end

for _, v in wheelsFolder:GetChildren() do
	local data = {}
	data.Object = v
	data.Temperature = _WheelTune.AmbientTemp
	data.Dirt = 0
	data.Stress = 0
	data.Ray = nil
	data.Material = ""
	data.SmokePart = v:WaitForChild("SmokePart")
	data.ID = v:GetAttribute("ID")
	data.Arm = v.Arm

	if _WheelTune.TireFlex then
		data.FlexCollision = data.Object:WaitForChild("Collision")
	end
	if data.FlexCollision then
		data.FlexCollision:WaitForChild("#GRAVCOMP")
	end

	WheelData[v.Name] = data
end

--Open/Load Heat Data
if _WheelTune.SaveHeatData then
	local wd = car:FindFirstChild("HeatData")
	if wd then
		local t = tick()-wd.STime.Value
		for name, data in WheelData do
			if wd:FindFirstChild(name) then
				local front = string.find(name, "F")
				data.Temperature = wd[name]:GetAttribute("Temperature") - 60*t*(front and _WheelTune.FCooling or _WheelTune.RCooling)
				data.Dirt = wd[name]:GetAttribute("Dirt")
			end
		end
	end
end

--Close/Store Heat Data
car.DriveSeat.ChildRemoved:Connect(function(child)
	if child.Name == "SeatWeld" then

		-- Save heat data
		if _WheelTune.SaveHeatData then
			local wd = car:FindFirstChild("HeatData")
			if not wd then
				wd = script.Parent.HeatData:Clone()
				wd.Parent = car
			end

			for name, data in WheelData do
				local config = wd:FindFirstChild(name) or Instance.new("Configuration")
				config.Name = name
				config.Parent = wd
				config:SetAttribute("Temperature", data.Temperature)
				config:SetAttribute("Dirt", data.Dirt)
			end

			wd.STime.Value = tick()
		end

		-- Stop haptics
		if isVibrationSupported then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
		end

		-- Stop smoke safely
		if _WheelTune.SmokeEffects == "Local" or _WheelTune.SmokeEffects == "All" then
			local wheelsFolder = car:FindFirstChild("Wheels")
			if wheelsFolder then
				for _, wheel in wheelsFolder:GetChildren() do
					if not wheel:IsA("BasePart") then continue end
					local smokePart = wheel:FindFirstChild("SmokePart")
					if not smokePart then continue end

					for _, d in smokePart:GetChildren() do
						if d:IsA("Sound") then
							d.Playing = false
							d.SoundId = d:GetAttribute("data") or d.SoundId
						elseif d:IsA("ParticleEmitter") then
							d.Enabled = false
							d.Lifetime = d:GetAttribute("data") or d.Lifetime
						elseif d:IsA("Trail") then
							d.Enabled = false
							d.Lifetime = d:GetAttribute("data") or d.Lifetime
						end
					end
				end
			end
		end

		script:Destroy()
	end
end)

--Ray Data (Detomiks)
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {car}
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local materialSort = {

	road = {
		"Plastic",
		"Slate",
		"Concrete",
		"Granite",
		"Brick",
		"Pebble",
		"Cobblestone",
		"Rock",
		"Basalt",
		"Ground",
		"Pavement",
		"SmoothPlastic",
		"Asphalt",
	},

	dirt = {
		"Grass",
		"Mud",
		"Ground",
		"LeafyGrass",
	},

	sand = {
		"Sand",
		"Sandstone",
		"Limestone"
	},

	snow = {
		"Glacier",
		"Snow",
	}

}
local materialID = {
	road = 1,
	dirt = 2,
	sand = 3,
	snow = 4,
}
local lastInput = UserInputService:GetLastInputType()
UserInputService.LastInputTypeChanged:Connect(function(inputType)
	lastInput = inputType
end)

--Runtime Loops
local numWheels = 0
for _, v in WheelData do
	numWheels = numWheels + 1
end
local dtTable = {}
for name, data in WheelData do
	-- Replicate effects to the client
	data.Sounds = {}
	data.Trails = {
		road = {},
		dirt = {},
		snow = {},
		sand = {}
	}
	data.Smokes = {}
	if _WheelTune.SmokeEffects == "Local" or _WheelTune.SmokeEffects == "All" then
		for _, v in data.SmokePart:GetChildren() do
			if string.find(v.Name, "Local_") then continue end
			if v:IsA("Trail") or v:IsA("ParticleEmitter") or v:IsA("Sound") then
				local effectType = (string.find(v.Name, "road") and "road") or (string.find(v.Name, "sand") and "sand") or (string.find(v.Name, "dirt") and "dirt") or (string.find(v.Name, "snow") and "snow")
				local effect = v
				if _WheelTune.SmokeEffects == "Local" then
					v.Name = "Local_"..v.Name
				else
					local new = data.SmokePart:FindFirstChild("Local_"..v.Name) or v:Clone()
					new.Name = "Local_"..v.Name
					new.Parent = data.SmokePart
					effect = new
					if v:IsA("Trail") then
						v:SetAttribute("data", v.Lifetime)
						v.Lifetime = 0
					elseif v:IsA("ParticleEmitter") then
						v:SetAttribute("data", v.Lifetime)
						v.Lifetime = NumberRange.new(0)
					else
						v:SetAttribute("data", v.SoundId)
						v.SoundId = ""
					end
				end
				if v:IsA("Trail") then
					data.Trails[effectType][math.round(v:GetAttribute("stress")*_WheelTune.TireMarkTransparencyLevels)] = effect
				elseif v:IsA("ParticleEmitter") then
					data.Smokes[effectType] = effect
				elseif v:IsA("Sound") then
					data.Sounds[effectType] = effect
				end
			end
		end
	end
	
	-- Cache other things
	data.SmokePartChildren = data.SmokePart:GetChildren()
	data.CollisionModel = data.Object:FindFirstChild("CollisionModel")
	data.tireUI = script.Parent.Tires:FindFirstChild(name)
	data.FlexCollisionGravComp = data.FlexCollision and data.FlexCollision:FindFirstChild("#GRAVCOMP")
	data.ObjectGravComp = data.Object:FindFirstChild("#GRAVCOMP")
	data.Collision = data.Object:FindFirstChild("Collision")
	data.TrailAttachmentPart = data.Object:FindFirstChild("TrailAttachmentPart")
	data.FlexCollisionAlignPosition = data.FlexCollision and data.FlexCollision.AlignPosition
	data.CurrentSound = nil
	data.CurrentSmoke = nil
	data.CurrentTrail = nil
	data.TrailStress = 0
	for _, d in data.SmokePartChildren do
		if d:IsA("Sound") and d:FindFirstChild("TremoloSoundEffect") then
			d:SetAttribute("HasTremolo", true)
		end
	end

	local sandForce = Vector3.new()
	local last = tick()

	local front = string.find(name, "F")
	
	local function TireFlexPhysics(dt)
		dtTable[name] = dt
		if not (_WheelTune.TireFlex and data.FlexCollision) then return end
		local radius = (data.Object.Size.Y/2)
		local h = (data.FlexCollision.Position - data.Object.Position).Magnitude/radius
		local y = 2 * radius * math.sqrt(1-(1-h)^2)
		local area = y * data.Object.Size.X
		if front then
			data.FlexCollisionAlignPosition.MaxForce = (_WheelTune.FPressureForce) * (area*(Units.Length_mm*0.03937008)^2) * 4.448222 * Units.Force_N
		else
			data.FlexCollisionAlignPosition.MaxForce = (_WheelTune.RPressureForce) * (area*(Units.Length_mm*0.03937008)^2) * 4.448222 * Units.Force_N
		end
	end
	local function SimulationLoop()
		while task.wait(SimulationRate) do
			local deltaTime = tick()-last
			last = tick()
						
			-- Disable if the wheel cannot physically collide
			if (data.FlexCollision and data.FlexCollision.CanCollide == false) or (data.Object.CanCollide == false and data.FlexCollision == nil and data.CollisionModel == nil) then
				return
			end

			local stress = 0
			local count = 0

			local rotSpeed = math.abs(data.Object.RotVelocity:Dot(data.SmokePart.CFrame.RightVector))
			local lateralDiff = math.abs(data.Object.Velocity:Dot(data.Object.CFrame.RightVector))/data.Object.Velocity.Magnitude
			local rotLinearSpeed = rotSpeed*(data.Object.Size.Y/2)
			local speed = VelocityValue.Value.Magnitude
			local diff = math.abs(rotLinearSpeed-speed)

			local ray = nil -- Assuming they are the same material
			local materialType = ""
			local materialChanged = false

			-- Rays
			-- Two rays, one for the inside and outside of the wheel for camber support.
			if _WheelTune.TireWearOn or _WheelTune.SmokeEffects == "Local" or _WheelTune.SmokeEffects == "All" then
				local rayI = workspace:Raycast(
					data.Object.Position,
					((data.Arm.CFrame * CFrame.new(-data.Object.Size.X/2, -data.Object.Size.Y/2, 0)).Position - data.Object.Position) * 1.1,
					rayParams)
				local rayO = workspace:Raycast(
					data.Object.Position,
					((data.Arm.CFrame * CFrame.new(data.Object.Size.X/2, -data.Object.Size.Y/2, 0)).Position - data.Object.Position) * 1.1,
					rayParams)
				ray = rayI or rayO
				if ray then
					-- Run a loop through the materialSort table. Set materialType and break when a material is found.
					for name, values in next, materialSort do
						if table.find(values, ray.Material.Name) then
							materialType = name
							break
						end
					end
				end
				data.Ray = ray
				if data.Material ~= materialType then
					materialChanged = true
				end
				data.Material = materialType
			end

			-- Slip
			local vstress = (math.max(ray and diff/20 or 0, ray and materialType~="road" and materialType ~= "" and rotSpeed/50 or 0) + (front and _WheelTune.FSpeedStress or _WheelTune.RSpeedStress)*(rotLinearSpeed/(Units.Velocity_mdivs/3.6)/100))
			if ray and materialType ~= "road" and materialType ~= "" then
				local random = Random.new():NextNumber() * speed
				if random > 20 then
					data.Object.Velocity += Vector3.new(0, math.random(0, _WheelTune.DirtBumps), 0) * math.min(speed/100, 5)
				end
			end
			if vstress > 0.05 * (60/(1/deltaTime)) and vstress > data.Stress then 
				data.Stress = math.min(data.Stress + 0.05 * (60/(1/deltaTime)), math.min(vstress, 1))
			else
				data.Stress = math.max(data.Stress - 0.05 * (60/(1/deltaTime)), vstress)	
			end

			-- Update dirt
			if materialType ~= "road" and materialType ~= "" then
				data.Dirt = 1
			else
				data.Dirt = math.max(data.Dirt - (front and _WheelTune.FDirtFadeRate or _WheelTune.RDirtFadeRate) * (rotSpeed/100) * (60/(1/deltaTime)), 0)
			end

			-- Apply friction
			local materialHeatFactor = materialType ~= "road" and .01 or 1
			local currentPhysicalProperties = data.Object.CurrentPhysicalProperties
			local coldLoss = 0
			local heatLoss = 0
			if _WheelTune.TireWearOn then
				if front then
					data.Temperature = math.clamp(data.Temperature + (data.Stress*(_WheelTune.FHeating+_WheelTune.FCooling)*materialHeatFactor - _WheelTune.FCooling) * (60/(1/deltaTime)), _WheelTune.AmbientTemp, _WheelTune.FMaxTemp)
				else
					data.Temperature = math.clamp(data.Temperature + (data.Stress*(_WheelTune.RHeating+_WheelTune.RCooling)*materialHeatFactor - _WheelTune.RCooling) * (60/(1/deltaTime)), _WheelTune.AmbientTemp, _WheelTune.RMaxTemp)
				end
				coldLoss = front and 
					(_WheelTune.FColdStats[1] * (1/(math.exp(_WheelTune.FColdStats[2]*(data.Temperature/100-_WheelTune.FColdStats[3]))+1))) or 
					(_WheelTune.RColdStats[1] * (1/(math.exp(_WheelTune.RColdStats[2]*(data.Temperature/100-_WheelTune.RColdStats[3]))+1)))
				heatLoss = front and 
					(_WheelTune.FHotStats[1] * (-(1/(math.exp(_WheelTune.FHotStats[2]*(data.Temperature/100-_WheelTune.FHotStats[3]))+1))+1)) or 
					(_WheelTune.RHotStats[1] * (-(1/(math.exp(_WheelTune.RHotStats[2]*(data.Temperature/100-_WheelTune.RHotStats[3]))+1))+1))
			end
			local density = math.round((((_Tune.FWheelWeight-(_WheelTune.TireFlex and _WheelTune.FTireWeight or 0))*Units.Mass_kg)/(math.pi*(data.Object.Size.Y/2)^2*(data.Object.Size.X)))*1000)/1000
			local friction = math.round(math.clamp(_WheelTune.FMaxFriction - coldLoss - heatLoss - data.Dirt*_WheelTune.FDirtLoss, 0, 2)*1000)/1000
			if not front then
				density = math.round((((_Tune.RWheelWeight-(_WheelTune.TireFlex and _WheelTune.RTireWeight or 0))*Units.Mass_kg)/(math.pi*(data.Object.Size.Y/2)^2*(data.Object.Size.X)))*1000)/1000
				friction = math.round(math.clamp(_WheelTune.RMaxFriction - coldLoss - heatLoss - data.Dirt*_WheelTune.RDirtLoss, 0, 2)*1000)/1000
			end
			if math.round(currentPhysicalProperties.Friction*1000)/1000 ~= friction or math.round(currentPhysicalProperties.Density*1000)/1000 ~= density then
				data.Object.CustomPhysicalProperties = PhysicalProperties.new(
					density,
					friction,
					currentPhysicalProperties.Elasticity,
					currentPhysicalProperties.FrictionWeight,
					currentPhysicalProperties.ElasticityWeight
				)
			end
			if ray and materialType == "sand" then
				data.Object:ApplyImpulseAtPosition(-data.Object.Velocity*_WheelTune.SandForce*deltaTime, data.Object.Position)
			end

			-- Update UI
			if script.Parent.Visible and script.Parent.Tires.Visible then
				local tire = data.tireUI
				if tire then
					local front = string.find(tire.Name, "F")
					tire.First.Second.Size = UDim2.new(1, 0, math.clamp(1-(data.Temperature-40)/((front and _WheelTune.FMaxTemp or _WheelTune.RMaxTemp)-40),0,1), 0)
					tire.BackgroundColor3 = Color3.fromHSV(0, data.Stress, 1)
					tire.BackgroundTransparency = .8 - .3 * data.Stress
				end
			end
			data.Object:SetAttribute("Temperature", data.Temperature)
			data.Object:SetAttribute("Dirt", data.Dirt)

			-- Update haptic values
			stress += data.Stress
			count += 1

			-- Tire flex
			if _WheelTune.TireFlex and data.FlexCollision then
				local flexDensity = math.round((((string.find(name, "F") and _WheelTune.FTireWeight or _WheelTune.RTireWeight)*Units.Mass_kg)/(math.pi*(data.Object.Size.Y/2)^2*(data.Object.Size.X)))*1000)/1000
				local flexCurrentPhysicalProperties = data.FlexCollision.CurrentPhysicalProperties
				if math.round(flexCurrentPhysicalProperties.Density*1000)/1000 ~= flexDensity or 
					currentPhysicalProperties.Friction ~= flexCurrentPhysicalProperties.Friction or 
					currentPhysicalProperties.Elasticity ~= flexCurrentPhysicalProperties.Elasticity or 
					currentPhysicalProperties.FrictionWeight ~= flexCurrentPhysicalProperties.FrictionWeight or 
					currentPhysicalProperties.ElasticityWeight ~= flexCurrentPhysicalProperties.ElasticityWeight then
					
					data.FlexCollision.CustomPhysicalProperties = PhysicalProperties.new(
						flexDensity,
						currentPhysicalProperties.Friction,
						currentPhysicalProperties.Elasticity,
						currentPhysicalProperties.FrictionWeight,
						currentPhysicalProperties.ElasticityWeight
					)
				end
				if data.FlexCollisionGravComp then
					data.FlexCollisionGravComp.Force = Vector3.new(0, _Tune.GravComp > 0 and data.FlexCollision.Mass*(workspace.Gravity-_Tune.GravComp) or 0, 0)
				end
				if data.ObjectGravComp then
					data.ObjectGravComp.Force = Vector3.new(0, _Tune.GravComp > 0 and data.Object.Mass*(workspace.Gravity-_Tune.GravComp) or 0, 0)
				end
			end

			-- Smoke
			if _WheelTune.SmokeEffects == "Local" or _WheelTune.SmokeEffects == "All" then
				-- Set sounds and smoke
				local currentSound = data.CurrentSound
				local currentSmoke = data.CurrentSmoke
				if materialChanged then
					if currentSound then
						currentSound.Playing = false
					end
					if currentSmoke then
						currentSmoke.Enabled = false
					end
					currentSound = data.Sounds[materialType]
					currentSmoke = data.Smokes[materialType]
					data.CurrentSound = currentSound
					data.CurrentSmoke = currentSmoke
				end
				
				-- Set Trails
				local smokeStress = math.clamp(data.Stress - _WheelTune.SmokeStressOffset/100, 0, 1)
				local trailStress = math.floor(smokeStress^3 * _WheelTune.TireMarkTransparencyLevels)
				if data.Trails[materialType] then
					for i = 1, (trailStress > data.TrailStress and trailStress or data.TrailStress) do
						data.Trails[materialType][i].Enabled = trailStress >= i
					end
				end
				if materialChanged and data.CurrentTrail then
					for i = 1, _WheelTune.TireMarkTransparencyLevels do
						data.CurrentTrail[i].Enabled = false
					end
				end
				data.CurrentTrail = data.Trails[materialType]
				data.TrailStress = trailStress
				
				-- Run effects
				if currentSound then
					-- Sound
					if not currentSound.Playing then
						currentSound.TimePosition = Random.new():NextNumber() * currentSound.TimeLength --avoid overlapping sounds
					end
					currentSound.Playing = true
					currentSound.Volume = smokeStress ^ 3 * 1.4
					currentSound.PlaybackSpeed = 1.6 - 0.5 * smokeStress
					local tremolo = currentSound:GetAttribute("HasTremolo") and currentSound.TremoloSoundEffect
					if tremolo then
						tremolo.Depth = lateralDiff
					end
				end
				if currentSmoke then
					-- Smoke
					currentSmoke.Enabled = true
					currentSmoke.Rate = smokeStress^10 * 100
				end
				local compression = 1
				if data.Collision then
					compression = math.clamp((data.Object.Position-data.Collision.Position).Magnitude/.1, 0, 1)
				end
				local trailAttachmentPart = data.TrailAttachmentPart
				if trailAttachmentPart and smokeStress > 0.05 and data.Object.Velocity.Magnitude > 10 then
					trailAttachmentPart.TrailAttachment0.Position = Vector3.new(data.Object.Size.X/2-.2 + .1*compression, .02, 0)
					trailAttachmentPart.TrailAttachment1.Position = Vector3.new(-data.Object.Size.X/2+.2 - .1*compression, .02, 0)
					trailAttachmentPart.AlignOrientation.CFrame = CFrame.lookAt(data.SmokePart.Position, (data.SmokePart.CFrame * CFrame.new(0, 0, -5 + math.min(data.Object.Velocity.Magnitude, 5))).Position+data.Object.Velocity, ray and ray.Normal or data.SmokePart.CFrame.UpVector)
				end
			end

			-- Haptics
			if isVibrationSupported and ((_WheelTune.Haptics == "Controller" or _WheelTune.Haptics == "Both" and string.find(lastInput.Name, "Gamepad")) or (_WheelTune.Haptics == "Mobile" or _WheelTune.Haptics == "Both" and lastInput == Enum.UserInputType.Touch)) then
				stress /= count
				stress = math.clamp(stress/2, 0, .5)
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, stress)
			end
		end
	end
	task.defer(SimulationLoop)
	RunService.Heartbeat:Connect(TireFlexPhysics)
end

--Everything else
if _WheelTune.SmokeEffects == "All" then
	local rate = _WheelTune.SmokePollingRate
	local lastTick = tick()
	local function SlowRuntimeLoop()
		while task.wait(rate) do
			for name, data in next, WheelData do
				if not dtTable[name] then continue end
				local ray = data.Ray
				local materialType = data.Material
				local smokeStress = math.clamp(data.Stress - _WheelTune.SmokeStressOffset/100, 0, 1)
				local rayNormal = ray and ray.Normal or Vector3.zero
				local packet = buffer.create(8)
				buffer.writeu8(packet, 0, data.ID)
				buffer.writeu8(packet, 1, materialID[materialType] or 0)
				buffer.writeu8(packet, 2, math.clamp(math.round(smokeStress*255), 0, 255))
				buffer.writei8(packet, 3, math.round(rayNormal.X*127))
				buffer.writei8(packet, 4, math.round(rayNormal.Y*127))
				buffer.writei8(packet, 5, math.round(rayNormal.Z*127))
				buffer.writeu16(packet, 6, math.clamp(math.round(dtTable[name]*65535), 0, 65535))
				event:FireServer(packet)
			end
		end
	end
	task.defer(SlowRuntimeLoop)
end
