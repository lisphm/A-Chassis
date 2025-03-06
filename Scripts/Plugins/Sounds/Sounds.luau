--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- You can edit the sound properties in the sounds under the script, or you can change where sounds are stored and if there is Filtering Enabled in here.

local car = script.Parent.Car.Value
local values = script.Parent.Values
local event = car:WaitForChild("Sounds")

-- [[ EDIT ]] -------------------------------------------------------------------------

local FE			= true										-- If true, this makes sounds play for everyone in the game, not just the driver.
local FE_RATE		= 1/60										-- FE must equal true. This changes how often the sound updates for the player. Higher = updates less often.
local DIRECTORY		= car.Body:FindFirstChild("Sounds")			-- This is the path of the sounds group or model to use.

-- [[ END EDIT ]] -------------------------------------------------------------------------

local RunService = game:GetService("RunService")

local _Tune = require(car["A-Chassis Tune"])
local Units = require(car["A-Chassis Tune"].README.Units)
local sounds = {}
local vvl = 0
local AverageRotSpeed = 0

-- Index all the sounds
if FE then
	event:FireServer("create", script:GetChildren(), DIRECTORY)
	-- Since plugins are cloned server-sided, we can use script:GetChildren() because the server can see the sound objects.
else
	for _, sound in next, script:GetChildren() do
		if not sound:IsA("Sound") then continue end

		local newSound = sound:Clone()

		table.insert(sounds, newSound)

		newSound.Playing = false
		newSound.Volume = 0
		newSound.Parent = DIRECTORY:FindFirstChild(newSound:GetAttribute("SoundParent")) or car.Body["#Weight"]
		if string.sub(newSound.Name, 1, 3) ~= "ENG" then continue end
		-- Three letter codes can be used with string.sub!

		if newSound:FindFirstChild("OffDistortion") then newSound.OffDistortion.Enabled = false end
		if newSound:FindFirstChild("OffEQ") then newSound.OffEQ.Enabled = false end
		if newSound:FindFirstChild("ThrottleDistortion") then newSound.ThrottleDistortion.Enabled = false end
		if newSound:FindFirstChild("ThrottleEQ") then newSound.ThrottleEQ.Enabled = false end
		if newSound:FindFirstChild("VVLEQ") then newSound.VVLEQ.Enabled = false end
		-- Do it the longer way so the user can add their own effects
		local eq = Instance.new("EqualizerSoundEffect", newSound)
		eq.Name = "#EQ"
		eq.HighGain = 0
		eq.MidGain = 0
		eq.LowGain = 0
		local dist = Instance.new("DistortionSoundEffect", newSound)
		dist.Name = "#Distortion"
		dist.Level = 0
	end
end

local function f(m, n, p, q, M, b, x) -- Calculation for VVL
	return math.clamp(M - ( (q-n)/(b^p-b^m) * (b^x-b^m) + n ), 0, M)
end

local function eqGain(sound, gainType, throt)
	local offEQ = sound:FindFirstChild("OffEQ") or sound:FindFirstChild("ThrottleEQ") or sound:FindFirstChild("VVLEQ")
	local throttleEQ = sound:FindFirstChild("ThrottleEQ") or sound:FindFirstChild("OffEQ") or sound:FindFirstChild("VVLEQ")
	local vvlEQ = sound:FindFirstChild("VVLEQ") or sound:FindFirstChild("ThrottleEQ") or sound:FindFirstChild("OffEQ")
	if not offEQ then return end
	local eq = offEQ[gainType] + ((throttleEQ[gainType] + (vvlEQ[gainType] - throttleEQ[gainType]) * vvl) - offEQ[gainType]) * throt
	return eq
end

local function distGain(sound, throt)
	local offDist = sound:FindFirstChild("OffDistortion") or sound:FindFirstChild("ThrottleDistortion")
	local throttleDist = sound:FindFirstChild("ThrottleDistortion") or sound:FindFirstChild("OffDistortion")
	if not offDist then return end
	return offDist.Level + (throttleDist.Level - offDist.Level) * throt
end

-- On driver leave
car.DriveSeat.ChildRemoved:Connect(function(child)
	if FE then
		event:FireServer("remove")
	else
		if child.Name == "SeatWeld" and child:IsA("Weld") then
			for _, sound in next, sounds do
				sound:Destroy()
			end
			table.clear(sounds)
		end
	end
end)

--man i love linear interpolation
local updateBOV = false
local lastBOV = tick()
local prevBoost = 0
RunService.Heartbeat:Connect(function(dt)
	if _Tune.CustomEngineCalculations == false or car["A-Chassis Tune"].README:FindFirstChild("CustomEngine") == nil then
		if _Tune.VVLTorque > 0 then
			vvl = (_Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, values.RPM.Value/1000))/_Tune.VVLTorque
		else
			vvl = 0
		end
	end
	
	-- Transmission rotation speed
	AverageRotSpeed = 0
	local count = 0
	for _, wheel in values.WheelSpeeds:GetChildren() do
		if string.find(wheel.Name, "F") then
			if not (_Tune.Config == "FWD" or _Tune.Config == "AWD") then continue end
			AverageRotSpeed += wheel.Value
			count += 1
		else
			if not (_Tune.Config == "RWD" or _Tune.Config == "AWD") then continue end
			AverageRotSpeed += wheel.Value
			count += 1
		end
	end
	AverageRotSpeed /= count
	
	local IsOn = script.Parent.IsOn.Value and 1 or 0
	for _, sound in next, sounds do
		local soundType = string.sub(sound.Name, 1, 3)
		if soundType == "ENG" then
			sound.Playing = true
			sound["#EQ"].HighGain = eqGain(sound, "HighGain", values.Throttle.Value)
			sound["#EQ"].MidGain = eqGain(sound, "MidGain", values.Throttle.Value)
			sound["#EQ"].LowGain = eqGain(sound, "LowGain", values.Throttle.Value)
			sound["#Distortion"].Level = distGain(sound, values.Throttle.Value)
			sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + (sound:GetAttribute("RedlinePlaybackSpeed") - sound:GetAttribute("BasePlaybackSpeed")) * (values.RPM.Value/_Tune.Redline)
			sound.Volume = IsOn * (sound:GetAttribute("BaseVolume") + (sound:GetAttribute("ThrottleVolume")*values.Throttle.Value) + (sound:GetAttribute("RedlineVolume")*(values.RPM.Value/_Tune.Redline))) * math.clamp(1/sound:GetAttribute("TransitionStart")*(values.RPM.Value-sound:GetAttribute("RangeStart")),0,1) * math.clamp(-1/sound:GetAttribute("TransitionEnd")*(values.RPM.Value-sound:GetAttribute("RangeEnd")),0,1)

		elseif soundType == "TRA" then
			sound.Playing = true
			local gears = string.split(string.gsub(sound:GetAttribute("Gears"), " ", ""), ",")
			sound.PlaybackSpeed = sound:GetAttribute("VariablePlaybackSpeed") * (AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))
			sound.Volume = table.find(gears, tostring(values.Gear.Value)) and (sound:GetAttribute("ClutchVolume") + ((sound:GetAttribute("BaseVolume") + sound:GetAttribute("VariableVolume")*(AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))) - sound:GetAttribute("ClutchVolume")) * (1-values.Clutch.Value)) or sound:GetAttribute("OffVolume")

		elseif soundType == "TUR" then
			sound.Playing = true
			sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + sound:GetAttribute("PlaybackSpeedIncrease") * values.BoostTurbo.Value
			sound.Volume = sound:GetAttribute("VolumeIncrease") * values.BoostTurbo.Value

		elseif soundType == "SUP" then
			sound.Playing = true
			sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + sound:GetAttribute("PlaybackSpeedIncrease") * values.BoostSuper.Value
			sound.Volume = sound:GetAttribute("VolumeIncrease") * values.BoostSuper.Value

		elseif soundType == "BOV" then
			if (values.BoostTurbo.Value - sound:GetAttribute("Sensitivity") < prevBoost) and (tick()-lastBOV > 1) and values.Throttle.Value < .8 then
				updateBOV = true
				sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + sound:GetAttribute("PlaybackSpeedIncrease") * values.BoostTurbo.Value
				sound.Volume = sound:GetAttribute("VolumeIncrease") * values.BoostTurbo.Value
				sound:Play()
			end
			prevBoost = values.BoostTurbo.Value

		elseif soundType == "IGN" then
			if script.Parent.Starting.Value then
				sound.Playing = true
				sound.Volume = sound:GetAttribute("Volume")
				sound.PlaybackSpeed = sound:GetAttribute("PitchPerRPM") * math.min(values.RPM.Value, _Tune.IgnitionRPM)
			else
				sound.Playing = false
			end

		end
	end
	if updateBOV then
		lastBOV = tick()
		updateBOV = false
	end
end)
if FE then
	while true do
		event:FireServer("update", values.RPM.Value, values.Throttle.Value, AverageRotSpeed, values.Gear.Value, values.Clutch.Value, values.BoostTurbo.Value, values.BoostSuper.Value, script.Parent.IsOn.Starting.Value, script.Parent.IsOn.Value)
		task.wait(FE_RATE)
	end
end