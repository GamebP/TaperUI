return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- ===================== SERVICES =====================
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

    -- ===================== GAME REFS =====================
    local Library      = workspace:WaitForChild("Library", 15)
    local Genres       = Library and Library:WaitForChild("Genres", 15)
    local BookSpawns   = workspace:WaitForChild("BookSpawns", 15)
    local Blacklist    = Library and Library:WaitForChild("Blacklist", 15)

    -- ===================== GENRE MAPPING =====================
    -- Derived from DataModel: shelf prefix → genre model name
    local PREFIX_TO_GENRE = {
        ["1A"] = "Studio",     ["1B"] = "Simulators",  ["1D"] = "Myths",
        ["1E"] = "DevEx",      ["1F"] = "Rules",       ["1G"] = "Obby",
        ["1H"] = "Horror",     ["1I"] = "Economy",     ["1J"] = "History",
        ["2A"] = "Magic",      ["2C"] = "Meditation",  ["2D"] = "Military",
        ["2E"] = "Brainrot",
    }
    local GENRE_TO_PREFIX = {}
    for prefix, genre in pairs(PREFIX_TO_GENRE) do
        GENRE_TO_PREFIX[genre] = prefix
    end

    local ALL_GENRES = {}
    for _, g in pairs(PREFIX_TO_GENRE) do table.insert(ALL_GENRES, g) end
    table.sort(ALL_GENRES)

    -- Floor labels from map GUIs for quick reference
    local FLOOR_LABELS = {
        "1A","1B","1C","1D","1E","1F","1G","1H","1I","1J",  -- 1st floor
        "2A","2B","2C","2D","2E","2F"                        -- 2nd floor
    }

    -- ===================== STATE =====================
    local fullAutoActive   = false
    local autoCollectOnly  = false
    local autoSortOnly     = false
    local bookEspActive    = false
    local shelfEspActive   = false
    local loopInterval     = 1.5
    local sortDelay        = 1.0
    local heldGenre        = nil     -- cached genre of currently held book
    local skipBlacklist    = true    -- avoid teleporting into blacklisted zones

    -- Thread handles
    local fullAutoThread   = nil
    local collectThread    = nil
    local sortThread       = nil
    local espThread        = nil

    -- ESP object pool
    local espPool = {}

    -- Cached remote references
    local cachedSortRemotes = nil

    -- ===================== HELPERS =====================

    local function getRoot()
        local char = LocalPlayer.Character
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart")
    end

    local function teleportTo(pos)
        local root = getRoot()
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    local function getObjectPos(obj)
        if obj:IsA("BasePart") then return obj.Position end
        if obj:IsA("Model") then
            if obj.PrimaryPart then return obj.PrimaryPart.Position end
            local p = obj:FindFirstChildWhichIsA("BasePart")
            return p and p.Position
        end
        return nil
    end

    -- ===================== BOOK GENRE DETECTION =====================

    local function getBookGenre(book)
        if not book then return nil end

        --- Attribute scan
        for _, attr in ipairs({"Genre","Category","Type","BookGenre","ShelfGenre","SortCategory"}) do
            local v = book:GetAttribute(attr)
            if v and v ~= "" then
                -- Normalize to known genre
                for _, genre in ipairs(ALL_GENRES) do
                    if v:lower() == genre:lower() then return genre end
                end
                -- Could be a prefix like "1A"
                local pfx = v:match("^(%d[A-Z])")
                if pfx and PREFIX_TO_GENRE[pfx] then return PREFIX_TO_GENRE[pfx] end
                return v   -- return raw value even if unknown
            end
        end

        --- StringValue / ObjectValue children
        for _, valName in ipairs({"Genre","Category","Type","BookGenre","ShelfGenre"}) do
            local val = book:FindFirstChild(valName)
            if val and val:IsA("StringValue") and val.Value ~= "" then
                for _, genre in ipairs(ALL_GENRES) do
                    if val.Value:lower() == genre:lower() then return genre end
                end
                local pfx = val.Value:match("^(%d[A-Z])")
                if pfx and PREFIX_TO_GENRE[pfx] then return PREFIX_TO_GENRE[pfx] end
            end
        end

        --- Parse object name (e.g. "Book_Studio_1", "1A_Book", "MagicBook")
        local nameLower = book.Name:lower()
        for _, genre in ipairs(ALL_GENRES) do
            if nameLower:find(genre:lower()) then return genre end
        end
        local namePrefix = book.Name:match("^(%d[A-Z])")
        if namePrefix and PREFIX_TO_GENRE[namePrefix] then
            return PREFIX_TO_GENRE[namePrefix]
        end

        --- Parent chain – if book is inside a shelf's Books folder
        local parent = book.Parent
        if parent then
            if parent.Name == "Books" and parent.Parent then
                local shelfName = parent.Parent.Name
                local sp = shelfName:match("^(%d[A-Z])")
                if sp and PREFIX_TO_GENRE[sp] then return PREFIX_TO_GENRE[sp] end
            end
            local pp = parent.Name:match("^(%d[A-Z])")
            if pp and PREFIX_TO_GENRE[pp] then return PREFIX_TO_GENRE[pp] end
        end

        --- Descendant TextLabels / SurfaceGuis / BillboardGuis
        for _, desc in ipairs(book:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                local t = desc.Text
                if t and t ~= "" then
                    for _, genre in ipairs(ALL_GENRES) do
                        if t:lower():find(genre:lower()) then return genre end
                    end
                    local tp = t:match("(%d[A-Z])")
                    if tp and PREFIX_TO_GENRE[tp] then return PREFIX_TO_GENRE[tp] end
                end
            end
        end

        return nil
    end

    -- ===================== FIND UNSORTED BOOKS =====================

    local function findUnsortedBooks()
        local books = {}

        -- Primary: BookSpawns folder
        if BookSpawns then
            for _, child in ipairs(BookSpawns:GetChildren()) do
                if child:IsA("Model") or child:IsA("Part") then
                    table.insert(books, child)
                end
            end
            -- Some games nest deeper
            for _, child in ipairs(BookSpawns:GetDescendants()) do
                if child:IsA("Model") or child:IsA("Part") then
                    if child.Name:lower():find("book") then
                        table.insert(books, child)
                    end
                end
            end
        end

        -- Secondary: Scan workspace top-level for book objects
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name:lower():find("book") and child ~= BookSpawns then
                if child:IsA("Model") or child:IsA("Part") then
                    -- Exclude books already inside genre shelves
                    local inShelf = false
                    local p = child.Parent
                    while p do
                        if p == Genres then inShelf = true; break end
                        p = p.Parent
                    end
                    if not inShelf then table.insert(books, child) end
                end
            end
        end

        return books
    end

    -- ===================== SHELF LOOKUP =====================

    local function findNearestShelf(genre, fromPos)
        if not Genres then return nil, nil end
        local genreModel = Genres:FindFirstChild(genre)
        if not genreModel then return nil, nil end

        local bestPos, bestShelf, bestDist = nil, nil, math.huge
        for _, shelf in ipairs(genreModel:GetChildren()) do
            if shelf:IsA("Model") then
                local base = shelf:FindFirstChild("Base")
                if base then
                    local pos = base.Position + Vector3.new(0, 3, 0)
                    local dist = (pos - fromPos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestPos  = pos
                        bestShelf = shelf
                    end
                end
            end
        end
        return bestPos, bestShelf
    end

    -- Returns ALL shelf positions for a genre (for cycling through them)
    local function getAllShelfPositions(genre)
        if not Genres then return {} end
        local genreModel = Genres:FindFirstChild(genre)
        if not genreModel then return {} end

        local positions = {}
        for _, shelf in ipairs(genreModel:GetChildren()) do
            if shelf:IsA("Model") then
                local base = shelf:FindFirstChild("Base")
                if base then
                    table.insert(positions, {
                        pos   = base.Position + Vector3.new(0, 3, 0),
                        shelf = shelf,
                        name  = shelf.Name
                    })
                end
            end
        end
        -- Sort by name for consistent ordering
        table.sort(positions, function(a, b) return a.name < b.name end)
        return positions
    end

    -- ===================== INTERACTION =====================

    local function interactWith(obj)
        if not obj then return false end

        -- ProximityPrompt
        for _, desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function()
                    fireproximityprompt(desc)
                end)
                return true
            end
        end

        -- ClickDetector
        for _, desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("ClickDetector") then
                pcall(function()
                    fireclickdetector(desc)
                end)
                return true
            end
        end

        return false
    end

    -- ===================== REMOTE SORTING =====================

    local function discoverSortRemotes()
        if cachedSortRemotes then return cachedSortRemotes end
        cachedSortRemotes = {}
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                local n = desc.Name:lower()
                if n:find("sort") or n:find("place") or n:find("shelve")
                    or n:find("return") or n:find("deposit") or n:find("put")
                    or n:find("book") or n:find("collect") or n:find("grab")
                    or n:find("pickup") or n:find("deliver") then
                    table.insert(cachedSortRemotes, desc)
                end
            end
        end
        return cachedSortRemotes
    end

    local function fireSortRemotes(book, shelf)
        local remotes = discoverSortRemotes()
        for _, remote in ipairs(remotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                    remote:FireServer(book)
                    remote:FireServer(book, shelf)
                    remote:FireServer(shelf)
                    remote:FireServer(shelf.Name)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer()
                    remote:InvokeServer(book)
                    remote:InvokeServer(book, shelf)
                    remote:InvokeServer(shelf)
                    remote:InvokeServer(shelf.Name)
                end
            end)
        end
    end

    -- ===================== CORE ACTIONS =====================

    local function collectBook(book)
        local root = getRoot()
        if not root then return false, nil end

        local pos = getObjectPos(book)
        if not pos then return false, nil end

        -- Check if position is in a blacklisted zone
        if skipBlacklist and Blacklist then
            for _, bp in ipairs(Blacklist:GetChildren()) do
                if bp:IsA("BasePart") then
                    if (bp.Position - pos).Magnitude < bp.Size.Magnitude / 2 then
                        return false, nil  -- skip blacklisted
                    end
                end
            end
        end

        teleportTo(pos + Vector3.new(0, 2, 0))
        task.wait(0.35)

        -- Try interaction methods
        interactWith(book)
        fireSortRemotes(book, nil)  -- some games use remotes for pickup

        local genre = getBookGenre(book)
        return true, genre
    end

    local function sortBookToShelf(genre)
        if not genre then return false end

        local root = getRoot()
        if not root then return false end

        local shelfPos, shelf = findNearestShelf(genre, root.Position)
        if not shelfPos or not shelf then return false end

        teleportTo(shelfPos)
        task.wait(sortDelay)

        -- Fire remotes for server-side sorting
        fireSortRemotes(nil, shelf)

        -- Interaction-based sorting
        interactWith(shelf)

        -- Also try the HoverArea (some games use it for placement)
        local hover = shelf:FindFirstChild("HoverArea")
        if hover then
            interactWith(hover)
        end

        return true
    end

    -- ===================== LOOP WORKERS =====================

    -- Full Auto: Collect → Detect Genre → Sort → Repeat
    local function startFullAuto()
        if fullAutoThread then task.cancel(fullAutoThread) end
        fullAutoThread = task.spawn(function()
            while fullAutoActive do
                pcall(function()
                    local books = findUnsortedBooks()
                    if #books == 0 then
                        task.wait(loopInterval)
                        return  -- no books found this cycle
                    end

                    -- Sort books by distance for efficiency
                    local root = getRoot()
                    if root then
                        table.sort(books, function(a, b)
                            local pa, pb = getObjectPos(a), getObjectPos(b)
                            if not pa then return false end
                            if not pb then return true end
                            return (pa - root.Position).Magnitude < (pb - root.Position).Magnitude
                        end)
                    end

                    for _, book in ipairs(books) do
                        if not fullAutoActive then break end
                        if book and book.Parent then
                            local success, genre = collectBook(book)
                            if success then
                                heldGenre = genre
                                task.wait(sortDelay)
                                if genre then
                                    local sorted = sortBookToShelf(genre)
                                    if sorted then
                                        print("[AutoSort] ✓ Sorted book → " .. genre)
                                    end
                                else
                                    warn("[AutoSort] ⚠ Could not detect genre for: " .. book.Name)
                                end
                                heldGenre = nil
                                break  -- process one book per cycle
                            end
                        end
                    end
                end)
                task.wait(loopInterval)
            end
        end)
    end

    -- Auto Collect Only
    local function startAutoCollect()
        if collectThread then task.cancel(collectThread) end
        collectThread = task.spawn(function()
            while autoCollectOnly do
                pcall(function()
                    local books = findUnsortedBooks()
                    local root = getRoot()
                    if root and #books > 0 then
                        table.sort(books, function(a, b)
                            local pa, pb = getObjectPos(a), getObjectPos(b)
                            if not pa then return false end
                            if not pb then return true end
                            return (pa - root.Position).Magnitude < (pb - root.Position).Magnitude
                        end)
                        for _, book in ipairs(books) do
                            if not autoCollectOnly then break end
                            if book and book.Parent then
                                local success, genre = collectBook(book)
                                if success then
                                    heldGenre = genre
                                    break
                                end
                            end
                        end
                    end
                end)
                task.wait(loopInterval)
            end
        end)
    end

    -- Auto Sort Only (sorts whatever book you're holding)
    local function startAutoSort()
        if sortThread then task.cancel(sortThread) end
        sortThread = task.spawn(function()
            while autoSortOnly do
                pcall(function()
                    -- Try to detect held book from character or backpack
                    if not heldGenre then
                        local char = LocalPlayer.Character
                        if char then
                            for _, child in ipairs(char:GetChildren()) do
                                if child:IsA("Tool") or child.Name:lower():find("book") then
                                    heldGenre = getBookGenre(child)
                                    if heldGenre then break end
                                end
                            end
                        end
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        if bp and not heldGenre then
                            for _, child in ipairs(bp:GetChildren()) do
                                if child:IsA("Tool") or child.Name:lower():find("book") then
                                    heldGenre = getBookGenre(child)
                                    if heldGenre then break end
                                end
                            end
                        end
                    end

                    if heldGenre then
                        local success = sortBookToShelf(heldGenre)
                        if success then
                            print("[AutoSort] ✓ Sorted → " .. heldGenre)
                            heldGenre = nil
                        end
                    end
                end)
                task.wait(loopInterval)
            end
        end)
    end

    -- ===================== ESP SYSTEM =====================

    local function clearEsp()
        for _, obj in ipairs(espPool) do
            pcall(function() obj:Destroy() end)
        end
        espPool = {}
    end

    local GENRE_COLORS = {
        Studio     = Color3.fromRGB(255, 165, 0),
        Simulators = Color3.fromRGB(0, 200, 255),
        Myths      = Color3.fromRGB(148, 0, 211),
        DevEx      = Color3.fromRGB(0, 255, 127),
        Rules      = Color3.fromRGB(255, 255, 100),
        Obby       = Color3.fromRGB(255, 69, 0),
        Horror     = Color3.fromRGB(139, 0, 0),
        Economy    = Color3.fromRGB(255, 215, 0),
        History    = Color3.fromRGB(160, 82, 45),
        Magic      = Color3.fromRGB(138, 43, 226),
        Meditation = Color3.fromRGB(64, 224, 208),
        Military   = Color3.fromRGB(85, 107, 47),
        Brainrot   = Color3.fromRGB(255, 105, 180),
    }

    local function getGenreColor(genre)
        return GENRE_COLORS[genre] or Color3.fromRGB(255, 255, 255)
    end

    local function updateBookEsp()
        clearEsp()
        if not bookEspActive then return end

        local books = findUnsortedBooks()
        for _, book in ipairs(books) do
            if book and book.Parent then
                local genre = getBookGenre(book)
                local color = getGenreColor(genre)
                local label = genre and (genre .. " [" .. (GENRE_TO_PREFIX[genre] or "?") .. "]") or "❓ Unknown"

                -- Determine adornee
                local adornee = book
                if book:IsA("Model") and not book.PrimaryPart then
                    adornee = book:FindFirstChildWhichIsA("BasePart") or book
                end

                -- Highlight
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_HL"
                hl.Adornee = adornee
                hl.FillColor = color
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.FillTransparency = 0.55
                hl.OutlineTransparency = 0
                hl.Parent = book
                table.insert(espPool, hl)

                -- Billboard label
                local basePart = book:IsA("BasePart") and book
                    or (book:IsA("Model") and (book.PrimaryPart or book:FindFirstChildWhichIsA("BasePart")))
                    or nil

                if basePart then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ESP_Label"
                    bb.Adornee = basePart
                    bb.Size = UDim2.new(0, 140, 0, 28)
                    bb.StudsOffset = Vector3.new(0, 3.5, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = book

                    local txt = Instance.new("TextLabel")
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 0.35
                    txt.BackgroundColor3 = Color3.new(0, 0, 0)
                    txt.TextColor3 = color
                    txt.Text = label
                    txt.Font = Enum.Font.GothamBold
                    txt.TextScaled = true
                    txt.Parent = bb

                    local stroke = Instance.new("UIStroke")
                    stroke.Color = Color3.new(0, 0, 0)
                    stroke.Thickness = 1.5
                    stroke.Parent = txt

                    table.insert(espPool, bb)
                end
            end
        end
    end

    local function updateShelfEsp()
        if not shelfEspActive or not Genres then return end

        for _, genreModel in ipairs(Genres:GetChildren()) do
            if genreModel:IsA("Model") then
                local genreName = genreModel.Name
                local color = getGenreColor(genreName)
                local prefix = GENRE_TO_PREFIX[genreName] or "?"

                for _, shelf in ipairs(genreModel:GetChildren()) do
                    if shelf:IsA("Model") and not shelf:FindFirstChild("ShelfESP_HL") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ShelfESP_HL"
                        hl.Adornee = shelf
                        hl.FillColor = color
                        hl.OutlineColor = Color3.new(1, 1, 1)
                        hl.FillTransparency = 0.8
                        hl.OutlineTransparency = 0.3
                        hl.Parent = shelf
                        table.insert(espPool, hl)

                        local base = shelf:FindFirstChild("Base")
                        if base then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "ShelfESP_Label"
                            bb.Adornee = base
                            bb.Size = UDim2.new(0, 120, 0, 24)
                            bb.StudsOffset = Vector3.new(0, 5, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = shelf

                            local txt = Instance.new("TextLabel")
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 0.4
                            txt.BackgroundColor3 = Color3.new(0, 0, 0)
                            txt.TextColor3 = color
                            txt.Text = prefix .. " - " .. genreName
                            txt.Font = Enum.Font.GothamBold
                            txt.TextScaled = true
                            txt.Parent = bb
                            table.insert(espPool, bb)
                        end
                    end
                end
            end
        end
    end

    local function startEspLoop()
        if espThread then task.cancel(espThread) end
        espThread = task.spawn(function()
            while bookEspActive or shelfEspActive do
                pcall(function()
                    if bookEspActive then updateBookEsp() end
                    if shelfEspActive then updateShelfEsp() end
                end)
                task.wait(2.5)
            end
            clearEsp()
        end)
    end

    -- ===================== QUICK TELEPORT =====================

    local function teleportToGenre(input)
        -- Accept genre name or shelf prefix
        local genre = nil

        -- Try direct genre name match
        for _, g in ipairs(ALL_GENRES) do
            if g:lower() == input:lower() then
                genre = g
                break
            end
        end

        -- Try prefix match (e.g. "1A", "2E")
        if not genre then
            local prefix = input:match("^(%d[A-Z])") or input:upper():match("^(%d[A-Z])")
            if prefix and PREFIX_TO_GENRE[prefix] then
                genre = PREFIX_TO_GENRE[prefix]
            end
        end

        if not genre then
            warn("[AutoSort] Unknown genre/prefix: " .. input)
            return
        end

        local root = getRoot()
        if not root then return end

        local pos, _ = findNearestShelf(genre, root.Position)
        if pos then
            teleportTo(pos)
            print("[AutoSort] Teleported to " .. genre .. " shelves")
        else
            warn("[AutoSort] No shelf found for genre: " .. genre)
        end
    end

    -- ===================== REMOTE SCANNER =====================

    local function scanAndPrintRemotes()
        print("\n===== REMOTE SCAN =====")
        local count = 0
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                count = count + 1
                print(string.format("  [%s] %s", desc.ClassName, desc:GetFullName()))
            end
        end
        print(string.format("  Total: %d remotes found", count))
        print("========================\n")
    end

    -- ===================== CHARACTER RESPAWN =====================

    local charAddedConn
    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        heldGenre = nil
        if fullAutoActive  then startFullAuto()    end
        if autoCollectOnly then startAutoCollect() end
        if autoSortOnly    then startAutoSort()    end
    end)

    -- ========================================================
    -- ===================== TAPER UI =========================
    -- ========================================================

    -- ── Section: Main Automation ──
    elements:Label("📚 Library Auto-Sort", parent)

    elements:Toggle("Full Auto (Collect → Sort)", parent, false, function(state)
        fullAutoActive = state
        if fullAutoActive then
            -- Disable individual toggles to avoid conflicts
            autoCollectOnly = false
            autoSortOnly = false
            startFullAuto()
        else
            if fullAutoThread then task.cancel(fullAutoThread); fullAutoThread = nil end
        end
    end)

    elements:Toggle("Auto Collect Only", parent, false, function(state)
        autoCollectOnly = state
        if autoCollectOnly then
            fullAutoActive = false
            if fullAutoThread then task.cancel(fullAutoThread); fullAutoThread = nil end
            startAutoCollect()
        else
            if collectThread then task.cancel(collectThread); collectThread = nil end
        end
    end)

    elements:Toggle("Auto Sort (Held Book)", parent, false, function(state)
        autoSortOnly = state
        if autoSortOnly then
            fullAutoActive = false
            if fullAutoThread then task.cancel(fullAutoThread); fullAutoThread = nil end
            startAutoSort()
        else
            if sortThread then task.cancel(sortThread); sortThread = nil end
        end
    end)

    -- ── Section: Timing Controls ──
    elements:Label("⏱ Timing Controls", parent)

    elements:Slider("Loop Interval (s)", parent, 0.5, 5.0, loopInterval, 1, function(val)
        loopInterval = val
    end)

    elements:Slider("Sort Delay (s)", parent, 0.3, 3.0, sortDelay, 1, function(val)
        sortDelay = val
    end)

    -- ── Section: ESP ──
    elements:Label("🔍 Visual ESP", parent)

    elements:Toggle("Book ESP (Genre Labels)", parent, false, function(state)
        bookEspActive = state
        if bookEspActive or shelfEspActive then
            startEspLoop()
        else
            clearEsp()
            if espThread then task.cancel(espThread); espThread = nil end
        end
    end)

    elements:Toggle("Shelf ESP (Genre Colors)", parent, false, function(state)
        shelfEspActive = state
        if bookEspActive or shelfEspActive then
            startEspLoop()
        else
            clearEsp()
            if espThread then task.cancel(espThread); espThread = nil end
        end
    end)

    -- ── Section: Quick Teleport ──
    elements:Label("🚀 Quick Teleport to Genre", parent)

    elements:Textbox("Genre or Prefix (e.g. Magic / 2A)", parent, "", function(text)
        if text and text ~= "" then
            teleportToGenre(text)
        end
    end)

    -- ── Section: Genre Reference ──
    elements:Label("📋 Genre → Shelf Reference", parent)

    local refText = ""
    for _, genre in ipairs(ALL_GENRES) do
        local prefix = GENRE_TO_PREFIX[genre] or "?"
        refText = refText .. prefix .. " = " .. genre .. "  |  "
    end
    elements:Textbox("Reference (read-only)", parent, refText, function() end)

    -- ── Section: Debug / Utility ──
    elements:Label("🔧 Debug & Utilities", parent)

    elements:Textbox("Type 'scan' to list all remotes", parent, "", function(text)
        if text:lower() == "scan" then
            scanAndPrintRemotes()
        end
    end)

    elements:Textbox("Type 'detect' to check held book", parent, "", function(text)
        if text:lower() == "detect" then
            local char = LocalPlayer.Character
            local found = false
            if char then
                for _, child in ipairs(char:GetChildren()) do
                    if child:IsA("Tool") or child.Name:lower():find("book") then
                        local genre = getBookGenre(child)
                        print("[AutoSort] Held: " .. child.Name .. " → Genre: " .. tostring(genre or "Unknown"))
                        found = true
                    end
                end
            end
            if not found then
                print("[AutoSort] No book currently held in character")
            end
        end
    end)

    elements:Textbox("Type 'books' to count unsorted", parent, "", function(text)
        if text:lower() == "books" then
            local books = findUnsortedBooks()
            print("[AutoSort] Unsorted books found: " .. #books)
            for i, book in ipairs(books) do
                if i > 10 then print("  ... and " .. (#books - 10) .. " more"); break end
                local genre = getBookGenre(book)
                print(string.format("  [%d] %s → %s", i, book.Name, genre or "Unknown"))
            end
        end
    end)

    -- ===================== CLEANUP =====================
    parent.Destroying:Connect(function()
        fullAutoActive  = false
        autoCollectOnly = false
        autoSortOnly    = false
        bookEspActive   = false
        shelfEspActive  = false

        if fullAutoThread then task.cancel(fullAutoThread) end
        if collectThread  then task.cancel(collectThread)  end
        if sortThread     then task.cancel(sortThread)     end
        if espThread      then task.cancel(espThread)      end
        if charAddedConn  then charAddedConn:Disconnect()  end

        clearEsp()
    end)

    print("[Library AutoSort] Loaded! Genres: " .. table.concat(ALL_GENRES, ", "))
end