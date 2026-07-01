return function(parent, config)
    -- 1. Import TaperUI elements helper
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local CollectionService = game:GetService("CollectionService")
    local UserInputService = game:GetService("UserInputService")
    
    local player = Players.LocalPlayer
    local autoOrganizeActive = false
    local loopThread = nil

    -- 2. Load game modules safely
    local Loader, ReplicaController, BooksData
    local moduleLoadSuccess, loadErr = pcall(function()
        Loader = require(ReplicatedStorage.Packages.Loader)
        ReplicaController = require(Loader.Shared.Utility.ReplicaController)
        BooksData = require(Loader.Shared.Data.Books)
    end)

    if not moduleLoadSuccess then
        warn("[TaperUI] Failed to load required modules:", loadErr)
        elements:Label("❌ Failed to load game modules", parent)
        elements:Label("Check ReplicatedStorage.Packages", parent)
        return
    end

    -- 3. Get LibraryReplica
    local LibraryReplica = nil
    for _, r in pairs(ReplicaController._replicas) do
        if r.Class == "Library" then LibraryReplica = r break end
    end
    if not LibraryReplica then
        ReplicaController.ReplicaOfClassCreated("Library", function(replica) LibraryReplica = replica end)
        while not LibraryReplica do task.wait() end
    end

    -- 4. Locate books folder
    local Library = Workspace:FindFirstChild("Library")
    if not Library then
        elements:Label("❌ Library not found in Workspace", parent)
        return
    end
    local BooksFolder = Library:FindFirstChild("Books")
    if not BooksFolder then
        elements:Label("❌ Books folder not found", parent)
        return
    end

    -- 5. Cache shelf models (must be tagged "Shelf" and have Width attribute)
    local shelfModels = {}
    for _, shelfModel in ipairs(CollectionService:GetTagged("Shelf")) do
        shelfModels[shelfModel.Name] = shelfModel
    end
    if next(shelfModels) == nil then
        elements:Label("⚠️ No tagged shelves found", parent)
        elements:Label("Ensure shelves have 'Shelf' tag", parent)
        -- non‑fatal, but will fail to find shelves
    end

    -- 6. Helper: get series currently assigned to a shelf
    local function getShelfAssignedSeries(shelfId)
        local shelfData = LibraryReplica.Data.Shelves[shelfId]
        if not shelfData then return nil end
        for _, placedBook in pairs(shelfData.Books) do
            local bookName = typeof(placedBook) == "Instance" and placedBook.Name or placedBook
            local seriesName = bookName:match("^(.-)_(.+)$")
            if seriesName then return seriesName end
        end
        return nil
    end

    -- 7. Find a suitable shelf for a given series
    local function findShelfForSeries(seriesName, genreName, volumeCount)
        -- First, try a shelf already assigned to this series
        for shelfId, shelfData in pairs(LibraryReplica.Data.Shelves) do
            if not shelfData.Completed and shelfData.Category == genreName then
                local shelfModel = shelfModels[shelfId]
                if shelfModel and shelfModel:GetAttribute("Width") == volumeCount then
                    if getShelfAssignedSeries(shelfId) == seriesName then
                        return shelfModel
                    end
                end
            end
        end
        -- Then, try an empty shelf of the correct width
        for shelfId, shelfData in pairs(LibraryReplica.Data.Shelves) do
            if not shelfData.Completed and shelfData.Category == genreName then
                local shelfModel = shelfModels[shelfId]
                if shelfModel and shelfModel:GetAttribute("Width") == volumeCount then
                    if not getShelfAssignedSeries(shelfId) and next(shelfData.Books) == nil then
                        return shelfModel
                    end
                end
            end
        end
        return nil
    end

    -- 8. Teleport helper
    local function teleportTo(obj)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
        if root and part then
            root.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
            task.wait(0.05)
        end
    end

    -- 9. Main sorting routine
    local function organizeBooks()
        if not BooksFolder then return end

        for _, book in ipairs(BooksFolder:GetChildren()) do
            if not autoOrganizeActive then break end
            task.wait(0.02)

            local seriesName, volumeStr = book.Name:match("^(.-)_(.+)$")
            local volumeNum = tonumber(volumeStr)
            if seriesName and volumeNum then
                local genreName, bookInfo = BooksData.GetCategory(seriesName)
                if genreName and bookInfo then
                    local shelfModel = findShelfForSeries(seriesName, genreName, bookInfo.VolumeCount)
                    if shelfModel then
                        local shelfData = LibraryReplica.Data.Shelves[shelfModel.Name]
                        if not (shelfData and shelfData.Books[tostring(volumeNum)]) then
                            teleportTo(book)
                            LibraryReplica:FireServer("Grab", book)
                            task.wait(0.1)
                            teleportTo(shelfModel)
                            LibraryReplica:FireServer("Place", shelfModel, volumeNum - 1)
                            task.wait(0.4)
                        end
                    end
                end
            end
        end
    end

    -- 10. UI with TaperUI
    elements:Label("📚 Library Organizer (Module‑based)", parent)

    elements:Toggle("Auto Organize Books", parent, false, function(state)
        autoOrganizeActive = state
        if autoOrganizeActive then
            -- Adjust camera for better view
            player.CameraMode = Enum.CameraMode.Classic
            player.CameraMinZoomDistance = 20
            task.spawn(function()
                task.wait(0.1)
                player.CameraMinZoomDistance = 0.5
            end)

            loopThread = task.spawn(function()
                while autoOrganizeActive do
                    local success, err = pcall(organizeBooks)
                    if not success then
                        warn("[TaperUI] Organize error:", err)
                    end
                    task.wait(5) -- longer delay between sweeps
                end
            end)
        else
            if loopThread then
                task.cancel(loopThread)
                loopThread = nil
            end
        end
    end)

    -- 11. Cleanup when UI tab is closed
    parent.Destroying:Connect(function()
        autoOrganizeActive = false
        if loopThread then
            task.cancel(loopThread)
        end
    end)

    print("✅ Book Organizer (TaperUI) loaded! Click the toggle to start.")
end