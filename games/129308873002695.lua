return function(parent, config)
    -- 1. Import TaperUI's elements helper module cleanly
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    -- 3. Declare global variables for auto-farm loops
    getgenv().AutoCollectCoins = false

    -- ─── CATEGORY 1: PLAYER MODIFICATIONS ───
    elements:Label("👑 Player Modifications", parent)

    -- Custom WalkSpeed Slider (Min: 16, Max: 250, Default: 16, Decimals: 0)
    elements:Slider("Set WalkSpeed", parent, 16, 250, 16, 0, function(value)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = value
        end
    end)

    -- Custom JumpPower Slider (Min: 50, Max: 350, Default: 50, Decimals: 0)
    elements:Slider("Set JumpPower", parent, 50, 350, 50, 0, function(value)
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.UseJumpPower = true
            character.Humanoid.JumpPower = value
        end
    end)

    -- ─── CATEGORY 2: FARMING UTILITIES ───
    elements:Label("🔥 Automation Utilities", parent)

    -- Toggle for loop-based Auto Farming
    elements:Toggle("Auto Collect Coins", parent, false, function(state)
        getgenv().AutoCollectCoins = state
        
        if getgenv().AutoCollectCoins then
            -- Spawns a background thread so the loop doesn't freeze Roblox
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
    local showToast = getgenv().showToast or function() end
    elements:Keybind("Teleport Home Hotkey", parent, "H", function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            -- Teleports the player to coordinates (adjust if needed)
            character.HumanoidRootPart.CFrame = CFrame.new(0, 100, 0) 
            showToast("Teleported", "Teleported back Home!", 1.5)
        else
            showToast("Error", "Character model is not loaded.", 2)
        end
    end)
end