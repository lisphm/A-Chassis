--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- *Most of the code documentation for here can be found in the LocalScript.

local car = script.Parent.Parent
local event = script.Parent

local _Tune = require(car["A-Chassis Tune"])
local Units = require(car["A-Chassis Tune"].README.Units)
local sounds = {}
local vvl = 0

local function create(children, DIRECTORY)
	for _, sound in next, children do
		if not sound:IsA("Sound") then continue end
		
		local newSound = sound:Clone()
		table.insert(sounds, newSound)

		newSound.Playing = false
		newSound.Volume = 0
		newSound.Parent = DIRECTORY and DIRECTORY:FindFirstChild(newSound:GetAttribute("SoundParent")) or car.Body["#Weight"]
		if string.sub(newSound.Name, 1, 3) ~= "ENG" then continue end

		if newSound:FindFirstChild("OffDistortion") then newSound.OffDistortion.Enabled = false end
		if newSound:FindFirstChild("OffEQ") then newSound.OffEQ.Enabled = false end
		if newSound:FindFirstChild("ThrottleDistortion") then newSound.ThrottleDistortion.Enabled = false end
		if newSound:FindFirstChild("ThrottleEQ") then newSound.ThrottleEQ.Enabled = false end
		if newSound:FindFirstChild("VVLEQ") then newSound.VVLEQ.Enabled = false end
		local eq = Instance.new("EqualizerSoundEffect", newSound)
		eq.Name = "#EQ"
		eq.HighGain = 0
		eq.MidGain = 0
		eq.LowGain = 0
		local dist = Instance.new("DistortionSoundEffect", newSound)
		dist.Name = "#Distortion"
		dist.Level = 0
		-- do it like this so the user can add their own EQ's and effects
	end
end

local function f(m, n, p, q, M, b, x)
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

local updateBOV = false
local lastBOV = tick()
local prevBoost = 0
local lastLoop = tick()
local function update(RPM, Throttle, AverageRotSpeed, Gear, Clutch, BoostTurbo, BoostSuper, Starting, IsOn)
	local dt = tick() - lastLoop
	if _Tune.CustomEngineCalculations == false or car["A-Chassis Tune"].README:FindFirstChild("CustomEngine") == nil then
		if _Tune.VVLTorque > 0 then
			vvl = (_Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, RPM/1000))/_Tune.VVLTorque
		else
			vvl = 0
		end
	end
	IsOn = IsOn and 1 or 0
	for _, sound in next, sounds do
		local soundType = string.sub(sound.Name, 1, 3)
		if soundType == "ENG" then
			sound.Playing = true
			sound["#EQ"].HighGain = eqGain(sound, "HighGain", Throttle)
			sound["#EQ"].MidGain = eqGain(sound, "MidGain", Throttle)
			sound["#EQ"].LowGain = eqGain(sound, "LowGain", Throttle)
			sound["#Distortion"].Level = distGain(sound, Throttle)
			sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + (sound:GetAttribute("RedlinePlaybackSpeed") - sound:GetAttribute("BasePlaybackSpeed")) * (RPM/_Tune.Redline)
			sound.Volume = IsOn * (sound:GetAttribute("BaseVolume") + (sound:GetAttribute("ThrottleVolume")*Throttle) + (sound:GetAttribute("RedlineVolume")*(RPM/_Tune.Redline))) * math.clamp(1/sound:GetAttribute("TransitionStart")*(RPM-sound:GetAttribute("RangeStart")),0,1)  * math.clamp(-1/sound:GetAttribute("TransitionEnd")*(RPM-sound:GetAttribute("RangeEnd")),0,1)

		elseif soundType == "TRA" then
			sound.Playing = true
			local gears = string.split(string.gsub(sound:GetAttribute("Gears"), " ", ""), ",")
			sound.PlaybackSpeed = sound:GetAttribute("VariablePlaybackSpeed") * (AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))
			sound.Volume = table.find(gears, tostring(Gear)) and (sound:GetAttribute("ClutchVolume") + ((sound:GetAttribute("BaseVolume") + sound:GetAttribute("VariableVolume")*(AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))) - sound:GetAttribute("ClutchVolume")) * (1-Clutch)) or sound:GetAttribute("OffVolume")

		elseif soundType == "TUR" then
			sound.Playing = true
			sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + sound:GetAttribute("PlaybackSpeedIncrease") * BoostTurbo
			sound.Volume = sound:GetAttribute("VolumeIncrease") * BoostTurbo

		elseif soundType == "SUP" then
			sound.Playing = true
			sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + sound:GetAttribute("PlaybackSpeedIncrease") * BoostSuper
			sound.Volume = sound:GetAttribute("VolumeIncrease") * BoostSuper

		elseif soundType == "BOV" then
			if (BoostTurbo - sound:GetAttribute("Sensitivity") < prevBoost) and (tick()-lastBOV > 1) and Throttle < .8 then
				updateBOV = true
				sound.PlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed") + sound:GetAttribute("PlaybackSpeedIncrease") * BoostTurbo
				sound.Volume = sound:GetAttribute("VolumeIncrease") * BoostTurbo
				sound:Play()
			end
			prevBoost = BoostTurbo

		elseif soundType == "IGN" then
			if Starting then
				sound.Playing = true
				sound.Volume = sound:GetAttribute("Volume")
				sound.PlaybackSpeed = sound:GetAttribute("PitchPerRPM") * math.min(RPM, _Tune.IgnitionRPM)
			else
				sound.Playing = false
			end
			
		end
	end
	if updateBOV then
		lastBOV = tick()
		updateBOV = false
	end
	lastLoop = tick()
end

local function remove()
	for _, sound in next, sounds do
		sound:Destroy()
	end
	table.clear(sounds)
end

event.OnServerEvent:Connect(function(player, func, ...)
	if func == "create" then
		create(...) 
	elseif func == "update" then
		update(...)
	elseif func == "remove" then
		remove()
	end
end)
