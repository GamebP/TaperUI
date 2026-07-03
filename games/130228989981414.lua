return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store service and network references
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local Network = ReplicatedStorage:WaitForChild("Network", 5)
    if not Network then
        warn("[TaperUI Error] 'Network' folder not found in ReplicatedStorage after 5s. Core loops may fail.")
    end

    -- ===== STATE CONFIGURATION =====
    -- Cash (Throw) Settings
    local autoThrowActive = false
    local throwInterval = 1.0
    local throwPowerValue = 3439345.1

    -- Strength Settings
    local autoStrengthActive = false
    local strengthInterval = 0.1
    local selectedWall = "Wall1"
    local wallOptions = {
        "Wall1", "Wall2", "Wall3", "Wall4", "Wall5", "Wall6",
        "Wall7", "Wall8", "Wall9", "Wall10", "Wall11", "Wall12"
    }

    -- Egg Open Settings
    local autoEggActive = false
    local eggInterval = 1.0
    local selectedEgg = "Egg1"
    local selectedEggAmount = 1
    local eggOptions = {"Egg1", "Egg2", "Egg3", "Egg4", "Egg5", "Egg6"}
    local eggAmounts = {"1", "3"}

    -- Rebirth Settings
    local autoRebirthActive = false
    local rebirthInterval = 2.0

    -- ===== AUTOMATION HELPER FUNCTIONS =====
    local function fireThrowSequence()
        if not Network then 
            warn("[TaperUI Warning] Throw sequence cancelled: 'Network' folder is missing.")
            return 
        end
        
        local beginEvent = Network:FindFirstChild("Throw/Begin")
        local updateEvent = Network:FindFirstChild("Throw/Update")
        local endEvent = Network:FindFirstChild("Throw/End")

        if not beginEvent then warn("[TaperUI Warning] Missing 'Throw/Begin' RemoteFunction!") end
        if not updateEvent then warn("[TaperUI Warning] Missing 'Throw/Update' RemoteEvent!") end
        if not endEvent then warn("[TaperUI Warning] Missing 'Throw/End' RemoteEvent!") end

        local success, err = pcall(function()
            if beginEvent and beginEvent:IsA("RemoteFunction") then
                beginEvent:InvokeServer()
            end
            task.wait(0.5)

            if updateEvent and updateEvent:IsA("RemoteEvent") then
                updateEvent:FireServer(throwPowerValue)
            end
            task.wait(0.5)

            if endEvent and endEvent:IsA("RemoteEvent") then
                endEvent:FireServer()
            end
        end)

        if not success then
            warn("[TaperUI Error] Firing throw sequence failed: " .. tostring(err))
        end
    end

    -- ===== UI ELEMENTS =====
    elements:Label("💵 Cash (Throw) Utilities", parent)

    elements:Textbox("Throw Power Value", parent, tostring(throwPowerValue), function(text)
        local customPower = tonumber(text)
        if customPower then
            throwPowerValue = customPower
        else
            warn("[Invalid] Please enter a valid number for throw power.")
        end
    end)

    elements:Slider("Throw Delay (s)", parent, 0.01, 5.0, throwInterval, 2, function(val)
        throwInterval = val
    end)

    elements:Toggle("Auto Throw Friend", parent, false, function(state)
        autoThrowActive = state
        if autoThrowActive then
            task.spawn(function()
                while autoThrowActive do
                    task.spawn(fireThrowSequence)
                    task.wait(throwInterval)
                end
            end)
        end
    end)

    elements:Label("💪 Strength Utilities", parent)

    elements:Dropdown("Select Training Wall", parent, wallOptions, selectedWall, function(value)
        selectedWall = value
    end)

    elements:Slider("Training Rate (s)", parent, 0.01, 5.0, strengthInterval, 2, function(val)
        strengthInterval = val
    end)

    elements:Toggle("Auto Train Strength", parent, false, function(state)
        autoStrengthActive = state
        if autoStrengthActive then
            task.spawn(function()
                while autoStrengthActive do
                    task.spawn(function()
                        if not Network then
                            warn("[TaperUI Warning] Training sequence aborted: 'Network' folder is missing.")
                            return
                        end

                        local trainEvent = Network:FindFirstChild("Training/Throw")
                        if trainEvent and trainEvent:IsA("RemoteEvent") then
                            local success, err = pcall(function()
                                trainEvent:FireServer(selectedWall, false)
                            end)
                            if not success then
                                warn("[TaperUI Error] Training request failed: " .. tostring(err))
                            end
                        else
                            warn("[TaperUI Warning] Missing or invalid 'Training/Throw' RemoteEvent!")
                        end
                    end)
                    task.wait(strengthInterval)
                end
            end)
        end
    end)

    elements:Label("🥚 Egg & Pet Utilities", parent)

    elements:Button("Equip Best Pets", parent, function()
        if not Network then
            warn("[TaperUI Warning] Cannot equip pets: 'Network' folder is missing.")
            return
        end

        local equipEvent = Network:FindFirstChild("Pets/EquipBest")
        if equipEvent and equipEvent:IsA("RemoteEvent") then
            local success, err = pcall(function() equipEvent:FireServer() end)
            if success then
                if getgenv().showToast then
                    getgenv().showToast("Pets Upgraded", "Best pets equipped!", 2.0)
                end
            else
                warn("[TaperUI Error] Failed to equip best pets: " .. tostring(err))
            end
        else
            warn("[TaperUI Warning] Missing 'Pets/EquipBest' RemoteEvent!")
        end
    end)

    elements:Dropdown("Select Egg", parent, eggOptions, selectedEgg, function(value)
        selectedEgg = value
    end)

    elements:Dropdown("Hatch Quantity", parent, eggAmounts, tostring(selectedEggAmount), function(value)
        selectedEggAmount = tonumber(value) or 1
    end)

    elements:Slider("Hatch Delay (s)", parent, 0.5, 5.0, eggInterval, 1, function(val)
        eggInterval = val
    end)

    elements:Toggle("Auto Open Eggs", parent, false, function(state)
        autoEggActive = state
        if autoEggActive then
            task.spawn(function()
                while autoEggActive do
                    if not Network then
                        warn("[TaperUI Warning] Egg opening halted: 'Network' folder is missing.")
                        task.wait(2.0) -- Extended wait to prevent spamming warnings
                        continue
                    end

                    local openEvent = Network:FindFirstChild("Egg/Open")
                    if openEvent and openEvent:IsA("RemoteFunction") then
                        local success, err = pcall(function()
                            openEvent:InvokeServer(selectedEgg, selectedEggAmount)
                        end)
                        if not success then
                            warn("[TaperUI Error] Failed to complete egg opening: " .. tostring(err))
                        end
                    else
                        warn("[TaperUI Warning] Missing 'Egg/Open' RemoteFunction!")
                        task.wait(2.0)
                        continue
                    end
                    task.wait(eggInterval)
                end
            end)
        end
    end)

    elements:Label("👑 Rebirth Utilities", parent)

    elements:Slider("Rebirth Loop Rate (s)", parent, 1.0, 10.0, rebirthInterval, 1, function(val)
        rebirthInterval = val
    end)

    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        if autoRebirthActive then
            task.spawn(function()
                while autoRebirthActive do
                    if not Network then
                        warn("[TaperUI Warning] Rebirth loop halted: 'Network' folder is missing.")
                        task.wait(2.0)
                        continue
                    end

                    local rebirthEvent = Network:FindFirstChild("Rebirth/Upgrade")
                    if rebirthEvent and rebirthEvent:IsA("RemoteFunction") then
                        local success, err = pcall(function()
                            rebirthEvent:InvokeServer()
                        end)
                        if not success then
                            warn("[TaperUI Error] Failed to complete rebirth request: " .. tostring(err))
                        end
                    else
                        warn("[TaperUI Warning] Missing 'Rebirth/Upgrade' RemoteFunction!")
                        task.wait(2.0)
                        continue
                    end
                    task.wait(rebirthInterval)
                end
            end)
        end
    end)

    -- Cleanup active threads when UI is destroyed
    parent.Destroying:Connect(function()
        autoThrowActive = false
        autoStrengthActive = false
        autoEggActive = false
        autoRebirthActive = false
    end)
end