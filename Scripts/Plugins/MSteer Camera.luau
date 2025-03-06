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
local values = script.Parent.Values
local cam = workspace.CurrentCamera
local RS = game:GetService("RunService")

car.DriveSeat.ChildRemoved:connect(function(child)
	if child.Name=="SeatWeld" then
		RS:UnbindFromRenderStep("MCam")
		cam.CameraType = Enum.CameraType.Custom
	end
end)

script.Parent.Values.MouseSteerOn.Changed:connect(function(property)
	if script.Parent.Values.MouseSteerOn.Value then
		RS:BindToRenderStep("MCam",Enum.RenderPriority.Camera.Value,function()	
			cam.CameraType = Enum.CameraType.Scriptable
			local pspeed = math.min(1, values.Velocity.Value.Magnitude/500)
			local cc = values.Center.Value.Position+Vector3.new(0,8+(pspeed*2),0)-(values.Center.Value.LookVector*17)+(values.Velocity.Value.Unit*-7*pspeed)
			cam.CFrame = CFrame.lookAt(cc, values.Center.Value.Position)
		end)
	else
		RS:UnbindFromRenderStep("MCam")
		cam.CameraType = Enum.CameraType.Custom
	end
end)