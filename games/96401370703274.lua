-- =============================================
--  Custom UI Hub (TaperUI)
-- =============================================

-- Enable Developer Mode
getgenv().TaperDev = true

-- Load TaperUI
local TaperUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/UI.lua"))()

-- Create the main window
local Window = TaperUI:CreateWindow({
    Name = "Ghost Hub v1.0",
    LoadingTitle = "Ghost Hub Premium",
    LoadingSubtitle = "Created by Ghost",
    LoadingVersion = "v1.0.4 - Alpha",
    ProfileSubtitle = "Elite Subscriber"
})

-- Create tabs
local MainTab = Window:CreateTab("Main", TaperAssets.eye)
local SpeedTab = Window:CreateTab("Speed", TaperAssets.script)
local InfoTab = Window:CreateTab("Info", TaperAssets.list)

-- Add settings tab (optional)
Window:CreateSettingsTab()

-- =============================================
--  HELPERS
-- =============================================
local function getChar()
    local plr = game.Players.LocalPlayer
    return plr and plr.Character
end

local function teleportTo(position)
    local char = getChar()
    if char then
        local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        if root then
            root.CFrame = CFrame.new(position)
            print("Teleported to:", position)
        else
            warn("No primary part or HumanoidRootPart found to teleport")
        end
    else
        warn("Character not found")
    end
end

-- =============================================
--  WALK SPEED FORCER
-- =============================================
local targetSpeed = 50
local speedEnabled = true

local function applySpeed(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and speedEnabled then
        hum.WalkSpeed = targetSpeed
    end
end

game.Players.LocalPlayer.CharacterAdded:Connect(applySpeed)

game:GetService("RunService").Heartbeat:Connect(function()
    if not speedEnabled then return end
    local char = getChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= targetSpeed then
            hum.WalkSpeed = targetSpeed
        end
    end
end)

-- =============================================
--  MAIN TAB
-- =============================================
MainTab:CreateLabel("📍 Navigation")

MainTab:CreateButton("Teleport Up", function()
    teleportTo(Vector3.new(-475, 10018, 47))
end)

MainTab:CreateButton("Teleport Back Down", function()
    -- Teleport to position
    teleportTo(Vector3.new(-473, 17, 8))
    
    -- Small delay to ensure position registration prior to resetting health
    task.wait(0.1)
    
    -- Set character health to 0 to trigger respawn mechanics
    local char = getChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        end
    end
end)

MainTab:CreateSpacer(10)
MainTab:CreateLabel("💰 Actions")

MainTab:CreateButton("Request Sell", function()
    local success, err = pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local packages = rep:FindFirstChild("Packages")
        local knit = packages and packages:FindFirstChild("Knit")
        local services = knit and knit:FindFirstChild("Services")
        local luckyBlock = services and services:FindFirstChild("LuckyBlockService")
        local re = luckyBlock and luckyBlock:FindFirstChild("RE")
        local remote = re and re:FindFirstChild("remote")

        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer({
                kind = "requestSell"
            })
            print("✅ FireServer sent: requestSell")
        else
            warn("❌ LuckyBlockService remote not found in ReplicatedStorage")
        end
    end)
    if not success then
        warn("Execution error: " .. tostring(err))
    end
end)

-- =============================================
--  SPEED TAB
-- =============================================
SpeedTab:CreateLabel("🏃 Walk Speed Forcer")

SpeedTab:CreateSlider("Walk Speed", 16, 1000, targetSpeed, 1, function(value)
    targetSpeed = value
    local char = getChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end
end)

SpeedTab:CreateToggle("Enable Speed Forcer", true, function(state)
    speedEnabled = state
end)

SpeedTab:CreateSpacer(10)
SpeedTab:CreateButton("Reset Speed to 16", function()
    targetSpeed = 16
    local char = getChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

-- =============================================
--  INFO TAB
-- =============================================
InfoTab:CreateParagraph("📘 About This Script",
    "Utility automation panel containing custom teleport locations, sell actions, and speed configurations."
)

InfoTab:CreateSpacer(10)
InfoTab:CreateButton("Uninject Script", function()
    Window:Destroy()
end)

print("✅ UI loaded with requested modifications.")