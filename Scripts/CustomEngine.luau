--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
-- This is the CustomEngine module.
--[[

	I'll try to explain this in the best way possible.
	
	How this works is every frame/tick, the Drive sends data to this script if you have the CustomEngine functionality enabled.
	*To enable this, make sure this script is inside A-Chassis Tune, and Tune.CustomEngineCalculations = true
	The data consists of nearly every variable that the Drive creates.
	
		If you are familiar with the Drive values, here is an example:
		local _RPM = env._RPM
		
		*env stands for environment, as I'm setting the environment of the function to be the environment of the Drive.
	
	The purpose of this script is so that savvy A-Chassis enjoyers can build custom engines without digging around in the Drive.
	It's for the people between tuning professionals and programming nerds.
	It's also for the legends who may distribute their own custom engines to others in a simpler and easier manner.
	
	For the purposes of A-Chassis:
		To me, and to future members and developers, use this feature to add backwards compatibility to older versions of the engine.
		With that being said, try to change as little as possible to ensure this feature still works for the engines that are at least 4 years old.

]]

--[[Engine]]

-- // End
-- Here are the values that will get outputted back to the drive.
-- It's possible to add more values, but that requires editting the Drive directly, defeating the whole purpose of this feature.
-- Most of these go unused if you are trying to build the engine from an older chassis.
-- *Keep in mind that until 1.6, torque calculations had the gear ratio factored in, so if you are building an engine, remember to factor out the gear ratios.
local engine = {}

local _Boost = 0
local _TBoost = 0
local _SBoost = 0

local _HP = 0
local _TQ = 0
local _NH = 0
local _NT = 0
local _EH = 0
local _ET = 0
local _TH = 0
local _TT = 0
local _SH = 0
local _ST = 0
local _BH = 0
local _BT = 0

--[[Power calculation prerequesites]]
-- Add the functions that don't run in the runtime loop here.
-- For example, the GetCurve functions from 1.5 and before.

--[[Loop]]
engine.run = function(env, dt)
	-- This is the runtime loop. It gets called every frame by the Drive. *Refer to the example from above.
	

	-- Everything above in this function can be replaced, but please keep the values below.
	engine._Boost = _Boost
	engine._TBoost = _TBoost
	engine._SBoost = _SBoost
	
	engine._HP = _HP
	engine._TQ = _TQ
	engine._NH = _NH
	engine._NT = _NT
	engine._EH = _EH
	engine._ET = _ET
	engine._TH = _TH
	engine._TT = _TT
	engine._SH = _SH
	engine._ST = _ST
	engine._BH = _BH
	engine._BT = _BT
end

return engine
