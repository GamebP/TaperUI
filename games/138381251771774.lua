-- 138381251771774.lua

-- Search non taken portal

-- You will need to find Group named "Portal" in `workspace` and in each of it's children 
-- there will be a `workspace:GetChildren()[%d].Billboard` located inside it.
-- And sinide the Billboard -> Container -> Time -> TimeLabel:ContextText
-- Once you read the text, if it's "Waiting...", then you know that portal is not taken.
-- If the text is "Setting Up" or "%d" - counting down.. then it will be taken.
-- But when it's "Waiting..." - then it's not taken.

-- So as it's not taken, you will need to Find the Portal child 
-- And then inside Portal -> Touch -> And fire the `TouchInterest` event

-- When you are inside the portal,
-- You will need to fire the event named
-- local createLobby = game:GetService("ReplicatedStorage").VerdantRemotes["VDT_Portal.CreateSetup"]
-- createLobby:FireServer(
--     {
--         Difficulty = "Easy", -- Can be "Easy", "Medium", "Hard"
--         MaxPlayers = 1 -- 1, 2, 3, 4
--     }
-- )

-- 1. Enable Developer Mode to bypass the automatic multi-game hub loader
getgenv().TaperDev = true

-- 2. Load the TaperUI framework library
local TaperUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/UI.lua"))()

-- 3. Create a Custom Window
local Window = TaperUI:CreateWindow({
    Name = "Auto TP",
    LoadingTitle = "Drain the Lake",
    LoadingSubtitle = "Auto Join Portal",
    LoadingVersion = "v1.0.2",
    ProfileSubtitle = "Elite Farmer"
})

-- 4. Dynamically create custom tabs
local FarmTab = Window:CreateTab("Portal Farm", TaperAssets.list)

-- 5. Auto-inject the standard TaperUI settings tab (Toggle UI key, uninject button, 3D rendering, rejoin)
Window:CreateSettingsTab()

-- ============================================================
--  CORE DATA & SETUP
-- ============================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Network references
local VerdantRemotes = ReplicatedStorage:WaitForChild("VerdantRemotes", 5)
local createLobby = VerdantRemotes and VerdantRemotes:WaitForChild("VDT_Portal.CreateSetup", 5)

-- State Configuration
local autoPortalActive = false
local selectedDifficulty = "Easy"
local selectedMaxPlayers = 1
local loopCooldown = 3.0

-- ============================================================
--  UTILITY FUNCTIONS (NESTED HIERARCHY RESOLUTION)
-- ============================================================

-- Scans the workspace dynamically to find all valid portal models, even if nested
local function getAllPortals()
    local portals = {}
    
    -- Recursively search the entire workspace for models named "Portal"
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc.Name == "Portal" and desc:FindFirstChild("Billboard") then
            table.insert(portals, desc)
        end
    end
    
    -- Ensure we also evaluate the top-level workspace.Portal itself if it matches
    local topPortal = workspace:FindFirstChild("Portal") or workspace:FindFirstChild("Portals")
    if topPortal and topPortal:FindFirstChild("Billboard") then
        local exists = false
        for _, p in ipairs(portals) do
            if p == topPortal then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(portals, topPortal)
        end
    end
    
    return portals
end

-- Safely resolves the exact path: Billboard -> Container -> Time -> TimeLabel
local function getPortalTimeText(portal)
    local billboard = portal:FindFirstChild("Billboard")
    local container = billboard and billboard:FindFirstChild("Container")
    local timeFrame = container and container:FindFirstChild("Time")
    local timeLabel = timeFrame and timeFrame:FindFirstChild("TimeLabel")
    
    if timeLabel and timeLabel:IsA("TextLabel") then
        return timeLabel.ContentText or timeLabel.Text
    end
    return nil
end

-- Evaluates each found portal to see if it is open ("Waiting...")
local function findOpenPortal()
    local portals = getAllPortals()
    for _, portal in ipairs(portals) do
        local text = getPortalTimeText(portal)
        if text and text:find("Waiting") then
            return portal
        end
    end
    return nil
end

-- Process entry by firing TouchInterest or using direct physics replication
local function touchPortal(touchPart)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and touchPart then
        if firetouchinterest then
            firetouchinterest(touchPart, root, 0)
            task.wait(0.05)
            firetouchinterest(touchPart, root, 1)
        else
            -- Fallback: Safely offset character positioning onto the physical touch trigger
            local originalCFrame = root.CFrame
            root.CFrame = touchPart.CFrame
            task.wait(0.2)
            root.CFrame = originalCFrame
        end
    end
end

-- ============================================================
--  AUTOMATION BACKGROUND LOOP
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1.0)
        if autoPortalActive then
            local openPortal = findOpenPortal()
            if openPortal then
                local touchPart = openPortal:FindFirstChild("Touch")
                if touchPart then
                    print("[Portal Farm] Open Portal identified: " .. openPortal:GetFullName())
                    
                    -- Step 1: Touch / Teleport to portal
                    touchPortal(touchPart)
                    task.wait(0.5)
                    
                    -- Step 2: Fire Server setup payload
                    if createLobby then
                        pcall(function()
                            createLobby:FireServer({
                                Difficulty = selectedDifficulty,
                                MaxPlayers = tonumber(selectedMaxPlayers) or 1
                            })
                        end)
                        print("[Portal Farm] Lobby initialization sent. Difficulty: " .. selectedDifficulty .. " | Max Players: " .. tostring(selectedMaxPlayers))
                    else
                        warn("[Portal Farm] Remote event 'VDT_Portal.CreateSetup' is missing.")
                    end
                    
                    task.wait(loopCooldown)
                else
                    warn("[Portal Farm] Portal touch trigger part is missing in " .. openPortal.Name)
                end
            end
        end
    end
end)

-- ============================================================
--  UI CONTROLS & INTERFACE BINDINGS
-- ============================================================

FarmTab:CreateLabel("🌌 Auto-Portal Integration")

FarmTab:CreateToggle("Auto Enter & Setup Portal", false, function(state)
    autoPortalActive = state
end)

FarmTab:CreateSelector("Lobby Difficulty", {"Easy", "Medium", "Hard"}, "Easy", function(mode)
    selectedDifficulty = mode
end)

FarmTab:CreateSelector("Max Players", {"1", "2", "3", "4"}, "1", function(choice)
    selectedMaxPlayers = tonumber(choice) or 1
end)

FarmTab:CreateSlider("Scan Delay (s)", 1, 10, 3, 0, function(value)
    loopCooldown = value
end)

FarmTab:CreateSpacer(12)

FarmTab:CreateLabel("🛠️ Manual Configurations")

FarmTab:CreateButton("Find & Touch Open Portal Once", function()
    local openPortal = findOpenPortal()
    if openPortal then
        local touchPart = openPortal:FindFirstChild("Touch")
        if touchPart then
            touchPortal(touchPart)
            print("[Manual Action] Successfully touched portal: " .. openPortal:GetFullName())
        else
            warn("[Manual Action] Found open portal but touch part was missing.")
        end
    else
        warn("[Manual Action] No open portals currently available.")
    end
end)

FarmTab:CreateButton("Force Lobby Event Setup", function()
    if createLobby then
        pcall(function()
            createLobby:FireServer({
                Difficulty = selectedDifficulty,
                MaxPlayers = tonumber(selectedMaxPlayers) or 1
            })
        end)
        print("[Manual Action] Sent lobby setup to server.")
    else
        warn("[Manual Action] Remote connection unavailable.")
    end
end)

-- Clean up automation on UI destruction
Window.ScreenGui.Destroying:Connect(function()
    autoPortalActive = false
end)