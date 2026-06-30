--[[

to teleport to the win location - X: -3605.383 Y: 54.590 Z: -3007.488 with int slider.

--]]

--[[

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get the rebirth remote from ReplicatedStorage
local rebirthRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Rebirth")

-- Get the progress label (should contain "XX/YY")
local progressLabel = playerGui:WaitForChild("Main"):WaitForChild("UIs"):WaitForChild("Rebirth"):WaitForChild("Level"):WaitForChild("Progress")

-- Parse "XX/YY" (with optional spaces)
local function parseProgress(text)
    if not text or text == "" then return nil, nil end
    local current, required = text:match("(%d+)%s*/%s*(%d+)")
    if current and required then
        return tonumber(current), tonumber(required)
    end
    return nil, nil
end

while true do
    task.wait(1)  -- check every second

    if not progressLabel:IsA("TextLabel") and not progressLabel:IsA("TextButton") then
        warn("Progress is not a text object")
        continue
    end

    local currentLevel, requiredLevel = parseProgress(progressLabel.Text)
    if not currentLevel or not requiredLevel then
        warn("Could not parse progress text: " .. progressLabel.Text)
        continue
    end

    if currentLevel >= requiredLevel then
        print(string.format("Rebirth eligible! %d/%d – firing remote...", currentLevel, requiredLevel))
        -- Fire the remote. If it requires an argument, try:
        -- rebirthRemote:FireServer(1)   or
        -- rebirthRemote:FireServer(true)
        rebirthRemote:FireServer()  -- try with no arguments first
        task.wait(0.5)  -- avoid spamming
    end
end

--]]

return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- ===== STATE CONFIGURATION =====
    local winFarmActive = false
    local loopInterval = 1
    local autoRebirthActive = false

    -- ===== TARGET POSITION (Win Location) =====
    local TARGET_POS = Vector3.new(-3605.383, 54.590, -3007.488)

    -- Helper: teleport local player to the designated position
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- Helper: Parse "XX/YY" (with optional spaces)
    local function parseProgress(text)
        if not text or text == "" then return nil, nil end
        local current, required = text:match("(%d+)%s*/%s*(%d+)")
        if current and required then
            return tonumber(current), tonumber(required)
        end
        return nil, nil
    end

    -- Safe retrieval of the progress label path
    local function getProgressLabel()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        local uis = main and main:FindFirstChild("UIs")
        local rebirth = uis and uis:FindFirstChild("Rebirth")
        local level = rebirth and rebirth:FindFirstChild("Level")
        return level and level:FindFirstChild("Progress")
    end

    -- Safe retrieval of the Rebirth remote
    local function getRebirthRemote()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        return remotes and remotes:FindFirstChild("Rebirth")
    end

    -- Rebirth eligibility evaluation and remote firing
    local function checkAndRebirth()
        local progressLabel = getProgressLabel()
        if not progressLabel then return end

        if not (progressLabel:IsA("TextLabel") or progressLabel:IsA("TextButton")) then
            return
        end

        local currentLevel, requiredLevel = parseProgress(progressLabel.Text)
        if not currentLevel or not requiredLevel then
            return
        end

        if currentLevel >= requiredLevel then
            local rebirthRemote = getRebirthRemote()
            if rebirthRemote and rebirthRemote:IsA("RemoteEvent") then
                rebirthRemote:FireServer()
            end
        end
    end

    -- ===== UI ELEMENTS =====
    elements:Label("🔥 Automation Utilities", parent)

    -- Toggle for Auto Win Farm Loop
    elements:Toggle("Auto Win Farm", parent, false, function(state)
        winFarmActive = state
        if winFarmActive then
            task.spawn(function()
                while winFarmActive do
                    teleportTo(TARGET_POS)
                    task.wait(loopInterval)
                end
            end)
        end
    end)

    -- Integer Slider to control speed between teleports (decimals set to 0)
    elements:Slider("Win Teleport Delay (s)", parent, 1, 10, loopInterval, 0, function(val)
        loopInterval = val
    end)

    -- Toggle for Auto Rebirth Loop
    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        if autoRebirthActive then
            task.spawn(function()
                while autoRebirthActive do
                    pcall(checkAndRebirth)
                    task.wait(1.0) -- Checks once every second
                end
            end)
        end
    end)

    -- Clean up running loops on GUI destroy
    parent.Destroying:Connect(function()
        winFarmActive = false
        autoRebirthActive = false
    end)
end