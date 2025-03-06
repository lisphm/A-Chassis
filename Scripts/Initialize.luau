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
script.Parent.Parent.DriveSeat.Disabled = true -- Prevents entering the car before initialization

_BuildVersion = require(script.Parent.README)

--[[Weld functions]]
function MakeWeldConstraint(x, y)
	local W = Instance.new("WeldConstraint", x)
	W.Name = "Weld"
	W.Part0 = x
	W.Part1 = y
	return W
end

function MakeWeld(x, y, type, s) 
	if type==nil then type="Weld" end
	if type == "Weld" then
		return MakeWeldConstraint(x, y)
	end
	local W=Instance.new(type, x) 
	W.Part0=x W.Part1=y 
	W.C0=x.CFrame:inverse()*x.CFrame 
	W.C1=y.CFrame:inverse()*x.CFrame 
	if type=="Motor" and s~=nil then 
		W.MaxVelocity=s 
	end 
	return W	
end

function ModelWeld(a, b) 
	if a:IsA("BasePart") then 
		MakeWeld(b, a) 
	end 
	for _, v in a:GetDescendants() do
		if v:IsA("BasePart") then
			MakeWeld(v, b)
		end
	end
end

function Unanchor(a) 
	if a:IsA("BasePart") then a.Anchored=false end 
	for i, v in (a:GetDescendants()) do 
		if v:IsA("BasePart") then
			v.Anchored = false 
		end
	end 
end

--[[Initialize]]
script.Parent:WaitForChild("A-Chassis Interface")
script.Parent:WaitForChild("Plugins")
script.Parent:WaitForChild("README")

local car = script.Parent.Parent
local Wheels = {}
local Drive = Wheels
local _Tune=require(script.Parent)
local Units = require(car["A-Chassis Tune"].README.Units)

for _, v in car.Wheels:GetChildren() do
	if (v.Name == "FL" or v.Name == "FR" or v.Name == "F" or v.Name == "RL" or v.Name == "RR" or v.Name == "R") and v:IsA("BasePart") then
		table.insert(Wheels, v)
	end
end

task.wait(_Tune.LoadDelay)

--Remove Existing Mass
function DReduce(p)
	for i, v in (p:GetDescendants())do
		if v:IsA("BasePart") then
			v.Massless = true --(LuaInt) but it's just this line
		end
	end
end
DReduce(car)

-- GravComp function
function MakeGravity(x: BasePart)
	local attachment = x:FindFirstChild("#GRAVCOMP_ATTACH") or Instance.new("Attachment", x)
	attachment.Name = "#GRAVCOMP_ATTACH"
	local force = x:FindFirstChild("#GRAVCOMP") or Instance.new("VectorForce", x)
	force.Name = "#GRAVCOMP"
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.Attachment0 = attachment
	force.Force = Vector3.new(0, _Tune.GravComp > 0 and x.Mass*(workspace.Gravity-_Tune.GravComp) or 0, 0)
	
	if x.Massless then
		force:Destroy()
		attachment:Destroy()
	end
end

--[[Wheel Configuration]]
function GetCarCenter()
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

local fDistX=_Tune.FWsBoneLen*math.cos(math.rad(_Tune.FWsBoneAngle))
local fDistY=_Tune.FWsBoneLen*math.sin(math.rad(_Tune.FWsBoneAngle))
local rDistX=_Tune.RWsBoneLen*math.cos(math.rad(_Tune.RWsBoneAngle))
local rDistY=_Tune.RWsBoneLen*math.sin(math.rad(_Tune.RWsBoneAngle))

local fSLX=_Tune.FSusLength*math.cos(math.rad(_Tune.FSusAngle))
local fSLY=_Tune.FSusLength*math.sin(math.rad(_Tune.FSusAngle))
local rSLX=_Tune.RSusLength*math.cos(math.rad(_Tune.RSusAngle))
local rSLY=_Tune.RSusLength*math.sin(math.rad(_Tune.RSusAngle))

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
		wdensity = (_Tune.FWheelWeight*Units.Mass_kg)/(math.pi*(v.Size.Y/2)^2*(v.Size.X))
	else
		wdensity = (_Tune.RWheelWeight*Units.Mass_kg)/(math.pi*(v.Size.Y/2)^2*(v.Size.X))
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
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(_Tune.FCaster), math.rad(-_Tune.FToe), math.rad(_Tune.FCamber))
	elseif v.Name=="FR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-_Tune.FCaster), math.rad(_Tune.FToe), math.rad(_Tune.FCamber))
	elseif v.Name=="RL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(_Tune.RCaster), math.rad(-_Tune.RToe), math.rad(_Tune.RCamber))
	elseif v.Name=="RR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-_Tune.RCaster), math.rad(_Tune.RToe), math.rad(_Tune.RCamber))
	end

	for _, a in WParts do
		a[1].CFrame = v.CFrame*a[2]
	end

	--[[Chassis Assembly]]
	--Create Steering Axle
	local arm = Instance.new("Part", v)
	arm.Name = "Arm"
	arm.Anchored = true
	arm.CanCollide = false
	arm.FormFactor = Enum.FormFactor.Custom
	arm.Size = Vector3.new(_Tune.AxleSize, _Tune.AxleSize, _Tune.AxleSize)
	arm.CFrame = v.CFrame
	arm.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(_Tune.AxleDensity, 0.01, 100), 0, 0, 100, 100)
	arm.TopSurface = Enum.SurfaceType.Smooth
	arm.BottomSurface = Enum.SurfaceType.Smooth
	arm.Transparency = 1

	--Create Wheel Spindle
	local base=arm:Clone()
	base.Parent=v
	base.Name="Base"
	base.CFrame=arm.CFrame*CFrame.new(0, _Tune.AxleSize, 0)

	local SteerOuter = (_Tune.LockToLock*180)/_Tune.SteerRatio
	local SteerInner = math.min(SteerOuter-(SteerOuter*(1-_Tune.Ackerman)), SteerOuter*1.2)
	if not string.find(v.Name, "F") then
		SteerOuter = _Tune.RSteerOuter
		SteerInner = _Tune.RSteerInner
	elseif _Tune.SteeringType == "Manual" then
		SteerOuter = _Tune.SteerOuter
		SteerInner = _Tune.SteerInner
	end

	--Create Steering Anchor
	local axle = arm:Clone()
	axle.Parent = v
	axle.Name = "Axle"
	axle.CFrame = v.CFrame*CFrame.new(v.Size.X/2+_Tune.AxleSize/2, 0, 0)

	--Create Powered Axle (LuaInt)
	local axlep = arm:Clone()
	axlep.Parent = v
	axlep.Name = 'AxleP'
	axlep.CFrame = v.CFrame
	MakeWeld(axlep, axle)

	--Create Suspension
	if _Tune.SuspensionEnabled==true then
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
					p.CustomPhysicalProperties=PhysicalProperties.new(math.clamp(_Tune.CustomSuspensionDensity, 0.01, 100), 0, 0, 0, 0)
					p.Massless = _Tune.CustomSuspensionDensity <= 0
					p.Transparency = _Tune.SusVisible and 0.5 or 1
				end
				if p:IsA("Constraint") then
					p.Visible = _Tune.SusVisible
				end
			end

			sp=SuspensionGeometry:FindFirstChild('Spring')
			sp.LimitsEnabled = true
			sp.Visible=_Tune.SpringsVisible
			sp.Radius=_Tune.SusRadius
			sp.Thickness=_Tune.SusThickness
			sp.Color=BrickColor.new(_Tune.SusColor)
			sp.Coils=_Tune.SusCoilCount

			local swayBar = SuspensionGeometry:FindFirstChild("SwayBar")
			if swayBar and swayBar.Attachment0 and swayBar.Attachment1 then
				swayBar.Attachment0.Position = Vector3.new(swayBar.Attachment0.Parent.CFrame:ToObjectSpace(GetCarCenter()).Position.X - 0.05, 0, 0)
				swayBar.Attachment1.Position = Vector3.new(swayBar.Attachment1.Parent.CFrame:ToObjectSpace(GetCarCenter()).Position.X - 0.05, 0, 0)
				swayBar.Damping = 20
				swayBar.FreeLength = 0.1
			end
			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				sp.Damping = _Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = _Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm -- 9806.65 converts kgf/mm to N/m
				sp.FreeLength = _Tune.FSusLength+_Tune.FPreCompress
				sp.MaxLength = _Tune.FSusLength+_Tune.FExtensionLim
				sp.MinLength = _Tune.FSusLength-_Tune.FCompressLim
				if swayBar then
					swayBar.Stiffness = _Tune.FSwayBar * 9806.65 * Units.Stiffness_Ndivm
				end
			else
				sp.Damping = _Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = _Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = _Tune.RSusLength+_Tune.RPreCompress
				sp.MaxLength = _Tune.RSusLength+_Tune.RExtensionLim
				sp.MinLength = _Tune.RSusLength-_Tune.RCompressLim
				if swayBar then
					swayBar.Stiffness = _Tune.RSwayBar * 9806.65 * Units.Stiffness_Ndivm
				end
			end
		else
			local legacyCFrame = v.CFrame*CFrame.Angles(math.rad(90), 0, math.rad(90)) -- not gonna bother fixing the entire thing so i just put this because it works

			local sa=arm:Clone()
			sa.Parent=v
			sa.Name="#SA"
			sa.CFrame = (legacyCFrame)*CFrame.Angles(-math.pi/2, -math.pi/2, 0)
			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				local aOff = _Tune.FAnchorOffset
				sa.CFrame=legacyCFrame*CFrame.new(_Tune.AxleSize/2, -fDistX, -fDistY)*CFrame.new(aOff[3], aOff[1], -aOff[2])*CFrame.Angles(-math.pi/2, -math.pi/2, 0)
			else
				local aOff = _Tune.RAnchorOffset
				sa.CFrame=legacyCFrame*CFrame.new(_Tune.AxleSize/2, -rDistX, -rDistY)*CFrame.new(aOff[3], aOff[1], -aOff[2])*CFrame.Angles(-math.pi/2, -math.pi/2, 0)
			end

			local sb=sa:Clone()
			sb.Parent=v
			sb.Name="#SB"
			sb.CFrame=sa.CFrame*CFrame.new(0, 0, _Tune.AxleSize)
			sb.FrontSurface=Enum.SurfaceType.Hinge	

			local sf1 = Instance.new("Attachment", sa)
			sf1.Name = "SAtt"

			local sf2 = sf1:Clone()
			sf2.Parent = sb

			--(Avxnturador) adds spring offset
			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				local aOff = _Tune.FSpringOffset
				if v.Name == "FL" then
					sf1.Position = Vector3.new(fDistX-fSLX+aOff[1], -fDistY+fSLY+aOff[2], _Tune.AxleSize/2+aOff[3])
					sf2.Position = Vector3.new(fDistX+aOff[1], -fDistY+aOff[2], -_Tune.AxleSize/2+aOff[3])
				else
					sf1.Position = Vector3.new(fDistX-fSLX+aOff[1], -fDistY+fSLY+aOff[2], _Tune.AxleSize/2-aOff[3])
					sf2.Position = Vector3.new(fDistX+aOff[1], -fDistY+aOff[2], -_Tune.AxleSize/2-aOff[3])
				end
			elseif v.Name == "RL" or v.Name=="RR" or v.Name == "R" then
				local aOff = _Tune.RSpringOffset
				if v.Name == "RL" then
					sf1.Position = Vector3.new(rDistX-rSLX+aOff[1], -rDistY+rSLY+aOff[2], _Tune.AxleSize/2+aOff[3])
					sf2.Position = Vector3.new(rDistX+aOff[1], -rDistY+aOff[2], -_Tune.AxleSize/2+aOff[3])
				else
					sf1.Position = Vector3.new(rDistX-rSLX+aOff[1], -rDistY+rSLY+aOff[2], _Tune.AxleSize/2-aOff[3])
					sf2.Position = Vector3.new(rDistX+aOff[1], -rDistY+aOff[2], -_Tune.AxleSize/2-aOff[3])
				end
			end

			sb:MakeJoints()
			--(LuaInt) there was axle:makejoints here I believe, but the new powered axle manually welds itself so I ditched it

			local sp = Instance.new("SpringConstraint", v)
			sp.Name = "Spring"
			sp.Attachment0 = sf1
			sp.Attachment1 = sf2
			sp.LimitsEnabled = true

			sp.Visible=_Tune.SpringsVisible
			sp.Radius=_Tune.SusRadius
			sp.Thickness=_Tune.SusThickness
			sp.Color=BrickColor.new(_Tune.SusColor)
			sp.Coils=_Tune.SusCoilCount

			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				sp.Damping = _Tune.FSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = _Tune.FSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = _Tune.FSusLength+_Tune.FPreCompress
				sp.MaxLength = _Tune.FSusLength+_Tune.FExtensionLim
				sp.MinLength = _Tune.FSusLength-_Tune.FCompressLim
			else
				sp.Damping = _Tune.RSusDamping * 1000 * Units.Damping_N_sdivm
				sp.Stiffness = _Tune.RSusStiffness * 9806.65 * Units.Stiffness_Ndivm
				sp.FreeLength = _Tune.RSusLength+_Tune.RPreCompress
				sp.MaxLength = _Tune.RSusLength+_Tune.RExtensionLim
				sp.MinLength = _Tune.RSusLength-_Tune.RCompressLim
			end

			MakeWeld(car.DriveSeat, sa)
			MakeWeld(sb, base)
		end
	else
		MakeWeld(car.DriveSeat, base)
	end

	--Lock Rear Steering Axle
	if (_Tune.FWSteer=='Static' or _Tune.FWSteer=='Speed' or _Tune.FWSteer=='Both') == false then
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

	if (v.Name=='FR' or v.Name=='FL' or v.Name=='F') or (_Tune.FWSteer=='Static' or _Tune.FWSteer=='Speed' or _Tune.FWSteer=='Both') then
		local steer
		if _Tune.PowerSteeringType == "New" then
			local steerAttach0 = Instance.new("Attachment", arm)
			steerAttach0.Name = "SteerAttach0"
			local steerAttach1 = Instance.new("Attachment", base)
			steerAttach1.Name = "SteerAttach1"
			steer = Instance.new("AlignOrientation", arm)
			steer.Name = "Steer"
			steer.Mode = Enum.OrientationAlignmentMode.TwoAttachment
			steer.ReactionTorqueEnabled = true
			steer.RigidityEnabled = true
			steer.Attachment0 = steerAttach0
			steer.Attachment1 = steerAttach1
		else
			steer = Instance.new("BodyGyro", arm)
			if string.find(v.Name, "F") then
				steer.P=_Tune.SteerP
				steer.D=_Tune.SteerD
				steer.MaxTorque=Vector3.new(0, _Tune.SteerMaxTorque, 0)
			else
				steer.P=_Tune.RSteerP
				steer.D=_Tune.RSteerD
				steer.MaxTorque=Vector3.new(0, _Tune.RSteerMaxTorque, 0)
			end
		end
		steer.Name="Steer"
		steer.CFrame=v.CFrame
	end

	--Add rotation constraint (Detomiks)
	local rotationAttachment0 = Instance.new("Attachment", base)
	rotationAttachment0.Name = "RotationAttachment0"
	rotationAttachment0.Position = Vector3.new(0, -_Tune.AxleSize/2, 0)
	rotationAttachment0.Orientation = Vector3.new(0, 0, 90)
	
	local rotationAttachment1 = Instance.new("Attachment", arm)
	rotationAttachment1.Name = "RotationAttachment1"
	rotationAttachment1.Position = Vector3.new(0, _Tune.AxleSize/2, 0)
	rotationAttachment1.Orientation = Vector3.new(0, 0, 90)
	
	local rotationHinge = Instance.new("HingeConstraint", base)
	rotationHinge.Name = "Rotate"
	rotationHinge.LimitsEnabled = true
	rotationHinge.UpperAngle = math.max(SteerOuter, SteerInner)
	rotationHinge.LowerAngle = -rotationHinge.UpperAngle
	rotationHinge.Attachment0 = rotationAttachment0
	rotationHinge.Attachment1 = rotationAttachment1

	--Add Motors (LuaInt)
	local AV=Instance.new("HingeConstraint", v)
	AV.ActuatorType='Motor'
	AV.Attachment0=Instance.new("Attachment", v.AxleP)
	AV.Attachment0.Name='AA'
	AV.Attachment1=Instance.new("Attachment", v)
	AV.Attachment1.Name='AB'
	AV.Name="#AV"
	AV.AngularVelocity=0
	AV.MotorMaxTorque=0

	local BV=Instance.new("HingeConstraint", v)
	BV.ActuatorType='Motor'
	BV.Attachment0=Instance.new("Attachment", v.AxleP)
	BV.Attachment0.Name='BA'
	BV.Attachment1=Instance.new("Attachment", v)
	BV.Attachment1.Name='BB'
	BV.Name="#BV"
	BV.AngularVelocity=0
	if string.find(v.Name, "F") then
		BV.MotorMaxTorque = (_Tune.PBrakeForce * 9.80665 * Units.Force_N) * _Tune.PBrakeBias
	else
		BV.MotorMaxTorque = (_Tune.PBrakeForce * 9.80665 * Units.Force_N) * (1-_Tune.PBrakeBias)
	end

	-- Attempt to fix wheel alignment issues
	if string.find(v.Name, "L") or v.Name=="R" or v.Name == "F" then
		AV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		AV.Attachment1.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment1.Orientation = Vector3.new(0, 180, 0)
	end
end

--[[Vehicle Weight]]	
task.wait()

--Determine Current Mass
local mass=0

function getMass(p)
	for i, v in (p:GetDescendants())do
		if v:IsA("BasePart") and not v.Massless then
			mass=mass+v.Mass
		end
	end	
end
getMass(car)

--Apply Vehicle Weight
if mass*Units.Mass_kg < _Tune.Weight*0.453592 then
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
	local center = centerR:Lerp(centerF, _Tune.WeightDist/100) 

	--Create Weight Brick
	local weightB = Instance.new("Part", car.Body)
	weightB.Name = "#Weight"
	weightB.Anchored = true
	weightB.CanCollide = false
	weightB.BrickColor = BrickColor.new("Really black")
	weightB.TopSurface = Enum.SurfaceType.Smooth
	weightB.BottomSurface = Enum.SurfaceType.Smooth
	if _Tune.WBVisible then
		weightB.Transparency = .75			
	else
		weightB.Transparency = 1			
	end

	weightB.Size = Vector3.new(_Tune.WeightBSize[1], _Tune.WeightBSize[2], _Tune.WeightBSize[3])/Units.Length_mm
	local tdensity = (_Tune.Weight*Units.Mass_kg - mass)/(weightB.Size.X*weightB.Size.Y*weightB.Size.Z) --fixed by denkodin
	weightB.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(tdensity, 0.01, 100), 0, 0, 0, 0)
	--Real life mass in pounds, converted to kg minus existing roblox mass converted to kg, divided by volume of the weight brick in cubic meters, divided by the density of water
	weightB.CFrame = (car.DriveSeat.CFrame-car.DriveSeat.Position+center)*CFrame.new(0, _Tune.CGHeight, 0)

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
		.."\n\t Target Mass:\t"..math.ceil(_Tune.Weight*Units.Mass_kg)
		.."\n\t Current Mass:\t"..math.ceil(mass)
		.."\n\t Reduce part size or axle density to achieve desired weight.")
end

-- Gravcomp
for _, object in car:GetDescendants() do
	if not object:IsA("BasePart") then continue end
	MakeGravity(object)
end

local flipG
if _Tune.FlipType == "New" then
	local flipAttach = Instance.new("Attachment", car.DriveSeat)
	flipAttach.Axis = Vector3.new(0, 1, 0)

	flipG = Instance.new("AlignOrientation", car.DriveSeat)
	flipG.Name = "Flip"
	flipG.Attachment0 = flipAttach
	flipG.AlignType = Enum.AlignType.PrimaryAxisParallel
	flipG.RigidityEnabled = true
	flipG.Enabled = false
	flipG.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flipG.PrimaryAxis = Vector3.new(0, 1, 0)
elseif _Tune.FlipType == "Old" then
	flipG = Instance.new("BodyGyro", car.DriveSeat)
	flipG.Name = "Flip"
	flipG.D = 0
	flipG.MaxTorque = Vector3.new(0, 0, 0)
	flipG.P = 0
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

-- Set network owner
task.wait()
car.DriveSeat:SetNetworkOwner(nil)

--[[Manage Plugins]]
task.wait()
script.Parent["A-Chassis Interface"].Car.Value = car
for i, v in (script.Parent.Plugins:GetChildren()) do
	for _, a in (v:GetChildren()) do
		if a:IsA("BaseRemoteEvent") or a:IsA("RemoteFunction") then 
			a.Parent = car
			for _, b in (a:GetChildren()) do
				if b:IsA("Script") then b.Enabled = true end
			end	
		end
	end
	v.Parent = script.Parent["A-Chassis Interface"]
end
script.Parent.Plugins:Destroy()

--[[Remove Character Weight]]
--Get Seats
local Seats = {}
function getSeats(p)
	for i, v in (p:GetDescendants()) do
		if v:IsA("VehicleSeat") or v:IsA("Seat") then
			local seat = {}
			seat.Seat = v
			seat.Parts = {}
			table.insert(Seats, seat)
		end
	end	
end
getSeats(car)

--Store Physical Properties/Remove Mass Function
function getPProperties(character, t)
	for _, v in character:GetDescendants() do
		if v:IsA("BasePart") then
			table.insert(t, {v, v.Massless})
			v.Massless = true
		end
	end
end

--Apply Seat Handler
for i, v in (Seats) do
	--Sit Handler
	v.Seat.ChildAdded:Connect(function(child)
		if child.Name=="SeatWeld" and child:IsA("Weld") and child.Part1 and child.Part1.Parent ~= workspace and not child.Part1.Parent:IsDescendantOf(car) then
			v.Parts = {}
			getPProperties(child.Part1.Parent, v.Parts)
		end
	end)

	--Leave Handler
	v.Seat.ChildRemoved:Connect(function(child)
		if child.Name=="SeatWeld" and child:IsA("Weld") then
			for i, v in (v.Parts) do
				if v[1] and v[1]:IsDescendantOf(workspace) then
					v[1].Massless = v[2]
				end
			end
			v.Parts = {}
		end
	end)
end

--[[Driver Handling]]

--Driver Sit
car.DriveSeat.ChildAdded:Connect(function(child)
	if child.Name=="SeatWeld" and child:IsA("Weld") and game.Players:GetPlayerFromCharacter(child.Part1.Parent)~=nil then
		--Distribute Client Interface
		local p=game.Players:GetPlayerFromCharacter(child.Part1.Parent)
		car.DriveSeat:SetNetworkOwner(p)
		local g=script.Parent["A-Chassis Interface"]:Clone()
		g.Parent=p.PlayerGui
	end
end)

--Driver Leave
car.DriveSeat.ChildRemoved:Connect(function(child)
	if child.Name=="SeatWeld" and child:IsA("Weld") then
		--Remove Client Interface
		local p=game.Players:GetPlayerFromCharacter(child.Part1.Parent)
		for _, v in p.PlayerGui:GetChildren() do
			if v.Name == "A-Chassis Interface" then
				v:Destroy()
			end
		end
		
		--Remove Flip Force
		if car.DriveSeat:FindFirstChild("Flip") then
			if _Tune.FlipType == "New" then
				car.DriveSeat.Flip.Enabled = false
			else
				car.DriveSeat.Flip.MaxTorque = Vector3.new()
			end
		end

		for _, wheel in Wheels do
			-- Remove wheel force
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
			
			-- Readjust steering
			if wheel.Arm:FindFirstChild("Steer") then
				if _Tune.PowerSteeringType == "New" then
					wheel.Arm.Steer.Attachment0.Orientation = Vector3.new(0, -wheel.Base.Rotate.CurrentAngle, 0)
				else
					wheel.Arm.Steer.CFrame = wheel.Base.CFrame * CFrame.Angles(0, math.rad(wheel.Base.Rotate.CurrentAngle), 0)
				end
			end
		end
	end
end)

--Allow entering the car now that everything is initialized
script.Parent.Parent.DriveSeat.Disabled = false

--[END]]