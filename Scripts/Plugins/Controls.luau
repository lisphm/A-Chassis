--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- rewritten by Detomiks
local UserInputService = game:GetService("UserInputService")
local playermouse = game:GetService("Players").LocalPlayer:GetMouse()

local car = script.Parent.Parent.Car.Value
local Controls = script.Parent.Parent:WaitForChild("Controls")
local ControlsOpen = script.Parent.Parent.ControlsOpen
local _Tune = require(car["A-Chassis Tune"])

local window = script.Parent.Window
local open = false

local allEntries = {}

local con1, con2 = nil, nil
local canInput, inputType, inputKey = false, nil, nil

local d, s, t = Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if not gameProcessedEvent then
		if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonL3 then
			script.Parent.Visible = not script.Parent.Visible
		end
	end
end)

--setup
local keyboard = window.KeyboardSF
local mouse = keyboard:Clone() mouse.Name = "MouseSF" mouse.Position = UDim2.new(1, 5, 0, 80) mouse.Parent = window
local contlr = keyboard:Clone() contlr.Name = "ControllerSF" contlr.Position = UDim2.new(2, 5, 0, 80) contlr.Parent = window

for name, keycode in pairs(_Tune.Controls) do
	local entry = keyboard.Placeholder:Clone()
	entry.Name = name
	entry.TextButton.Text = keycode.Name
	entry.Visible = true
	
	if string.find(name, "Mouse") then
		entry.Text = string.gsub(name, "Mouse", "")
		entry.Parent = mouse
	elseif string.find(name, "Contlr") then
		entry.Text = string.gsub(name, "Contlr", "")
		entry.Parent = contlr
	else
		entry.Text = name
		entry.Parent = keyboard
	end
	table.insert(allEntries, entry)
end

for name, value in pairs(_Tune.Peripherals) do
	local entry = keyboard.PlaceholderPeripheral:Clone()
	entry.Name = name
	entry.Frame.TextButton.Position = UDim2.new(value/100, 0, .5, 0)
	entry.Frame.TextButton.TextBox.Text = math.round(value) .."%"
	entry.Visible = true

	if string.find(name, "M") then
		entry.Text = string.gsub(name, "M", "")
		entry.Parent = mouse
	elseif string.find(name, "Control") then
		entry.Text = string.gsub(name, "Control", "")
		entry.Parent = contlr
	else
		entry.Text = name
		entry.Parent = keyboard
	end
	table.insert(allEntries, entry)
end

--navigation
local function navTo(button)
	for _, v in next, window:GetChildren() do
		if v:IsA("TextButton") then
			if v.Name == button.Name then
				v.BackgroundColor3 = Color3.new(1,1,1)
				v.BackgroundTransparency = 0
				v.TextColor3 = Color3.new()
				v.UIGradient.Enabled = false
				v.Frame.Visible = true
			else
				v.BackgroundColor3 = Color3.new()
				v.BackgroundTransparency = .5
				v.TextColor3 = Color3.new(1,1,1)
				v.UIGradient.Enabled = true
				v.Frame.Visible = false
			end
		end
	end
	window.Highlight:TweenPosition(UDim2.new(button.Position.X.Scale, 0, 0, 77), d, s, t, true, nil)
	local pos = 0
	if button.Name == "Controller" then
		pos = -2
	elseif button.Name == "Mouse" then
		pos = -1
	end
	keyboard:TweenPosition(UDim2.new(pos, 5, 0, 80), d, s, t, true, nil)
	mouse:TweenPosition(UDim2.new(pos + 1, 5, 0, 80), d, s, t, true, nil)
	contlr:TweenPosition(UDim2.new(pos + 2, 5, 0, 80), d, s, t, true, nil)
end
window.Controller.MouseButton1Click:Connect(function()
	navTo(window.Controller)
end)
window.Mouse.MouseButton1Click:Connect(function()
	navTo(window.Mouse)
end)
window.Keyboard.MouseButton1Click:Connect(function()
	navTo(window.Keyboard)
end)

--key assigning
for _, entry in next, allEntries do
	local button = entry:FindFirstChildWhichIsA("TextButton")
	if button then --this is a normal key press thing
		button.MouseButton1Click:Connect(function()
			if con1 then con1:Disconnect() end
			if con2 then con2:Disconnect() end
			ControlsOpen.Value = true
			window.Overlay.Visible = true
			canInput = true
			
			con1 = UserInputService.InputBegan:Connect(function(input)
				if canInput then
					inputKey, inputType = input.KeyCode, input.UserInputType
				end
			end)
			con2 = UserInputService.InputChanged:Connect(function(input)
				if canInput and (input.KeyCode==Enum.KeyCode.Thumbstick1 or input.KeyCode==Enum.KeyCode.Thumbstick2) then
					inputKey, inputType = input.KeyCode, input.UserInputType
				end
			end)
			
			repeat wait() until inputKey
			if con1 then con1:Disconnect() end
			if con2 then con2:Disconnect() end
			
			if inputKey == Enum.KeyCode.Return or inputKey == Enum.KeyCode.KeypadEnter then
				-- do nothing
			elseif string.find(entry.Name, "Contlr") then
				if string.find(inputType.Name, "Gamepad") then
					Controls[entry.Name].Value = inputKey.Name
					entry.TextButton.Text = inputKey.Name
				else
					window.Error.Visible = true
				end
			elseif entry.Name == "MouseThrottle" or entry.Name == "MouseBrake" then
				if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.MouseButton2 then
					Controls[entry.Name].Value = inputType.Name
					button.Text = inputType.Name
				elseif inputType ==  Enum.UserInputType.Keyboard then
					Controls[entry.Name].Value = inputKey.Name
					button.Text = inputKey.Name	
				else
					window.Error.Visible = true
				end	
			else
				if inputType == Enum.UserInputType.Keyboard then
					Controls[entry.Name].Value = inputKey.Name
					button.Text = inputKey.Name
				else
					window.Error.Visible = true
				end
			end
			
			inputKey, inputType, canInput = nil, nil, false
			wait(.2)
			window.Overlay.Visible = false
			ControlsOpen.Value = false
		end)
	else --this is a slider
		local holding = false
		entry.Frame.TextButton.MouseButton1Down:Connect(function()
			holding = true
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				holding = false
			end
		end)
		playermouse.Move:Connect(function()
			if holding then
				local x = (playermouse.X-entry.Frame.AbsolutePosition.X)/entry.Frame.AbsoluteSize.X
				entry.Frame.TextButton.Position = UDim2.new(math.clamp(x, 0, 1), 0, .5, 0)
			end
		end)
		entry.Frame.TextButton.Changed:Connect(function()
			Controls[entry.Name].Value = entry.Frame.TextButton.Position.X.Scale * 100
			entry.Frame.TextButton.TextBox.Text = math.round(Controls[entry.Name].Value).."%"
		end)
		entry.Frame.TextButton.TextBox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
			if entry.Frame.TextButton.TextBox.CursorPosition == -1 then
				entry.Frame.TextButton.Position = UDim2.new(math.clamp((tonumber(entry.Frame.TextButton.TextBox.Text) or Controls[entry.Name].Value)/100,0,1), 0, .5, 0)
			end
		end)
	end
end

window.Error:GetPropertyChangedSignal("Visible"):Connect(function()
	wait(3)
	window.Error.Visible = false
end)

script.Parent.Toggle.MouseButton1Click:Connect(function()
	if open then
		script.Parent.Toggle.BackgroundColor3 = Color3.new(0,0,0)
		script.Parent.Toggle.BackgroundTransparency = .5
		script.Parent.Toggle.UIGradient.Enabled = true
		script.Parent.Toggle.TextColor3 = Color3.new(1,1,1)
		window:TweenPosition(UDim2.new(.5, 0, 1.5, 0), d, s, t, true, nil)
		open = false
	else
		script.Parent.Toggle.BackgroundColor3 = Color3.new(1,1,1)
		script.Parent.Toggle.BackgroundTransparency = 0
		script.Parent.Toggle.UIGradient.Enabled = false
		script.Parent.Toggle.TextColor3 = Color3.new(0,0,0)
		window:TweenPosition(UDim2.new(.5, 0, .5, 0), d, s, t, true, nil)
		open = true
	end
end)


