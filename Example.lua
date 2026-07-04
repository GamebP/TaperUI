-- example.lua

-- 1. Enable Developer Mode to bypass the automatic multi-game hub loader
getgenv().TaperUI_DeveloperMode = true

-- 2. Load the TaperUI framework library
local TaperUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/UI.lua"))()

-- 3. Create a Custom Window
-- Customize your sidebar title, loading intro titles, version text, and profile subtitle here!
local Window = TaperUI:CreateWindow({
    Name = "Ghost Hub v1.0",              -- Sidebar main title
    LoadingTitle = "Ghost Hub Premium",   -- Large title shown during the intro loading screen
    LoadingSubtitle = "Created by Ghost", -- Small description subtitle shown during intro
    LoadingVersion = "v1.0.4 - Alpha",    -- Version status shown during the intro loading screen
    ProfileSubtitle = "Elite Subscriber"  -- Subtitle text shown underneath your username in the profile widget
})

-- 4. Dynamically create your custom tabs
-- Assign any icon from TaperAssets (e.g., eye, list, settings, home, script, user, unlock, Done, error)
local CombatTab = Window:CreateTab("Combat", TaperAssets.eye)
local FarmTab = Window:CreateTab("Autofarm", TaperAssets.list)
local UtilityTab = Window:CreateTab("Utilities", TaperAssets.script)

-- 5. Auto-inject the standard TaperUI settings tab (Toggle UI key, uninject button, 3D rendering, rejoin)
Window:CreateSettingsTab()


-- ===================================================
-- COMBAT TAB CONTROLS (Toggles, Sliders, Keybinds, Selectors)
-- ===================================================
CombatTab:CreateLabel("🎯 Aim Assistance Options")

CombatTab:CreateToggle("Enable Silent Aim", false, function(state)
    print("Silent Aim toggled: ", state)
end)

CombatTab:CreateSlider("Aimbot Field of View", 10, 180, 75, 0, function(value)
    print("FOV updated to: ", value)
end)

CombatTab:CreateKeybind("Silent Aim Keybind", "V", function(keyName)
    print("Silent Aim keybind changed to: ", keyName)
end)

CombatTab:CreateLabel("🔫 Combat Automation")

CombatTab:CreateSelector("Trigger Mode", {"Hold", "Toggle"}, "Hold", function(mode)
    print("Trigger mode selected: ", mode)
end)


-- ===================================================
-- AUTOFARM TAB CONTROLS (Paragraphs, Textboxes, DualButtons)
-- ===================================================
FarmTab:CreateParagraph("🚜 Universal Autofarm Rules", "Keep your travel transmit delay above 0.15s on high-security executors to prevent unexpected client rate-limits or bans.")

FarmTab:CreateTextbox("Farming Travel Delay (s)", "1.5", function(text)
    local delayVal = tonumber(text)
    if delayVal then
        print("Travel delay updated: ", delayVal)
    else
        warn("Please enter a valid positive number.")
    end
end)

FarmTab:CreateSpacer(12)

FarmTab:CreateDualButton(
    "Start Farm", function() print("Autofarm sequence started!") end,
    "Stop Farm", function() print("Autofarm sequence halted.") end
)


-- ===================================================
-- UTILITIES TAB CONTROLS (Buttons, Dropdowns)
-- ===================================================
UtilityTab:CreateLabel("🛠️ Diagnostics & Travel")

UtilityTab:CreateButton("Speed Hack (Boost WalkSpeed)", function()
    local char = game:GetService("Players").LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 100
    end
end)

UtilityTab:CreateDropdown("Fast Travel Destination", {"World 1", "World 2", "World 3", "World 4"}, "World 1", function(choice)
    print("Teleport coordinate selected: ", choice)
end)


-- 6. Trigger the play intro sequence to reveal the customized UI cleanly
Window:PlayIntro()