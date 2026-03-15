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
local Players = game:GetService("Players")
script.Parent.Parent.DriveSeat.Disabled = true -- Prevents entering the car before initialization

local _BuildVersion = require(script.Parent.README)

--[[Weld functions]]
local function MakeWeldConstraint(x, y)
	local W = Instance.new("WeldConstraint")
	W.Name = "Weld"
	W.Part0 = x
	W.Part1 = y
	W.Parent = x
	return W
end

local function MakeWeld(x, y, type, s) 
	if type==nil then type="Weld" end
	if type == "Weld" then
		return MakeWeldConstraint(x, y)
	end
	local W=Instance.new(type) 
	W.Part0=x W.Part1=y 
	W.C0=x.CFrame:inverse()*x.CFrame 
	W.C1=y.CFrame:inverse()*x.CFrame 
	W.Parent = x
	if type=="Motor" and s~=nil then 
		W.MaxVelocity=s 
	end 
	return W	
end

local function ModelWeld(a, b) 
	if a:IsA("BasePart") then 
		MakeWeld(b, a) 
	end 
	for _, v in a:GetDescendants() do
		if v:IsA("BasePart") then
			MakeWeld(v, b)
		end
	end
end

local function Unanchor(a) 
	if a:IsA("BasePart") then a.Anchored=false end 
	for i, v in (a:GetDescendants()) do 
		if v:IsA("BasePart") then
			v.Anchored = false 
		end
	end 
end

--[[Initialize]]
local car = script.Parent.Parent
local seat = car.DriveSeat

local Wheels = {}
local Drive = Wheels
local Tune = require(script.Parent)
local Units = require(car["A-Chassis Tune"].README.Units)

local shutdownEvent = Instance.new("UnreliableRemoteEvent", script.Parent)
shutdownEvent.Name = "Shutdown"

for _, v in car.Wheels:GetChildren() do
	if (v.Name == "FL" or v.Name == "FR" or v.Name == "F" or v.Name == "RL" or v.Name == "RR" or v.Name == "R") and v:IsA("BasePart") then
		table.insert(Wheels, v)
	end
end

task.wait(Tune.LoadDelay)

--Remove Existing Mass
for i, descendant in car:GetDescendants() do
	if descendant:IsA("BasePart") then
		descendant.Massless = true
	end
end

--[[Wheel Configuration]]
local function GetCarCenter()
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

--PGS/Legacy
task.wait() -- Add waits to help server speed as the car loads

local fDistX=Tune.FWsBoneLen*math.cos(math.rad(Tune.FWsBoneAngle))
local fDistY=Tune.FWsBoneLen*math.sin(math.rad(Tune.FWsBoneAngle))
local rDistX=Tune.RWsBoneLen*math.cos(math.rad(Tune.RWsBoneAngle))
local rDistY=Tune.RWsBoneLen*math.sin(math.rad(Tune.RWsBoneAngle))

local fSLX=Tune.FSusLength*math.cos(math.rad(Tune.FSusAngle))
local fSLY=Tune.FSusLength*math.sin(math.rad(Tune.FSusAngle))
local rSLX=Tune.RSusLength*math.cos(math.rad(Tune.RSusAngle))
local rSLY=Tune.RSusLength*math.sin(math.rad(Tune.RSusAngle))

for _, v in Drive do
	-- Remove non-parts
	if not v:IsA("BasePart") then 
		table.remove(Drive, table.find(Drive, v))
		continue
	end
	
	--Apply Wheel Density
	local cpp = v.CurrentPhysicalProperties
	local wdensity = 0
	if string.find(v.Name, "F") then
		wdensity = (Tune.FWheelWeight*Units.Mass_kg)/(math.pi*(v.Size.Y/2)^2*(v.Size.X))
	else
		wdensity = (Tune.RWheelWeight*Units.Mass_kg)/(math.pi*(v.Size.Y/2)^2*(v.Size.X))
	end
	v.CustomPhysicalProperties = PhysicalProperties.new(
		wdensity, 
		cpp.Friction, 
		cpp.Elasticity, 
		cpp.FrictionWeight, 
		cpp.ElasticityWeight
	)
	v.Massless = false

	--Save wheel part positions
	local WParts = {}
	for _, a in v.Parts:GetDescendants() do
		if not a:IsA("BasePart") then continue end
		table.insert(WParts, {a, v.CFrame:ToObjectSpace(a.CFrame)})
	end
	for _, a in v.WheelFixed:GetDescendants() do
		if not a:IsA("BasePart") then continue end
		table.insert(WParts, {a, v.CFrame:ToObjectSpace(a.CFrame)})
	end

	--Align Wheels
	if v.Name=="FL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.FCaster), math.rad(-Tune.FToe), math.rad(Tune.FCamber))
	elseif v.Name=="FR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.FCaster), math.rad(Tune.FToe), math.rad(Tune.FCamber))
	elseif v.Name=="RL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.RCaster), math.rad(-Tune.RToe), math.rad(Tune.RCamber))
	elseif v.Name=="RR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.RCaster), math.rad(Tune.RToe), math.rad(Tune.RCamber))
	end

	for _, a in WParts do
		a[1].CFrame = v.CFrame*a[2]
	end

	--[[Chassis Assembly]]
	--Create Steering Axle
	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Anchored = true
	arm.CanCollide = false
	arm.Size = Vector3.new(Tune.AxleSize, Tune.AxleSize, Tune.AxleSize)
	arm.CFrame = v.CFrame
	arm.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(Tune.AxleDensity, 0.01, 100), 0, 0, 100, 100)
	arm.TopSurface = Enum.SurfaceType.Smooth
	arm.BottomSurface = Enum.SurfaceType.Smooth
	arm.Transparency = 1
	arm.Parent = v

	--Create Wheel Spindle
	local base=arm:Clone()
	base.Name="Base"
	base.CFrame=arm.CFrame*CFrame.new(0, Tune.AxleSize, 0)
	base.Parent=v

	local SteerOuter = (Tune.LockToLock*180)/Tune.SteerRatio
	local SteerInner = math.min(SteerOuter-(SteerOuter*(1-Tune.Ackerman)), SteerOuter*1.2)
	if not string.find(v.Name, "F") then
		SteerOuter = Tune.RSteerOuter
		SteerInner = Tune.RSteerInner
	elseif Tune.SteeringType == "Manual" then
		SteerOuter = Tune.SteerOuter
		SteerInner = Tune.SteerInner
	end

	--Create Steering Anchor
	local axle = arm:Clone()
	axle.Name = "Axle"
	axle.CFrame = v.CFrame*CFrame.new(v.Size.X/2+Tune.AxleSize/2, 0, 0)
	axle.Parent = v

	--Create Powered Axle (LuaInt)
	local axlep = arm:Clone()
	axlep.Name = 'AxleP'
	axlep.CFrame = v.CFrame
	axlep.Parent = v
	MakeWeld(axlep, axle)

	--Create Suspension
	if Tune.SuspensionEnabled==true then
		local SuspensionGeometry=v:FindFirstChild("SuspensionGeometry")
		if SuspensionGeometry then
			for _, a in SuspensionGeometry:GetDescendants() do
				if a.Name == "Weld" then
					if a:IsA("BasePart") then
						MakeWeld(a, car.DriveSeat)
					elseif a:IsA("Model") then
						ModelWeld(a, car.DriveSeat)
					end
				end
			end
			MakeWeld(SuspensionGeometry.Hub, base)
			if SuspensionGeometry:FindFirstChild("SpringTop") then
				MakeWeld(SuspensionGeometry.SpringTop, car.DriveSeat)
			end
			
			local susparts=SuspensionGeometry:GetDescendants()
			for _, p in susparts do
				if p:IsA('Part') then
					p.CustomPhysicalProperties=PhysicalProperties.new(math.clamp(Tune.CustomSuspensionDensity, 0.01, 100), 0, 0, 0, 0)
					if Tune.CustomSuspensionDensity <= 0 then
						p.Massless = true -- So we only set it to true, rather than overriding it with false like before
					end
					p.Transparency = Tune.SusVisible and 0.5 or 1
				end
				if p:IsA("Constraint") then
					p.Visible = Tune.SusVisible
				end
			end
			
			sp=SuspensionGeometry:FindFirstChild('Spring')
			sp.LimitsEnabled = true
			sp.Visible=Tune.SpringsVisible
			sp.Radius=Tune.SusRadius
			sp.Thickness=Tune.SusThickness
			sp.Color=BrickColor.new(Tune.SusColor)
			sp.Coils=Tune.SusCoilCount

			local swayBar = SuspensionGeometry:FindFirstChild("SwayBar")
			if swayBar and swayBar.Attachment0 and swayBar.Attachment1 then
				swayBar.Attachment0.Position = Vector3.new(swayBar.Attachment0.Parent.CFrame:ToObjectSpace(GetCarCenter()).Position.X - 0.05, 0, 0)
				swayBar.Attachment1.Position = Vector3.new(swayBar.Attachment1.Parent.CFrame:ToObjectSpace(GetCarCenter()).Position.X - 0.05, 0, 0)
				swayBar.Damping = 20
				swayBar.FreeLength = 0.1				
			end
			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				sp.Damping = Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm -- 9806.65 converts kgf/mm to N/m
				sp.FreeLength = Tune.FSusLength+Tune.FPreCompress
				sp.MaxLength = Tune.FSusLength+Tune.FExtensionLim
				sp.MinLength = Tune.FSusLength-Tune.FCompressLim
				if swayBar then
					swayBar.Stiffness = Tune.FSwayBar * 9806.65 * Units.Stiffness_Ndivm
				end
			else
				sp.Damping = Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = Tune.RSusLength+Tune.RPreCompress
				sp.MaxLength = Tune.RSusLength+Tune.RExtensionLim
				sp.MinLength = Tune.RSusLength-Tune.RCompressLim
				if swayBar then
					swayBar.Stiffness = Tune.RSwayBar * 9806.65 * Units.Stiffness_Ndivm
				end
			end
		else
			local legacyCFrame = v.CFrame*CFrame.Angles(math.rad(90), 0, math.rad(90)) -- not gonna bother fixing the entire thing so i just put this because it works

			local sa=arm:Clone()
			sa.Parent=v
			sa.Name="#SA"
			sa.CFrame = (legacyCFrame)*CFrame.Angles(-math.pi/2, -math.pi/2, 0)
			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				local aOff = Tune.FAnchorOffset
				sa.CFrame=legacyCFrame*CFrame.new(Tune.AxleSize/2, -fDistX, -fDistY)*CFrame.new(aOff[3], aOff[1], -aOff[2])*CFrame.Angles(-math.pi/2, -math.pi/2, 0)
			else
				local aOff = Tune.RAnchorOffset
				sa.CFrame=legacyCFrame*CFrame.new(Tune.AxleSize/2, -rDistX, -rDistY)*CFrame.new(aOff[3], aOff[1], -aOff[2])*CFrame.Angles(-math.pi/2, -math.pi/2, 0)
			end

			local sb=sa:Clone()
			sb.Parent=v
			sb.Name="#SB"
			sb.CFrame=sa.CFrame*CFrame.new(0, 0, Tune.AxleSize)
			sb.FrontSurface=Enum.SurfaceType.Hinge	

			local sf1 = Instance.new("Attachment")
			sf1.Name = "SAtt"
			sf1.Parent = sa

			local sf2 = sf1:Clone()
			sf2.Parent = sb

			--(Avxnturador) adds spring offset
			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				local aOff = Tune.FSpringOffset
				if v.Name == "FL" then
					sf1.Position = Vector3.new(fDistX-fSLX+aOff[1], -fDistY+fSLY+aOff[2], Tune.AxleSize/2+aOff[3])
					sf2.Position = Vector3.new(fDistX+aOff[1], -fDistY+aOff[2], -Tune.AxleSize/2+aOff[3])
				else
					sf1.Position = Vector3.new(fDistX-fSLX+aOff[1], -fDistY+fSLY+aOff[2], Tune.AxleSize/2-aOff[3])
					sf2.Position = Vector3.new(fDistX+aOff[1], -fDistY+aOff[2], -Tune.AxleSize/2-aOff[3])
				end
			elseif v.Name == "RL" or v.Name=="RR" or v.Name == "R" then
				local aOff = Tune.RSpringOffset
				if v.Name == "RL" then
					sf1.Position = Vector3.new(rDistX-rSLX+aOff[1], -rDistY+rSLY+aOff[2], Tune.AxleSize/2+aOff[3])
					sf2.Position = Vector3.new(rDistX+aOff[1], -rDistY+aOff[2], -Tune.AxleSize/2+aOff[3])
				else
					sf1.Position = Vector3.new(rDistX-rSLX+aOff[1], -rDistY+rSLY+aOff[2], Tune.AxleSize/2-aOff[3])
					sf2.Position = Vector3.new(rDistX+aOff[1], -rDistY+aOff[2], -Tune.AxleSize/2-aOff[3])
				end
			end

			sb:MakeJoints()
			--(LuaInt) there was axle:makejoints here I believe, but the new powered axle manually welds itself so I ditched it

			local sp = Instance.new("SpringConstraint")
			sp.Name = "Spring"
			sp.Attachment0 = sf1
			sp.Attachment1 = sf2
			sp.LimitsEnabled = true

			sp.Visible=Tune.SpringsVisible
			sp.Radius=Tune.SusRadius
			sp.Thickness=Tune.SusThickness
			sp.Color=BrickColor.new(Tune.SusColor)
			sp.Coils=Tune.SusCoilCount
			
			sp.Parent = v

			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				sp.Damping = Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = Tune.FSusLength+Tune.FPreCompress
				sp.MaxLength = Tune.FSusLength+Tune.FExtensionLim
				sp.MinLength = Tune.FSusLength-Tune.FCompressLim
			else
				sp.Damping = Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = Tune.RSusLength+Tune.RPreCompress
				sp.MaxLength = Tune.RSusLength+Tune.RExtensionLim
				sp.MinLength = Tune.RSusLength-Tune.RCompressLim
			end

			MakeWeld(car.DriveSeat, sa)
			MakeWeld(sb, base)
		end
	else
		local SuspensionGeometry=v:FindFirstChild("SuspensionGeometry")
		if SuspensionGeometry then
			SuspensionGeometry:ClearAllChildren()
		end
		MakeWeld(car.DriveSeat, base)
	end

	--Lock Rear Steering Axle
	if (Tune.FWSteer=='Static' or Tune.FWSteer=='Speed' or Tune.FWSteer=='Both') == false then
		if v.Name == "RL" or v.Name == "RR" or v.Name=="R" then
			MakeWeld(base, axle)
		end
	end

	MakeWeld(arm, axle)

	--Weld Miscelaneous Parts
	if v:FindFirstChild("SuspensionFixed")~=nil then
		ModelWeld(v.SuspensionFixed, car.DriveSeat)
	end
	if v:FindFirstChild("WheelFixed")~=nil then
		ModelWeld(v.WheelFixed, axle)
	end
	if v:FindFirstChild("Fixed")~=nil then
		ModelWeld(v.Fixed, arm)
	end

	--Weld Wheel Parts
	if v:FindFirstChild("Parts")~=nil then
		ModelWeld(v.Parts, v)
	end

	--Add Steering Gyro
	if v:FindFirstChild("Steer") then
		v:FindFirstChild("Steer"):Destroy()
	end

	if (v.Name=='FR' or v.Name=='FL' or v.Name=='F') or (Tune.FWSteer=='Static' or Tune.FWSteer=='Speed' or Tune.FWSteer=='Both') then
		local steer
		if Tune.PowerSteeringType == "New" then
			local steerAttach0 = Instance.new("Attachment")
			steerAttach0.Name = "SteerAttach0"
			steerAttach0.Parent = arm
			
			local steerAttach1 = Instance.new("Attachment")
			steerAttach1.Name = "SteerAttach1"
			steerAttach1.Parent = base
			
			steer = Instance.new("AlignOrientation")
			steer.Name = "Steer"
			steer.Mode = Enum.OrientationAlignmentMode.TwoAttachment
			steer.ReactionTorqueEnabled = true
			steer.RigidityEnabled = true
			steer.Attachment0 = steerAttach0
			steer.Attachment1 = steerAttach1
		else
			steer = Instance.new("BodyGyro")
			if string.find(v.Name, "F") then
				steer.P=Tune.SteerP
				steer.D=Tune.SteerD
				steer.MaxTorque=Vector3.new(0, Tune.SteerMaxTorque, 0)
			else
				steer.P=Tune.RSteerP
				steer.D=Tune.RSteerD
				steer.MaxTorque=Vector3.new(0, Tune.RSteerMaxTorque, 0)
			end
		end
		steer.Name="Steer"
		steer.CFrame=v.CFrame
		steer.Parent = v.Arm
	end

	--Add rotation constraint (Detomiks)
	local rotationAttachment0 = Instance.new("Attachment")
	rotationAttachment0.Name = "RotationAttachment0"
	rotationAttachment0.Position = Vector3.new(0, -Tune.AxleSize/2, 0)
	rotationAttachment0.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment0.Parent = base
	
	local rotationAttachment1 = Instance.new("Attachment")
	rotationAttachment1.Name = "RotationAttachment1"
	rotationAttachment1.Position = Vector3.new(0, Tune.AxleSize/2, 0)
	rotationAttachment1.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment1.Parent = arm
	
	local rotationHinge = Instance.new("HingeConstraint")
	rotationHinge.Name = "Rotate"
	rotationHinge.LimitsEnabled = true
	rotationHinge.UpperAngle = math.max(SteerOuter, SteerInner)
	rotationHinge.LowerAngle = -rotationHinge.UpperAngle
	rotationHinge.Attachment0 = rotationAttachment0
	rotationHinge.Attachment1 = rotationAttachment1
	rotationHinge.Parent = base

	--Add Motors (LuaInt)
	local AV=Instance.new("HingeConstraint")
	AV.ActuatorType='Motor'
	AV.Parent = v
	AV.Attachment0=Instance.new("Attachment")
	AV.Attachment0.Name='AA'
	AV.Attachment0.Parent = v.AxleP
	AV.Attachment1=Instance.new("Attachment")
	AV.Attachment1.Name='AB'
	AV.Attachment1.Parent = v
	AV.Name="#AV"
	AV.AngularVelocity=0
	AV.MotorMaxTorque=0

	local BV=Instance.new("HingeConstraint")
	BV.ActuatorType='Motor'
	BV.Parent = v
	BV.Attachment0=Instance.new("Attachment")
	BV.Attachment0.Parent = v.AxleP
	BV.Attachment0.Name='BA'
	BV.Attachment1=Instance.new("Attachment")
	BV.Attachment1.Name='BB'
	BV.Attachment1.Parent = v
	BV.Name="#BV"
	BV.AngularVelocity=0
	if string.find(v.Name, "F") then
		BV.MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * Tune.PBrakeBias
	else
		BV.MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * (1-Tune.PBrakeBias)
	end

	-- Attempt to fix wheel alignment issues
	if string.find(v.Name, "L") or v.Name=="R" or v.Name == "F" then
		AV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		AV.Attachment1.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment1.Orientation = Vector3.new(0, 180, 0)
	end
	
	--Realign Caster
	if v.Name=="FL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.FCaster), 0, 0)
	elseif v.Name=="FR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.FCaster), 0, 0)
	elseif v.Name=="RL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.RCaster), 0, 0)
	elseif v.Name=="RR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.RCaster), 0, 0)
	end
end

--[[Vehicle Weight]]	
task.wait()

--Determine Current Mass
local mass=0

local function getMass(p)
	for i, v in (p:GetDescendants())do
		if v:IsA("BasePart") and not v.Massless then
			mass=mass+v.Mass
		end
	end	
end
getMass(car)

--Apply Vehicle Weight
if mass*Units.Mass_kg < Tune.Weight*0.453592 then
	--Calculate Weight Distribution
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0

	for i, v in (Drive) do
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
	local center = centerR:Lerp(centerF, Tune.WeightDist/100) 

	--Create Weight Brick
	local weightB = Instance.new("Part")
	weightB.Name = "#Weight"
	weightB.Anchored = true
	weightB.CanCollide = false
	weightB.BrickColor = BrickColor.new("Really black")
	weightB.TopSurface = Enum.SurfaceType.Smooth
	weightB.BottomSurface = Enum.SurfaceType.Smooth
	if Tune.WBVisible then
		weightB.Transparency = .75			
	else
		weightB.Transparency = 1			
	end

	weightB.Size = Vector3.new(Tune.WeightBSize[1], Tune.WeightBSize[2], Tune.WeightBSize[3])/Units.Length_mm
	local tdensity = (Tune.Weight*Units.Mass_kg - mass)/(weightB.Size.X*weightB.Size.Y*weightB.Size.Z) --fixed by denkodin
	weightB.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(tdensity, 0.01, 100), 0, 0, 0, 0)
	--Real life mass in pounds, converted to kg minus existing roblox mass converted to kg, divided by volume of the weight brick in cubic meters, divided by the density of water
	weightB.CFrame = (car.DriveSeat.CFrame-car.DriveSeat.Position+center)*CFrame.new(0, Tune.CGHeight, 0)
	weightB.Parent = car.Body
	
	--Density Cap
	if weightB.CustomPhysicalProperties.Density>=100 then
		warn( "\n\t [A-Chassis ".._BuildVersion.."]: Density too high for specified volume."
			.."\n\t Current Density:\t"..math.ceil(tdensity)
			.."\n\t Max Density:\t"..math.ceil(weightB.CustomPhysicalProperties.Density)
			.."\n\t Increase weight brick size to compensate.")
	end
else
	--Existing Weight Is Too Massive
	warn( "\n\t [A-Chassis ".._BuildVersion.."]: Mass too high for specified weight."
		.."\n\t Target Mass:\t"..math.ceil(Tune.Weight*Units.Mass_kg)
		.."\n\t Current Mass:\t"..math.ceil(mass)
		.."\n\t Reduce part size or axle density to achieve desired weight.")
end

-- Gravcomp
for i, descendent in car:GetDescendants() do
	local valid = descendent:IsA("BasePart") and not descendent.Massless
	if not valid then 
		continue
	end
	
	local attachment = descendent:FindFirstChild("#GRAVCOMP_ATTACH") or Instance.new("Attachment")
	attachment.Name = "#GRAVCOMP_ATTACH"
	attachment.Parent = descendent

	local force = descendent:FindFirstChild("#GRAVCOMP") or Instance.new("VectorForce")
	force.Name = "#GRAVCOMP"
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass  = true
	force.Attachment0 = attachment
	force.Force = Vector3.new(0, Tune.GravComp > 0 and descendent.Mass * (workspace.Gravity - Tune.GravComp) or 0, 0)
	force.Enabled = Tune.GravComp > 0
	force.Parent = descendent
end

local flipG
if Tune.FlipType == "New" then
	local flipAttach = Instance.new("Attachment")
	flipAttach.Axis = Vector3.new(0, 1, 0)
	flipAttach.Parent = car.DriveSeat

	flipG = Instance.new("AlignOrientation")
	flipG.Name = "Flip"
	flipG.Attachment0 = flipAttach
	flipG.AlignType = Enum.AlignType.PrimaryAxisParallel
	flipG.RigidityEnabled = true
	flipG.Enabled = false
	flipG.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flipG.PrimaryAxis = Vector3.new(0, 1, 0)
	flipG.Parent = car.DriveSeat
elseif Tune.FlipType == "Old" then
	flipG = Instance.new("BodyGyro")
	flipG.Name = "Flip"
	flipG.D = 0
	flipG.MaxTorque = Vector3.new(0, 0, 0)
	flipG.P = 0
	flipG.Parent = car.DriveSeat
end

--[[Finalize Chassis]]	
task.wait()

--Misc Weld
for i, v in (script:GetChildren()) do
	if v:IsA("ModuleScript") then
		require(v)
	end
end

--Weld Body
task.wait()
ModelWeld(car.Body, car.DriveSeat)

--Unanchor
task.wait()
Unanchor(car)

--[[Manage Plugins]]
task.wait()

local plugins = script.Parent.Plugins
local interface = script.Parent["A-Chassis Interface"]
interface.Car.Value = car

for i, v in plugins:GetChildren() do
	for _, a in v:GetChildren() do
		if a:IsA("BaseRemoteEvent") or a:IsA("RemoteFunction") then 
			a.Parent = car
			for _, b in (a:GetChildren()) do
				if b:IsA("Script") then b.Enabled = true end
			end	
		end
	end
	v.Parent = interface
end

plugins:Destroy()

local function shutdown(player)
	for _, child in player.PlayerGui:GetChildren() do
		if child.Name == "A-Chassis Interface" then
			child:Destroy()
		end
	end
end

--[[Remove Character Weight]]

-- Get Seats
local Seats = {}

local function getSeats(group: Instance)
	for _, descendant in group:GetDescendants() do
		if descendant:IsA("VehicleSeat") or descendant:IsA("Seat") then
			local cache = {}
			cache.Seat = descendant		-- Seat Instance
			cache.Parts = {}			-- Player Part Storage
			table.insert(Seats, cache)
		end
	end	
end

getSeats(car)

-- Store Physical Properties/Remove Mass Function
local function handleCharacter(character, tbl)
	for _, v in character:GetDescendants() do
		if v:IsA("BasePart") then
			table.insert(tbl, {v, v.Massless})
			v.Massless = true
		end
	end
end

--Apply Seat Handler
for _, data in Seats do
	local seatObject = data.Seat :: Seat
	local parts = data.Parts

	seatObject:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seatObject.Occupant and seatObject.Occupant.Parent
		if occupant then
			handleCharacter(occupant, parts)
		else
			for _, entry in parts do
				entry[1].Massless = entry[2]
			end
			table.clear(parts)
		end
	end)
end

--[[Destroying Cleanup]]
seat.AncestryChanged:Connect(function()
	if seat.Parent then return end
	task.wait(10) -- Delay for clients to finish up
	if car then
		car:Destroy()
	end
end)

--[[Driver Handling]]

-- Driver Sit
seat.ChildAdded:Connect(function(child: Instance)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		local player = Players:GetPlayerFromCharacter(child.Part1.Parent)
		if not player then return end

		car.DriveSeat:SetNetworkOwner(player)

		local clone = interface:Clone()
		clone.Parent = player.PlayerGui
	end
end)

--Driver Leave
seat.ChildRemoved:Connect(function(child: Instance)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		-- Safety check in case vehicle destroying
		if not seat.Parent then return end
		
		-- Remove Flip Force
		if seat:FindFirstChild("Flip") then
			if Tune.FlipType == "New" then
				seat.Flip.Enabled = false
			else
				seat.Flip.MaxTorque = Vector3.new()
			end
		end
		
		-- Handle wheel changes
		for _, wheel in Wheels do
			-- Apply handbrake
			if wheel:FindFirstChild("#BV") and Tune.ExitBrake then
				if string.find(wheel.Name, "F") then
					wheel["#BV"].MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * Tune.PBrakeBias
				else
					wheel["#BV"].MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * (1-Tune.PBrakeBias)
				end
			end
			
			-- Remove wheel force
			if wheel:FindFirstChild("#AV") then
				wheel["#AV"].MotorMaxTorque = 0
				wheel["#AV"].AngularVelocity = 0
			end
			
			-- Readjust steering
			if wheel.Arm:FindFirstChild("Steer") then
				if Tune.PowerSteeringType == "New" then
					wheel.Arm.Steer.Attachment0.Orientation = Vector3.new(0, -wheel.Base.Rotate.CurrentAngle, 0)
				else
					wheel.Arm.Steer.CFrame = wheel.Base.CFrame * CFrame.Angles(0, math.rad(wheel.Base.Rotate.CurrentAngle), 0)
				end
			end
		end
	end
end)

--Driver mental breakdown
shutdownEvent.OnServerEvent:Connect(function(player)
	if not player:FindFirstChild("PlayerGui") then return end
	for _, v in player.PlayerGui:GetChildren() do
		if v.Name ~= "A-Chassis Interface" then continue end
		v:Destroy()
	end
end)

--Allow entering the car now that everything is initialized
task.wait(1)
script.Parent.Parent.DriveSeat.Disabled = false

--[END]]
