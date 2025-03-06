--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]
--[[

	All the sounds are scalable, meaning that you can add or subtract as many sounds as you like.
	Each sound is characterized by a three-letter code in the beginning:
		- BOV is the blow-off valve
		- ENG is the engine
		- IGN is the ignition/turning over
		- SUP is the supercharger
		- TRA is the transmission
		- TUR is the turbocharger
	Each sound also includes a "SoundParent" attribute located at the bottom of the properties tab.
	The value of this attribute is the name of the part that the sound is parented to.
	You can change the location of said part in the Sounds plugin script, with the "DIRECTORY" value.
	
	In the properties tab of each sound, there are also attributes at the bottom of the list.
	The engine sounds also include equalizer settings.
	Keep in mind the following settings for all sounds:
		- The "Volume" property does nothing, use the volume settings in the attributes section.
		- The "PlaybackSpeed" property also does nothing.
		
	The Sounds plugin script also includes FilteringEnabled (FE) settings.
	You can find more about those settings in the script.
	
]]

return