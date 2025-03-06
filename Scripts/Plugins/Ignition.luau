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
--------------------------------------------------------------------------

local IGNITION_KEYBOARD = Enum.KeyCode.F
local IGNITION_CONTROLLER = Enum.KeyCode.ButtonB

local UserInputService = game:GetService("UserInputService")
local gamepadPresent = UserInputService.GamepadEnabled

local function onInput(input:InputObject, gameProcessedEvent:boolean)
	if gameProcessedEvent then return end
	if not (input.KeyCode == IGNITION_KEYBOARD or input.KeyCode == IGNITION_CONTROLLER) then return end
	if script.Parent.Parent.IsOn.Value and not script.Parent.Parent.IsOn.Starting.Value then
		if input.UserInputState == Enum.UserInputState.End then return end
		script.Parent.Parent.IsOn.Value = false
	else
		script.Parent.Parent.IsOn.Starting.Value = input.UserInputState == Enum.UserInputState.Begin
	end
end

local function update()
	gamepadPresent = UserInputService.GamepadEnabled
	script.Parent.Text = "Hold <i><stroke color='#000000' thickness='2'><font weight='900'>"..(gamepadPresent and IGNITION_CONTROLLER.Name or IGNITION_KEYBOARD.Name).."</font></stroke></i> to turn on."
	script.Parent.Visible = not script.Parent.Parent.IsOn.Value
end

UserInputService.InputBegan:Connect(onInput)
UserInputService.InputChanged:Connect(onInput)
UserInputService.InputEnded:Connect(onInput)

UserInputService.GamepadConnected:Connect(update)
UserInputService.GamepadDisconnected:Connect(update)
script.Parent.Parent.IsOn.Changed:Connect(update)
update()