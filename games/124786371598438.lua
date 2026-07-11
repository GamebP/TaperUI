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
getgenv().FarmDelay_ENV = 0.05   -- Default to 0.05 (fastest)
getgenv().AutoBuySkillTree = false
getgenv().AntiAFK_ENV = false
getgenv().InstantPrompts = false
getgenv().AutoClearTokens = false 
getgenv().TokenLimit_ENV = 300     
getgenv().AFKTriggerCount = getgenv().AFKTriggerCount or 0
getgenv().AFKLastTrigger = getgenv().AFKLastTrigger or "N/A"
getgenv().AFKStatusText = getgenv().AFKStatusText or "Inactive"
getgenv().AFK_IdleTime = 0
getgenv().BoughtNodesCache = getgenv().BoughtNodesCache or {}

local checkpointDropdownInitialized = false 
local promptAddedConnection = nil
local originalHoldDurations = {} 

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
    local parentGui = nil
    pcall(function()
        parentGui = (getgenv().gethui and getgenv().gethui()) or game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
    end)
    if not parentGui then return end

    local oldGui = parentGui:FindFirstChild("VerdantAFKWatermark")
    if oldGui then oldGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VerdantAFKWatermark"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = parentGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 240, 0, 100) 
    Frame.Position = UDim2.new(1, -250, 0, 15) 
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true 
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
    Title.Font = Enum.Font.GothamBold 
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Parent = Frame

    StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(1, -20, 0, 65)
    StatsLabel.Position = UDim2.new(0, 10, 0, 28)
    StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatsLabel.TextSize = 13
    StatsLabel.Font = Enum.Font.GothamMedium 
    StatsLabel.RichText = true 
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
    StatsLabel.LineHeight = 1.2
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Parent = Frame
end

local function updateWatermark()
    if StatsLabel then
        local statusColor = "rgb(150, 150, 150)" 
        if getgenv().AFKStatusText == "PREVENTING KICK!" then
            statusColor = "rgb(255, 180, 0)" 
        elseif getgenv().AFKStatusText == "Monitoring..." then
            statusColor = "rgb(0, 220, 100)" 
        end
        
        local idleSecs = getgenv().AFK_IdleTime or 0
        local stateText = "Active"
        local stateColor = "rgb(0, 220, 100)" 
        
        if idleSecs > 5 then
            stateText = "Away"
            stateColor = "rgb(255, 100, 100)" 
        end
        
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

        local num = tonumber(text:match("(%d+)"))
        return num or 0
    end

    return 0
end

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

local function getNodeValue(node, name)
    if not node then return nil end

    local attribute = node:GetAttribute(name)
    if attribute ~= nil then return attribute end

    local child = node:FindFirstChild(name)
    if child and (child:IsA("ValueObject") or child.ClassName:find("Value")) then
        return child.Value
    end

    return nil
end

local function getCurrentSkillFolder(nodesFolder)
    if not nodesFolder then return nil end

    for _, node in ipairs(nodesFolder:GetChildren()) do
        local icon = node:FindFirstChild("Icon")
        if icon and icon:IsA("ImageLabel") then
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

local function runAutoBuySkills()
    local player = Players.LocalPlayer
    if not player then return end

    local tokensObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Tokens")
    local currentTokens = tokensObj and tokensObj.Value or 0

    local success, nodesFolder = pcall(function()
        return player.PlayerGui.Interface.Holder.SkillTree.Main.Nodes
    end)

    if not success or not nodesFolder then return end

    local activeFolder = getCurrentSkillFolder(nodesFolder)
    if not activeFolder then return end

    for _, node in ipairs(nodesFolder:GetChildren()) do
        if node.Name:match("^Hex_") then
            local kind = getNodeValue(node, "Kind")
            local q = getNodeValue(node, "Q")
            local r = getNodeValue(node, "R")

            if not q or not r then
                local parsedQ, parsedR = node.Name:match("^Hex_([%-]?%d+)_([%-]?%d+)")
                q = q or tonumber(parsedQ)
                r = r or tonumber(parsedR)
            end

            if kind and tostring(kind):lower() == "node" and q and r and (q ~= 0 or r ~= 0) then
                local key = activeFolder .. "_" .. tostring(q) .. "_" .. tostring(r)
                
                if not getgenv().BoughtNodesCache[key] then
                    local cost = 0
                    local costFrame = node:FindFirstChild("CostFrame")
                    
                    if costFrame then
                        local label = costFrame:FindFirstChild("Label") or costFrame:FindFirstChildWhichIsA("TextLabel")
                        if label then
                            local rawText = label.ContentText or label.Text or "0"
                            cost = parseFormattedCost(rawText)
                        end
                    end

                    if cost > 0 and currentTokens >= cost then
                        if SkillTreeBuyThing then
                            local purchaseSuccess = pcall(function()
                                if SkillTreeBuyThing:IsA("RemoteFunction") then
                                    SkillTreeBuyThing:InvokeServer(activeFolder, q, r)
                                else
                                    SkillTreeBuyThing:FireServer(activeFolder, q, r)
                                end
                            end)

                            if purchaseSuccess then
                                getgenv().BoughtNodesCache[key] = true
                                currentTokens = currentTokens - cost 
                                task.wait(0.1) 
                            end
                        end
                    end
                end
            end
        end
    end
end

local function makePromptInstant(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        if not originalHoldDurations[prompt] then
            originalHoldDurations[prompt] = prompt.HoldDuration
        end
        prompt.HoldDuration = 0
    end)
end

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

-- ============================================================
--  AUTO FARM – FASTEST POSSIBLE (0.05s per event)
-- ============================================================
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
                            if getBucketPercentage() < 100 then
                                break 
                            end

                            pcall(function()
                                if takeToken then
                                    takeToken:FireServer(prompt)
                                end
                                if doAfter then
                                    doAfter:FireServer(prompt)
                                end
                            end)

                            -- Wait exactly the configured cooldown (default 0.05)
                            task.wait(getgenv().FarmDelay_ENV)
                        end
                    end
                else
                    -- FILL: No rate limit – fires every loop iteration
                    if EventGetWat then
                        pcall(function()
                            EventGetWat:FireServer()
                        end)
                    end
                end
                
                -- Global loop delay (also uses FarmDelay_ENV)
                task.wait(getgenv().FarmDelay_ENV)
            end
        end)
    end
end)

-- Slider: now defaults to 0.05 and goes as low as 0.02 (for even more aggression)
FarmTab:CreateSlider("Action Cooldown (s)", 0.02, 1.0, 0.05, 2, function(val)
    getgenv().FarmDelay_ENV = val
end)

FarmTab:CreateLabel("🚀 Teleportation")

FarmTab:CreateDropdown("Teleport to Checkpoint", {"1", "2", "3", "4", "5", "6", "7"}, "1", function(choice)
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
                task.wait(1.5) 
            end
        end)
    end
end)

FarmTab:CreateToggle("Instant Proximity Prompts", false, function(state)
    getgenv().InstantPrompts = state
    
    if state then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                makePromptInstant(desc)
            end
        end
        
        if not promptAddedConnection then
            promptAddedConnection = workspace.DescendantAdded:Connect(function(desc)
                if getgenv().InstantPrompts and desc:IsA("ProximityPrompt") then
                    makePromptInstant(desc)
                end
            end)
        end
    else
        if promptAddedConnection then
            promptAddedConnection:Disconnect()
            promptAddedConnection = nil
        end
        
        for prompt, _ in pairs(originalHoldDurations) do
            restorePromptDuration(prompt)
        end
    end
end)

FarmTab:CreateToggle("Anti-AFK System", false, function(state)
    getgenv().AntiAFK_ENV = state
    
    if ScreenGui then
        ScreenGui.Enabled = state
    end
    
    if state then
        getgenv().AFKStatusText = "Monitoring..."
        getgenv().AFK_IdleTime = 0
        updateWatermark()

        if not getgenv().IdledConnection then
            local vu = game:GetService("VirtualUser")
            getgenv().IdledConnection = Players.LocalPlayer.Idled:Connect(function()
                if getgenv().AntiAFK_ENV then
                    pcall(function()
                        getgenv().AFKTriggerCount = getgenv().AFKTriggerCount + 1
                        getgenv().AFKLastTrigger = os.date("%X")
                        getgenv().AFKStatusText = "PREVENTING KICK!"
                        updateWatermark()

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

FarmTab:CreateButton("Use Phone (Instantly)", function()
    local phoneFolder = workspace:FindFirstChild("Phone")
    local handle = phoneFolder and phoneFolder:FindFirstChild("PhoneHandle")
    local prompt = handle and handle:FindFirstChild("ProximityPrompt")

    if prompt and handle then
        local originalCFrame = nil
        local character = Players.LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if rootPart then
            originalCFrame = rootPart.CFrame
            pcall(function()
                rootPart.CFrame = handle.CFrame + Vector3.new(0, 3, 0)
            end)
            task.wait(0.25) 
        end

        pcall(function()
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 999999
        end)

        if fireproximityprompt then
            pcall(function()
                fireproximityprompt(prompt)
            end)
        else
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end)
        end

        task.wait(0.1)

        if originalCFrame and rootPart then
            pcall(function()
                rootPart.CFrame = originalCFrame
            end)
        end
    else
        warn("Phone ProximityPrompt or PhoneHandle was not found.")
    end
end)

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

    local originalCFrame = nil
    local character = Players.LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        originalCFrame = rootPart.CFrame
    end

    local openedCount = 0
    for _, chest in ipairs(chestsFolder:GetChildren()) do
        local part = chest:FindFirstChild("Part")
        if part then
            pcall(function()
                if rootPart then
                    rootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                end
            end)

            task.wait(0.25)

            pcall(function()
                openChest:FireServer(part)
                openedCount = openedCount + 1
            end)

            task.wait(0.05)
        end
    end

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

-- WIDE-SPECTRUM DELETE SCANNER (Full Workspace scan with safety pauses)
local function clearTokensLocally()
    local count = 0
    local itemsChecked = 0
    
    -- Scan the entire workspace to ensure drops outside 'Scripted' are caught
    for _, desc in ipairs(workspace:GetDescendants()) do
        itemsChecked = itemsChecked + 1
        
        -- Yield every 250 items to keep framerate completely smooth
        if itemsChecked % 250 == 0 then
            task.wait()
        end
        
        local nameLower = desc.Name:lower()
        local classLower = desc.ClassName:lower()
        
        -- Matches 'Token', 'Cash', 'Money', 'Gold', or 'Bill'
        if nameLower:find("token") or nameLower:find("cash") or nameLower:find("money") or nameLower:find("gold") or nameLower:find("bill") or classLower == "token" then
            pcall(function()
                desc:Destroy()
                count = count + 1
            end)
            
            -- Yield briefly during fast destructions to prevent micro-stuttering
            if count % 20 == 0 then
                task.wait()
            end
        end
    end
    return count
end

FarmTab:CreateButton("Delete Client-Side Tokens (FPS)", function()
    local count = clearTokensLocally()
    warn("Destroyed " .. tostring(count) .. " client-side token/cash instances for optimized performance.")
end)

FarmTab:CreateSpacer(15)

-- ============================================================
-- Background Task: Monitor and Auto-Clear Client-Side Tokens
-- ============================================================
task.spawn(function()
    while true do
        task.wait(5) 
        
        if getgenv().AutoClearTokens then
            pcall(function()
                local foundTokens = {}
                local itemsChecked = 0
                
                -- Dynamic scanning across the entire workspace
                for _, desc in ipairs(workspace:GetDescendants()) do
                    itemsChecked = itemsChecked + 1
                    if itemsChecked % 300 == 0 then
                        task.wait() 
                    end
                    
                    local nameLower = desc.Name:lower()
                    local classLower = desc.ClassName:lower()
                    if nameLower:find("token") or nameLower:find("cash") or nameLower:find("money") or nameLower:find("gold") or nameLower:find("bill") or classLower == "token" then
                        table.insert(foundTokens, desc)
                    end
                end
                
                local currentLimit = getgenv().TokenLimit_ENV or 300
                
                if #foundTokens >= currentLimit then
                    local destroyedCount = 0
                    for _, token in ipairs(foundTokens) do
                        pcall(function()
                            if token and token.Parent then
                                token:Destroy()
                                destroyedCount = destroyedCount + 1
                            end
                        end)
                        if destroyedCount % 20 == 0 then
                            task.wait()
                        end
                    end
                    warn("[Auto-FPS] Automatically cleared " .. tostring(destroyedCount) .. " client-side drops.")
                end
            end)
        end
    end
end)