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

    -- 2. Direct physical requires (Bypasses the custom "Loader" class to avoid executor hook conflicts)
    local ReplicaController, BooksData
    local success, err = pcall(function()
        local Shared = ReplicatedStorage:WaitForChild("Shared")
        ReplicaController = require(Shared:WaitForChild("Utility"):WaitForChild("ReplicaController"))
        BooksData = require(Shared:WaitForChild("Data"):WaitForChild("Books"))
    end)

    if not success then
        warn("[TaperUI] Failed to load internal game modules directly:", err)
        elements:Label("⚠️ Error Loading Game Modules", parent)
        return
    end

    -- 3. Locate the Active Library Replica instance
    local LibraryReplica = nil
    for _, r in pairs(ReplicaController._replicas) do
        if r.Class == "Library" then
            LibraryReplica = r
            break
        end
    end

    if not LibraryReplica then
        ReplicaController.ReplicaOfClassCreated("Library", function(replica)
            LibraryReplica = replica
        end)
    end

    local Library = Workspace:FindFirstChild("Library")
    local BooksFolder = Library and Library:FindFirstChild("Books")

    -- Cache physical shelf models via tags
    local shelfModels = {}
    for _, shelfModel in ipairs(CollectionService:GetTagged("Shelf")) do
        shelfModels[shelfModel.Name] = shelfModel
    end

    -- 4. Sorting Decision Helpers
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

    local function findShelfForSeries(seriesName, genreName, volumeCount)
        -- Attempt to find a shelf already containing this specific series
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
        -- Alternatively, locate an empty, unassigned shelf of the same width
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
        if not LibraryReplica or not BooksFolder then return end
        
        for _, book in ipairs(BooksFolder:GetChildren()) do
            if not autoOrganizeActive then break end
            
            -- Match book series and volume index from name (e.g., FalseReports_1)
            local seriesName, volumeStr = book.Name:match("^(.-)_(.+)$")
            local volumeNum = tonumber(volumeStr)
            
            if seriesName and volumeNum then
                local genreName, bookInfo = BooksData.GetCategory(seriesName)
                if genreName and bookInfo then
                    local shelfModel = findShelfForSeries(seriesName, genreName, bookInfo.VolumeCount)
                    if shelfModel then
                        local shelfData = LibraryReplica.Data.Shelves[shelfModel.Name]
                        if not (shelfData and shelfData.Books[tostring(volumeNum)]) then
                            -- Teleport to target book and invoke replication Grab
                            teleportTo(book)
                            LibraryReplica:FireServer("Grab", book)
                            task.wait(0.12)
                            
                            -- Teleport to target shelf and invoke replication Place
                            teleportTo(shelfModel)
                            LibraryReplica:FireServer("Place", shelfModel, volumeNum - 1)
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
            if not LibraryReplica then
                -- Wait for replica initialization if run at startup
                task.spawn(function()
                    while autoOrganizeActive and not LibraryReplica do
                        task.wait(0.5)
                    end
                    if autoOrganizeActive then
                        loopThread = task.spawn(function()
                            while autoOrganizeActive do
                                pcall(organizeBooks)
                                task.wait(1.0)
                            end
                        end)
                    end
                end)
            else
                loopThread = task.spawn(function()
                    while autoOrganizeActive do
                        pcall(organizeBooks)
                        task.wait(1.0)
                    end
                end)
            end
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