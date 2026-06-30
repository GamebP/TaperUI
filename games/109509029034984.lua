return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- Localized State Configuration
    local winFarmActive = false
    local loopInterval = 1.0 -- Default start delay (in seconds)
    local autoRebirthActive = false
    local requiredTrophiesString = "1K" -- Default target trophies
    local TARGET_POS = Vector3.new(-3204.50, 53.29, -20.50)

    -- Suffix multipliers to evaluate simulator values
    local suffixMultiplier = {
        K = 1e3,
        M = 1e6,
        B = 1e9,
        T = 1e12,
        QA = 1e15,
        QD = 1e15,
        QI = 1e18,
        QT = 1e18,
        SX = 1e21,
        SP = 1e24,
        OC = 1e27,
        NO = 1e30,
        NN = 1e30,
        DC = 1e33
    }

    -- Helper: Parses abbreviated formatted numbers (e.g., "1K", "5.4M") into raw numbers
    local function parseAbbreviatedNumber(str)
        if not str then return 0 end
        str = str:gsub(",", "")
        local numPart, suffixPart = str:match("([%d%.]+)%s*([%a]*)")
        if not numPart then return 0 end
        
        local num = tonumber(numPart) or 0
        if suffixPart and suffixPart ~= "" then
            local suffix = suffixPart:upper()
            local multiplier = suffixMultiplier[suffix]
            if multiplier then
                return num * multiplier
            end
        end
        return num
    end

    local requiredTrophies = parseAbbreviatedNumber(requiredTrophiesString)

    -- Helper: teleport local player to the designated position
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- Helper: Handles the clicking simulation safely on all executors
    local function clickButton(button)
        local clicked = false
        
        -- 1. Try firesignal (Most common exploit global)
        if typeof(firesignal) == "function" then
            local s1 = pcall(firesignal, button.MouseButton1Click)
            local s2 = pcall(firesignal, button.Activated)
            if s1 or s2 then
                clicked = true
            end
        end

        -- 2. Try getconnections (Alternative common exploit global)
        if not clicked then
            local getConnections = getconnections or get_signal_cons
            if typeof(getConnections) == "function" then
                local ok1, cons1 = pcall(getConnections, button.MouseButton1Click)
                local ok2, cons2 = pcall(getConnections, button.Activated)
                
                if ok1 and type(cons1) == "table" then
                    for _, connection in ipairs(cons1) do
                        pcall(function() connection:Fire() end)
                    end
                    clicked = true
                end
                if ok2 and type(cons2) == "table" then
                    for _, connection in ipairs(cons2) do
                        pcall(function() connection:Fire() end)
                    end
                    clicked = true
                end
            end
        end

        -- 3. Fallback to VirtualInputManager (Built-in engine simulation)
        if not clicked then
            local success, vim = pcall(game.GetService, game, "VirtualInputManager")
            if success and vim then
                local absPos = button.AbsolutePosition
                local absSize = button.AbsoluteSize
                local clickX = absPos.X + (absSize.X / 2)
                local clickY = absPos.Y + (absSize.Y / 2)
                
                -- Virtual click on center of the button
                pcall(function()
                    vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                    task.wait(0.01)
                    vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                end)
                clicked = true
            end
        end
    end

    -- Helper: Rebirth action via direct RemoteFunction, falling back to UI clicks
    local function performRebirth()
        local success, remote = pcall(function()
            return ReplicatedStorage.Remotes.AuraRunnerRebirth
        end)

        if success and remote and remote:IsA("RemoteFunction") then
            local ok, err = pcall(function()
                remote:InvokeServer()
            end)
            if ok then
                print("[AutoRebirth] Successfully invoked AuraRunnerRebirth RemoteFunction!")
                return true
            else
                warn("[AutoRebirth] Remote invocation failed:", tostring(err))
            end
        end

        -- Secondary Fallback: Use UI clicking if the remote path is missing/fails
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local ui = playerGui and playerGui:FindFirstChild("UI")
        local rebirth = ui and ui:FindFirstChild("Rebirth")
        local frame = rebirth and rebirth:FindFirstChild("Frame")
        local buttons = frame and frame:FindFirstChild("Buttons")
        local button = buttons and buttons:FindFirstChild("RebirthButton")

        if button then
            clickButton(button)
            print("[AutoRebirth] UI click fallback executed.")
            return true
        end

        warn("[AutoRebirth] All rebirth methods failed.")
        return false
    end

    -- Foolproof dynamic loop checking (Runs independently every 1.0 second)
    local loopRunning = false
    local function startRebirthLoop()
        loopRunning = false
        task.wait(0.1) -- settle previous threads
        loopRunning = true

        task.spawn(function()
            while loopRunning and autoRebirthActive do
                pcall(function()
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    local ui = playerGui and playerGui:FindFirstChild("UI")
                    
                    -- Find TrophyAmount dynamically
                    local hud = ui and ui:FindFirstChild("HUD")
                    local leftBar = hud and hud:FindFirstChild("LeftBar")
                    local stats = leftBar and leftBar:FindFirstChild("Statistics")
                    local trophies = stats and stats:FindFirstChild("Trophies")
                    local trophyAmount = trophies and trophies:FindFirstChild("TrophyAmount")

                    if trophyAmount then
                        local currentTrophies = parseAbbreviatedNumber(trophyAmount.Text)
                        
                        -- If trophies are equal or higher than the target, perform the rebirth
                        if currentTrophies >= requiredTrophies then
                            performRebirth()
                        end
                    end
                end)
                task.wait(1.0) -- Checking once per second to allow server processing
            end
        end)
    end

    -- Handle UI re-creation automatically on character respawn (after a rebirth)
    local characterAddedConn
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5) -- Settle physics loading before verifying state
        if autoRebirthActive then
            startRebirthLoop()
        end
    end)

    -- UI: Automation Utilities Section
    elements:Label("🔥 Automation Utilities", parent)

    -- Textbox to change how fast it transmits (in seconds)
    elements:Textbox("Transmit Interval (s)", parent, tostring(loopInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            loopInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number for the interval.")
        end
    end)

    -- Toggle to activate/deactivate the loop
    elements:Toggle("Auto Win Farm", parent, false, function(state)
        winFarmActive = state
        
        if winFarmActive then
            task.spawn(function()
                while winFarmActive do
                    teleportTo(TARGET_POS)
                    task.wait(loopInterval)
                end
            end)
        end
    end)

    -- Textbox to input custom trophy target limits (supports K, M, B, T, etc.)
    elements:Textbox("Trophy Target to Rebirth", parent, requiredTrophiesString, function(text)
        requiredTrophiesString = text
        requiredTrophies = parseAbbreviatedNumber(text)
        if autoRebirthActive then
            startRebirthLoop()
        end
    end)

    -- Toggle to activate/deactivate Auto Rebirth
    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        if autoRebirthActive then
            startRebirthLoop()
        else
            loopRunning = false
        end
    end)

    -- Clean up event connections upon UI uninject/destruction
    parent.Destroying:Connect(function()
        loopRunning = false
        if characterAddedConn then characterAddedConn:Disconnect() end
    end)
end