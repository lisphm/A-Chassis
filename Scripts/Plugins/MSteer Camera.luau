--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- By vanilla01 and detocoyote

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local camera = workspace.CurrentCamera
local frame = script.Parent

local car = frame.Parent.Car.Value :: Model
local values = frame.Parent.Values :: Folder
local seat = car.DriveSeat :: VehicleSeat
local wheels = car.Wheels:GetChildren() :: { BasePart }

local valuesMouseSteerOn = values.MouseSteerOn :: BoolValue
local valuesVelocity = values.Velocity :: Vector3Value

local RENDER_STEPPED_BIND_NAME = "MCam"
local RENDER_STEPPED_BIND_PRIORITY = Enum.RenderPriority.Camera.Value

-- Functions
local function GetCenter()
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	for i, wheel in wheels do
		if string.find(wheel.Name, "F") then
			centerF = centerF + wheel.Position
			countF = countF + 1
		else
			centerR = centerR + wheel.Position
			countR = countR + 1
		end
	end
	centerF = centerF / countF
	centerR = centerR / countR
	local center = CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
	return center
end

local function onUpdate()
	local velocity = valuesVelocity.Value
	local center = GetCenter()
	
	local pspeed = math.min(1, velocity.Magnitude / 500)
	local cc = center.Position + Vector3.new(0, 8 + (pspeed * 2), 0) - (center.LookVector * 17) + (velocity.Unit * -7 * pspeed)
	camera.CFrame = CFrame.lookAt(cc, center.Position)
	
	local centerX = camera.ViewportSize.X / 2
	local inset = GuiService:GetGuiInset() :: UDim2
	
	local height = mouse.Y + inset.Y
	local width = mouse.X - centerX
	
	frame.Position = UDim2.new(0, centerX, 0, height)
	frame.Size = UDim2.new(0, width, 0, 2)
end

local function onMouseSteerChanged()
	local value = valuesMouseSteerOn.Value
	frame.Visible = value
	
	if value then
		camera.CameraType = Enum.CameraType.Scriptable
		RunService:BindToRenderStep(RENDER_STEPPED_BIND_NAME, RENDER_STEPPED_BIND_PRIORITY, onUpdate)
	else
		camera.CameraType = Enum.CameraType.Custom
		RunService:UnbindFromRenderStep(RENDER_STEPPED_BIND_NAME)
	end
end

local function onChildRemoved(child: Instance)
	if child.Name == "SeatWeld" then
		camera.CameraType = Enum.CameraType.Custom
		RunService:UnbindFromRenderStep(RENDER_STEPPED_BIND_NAME)
	end
end

-- Connections
valuesMouseSteerOn:GetPropertyChangedSignal("Value"):Connect(onMouseSteerChanged)
seat.ChildRemoved:Connect(onChildRemoved)

-- Initialise
onMouseSteerChanged()
