return function(parent, config)
    -- 1. Import TaperUI's elements helper module cleanly [1]
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    -- 3. Declare global variables for auto-farm loops [1]
    getgenv().AutoCollectCoins = false

    -- ─── CATEGORY 1: PLAYER MODIFICATIONS ───
    elements:Label("👑 Player Modifications", parent)

    -- Custom WalkSpeed Input
    elements:Textbox("Set WalkSpeed", parent, "16", function(text)
        local numericValue = tonumber(text) -- Validate that input is a number [1]
        if numericValue then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = numericValue
            end
        end
    end)

    -- Custom JumpPower Input
    elements:Textbox("Set JumpPower", parent, "50", function(text)
        local numericValue = tonumber(text)
        if numericValue then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.UseJumpPower = true
                character.Humanoid.JumpPower = numericValue
            end
        end
    end)

    -- ─── CATEGORY 2: FARMING UTILITIES ───
    elements:Label("🔥 Automation Utilities", parent)

    -- Toggle for loop-based Auto Farming [1]
    elements:Toggle("Auto Collect Coins", parent, false, function(state)
        getgenv().AutoCollectCoins = state
        
        if getgenv().AutoCollectCoins then
            -- Spawns a background thread so the loop doesn't freeze Roblox [1]
            task.spawn(function()
                while getgenv().AutoCollectCoins do
                    -- Example: Firing a coin collection remote event
                    local collectRemote = ReplicatedStorage:FindFirstChild("CollectCoin") or ReplicatedStorage:FindFirstChild("AddCoins")
                    if collectRemote and collectRemote:IsA("RemoteEvent") then
                        collectRemote:FireServer()
                    end
                    task.wait(0.2) -- Loop delay
                end
            end)
        end
    end)

    -- Button for an instant action
    elements:Button("Instant Rebirth", parent, function()
        local rebirthRemote = ReplicatedStorage:FindFirstChild("Rebirth") or ReplicatedStorage:FindFirstChild("ClaimRebirth")
        if rebirthRemote and rebirthRemote:IsA("RemoteEvent") then
            rebirthRemote:FireServer()
        end
    end)

    -- ─── CATEGORY 3: HOTKEY BINDS ───
    elements:Label("⌨️ Hotkey Binds", parent)

    -- Custom Keybind Card
    elements:Keybind("Teleport Home Hotkey", parent, "H", function(keyName)
        print("Selected hotkey changed to: " .. tostring(keyName))
    end)
end