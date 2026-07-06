-- 1. Enable Developer Mode
getgenv().TaperDev = true

-- 2. Load the TaperUI framework
local TaperUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/UI.lua"))()

-- 3. Create a custom Window
local Window = TaperUI:CreateWindow({
    Name = "One-Tap FPS Utility",
    LoadingTitle = "OneTap FPS",
    LoadingSubtitle = "Universal features",
    LoadingVersion = "v1.4",
    ProfileSubtitle = "by SkyDash"
})

-- 4. Create custom tabs
local SilentAimTab = Window:CreateTab("Aim & Combat", TaperAssets.eye)
local FreezeTab = Window:CreateTab("Bring & Freeze", TaperAssets.script)

-- ===================================================
--  CORE DATA & SETUP
-- ===================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

-- Global State Variables
local cameraLockActive = true -- Enabled by default to solve camera aimlock issue
local cameraSmoothness = 1.0   -- 1.0 = instant snap, lower = smoother lerping
local wallCheckActive = true
local autoShootActive = false
local showFovCircle = true
local fovRadius = 150
local targetPartName = "Head" -- "Head" or "HumanoidRootPart"
local autoShootCooldown = 0.1

local espEnabled = true
local autoBringActive = false
local bringDistance = 5
local cachedTargets = {}
local currentLockedTargetChar = nil -- Tracks current target to prevent visual jitter
local latestTarget = nil -- Decoupled hook cache to prevent hook lag and metatable recursion

-- Safely resolve local character root part
local function getMyRoot()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ===================================================
--  OPTIMIZED TARGET DETECTION (PLAYERS & BOTS)
-- ===================================================
local function updateTargetCache()
    local temp = {}
    -- Scan actual players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(temp, plr.Character)
            end
        end
    end
    
    -- Scan NPC bots in the workspace
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if hum and hum.Health > 0 and root then
                table.insert(temp, obj)
            end
        end
    end
    cachedTargets = temp
end

-- Periodically refresh the targets cache in the background to avoid performance drops
task.spawn(function()
    while true do
        pcall(updateTargetCache)
        task.wait(1.5)
    end
end)

-- Trace line-of-sight to check if target is hidden behind an object/wall
local function isTargetVisible(targetPart, targetCharacter)
    local origin = CurrentCamera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    -- If nil, nothing blocked the path between the camera and the target part
    return result == nil
end

-- Find the target closest to the center of your screen (with Sticky Target lock)
local function getClosestTargetToCenter()
    -- 1. Sticky Target validation (stick to target until dead or behind cover)
    if currentLockedTargetChar then
        local hum = currentLockedTargetChar:FindFirstChildOfClass("Humanoid")
        local part = currentLockedTargetChar:FindFirstChild(targetPartName)
        if hum and hum.Health > 0 and part then
            local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(part.Position)
            if onScreen then
                local viewportSize = CurrentCamera.ViewportSize
                local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if dist <= fovRadius then
                    if not wallCheckActive or isTargetVisible(part, currentLockedTargetChar) then
                        return part
                    end
                end
            end
        end
        currentLockedTargetChar = nil -- Reset target if invalid or out of view
    end

    -- 2. Find a new target if none is locked
    local closestTarget = nil
    local shortestDistance = math.huge
    local viewportSize = CurrentCamera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    for _, char in ipairs(cachedTargets) do
        local part = char:FindFirstChild(targetPartName)
        if part then
            -- Added real-time health check inside selection loop to prevent targeting dead entities
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local screenPos, onScreen = CurrentCamera:WorldToViewportPoint(part.Position)
                if onScreen then
                    if not wallCheckActive or isTargetVisible(part, char) then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist < shortestDistance and dist <= fovRadius then
                            shortestDistance = dist
                            closestTarget = part
                            currentLockedTargetChar = char
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- ===================================================
--  RED LIGHT GLOW & NAME ESP SYSTEM
-- ===================================================
local espData = {}

local function createESPForModel(model, displayName)
    if espData[model] then return end

    local container = Instance.new("Folder")
    container.Name = "ESP_Container"
    container.Parent = model

    -- Red Glow Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "Glow"
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0.1
    highlight.Enabled = true
    highlight.Parent = container

    -- 3D Name Tag Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.new(0, 160, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = true
    
    local adorneePart = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    billboard.Adornee = adorneePart
    billboard.Parent = container

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = displayName
    textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    textLabel.TextSize = 13
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.25
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboard

    espData[model] = {
        Container = container,
        Billboard = billboard
    }
end

local function clearAllESP()
    for model, data in pairs(espData) do
        pcall(function() data.Container:Destroy() end)
    end
    table.clear(espData)
end

local function updateESP()
    if not espEnabled then
        clearAllESP()
        return
    end

    -- Cleanup targets that died, left, or became invalid
    for model, data in pairs(espData) do
        if not model or not model.Parent then
            pcall(function() data.Container:Destroy() end)
            espData[model] = nil
        else
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                pcall(function() data.Container:Destroy() end)
                espData[model] = nil
            else
                local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
                if head then
                    data.Billboard.Adornee = head
                end
            end
        end
    end

    -- Construct visuals for all active tracked entities
    for _, char in ipairs(cachedTargets) do
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local isPlayer = Players:GetPlayerFromCharacter(char)
            local name = isPlayer and isPlayer.Name or char.Name
            createESPForModel(char, name)
        end
    end
end

-- ==========================================
--  AIM LOCK ENGINE & FOV UPDATE (RENDERSTEPPED)
-- ==========================================
local fovCircle = nil
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Visible = false
end

RunService.RenderStepped:Connect(function()
    latestTarget = getClosestTargetToCenter()
    
    -- Visual updater routine
    pcall(updateESP)

    -- 1. Apply Camera-based Aim Lock if enabled
    if cameraLockActive and latestTarget then
        local camPos = CurrentCamera.CFrame.Position
        local targetCFrame = CFrame.new(camPos, latestTarget.Position)
        if cameraSmoothness >= 1.0 then
            CurrentCamera.CFrame = targetCFrame
        else
            CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(targetCFrame, cameraSmoothness)
        end
    end

    -- 2. Manage FOV circle visual boundaries
    if fovCircle then
        local targetState = cameraLockActive
        fovCircle.Visible = targetState and showFovCircle
        if fovCircle.Visible then
            fovCircle.Position = CurrentCamera.ViewportSize / 2
            fovCircle.Radius = fovRadius
        end
    end
end)

-- ===================================================
--  AUTO SHOOT (TRIGGER BOT) LOOP
-- ===================================================
local lastShotTime = 0

task.spawn(function()
    while true do
        local targetState = cameraLockActive
        if targetState and autoShootActive then
            local target = latestTarget
            if target then
                local now = tick()
                if now - lastShotTime >= autoShootCooldown then
                    lastShotTime = now
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) -- Click down
                        task.wait(0.01)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) -- Click release
                    end)
                end
            end
        end
        task.wait(0.03) -- Scan check rate
    end
end)

-- ===================================================
--  BRING & FREEZE ENEMY POSITIONS
-- ===================================================
local function performFreezeAndBring()
    local myRoot = getMyRoot()
    if not myRoot then return end

    local targetCFrame = myRoot.CFrame * CFrame.new(0, 0, -bringDistance)

    for _, enemy in ipairs(cachedTargets) do
        pcall(function()
            for _, part in ipairs(enemy:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.Anchored = true
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end

            if enemy.PrimaryPart then
                enemy:SetPrimaryPartCFrame(targetCFrame)
            else
                local tRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
                if tRoot then
                    tRoot.CFrame = targetCFrame
                end
            end
        end)
    end
end

local function unfreezeAll()
    for _, enemy in ipairs(cachedTargets) do
        pcall(function()
            for _, part in ipairs(enemy:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = true
                end
            end
        end)
    end
end

task.spawn(function()
    while true do
        if autoBringActive then
            pcall(performFreezeAndBring)
        end
        task.wait(0.2)
    end
end)

-- ===================================================
--  AIM & COMBAT TAB CONTROLS
-- ===================================================
SilentAimTab:CreateLabel("🎯 Camera Lock (Universal Aimlock)")

SilentAimTab:CreateToggle("Enable Camera Lock", true, function(state)
    cameraLockActive = state
    if getgenv().showToast then
        getgenv().showToast("Aim Lock", state and "Aim Lock active." or "Aim Lock disabled.", TaperAssets.eye, 1.5)
    end
end)

SilentAimTab:CreateSlider("Aim Smoothness", 0.05, 1.0, 1.0, 2, function(value)
    cameraSmoothness = value
end)

SilentAimTab:CreateLabel("🔫 Automation (Auto Shoot)")

SilentAimTab:CreateToggle("Auto Shoot (Trigger Bot)", false, function(state)
    autoShootActive = state
end)

SilentAimTab:CreateSlider("Auto Shoot Delay (s)", 0.05, 1.0, 0.1, 2, function(value)
    autoShootCooldown = value
end)

SilentAimTab:CreateLabel("🛠️ Visuals & Extra Options")

SilentAimTab:CreateToggle("Red Glow & Name ESP", true, function(state)
    espEnabled = state
    if not state then
        clearAllESP()
    end
end)

SilentAimTab:CreateToggle("Wall Check (Visibility)", true, function(state)
    wallCheckActive = state
end)

SilentAimTab:CreateToggle("Show FOV Circle", true, function(state)
    showFovCircle = state
end)

SilentAimTab:CreateSlider("FOV Radius Size", 50, 4000, 150, 0, function(value)
    fovRadius = value
end)

SilentAimTab:CreateDropdown("Target Part Location", {"Head", "HumanoidRootPart"}, "Head", function(choice)
    targetPartName = choice
end)

-- ===================================================
--  BRING & FREEZE CONTROLS
-- ===================================================
FreezeTab:CreateLabel("🧊 Bring & Freeze Targets")

FreezeTab:CreateToggle("Auto Bring & Freeze Loop", false, function(state)
    autoBringActive = state
    if not state then
        unfreezeAll()
    end
end)

FreezeTab:CreateSlider("Bring Offset Distance", 2, 15, 5, 0, function(val)
    bringDistance = val
end)

FreezeTab:CreateDualButton(
    "Freeze & Bring", function()
        performFreezeAndBring()
    end,
    "Unfreeze All", function()
        unfreezeAll()
    end
)

FreezeTab:CreateSpacer(8)
FreezeTab:CreateParagraph(
    "Combat Guide",
    "• Camera Lock: Snaps your viewpoint directly to the target dynamically. Use this to automatically track visible targets within your customizable FOV circle.\n• Aim Smoothness: 1.0 represents instant target snapping; lower values make your looking movement look more organic.\n• Auto Shoot: Simulates rapid hardware clicks automatically whenever a target is successfully locked in your sights.\n• ESP visuals: Highlights all tracked target players with a bold red glow and names tags."
)

-- Clean up raw drawings and drawings lists if UI Screen is destroyed
Window.ScreenGui.Destroying:Connect(function()
    clearAllESP()
    if fovCircle then
        pcall(function() fovCircle:Remove() end)
    end
end)