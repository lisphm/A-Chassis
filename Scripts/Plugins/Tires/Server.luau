--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

local car = script.Parent.Parent
local _Tune = require(car["A-Chassis Tune"])
local Units = require(car["A-Chassis Tune"].README.Units)
local RunService = game:GetService("RunService")

local wheelID = {}
local previousMaterialData = {}
local previousSoundsData = {}
local previousTrailsData = {}
local previousSmokesData = {}

local canUpdate = false

task.wait(.5)

local function create(_WheelTune)
	for i, v in car.Wheels:GetChildren() do
		if not v:FindFirstChild("SmokePart") then
			v:SetAttribute("ID", i)
			wheelID[i] = v
			local caster = string.find(v.Name, "F") and _Tune.FCaster or _Tune.RCaster
			caster = (v.Name == "FR" or v.Name == "RR") and -caster or caster

			local smokePart = v:FindFirstChild("SmokePart") or v.Arm:Clone()
			smokePart.Name = "SmokePart"
			smokePart.Massless = true
			smokePart:ClearAllChildren()
			smokePart.CFrame = CFrame.new((v.CFrame * CFrame.new(0, -v.Size.Y/2, 0)).Position) * v.Arm.CFrame.Rotation
			smokePart.Parent = v

			local sa0 = Instance.new("Attachment")
			sa0.Name = "SmokePartAttachment0"
			sa0.Parent = v.Base

			local sa1 = Instance.new("Attachment")
			sa1.Name = "SmokePartAttachment1"
			sa1.Position = Vector3.new(0, v.Size.Y/2 + _Tune.AxleSize, 0)
			sa1.Parent = smokePart

			local smokePartRigidConstraint = Instance.new("RigidConstraint")
			smokePartRigidConstraint.Attachment0 = sa0
			smokePartRigidConstraint.Attachment1 = sa1
			smokePartRigidConstraint.Parent = smokePart

			for _, a in script:GetChildren() do
				if smokePart:FindFirstChild(a.Name) then continue end
				local clone = a:Clone()
				clone.Parent = smokePart
			end

			-- create trails
			local trailAttachmentPart = v:FindFirstChild("TrailAttachmentPart") or smokePart:Clone()
			trailAttachmentPart:ClearAllChildren()
			trailAttachmentPart.Name = "TrailAttachmentPart"
			trailAttachmentPart.Parent = v

			local ta0 = Instance.new("Attachment")
			ta0.Parent = v.Arm

			local ta1 = Instance.new("Attachment")
			ta1.Position = Vector3.new(0, v.Size.Y/2, 0)
			ta1.Parent = trailAttachmentPart

			local tapalign = Instance.new("AlignPosition")
			tapalign.ReactionForceEnabled = true
			tapalign.RigidityEnabled = true
			tapalign.Attachment0 = ta0
			tapalign.Attachment1 = ta1
			tapalign.Parent = trailAttachmentPart

			local tapOrientation = Instance.new("AlignOrientation")
			tapOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
			tapOrientation.Attachment0 = ta1
			tapOrientation.MaxTorque = math.huge
			tapOrientation.RigidityEnabled = true
			tapOrientation.Parent = trailAttachmentPart

			local a0 = Instance.new("Attachment")
			a0.Name = "TrailAttachment0"
			a0.Parent = trailAttachmentPart

			local a1 = Instance.new("Attachment")
			a1.Name = "TrailAttachment1"
			a1.Parent = trailAttachmentPart

			if _WheelTune.TireFlex then				
				local collision = v:FindFirstChild("Collision") or Instance.new("Part")
				collision.Name = "Collision"
				collision.CanCollide = false -- false for now
				collision.CFrame = v.CFrame
				collision.Transparency = _WheelTune.ShowTF and .5 or 1
				collision.Shape = Enum.PartType.Cylinder
				collision.Size = v.Size
				collision.CollisionGroup = v.CollisionGroup
				collision.Parent = v

				ta0.Parent = v.Collision
				ta0.Position = Vector3.new()
				ta1.Position = Vector3.new(0, v.Size.Y/2, 0)

				for _, a in v:GetNoCollisionConstraints() do
					if a.Part0 == v then a.Part0 = collision end
					if a.Part1 == v then a.Part1 = collision end
				end

				local model = v:FindFirstChild("CollisionModel")
				if model then
					for _, a in model:GetDescendants() do
						if a:IsA("BasePart") then
							local weld = a:FindFirstChild("Weld")
							if weld and weld.Part1 == v then
								weld.Part1 = collision
							end
						end
					end
					collision.CanCollide = false
				end

				local attachment = Instance.new("Attachment")
				attachment.Name = "#GRAVCOMP_ATTACH"
				attachment.Parent = collision

				for _, child in collision:GetChildren() do
					if child:IsA("VectorForce") and child.Name == "#GRAVCOMP" then
						child:Destroy()
					end
				end

				local force = Instance.new("VectorForce")
				force.Name = "#GRAVCOMP"
				force.RelativeTo = Enum.ActuatorRelativeTo.World
				force.Attachment0 = attachment
				force.Force = Vector3.new(0, _Tune.GravComp > 0 and collision.Mass*(workspace.Gravity-_Tune.GravComp) or 0, 0)
				force.Parent = collision

				local mainAttachment = Instance.new("Attachment")
				mainAttachment.Orientation = v["AB"].Orientation
				mainAttachment.Parent = collision

				local alignForce = Instance.new("AlignPosition")
				alignForce.ReactionForceEnabled = true
				alignForce.Attachment0 = v["AB"]
				alignForce.Attachment1 = mainAttachment
				alignForce.ForceLimitMode = Enum.ForceLimitMode.Magnitude
				alignForce.ForceRelativeTo = Enum.ActuatorRelativeTo.World
				alignForce.Responsiveness = 100
				alignForce.MaxVelocity = 10
				alignForce.Parent = collision

				local rotationForce = Instance.new("AlignOrientation")
				rotationForce.ReactionTorqueEnabled = true
				rotationForce.RigidityEnabled = true
				rotationForce.Attachment0 = v["AB"]
				rotationForce.Attachment1 = mainAttachment
				rotationForce.Responsiveness = math.huge
				rotationForce.Parent = collision

				local limiter = Instance.new("SpringConstraint")
				limiter.Name = "Limiter"
				limiter.Damping = 0
				limiter.Stiffness = 0
				limiter.MaxForce = 0
				limiter.Coils = 0
				limiter.Attachment0 = v["AB"]
				limiter.Attachment1 = mainAttachment
				limiter.LimitsEnabled = true
				limiter.FreeLength = 0
				limiter.Parent = collision

				if string.find(v.Name, "F") then
					limiter.MaxLength = _WheelTune.FTireThickness/Units.Length_mm
				else
					limiter.MaxLength = _WheelTune.RTireThickness/Units.Length_mm
				end

				v.CanCollide = false
				collision.CanCollide = true
			end

			local TAPRayParams = RaycastParams.new()
			TAPRayParams.FilterType = Enum.RaycastFilterType.Exclude
			TAPRayParams.FilterDescendantsInstances = {car}

			if _WheelTune.TireMarkTransparencyLevels > 0 then
				for m = 1, 4 do
					for i = 1, _WheelTune.TireMarkTransparencyLevels do
						local name = "Trail"..((m==1 and "road") or (m==2 and "snow") or (m==3 and "sand") or (m==4 and "dirt") or "") .. i
						local trail = smokePart:FindFirstChild(name) or Instance.new("Trail")
						trail.Name = name
						trail.Transparency = NumberSequence.new(_WheelTune.TireMarkTransparency)
						trail.Texture = "rbxassetid://14987871952"
						trail.TextureMode = Enum.TextureMode.Static
						trail.Lifetime = 20
						trail.Enabled = false
						trail.Attachment0 = a0
						trail.Attachment1 = a1
						trail:SetAttribute("stress", i/_WheelTune.TireMarkTransparencyLevels)
						if m == 1 then
							trail.Color = ColorSequence.new(Color3.new(0, 0, 0))
						elseif m == 2 then
							trail.Color = ColorSequence.new(Color3.fromRGB(205, 250, 255))
						elseif m == 3 then
							trail.Color = ColorSequence.new(Color3.fromRGB(255, 241, 136))
						else
							trail.Color = ColorSequence.new(Color3.fromRGB(255, 173, 102))
						end
						trail.Parent = smokePart
					end
				end
			end

		end
	end
end

local materialID = {
	"road", "dirt", "sand", "snow"
}

local function update(player, packet)
	if not canUpdate then return end

	local wheel, materialType, smokeStress, rayNormal, dt =
		wheelID[buffer.readu8(packet, 0)],
	materialID[buffer.readu8(packet, 1)] or "",
	buffer.readu8(packet, 2)/255,
	Vector3.new(buffer.readi8(packet, 3)/127, buffer.readi8(packet, 4)/127, buffer.readi8(packet, 5)/127),
	buffer.readu16(packet, 6)/65535

	if not wheel or not wheel.Parent then return end
	-- Set smokepart data
	local smokePart = wheel:FindFirstChild("SmokePart")
	if not smokePart then return end

	local materialChanged = previousMaterialData[wheel] ~= materialType
	previousMaterialData[wheel] = materialType

	local currentSound = previousSoundsData[wheel]
	local currentSmoke = previousSmokesData[wheel]
	if materialChanged then
		if currentSound then
			currentSound.Playing = false
		end
		if currentSmoke then
			currentSmoke.Enabled = false
		end
		currentSound = smokePart:FindFirstChild("Sound_" .. materialType)
		currentSmoke = smokePart:FindFirstChild("Smoke_" .. materialType)
		previousSoundsData[wheel] = currentSound
		previousSmokesData[wheel] = currentSmoke
	end
	for _, d in smokePart:GetChildren() do
		if d.ClassName == "Trail" then
			d.Enabled = false
			if materialType ~= "" and string.find(d.Name, materialType) and d:GetAttribute("stress") < smokeStress^3 and rayNormal then
				d.Enabled = true
			end
		end				
	end
	if currentSound then
		-- Sound
		if not currentSound.Playing then
			currentSound.TimePosition = Random.new():NextNumber() * currentSound.TimeLength --avoid overlapping sounds
		end
		currentSound.Playing = true
		currentSound.Volume = smokeStress ^ 3 * 1.4
		currentSound.PlaybackSpeed = 1.6 - 0.5 * smokeStress
		local tremolo = currentSound:FindFirstChildWhichIsA("TremoloSoundEffect")
		if tremolo then
			local lateralDiff = (math.abs(wheel.Velocity:Dot(wheel.CFrame.RightVector))/wheel.Velocity.Magnitude)
			tremolo.Depth = lateralDiff
		end
	end
	if currentSmoke then
		-- Smoke
		currentSmoke.Enabled = true
		currentSmoke.Rate = smokeStress^10 * 100
	end
	local compression = 1
	if wheel:FindFirstChild("Collision") then
		compression = math.clamp((wheel.Position-wheel.Collision.Position).Magnitude/.1, 0, 1)
	end
	local trailAttachmentPart = wheel:FindFirstChild("TrailAttachmentPart")
	if trailAttachmentPart and smokeStress > 0.05 and wheel.Velocity.Magnitude > 10 then
		trailAttachmentPart.TrailAttachment0.Position = Vector3.new(wheel.Size.X/2-.2 + .1*compression, .02, 0)
		trailAttachmentPart.TrailAttachment1.Position = Vector3.new(-wheel.Size.X/2+.2 - .1*compression, .02, 0)
		trailAttachmentPart.AlignOrientation.CFrame = CFrame.lookAt(smokePart.Position, (smokePart.CFrame * CFrame.new(0, 0, -5 + math.min(wheel.Velocity.Magnitude, 5))).Position+wheel.Velocity, rayNormal or smokePart.CFrame.UpVector)
	end

	smokePart.SmokePartAttachment1.Position = Vector3.new(0, wheel.Size.Y/2 + _Tune.AxleSize, 0) + smokePart.CFrame:VectorToObjectSpace(wheel.Velocity)*dt
end

local function stop()
	if not car or not car.Parent then return end

	local wheelsFolder = car:FindFirstChild("Wheels")
	if not wheelsFolder then return end

	for _, wheel in next, wheelsFolder:GetChildren() do
		if not wheel:IsA("BasePart") then continue end
		local smokePart = wheel:FindFirstChild("SmokePart")
		if not smokePart then continue end

		for _, d in next, smokePart:GetChildren() do
			if d:IsA("Sound") then d.Playing = false end
			if d:IsA("ParticleEmitter") then d.Enabled = false end
			if d:IsA("Trail") then d.Enabled = false end
		end
	end
end

script.Parent.OnServerEvent:Connect(update)
car.DriveSeat.ChildAdded:Connect(function(child)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		canUpdate = true
	end
end)
car.DriveSeat.ChildRemoved:Connect(function(child)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		canUpdate = false
		stop()
	end
end)

local wheelTuneThing = nil
for i, desc in car["A-Chassis Tune"]["A-Chassis Interface"]:GetDescendants() do
	if desc:IsA("ModuleScript") and desc.Name == "Tune" and desc:GetAttribute("ID") == "A-Chassis Tires" then
		wheelTuneThing = require(desc)
		break
	end
end

if not wheelTuneThing then
	warn(script:GetFullName() .. ": Tires tune not found")
	script.Enabled = false
	return
end

create(wheelTuneThing)
