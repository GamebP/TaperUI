--[=[
-- 110064275358409.lua
--[[

-- Get the best gun in the game

local Event = game:GetService("ReplicatedStorage").AddSkinEvent
Event:FireServer(
    "Gemini_Generated_Image_52v5nk52v5nk52v5-removebg-preview"
)

-- Get 5K cash

local Event = game:GetService("ReplicatedStorage").RewardFromRangeEvent
Event:FireServer(
    5000
)

--]]
-- Note that selling all items will not sell all it will take time beacuse game is fucking russian
--]=]

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
    local autoCashActive = false
    local cashInterval = 1.0

    local autoSkinActive = false
    local skinInterval = 1.0

    -- Helper: Fire Best Skin Remote
    local function claimBestSkin()
        local skinEvent = ReplicatedStorage:FindFirstChild("AddSkinEvent")
        if skinEvent and skinEvent:IsA("RemoteEvent") then
            skinEvent:FireServer("Gemini_Generated_Image_52v5nk52v5nk52v5-removebg-preview")
        else
            warn("[TaperUI] AddSkinEvent not found in ReplicatedStorage.")
        end
    end

    -- Helper: Fire Reward Remote
    local function claimCash(amount)
        local rewardEvent = ReplicatedStorage:FindFirstChild("RewardFromRangeEvent")
        if rewardEvent and rewardEvent:IsA("RemoteEvent") then
            rewardEvent:FireServer(amount)
        else
            warn("[TaperUI] RewardFromRangeEvent not found in ReplicatedStorage.")
        end
    end

    -- ===== UI ELEMENTS =====
    elements:Label("⚡ Skin Upgrader Utilities", parent)

    -- Static Instant Buttons
    elements:Button("Claim Best Skin (Once)", parent, function()
        claimBestSkin()
        if getgenv().showToast then
            getgenv().showToast("Best Skin", "Best skin added to inventory!", 2.0)
        end
    end)

    elements:Button("Claim 5K Cash (Once)", parent, function()
        claimCash(5000)
        if getgenv().showToast then
            getgenv().showToast("Cash Claimed", "Claimed 5,000 cash successfully.", 2.0)
        end
    end)

    elements:Label("🔄 Automation Loops", parent)

    -- Loop 1: Auto Cash Settings & Toggle
    elements:Slider("Cash Loop Speed (s)", parent, 0.1, 5.0, cashInterval, 1, function(val)
        cashInterval = val
    end)

    elements:Toggle("Auto Cash Farm (5K Loop)", parent, false, function(state)
        autoCashActive = state
        if autoCashActive then
            task.spawn(function()
                while autoCashActive do
                    claimCash(5000)
                    task.wait(cashInterval)
                end
            end)
        end
    end)

    -- Loop 2: Auto Skin Settings & Toggle
    elements:Slider("Skin Loop Speed (s)", parent, 0.1, 5.0, skinInterval, 1, function(val)
        skinInterval = val
    end)

    elements:Toggle("Auto Skin Farm (Loop)", parent, false, function(state)
        autoSkinActive = state
        if autoSkinActive then
            task.spawn(function()
                while autoSkinActive do
                    claimBestSkin()
                    task.wait(skinInterval)
                end
            end)
        end
    end)

    -- Cleanup connection on GUI destroy
    parent.Destroying:Connect(function()
        autoCashActive = false
        autoSkinActive = false
    end)
end