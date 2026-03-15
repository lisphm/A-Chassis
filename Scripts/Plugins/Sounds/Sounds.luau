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
-- You can edit the sound properties in the sounds under the script, or you can change where sounds are stored and if there is Filtering Enabled in here.

local car = script.Parent.Car.Value
local values = script.Parent.Values
local event = car:WaitForChild("Sounds")

-- [[ EDIT ]] -------------------------------------------------------------------------

local FE			= true										-- If true, this makes sounds play for everyone in the game, not just the driver.
local FE_RATE		= 1/15										-- FE must equal true. This changes how often the sound updates for the player. Higher = updates less often.
local DIRECTORY		= car.Body.Sounds					-- This is the path of the sounds group or model to use.

-- [[ END EDIT ]] -------------------------------------------------------------------------

local RunService = game:GetService("RunService")

local _Tune = require(car["A-Chassis Tune"])
local Units = require(car["A-Chassis Tune"].README.Units)
local sounds = {}
local vvl = 0
local AverageRotSpeed = 0
local rpmHistory = {}
local rpm = 0
local soundEQCache = {}
local modifierDataCache = {}

local ThrottleValue = values.Throttle
local RPMValue = values.RPM
local GearValue = values.Gear
local ClutchValue = values.Clutch
local BoostTurboValue = values.BoostTurbo
local BoostSuperValue = values.BoostSuper
local StartingValue = script.Parent.IsOn.Starting
local IsOnValue = script.Parent.IsOn

-- Index all the sounds
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
for _, sound in script:GetChildren() do
	if not sound:IsA("Sound") then continue end
	
	local soundParent = DIRECTORY:FindFirstChild(sound:GetAttribute("SoundParent")) or car.Body["#Weight"]
	local newSound = soundParent:FindFirstChild(sound.Name.."_Local")
	
	local soundData = {}
	if not newSound then
		newSound = sound:Clone()
		newSound.Name = newSound.Name.."_Local"
		
		newSound.Playing = false
		newSound.Volume = 0
		newSound.Parent = soundParent
		
		-- Do it the longer way so the user can add their own effects
		local eq = Instance.new("EqualizerSoundEffect", newSound)
		eq.Name = "#EQ"
		eq.HighGain = 0
		eq.MidGain = 0
		eq.LowGain = 0
		local dist = Instance.new("DistortionSoundEffect", newSound)
		dist.Name = "#Distortion"
		dist.Level = 0
		
		soundData.EQ = eq
		soundData.Distortion = dist
	end
	
	if FE then
		local serverSound = soundParent:FindFirstChild(sound.Name)
		if serverSound then
			serverSound:SetAttribute("SoundId", serverSound.SoundId)
			serverSound.SoundId = ""
			soundData.ServerSound = serverSound
		end
	end
	
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

	if newSound:FindFirstChild("OffDistortion") then newSound.OffDistortion.Enabled = false end
	if newSound:FindFirstChild("OffEQ") then newSound.OffEQ.Enabled = false end
	if newSound:FindFirstChild("ThrottleDistortion") then newSound.ThrottleDistortion.Enabled = false end
	if newSound:FindFirstChild("ThrottleEQ") then newSound.ThrottleEQ.Enabled = false end
	if newSound:FindFirstChild("VVLEQ") then newSound.VVLEQ.Enabled = false end
	
	soundData.Sound = newSound
	soundData.Playing = false
	soundData.type = string.sub(sound.Name, 1, 3)
	soundData.EQ = newSound:FindFirstChild("#EQ")
	soundData.Distortion = newSound:FindFirstChild("#Distortion")
	
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

local function f(m, n, p, q, M, b, x) -- Calculation for VVL
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

--man i love linear interpolation
local updateBOV = false
local lastBOV = tick()
local last = tick()
local prevBoost = 0
local noCustomEngine = car["A-Chassis Tune"].README:FindFirstChild("CustomEngine") == nil
local WheelSpeedsChildren = values.WheelSpeeds:GetChildren()
local function RuntimeLoop(dt)
	if tick()-last < 1/60 then return end
	last = tick()
	
	-- Calculate smooth RPM
	table.insert(rpmHistory, RPMValue.Value)
	if #rpmHistory > 8 then
		table.remove(rpmHistory, 1)
	end
	rpm = 0
	for _, v in rpmHistory do
		rpm = rpm + v
	end
	rpm = rpm / #rpmHistory

	-- Calculate VVL
	if _Tune.CustomEngineCalculations == false or noCustomEngine then
		if _Tune.VVLTorque > 0 then
			vvl = (_Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, rpm/1000))/_Tune.VVLTorque
		else
			vvl = 0
		end
	end

	-- Transmission rotation speed
	AverageRotSpeed = 0
	local count = 0
	for _, wheel in WheelSpeedsChildren do
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

	local IsOn = IsOnValue.Value and 1 or 0
	for _, soundData in sounds do
		if soundData.type == "ENG" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.EQ.HighGain = eqGain(soundData.Sound, "HighGain", ThrottleValue.Value)
			soundData.EQ.MidGain = eqGain(soundData.Sound, "MidGain", ThrottleValue.Value)
			soundData.EQ.LowGain = eqGain(soundData.Sound, "LowGain", ThrottleValue.Value)
			soundData.Distortion.Level = distGain(soundData.Sound, ThrottleValue.Value)
			soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + (soundData.RedlinePlaybackSpeed - soundData.BasePlaybackSpeed) * (rpm/_Tune.Redline)
			soundData.Sound.Volume = IsOn * (soundData.BaseVolume + (soundData.ThrottleVolume*ThrottleValue.Value) + (soundData.RedlineVolume*(rpm/_Tune.Redline))) * math.clamp(1/soundData.TransitionStart*(rpm-soundData.RangeStart),0,1) * math.clamp(-1/soundData.TransitionEnd*(rpm-soundData.RangeEnd),0,1)

		elseif soundData.type == "TRA" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.Sound.PlaybackSpeed = soundData.VariablePlaybackSpeed * (AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))
			soundData.Sound.Volume = table.find(soundData.Gears, tostring(GearValue.Value)) and (soundData.ClutchVolume + ((soundData.BaseVolume + soundData.VariableVolume*(AverageRotSpeed/(300*(Units.Length_mm/1000)*3.6))) - soundData.ClutchVolume) * (1-ClutchValue.Value) + soundData.ThrottleVolume*ThrottleValue.Value) or soundData.OffVolume

		elseif soundData.type == "TUR" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + soundData.PlaybackSpeedIncrease * BoostTurboValue.Value
			soundData.Sound.Volume = soundData.VolumeIncrease * BoostTurboValue.Value

		elseif soundData.type == "SUP" then
			if soundData.Playing == false then
				soundData.Playing = true
				soundData.Sound.Playing = true
			end
			soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + soundData.PlaybackSpeedIncrease * BoostSuperValue.Value
			soundData.Sound.Volume = soundData.VolumeIncrease * BoostSuperValue.Value

		elseif soundData.type == "BOV" then
			if (BoostTurboValue.Value - soundData.Sensitivity < prevBoost) and (tick()-lastBOV > 1) and ThrottleValue.Value < .8 then
				updateBOV = true
				soundData.Sound.PlaybackSpeed = soundData.BasePlaybackSpeed + soundData.PlaybackSpeedIncrease * BoostTurboValue.Value
				soundData.Sound.Volume = soundData.VolumeIncrease * BoostTurboValue.Value
				soundData.Sound.TimePosition = 0
				soundData.Sound.Playing = true
			end
			prevBoost = BoostTurboValue.Value

		elseif soundData.type == "IGN" then
			if StartingValue.Value then
				if not soundData.Sound:GetAttribute("Played") then
					soundData.Sound.TimePosition = 0
					soundData.Sound.Playing = true
					soundData.Playing = true
				end
				soundData.Sound:SetAttribute("Played", true)
				soundData.Sound.Volume = soundData.Volume
				soundData.Sound.PlaybackSpeed = soundData.Pitch + (soundData.MaxPitch - soundData.Pitch) * (rpm/_Tune.IgnitionRPM)
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
end
RunService.Heartbeat:Connect(RuntimeLoop)

car.DriveSeat.ChildRemoved:Connect(function(child)
	if child:IsA("Weld") and child.Name == "SeatWeld" then
		for _, soundData in sounds do
			soundData.Sound.Playing = false
			soundData.ServerSound.Playing = false
			if soundData.ServerSound then
				soundData.ServerSound.SoundId = soundData.ServerSound:GetAttribute("SoundId")
			end
		end
		script:Destroy()
	end
end)

local function FELoop()
	while task.wait(FE_RATE) do
		local packet = buffer.create(17)
		buffer.writeu16(packet, 0, math.clamp(math.round(rpm), 0, 65535))
		buffer.writeu8(packet, 2, math.clamp(math.round(ThrottleValue.Value*255), 0, 255))
		buffer.writeu16(packet, 3, math.clamp(math.round(AverageRotSpeed), 0, 65535))
		buffer.writei8(packet, 5, GearValue.Value)
		buffer.writeu8(packet, 6, math.clamp(math.round(ClutchValue.Value*255), 0, 255))
		buffer.writef32(packet, 7, math.round(BoostTurboValue.Value*100)/100)
		buffer.writef32(packet, 11, math.round(BoostSuperValue.Value*100)/100)
		buffer.writeu8(packet, 15, StartingValue.Value and 1 or 0)
		buffer.writeu8(packet, 16, IsOnValue.Value and 1 or 0)
		event:FireServer(packet)
	end
end
if FE then
	task.spawn(FELoop)
end
