-- TaperUI Script for Grocery Store
-- Features: Auto-pickup items from floor, auto-place into correct shelves with bypass handling

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
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    -- ===== STATE =====
    local autoModeActive = false
    local collectRadius = 30
    local loopInterval = 0.5
    local availableItems = {}            -- List of floor items with their type
    local slotMap = {}                   -- Map itemType -> list of slot parts

    -- ===== REMOTE REFERENCES (cached) =====
    local remotes = {
        PickupItem = nil,
        DropItem = nil,
        PlaceItem = nil,
    }

    -- ===== SIMULATE E KEY PRESS =====
    local function pressE()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end

    -- ===== FIND REMOTES =====
    local function findRemotes()
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local name = remote.Name:lower()
                if name:find("pickup") then remotes.PickupItem = remote end
                if name:find("drop") then remotes.DropItem = remote end
                if name:find("place") then remotes.PlaceItem = remote end
            end
        end
        print(string.format("[GroceryStore] Remotes: Pickup=%s, Drop=%s, Place=%s",
            tostring(remotes.PickupItem), tostring(remotes.DropItem), tostring(remotes.PlaceItem)))
    end

    -- ===== BUILD SLOT MAP =====
    local function buildSlotMap()
        slotMap = {}
        local storeMaps = Workspace:FindFirstChild("StoreMaps")
        local mediumStore = storeMaps and storeMaps:FindFirstChild("MediumStore")
        if not mediumStore then
            warn("[GroceryStore] MediumStore not found")
            return
        end

        for _, slot in ipairs(mediumStore:GetDescendants()) do
            if slot:IsA("BasePart") and slot.Name:match("^Slot_") then
                -- Extract item type from slot name (e.g., "Slot_Seafood_FishFillet_Pink_4" -> "Seafood_FishFillet_Pink")
                local itemType = slot.Name:gsub("^Slot_", ""):gsub("_%d+$", "")
                if not slotMap[itemType] then slotMap[itemType] = {} end
                table.insert(slotMap[itemType], slot)
            end
        end

        print("[GroceryStore] Slot map built with " .. #slotMap .. " types")
    end

    -- ===== FIND FLOOR ITEMS =====
    local function refreshFloorItems()
        availableItems = {}
        local floorItemsFolder = Workspace:FindFirstChild("FloorItems")
        if not floorItemsFolder then
            warn("[GroceryStore] FloorItems folder not found")
            return
        end

        for _, item in ipairs(floorItemsFolder:GetChildren()) do
            if item:IsA("BasePart") or item:IsA("MeshPart") then
                -- Determine item type from name (remove suffixes like numbers)
                local itemType = item.Name:gsub("_[%d]+$", "")
                if not itemType or itemType == "" then
                    itemType = item.Name
                end
                table.insert(availableItems, {
                    instance = item,
                    type = itemType,
                    position = item.Position,
                })
            end
        end
        print("[GroceryStore] Found " .. #availableItems .. " floor items")
    end

    -- ===== CHECK IF PLAYER IS HOLDING AN ITEM =====
    local function getHeldItems()
        local held = {}
        
        -- Checks Workspace.Camera.HeldVisuals folder
        local camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
        local heldVisuals = camera and camera:FindFirstChild("HeldVisuals")
        if heldVisuals then
            for _, child in ipairs(heldVisuals:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") or child:IsA("Model") then
                    local itemType = child.Name:gsub("_[%d]+$", "")
                    table.insert(held, {instance = child, type = itemType})
                end
            end
        end

        -- Check player character directly as fallback
        local char = LocalPlayer.Character
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Tool") or child.Name:find("Held") or child.Name:find("Holding") then
                    local itemType = child.Name:gsub("_[%d]+$", "")
                    table.insert(held, {instance = child, type = itemType})
                end
            end
        end

        return held
    end

    -- ===== PERFORM PICKUP (Teleports briefly to bypass distance checks) =====
    local function pickupItem(item)
        if not item or not item.instance then return false end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        local originalPos = root.CFrame
        
        -- Teleport directly to the item position to satisfy distance validation
        root.CFrame = CFrame.new(item.position + Vector3.new(0, 1.5, 0))
        task.wait(0.15)

        if remotes.PickupItem then
            pcall(function()
                remotes.PickupItem:FireServer(item.instance)
            end)
        else
            pressE()
        end

        task.wait(0.1)
        root.CFrame = originalPos
        return true
    end

    -- ===== PERFORM PLACE (Teleports briefly to bypass distance checks) =====
    local function placeItem(slot, itemType)
        if not slot then return false end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false end

        local originalPos = root.CFrame
        
        -- Teleport directly to the slot position to satisfy distance validation
        root.CFrame = CFrame.new(slot.Position + Vector3.new(0, 1.5, 0))
        task.wait(0.15)

        if remotes.PlaceItem then
            pcall(function()
                -- Attempt with and without implicit slot parent arguments to ensure network compatibility
                remotes.PlaceItem:FireServer(slot, itemType)
                remotes.PlaceItem:FireServer(slot)
            end)
        else
            pressE()
        end

        task.wait(0.1)
        root.CFrame = originalPos
        return true
    end

    -- ===== FIND EMPTY SLOT FOR ITEM TYPE =====
    local function findEmptySlot(itemType)
        local slots = slotMap[itemType]
        if not slots then return nil end

        -- Check if any shelf slot of this type is currently empty
        for _, slot in ipairs(slots) do
            local hasItem = false
            for _, child in ipairs(slot:GetChildren()) do
                if child:IsA("MeshPart") or (child:IsA("BasePart") and child.Name ~= slot.Name) then
                    hasItem = true
                    break
                end
            end
            if not hasItem then
                return slot
            end
        end
        return nil
    end

    -- ===== MAIN AUTOMATION LOOP =====
    local function runAutomation()
        if not autoModeActive then return end

        -- Step 1: If holding any items, prioritize placing them on their shelves
        local heldItems = getHeldItems()
        if #heldItems > 0 then
            for _, item in ipairs(heldItems) do
                local slot = findEmptySlot(item.type)
                if slot then
                    print("[GroceryStore] Placing " .. item.type .. " into slot " .. slot.Name)
                    placeItem(slot, item.type)
                    task.wait(0.3)
                    return
                else
                    print("[GroceryStore] No empty slot found for " .. item.type .. ". Dropping it.")
                    if remotes.DropItem then
                        pcall(function() remotes.DropItem:FireServer() end)
                    end
                    task.wait(0.3)
                    return
                end
            end
        end

        -- Step 2: Grab any matching floor item
        refreshFloorItems()

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local nearestItem = nil
        local nearestDist = math.huge
        for _, item in ipairs(availableItems) do
            local dist = (item.position - root.Position).Magnitude
            if dist < collectRadius and dist < nearestDist then
                -- Only pick up if there's actually an open slot available for it
                if findEmptySlot(item.type) then
                    nearestItem = item
                    nearestDist = dist
                end
            end
        end

        if nearestItem then
            print("[GroceryStore] Picking up " .. nearestItem.type)
            pickupItem(nearestItem)
            task.wait(0.3)
        else
            task.wait(0.5)
        end
    end

    -- ===== UI ELEMENTS =====
    elements:Label("🛒 Grocery Store Automation", parent)

    -- Radius slider
    elements:Slider("Collection Radius", parent, 5, 100, collectRadius, 0, function(val)
        collectRadius = val
    end)

    -- Interval slider
    elements:Slider("Loop Interval (s)", parent, 0.1, 5.0, loopInterval, 1, function(val)
        loopInterval = val
    end)

    -- Main toggle
    elements:Toggle("Auto Pick & Place", parent, false, function(state)
        autoModeActive = state
        if state then
            findRemotes()
            buildSlotMap()
            refreshFloorItems()
            print("[GroceryStore] Auto mode started")
        else
            print("[GroceryStore] Auto mode stopped")
        end
    end)

    -- Manual buttons for debugging
    elements:Button("Refresh Slots", parent, function()
        buildSlotMap()
        print("[GroceryStore] Slots refreshed")
    end)

    elements:Button("Refresh Floor Items", parent, function()
        refreshFloorItems()
        print("[GroceryStore] Floor items refreshed")
    end)

    elements:Button("Drop Held Item", parent, function()
        if remotes.DropItem then
            pcall(function() remotes.DropItem:FireServer() end)
        else
            warn("[GroceryStore] Drop remote not found")
        end
    end)

    -- Status label
    local statusLabel = elements:Label("Status: Idle", parent)

    -- Update status in main loop
    task.spawn(function()
        while parent and parent.Parent do
            if autoModeActive then
                statusLabel.Text = "Status: Running"
            else
                statusLabel.Text = "Status: Idle"
            end
            task.wait(0.5)
        end
    end)

    -- Main automation loop (runs independently)
    task.spawn(function()
        while parent and parent.Parent do
            if autoModeActive then
                pcall(runAutomation)
            end
            task.wait(loopInterval)
        end
    end)

    -- ===== CLEANUP =====
    parent.Destroying:Connect(function()
        autoModeActive = false
    end)

    print("[GroceryStore] Script loaded successfully!")
end