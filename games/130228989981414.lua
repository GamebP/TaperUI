-- World 1, 2 & 3 Config Metadata

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
    local selectedWorld = "World 1"

    -- Cash (Throw) Settings
    local autoThrowActive = false
    local throwInterval = 1.0
    local throwPowerValue = 9e200 -- Hardcoded throw power to bypass standard calculation

    -- Strength Settings
    local autoStrengthActive = false
    local strengthInterval = 0.1
    local selectedWall = "Wall1"

    local wallOptionsW1 = {
        "Wall1 (+3)", "Wall2 (+6)", "Wall3 (+8)", "Wall4 (+12)", "Wall5 (+15)", "Wall6 (+20)",
        "Wall7 (+25)", "Wall8 (+30)", "Wall9 (+35)", "Wall10 (+45)", "Wall11 (+60)", "Wall12 (+85)"
    }
    local wallOptionsW2 = {
        "Wall1 (+140)", "Wall2 (+160)", "Wall3 (+170)", "Wall4 (+195)", "Wall5 (+225)", "Wall6 (+260)",
        "Wall7 (+300)", "Wall8 (+375)", "Wall9 (+450)", "Wall10 (+550)", "Wall11 (+675)", "Wall12 (+800)"
    }
    local wallOptionsW3 = {
        "Wall1 (+850)", "Wall2 (+950)", "Wall3 (+1100)", "Wall4 (+1200)", "Wall5 (+1400)", "Wall6 (+1600)",
        "Wall7 (+1800)", "Wall8 (+2100)", "Wall9 (+2700)", "Wall10 (+3400)", "Wall11 (+4300)", "Wall12 (+5500)"
    }

    -- Shop Settings
    local selectedShopItem = "Paper Airplane"
    local autoBuyEquipActive = false
    
    local shopItemsW1 = {
        "Paper Airplane", "Balloon", "Kite", "Umbrella", "Fan", "Leaf Blower",
        "Hang Glider", "WindTurbine", "Parachute", "Firework", "Triple Balloon",
        "Blimp", "Hot Air Balloon", "Airplane Turbine", "Jetpack", "Rocket"
    }
    local shopItemsW2 = {
        "BeachBall", "SharkFin", "LifeGuardFloatie", "Hat", "SandBucket", "BeachUmbrella",
        "Anchor", "DonutFloatie", "Barrel", "TurtleFloatie", "SurfBoard", "Trident",
        "CrabFloatie", "Kayak", "SandCastle", "FlamingoFloatie"
    }
    local shopItemsW3 = {
        "SnowFlake", "Present", "Wreath", "ChristmasBell", "BiscuitMan", "SnowBalls",
        "PresentBag", "TreeStar", "ChristmasTrain", "CandyCane", "SantaHat", "Igloo",
        "ChristmasSock", "Turkey", "Chimney", "SnowMan"
    }

    -- Egg Open Settings
    local autoEggActive = false
    local eggInterval = 1.0
    local selectedEgg = "Egg1"
    local selectedEggAmount = 1
    
    local eggOptionsW1 = {"Egg1", "Egg2", "Egg3"}
    local eggOptionsW2 = {"Egg4", "Egg5", "Egg6"}
    local eggOptionsW3 = {"Egg7", "Egg8", "Egg9"}
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

    -- Safety & AFK Settings
    local autoAntiAfkActive = true
    local idledConnection = nil

    -- ===== AUTOMATION HELPER FUNCTIONS =====
    
    -- Safety AFK Connection Handler
    local function setupAntiAfk()
        if idledConnection then
            idledConnection:Disconnect()
            idledConnection = nil
        end
        
        if autoAntiAfkActive then
            idledConnection = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end)
        end
    end

    -- Active redundant background loop (keeps client active every 60s as a backup)
    task.spawn(function()
        while true do
            task.wait(60)
            if autoAntiAfkActive then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end
        end
    end)

    -- Initialize AFK protection on startup
    setupAntiAfk()

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

        if colorsMatch(c1, Color3.new(0.317647, 1, 0)) and colorsMatch(c2, Color3.new(0.0745098, 0.745098, 0.00392157)) then
            return "Common"
        elseif colorsMatch(c1, Color3.new(0, 0.662745, 0.996078)) and colorsMatch(c2, Color3.new(0.0823529, 0.419608, 0.733333)) then
            return "Rare"
        elseif colorsMatch(c1, Color3.new(0.984314, 0.207843, 0.92549)) and colorsMatch(c2, Color3.new(0.682353, 0.32549, 0.996078)) then
            return "Epic"
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
    elements:Label("🌍 World Selection", parent)

    -- Pre-declare dropdown visual variables
    local wallDropdownW1, wallDropdownW2, wallDropdownW3
    local shopDropdownW1, shopDropdownW2, shopDropdownW3
    local eggDropdownW1, eggDropdownW2, eggDropdownW3

    local function updateWorldVisibility()
        local isW1 = (selectedWorld == "World 1")
        local isW2 = (selectedWorld == "World 2")
        local isW3 = (selectedWorld == "World 3")

        if wallDropdownW1 then wallDropdownW1.Visible = isW1 end
        if wallDropdownW2 then wallDropdownW2.Visible = isW2 end
        if wallDropdownW3 then wallDropdownW3.Visible = isW3 end

        if shopDropdownW1 then shopDropdownW1.Visible = isW1 end
        if shopDropdownW2 then shopDropdownW2.Visible = isW2 end
        if shopDropdownW3 then shopDropdownW3.Visible = isW3 end

        if eggDropdownW1 then eggDropdownW1.Visible = isW1 end
        if eggDropdownW2 then eggDropdownW2.Visible = isW2 end
        if eggDropdownW3 then eggDropdownW3.Visible = isW3 end
    end

    elements:Dropdown("Select Active World", parent, {"World 1", "World 2", "World 3"}, selectedWorld, function(value)
        selectedWorld = value
        if value == "World 1" then
            selectedWall = "Wall1"
            selectedShopItem = "Paper Airplane"
            selectedEgg = "Egg1"
        elseif value == "World 2" then
            selectedWall = "Wall1"
            selectedShopItem = "BeachBall"
            selectedEgg = "Egg4"
        elseif value == "World 3" then
            selectedWall = "Wall1"
            selectedShopItem = "SnowFlake"
            selectedEgg = "Egg7"
        end
        updateWorldVisibility()
    end)

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

    -- World 1 Wall Dropdown
    wallDropdownW1 = elements:Dropdown("Select Training Wall (W1)", parent, wallOptionsW1, "Wall1 (+3)", function(value)
        local baseWallName = value:match("^(Wall%d+)")
        if baseWallName then selectedWall = baseWallName end
    end)

    -- World 2 Wall Dropdown
    wallDropdownW2 = elements:Dropdown("Select Training Wall (W2)", parent, wallOptionsW2, "Wall1 (+140)", function(value)
        local baseWallName = value:match("^(Wall%d+)")
        if baseWallName then selectedWall = baseWallName end
    end)

    -- World 3 Wall Dropdown
    wallDropdownW3 = elements:Dropdown("Select Training Wall (W3)", parent, wallOptionsW3, "Wall1 (+850)", function(value)
        local baseWallName = value:match("^(Wall%d+)")
        if baseWallName then selectedWall = baseWallName end
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

    -- World 1 Shop Dropdown
    shopDropdownW1 = elements:Dropdown("Select Shop Item (W1)", parent, shopItemsW1, "Paper Airplane", function(value)
        selectedShopItem = value
    end)

    -- World 2 Shop Dropdown
    shopDropdownW2 = elements:Dropdown("Select Shop Item (W2)", parent, shopItemsW2, "BeachBall", function(value)
        selectedShopItem = value
    end)

    -- World 3 Shop Dropdown
    shopDropdownW3 = elements:Dropdown("Select Shop Item (W3)", parent, shopItemsW3, "SnowFlake", function(value)
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

    -- World 1 Egg Dropdown
    eggDropdownW1 = elements:Dropdown("Select Egg (W1)", parent, eggOptionsW1, "Egg1", function(value)
        selectedEgg = value
    end)

    -- World 2 Egg Dropdown
    eggDropdownW2 = elements:Dropdown("Select Egg (W2)", parent, eggOptionsW2, "Egg4", function(value)
        selectedEgg = value
    end)

    -- World 3 Egg Dropdown
    eggDropdownW3 = elements:Dropdown("Select Egg (W3)", parent, eggOptionsW3, "Egg7", function(value)
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

    elements:Label("🛡️ Safety & AFK Utilities", parent)

    elements:Toggle("Anti-AFK Keep-Alive", parent, autoAntiAfkActive, function(state)
        autoAntiAfkActive = state
        setupAntiAfk()
    end)

    -- Adjust initial visibility state based on selectedWorld
    updateWorldVisibility()

    -- Cleanup active threads and connections when UI is destroyed
    parent.Destroying:Connect(function()
        autoThrowActive = false
        autoStrengthActive = false
        autoEggActive = false
        autoRebirthActive = false
        autoBuyEquipActive = false
        autoDeleteActive = false
        autoAntiAfkActive = false
        
        if idledConnection then
            idledConnection:Disconnect()
        end
    end)
end