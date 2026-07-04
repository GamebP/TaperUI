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

    -- Resolve ReplicatedStorage remote parent directory safely
    local EventFolder = ReplicatedStorage:WaitForChild("Event")

    -- ===== STATE CONFIGURATION =====
    local autoTrainActive = false
    local trainAmount = "50"
    local trainInterval = 0.1

    local autoRebirthActive = false
    local rebirthHealth = "300"

    local autoCraftActive = false
    local selectedWeaponToCraft = "Stick"
    local craftQuantity = "1"

    local autoEnchantActive = false
    local enchantCost = "1"
    local enchantIncrease = "1e6"

    local autoSellActive = false
    local sellPrice = "1"
    local sellQuantity = "1"

    local targetSellerToSet = "Seller1"
    local buyerToUnlock = "Seller2"
    local unlockCost = "1"

    local powerWeaponName = "Knife"
    local powerCost = "10"

    -- ===== EXPLICIT THREAD REFERENCES =====
    local trainThread = nil
    local rebirthThread = nil
    local craftThread = nil
    local enchantThread = nil
    local sellThread = nil

    -- ===== TASK SPINDOWN / MANAGERS =====

    local function startTrainLoop()
        if trainThread then
            task.cancel(trainThread)
            trainThread = nil
        end
        if not autoTrainActive then return end

        trainThread = task.create(function()
            while autoTrainActive do
                pcall(function()
                    local amt = tonumber(trainAmount) or 50
                    EventFolder.Train:FireServer(amt)
                end)
                task.wait(trainInterval)
            end
        end)
        task.spawn(trainThread)
    end

    local function startRebirthLoop()
        if rebirthThread then
            task.cancel(rebirthThread)
            rebirthThread = nil
        end
        if not autoRebirthActive then return end

        rebirthThread = task.create(function()
            while autoRebirthActive do
                pcall(function()
                    local hp = tonumber(rebirthHealth) or 300
                    EventFolder.HealthAdd:FireServer(hp)
                end)
                task.wait(0.5)
            end
        end)
        task.spawn(rebirthThread)
    end

    local function startCraftLoop()
        if craftThread then
            task.cancel(craftThread)
            craftThread = nil
        end
        if not autoCraftActive then return end

        craftThread = task.create(function()
            while autoCraftActive do
                pcall(function()
                    local qty = tonumber(craftQuantity) or 1
                    EventFolder.CraftWeapon:FireServer(selectedWeaponToCraft, qty)
                end)
                task.wait(0.3)
            end
        end)
        task.spawn(craftThread)
    end

    local function startEnchantLoop()
        if enchantThread then
            task.cancel(enchantThread)
            enchantThread = nil
        end
        if not autoEnchantActive then return end

        enchantThread = task.create(function()
            while autoEnchantActive do
                pcall(function()
                    local cost = tonumber(enchantCost) or 1
                    local inc = tonumber(enchantIncrease) or 1e6
                    EventFolder.Enchanted:FireServer(cost, inc)
                end)
                task.wait(0.2)
            end
        end)
        task.spawn(enchantThread)
    end

    local function startSellLoop()
        if sellThread then
            task.cancel(sellThread)
            sellThread = nil
        end
        if not autoSellActive then return end

        sellThread = task.create(function()
            while autoSellActive do
                pcall(function()
                    local price = tonumber(sellPrice) or 1
                    local qty = tonumber(sellQuantity) or 1
                    EventFolder.SellWeapon:FireServer(price, qty)
                end)
                task.wait(0.2)
            end
        end)
        task.spawn(sellThread)
    end

    -- ===== TAPERUI INTERFACE ELEMENTS =====

    -- SECTION: Training & Rebirthing
    elements:Label("💪 Training & Rebirthing", parent)

    elements:Toggle("Auto Train Strength", parent, false, function(state)
        autoTrainActive = state
        startTrainLoop()
    end)

    elements:Textbox("Train Amount", parent, trainAmount, function(text)
        trainAmount = text
    end)

    elements:Slider("Training Loop Rate (s)", parent, 0.01, 2.0, trainInterval, 2, function(val)
        trainInterval = val
        if autoTrainActive then
            startTrainLoop() -- Restart task to immediately apply the updated timing
        end
    end)

    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        startRebirthLoop()
    end)

    elements:Textbox("Rebirth Health Add Value", parent, rebirthHealth, function(text)
        rebirthHealth = text
    end)

    -- SECTION: Weapon Crafting & Upgrades
    elements:Label("⚔️ Weapon Crafting & Upgrades", parent)

    elements:Toggle("Auto Craft Selected", parent, false, function(state)
        autoCraftActive = state
        startCraftLoop()
    end)

    elements:Dropdown("Select Weapon to Craft", parent, {"Stick", "Knife", "Emperos", "Endtime"}, selectedWeaponToCraft, function(value)
        selectedWeaponToCraft = value
    end)

    elements:Textbox("Craft Quantity", parent, craftQuantity, function(text)
        craftQuantity = text
    end)

    elements:Toggle("Auto Enchant Active", parent, false, function(state)
        autoEnchantActive = state
        startEnchantLoop()
    end)

    elements:Textbox("Enchant Cost", parent, enchantCost, function(text)
        enchantCost = text
    end)

    elements:Textbox("Enchant Increase Multiplier", parent, enchantIncrease, function(text)
        enchantIncrease = text
    end)

    -- SECTION: Economy & Shops
    elements:Label("💰 Economy & Shops", parent)

    elements:Toggle("Auto Sell Weapon (Negative Price Allowed)", parent, false, function(state)
        autoSellActive = state
        startSellLoop()
    end)

    elements:Textbox("Sell Price (Money)", parent, sellPrice, function(text)
        sellPrice = text
    end)

    elements:Textbox("Sell Quantity", parent, sellQuantity, function(text)
        sellQuantity = text
    end)

    elements:Dropdown("Choose Target Seller", parent, {"Seller1", "Seller2", "Seller3", "Seller4", "Seller5"}, targetSellerToSet, function(value)
        targetSellerToSet = value
        pcall(function()
            EventFolder.ChosenTargetFighter:FireServer(value)
        end)
    end)

    elements:Dropdown("Select Buyer to Unlock", parent, {
        "Seller2", "Seller3", "Seller4", "Seller5", "Seller6", "Seller7", "Seller8", "Seller9", "Seller10",
        "Seller11", "Seller12", "Seller13", "Seller14", "Seller15", "Seller16", "Seller17", "Seller18", "Seller19", "Seller20"
    }, buyerToUnlock, function(value)
        buyerToUnlock = value
    end)

    elements:Textbox("Unlock Price Value", parent, unlockCost, function(text)
        unlockCost = text
    end)

    elements:Button("Unlock Selected Buyer Instance", parent, function()
        pcall(function()
            local storeFolder = workspace:FindFirstChild("StoresRob")
            local targetInstance = storeFolder and storeFolder:FindFirstChild(buyerToUnlock)
            if targetInstance then
                EventFolder.UnlockBuyer:FireServer(targetInstance, tonumber(unlockCost) or 1)
            else
                warn("[TaperUI Error] Store buyer instance not found in workspace.StoresRob: " .. tostring(buyerToUnlock))
            end
        end)
    end)

    elements:Textbox("Weapon Power Name", parent, powerWeaponName, function(text)
        powerWeaponName = text
    end)

    elements:Textbox("Power Buy Cost", parent, powerCost, function(text)
        powerCost = text
    end)

    elements:Button("Buy Power (Once)", parent, function()
        pcall(function()
            EventFolder.BuyPower:FireServer(powerWeaponName, tonumber(powerCost) or 10)
        end)
    end)

    elements:Button("Equip Weapon Effect", parent, function()
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                EventFolder.EquipEffect:FireServer(powerWeaponName, char)
            end
        end)
    end)

    -- Cleanup task threads when the TaperUI frame is destroyed
    parent.Destroying:Connect(function()
        autoTrainActive = false
        autoRebirthActive = false
        autoCraftActive = false
        autoEnchantActive = false
        autoSellActive = false

        if trainThread then task.cancel(trainThread) end
        if rebirthThread then task.cancel(rebirthThread) end
        if craftThread then task.cancel(craftThread) end
        if enchantThread then task.cancel(enchantThread) end
        if sellThread then task.cancel(sellThread) end
    end)
end