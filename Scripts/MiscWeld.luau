--[[    
       ___  _____
      / _ |/ ___/    	Avxnturador       	| Novena                            midmm5        |
     / __ / /__        	LuaInt             	| Novena                            
    /_/ |_\___/         Detomiks        	| Base Chassis

                    Version 1.7
                    
	*Credit to VanillaEdge for this MiscWeld refresh.
                    
--]]
local MiscWeld = {}

-- Create weld between two parts and optional motor setup
function MakeWeld(part1, part2, weldType, motorSpeed ) 
    if weldType == nil then weldType = "Weld" end
    local weld = Instance.new(weldType, part1) 
    weld.Part0 = part1
    weld.Part1 = part2
    weld.C0 = part1.CFrame:inverse() * part1.CFrame 
    weld.C1 = part2.CFrame:inverse() * part1.CFrame 
    if weldType == "Motor" and motorSpeed ~= nil then 
        weld.MaxVelocity = motorSpeed 
    end 
    return weld
end

-- Welds all parts within an instance to a target part
function ModelWeld(model, target) 
    if model:IsA("BasePart") then 
        MakeWeld(target, model, "Weld") 
    end 
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            MakeWeld(part, target)
        end
    end
end

car = script.Parent.Parent.Parent
misc = car:WaitForChild("Misc")

---------------------------

--[[
    Usage Guide:
    Main anchor point is the DriveSeat <car.DriveSeat>
    
    1. MakeWeld: Connects two parts with a weld. Use for simple connections.
        - Syntax: MakeWeld(part1, part2, [weldType], [motorSpeed])
        - Example: MakeWeld(car.DriveSeat, misc.PassengerSeat) -- Default weld
                   MakeWeld(car.DriveSeat, misc.SteeringWheel, "Motor", 0.2) -- Motor with speed
    
    2. ModelWeld: Welds an entire model to a target part
        - Syntax: ModelWeld(model, targetPart)
        - Example: ModelWeld(misc.FrontBumper, car.DriveSeat)
    
    3. FolderWeld: Welds all parts within a folder to a target part
        - Syntax: FolderWeld(folder, targetPart)
        - Example: FolderWeld(misc.Accessories, car.DriveSeat)
       
]]

--[[Weld stuff below here]]

-- This is the default character offset for the driveseat
car.DriveSeat.ChildAdded:connect(function(child)
    if child.Name=="SeatWeld" and child:IsA("Weld") and game.Players:GetPlayerFromCharacter(child.Part1.Parent)~=nil then
        child.C0=CFrame.new(0,-.5,0)*CFrame.fromEulerAnglesXYZ(-(math.pi/2),0,0)*CFrame.Angles(math.rad(13),0,0)
    end
end)

---------------------------
return MiscWeld