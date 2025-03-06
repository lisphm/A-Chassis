--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- By Detomiks

-- Editable values
local LineLifetime = 3
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
local history = {}

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
RunService.Heartbeat:Connect(function()
	-- Values
	local accel: Vector3 = values.Acceleration.Value*Vector3.new(1, 0, 1)/(Units.Velocity_mdivs)/((_Tune.GravComp>0 and _Tune.GravComp or workspace.Gravity)*(Units.Length_mm/1000))
	local g: Vector3 = -(car.Body["#Weight"].CFrame:VectorToObjectSpace(accel))
	local old: UDim2 = gauge.Indicator.Position
	
	-- GForce damping and setting things
	table.insert(history, g.Magnitude * g.Unit)
	
	if #history > AntiJitter then
		table.remove(history, 1)
	end
	local avgPos = Vector3.new()
	for _, pos in history do
		avgPos += pos
	end
	avgPos /= #history
	
	-- Clamping only, use avgPos for the actual values
	local indicatorPosition = avgPos.Unit * math.clamp(avgPos.Magnitude, 0, 3)
	gauge.Indicator.Position = UDim2.new(0.5 + 0.5*(indicatorPosition.X/3), 0, 0.5 + 0.5*(indicatorPosition.Z/3), 0)
	
	-- Set discrete numbers
	gauge.XNum.Text = string.format("%.1f", math.round(avgPos.X * 10)/10)
	gauge.XNum.Text = gauge.XNum.Text == "-0.0" and "0.0" or gauge.XNum.Text
	gauge.YNum.Text = string.format("%.1f", math.round(avgPos.Z * 10)/10)
	gauge.YNum.Text = gauge.YNum.Text == "-0.0" and "0.0" or gauge.YNum.Text
	
	-- Frame stuff
	local vec = Vector2.new(((gauge.Indicator.Position-old)).X.Scale, (gauge.Indicator.Position-old).Y.Scale)
	local frame = Instance.new("Frame", gauge.Visuals)
	frame.Name = "Visual"
	frame.Size = UDim2.new(vec.Magnitude, 0, .01, 0)
	frame.AnchorPoint = Vector2.new(.5, .5)
	frame.Rotation = math.atan(vec.Unit.Y/vec.Unit.X)*(180/math.pi)
	frame.Position = old:Lerp(gauge.Indicator.Position, .5)
	frame.BackgroundColor3 = Color3.new(1,1,1)
	frame.BorderSizePixel = 0
	frame:SetAttribute("time", tick())
	
	-- Basic offloading of removal to Debris
	Debris:AddItem(frame, LineLifetime)
	for _, f in next, gauge.Visuals:GetChildren() do
		f.BackgroundTransparency = .8 + .2*((tick()-f:GetAttribute("time"))/LineLifetime)
	end
end)