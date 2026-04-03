ATM10 & CC:Tweaked Draconic Evolution Reactor Monitoring System (v1)  
Author: kyoji42

1. Overview
This project provides a graphical monitoring system for the Draconic Evolution Reactor in
All The Mods 10 (ATM10) v6.2.1, implemented using CC:Tweaked.

The system focuses on safe, real‑time monitoring, offering:

  Graphical UI (bar graphs + multi‑line charts)
  Recommended output estimation
  Remaining operation time prediction
  Maximum safe output estimation
Safe / Aggressive mode switching

This version (v1) is monitoring‑only.
A separate control option (output control, emergency shutdown, etc.) will be released in a future update.

2. Tested Environment
Minecraft Modpack: All The Mods 10 (ATM10) v6.2.1

Required Mod: Draconic Evolution Render Patcher v1.1.2
https://www.curseforge.com/minecraft/mc-mods/draconic-evolution-render-patcher

Without this patch, the reactor may not render visually (it still functions).
Install the patch if you want the reactor to be visible.

3. Installation
There are three supported installation methods:

  A. Direct file placement
  Copy the .lua files into the target computer’s directory:

  .minecraft/saves/<WorldName>/computercraft/computer/<ComputerID>/
  The folder is created automatically after saving any file via the edit command.

  B. Download via wget
  Use CC:Tweaked’s wget command to download files directly from GitHub.
  Outside PC
  wget https://raw.githubusercontent.com/gmiz42/ATM10-cc-tweaked-Draconic-Evolition-Reactor-Monitoring-System/main/install_outside.lua install.lua
  install
  
  Inside PC
  wget https://raw.githubusercontent.com/gmiz42/ATM10-cc-tweaked-Draconic-Evolition-Reactor-Monitoring-System/main/install_inside.lua install.lua
  install
  

  C. Floppy disk transfer
  Copy the .lua files into the disk directory on your real PC:
  .minecraft/saves/<WorldName>/computercraft/disk/<DiskID>/
  Insert the disk into a Disk Drive in‑game
  Use fs.copy() to transfer files to the computer

Reference: https://tweaked.cc/module/fs.html

4. Setup Instructions
Prerequisites
You must defeat the Chaos Guardian to obtain Chaos Shards, required for reactor construction.

Recommended Reactor Location
Use a Compact Machine (Soaryn or Farming type).
Running the reactor in a separate dimension is strongly recommended.

Chunk Loading
Ensure the entire setup fits within one chunk and keep it chunk‑loaded.

Required Draconic Evolution Blocks
  Reactor Core ×1
  Reactor Stabilizer ×4
  Reactor Injector ×1
  Flux Gate ×2

Energy Output Destination
Use a high‑capacity energy storage system, such as:
  Draconic Evolution Energy Core
  Mekanism Induction Matrix
  Applied Flux (AE2 addon) Flux Accessor (256M cell)

Required CC:Tweaked Components
  Advanced Computer ×2
    One connected to the Reactor Stabilizer (inside PC)
    One connected to the monitor (outside PC)

  Ender Modem ×2
    Enables cross‑dimension communication

  Wired Modem (block) ×1+
    Attach to Draconic Evolution machines

  Wired Modem (item) ×2+
    For monitor and Flux Gate connections

  Network Cable (as needed)

  Advanced Monitor
    Height: 4 blocks
    Width: 8 blocks

Ensure all modems are activated by right‑clicking them.

Safety Tip
  (Mekanism) Cardboard Box  
  If a small explosion occurs, right‑click the reactor core with a cardboard box to safely package it.

5. Usage
  1. Identify peripheral names
  Use the peripherals command to list connected devices.

  2. Edit configuration files
  Update the config files (config_inside.lua, config_monitor.lua) with the correct peripheral names.

  3. Enable auto‑start
  Rename the program file to:
  startup.lua
  The system will start automatically when the computer boots.

  4. Mode switching
  Right‑click the Mode (touch) button on the monitor to toggle between:
    SAFE (conservative output recommendations)
    AGGRESSIVE (higher output recommendations)

6. Screen Layout Explanation
Left Side (Bar Graphs)
  Temperature
  Field Strength
  Energy Saturation

Right Side (Line Graphs)
  Temperature trend
  Saturation trend
  Field strength trend
  Estimated remaining operation time
  Fuel burn rate

Bottom Section
  Top row: Recommended output, headroom, current mode
  Middle row: Reactor status, current output, fuel usage and remaining percentage
  Bottom row: Temperature, burn rate (nB/t), estimated remaining time

7. Notes
  License
  MIT License (see LICENSE file on GitHub)

  Contact
  GitHub Issues or Twitter: @kyoji42

  To‑Do
  Implement optional control module (output control, emergency shutdown)

8. Disclaimer
The Draconic Reactor is an extremely dangerous power source:
  Overheating → explosion
  Insufficient input power → explosion
  Excessive output demand → explosion
  Neglect → explosion
  Explosion radius → catastrophic

This monitoring system improves safety, but cannot guarantee prevention of all failures.
If you require a safe, high‑output, fully automated power system, consider other options.
This project is intended for players who enjoy the challenge and aesthetic appeal of Draconic Reactor management.