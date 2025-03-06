--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

local Tune = {}

-- It is recommended that you go to: https://www.desmos.com/calculator/lhxwlpppyh
-- to tune your vehicle's tires.

-- The default configuration is of a soft-compound sports tire.

--[[Misc]]
	Tune.SaveHeatData		= true				-- Whether to save heat data when leaving the car
	Tune.TireWearOn			= true				-- False sets friction to maximum
	Tune.Haptics			= "Controller"		-- Tire slippage will activate the small motor ("Controller", "Mobile", "Both", "Off")
	Tune.AmbientTemp		= workspace:GetAttribute("GlobalTemperature") or 22
	
	Tune.DirtBumps			= 20				-- Aggresiveness of artificial bumps in dirt-, sand-, and snow-type surfaces (0 for none)
	Tune.SandForce			= 10					-- Sand force, more means going over sand slows down the car more

--[[Aesthetics]]
	Tune.SmokeEffects				= "All"		-- Turns smoke effects on or off, "All" for viewable by everyone, "Local" for only viewable by you, "Off" for none.
	Tune.SmokeStressOffset			= 5			-- Offsets the stress required to activate smoke-related effects (in percent, higher means less smoke).
	Tune.SmokePollingRate			= 1/60		-- "All" setting only. This changes how often the server gets data to run the smoke effects. Higher = more delay.
	Tune.TireMarkTransparencyLevels	= 7			-- How many levels of transparency there are (0 for no marks)
	Tune.TireMarkTransparency		= .95		-- The transparency of the tire marks

--[[Friction]]
	Tune.FMinTemp			= 8					-- Minimum temperature of the front tires in celcius
	Tune.FMaxTemp			= 100				-- Maximum temperature of the front tires in celcius
	Tune.FMaxFriction		= 1.8				-- Maximum friction of the front tires
	Tune.FColdStats			= {.38, 11.7, .32}	-- Loss, Sharpness, Offset
	Tune.FHotStats			= {.96, 18.3, 1.05}	-- Loss, Sharpness, Offset
	Tune.FDirtLoss			= .1				-- Friction loss from dirty tires
	Tune.FDirtFadeRate		= .001				-- The rate that dirt fades
	Tune.FHeating			= .001				-- Heat gain from maximum slippage
	Tune.FCooling			= .002				-- Heat loss at no slippage
	Tune.FSpeedStress		= .04				-- Stress generated at 100 km/h

	Tune.RMinTemp			= 8					-- Minimum temperature of the rear tires in celcius
	Tune.RMaxTemp			= 100				-- Maximum temperature of the rear tires in celcius
	Tune.RMaxFriction		= 2.0				-- Maximum friction of the rear tires
	Tune.RColdStats			= {.38, 11.7, .32}	-- Loss, Sharpness, Offset
	Tune.RHotStats			= {.96, 18.3, 1.05}	-- Loss, Sharpness, Offset
	Tune.RDirtLoss			= .1				-- Friction loss from dirty tires
	Tune.RDirtFadeRate		= .001				-- The rate that dirt fades
	Tune.RHeating			= .001				-- Heat gain from maximum slippage
	Tune.RCooling			= .002				-- Heat loss at no slippage
	Tune.RSpeedStress		= .04				-- Stress generated at 100 km/h

--[[Tire Flex]]
	Tune.TireFlex			= false				-- Uses a separate collision to simulate tire flex
	Tune.ShowTF				= false				-- Debug tire flex

	Tune.FPressureForce		= 18				-- Pressure force (no unit)
	Tune.FTireThickness		= 50				-- Tire sidewall thickness in milimeters
	Tune.FTireWeight		= 9					-- Tire weight in kg

	Tune.RPressureForce		= 18				-- Pressure force (no unit)
	Tune.RTireThickness		= 50				-- Tire sidewall thickness in milimeters
	Tune.RTireWeight		= 9					-- Tire weight in kg

return Tune
