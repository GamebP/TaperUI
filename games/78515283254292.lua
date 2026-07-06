

-- First if we see the NPC Is not an anomaly -- (NEEED TO KNWO HOW TO GET ANOMALYY)
-- Then we will check them in with doing this sequence (they are all proximitypromts)

-- workspace.Misc.CheckIn.Form.PP
-- workspace.Misc.CheckIn.Camera.PP
-- workspace.Misc.CheckIn.Computer.PP
-- workspace.Misc.CheckIn.Printer.PP
-- workspace.Misc.CheckIn.PrintedBadge.PP
-- workspace.NPCs["<NPC>"].PP

-- To first know where we are going.. To what room..
-- We will check if Room%d has a NPC

-- Then if it has and has not shown us any information at the screen located at ` `
-- then we will first do `workspace.Rooms.Medical.Room1.Minigame.Analyzer.PP`
-- then after that we will do `workspace.Rooms.Medical.Room1.Minigame.Monitor.PP2`

-- Then after that at the screen located at `workspace.Rooms.Medical.Room1.Minigame.TV.Screen.UI.Report.inv` there will be a Report of things located that need to be given to the NPC
-- If we go to the first Frame like inside `workspace.Rooms.Medical.Room1.Minigame.TV.Screen.UI.Report.inv` you will need to find the first Frame Child name and cache it only for that room%d
-- And after caching of what we need to give for NPC in room%d we will need to check if That item even exists in the workspace
-- Item list and its proximitypromts:
-- workspace:GetChildren()[146].Items["Eye Drops"].PP (Eye Drops)
-- workspace:GetChildren()[146].Items["IV Drops"].PP (IV Drops)
-- workspace:GetChildren()[142].Items.Herbs.PP (Herbs)
-- workspace:GetChildren()[142].Items.Medicine.PP (Medicine)
-- workspace:GetChildren()[145].Items.Medkit.PP (Medkit)
-- workspace:GetChildren()[145].Items.Thermo.PP (Thermo)
-- workspace:GetChildren()[144].Items.Ointment.PP (Ointment)
-- workspace:GetChildren()[144].Items.Bandages.PP (Bandages)
-- workspace:GetChildren()[143].Items["Cough Syrup"].PP (Cough Syrup)
-- workspace:GetChildren()[143].Items["Maple Syrup"].PP (Maple Syrup)

-- Since the original path was around 142 to 146 .. we will need to first find by looping through the `workspace:GetChildren()[%d].Items[.]<item>` to get the proximity promt.
-- Item list:
-- ["Eye Drops"].PP
-- ["IV Drops"].PP
-- Herbs.PP
-- Medicine.PP
-- Medkit.PP
-- Thermo.PP
-- Ointment.PP
-- Bandages.PP
-- ["Cough Syrup"].PP
-- ["Maple Syrup"].PP

-- So after we get the item, it will be located at `game:GetService("Players").LocalPlayer.Backpack` and you will need to itirate and find the correct item we need to give.
-- Since the list in `game:GetService("Players").LocalPlayer.Backpack` is like this for example:
-- `game:GetService("Players").LocalPlayer.Backpack.Herbs` is the first item. But when I click 1. It will equip it.
-- `game:GetService("Players").LocalPlayer.Backpack.Medicine` is the second item. But when I click 2. It will equip it.
-- `game:GetService("Players").LocalPlayer.Backpack.Medkit` is the third item. But when I click 3. It will equip it.
-- But in the UI for the player it looks like this 1, 2, 3

-- But the thing is when I trash one item like for example i put Medicine in the trash
-- It will be like this now:
-- `game:GetService("Players").LocalPlayer.Backpack.Herbs` is the first item. But when I click 1. It will equip it.
-- `game:GetService("Players").LocalPlayer.Backpack.Medkit` is the third item. But when I click 3. It will equip it.
-- `game:GetService("Players").LocalPlayer.Backpack.Thermo` is the second item. But when I click 2. It will equip it.
-- But in the UI for the player it looks like this 1, 2, 3 like last time.

-- When I have the Item equipped that is required from the screen UI ->
-- Then I will equip the thing, then for the NPC in the specific room%d i will `workspace.Rooms.Medical.Room%d.Minigame.Bed.InBed.PP` to give the item.
-- And it worked.

-- But when I gave the item to the NPC the items in my UI Slot changed from 1, 2, 3
-- `game:GetService("Players").LocalPlayer.Backpack.Herbs` is the first item. But when I click 1. It will equip it.
-- `game:GetService("Players").LocalPlayer.Backpack.Medkit` is the third item. But when I click 3. It will equip it.
-- `game:GetService("Players").LocalPlayer.Backpack.Thermo` is the second item. But when I click 2. It will equip it.

-- To 2, 3
-- `game:GetService("Players").LocalPlayer.Backpack.Medkit` is the third item. But when I click 3. It will equip it.
-- `game:GetService("Players").LocalPlayer.Backpack.Thermo` is the second item. But when I click 2. It will equip it.
-- It shows in UI for player it can chose to get 2 and 3 (two options from UI)

-- So it looks like when you use the item.. It will leave but not adjust the 1, 2 and 3 size if I trashed one item before. 

-- But I trashed the item like this:
-- `game:GetService("Players").LocalPlayer.Backpack.Herbs` is the first item. 
-- `game:GetService("Players").LocalPlayer.Backpack.Medkit` is the second item.
-- `game:GetService("Players").LocalPlayer.Backpack.Thermo` is the third item.
-- When I trashed the second item.. It became 1, 3 only one of two options to pick from..

-- I cant figure out how i will be able to know what item I am currently holding since it dosent use attributes at all.