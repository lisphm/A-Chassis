--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- By detocoyote

-- Editable values
local LineLifetime = 1
local FPS = 15
local PollingRate = 60
local AntiJitter = 8

-- The rest of the script

-- Values
local car = script.Parent.Parent.Car.Value
local values = script.Parent.Parent.Values

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Units = require(car["A-Chassis Tune"].README.Units)
local _Tune = require(car["A-Chassis Tune"])

local gauge = script.Parent.Frame
local AccelerationValue = values.Acceleration
local history = {}
local framePool = {}

-- Visibility toggles
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if not gameProcessedEvent then
		if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonL3 then
			script.Parent.Visible = not script.Parent.Visible
		end
	end
end)

gauge.ToggleNum.MouseButton1Click:Connect(function()
	gauge.XNum.Visible = not gauge.XNum.Visible
	gauge.YNum.Visible = not gauge.YNum.Visible
end)

-- Runtime loop
local function removeFrame(frame)
	frame.Parent = nil
	table.insert(framePool, frame)
end

local function PollingLoop()
	while task.wait(1/PollingRate) do
		local value = AccelerationValue.Value
				
		-- Values
		local accel = value*Vector3.new(1, 0, 1)/(Units.Velocity_mdivs)/((_Tune.GravComp>0 and _Tune.GravComp or workspace.Gravity)*(Units.Length_mm/1000))
		local g = -(car.Body["#Weight"].CFrame:VectorToObjectSpace(accel))

		-- GForce damping and setting things
		if g.Unit ~= g.Unit then g = Vector3.new(0.001, 0, 0) end -- Prevent 0, 0, 0

		table.insert(history, g.Magnitude * g.Unit)
		if #history > AntiJitter then
			table.remove(history, 1)
		end
	end
end

local function UpdateLoop()
	while task.wait(1/FPS) do
		local avgPos = Vector3.new()
		for _, pos in history do
			avgPos += pos
		end
		avgPos /= #history

		-- Clamping only, use avgPos for the actual values
		local old = gauge.Indicator.Position
		local indicatorPosition = avgPos.Unit * math.clamp(avgPos.Magnitude, 0, 3)
		gauge.Indicator.Position = UDim2.new(math.clamp(0.5 + 0.5*(indicatorPosition.X/3), -1, 1), 0, math.clamp(0.5 + 0.5*(indicatorPosition.Z/3), -1, 1), 0)

		-- Set discrete numbers
		gauge.XNum.Text = string.format("%.1f", math.round(avgPos.X * 10)/10)
		gauge.XNum.Text = gauge.XNum.Text == "-0.0" and "0.0" or gauge.XNum.Text
		gauge.YNum.Text = string.format("%.1f", math.round(avgPos.Z * 10)/10)
		gauge.YNum.Text = gauge.YNum.Text == "-0.0" and "0.0" or gauge.YNum.Text

		-- Frame stuff
		local vec = Vector2.new(((gauge.Indicator.Position-old)).X.Scale, (gauge.Indicator.Position-old).Y.Scale)
		local frame: Frame
		if framePool[1] then
			frame = framePool[1]
			table.remove(framePool, 1)
		else
			frame = Instance.new("Frame")
			frame.Name = "Visual"
			frame.AnchorPoint = Vector2.new(.5, .5)
			frame.BackgroundColor3 = Color3.new(1,1,1)
			frame.BackgroundTransparency = 0.8
			frame.BorderSizePixel = 0
		end
		frame.Size = UDim2.new(vec.Magnitude, 0, .01, 0)
		frame.Rotation = math.atan(vec.Unit.Y/vec.Unit.X)*(180/math.pi)
		frame.Position = old:Lerp(gauge.Indicator.Position, .5)
		frame.Parent = gauge.Visuals

		-- Removal
		task.delay(LineLifetime, removeFrame, frame)
	end
end

task.spawn(PollingLoop)
task.spawn(UpdateLoop)
