-- ============================================================
--  TAPERUI - STANDALONE GAME SCRIPT
--  Verdant Autofarm (AFK Real-Time Timer Edition)
-- ============================================================

-- 1. Enable Developer Mode to bypass the automatic multi-game hub loader
getgenv().TaperDev = true

-- 2. Load the TaperUI framework library
local TaperUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/UI.lua"))()

-- 3. Create a Custom Window and Tab
local Window = TaperUI:CreateWindow({
    Name = "Verdant",
    LoadingTitle = "Verdant Auto-Farm",
    LoadingSubtitle = "Just watering plants",
    LoadingVersion = "v2.8",
    ProfileSubtitle = "Elite Farmer"
})

local FarmTab = Window:CreateTab("Autofarm", TaperAssets.list)
Window:CreateSettingsTab()

-- Global runtime variables
getgenv().AutoFarm_ENV = false
getgenv().FarmDelay_ENV = 0.2
getgenv().AutoBuySkillTree = false
getgenv().AntiAFK_ENV = false
getgenv().InstantPrompts = false
getgenv().AutoClearTokens = false -- Controls the automatic clearing behavior
getgenv().TokenLimit_ENV = 300     -- Dynamic auto-delete limit (Defaults to 300)
getgenv().AFKTriggerCount = getgenv().AFKTriggerCount or 0
getgenv().AFKLastTrigger = getgenv().AFKLastTrigger or "N/A"
getgenv().AFKStatusText = getgenv().AFKStatusText or "Inactive"
getgenv().AFK_IdleTime = 0
getgenv().BoughtNodesCache = getgenv().BoughtNodesCache or {}

local checkpointDropdownInitialized = false -- Guard to prevent injection teleport
local promptAddedConnection = nil
local originalHoldDurations = {} -- Cache to store original prompt holding durations

-- Remotes & Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("VerdantRemotes", 5)
local EventGetWat = remotes and remotes:WaitForChild("VDT_Bucket.Used", 5)
local doAfter = remotes and remotes:WaitForChild("VDT_Bucket.Poured", 5)
local takeToken = remotes and remotes:WaitForChild("VDT_Tokens.Take", 5)
local openChest = remotes and remotes:WaitForChild("VDT_Chest.Open", 5)
local SkillTreeBuyThing = remotes and remotes:WaitForChild("VDT_SkillTree.Purchase", 5)

-- ============================================================
--  HUD WATERMARK INITIALIZATION (Anti-AFK Monitor)
-- ============================================================
local ScreenGui = nil
local StatsLabel = nil

local function createWatermark()
    -- Safe UI Parent selection (Hides GUI from standard detections when possible)
    local parentGui = nil
    pcall(function()
        parentGui = (getgenv().gethui and getgenv().gethui()) or game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
    end)
    if not parentGui then return end

    -- Destroy old watermark if script is re-run
    local oldGui = parentGui:FindFirstChild("VerdantAFKWatermark")
    if oldGui then oldGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VerdantAFKWatermark"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = parentGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 240, 0, 100) -- Expanded to accommodate the User State line
    Frame.Position = UDim2.new(1, -250, 0, 15) -- Placed in top-right corner
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true -- Allows user dragging
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(50, 50, 50)
    UIStroke.Thickness = 1
    UIStroke.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 25)
    Title.Position = UDim2.new(0, 10, 0, 4)
    Title.Text = "🌾 Verdant AFK Monitor"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold -- Clean bold header
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Parent = Frame

    StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(1, -20, 0, 65)
    StatsLabel.Position = UDim2.new(0, 10, 0, 28)
    StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatsLabel.TextSize = 13
    StatsLabel.Font = Enum.Font.GothamMedium -- Clean body font
    StatsLabel.RichText = true -- Enable HTML style tags for optimized readability
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
    StatsLabel.LineHeight = 1.2
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Parent = Frame
end

local function updateWatermark()
    if StatsLabel then
        local statusColor = "rgb(150, 150, 150)" -- Default gray
        if getgenv().AFKStatusText == "PREVENTING KICK!" then
            statusColor = "rgb(255, 180, 0)" -- Gold during trigger event
        elseif getgenv().AFKStatusText == "Monitoring..." then
            statusColor = "rgb(0, 220, 100)" -- Green when active
        end
        
        -- Resolve active user state dynamically using the idle timer
        local idleSecs = getgenv().AFK_IdleTime or 0
        local stateText = "Active"
        local stateColor = "rgb(0, 220, 100)" -- Green
        
        if idleSecs > 5 then
            stateText = "Away"
            stateColor = "rgb(255, 100, 100)" -- Red
        end
        
        -- Formatted rich text output
        StatsLabel.Text = string.format(
            "<b>Status:</b> <font color='%s'>%s</font>\n<b>User State:</b> <font color='%s'>%s (%ds)</font>\n<b>Triggers:</b> <font color='rgb(255, 255, 255)'>%d</font>\n<b>Last Prevented:</b> <font color='rgb(255, 255, 255)'>%s</font>",
            statusColor,
            getgenv().AFKStatusText,
            stateColor,
            stateText,
            idleSecs,
            getgenv().AFKTriggerCount,
            getgenv().AFKLastTrigger
        )
    end
end

createWatermark()

-- ============================================================
--  VERDANT GAME LOGIC HELPERS
-- ============================================================

-- Helper to safely get current bucket progress percentage
local function getBucketPercentage()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return 0 end

    local success, progressObj = pcall(function()
        return localPlayer.PlayerGui.Interface.Holder.BucketFill.Bar.Progress
    end)

    if success and progressObj then
        local text = ""
        pcall(function()
            text = progressObj.Text or tostring(progressObj)
        end)

        -- Extracts only the digits (e.g. "100% Full" -> 100)
        local num = tonumber(text:match("(%d+)"))
        return num or 0
    end

    return 0
end

-- Helper to dynamically locate all ProximityPrompts under workspace.Scripted
local function getSpecificPrompts()
    local prompts = {}
    local scriptedFolder = workspace:FindFirstChild("Scripted")
    if not scriptedFolder then return prompts end

    pcall(function()
        for _, desc in ipairs(scriptedFolder:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                table.insert(prompts, desc)
            end
        end
    end)

    return prompts
end

-- Helper to read custom values (supporting Roblox Attributes or nested ValueObjects)
local function getNodeValue(node, name)
    if not node then return nil end

    -- 1. Try native Roblox Attribute
    local attribute = node:GetAttribute(name)
    if attribute ~= nil then return attribute end

    -- 2. Fallback to searching for child ValueObjects (StringValue, IntValue, etc.)
    local child = node:FindFirstChild(name)
    if child and (child:IsA("ValueObject") or child.ClassName:find("Value")) then
        return child.Value
    end

    return nil
end

-- Helper to determine the active folder in the skill tree based on Icon asset IDs
local function getCurrentSkillFolder(nodesFolder)
    if not nodesFolder then return nil end

    for _, node in ipairs(nodesFolder:GetChildren()) do
        local icon = node:FindFirstChild("Icon")
        if icon and icon:IsA("ImageLabel") then
            -- Safely extract only digits from the Image string
            local imageId = tostring(icon.Image):match("(%d+)")
            if imageId == "140096718972182" then
                return "diamonds"
            elseif imageId == "135566735435367" then
                return "root"
            elseif imageId == "126997578929005" then
                return "buckets"
            elseif imageId == "88188299453143" then
                return "character"
            end
        end
    end
    return nil
end

-- Helper to parse costs with decimals and abbreviated suffixes (e.g., 50.5M, 10K, 1B)
local function parseFormattedCost(text)
    text = tostring(text):upper():gsub(",", "")
    local numberStr, suffix = text:match("([%d%.]+)([KMBT]?)")
    if not numberStr then return 0 end

    local val = tonumber(numberStr) or 0
    if suffix == "K" then
        val = val * 1000
    elseif suffix == "M" then
        val = val * 1000000
    elseif suffix == "B" then
        val = val * 1000000000
    elseif suffix == "T" then
        val = val * 1000000000000
    end
    return math.floor(val)
end

-- Helper to safely check and purchase eligible skill tree nodes
local function runAutoBuySkills()
    local player = Players.LocalPlayer
    if not player then return end

    -- Verify current Token balance
    local tokensObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Tokens")
    local currentTokens = tokensObj and tokensObj.Value or 0

    -- Navigate skill tree elements safely
    local success, nodesFolder = pcall(function()
        return player.PlayerGui.Interface.Holder.SkillTree.Main.Nodes
    end)

    if not success or not nodesFolder then return end

    -- Detect active category folder
    local activeFolder = getCurrentSkillFolder(nodesFolder)
    if not activeFolder then return end

    for _, node in ipairs(nodesFolder:GetChildren()) do
        if node.Name:match("^Hex_") then
            -- Fetch Node configuration using double detection (Attribute vs ValueObject)
            local kind = getNodeValue(node, "Kind")
            local q = getNodeValue(node, "Q")
            local r = getNodeValue(node, "R")

            -- Parsing fallback strictly from Node Name (e.g. Hex_0_-1) if Q or R are missing
            if not q or not r then
                local parsedQ, parsedR = node.Name:match("^Hex_([%-]?%d+)_([%-]?%d+)")
                q = q or tonumber(parsedQ)
                r = r or tonumber(parsedR)
            end

            -- Validate Node filters (Kind must be "node", Q and R must not equal 0)
            if kind and tostring(kind):lower() == "node" and q and r and (q ~= 0 or r ~= 0) then
                local key = activeFolder .. "_" .. tostring(q) .. "_" .. tostring(r)
                
                -- Check if this specific node has already been purchased/recorded in session cache
                if not getgenv().BoughtNodesCache[key] then
                    local cost = 0
                    local costFrame = node:FindFirstChild("CostFrame")
                    
                    if costFrame then
                        -- Check for a text label inside CostFrame
                        local label = costFrame:FindFirstChild("Label") or costFrame:FindFirstChildWhichIsA("TextLabel")
                        if label then
                            local rawText = label.ContentText or label.Text or "0"
                            cost = parseFormattedCost(rawText)
                        end
                    end

                    -- Purchase if affordable
                    if cost > 0 and currentTokens >= cost then
                        if SkillTreeBuyThing then
                            local purchaseSuccess = pcall(function()
                                -- Safely decide between RemoteFunction (InvokeServer) or RemoteEvent (FireServer)
                                if SkillTreeBuyThing:IsA("RemoteFunction") then
                                    SkillTreeBuyThing:InvokeServer(activeFolder, q, r)
                                else
                                    SkillTreeBuyThing:FireServer(activeFolder, q, r)
                                end
                            end)

                            if purchaseSuccess then
                                getgenv().BoughtNodesCache[key] = true
                                currentTokens = currentTokens - cost -- Adjust tracking balance locally
                                task.wait(0.1) -- Small yield to prevent frame spikes
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Helper to make a ProximityPrompt instant
local function makePromptInstant(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        -- Store the original hold duration in case the user toggles the feature off
        if not originalHoldDurations[prompt] then
            originalHoldDurations[prompt] = prompt.HoldDuration
        end
        prompt.HoldDuration = 0
    end)
end

-- Helper to restore a ProximityPrompt to its original duration
local function restorePromptDuration(prompt)
    if not prompt then return end
    pcall(function()
        if originalHoldDurations[prompt] then
            prompt.HoldDuration = originalHoldDurations[prompt]
            originalHoldDurations[prompt] = nil
        end
    end)
end

-- ============================================================
--  TAB POPULATION
-- ============================================================

FarmTab:CreateLabel("🌾 Verdant Auto-Farm")

FarmTab:CreateParagraph(
    "💡 Dynamic Resolution System", 
    "This script dynamically resolves interactive targets within the 'Scripted' workspace. It loops and uses the nearest valid targets to process the pour step without getting stuck on loading variations."
)

FarmTab:CreateToggle("Enable Autofarm", false, function(state)
    getgenv().AutoFarm_ENV = state
    
    if state then
        task.spawn(function()
            while getgenv().AutoFarm_ENV do
                local percentage = getBucketPercentage()
                
                if percentage >= 100 then
                    local targetPrompts = getSpecificPrompts()
                    
                    if #targetPrompts > 0 then
                        for _, prompt in ipairs(targetPrompts) do
                            -- Double check if we still have water before trying this location
                            if getBucketPercentage() < 100 then
                                break -- Successfully emptied, go back to collecting water
                            end

                            -- Execute actions on the current prompt
                            pcall(function()
                                if takeToken then
                                    takeToken:FireServer(prompt)
                                end
                                if doAfter then
                                    doAfter:FireServer(prompt)
                                end
                            end)

                            -- Wait a split-second to allow server replication
                            task.wait(0.05)
                        end
                    end
                else
                    -- Use bucket to collect water
                    if EventGetWat then
                        pcall(function()
                            EventGetWat:FireServer()
                        end)
                    end
                end
                
                task.wait(getgenv().AutoFarm_ENV and getgenv().FarmDelay_ENV or 0.2)
            end
        end)
    end
end)

FarmTab:CreateSlider("Action Cooldown (s)", 0.05, 1.0, 0.2, 2, function(val)
    getgenv().FarmDelay_ENV = val
end)

FarmTab:CreateLabel("🚀 Teleportation")

FarmTab:CreateDropdown("Teleport to Checkpoint", {"1", "2", "3", "4", "5", "6", "7", "8"}, "1", function(choice)
    -- Block execution on initial UI load to prevent unwanted injection teleport
    if not checkpointDropdownInitialized then
        checkpointDropdownInitialized = true
        return
    end

    local checkPoints = workspace:FindFirstChild("Scripted") and workspace.Scripted:FindFirstChild("Checkpoints")
    if checkPoints then
        local cp = checkPoints:FindFirstChild(choice)
        if cp then
            local character = Players.LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                pcall(function()
                    -- Safely resolve checkpoint target CFrame (Part, Model, or Pivot)
                    local targetCFrame = cp:IsA("BasePart") and cp.CFrame 
                        or cp:GetPivot() 
                        or (cp.PrimaryPart and cp.PrimaryPart.CFrame)
                    if targetCFrame then
                        rootPart.CFrame = targetCFrame
                    end
                end)
            end
        end
    end
end)

FarmTab:CreateSpacer(5)

FarmTab:CreateLabel("🛠 Automation & Utilities")

FarmTab:CreateToggle("Auto Buy Skills", false, function(state)
    getgenv().AutoBuySkillTree = state
    
    if state then
        task.spawn(function()
            while getgenv().AutoBuySkillTree do
                pcall(runAutoBuySkills)
                task.wait(1.5) -- Cool down delay between loops to prevent rate limits
            end
        end)
    end
end)

-- Instant Proximity Prompts Sliding Toggle Switch
FarmTab:CreateToggle("Instant Proximity Prompts", false, function(state)
    getgenv().InstantPrompts = state
    
    if state then
        -- 1. Apply to all currently existing prompts in the game
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                makePromptInstant(desc)
            end
        end
        
        -- 2. Watch for new prompts that spawn dynamically
        if not promptAddedConnection then
            promptAddedConnection = workspace.DescendantAdded:Connect(function(desc)
                if getgenv().InstantPrompts and desc:IsA("ProximityPrompt") then
                    makePromptInstant(desc)
                end
            end)
        end
    else
        -- Disconnect listener
        if promptAddedConnection then
            promptAddedConnection:Disconnect()
            promptAddedConnection = nil
        end
        
        -- Restore original hold durations
        for prompt, _ in pairs(originalHoldDurations) do
            restorePromptDuration(prompt)
        end
    end
end)

-- Anti-AFK Sliding Toggle Switch with HUD Monitor integration
FarmTab:CreateToggle("Anti-AFK System", false, function(state)
    getgenv().AntiAFK_ENV = state
    
    if ScreenGui then
        ScreenGui.Enabled = state
    end
    
    if state then
        getgenv().AFKStatusText = "Monitoring..."
        getgenv().AFK_IdleTime = 0
        updateWatermark()

        -- Set up the passive connection if it hasn't been instantiated yet
        if not getgenv().IdledConnection then
            local vu = game:GetService("VirtualUser")
            getgenv().IdledConnection = Players.LocalPlayer.Idled:Connect(function()
                if getgenv().AntiAFK_ENV then
                    pcall(function()
                        -- Update state indicators on trigger
                        getgenv().AFKTriggerCount = getgenv().AFKTriggerCount + 1
                        getgenv().AFKLastTrigger = os.date("%X")
                        getgenv().AFKStatusText = "PREVENTING KICK!"
                        updateWatermark()

                        -- Simulates viewport interaction to reset the 20-minute idle disconnect timer
                        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        task.wait(1)
                        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        
                        task.wait(1)
                        if getgenv().AntiAFK_ENV then
                            getgenv().AFKStatusText = "Monitoring..."
                            updateWatermark()
                        end
                    end)
                end
            end)
        end

        -- Background loop tracking real-time idle status using UserInputService
        task.spawn(function()
            local UIS = game:GetService("UserInputService")
            while getgenv().AntiAFK_ENV do
                pcall(function()
                    getgenv().AFK_IdleTime = math.floor(UIS:GetIdleTime())
                    updateWatermark()
                end)
                task.wait(1)
            end
        end)
    else
        getgenv().AFKStatusText = "Inactive"
        getgenv().AFK_IdleTime = 0
        updateWatermark()
    end
end)

-- Button to trigger the phone prompt instantly with teleportation and bypass checks
FarmTab:CreateButton("Use Phone (Instantly)", function()
    local phoneFolder = workspace:FindFirstChild("Phone")
    local handle = phoneFolder and phoneFolder:FindFirstChild("PhoneHandle")
    local prompt = handle and handle:FindFirstChild("ProximityPrompt")

    if prompt and handle then
        -- 1. Cache the original position
        local originalCFrame = nil
        local character = Players.LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if rootPart then
            originalCFrame = rootPart.CFrame
            -- 2. Teleport directly next to the phone to pass server-side distance checks
            pcall(function()
                rootPart.CFrame = handle.CFrame + Vector3.new(0, 3, 0)
            end)
            task.wait(0.25) -- Wait briefly for physics & replication update
        end

        -- 3. Bypass prompt restriction properties locally
        pcall(function()
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 999999
        end)

        -- 4. Execute prompt interaction
        if fireproximityprompt then
            pcall(function()
                fireproximityprompt(prompt)
            end)
        else
            -- Fallback hold inputs if fireproximityprompt isn't available
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end)
        end

        task.wait(0.1)

        -- 5. Teleport back to starting coordinates
        if originalCFrame and rootPart then
            pcall(function()
                rootPart.CFrame = originalCFrame
            end)
        end
    else
        warn("Phone ProximityPrompt or PhoneHandle was not found.")
    end
end)

-- Button to automatically teleport, open chests, and return to original position
FarmTab:CreateButton("Open All Chests", function()
    local chestsFolder = workspace:FindFirstChild("Scripted") and workspace.Scripted:FindFirstChild("Chests")
    if not chestsFolder then
        warn("Chests folder was not found under workspace.Scripted.")
        return
    end

    if not openChest then
        warn("VDT_Chest.Open remote is missing.")
        return
    end

    -- Cache the original position before moving
    local originalCFrame = nil
    local character = Players.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        originalCFrame = rootPart.CFrame
    end

    local openedCount = 0
    -- Loop through all children inside Chests
    for _, chest in ipairs(chestsFolder:GetChildren()) do
        local part = chest:FindFirstChild("Part")
        if part then
            -- Teleport slightly above the target chest
            pcall(function()
                if rootPart then
                    rootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                end
            end)

            -- Wait for physics & server position replication to update
            task.wait(0.25)

            -- Open the chest
            pcall(function()
                openChest:FireServer(part)
                openedCount = openedCount + 1
            end)

            task.wait(0.05)
        end
    end

    -- Teleport back to the original cached position
    if originalCFrame and rootPart then
        pcall(function()
            rootPart.CFrame = originalCFrame
        end)
    end

    warn("Opened " .. tostring(openedCount) .. " chest(s) and returned to original location.")
end)

-- Toggle switch to enable and disable the auto token remover
FarmTab:CreateToggle("Auto-Clear Client-Side Tokens", false, function(state)
    getgenv().AutoClearTokens = state
end)

-- Slider to set custom token trigger count (Defaults to 300)
FarmTab:CreateSlider("Auto-Clear Token Limit", 50, 1500, 300, 0, function(val)
    getgenv().TokenLimit_ENV = val
end)

-- Button to clear all instances with Name/ClassName "Token" locally for FPS optimization
FarmTab:CreateButton("Delete Client-Side Tokens (FPS)", function()
    local count = 0
    
    -- Recursively checks the entire workspace for any instance representing a "Token"
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc.Name == "Token" or desc.ClassName == "Token" then
            pcall(function()
                desc:Destroy()
                count = count + 1
            end)
        end
    end
    
    warn("Destroyed " .. tostring(count) .. " client-side token instances for optimized performance.")
end)

FarmTab:CreateSpacer(15)

-- ============================================================
-- Background Task: Monitor and Auto-Clear Client-Side Tokens
-- ============================================================
task.spawn(function()
    while true do
        task.wait(5) -- Scan every 5 seconds to minimize performance overhead
        
        -- Only execute the counting/cleanup loop if the toggle is activated
        if getgenv().AutoClearTokens then
            pcall(function()
                local foundTokens = {}
                
                -- Check the entire workspace for matching Token instances
                for _, desc in ipairs(workspace:GetDescendants()) do
                    if desc.Name == "Token" or desc.ClassName == "Token" then
                        table.insert(foundTokens, desc)
                    end
                end
                
                -- Read dynamic threshold set from the slider (falls back to 300)
                local currentLimit = getgenv().TokenLimit_ENV or 300
                
                -- If current count meets or exceeds the selected limit, trigger auto-clear
                if #foundTokens >= currentLimit then
                    local destroyedCount = 0
                    for _, token in ipairs(foundTokens) do
                        pcall(function()
                            if token and token.Parent then
                                token:Destroy()
                                destroyedCount = destroyedCount + 1
                            end
                        end)
                    end
                    warn("[Auto-FPS] Automatically cleared " .. tostring(destroyedCount) .. " client-side tokens (Threshold of " .. tostring(currentLimit) .. " met).")
                end
            end)
        end
    end
end)