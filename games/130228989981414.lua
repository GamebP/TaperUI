--[[
    -- World 1: 

    -- Walls:

    -- Wall1 = +3 Strength
    -- Wall2 = +6 Strength (350 Required Strength or 1 Rebirth)
    -- Wall3 = +8 Strength (1,500 Required Strength or 2 Rebirths)
    -- Wall4 = +12 Strength (4,000 Required Strength or 3 Rebirths)
    -- Wall5 = +15 Strength (15,000 Required Strength or 4 Rebirths)
    -- Wall6 = +20 Strength (40,000 Required Strength or 5 Rebirths)
    -- Wall7 = +25 Strength (100,000 Required Strength or 6 Rebirths)
    -- Wall8 = +30 Strength (300,000 Required Strength or 7 Rebirths)
    -- Wall9 = +35 Strength (500,000 Required Strength or 8 Rebirths)
    -- Wall10 = +45 Strength (850,000 Required Strength or 9 Rebirths)
    -- Wall11 = +60 Strength (1,500,000 Required Strength or 10 Rebirths)
    -- Wall12 = +85 Strength (3,000,000 Required Strength or 11 Rebirths)

    -- Eggs:

    -- Egg1 = 50 Cash
    -- Egg2 = 2.7K Cash
    -- Egg3 = 250K Cash

    -- Shop:

    --[[
    Example:

    local Event = game:GetService("ReplicatedStorage").Network["ItemShop/Purchase"]
    Event:InvokeServer(
        "Balloon"
    )

    And:

    local Event = game:GetService("ReplicatedStorage").Network["ItemShop/Equip"]
    Event:InvokeServer(
        "Paper Airplane"
    )

    --]]

    "Paper Airplane", "Balloon", "Kite",
    -- Paper Airplane:
    -- Balloon: 1K Cash
    -- Kite: 2.5K Cash
    "Umbrella", "Fan", "Leaf Blower",
    -- Umbrella: 6K Cash
    -- Fan: 20K Cash
    -- Leaf Blower: 80K Cash
    "Hang Glider", "WindTurbine", "Parachute",
    -- Hang Glider: 350K Cash
    -- Wind Turbine: 1M Cash
    -- Parachute: 1.5M Cash
    "Firework", "Triple Balloon", "Blimp",
    -- Firework: 2.2M Cash
    -- Triple Balloon: 3.5M Cash
    -- Blimp: 5M Cash
    "Hot Air Balloon", "Airplane Turbine", "Jetpack",
    -- Hot Air Balloon: 8.5M Cash
    -- Airplane Turbine: 15M Cash
    -- Jetpack: 30M Cash
    "Rocket"
    -- Rocket: 50M Cash


    --[[

    local Event = game:GetService("ReplicatedStorage").Network["Pets/Delete"]
    Event:FireServer(
        {
            "{2433e8d1-a936-4ed2-9a9a-8b635406d238}",
            "{740f8cf4-31ac-4681-be7d-91463eeb6d2c}",
            "{edebcce7-7dd4-4241-8b88-124feb6918ba}"
        }
    )
    
    --]]

    --[[
    
    Add a function to delete pets lower from Common:
        `game:GetService("Players").LocalPlayer.PlayerGui.PetsInventory.Holder.main.Petcontent["{e659d0b8-b18e-43d5-9bbd-22acf5e87a5d}"].main.UIGradient` You need to check if the UIGradiant matches the `0 0.317647 1 0 0 1 0.0745098 0.745098 0.00392157 0`
         -- {e659d0b8-b18e-43d5-9bbd-22acf5e87a5d} Can be anything random please use scripts to check it...
         
        `0 0.317647 1 0 0 1 0.0745098 0.745098 0.00392157 0` = Common
        `0 0 0.662745 0.996078 0 1 0.0823529 0.419608 0.733333 0` = Rare
        `0 0.984314 0.207843 0.92549 0 1 0.682353 0.32549 0.996078 0` = Epic
        `0 0.960784 0.976471 0.403922 0 1 1 0.8 0 0` = Legendary
    --]]

--]]

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
    local VirtualUser = game:GetService("VirtualUser")
    
    local Network = ReplicatedStorage:WaitForChild("Network", 5)
    if not Network then
        warn("[TaperUI Error] 'Network' folder not found in ReplicatedStorage after 5s. Core loops may fail.")
    end

    -- ===== STATE CONFIGURATION =====
    -- Cash (Throw) Settings
    local autoThrowActive = false
    local throwInterval = 1.0
    local throwPowerValue = 9e200 -- Hardcoded throw power to bypass standard calculation

    -- Strength Settings
    local autoStrengthActive = false
    local strengthInterval = 0.1
    local selectedWall = "Wall1"

    local wallOptions = {
        "Wall1", "Wall2", "Wall3", "Wall4", "Wall5", "Wall6",
        "Wall7", "Wall8", "Wall9", "Wall10", "Wall11", "Wall12"
    }

    -- Shop Settings
    local selectedShopItem = "Paper Airplane"
    local autoBuyEquipActive = false
    local shopItems = {
        "Paper Airplane", "Balloon", "Kite", "Umbrella", "Fan", "Leaf Blower",
        "Hang Glider", "WindTurbine", "Parachute", "Firework", "Triple Balloon",
        "Blimp", "Hot Air Balloon", "Airplane Turbine", "Jetpack", "Rocket"
    }

    -- Egg Open Settings
    local autoEggActive = false
    local eggInterval = 1.0
    local selectedEgg = "Egg1"
    local selectedEggAmount = 1
    local eggOptions = {"Egg1", "Egg2", "Egg3"} -- World 1 Eggs
    local eggAmounts = {"1", "3"}

    -- Pet Deletion Settings
    local autoDeleteActive = false
    local deleteInterval = 1.0
    local deleteRarities = {
        Common = false,
        Rare = false,
        Epic = false,
        Legendary = false
    }

    -- Rebirth Settings
    local autoRebirthActive = false
    local rebirthInterval = 2.0

    -- ===== ANTI-AFK INITIALIZATION =====
    -- Captures and handles idle state to prevent standard 20-minute disconnects
    local idledConnection = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)

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

    -- Robust UIGradient matching logic using color-proximity (epsilon check)
    local function colorsMatch(c1, c2)
        local epsilon = 0.01
        return math.abs(c1.R - c2.R) < epsilon 
           and math.abs(c1.G - c2.G) < epsilon 
           and math.abs(c1.B - c2.B) < epsilon
    end

    local function getPetRarity(uiGradient)
        if not uiGradient or not uiGradient:IsA("UIGradient") then return nil end
        local keypoints = uiGradient.Color.Keypoints
        if #keypoints ~= 2 then return nil end
        
        local c1 = keypoints[1].Value
        local c2 = keypoints[2].Value

        -- Common Gradient: 0.317647, 1, 0  and  0.0745098, 0.745098, 0.00392157
        if colorsMatch(c1, Color3.new(0.317647, 1, 0)) and colorsMatch(c2, Color3.new(0.0745098, 0.745098, 0.00392157)) then
            return "Common"
        -- Rare Gradient: 0, 0.662745, 0.996078  and  0.0823529, 0.419608, 0.733333
        elseif colorsMatch(c1, Color3.new(0, 0.662745, 0.996078)) and colorsMatch(c2, Color3.new(0.0823529, 0.419608, 0.733333)) then
            return "Rare"
        -- Epic Gradient: 0.984314, 0.207843, 0.92549  and  0.682353, 0.32549, 0.996078
        elseif colorsMatch(c1, Color3.new(0.984314, 0.207843, 0.92549)) and colorsMatch(c2, Color3.new(0.682353, 0.32549, 0.996078)) then
            return "Epic"
        -- Legendary Gradient: 0.960784, 0.976471, 0.403922  and  1, 0.8, 0
        elseif colorsMatch(c1, Color3.new(0.960784, 0.976471, 0.403922)) and colorsMatch(c2, Color3.new(1, 0.8, 0)) then
            return "Legendary"
        end
        return nil
    end

    local function getPetsToDelete()
        local uuids = {}
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return uuids end
        
        local petsInventory = playerGui:FindFirstChild("PetsInventory")
        local holder = petsInventory and petsInventory:FindFirstChild("Holder")
        local main = holder and holder:FindFirstChild("main")
        local petContent = main and main:FindFirstChild("Petcontent")

        if petContent then
            for _, petFrame in ipairs(petContent:GetChildren()) do
                if petFrame:IsA("GuiObject") then
                    local uuid = petFrame.Name
                    -- Standard UUID basic format check
                    if string.match(uuid, "^{[%w%-]+}$") then
                        local petMain = petFrame:FindFirstChild("main")
                        local uiGradient = petMain and petMain:FindFirstChildOfClass("UIGradient")
                        if uiGradient then
                            local rarity = getPetRarity(uiGradient)
                            if rarity and deleteRarities[rarity] == true then
                                table.insert(uuids, uuid)
                            end
                        end
                    end
                end
            end
        end
        return uuids
    end

    -- ===== UI ELEMENTS =====
    elements:Label("💵 Cash (Throw) Utilities", parent)
    elements:Label("Throw Power: LOCKED AT 9e200 (Maximum)", parent)

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

    elements:Label("🛒 Shop Utilities", parent)

    elements:Dropdown("Select Shop Item", parent, shopItems, selectedShopItem, function(value)
        selectedShopItem = value
    end)

    elements:Button("Purchase Selected", parent, function()
        if not Network then return end
        local purchaseEvent = Network:FindFirstChild("ItemShop/Purchase")
        if purchaseEvent and purchaseEvent:IsA("RemoteFunction") then
            local success, err = pcall(function()
                purchaseEvent:InvokeServer(selectedShopItem)
            end)
            if not success then
                warn("[TaperUI Error] Shop purchase failed: " .. tostring(err))
            end
        end
    end)

    elements:Button("Equip Selected", parent, function()
        if not Network then return end
        local equipEvent = Network:FindFirstChild("ItemShop/Equip")
        if equipEvent and equipEvent:IsA("RemoteFunction") then
            local success, err = pcall(function()
                equipEvent:InvokeServer(selectedShopItem)
            end)
            if not success then
                warn("[TaperUI Error] Shop equip failed: " .. tostring(err))
            end
        end
    end)

    elements:Toggle("Auto Buy & Equip Selected", parent, false, function(state)
        autoBuyEquipActive = state
        if autoBuyEquipActive then
            task.spawn(function()
                while autoBuyEquipActive do
                    if Network then
                        local purchaseEvent = Network:FindFirstChild("ItemShop/Purchase")
                        local equipEvent = Network:FindFirstChild("ItemShop/Equip")
                        pcall(function()
                            if purchaseEvent and purchaseEvent:IsA("RemoteFunction") then
                                purchaseEvent:InvokeServer(selectedShopItem)
                            end
                            task.wait(0.5)
                            if equipEvent and equipEvent:IsA("RemoteFunction") then
                                equipEvent:InvokeServer(selectedShopItem)
                            end
                        end)
                    end
                    task.wait(2.0)
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
                        task.wait(2.0)
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

    -- Pet Deletion Configuration Section
    elements:Label("🧹 Pet Deletion Config", parent)

    elements:Toggle("Target Common", parent, false, function(state)
        deleteRarities.Common = state
    end)

    elements:Toggle("Target Rare", parent, false, function(state)
        deleteRarities.Rare = state
    end)

    elements:Toggle("Target Epic", parent, false, function(state)
        deleteRarities.Epic = state
    end)

    elements:Toggle("Target Legendary", parent, false, function(state)
        deleteRarities.Legendary = state
    end)

    elements:Slider("Deletion Speed (s)", parent, 0.5, 10.0, deleteInterval, 1, function(val)
        deleteInterval = val
    end)

    elements:Toggle("Auto Delete Checked", parent, false, function(state)
        autoDeleteActive = state
        if autoDeleteActive then
            task.spawn(function()
                while autoDeleteActive do
                    if Network then
                        local targets = getPetsToDelete()
                        if #targets > 0 then
                            local deleteEvent = Network:FindFirstChild("Pets/Delete")
                            if deleteEvent and deleteEvent:IsA("RemoteEvent") then
                                pcall(function()
                                    deleteEvent:FireServer(targets)
                                end)
                            end
                        end
                    end
                    task.wait(deleteInterval)
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

    -- Cleanup active threads and connections when UI is destroyed
    parent.Destroying:Connect(function()
        autoThrowActive = false
        autoStrengthActive = false
        autoEggActive = false
        autoRebirthActive = false
        autoBuyEquipActive = false
        autoDeleteActive = false
        
        if idledConnection then
            idledConnection:Disconnect()
        end
    end)
end