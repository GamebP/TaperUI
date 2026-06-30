return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- State
    local winFarmActive = false
    local loopInterval = 2.5

    -- Win location (provided by user)
    local TARGET_POS = Vector3.new(11471.80, -29.28, -233.62)

    -- Teleport helper
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- UI
    elements:Label("🔥 Automation Utilities", parent)

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

    elements:Textbox("Teleport Interval (s)", parent, tostring(loopInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            loopInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number.")
        end
    end)

    -- Optional debug button to teleport once
    elements:Button("Teleport Once", parent, function()
        teleportTo(TARGET_POS)
        print("Teleported to " .. tostring(TARGET_POS))
    end)

    print("[TaperUI] +1 Speed Dragon Escape loaded. Win at: " .. tostring(TARGET_POS))
end