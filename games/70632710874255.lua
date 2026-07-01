-- TaperUI Script for Game 70632710874255 (Grocery Store)
-- Features: Auto-pickup items from floor, auto-place into correct shelves

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
    local currentHeldItem = nil          -- Name of the item currently held (if any)
    local availableItems = {}            -- List of floor items with their type
    local slotMap = {}                   -- Map itemType -> list of slot parts

    -- ===== REMOTE REFERENCES (cached) =====
    local remotes = {
        PickupItem = nil,
        DropItem = nil,
        PlaceItem = nil,
    }

    -- ===== HELPER: TELEPORT =====
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
                -- Special case: if name contains underscores, assume it's the type
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
    local function getHeldItem()
        -- Check HeldVisuals folder in workspace or player's character
        local char = LocalPlayer.Character
        if not char then return nil end

        -- Look for held item in character (e.g., a tool or a part attached to hand)
        local held = char:FindFirstChild("HeldItem") or char:FindFirstChild("Holding")
        if held then
            -- Determine its type from name
            return held.Name:gsub("_[%d]+$", "")
        end

        -- Also check the HeldVisuals folder (from data model)
        local workspaceHeld = Workspace:FindFirstChild("HeldVisuals")
        if workspaceHeld then
            for _, child in ipairs(workspaceHeld:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    return child.Name:gsub("_[%d]+$", "")
                end
            end
        end

        return nil
    end

    -- ===== PERFORM PICKUP =====
    local function pickupItem(item)
        if not item or not item.instance then return false end

        -- Attempt remote fire
        if remotes.PickupItem then
            pcall(function()
                remotes.PickupItem:FireServer(item.instance)
                remotes.PickupItem:FireServer(item.instance:GetFullName())
            end)
            return true
        end

        -- Fallback: simulate E on the part
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local originalPos = root.Position
            root.CFrame = CFrame.new(item.position + Vector3.new(0, 2, 0))
            task.wait(0.1)
            pressE()
            root.CFrame = CFrame.new(originalPos)
            return true
        end
        return false
    end

    -- ===== PERFORM PLACE =====
    local function placeItem(slot, itemType)
        if not slot then return false end

        -- Attempt remote fire
        if remotes.PlaceItem then
            pcall(function()
                remotes.PlaceItem:FireServer(slot, itemType)
                remotes.PlaceItem:FireServer(slot:GetFullName(), itemType)
            end)
            return true
        end

        -- Fallback: teleport to slot and press E
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local originalPos = root.Position
            root.CFrame = CFrame.new(slot.Position + Vector3.new(0, 2, 0))
            task.wait(0.1)
            pressE()
            root.CFrame = CFrame.new(originalPos)
            return true
        end
        return false
    end

    -- ===== FIND EMPTY SLOT FOR ITEM TYPE =====
    local function findEmptySlot(itemType)
        local slots = slotMap[itemType]
        if not slots then return nil end

        -- Check if any slot is empty (has no child or has a specific flag)
        for _, slot in ipairs(slots) do
            -- Check if slot has a child that is an item (maybe a part named after the item)
            local hasItem = false
            for _, child in ipairs(slot:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                    -- Check if child name matches the item type or is something like "Item"
                    if child.Name:find(itemType) or child.Name:find("Item") then
                        hasItem = true
                        break
                    end
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

        -- Refresh floor items periodically
        refreshFloorItems()

        -- Step 1: If holding an item, try to place it
        local heldType = getHeldItem()
        if heldType then
            local slot = findEmptySlot(heldType)
            if slot then
                print("[GroceryStore] Placing " .. heldType .. " into slot " .. slot.Name)
                placeItem(slot, heldType)
                task.wait(0.5)
            else
                print("[GroceryStore] No empty slot found for " .. heldType)
                -- If no slot, maybe drop the item?
                if remotes.DropItem then
                    pcall(function() remotes.DropItem:FireServer() end)
                end
            end
            return
        end

        -- Step 2: Pick up a nearby item from the floor
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local nearestItem = nil
        local nearestDist = math.huge
        for _, item in ipairs(availableItems) do
            local dist = (item.position - root.Position).Magnitude
            if dist < collectRadius and dist < nearestDist then
                -- Check if this item type has an empty slot (so we can place it)
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
            -- No items to pick up, wait a bit
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
            -- Initialize on start
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