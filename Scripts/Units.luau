--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

-- All units derived from: https://create.roblox.com/docs/physics/units
-- Converting from the real life unit to the Roblox unit
-- Equations to convert from the real life measurement to the Roblox unit are given.
local Units = {}

-- Mass in kilograms (kg)
Units.Mass_kg = 1/21.952		-- [Mass in kilograms] * [Units.Mass_kg] = [Roblox mass]

-- Length in milimeters (mm)
Units.Length_mm = 280		-- [Length in meters] * [1/(Units.Length_mm/1000)] = [Roblox studs]

-- Force in newtons (N)
Units.Force_N = Units.Mass_kg * (1/(Units.Length_mm/1000))		-- [Force in newtons] * [Units.Force_N] = [Roblox force]

-- Stiffness in newtons per meter (N/m)
Units.Stiffness_Ndivm = Units.Mass_kg		-- [Stiffness in N/m] * [Units.Stiffness_Ndivm] = [Roblox stiffness]

-- Damping in newton-seconds per meter (N s/m)
Units.Damping_N_sdivm = Units.Mass_kg		-- [Damping in N s/m] * [Units.Damping_N_sdivm] = [Roblox damping]

-- Velocity in meters per second (m/s)
Units.Velocity_mdivs = 1/(Units.Length_mm/1000)			-- [Velocity in m/s] * [Units.Velocity_mdivs] = [Roblox velocity]

-- Torque in newton-meters (Nm)
Units.Torque_nm = Units.Force_N/(Units.Length_mm/1000)	-- [Torque in Nm] * [Units.Torque_nm] = [Roblox torque]

return Units
