return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- Localized State Configuration
    local touchFarmActive = false
    local loopInterval = 2.5

    -- Constants specific to Place 83569851223739
    local TARGET_POS = Vector3.new(7981, 213, 480)

    -- Helper: teleport local player to the designated position
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    elements:Label("🔥 Automation Utilities", parent)

    -- Toggle for Touch Farm Loop
    elements:Toggle("Touch Farm Toggle", parent, false, function(state)
        touchFarmActive = state
        
        if touchFarmActive then
            task.spawn(function()
                while touchFarmActive do
                    teleportTo(TARGET_POS)
                    task.wait(loopInterval)
                end
            end)
        end
    end)
end