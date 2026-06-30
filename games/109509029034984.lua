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
    local loopInterval = 1.0 -- Default start delay (in seconds)
    local autoRebirthActive = false
    local requiredTrophiesString = "1K" -- Default target trophies set to 1K for the first rebirth

    -- Target coordinates for 50 Billion wins
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

        if not clicked then
            warn("[TaperUI] Click simulation failed: No supported methods (firesignal, getconnections, or VirtualInputManager) were successful.")
        end
    end

    -- Rebirth Listener references for garbage collection/updates
    local currentConnection = nil
    local currentTrophyConnection = nil
    local currentDestroyConnection = nil

    -- Helper: Setup the auto-rebirth listener for the active UI
    local function setupAutoRebirthListener()
        -- Clean up old connections if they exist to prevent memory leaks
        if currentConnection then currentConnection:Disconnect() currentConnection = nil end
        if currentTrophyConnection then currentTrophyConnection:Disconnect() currentTrophyConnection = nil end
        if currentDestroyConnection then currentDestroyConnection:Disconnect() currentDestroyConnection = nil end

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local ui = playerGui and playerGui:FindFirstChild("UI")
        local rebirth = ui and ui:FindFirstChild("Rebirth")
        local frame = rebirth and rebirth:FindFirstChild("Frame")
        local buttons = frame and frame:FindFirstChild("Buttons")
        local button = buttons and buttons:FindFirstChild("RebirthButton")

        local hud = ui and ui:FindFirstChild("HUD")
        local leftBar = hud and hud:FindFirstChild("LeftBar")
        local stats = leftBar and leftBar:FindFirstChild("Statistics")
        local trophies = stats and stats:FindFirstChild("Trophies")
        local trophyAmount = trophies and trophies:FindFirstChild("TrophyAmount")

        if not button then return end

        local function checkAndClick()
            if not autoRebirthActive then return end
            
            -- 1. Verify if the button is active (lit up)
            local color = button.ImageColor3
            local isLit = (color.R > 0.95 and color.G > 0.95 and color.B > 0.95)
            if not isLit then return end

            -- 2. Verify if the player has met the trophy requirement
            local currentTrophies = 0
            if trophyAmount and trophyAmount:IsA("TextLabel") then
                currentTrophies = parseAbbreviatedNumber(trophyAmount.Text)
            end

            if currentTrophies >= requiredTrophies then
                clickButton(button)
            end
        end

        -- Check when button color updates
        currentConnection = button:GetPropertyChangedSignal("ImageColor3"):Connect(checkAndClick)
        
        -- Check when trophy text updates
        if trophyAmount then
            currentTrophyConnection = trophyAmount:GetPropertyChangedSignal("Text"):Connect(checkAndClick)
        end

        checkAndClick()

        currentDestroyConnection = button.Destroying:Connect(function()
            if currentConnection then currentConnection:Disconnect() currentConnection = nil end
            if currentTrophyConnection then currentTrophyConnection:Disconnect() currentTrophyConnection = nil end
            if currentDestroyConnection then currentDestroyConnection:Disconnect() currentDestroyConnection = nil end
        end)
    end

    -- Handle UI re-creation automatically on character respawn (after a rebirth)
    local characterAddedCon
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5) -- Settle physics loading before verifying state
        if autoRebirthActive then
            setupAutoRebirthListener()
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
            setupAutoRebirthListener()
        end
    end)

    -- Toggle to activate/deactivate Auto Rebirth
    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        if autoRebirthActive then
            setupAutoRebirthListener()
        end
    end)

    -- Clean up event connections upon UI uninject/destruction
    parent.Destroying:Connect(function()
        if currentConnection then currentConnection:Disconnect() end
        if currentTrophyConnection then currentTrophyConnection:Disconnect() end
        if currentDestroyConnection then currentDestroyConnection:Disconnect() end
        if characterAddedConn then characterAddedConn:Disconnect() end
    end)
end