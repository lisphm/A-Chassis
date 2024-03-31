# A-Chassis
Welcome to the official GitHub page for A-Chassis. Here, you will find the beta updates and links to the latest versions.

<img alt="A-Chassis 1.6" src="https://github.com/lisphm/A-Chassis/assets/116984726/fb71f6eb-64d4-4692-afe9-42fd7d8489ec" width="400px" align="right">

[![Roblox Stable](https://badgen.net/badge/Roblox%20Stable/1.6.3.4/blue?icon=https://upload.wikimedia.org/wikipedia/commons/6/6c/Roblox_Logo.svg)](https://create.roblox.com/store/asset/13999609938)
[![GitHub Stable](https://badgen.net/badge/GitHub%20Stable/1.6.3.4/blue?icon=github)](https://github.com/lisphm/A-Chassis/releases/tag/v1.6.3.4-stable)
[![GitHub Beta](https://badgen.net/badge/GitHub%20Beta/1.7%20Beta%202/purple?icon=github)](https://github.com/lisphm/A-Chassis/releases/tag/v1.7-beta.2)
 
A-Chassis is a free, open-source chassis kit on Roblox. It is set to provide a beginner-friendly, yet scalable starting point for those who want to experiment with automobiles.
&nbsp;

- 🔌Easy-to-use plugin system
- 💪Extensive user support
- 🌍Used by hundreds of experiences
&nbsp;

If you would like to contribute to the chassis, or if you need help with the chassis, you can check out [our Discord server](https://discord.gg/P2WXGe3U7E).

# Installation
Installing A-Chassis from this page is a simple process.
1. Download the `.rbxm` file from the [Releases](https://github.com/lisphm/A-Chassis/releases) page. You can find previous versions here as well
2. Copy the `.rbxm` file into a place in Roblox Studio

You can also install it with the Roblox model.
1. Go to the [Roblox version](https://create.roblox.com/store/asset/13999609938) and click `Get Model`
2. In a Roblox Studio place, open the <img src="https://github.com/lisphm/A-Chassis/assets/116984726/10eaab8a-4970-4dc8-af49-bec5cada7e78" width="14px">
Toolbox
3. Go into the <img src="https://github.com/lisphm/A-Chassis/assets/116984726/e57ba175-4357-4a07-893c-a5397a39b062" width="14px">Inventory tab
4. Find and click the A-Chassis model to insert it into the place

# Known Issues
*Solved issues will be marked with **SOLVED** for one update cycle*
1. Wheels glitch when approaching the car on spawn
    - Setting network ownership on spawn (Doesn't work)
    - Disabling tire flex (Doesn't work)

2. Entire car shifts when steering on "New" steering type
    - Set this to "Old" until fixed (Temporary solution only, not recommended as it uses deprecated components)
    - RigidityEnabled set to False (Works, but with weak steering at high speed)
3. Front wheel "F" still flips around on spawn (**Solved**)
    - Change both Attachment0 and Attachment1 on "F" to Vector.new(0, 180, 0) (Works)
4. Possible RPM jitter at low RPM
