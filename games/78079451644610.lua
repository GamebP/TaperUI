return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local CollectionService = game:GetService("CollectionService")
    
    local player = Players.LocalPlayer
    local autoOrganizeActive = false
    local loopThread = nil

    -- Load game modules
    local ReplicaController, BooksData
    local ok, err = pcall(function()
        ReplicaController = require(ReplicatedStorage.Shared.Utility.ReplicaController)
        BooksData = require(ReplicatedStorage.Shared.Data.Books)
    end)
    if not ok then
        elements:Label("❌ Failed to load modules: " .. tostring(err), parent)
        return
    end

    -- Get LibraryReplica
    local LibraryReplica
    for _, r in pairs(ReplicaController._replicas) do
        if r.Class == "Library" then LibraryReplica = r break end
    end
    if not LibraryReplica then
        ReplicaController.ReplicaOfClassCreated("Library", function(r) LibraryReplica = r end)
        while not LibraryReplica do task.wait() end
    end

    local Library = Workspace:FindFirstChild("Library")
    if not Library then elements:Label("❌ Library not found", parent) return end
    local BooksFolder = Library:FindFirstChild("Books")
    if not BooksFolder then elements:Label("❌ Books folder not found", parent) return end

    -- Cache shelf models
    local shelfModels = {}
    for _, shelf in ipairs(CollectionService:GetTagged("Shelf")) do
        shelfModels[shelf.Name] = shelf
    end

    -- Helper: get series name from a book model name (assumes "SeriesName_Volume")
    local function getSeriesAndVolume(bookName)
        local series, vol = bookName:match("^(.-)_(%d+)$")
        if series and vol then
            return series, tonumber(vol)
        end
        return nil, nil
    end

    -- Helper: check if a book is already placed on any shelf
    local function isBookPlaced(book)
        for _, shelfData in pairs(LibraryReplica.Data.Shelves) do
            for _, placed in pairs(shelfData.Books) do
                if placed == book then
                    return true
                end
            end
        end
        return false
    end

    -- Helper: find the best shelf for a series (same as before)
    local function findShelfForSeries(seriesName, genreName, volumeCount)
        -- First, try a shelf already assigned to this series
        for shelfId, shelfData in pairs(LibraryReplica.Data.Shelves) do
            if not shelfData.Completed and shelfData.Category == genreName then
                local shelfModel = shelfModels[shelfId]
                if shelfModel and shelfModel:GetAttribute("Width") == volumeCount then
                    -- Check if this shelf is already holding books of this series
                    local assignedSeries
                    for _, placedBook in pairs(shelfData.Books) do
                        local s, _ = getSeriesAndVolume(placedBook.Name)
                        if s then assignedSeries = s break end
                    end
                    if assignedSeries == seriesName then
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
                    if next(shelfData.Books) == nil then
                        return shelfModel
                    end
                end
            end
        end
        return nil
    end

    -- Teleport helper
    local function teleportTo(obj)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
        if root and part then
            root.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
            task.wait(0.05)
        end
    end

    -- Main sorting routine (fixed)
    local function organizeBooks()
        for _, book in ipairs(BooksFolder:GetChildren()) do
            if not autoOrganizeActive then break end
            task.wait(0.02)

            local seriesName, volumeNum = getSeriesAndVolume(book.Name)
            if not seriesName or not volumeNum then continue end

            local genreName, bookInfo = BooksData.GetCategory(seriesName)
            if not genreName or not bookInfo then continue end

            local shelfModel = findShelfForSeries(seriesName, genreName, bookInfo.VolumeCount)
            if not shelfModel then continue end

            local shelfData = LibraryReplica.Data.Shelves[shelfModel.Name]
            -- Use 0‑based index for the slot
            local slotIndex = volumeNum - 1

            -- Check if this volume is already on this shelf at the correct slot
            local alreadyPlaced = shelfData and shelfData.Books[slotIndex] == book

            if not alreadyPlaced then
                -- If the book is already placed somewhere else, we need to grab it first
                if isBookPlaced(book) then
                    teleportTo(book)
                    LibraryReplica:FireServer("Grab", book)
                    task.wait(0.1)
                end
                -- Now teleport to the shelf and place it
                teleportTo(shelfModel)
                LibraryReplica:FireServer("Place", shelfModel, slotIndex)
                task.wait(0.4)
            end
        end
    end

    -- UI
    elements:Label("📚 Library Organizer (fixed)", parent)

    elements:Toggle("Auto Organize Books", parent, false, function(state)
        autoOrganizeActive = state
        if autoOrganizeActive then
            player.CameraMode = Enum.CameraMode.Classic
            player.CameraMinZoomDistance = 20
            task.spawn(function()
                task.wait(0.1)
                player.CameraMinZoomDistance = 0.5
            end)
            loopThread = task.spawn(function()
                while autoOrganizeActive do
                    pcall(organizeBooks)
                    task.wait(5)
                end
            end)
        else
            if loopThread then
                task.cancel(loopThread)
                loopThread = nil
            end
        end
    end)

    parent.Destroying:Connect(function()
        autoOrganizeActive = false
        if loopThread then
            task.cancel(loopThread)
        end
    end)

    print("✅ Book Organizer (fixed) loaded!")
end