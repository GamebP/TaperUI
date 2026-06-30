return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- State
    local winFarmActive = false
    local loopInterval = 1.0
    local autoRebirthActive = false
    local requiredTrophiesString = "1K"
    local TARGET_POS = Vector3.new(-3204.50, 53.29, -20.50)

    -- Suffix multipliers
    local suffixMultiplier = {
        K = 1e3, M = 1e6, B = 1e9, T = 1e12,
        QA = 1e15, QD = 1e15, QI = 1e18, QT = 1e18,
        SX = 1e21, SP = 1e24, OC = 1e27, NO = 1e30,
        NN = 1e30, DC = 1e33
    }

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

    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- Click simulation (unchanged, robust)
    local function clickButton(button)
        local clicked = false
        if typeof(firesignal) == "function" then
            local s1 = pcall(firesignal, button.MouseButton1Click)
            local s2 = pcall(firesignal, button.Activated)
            if s1 or s2 then clicked = true end
        end
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
        if not clicked then
            local success, vim = pcall(game.GetService, game, "VirtualInputManager")
            if success and vim then
                local absPos = button.AbsolutePosition
                local absSize = button.AbsoluteSize
                local clickX = absPos.X + (absSize.X / 2)
                local clickY = absPos.Y + (absSize.Y / 2)
                pcall(function()
                    vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                    task.wait(0.01)
                    vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                end)
                clicked = true
            end
        end
        if not clicked then
            warn("[TaperUI] Click simulation failed.")
        end
        return clicked
    end

    -- Variables for polling
    local rebirthLoopConnection = nil
    local characterAddedConn = nil

    -- Helper to get UI references
    local function getUIElements()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return nil, nil end
        local ui = playerGui:FindFirstChild("UI")
        if not ui then return nil, nil end
        local rebirth = ui:FindFirstChild("Rebirth")
        if not rebirth then return nil, nil end
        local frame = rebirth:FindFirstChild("Frame")
        if not frame then return nil, nil end
        local buttons = frame:FindFirstChild("Buttons")
        if not buttons then return nil, nil end
        local button = buttons:FindFirstChild("RebirthButton")
        if not button then return nil, nil end

        local hud = ui:FindFirstChild("HUD")
        if not hud then return button, nil end
        local leftBar = hud:FindFirstChild("LeftBar")
        if not leftBar then return button, nil end
        local stats = leftBar:FindFirstChild("Statistics")
        if not stats then return button, nil end
        local trophies = stats:FindFirstChild("Trophies")
        if not trophies then return button, nil end
        local trophyAmount = trophies:FindFirstChild("TrophyAmount")
        return button, trophyAmount
    end

    -- Main polling function
    local function startRebirthLoop()
        if rebirthLoopConnection then
            rebirthLoopConnection:Disconnect()
            rebirthLoopConnection = nil
        end

        rebirthLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not autoRebirthActive then return end

            local button, trophyAmount = getUIElements()
            if not button then
                warn("[AutoRebirth] UI not ready – button missing")
                return
            end

            -- Check button lit state (adjust threshold if needed)
            local color = button.ImageColor3
            local isLit = (color.R > 0.95 and color.G > 0.95 and color.B > 0.95)
            if not isLit then
                -- Optionally log once in a while
                return
            end

            -- Get current trophies
            local currentTrophies = 0
            if trophyAmount and trophyAmount:IsA("TextLabel") then
                currentTrophies = parseAbbreviatedNumber(trophyAmount.Text)
            end

            -- Debug print every 10 seconds
            if tick() % 10 < 0.05 then
                print(string.format("[AutoRebirth] Trophies: %s (parsed: %.2e), Required: %.2e", 
                    trophyAmount and trophyAmount.Text or "??", currentTrophies, requiredTrophies))
            end

            if currentTrophies >= requiredTrophies then
                print("[AutoRebirth] Threshold met! Clicking rebirth button.")
                local clicked = clickButton(button)
                if clicked then
                    print("[AutoRebirth] Rebirth clicked successfully.")
                else
                    warn("[AutoRebirth] Rebirth click failed.")
                end
            end
        end)
    end

    -- Handle character respawn – restart polling
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        if autoRebirthActive then
            startRebirthLoop()
        end
    end)

    -- UI Elements
    elements:Label("🔥 Automation Utilities", parent)

    elements:Textbox("Transmit Interval (s)", parent, tostring(loopInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            loopInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number.")
        end
    end)

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

    elements:Textbox("Trophy Target to Rebirth", parent, requiredTrophiesString, function(text)
        requiredTrophiesString = text
        requiredTrophies = parseAbbreviatedNumber(text)
        if autoRebirthActive then
            -- Restart loop with new threshold
            startRebirthLoop()
        end
    end)

    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        if autoRebirthActive then
            startRebirthLoop()
        else
            if rebirthLoopConnection then
                rebirthLoopConnection:Disconnect()
                rebirthLoopConnection = nil
            end
        end
    end)

    parent.Destroying:Connect(function()
        if rebirthLoopConnection then rebirthLoopConnection:Disconnect() end
        if characterAddedConn then characterAddedConn:Disconnect() end
    end)
end