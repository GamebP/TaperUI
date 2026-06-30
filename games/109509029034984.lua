return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
            local multiplier = suffixMultiplier[suffixPart:upper()]
            if multiplier then return num * multiplier end
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

    -- ===== REBIRTH EXECUTION (REMOTE ONLY) =====
    local function performRebirth()
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AuraRunnerRebirth")
        if remote and remote:IsA("RemoteFunction") then
            local success, result = pcall(function()
                -- Invoking the RemoteFunction with the verified handshake string "AuraRunnerRebirth"
                return remote:InvokeServer("AuraRunnerRebirth")
            end)
            if success then
                print("[AutoRebirth] RemoteFunction invocation successful!")
                return true
            else
                warn("[AutoRebirth] RemoteFunction failed:", tostring(result))
            end
        else
            warn("[AutoRebirth] Rebirth RemoteFunction ('AuraRunnerRebirth') not found under ReplicatedStorage.Remotes.")
        end
        return false
    end

    -- ===== AUTO REBIRTH LOOP =====
    local loopActive = false
    local loopThread = nil

    local function startRebirthLoop()
        if loopThread then
            loopActive = false
            task.wait(0.1)
        end
        loopActive = true
        loopThread = task.spawn(function()
            while loopActive and autoRebirthActive do
                pcall(function()
                    -- Find trophy label
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    local ui = playerGui and playerGui:FindFirstChild("UI")
                    local hud = ui and ui:FindFirstChild("HUD")
                    local leftBar = hud and hud:FindFirstChild("LeftBar")
                    local stats = leftBar and leftBar:FindFirstChild("Statistics")
                    local trophies = stats and stats:FindFirstChild("Trophies")
                    local trophyAmount = trophies and trophies:FindFirstChild("TrophyAmount")

                    if trophyAmount and trophyAmount:IsA("TextLabel") then
                        local currentText = trophyAmount.Text
                        local currentTrophies = parseAbbreviatedNumber(currentText)
                        
                        if currentTrophies >= requiredTrophies then
                            print("[AutoRebirth] Threshold reached! Performing rebirth.")
                            performRebirth()
                        end
                    else
                        warn("[AutoRebirth] TrophyAmount not found.")
                    end
                end)
                task.wait(1.0)  -- check every second
            end
        end)
    end

    -- Handle respawn
    local characterAddedConn
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        if autoRebirthActive then
            startRebirthLoop()
        end
    end)

    -- ===== UI ELEMENTS =====
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
            startRebirthLoop()
        end
    end)

    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        if autoRebirthActive then
            startRebirthLoop()
        else
            loopActive = false
            if loopThread then
                task.cancel(loopThread)
                loopThread = nil
            end
        end
    end)

    parent.Destroying:Connect(function()
        loopActive = false
        if loopThread then task.cancel(loopThread) end
        if characterAddedConn then characterAddedConn:Disconnect() end
    end)

    print("[AutoRebirth] Script loaded. Check console for debug logs.")
end