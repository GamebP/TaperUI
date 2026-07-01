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
    
    local player = Players.LocalPlayer
    local autoOrganizeActive = false
    local loopThread = nil

    -- 2. Dynamically build Books database from ReplicatedStorage to avoid requiring any modules
    local BooksMap = {}
    local success, err = pcall(function()
        local Assets = ReplicatedStorage:WaitForChild("Assets")
        local Books = Assets:WaitForChild("Books")
        for _, categoryFolder in ipairs(Books:GetChildren()) do
            for _, seriesFolder in ipairs(categoryFolder:GetChildren()) do
                local seriesName = seriesFolder.Name
                local volumeCount = #seriesFolder:GetChildren()
                BooksMap[seriesName] = {
                    Genre = categoryFolder.Name,
                    VolumeCount = volumeCount
                }
            end
        end
    end)

    if not success then
        warn("[TaperUI] Failed to build Books database from Assets:", err)
        elements:Label("⚠️ Error Parsing Book Data", parent)
        return
    end

    -- 3. Garbage Collector scanner to find the active replica safely
    local LibraryReplica = nil
    local function getLibraryReplica()
        if LibraryReplica then return LibraryReplica end
        
        local success, gc = pcall(getgc, true)
        if not success then return nil end
        
        for _, obj in ipairs(gc) do
            if type(obj) == "table" and rawget(obj, "Class") == "Library" and type(rawget(obj, "Data")) == "table" then
                LibraryReplica = obj
                return obj
            end
        end
        return nil
    end

    local Library = Workspace:FindFirstChild("Library")
    local BooksFolder = Library and Library:FindFirstChild("Books")

    -- Cache physical shelf models via tags
    local shelfModels = {}
    for _, shelfModel in ipairs(CollectionService:GetTagged("Shelf")) do
        shelfModels[shelfModel.Name] = shelfModel
    end

    -- 4. Sorting Decision Helpers
    local function getShelfAssignedSeries(replica, shelfId)
        local shelfData = replica.Data.Shelves[shelfId]
        if not shelfData then return nil end
        for _, placedBook in pairs(shelfData.Books) do
            local bookName = typeof(placedBook) == "Instance" and placedBook.Name or placedBook
            local seriesName = bookName:match("^(.-)_(.+)$")
            if seriesName then return seriesName end
        end
        return nil
    end

    local function findShelfForSeries(replica, seriesName, genreName, volumeCount)
        -- Attempt to find a shelf already containing this specific series
        for shelfId, shelfData in pairs(replica.Data.Shelves) do
            if not shelfData.Completed and shelfData.Category == genreName then
                local shelfModel = shelfModels[shelfId]
                if shelfModel and shelfModel:GetAttribute("Width") == volumeCount then
                    if getShelfAssignedSeries(replica, shelfId) == seriesName then
                        return shelfModel
                    end
                end
            end
        end
        -- Alternatively, locate an empty, unassigned shelf of the same width
        for shelfId, shelfData in pairs(replica.Data.Shelves) do
            if not shelfData.Completed and shelfData.Category == genreName then
                local shelfModel = shelfModels[shelfId]
                if shelfModel and shelfModel:GetAttribute("Width") == volumeCount then
                    if not getShelfAssignedSeries(replica, shelfId) and next(shelfData.Books) == nil then
                        return shelfModel
                    end
                end
            end
        end
        return nil
    end

    local function teleportTo(obj)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")) or obj
        if root and part then
            root.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
            task.wait(0.08) -- Minimum physics latency allowance
        end
    end

    -- 5. Main Sorting Execution
    local function organizeBooks()
        local replica = getLibraryReplica()
        if not replica or not BooksFolder then return end
        
        for _, book in ipairs(BooksFolder:GetChildren()) do
            if not autoOrganizeActive then break end
            
            -- Match book series and volume index from name (e.g., FalseReports_1)
            local seriesName, volumeStr = book.Name:match("^(.-)_(.+)$")
            local volumeNum = tonumber(volumeStr)
            
            if seriesName and volumeNum then
                local bookInfo = BooksMap[seriesName]
                if bookInfo then
                    local shelfModel = findShelfForSeries(replica, seriesName, bookInfo.Genre, bookInfo.VolumeCount)
                    if shelfModel then
                        local shelfData = replica.Data.Shelves[shelfModel.Name]
                        if not (shelfData and shelfData.Books[tostring(volumeNum)]) then
                            -- Teleport to target book and invoke replication Grab
                            teleportTo(book)
                            replica:FireServer("Grab", book)
                            task.wait(0.12)
                            
                            -- Teleport to target shelf and invoke replication Place
                            teleportTo(shelfModel)
                            replica:FireServer("Place", shelfModel, volumeNum - 1)
                            task.wait(0.4) -- Settle buffer to prevent server disconnects
                        end
                    end
                end
            end
        end
    end

    -- 6. Setup Visual Interface Elements
    elements:Label("📚 Library Clean Up", parent)

    elements:Toggle("Auto Organize Books", parent, false, function(state)
        autoOrganizeActive = state
        if autoOrganizeActive then
            loopThread = task.spawn(function()
                while autoOrganizeActive do
                    pcall(organizeBooks)
                    task.wait(1.0)
                end
            end)
        else
            if loopThread then
                task.cancel(loopThread)
                loopThread = nil
            end
        end
    end)

    -- 7. Memory Leak Cleanup on Tab/UI Close
    parent.Destroying:Connect(function()
        autoOrganizeActive = false
        if loopThread then
            task.cancel(loopThread)
        end
    end)
end