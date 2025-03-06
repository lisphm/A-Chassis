--[[	
	   ___  _____
	  / _ |/ ___/	Avxnturador   	| Novena						    midmm5	    |
	 / __ / /__		LuaInt         	| Novena						    doomcentury	|
    /_/ |_\___/	 	Detomiks		| Base Chassis

	                Version 1.7 (Release Candidate)
	            	A-Chassis and its plugins, scripts, and assets, is free, open-source software under the GNU GENERAL PUBLIC LICENSE. 
	            	
	            	Special thanks to all our beta testers and bug reporters as always!
	 				 ___________________________________________________________________________
					|																			|
					| It is highly recommended to completely re-install A-Chassis from scratch.	|
					|___________________________________________________________________________|
	               	
		*The "A-Chassis Tune" module is where you would want to go to tune the car. Everything you'd need to touch would be there.
		*However, some tuning values are in the Tires plugin, so please check that out.
		
		It is possible to import engines from older versions by using the CustomEngine functionality.
		You can find those details in the default CustomEngine module.
	            
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Changelog [MM/DD/YYYY]
-- *Beta changelog will be consolidated for the stable release

-- [Known issues and solutions tested]:
*Solved issues will be marked with SOLVED for one update cycle

	1. Wheels glitch when approaching the car on spawn.
		- Setting network ownership to the server on spawn					(Does not work)
		- Disabling tire flex												(Does not work)
		
	2. Entire car shifts when steering on "New" power steering type
		- Set this to "Old" until fixed										(Temporary solution only)
		- RigidityEnabled set to false										(Works, but with weak steering at high speed)
	
	3. Possible RPM jitter at low RPM (may be due to applying the clutch based on speed)
	
	
	
[05/24/2024 : A-Chassis, Version 1.7 Release Candidate] - The Coating
	[Fixes] -Detomiks
		- RPM management improvements														(Stall setting actually works, no longer glitches when shifting up, over-revving)
		- Engine graph improvements															(Integrates gear tuning with torque vs. velocity)
		- Tire temperature improvements														(Cooling is more realistic, clicking the tire UI shows the temperature)
		- (Car) Revised tire sounds again													(Uses a different, more realistic sound effect)

		- Due to possible model shadowban:													(These components will cause the model to be shadowbanned from the toolbox or removed from Roblox entirely)
			- Deleted SetValue																
			- Limited CustomEngine															(Instead of using get/set environment, it now uses a manual list of required variables. You may edit this list to suit your needs, or revert back to the previous get/set enviroment state)

[04/27/2024 : A-Chassis, Version 1.7 Beta 4] - The Polish
	[Features] -Detomiks
		- Basic air pressure and altitude support											(Barometric formula is used for engine power loss and aerodynamics)
		- (Car) Revised tire sounds															(Tire sounds use a different playback speed and the TremoloSoundEffect for a more realistic effect)
		
	[Fixes] -Detomiks
		- AWD split behavior changed														(Only in cases where there are more front wheels than rear wheels, etc. The calculation actually makes sense now)
		- CollisionGroup support for tire flex												(Previous versions only used the Default collision group and did not support NoCollisionConstraints)
		- Readded manual steering angle														(Helpful for those who don't want to use the new system. "New" and "Old" renamed to "Auto" and "Manual")
		- Renamed CarCenter to Center														(Adds continuity between the car and bike chassis)
		- (Car) SetValue improvements														(Allows plugins to change the drivetrain configuration)
		- Removed AutoGravComp																(It broke everything)
		
		- (Bike) Fixed PhysicalProperties warnings											(I missed this when I did it on the car chassis)

[03/30/2024 : A-Chassis, Version 1.7 Beta 3] - The Clay Bar Beta
	[Features] -Detomiks
		- VirtualInput added																(Helpful for mobile support plugins and other things. There is a hard-block inside the Drive script to disable this in case exploits are an issue.)
		- SetValue added (credit to VanillaEdge)											(Allows for plugins to set internal Drive values. There is a hard-block inside the Drive script to disable this in case exploits are an issue.)
		- AutoGravComp																		(For legacy plugins)
	
	[Fixes] -Detomiks
		- Moved Units to README and Starting to IsOn										(For organization and aesthetic purposes)
		- IThrottle and IBrake renamed to InputThrottle and InputBrake respectively			(For aesthetic purposes)
		- Suspension damping changed from kg/s to thousands of kg/s							(Also for aesthetic purposes)
		- ClutchIdle renamed to IdleDamping													(This was also broken before, too)

		- Warnings in gauges can be pressed to toggle the warning							(Helpful for mobile support)
		- Tireflex retuned																	(Can handle high downforce a bit better)
		- Players correctly revert back to being not massless								(This somehow broke before??)
		- Smoke effects fixed for some materials											(This includes materials like fabric)
		- Sound improvements																(Fixed a typo causing throttle distortion to not work, made transmission sounds follow driven wheels instead of all wheels)
		- Revbounce fixed for non-neutral gears												(Caused by goalMax being redline instead of slightly higher)
		- Drive optimizations																(WheelOutput no longer contains 5 for-loops like before)
		- Tires plugin has trail-part behavior changes										(Only changes the part orientation when at speed and when there is tire stress, preventing low-speed physics glitches)

		- (Bike) Fixed wheels not staying at the set transparency							(Don't know how I missed this) 
		
[03/23/2024 : A-Chassis, Version 1.7 Beta 2] - A few fine and dandy fixes.
	[Fixes] -Detomiks, doomcentury
		- WeldConstraint is used instead of RigidConstraint	(Detomiks)						(RigidConstraint had too many attachments that showed up in the "Show Constraints" toggle.)
		- Reconfigured controller toggles for UI visibility (Detomiks)						(They interfered with countersteer)
		- Turbo spooling reworked (Detomiks)												(Old system was unrealistic)
		- Initialize and Drive optimizations (doomcentury)									

[02/25/2024 : A-Chassis, Version 1.7 Beta 1] - The first of many.
	[Features] -Detomiks (These are in order of importance.)
		- G-Force-based Electronic Stability Control (ESC).									(Only used for stability, not for desired turning radius or steering Gs. This is a lot like Greenville's implementation).
		- Counter Steer Assist (CS).														(To help steering by AlignOrientation, and just a QOL thing.)
		- CustomEngine module added.														(This allows for easy porting of engines. This is a lot like #ENGINE in previous versions. More information is provided in the blank, default one.)
		- New Sounds plugin.																(The old sounds plugin caused a lot of problems with internet bandwidth, plus it was too complicated.)
		- New Gauges plugin.																(A lot simpler, basically just modernized AC6C gauges.)
		- Removed deprecated components.													
			- (Optional) Changed Flip to an AlignOrientation instead of BodyGyro.				(FOR PLUGINS IN "New" MODE: use Flip.Enabled instead of Flip.MaxForce now)
			- (Optional) Steering changed to AlignOrientation.									(To make this as similar to BodyGyro as possible, we've added countersteer and steer smoothing values.)
			- (NOT Optional) Using VectorForce instead of the deprecated BodyForce.				(It's deprecated... what else is there to say?)
		- ABS gradient.																		(This can possibly help tire slippage when braking.)
		- Speedlimiter can also apply brake.												(This is helpful when going downhill.)
		- Tires plugin value to change FE rate.												(This is helpful for lag.)

	[Fixes] -Detomiks
		- Minor update to the turbo lag calculations.										(Smoothly interpolates to maximum and minimum boost because I fixed delta-time).
		- Changed clutch dumping mechanic. 													(No longer requires holding down the clutch. It now uses the difference between the RPM of the engine and the RPM of the wheels).
		- Fixed the G-Force plugin underreporting turning forces. 							(For some reason the X-axis was divided by 4.5 instead of 3).
		- Ignition requires letting go of the ignition before the car begins running. 		(It now assumes the car is already on while starting, so you can check if Starting is false and IsOn is true if you want to truly see if the car is running).
		- Fixed an inaccuracy with the Aerodynamics plugin.									(It now squares the magnitude of the wind speed instead of each axis).
		- Fixed RevAccel.																	(It no longer uses the torque of the engine).
		- Fixed smoke appearing in front of the wheel.										(This was fixed in 1.6, but something happened and it got removed.)
		- Removed ClutchIdle now that RevDecay is fixed.									(The point of ClutchIdle was to allow the chassis to move when the RPM was below Idle because power was cut off below those RPM's so the car wouldn't move. However, that's kinda just what happens irl anyway so I removed it.)
			- Consequently, there is now in-built creep which can be disabled with Tune.RemoveCreep		(It's not a bug, it's a feature!)
		- Renamed S_PeakBoost to just S_Boost.												(This is to be friendlier to plugins from 1.5.)
		- Initialize with RigidConstraint instead of Weld.									(RigidConstraint will probably be supported for longer and might have more accurate physics than Weld. idk)
		- Added back PBrake saving when exiting the car.									(I probably accidentally removed this on the transition to 1.6 because 1.5's PBrake on by default was pretty annoying ngl, but it's back now!)
		- General quality improvements.
			
			
			
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Previous Versions

[02/27/2024 : A-Chassis, Version 1.6.3.4] - A fix from a Roblox update.
	[Fixes] -Detomiks
		- Clamped all density values in Initialize to stop warnings.
		
[01/31/2024 : A-Chassis, Version 1.6.3.3] - january moment
	[Fixes] -Detomiks
		- Fixed the turbos dying randomly.

[01/25/2024 : A-Chassis, Version 1.6.3.2] - another little patch
	[Fixes] -Detomiks
		- Changed density of players to 0.01 from 0 in initialize to follow Roblox's buoyancy update.
		
[01/20/2024 : A-Chassis, Version 1.6.3.1] - a little patch
	[Fixes] -Detomiks
		- Removed the progressive springs, as the calculations were broken, and this can be easily replicated with a plugin.

[12/17/2023 : A-Chassis, Version 1.6.3] - the moral of the story...
	[Features] -Detomiks, midmm55
		- Tires plugin includes optional tire flex and tire weight, and tire marks.
		- Pressing V hides things like tires, power graphs, G-Force and holding hides everything.
		- Redid the engine calculations to be more intuitive.

	[Fixes] -Detomiks
		- Performance improvements and code optimizations.
		- Proper body welding.
		
[10/08/2023 : A-Chassis, Version 1.6.2.1] - Minor fixing...
	[Fixes] -Detomiks
		- Removed the camera plugin
		- Fixed incline compensation

[10/01/2023 : A-Chassis, Version 1.6.2] - little update
	[Features] -Detomiks
		- Added SteerSpeedDecay and MinSteerSpeed to configure the new steer speed settings
		- Added variable spring rates.
		
	[Fixes] -Detomiks
		- Hinge surface connecting Base to Arm is now a hinge constraint to stop wheels from steering backwards. (Detomiks)
		- Fixed engine calculations being broken. (Detomiks)
		- Fixed serious ping issue.
		- Fixed wheels flippimg around.
		- Reverted back to unscalable values for performance.
		* General default tune fixes.
		
	[Plugins] -Detomiks, chedsapp
		- New Camera plugin found by phen/midmm5
		- Default plugins now have A-Chassis credits. (Detomiks)
		- Aerodynamics uses ApplyImpulseAtPosition. (chedsapp)
		- Rewrote Controls Module in case controls are added later down the line. (Detomiks)

[07/08/2023 : A-Chassis, Version 1.6.1] - A bunch of bugs
	[Fixes] -Detomiks
		- *Most* 1.5 plugins can be easily ported to 1.6.
		- Auto/CVT conflicts resolved.
		- New Gauges look
		- Aerodynamics is a plugin again.
		- "Wobbly" wheel parts solved.
		- G-Force meter displays correctly with unrealistic gravities.
		- Units is relative to length, mass, and force now.
		
[07/08/2023 : A-Chassis, Version 1.6.0] - The Modern Era
	[OVERHAULS] -Detomiks
		- Completely redid all the engine calculations. Begone terrible horsepower numbers!
		- Changed scaling chassis-wide using: https://create.roblox.com/docs/physics/units
		- Mobile support with taps and tilting.
		- CVT behaves A LOT more realistically now.
		
	[Features] -Detomiks
		- Added cylinder wheels by changing some Initialize stuff... you can easily change back to ball wheels by setting the Shape property to "Ball" and setting all 3 sizes to be the same.
		- Sway bar is now a spring constraint. It is now MUCH, MUCH, MUCH easier to tune properly. A tutorial on how to set it up might be coming soon...
		- Gravity compensation because you people keep complaining about it...
		- Individual disabling of steering in each wheel. Just add a boolean attribute in the wheel called "SteerDisabled". Thanks @MEGAHACKER2228 for the idea.
		- Wheel weight instead of density.
		
	[Fixes] -Detomiks
		- RPM management improved:
			- Revlimiter that changes the throttle.
			- Removed idle throttle since idle is actually held with throttle now.
			- "Starting" value added. Use this for a Drive-controlled startup.
			- Rev acceleration and deceleration is now more like Automation and BeamNG.
			- Smoother overall by averaging the wheel rotational velocity to account for jittery Roblox physics.
		- Made axle structural member positions not garbage in code.
		- Update system works with new update codes and is mostly future-proofed.
	
	[Plugins] -Detomiks
		- Renamed many plugins to be more user-friendly and fit with the possibly new naming scheme?
		- Removed many plugins to reduce bloat. Most have been migrated directly into the drive.
		- Added new sounds module to go with the new calculations.
		- Controls module has working deadzone sliders now along with rounded corners. A full redesign and overhaul is coming soon.
		- Gauges have finally been updated.
		- Tires features new haptics among a standalone wheel tune module.
		- Mouse Steer Camera retains camera position before activation.
		- Little G-Force meter.
		
[01/26/2023 : A-Chassis C Version 1.51.2] - just a fix: the late sequel
	[Features] -Adhamkhedrhuman
		- A RodConstraint sway bar is now dumped into the chassis and will be scriptable in 1.52 but in the meantime you can have a customizable sway bar you can enable.
		
	[Fixes] -Adhamkhedrhuman and hwoagh_a	
		- Attach camera is now used in mouse steering to restrict movement when braking
		- Added hwoagh_a's turbocharger fix

	[Miscellaneous] -Adhamkhedrhuman
		- Balanced the slipstream multiplier for better racing against 1.52 cars (to backport the change change slipstreamMult to 25)
		
[07/02/2022 : A-Chassis C Version 1.51.1] - just a fix
	[Fixes] -SW_TK and Adhamkhedrhuman
		- Editable values for what enables and disables in the mouse steering added by Adhamkhedrhuman
		- Mouse steering by SW_TK is added

[05/27/2022 : A-Chassis C Version 1.51] - The up to Date for 2022 Update.
	[Features] -Eniiqz
		- Speed limiter added

	[Fixes] -Adhamkhedrhuman and Gam3rPlay3r
		- The gear you are on resetting to neutral when re entering the car is fixed
		- Added Gam3rPlay3r's Anti-Loop plugin
		- Fixed the mouse steering camera
		
	[Engine sounds] -Adhamkhedrhuman
		- Added a reverb effect that can be enabled
		
	[Plugins] -Adhamkhedrhuman, SW_TK, hwoagh_a, riojr100, moonaux, EA11_R, itzt, crazy378, Arriva_chessboy, Birdatoo, Eniiqz, 7h3L337Dude and ArisNeta
		- Added SW_TK's fortune advanced first person plugin with ArisNeta's invisible first person hats integrated with values to turn both on and off
		- Added the liftoff backfire plugin that makes crackle sounds uploaded but not made by 7h3L337Dude with on and off values
		- Added an engine shake plugin with on and off values sent to me by a friend (creator unknown)
		- Added a basic version of Pog Mobile Support 1.4 by Eniiqz and Adhamkhedrhuman
		- Added Birdatoo's universal transmission whine adapted for a chassis which is enabled in te IgnitionHandler
		- Added SWT_K's mouse steering but with the indicator removed and the inivisble cursor kept
		- Added my modified transmission shift sound (original creator unknown)
		- Added Arriva_chessboy's brake squeal plugin with a value to enable and disable it
		- Added hwoagh_a's AC6 SoundPack with the sounds that are good for being played from the DriveSeat
		- Added the burnout script uploaded but not made by crazy378 with on and off values
		- Added itzt's creep plugin with on and off values
		- Added EA11_R's brake fade with a heat display that can be enabled
		- Added moonaux's editable AC6C gauges with color reset back to normal
		- Added Adhamkhedrhuman and riojr100's upgraded AC6C startup with all sounds able to be enabled and disabled
		- Power to weight modified power and torque reader by hwoagh_a added
		- Added PacejkaTires 
		- IgnoreGuiInset enabled in the interface for better mobile scaling

	[Aerodynamics] -Adhamkhedrhuman and RikOne2
		- Readded the body sound 
		- Blown diffuser system added
	    - Integrated the stuart six slipstream plugin
		- Wind sound replaced to a sound that i can unprivate later when it is possible
		
	[Optimizations] -Adhamkhedrhuman
		- Default invisible positonable system parts and SUSpension parts very slightly optimized
		- More massless parts for better weight accuracy 
	
	[Miscellaneous] -Adhamkhedrhuman
		- Speed autoscaling in the gauges is off by default
		- Turning on SUSvisible actually makes your SUSpension fully visible with no transparency
		- Pre toggled parking brake turned off by default
		- Transmission mode order changed to order from easiest to hardest
		
[02/01/2021 : A-Chassis C Version 1.5, Update 2] - DO People Read These?
	[Misc] -LuaInt
		- Weight brick density cap added
		- Rear caster fixed
		- Aerodynamics fixed
		- Engine and induction sounds fixed

[12/31/2020 : A-Chassis C Version 1.5, Update 1] - The Movement Update 2, The Reckoning
	[Overhaul] -LuaInt
		- Weight calculation entirely rewritten
		- Torque delivery calculation simplified, engine untouched
		
	[New Suspension System] -LuaInt
		- In-depth player-built suspension (Tutorial can be found on our server)
		- Chassis contains double-wishbone suspension on all 4 wheels by default
		- Deleting the "SuspensionGeometry" model inside of a wheel will revert it to pre-1.5 suspension
		
	[Plugins] -LuaInt
		- New aerodynamics plugin
		- New stock engine and exhaust sound plugin
		- New forced induction sound plugin
		
	[Miscellaneous] -LuaInt
		- Tune reorganized

[07/09/2020 : A-Chassis C Version 1.4, Update 4] - The Burnout Update
	[Welding Bugfix] -Avxnturador and LuaInt
		- Fixed a parenting issue in the Initialize script regarding welds, making client and server replication break.
		
	[Parking Brake Bias] -Avxnturador
		- Added Parking Brake Bias, works like regular Brake Bias
		
	[Four Wheel Steering Update] -LuaInt
		- Updated Static 4WS as part of a bugfix.
			
[06/19/2020 : A-Chassis C Version 1.4, Update 3] - The Braking Bugfix
	[Updated Parking Brake] -LuaInt
		- Updated Parking Brake for simplicity in the Drive
		- Also fixes a bug where all 4 wheels have the parking brake applied

[06/14/2020 : A-Chassis C Version 1.4, Updates 1 and 2] - The Movement Update
	[Pertaining to Update 2] -LuaInt and Avxnturador
		- Separated Front and Rear Steering gyro options (Added Tune.RSteerD, Tune.RSteerMaxTorque and Tune.RSteerP)
		- Added rear wheel steering to "R" wheels
			Please add Tune.RSteerD, Tune.RSteerMaxTorque and Tune.RSteerP to the tune to take advantage of separated gryo options

	(Personal Note by Avxnturador)
		This update would not have been as big of an update without LuaInt
		With that said, LuaInt is now the newest member to the AC6 and NCT chassis team.
		Thank him endlessly.
		
	[New Engine] -Avxnturador 
		- Combining AC6C V1.2's engines alongside AC6C V1.3's aspiration, the engine now has its final revision
		- Instructions to tune it are now similar to both previous versions of the chassis', and a new Desmos graph reflects it
	
	[PGS Physics Overhaul] -LuaInt
		- The chassis now uses PGS Physics Solver Components to replace the legacy BodyMovers
		- Different Power and Brake motors are now implemented, bringing a more realistic driving experience
		
	[Rev Limiter] -Avxnturador
		- Limits the RPM to a certain set RPM
		- Can be limited in Neutral gear or when the clutch is in
	
	[New Steering] -LuaInt
		- More realistic steering options
		- Ackermann steering included for more true-to-life steering
	
	[Four Wheel Steering] -LuaInt
		- If activated, the rear wheels will turn alongside and/or against the front wheels
		- Check the Tune to see how to tune it
		- Note: Always have the rear wheels' degrees (e.g. 12, 15) LESS THAN the front wheels (e.g. 37, 45)
	
	[New Differential] -LuaInt
		- The new differential is easier to understand and tune
		- Includes power, coast, and preload
	
	[Clutch Kick] -LuaInt
		- Torque will be multiplied if a clutck kick occurs
		- Helpful for getting extra power to drift or get up hills
	
	[Braking Overhaul] -LuaInt
		- Braking has been combined, alongside with brake bias
		- Engine braking has also been introduced
	
	[Suspension Geometry Separation] -Avxnturador
		- The suspension geometry (the wishbone and spring) can now be separated
		- This is done with the new Spring Offset values
		- This will move the spring offset IN RELATION TO THE ANCHOR OFFSET

	[Weight Optimization] -Avxnturador
		- Objects with the Massless property enabled will be ignored when calculating weight
		- This is insanely helpful for highly detailed cars where the cars' mass would reach excess of 1000 or so

	[Others] -Avxnturador
		- Revamped the Auto Update feature to be better alongside the new model
		- Removed the Drag feature, allowing third-party plugins to handle that force by itself
		- Added RCaster for four wheel steering enabled cars 
	
	[Legacy Physics Deprecated] -LuaInt and Avxnturador
		- With the release of this new chassis, Legacy physics engine support has been completely deprecated
		
[09/18/2019 : A-Chassis C Version 1.3, Update 1] - The Engine Update
	[Engine]
		-The engine from the NCT: M chassis has been carried over
		-This allows for great control over your power graphs
		-This also separates aspiration, allowing for twincharging and unlimited aspiration objects
	
	[Backwards Compatibility]
		-If you don't want to retune your engine, backwards compatibility has been brought over
		-You can use your AC6C V1.2 engine tune with this update
		-Take a look at #ENGINE to look at engine backwards compatibility
		-YOU MUST UPDATE THE WHOLE ENGINE CODE IN THE TUNE, #ENGINE WILL THEN OVERRIDE THAT CODE!
	
	[Clutch]
		-Added three different clutch types, all under Tune.ClutchType
			-Clutch, standard clutch present in AC6C
			-Torque Converter, keeps RPM up overall
			-CVT (however not a true CVT), keeps RPM at a set RPM until above
	
	[Other]
		-Added Tune.Drag, simulating drag right from the chassis
		-Added throttle and brake responsiveness
			-Tune.ThrotAccel and Tune.ThrotDecel
			-Tune.BrakeAccel and Tune.BrakeDecel
		
		-Fixed auto-updating feature, PLEASE update or reinstall this chassis to your cars.
	
[05/28/2019, 05/30/2019 and 07/31/2019 : A-Chassis C Version 1.2, Updates 3, 4 and 5] - The Optimization Update
	[Bugfixes]
		-Added delta time so the chassis runs smooth at any framerate
			-RPM, steering, and power all contain these fixes.
			-The clutch, due to its' nature, is not optimized, however it should still be good.
		-Fixed curve caching so HP and Torque don't jump from one value to the other
		-Fixed a typo that disallowed electric motors to rev (yes, really)
		-Fixed boost intakes so they cut off once throttle is cut off (mainly in shifting)
	
	To install, please replace the Drive script, and update the "Version" value to 5.

[04/28/2019 : A-Chassis C Version 1.2, Update 2] - The Rev Update
	[Bugfixes]
		-I literally just made it so revving with clutch off felt like old A-Chassis.
		-That's it. It's just so it revs like it should.

[04/16/2019 : A-Chassis C Version 1.2, Update 1] - The Transmission and Future-Proof Update 
	[Clutch]
		-After having a very rough start and notoriety, a newer clutch system has been added. 
		-Torque should now be fixed, tune revision from previous versions highly recommended.
		-Special thanks to IMeanBiz, the creator of the newly-revised clutch.
			Note: PLEASE DO NOT SEND TRANSMISSION QUESTIONS TO HIM! Send them to Avxnturador instead.
		-Tune.Clutch has been added, disabling it makes the chassis act like AC6.81T (no realistic clutch).
		-Tune.ClutchMode has been added, changes if RPM will influence the clutch or not.
	
	[Transmission Changes]
		-Automatic shifting has been revamped, making it fail-safe.
		-Automatic shifting settings has been expanded on.
			-Automatic shifting mode, toggle between Speed and RPM
			-Automatic shifting type, toggle between DCT (AC6.81T) and Rev (AC6C V1)
			-Automatic shifting version, toggle between Old (AC6.52S2) and New (AC6.81T)
		-Old "Shift Time" shifting behavior is reintroduced under "DCT".
		-Revmatching is modified, values for throttle behavior introduced.
	
	[Automatic Updates]
		-In an attempt to heavily reduce bugfix releases, an auto updater has been added.
		-You are heavily advised to take a copy of this chassis if you haven't already.
		-Minor bugfixes will automatically be installed, while major updates will not.
		-You will be notified of any update, minor or major. 
		-You can opt out of this by changing "Tune.AutoUpdate" to false.
	
	[Tune Changes]
		-A completely new Transmission tune panel, check the values inside for more information.

[12/09/2018 : A-Chassis C Version 1.1] - The Refinement Update
	[Drive Changes]
		-Manual transmission gearshifts now work properly.
		-Downshift revmatching has been implemented.
		-The clutch is now smooth when the clutch is disengaged. Only works and makes sense in Manual transmissions.
	
	[Tune Changes]
		-Added "Tune.ClutchSens", Clutch Sensitivity. 
		-Added "Tune.Stall", the ability to stall. 
	
	[Plugin Changes]
		-Added "AC6C_Ignition", a stock ignition switch. "F" is the key to start/stop the engine.
	
	[Note]
		-To stop stalling at low RPM's, most noted in first gear, engage the clutch around where Idle RPM is set right before you come to a stop.
	
	[Planned future updates]
		-New, more efficient sound scripts. Thanks to lsThisThingOn for the idea of replacing the scripts for something better.

[12/02/2018 : A-Chassis C Version 1.0] - The Anniversary Update
	[Clutch]
		-With a humongous thanks to DJay500, the newest member to Novena, a proper clutch has been added. 
	
	[Drive Changes]
		-A new clutch system has been added, along with new RPM calculations.
		-The gear system has been reworked. Upshift revmatching is now implemented.
	
	[Tune Changes]
		-Changed "Tune.ClutchTol" to "Tune.Flywheel"
		-Added "Tune.ClutchMult", Clutch Multilpier.
	
	[Plugin Changes]
		-Changed the stock gauges to include options to change the clutch input.
		-The white button will allow you to change the clutch amount. Full white bar means clutch engaged, no white bar means clutch disengaged.
	
	[Planned future updates]
		-Stalling is planned, a stock ignition plugin would be included if so.
		-Downshift revmatching is planned to complement everything else.
		
		[11/09/18 : A-Chassis T Build 6.81] - The AWD Bugfix
	[All Wheel Drive]
		-Fixed a bug with the torque split for All Wheel Drive. Top speed will be reached much more realistically now.
		
[09/20/2018 : A-Chassis T Builds 6.75 and 6.8] - The Supercharged Update
	[Supercharger]
		-Utilizing new boost calculations, the car now has supercharging capabilities.
		
	[Drive Changes]
		-Fixed the AWD torque bug, and added torque vectoring as a bonus.
		-Fixed the turbo spooling up too fast (Thanks to IMeanBiz, the original turbo script guy.)
		-Added supercharger boost.
		
	[Tune Changes]
		-Added "Super" mode in Tune.Aspiration
		-Added Tune.Sensitivity, read the value in the Tune to get up to speed with it.
		-Added Tune.TorqueVector, lets you change the amount of power your wheels have.
		
	[Plugin Changes]
		-Changed the gauges to support the supercharger.
		-Changed AC6_Turbo_Sound to AC6_Boost_Sound, has a supercharger whine.
		
	[Credits]
		-Credits to iiEpikz for the supercharger whine, Bexn and GloJxy for their help in the knowledge of superchargers, and to Autoclub for helping me test this out.
	
	Install by changing the Drive script, and adding all the new tune values described above.
		
[05/05/2018 : A-Chassis T Build 6.72] - The Rebirth's Bugfixes
	[Tune Changes]
		-"RAntiRoll" is fixed and an actual value, beforehand it only had 2 FAntiRolls and no RAntiRolls.
		
	[Transmission Changes]
		-Automatic transmission has been properly fixed and works flawlessly.
		
	Install by changing the Drive script, and by changing "FAntiRoll" in line 70 to "RAntiRoll" in the Tune.
		
[04/11/2018 : A-Chassis T Build 6.7] - The Rebirth
	[IMPORTANT]
		-A whole re-write of the chassis has been done. Taking AC6.52S2 and re-writing everything, most bugs from other versions should be removed.
		
	[Drive Changes]
		-Curve caching is mandatory and always on, CurveCache and CacheInc is removed.
		-Wheel RPM is now fixed and gets the rotation velocity from ALL driven wheels.
		
	[Boost Changes]
		-The turbo properly spools up and keeps its spool once changing gears or engaging and disengaging the clutch.
		
	[Transmission Changes]
		-Disabled the wait time in Manual transmission mode.
		-Shifting between Reverse, Neutral and Drive is possible in Automatic transmission mode, credit to BobNoobington for this.
		
	[New Values]
		-FCaster, only in the front, credit to Zyori for this.
	
	[Credits]
		-Credits to RikOne2, Zyori, and BobNoobington for helping me out with special features.
		
	Install by changing the initialize, A-Chassis Interface, and by adding "FCaster" in the tune.
	
[03/25/2018 : A-Chassis T Build 6.62] - The Small Bugfixing Update
	[Fixes]
		-Turbo stays spooled up while shifting.
		-If you throttle up while shifting, power will stay instead of staying at 0.
		
	Install by changing the Drive script.
		
[02/15/2018 : A-Chassis T Build 6.6] - The Realism Update
	[Curves]
		-Curves are now fixed due to a re-write of the Horsepower and Torque curves.
		-Instead of the HP and Torque being insanely off, it's now perfected.
			-Example: A naturally aspirated car with the horsepower at 180 will have its max HP be 180, not 360.
	
	[New Car Values]
		-TCSAmt (The amount of cutoff TCS has on the throttle)
		
	[New Tune Values]
		[EDITABLE]
		-ShiftTime (The time delay in which you initiate a shift and the car changes gear)
		[STANDARDIZED] (Highly recommended you don't touch these in the tune)
		-CurveCache (The time delay in which you initiate a shift and the car changes gear)
		-CacheInc (The time delay in which you initiate a shift and the car changes gear)
		
[12/2/2017 : A-Chassis T Build 6.5] - The Turbocharged Update
	[Turbocharger]
		-Utilizing IMeanBiz's turbo scripts, the car now has turbo.
	
	[New Car Values]
		-HpNatural (Horsepower made by the engine naturally aspirated)
		-TqNatural (Torque made by the engine naturally aspirated)
		
		-HpBoosted (Horsepower made by the turbocharger[s], NOT including HpNatural HP)
		-TqBoosted (Torque made by the turbocharger[s], NOT including TqNatural Torque)
		
		-Boost (Total boost [in PSI])
		
	[New Tune Values]
		-Should all be self explanatory in the tune.
		
	[New Plugins]
		-AC6T Stock Gauges, includes a turbo thing in the middle (when car is turbocharged), can easily be swapped with AC6 default gauges if not wanted.
		-Turbocharger sounds, which works regularly
		
	[Rewritten Values]
		-Horsepower (Horsepower combined from the engine and turbocharger[s])
		-Torque (Torque combined from the engine and turbocharger[s])

[05/23/2017 : Build 6.43S] - STUFF
	[Added Tune Values]
		-Added WBVisible to set weight brick visibility
	
	[Independent Camera Handling]
		-Separated camera handling from Drive script
		-Mouse camera is now handled by a plugin
		-Custom camera plugin support is now easier
	
	[Stock Plugins Update]
		-Added Dynamic Friction as a stock plugin
		-Dynamic friction can be tuned within the Simulated script
		-Updated default sound plugin
		-Added mouse-steer camera plugin
	
	[Code Fixes]
		-Fixed missing operation within torque curve
		-Slight optimizations during runtime

[05/20/2017 : Build 6.42S] - ABS and PGS Standardization

	[Added ABS]
		-Modulates brakes when locking
		-Added threshold value for slip allowance
		-Added control toggles for ABS
		-Added ABS indicator and control mapping to stock UI
	
	[Split Density Tuning for PGS and Legacy]
		-Added standardized weight scaling values to tune
		-Default weight tuning set to 1 cubic stud : 50 lbs for PGS
		-Default weight tuning set to 1 cubic stud : 10 lbs for Legacy
		-Split front and rear density to PGS and Legacy
		-Split brake force tuning to PGS and Legacy
	
	[Added Tune Values]
		-TCSEnabled: Sets whether or not the car will have TCS
		-ABSEnabled: Sets whether or not the car will have ABS
		-LoadDelay: Sets a delay time before initializing car
	
	[Bug Fix: Axle Size Initialization]
		-Car applies proper axle size
		-Added AxleDensity value which sets axle density
		-Fixed miscelaneous wheel part welding
	
	[Added Changable Stock Gauge Units]
		-Added units system for stock gauges
		-Added default units: MPH [1 stud : 10 in], KP/H [1 stud : 10 in], SPS
		-Custom units can be added or removed
		-Click on speed to change between units
		-Moved Controls button to middle for better visibility
	
	[Code Documentation]
		-Extensive documentation and commenting within scripts for better readability
		-Improved warning message for oversized mass condition

[05/04/2017 : Build 6.41S] - Standardized Weight

	[Added automatic weight system]
		-Added tune values for car weight, center of gravity, and wheel density
		-Weight standard: 100 lbs = 1 cubic stud mass
		-Applies weight at initialization
	
	[Scaled Down Power Delivery]
		-Horsepower output now at 1/10 because of lighter weight standard
		-Added FDMult value in transmission for gear ratio scaling without having to change Final Drive (useful for low HP tunes)
	
	[Optimized value for Anchor Offset]
		-Changed "SusOffset" to "Anchor Offset"
			-New anchor offset is now based off of wishbone length and wishbone angle.
		-Anchor offset now labelled for forward, lateral, and vertical offsets.
	
	[Split some tune values to F/R]
		-Suspension values for front and rear are now independently tunable.
		-Front and rear brakes can be tuned independently.	
	
	[Tune Module Housekeeping]
		-Rearranged and documented several of the values within the tune module.
		-Removed GyroP and GyroMaxTorque for simplicity. Dampening values are still present.
		-Changed some decimal values to percent values 

[01/02/2017 : Build 6.40S] - Suspension
	"S" Build number identifies suspension build

	[Added suspension system for PGS Physics Solver]
		-Suspension uses ROBLOX constraints and is automatically generated with the chassis
		-Added tune values for suspension
		-Temporarily removed caster tuning
	
	[Steering Fix]
		-Added tune value 'ReturnSpeed' which determines how fast wheels return to default orientation
	
	[New Torque Curve Equation]
		-New equation gives more control over the shape of the torque curve
		-Engine values have been replaced with the new equation's variables
		-Added link to desmos graph for the torque curve visualization

[10/31/2016 : Build 6.33] - Semi-Automatic
	
	[Added semi-automatic transmission mode]
		-'TransModes' now accepts "Semi" value for semi-automatic.
		-Updated AC6_Stock_Gauges to include semi-automatic mode.
	
	[Fixed disengaging p-brake]
		-P-Brake now remains engaged if player gets into then vehicle.
	
	[Fixed FE Support for AC6_Stock_Sound]
		-Sounds should now work properly with Filtering Enabled.

[08/05/2016 : Build 6.32] - Differential System
	
	[Implemented differential system]
		-Differential controls torque distibution between wheels that are spinning at different rates
		-Added tune values 'FDiffSlipThres', 'FDiffLockThres', 'RDiffSlipThres', 'RDiffLockThres', 'CDiffSlipThres', and 'CDiffLockThres'.
		-'DiffSlipThres' determine the threshold of the speed difference between the wheels. Full lock applies at max threshold.
		-A lower slip threshold value will make the diff more aggressive.
		-'DiffLockThres' determines the bias of the differential.
		-A lock threshold value more than 50 puts more torque into the slipping wheel (moving towards an open diff).
		-A lock threshold value less than 50 puts more torque into the grounded wheel (moving towards a locked diff).
	
	[Fixed multiple wheel support]
		-The chassis can now use more than just the default 4 set of wheels. Just copy an existing wheel and place accordingly.
		-Differential works with auxiliary wheels.

[07/13/2016 : Build 6.31] - Peripheral Settings
	
	[Added peripheral adjustment values]
		-Moved controller and mouse deadzone values to the "Controls" section of the tune.
		-Split controller deadzone into left and right input.
		-Moved mouse control width to "Conrols" secton. This value now operates based off of % of screed width.
		
	[Updated stock Controls Module]
		-Added sliders for controller and mouse deadzone values.
		-Added slider for mouse control width.

[06/15/2016 : Build 6.3] - Motercisly

	[Better motorcycle system support]
		-Added wheel configurations "F" and "R" for single wheel settup.
		-"F" and "R" wheels will have axle parts on both sides for better balance.
		-These wheel configurations will ignore outor rotation value and will rotated based off of the inner rotation value only.
		-Camber and Toe cannot be applied to these wheel configurations. Caster will still be applied as normal.
	
	[Bug fixes]
		-Caster now applies after wheel part rotations so wheel parts dont rotate with caster.
		-Fixed Clutch re-engaging automatically when shifting out of neutral.	
	
[06/04/2016 : Build 6.21] - AC6 Official Public Kit Release

	[Plugin FilteringEnabled compatability made easier]
		-System now detects if there is a RemoteEvent or RemoteFunction inside a plugin. These will be parented directly under the car.
		-The RemoteEvent/RemoteFunction needs to be a direct child of the plugin for it to be detected.
		-Scripts inside the RemoteEvent/RemoteFunction should be disabled. They will be enabled after initialization.
		-Be careful as this system is suceptible to name collisions. Name your RemoteEvents/RemoteFunctions uniquely.
		-Stock AC6 Sound plugin is now FE compatible.

	[Controls Panel now a plugin instead of integrated]
		-Separated controls panel from Drive script. The controls panel is now a plugin.
		-The "Controls" folder appears inside the interface on Drive startup. Use this folder to reference button mapping values for custom controls plugins.
		-"ControlsOpen" value added. This is a safety toggle when changing control values. This value can be manipulated by plugins.
	
	[New tune values]
		-Added 'AutoFlip' tune value. This determines if the car automatically flips itself over when upside down.
		-Added 'StAxisOffset' tune value. This offsets the center of the steering axis. Positive value = offset outward.
		-Added 'SteerD', 'SteerMaxTorque', and 'SteerP' values which set the steering axle gyro properties.
	
	[MiscWeld streamlining]
		-Added "Misc" section to the main sections. This should contain scripted/moving parts.
		-Parts in this section are NOT WELDED AUTOMATICALLY. Use the "MiscWeld" module to weld these parts. The "Misc" section is pre-referenced as 'misc'.
	
	[Bug fixes]
		-Fixed flip gyro not resetting when gyro is active and driver leaves car.
		-Fixed issue with switching transmission modes.
--]]
-- yes, it is completely necessary to include the logs from 2016

return "1.7"