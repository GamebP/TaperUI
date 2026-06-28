return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- Localized State Configuration
    local winFarmActive = false
    local loopInterval = 0.5
    local selectedWorld = "World1"
    local selectedGate = "4"

    -- Helper to correct the off-screen layout clipping bug in the TaperUI library
    local function fixDropdownLayout(dropdown)
        if not dropdown then return end
        local header = dropdown:FindFirstChild("HeaderButton")
        local selectedLabel = header and header:FindFirstChild("SelectedLabel")
        if selectedLabel then
            selectedLabel.AnchorPoint = Vector2.new(1, 0)
            selectedLabel.Size = UDim2.new(0.5, 0, 1, 0)
            selectedLabel.Position = UDim2.new(1, -35, 0, 0)
        end
    end

    -- Dynamically discover Worlds and Gate Numbers from workspace.Goals
    local goals = workspace:FindFirstChild("Goals")
    local worlds = {}
    local gates = {}

    if goals then
        for _, world in ipairs(goals:GetChildren()) do
            if world.Name:match("^World%d+$") then
                if not table.find(worlds, world.Name) then
                    table.insert(worlds, world.Name)
                end
                for _, gate in ipairs(world:GetChildren()) do
                    if tonumber(gate.Name) and not table.find(gates, gate.Name) then
                        table.insert(gates, gate.Name)
                    end
                end
            end
        end
    end

    -- Sort discovered values numerically
    table.sort(worlds, function(a, b)
        return (tonumber(a:match("%d+")) or 0) < (tonumber(b:match("%d+")) or 0)
    end)

    table.sort(gates, function(a, b)
        return (tonumber(a) or 0) < (tonumber(b) or 0)
    end)

    -- Fallback configurations if Goals directory has not loaded
    if #worlds == 0 then
        worlds = {"World1", "World2", "World3", "World4"}
    end
    if #gates == 0 then
        for i = 1, 30 do
            table.insert(gates, tostring(i))
        end
    end

    -- Helper: Safely resolve the path to the selected target part
    local function getTargetPart()
        local success, part = pcall(function()
            return workspace.Goals[selectedWorld][selectedGate].Wins.Anchor
        end)
        return success and part or nil
    end

    -- Helper: Teleports you directly to the target part's CFrame
    local function teleportToPart()
        local targetPart = getTargetPart()
        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")

        if targetPart and rootPart then
            rootPart.CFrame = targetPart.CFrame
        else
            warn("[Error] Target part or your character's HumanoidRootPart was not found.")
        end
    end

    elements:Label("🔥 Automation Utilities", parent)

    -- Dropdown to pick the World
    local worldDropdown = elements:Dropdown("Select World", parent, worlds, selectedWorld, function(value)
        selectedWorld = value
    end)
    fixDropdownLayout(worldDropdown)

    -- Dropdown to pick the Win Anchor (Gate)
    local gateDropdown = elements:Dropdown("Select Win Anchor", parent, gates, selectedGate, function(value)
        selectedGate = value
    end)
    fixDropdownLayout(gateDropdown)

    -- Textbox to precisely change how fast it transmits (in seconds)
    elements:Textbox("Transmit Interval (s)", parent, tostring(loopInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            loopInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number for the interval.")
        end
    end)

    -- Toggle for Teleport Win Farm Loop
    elements:Toggle("Auto Win Farm", parent, false, function(state)
        winFarmActive = state
        
        if winFarmActive then
            task.spawn(function()
                while winFarmActive do
                    teleportToPart()
                    task.wait(loopInterval)
                end
            end)
        end
    end)
end