-- TaperUI Script for Game 70632710874255 (Grocery Store)
-- Place in: /TaperUI/games/70632710874255.lua

return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local GuiService = game:GetService("GuiService")

    -- ===== STATE VARIABLES =====
    local autoCollectActive = false
    local autoRestockActive = false
    local autoSellActive = false
    local loopInterval = 0.5
    local collectRadius = 25
    local selectedSection = "None"

    -- ===== SECTION POSITIONS (Adjust based on actual game positions) =====
    local sectionPositions = {
        ["Seafood"] = nil,      -- Will auto-detect from workspace
        ["Dairy"] = nil,
        ["Bakery"] = nil,
        ["Beverages"] = nil,
        ["Cans/Snacks"] = nil,
        ["Entrance"] = nil,
    }

    -- ===== HELPER: TELEPORT TO POSITION =====
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- ===== HELPER: VIRTUAL CLICK =====
    local function virtualClick(button)
        if not button then return false end
        
        local absPos = button.AbsolutePosition
        local absSize = button.AbsoluteSize
        local clickX = absPos.X + (absSize.X / 2)
        local clickY = absPos.Y + (absSize.Y / 2)
        
        local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
        if screenGui and not screenGui.IgnoreGuiInset then
            local inset = GuiService:GetGuiInset()
            clickX = clickX + inset.X
            clickY = clickY + inset.Y
        end
        
        VirtualInputManager:SendMouseMoveEvent(clickX, clickY, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
        return true
    end

    -- ===== AUTO-DETECT SECTION POSITIONS FROM WORKSPACE =====
    local function detectSectionPositions()
        local storeMaps = Workspace:FindFirstChild("StoreMaps")
        local mediumStore = storeMaps and storeMaps:FindFirstChild("MediumStore")
        
        if not mediumStore then
            warn("[GroceryStore] MediumStore not found in Workspace")
            return
        end

        -- Detect section positions from model centers
        local sections = {
            Seafood = mediumStore:FindFirstChild("Seafood_Seafood"),
            Dairy = mediumStore:FindFirstChild("Fridge_Dairy"),
            Bakery = mediumStore:FindFirstChild("WallShelf_Bakery"),
            Beverages = mediumStore:FindFirstChild("Fridge_Beverages"),
            ["Cans/Snacks"] = mediumStore:FindFirstChild("Gondola_Cans_Snacks"),
        }

        for sectionName, sectionModel in pairs(sections) do
            if sectionModel then
                local _, size = sectionModel:GetBoundingBox()
                local pos = sectionModel:GetPivot().Position
                -- Position slightly above the section for navigation
                sectionPositions[sectionName] = pos + Vector3.new(0, 3, 0)
                print("[GroceryStore] Found " .. sectionName .. " at: " .. tostring(sectionPositions[sectionName]))
            end
        end

        -- Find entrance from door positions
        local shell = mediumStore:FindFirstChild("Shell")
        if shell then
            local doorFrame = shell:FindFirstChild("DoorFrame")
            if doorFrame then
                sectionPositions["Entrance"] = doorFrame.Position + Vector3.new(0, 3, 8)
            end
        end
    end

    -- Detect positions on script load
    detectSectionPositions()

    -- ===== FIND AND COLLECT NEARBY ITEMS =====
    local function collectNearbyItems()
        local char = LocalPlayer.Character
        if not char then return 0 end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return 0 end

        local collected = 0
        
        -- Method 1: Fire Collection Remotes
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local nameLower = string.lower(remote.Name)
                if string.find(nameLower, "collect") or string.find(nameLower, "pickup") or string.find(nameLower, "grab") then
                    pcall(function()
                        remote:FireServer()
                        collected = collected + 1
                    end)
                end
            end
        end

        -- Method 2: Touch nearby collectible parts
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj:FindFirstChild("TouchTransmitter") or obj.Name:lower():find("collect") or obj.Name:lower():find("item") or obj.Name:lower():find("drop")) then
                local dist = (obj.Position - root.Position).Magnitude
                if dist <= collectRadius then
                    pcall(function()
                        root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2, 0))
                        task.wait(0.05)
                    end)
                    collected = collected + 1
                end
            end
        end

        return collected
    end

    -- ===== FIND AND CLICK RESTOCK BUTTONS =====
    local function attemptRestock()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end

        -- Search for restock-related buttons in all GUIs
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local found = gui:FindFirstChild("Restock", true)
                if found and (found:IsA("TextButton") or found:IsA("ImageButton")) then
                    if found.Visible then
                        virtualClick(found)
                        return true
                    end
                end
            end
        end
        return false
    end

    -- ===== FIND AND CLICK SELL/CHECKOUT BUTTON =====
    local function attemptSell()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return false end

        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, child in ipairs(gui:GetDescendants()) do
                    if (child:IsA("TextButton") or child:IsA("ImageButton")) and child.Visible then
                        local nameLower = string.lower(child.Name)
                        local textLower = child:IsA("TextButton") and string.lower(child.Text) or ""
                        
                        if string.find(nameLower, "sell") or string.find(nameLower, "checkout") or
                           string.find(nameLower, "cash") or string.find(textLower, "sell") or 
                           string.find(textLower, "checkout") then
                            virtualClick(child)
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    -- ===== GET CURRENT MONEY/CASH FROM LEADERSTATS =====
    local function getCurrentMoney()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if not leaderstats then
            -- Try alternative stat names
            leaderstats = LocalPlayer:FindFirstChild("Stats") or LocalPlayer:FindFirstChild("Data")
        end
        
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    local nameLower = string.lower(stat.Name)
                    if string.find(nameLower, "money") or string.find(nameLower, "cash") or 
                       string.find(nameLower, "coin") or string.find(nameLower, "fund") then
                        return stat.Name, stat.Value
                    end
                end
            end
        end
        return nil, 0
    end

    -- ===== SECTION QUICK TELEPORT DROPDOWN =====
    local sectionDropdown = elements:Dropdown("Teleport to Section", parent, {
        "None",
        "Seafood",
        "Dairy", 
        "Bakery",
        "Beverages",
        "Cans/Snacks",
        "Entrance"
    }, "None", function(value)
        selectedSection = value
        if value ~= "None" and sectionPositions[value] then
            teleportTo(sectionPositions[value])
            print("[GroceryStore] Teleported to: " .. value)
        elseif value ~= "None" then
            warn("[GroceryStore] Position not found for: " .. value)
        end
    end)

    -- ===== REFRESH SECTION POSITIONS BUTTON =====
    elements:Button("Refresh Section Positions", parent, function()
        detectSectionPositions()
        print("[GroceryStore] Section positions refreshed")
    end)

    -- ===== UI ELEMENTS =====
    elements:Label("🔥 Grocery Store Utilities", parent)

    -- Collect Radius Slider
    elements:Slider("Collection Radius", parent, 5, 100, collectRadius, 0, function(val)
        collectRadius = val
    end)

    -- Loop Interval Slider
    elements:Slider("Loop Interval (s)", parent, 0.1, 5.0, loopInterval, 1, function(val)
        loopInterval = val
    end)

    -- Auto Collect Toggle
    elements:Toggle("Auto Collect Items", parent, false, function(state)
        autoCollectActive = state
        if autoCollectActive then
            task.spawn(function()
                while autoCollectActive do
                    pcall(function()
                        local collected = collectNearbyItems()
                        if collected > 0 then
                            print("[GroceryStore] Collected " .. collected .. " items")
                        end
                    end)
                    task.wait(loopInterval)
                end
            end)
        end
    end)

    -- Auto Restock Toggle
    elements:Toggle("Auto Restock Shelves", parent, false, function(state)
        autoRestockActive = state
        if autoRestockActive then
            task.spawn(function()
                while autoRestockActive do
                    pcall(function()
                        if attemptRestock() then
                            print("[GroceryStore] Restock action triggered")
                        end
                    end)
                    task.wait(loopInterval)
                end
            end)
        end
    end)

    -- Auto Sell Toggle
    elements:Toggle("Auto Sell/Checkout", parent, false, function(state)
        autoSellActive = state
        if autoSellActive then
            task.spawn(function()
                while autoSellActive do
                    pcall(function()
                        if attemptSell() then
                            print("[GroceryStore] Sell action triggered")
                        end
                    end)
                    task.wait(loopInterval)
                end
            end)
        end
    end)

    -- Money Display
    local moneyLabel = elements:Label("💰 Money: Loading...", parent)

    -- Update money display loop
    task.spawn(function()
        while parent and parent.Parent do
            pcall(function()
                local statName, money = getCurrentMoney()
                if statName then
                    moneyLabel.Text = "💰 " .. statName .. ": " .. tostring(money)
                else
                    moneyLabel.Text = "💰 Money: Not found"
                end
            end)
            task.wait(1)
        end
    end)

    -- ===== SCAN FOR REMOTES BUTTON =====
    elements:Button("Scan Game Remotes", parent, function()
        print("\n[GroceryStore] ===== REMOTE SCAN RESULTS =====")
        
        local remoteCount = 0
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                remoteCount = remoteCount + 1
                print(string.format("[%d] %s (%s)", remoteCount, remote.Name, remote.ClassName))
            end
        end
        
        -- Also check Workspace for remotes
        for _, remote in ipairs(Workspace:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                remoteCount = remoteCount + 1
                print(string.format("[%d] %s (%s) [Workspace]", remoteCount, remote.Name, remote.ClassName))
            end
        end
        
        print("[GroceryStore] Total remotes found: " .. remoteCount)
        print("[GroceryStore] ================================\n")
    end)

    -- ===== SCAN FOR GUI BUTTONS BUTTON =====
    elements:Button("Scan GUI Buttons", parent, function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then
            warn("[GroceryStore] PlayerGui not found")
            return
        end

        print("\n[GroceryStore] ===== GUI BUTTON SCAN =====")
        
        local buttonCount = 0
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, child in ipairs(gui:GetDescendants()) do
                    if (child:IsA("TextButton") or child:IsA("ImageButton")) and child.Visible then
                        buttonCount = buttonCount + 1
                        local text = child:IsA("TextButton") and child.Text or "(ImageButton)"
                        print(string.format("[%d] %s - \"%s\" [%s]", buttonCount, child:GetFullName(), text, gui.Name))
                    end
                end
            end
        end
        
        print("[GroceryStore] Total visible buttons: " .. buttonCount)
        print("[GroceryStore] ================================\n")
    end)

    -- ===== LIST SHELF SLOTS BUTTON =====
    elements:Button("List Shelf Slots", parent, function()
        local storeMaps = Workspace:FindFirstChild("StoreMaps")
        local mediumStore = storeMaps and storeMaps:FindFirstChild("MediumStore")
        
        if not mediumStore then
            warn("[GroceryStore] MediumStore not found")
            return
        end

        print("\n[GroceryStore] ===== SHELF SLOTS =====")
        
        local slotCount = 0
        for _, obj in ipairs(mediumStore:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:match("^Slot_") then
                slotCount = slotCount + 1
                -- Extract product name from slot name
                local productName = obj.Name:gsub("^Slot_", ""):gsub("_%d+$", "")
                print(string.format("[%d] %s at %s (Product: %s)", slotCount, obj.Name, tostring(obj.Position), productName))
            end
        end
        
        print("[GroceryStore] Total slots: " .. slotCount)
        print("[GroceryStore] ==========================\n")
    end)

    -- ===== CHARACTER RESPAWN HANDLER =====
    local characterAddedConn
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        detectSectionPositions()
        
        -- Re-enable loops if they were active
        if autoCollectActive then
            task.spawn(function()
                while autoCollectActive do
                    pcall(collectNearbyItems)
                    task.wait(loopInterval)
                end
            end)
        end
    end)

    -- ===== CLEANUP ON UI DESTROY =====
    parent.Destroying:Connect(function()
        autoCollectActive = false
        autoRestockActive = false
        autoSellActive = false
        if characterAddedConn then
            characterAddedConn:Disconnect()
        end
    end)

    print("[GroceryStore] Script loaded successfully!")
end