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

task.wait(.5)


local car = script.Parent.Parent
local event = script.Parent

local DIRECTORY = car.Body.Sounds

local _Tune = require(car["A-Chassis Tune"])
local Units = require(car["A-Chassis Tune"].README.Units)
local sounds = {}
local vvl = 0
local soundEQCache = {}
local modifierDataCache = {}
local canUpdate = false

local function cacheEQData(eq)
	if eq == nil then return end
	modifierDataCache[eq] = {
		HighGain = eq.HighGain,
		LowGain = eq.LowGain,
		MidGain = eq.MidGain,
	}
end
local function cacheDistortionData(dist)
	if dist == nil then return end
	modifierDataCache[dist] = dist.Level
end
local function create(children)
	for _, sound in children do
		if not sound:IsA("Sound") then continue end
		
		local newSound = sound:Clone()		
		local offEQ = sound:FindFirstChild("OffEQ") or sound:FindFirstChild("ThrottleEQ") or sound:FindFirstChild("VVLEQ")
		local throttleEQ = sound:FindFirstChild("ThrottleEQ") or sound:FindFirstChild("OffEQ") or sound:FindFirstChild("VVLEQ")
		local vvlEQ = sound:FindFirstChild("VVLEQ") or sound:FindFirstChild("ThrottleEQ") or sound:FindFirstChild("OffEQ")
		local offDist = sound:FindFirstChild("OffDistortion") or sound:FindFirstChild("ThrottleDistortion")
		local throttleDist = sound:FindFirstChild("ThrottleDistortion") or sound:FindFirstChild("OffDistortion")
		soundEQCache[newSound] = {offEQ, throttleEQ, vvlEQ, offDist, throttleDist}
		
		cacheEQData(offEQ)
		cacheEQData(throttleEQ)
		cacheEQData(vvlEQ)
		cacheDistortionData(offDist)
		cacheDistortionData(throttleDist)

		newSound.Playing = false
		newSound.Volume = 0
		newSound.Parent = DIRECTORY and DIRECTORY:FindFirstChild(newSound:GetAttribute("SoundParent")) or car.Body["#Weight"]

		if newSound:FindFirstChild("OffDistortion") then newSound.OffDistortion.Enabled = false end
		if newSound:FindFirstChild("OffEQ") then newSound.OffEQ.Enabled = false end
		if newSound:FindFirstChild("ThrottleDistortion") then newSound.ThrottleDistortion.Enabled = false end
		if newSound:FindFirstChild("ThrottleEQ") then newSound.ThrottleEQ.Enabled = false end
		if newSound:FindFirstChild("VVLEQ") then newSound.VVLEQ.Enabled = false end
		local eq = Instance.new("EqualizerSoundEffect")
		eq.Name = "#EQ"
		eq.HighGain = 0
		eq.MidGain = 0
		eq.LowGain = 0
		eq.Parent = newSound
		local dist = Instance.new("DistortionSoundEffect")
		dist.Name = "#Distortion"
		dist.Level = 0
		dist.Parent = newSound
		
		local soundData = {
			Sound = newSound,
			type = string.sub(sound.Name, 1, 3),
			EQ = eq,
			Distortion = dist,
			Playing = false,
		}

		-- Cache all possible sound attributes
		soundData.BasePlaybackSpeed = sound:GetAttribute("BasePlaybackSpeed")
		soundData.BaseVolume = sound:GetAttribute("BaseVolume")
		soundData.RangeEnd = sound:GetAttribute("RangeEnd")
		soundData.RangeStart = sound:GetAttribute("RangeStart")
		soundData.RedlinePlaybackSpeed = sound:GetAttribute("RedlinePlaybackSpeed")
		soundData.RedlineVolume = sound:GetAttribute("RedlineVolume")
		soundData.ThrottleVolume = sound:GetAttribute("ThrottleVolume")
		soundData.TransitionEnd = sound:GetAttribute("TransitionEnd")
		soundData.TransitionStart = sound:GetAttribute("TransitionStart")
		soundData.ClutchVolume = sound:GetAttribute("ClutchVolume")
		soundData.Gears = string.split(string.gsub(soundData.Sound:GetAttribute("Gears") or "", " ", ""), ",")
		soundData.OffVolume = sound:GetAttribute("OffVolume")
		soundData.VariablePlaybackSpeed = sound:GetAttribute("VariablePlaybackSpeed")
		soundData.VariableVolume = sound:GetAttribute("VariableVolume")
		soundData.PlaybackSpeedIncrease = sound:GetAttribute("PlaybackSpeedIncrease")
		soundData.VolumeIncrease = sound:GetAttribute("VolumeIncrease")
		soundData.Sensitivity = sound:GetAttribute("Sensitivity")
		soundData.MaxPitch = sound:GetAttribute("MaxPitch")
		soundData.Pitch = sound:GetAttribute("Pitch")
		soundData.Volume = sound:GetAttribute("Volume")

		table.insert(sounds, soundData)
	end
end

local function f(m, n, p, q, M, b, x)
	return math.clamp(M - ( (q-n)/(b^p-b^m) * (b^x-b^m) + n ), 0, M)
end

local function eqGain(sound, gainType, throt)
	local offEQ = soundEQCache[sound][1]
	if not offEQ then return end
	local throttleEQ = soundEQCache[sound][2]
	local vvlEQ = soundEQCache[sound][3]
	local eq = modifierDataCache[offEQ][gainType] + ((modifierDataCache[throttleEQ][gainType] + (modifierDataCache[vvlEQ][gainType] - modifierDataCache[throttleEQ][gainType]) * vvl) - modifierDataCache[offEQ][gainType]) * throt
	return eq
end

local function distGain(sound, throt)
	local offDist = soundEQCache[sound][4]
	if not offDist then return end
	local throttleDist = soundEQCache[sound][5]
	return modifierDataCache[offDist] + (modifierDataCache[throttleDist] - modifierDataCache[offDist]) * throt
end

local updateBOV = false
local lastBOV = tick()
local prevBoost = 0
local lastLoop = tick()

local function update(player, packet)
	if not canUpdate then return end
	local RPM, Throttle, AverageRotSpeed, Gear, Clutch, BoostTurbo, BoostSuper, Starting, IsOn =
		buffer.readu16(packet, 0),
		buffer.readu8(packet, 2)/255,
		buffer.readu16(packet, 3),
		buffer.readi8(packet, 5),
		buffer.readu8(packet, 6)/255,
		buffer.readf32(packet, 7),
		buffer.readf32(packet, 11),
		buffer.readu8(packet, 15) == 1,
		buffer.readu8(packet, 16) == 1
	local dt = tick() - lastLoop
	if _Tune.CustomEngineCalculations == false or car["A-Chassis Tune"].README:FindFirstChild("CustomEngine") == nil then
		if _Tune.VVLTorque > 0 then
			vvl = (_Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, RPM/1000))/_Tune.VVLTorque
		else
			vvl = 0
		end
	end
	IsOn = IsOn and 1 or 0
	for _, soundData in sounds do
		if soundData.type == "ENG" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.EQ.HighGain = eqGain(soundData.Sound, "HighGain", Throttle)
			soundData.EQ.MidGain = eqGain(soundData.Sound, "MidGain", Throttle)
			soundData.EQ.LowGain = eqGain(soundData.Sound, "LowGain", Throttle)
			soundData.Distortion.Level = distGain(soundData.Sound, Throttle)
			soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + (soundData.RedlinePlaybackSpeed - soundData.BasePlaybackSpeed) * (RPM/_Tune.Redline)
			soundData.Sound.Volume = IsOn * (soundData.BaseVolume + (soundData.ThrottleVolume*Throttle) + (soundData.RedlineVolume*(RPM/_Tune.Redline))) * math.clamp(1/soundData.TransitionStart*(RPM-soundData.RangeStart),0,1) * math.clamp(-1/soundData.TransitionEnd*(RPM-soundData.RangeEnd),0,1)

		elseif soundData.type == "TRA" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.Sound.PlaybackSpeed = soundData.VariablePlaybackSpeed * (AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))
			soundData.Sound.Volume = table.find(soundData.Gears, tostring(Gear)) and (soundData.ClutchVolume + ((soundData.BaseVolume + soundData.VariableVolume*(AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))) - soundData.ClutchVolume) * (1-Clutch) + soundData.ThrottleVolume*Throttle) or soundData.OffVolume

		elseif soundData.type == "TUR" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + soundData.PlaybackSpeedIncrease * BoostTurbo
			soundData.Sound.Volume = soundData.VolumeIncrease * BoostTurbo

		elseif soundData.type == "SUP" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + soundData.PlaybackSpeedIncrease * BoostSuper
			soundData.Sound.Volume = soundData.VolumeIncrease * BoostSuper

		elseif soundData.type == "BOV" then
			if (BoostTurbo - soundData.Sensitivity < prevBoost) and (tick()-lastBOV > 1) and Throttle < .8 then
				updateBOV = true
				soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + soundData.PlaybackSpeedIncrease * BoostTurbo
				soundData.Sound.Volume = soundData.VolumeIncrease * BoostTurbo
				soundData.Sound.TimePosition = 0
				soundData.Sound.Playing = true
			end
			prevBoost = BoostTurbo

		elseif soundData.type == "IGN" then
			if Starting then
				if not soundData.Sound:GetAttribute("Played") then
					soundData.Sound.TimePosition = 0
					soundData.Sound.Playing = true
					soundData.Playing = true
				end
				soundData.Sound:SetAttribute("Played", true)
				soundData.Sound.Volume = soundData.Volume
				soundData.Sound.PlaybackSpeed = soundData.Pitch + (soundData.MaxPitch - soundData.Pitch) * (RPM/_Tune.IgnitionRPM)
			else
				soundData.Sound:SetAttribute("Played", false)
				if soundData.Playing == true then
					soundData.Playing = false
					soundData.Sound.Playing = false
				end
			end

		end
	end
	if updateBOV then
		lastBOV = tick()
		updateBOV = false
	end
	lastLoop = tick()
end

event.OnServerEvent:Connect(update)

-- Credit to Benkeeeee for solving a bug here for the community 💕
car.DriveSeat.ChildAdded:Connect(function(child: Instance)
	if child:IsA("Weld") and child.Name == "SeatWeld" then
		canUpdate = true
		for _, soundData in sounds do
			if soundData.type == "BOV" or soundData.type == "IGN" then
				continue
			end
			soundData.Sound.Volume = 0
			soundData.Sound:Play()
		end
	end
end)
car.DriveSeat.ChildRemoved:Connect(function(child: Instance)
	if child:IsA("Weld") and child.Name == "SeatWeld" then
		canUpdate = false
		for _, soundData in sounds do
			soundData.Sound:Stop()
		end
	end
end)

local children = nil
for i, desc in car["A-Chassis Tune"]["A-Chassis Interface"]:GetDescendants() do
	if desc:IsA("LocalScript") and desc:GetAttribute("ID") == "A-Chassis Sounds" then
		children = desc:GetChildren()
		break
	end
end

create(children)
