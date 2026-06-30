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

    -- Teleport function
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- ===== REMOTE EVENT DETECTION =====
    local rebirthRemote = nil
    local remoteArgs = {}

    -- Function to find the remote event
    local function findRebirthRemote()
        local remoteNames = {"Rebirth", "RebirthRemote", "RebirthEvent", "DoRebirth", "RebirthButton"}
        for _, name in ipairs(remoteNames) do
            local remote = ReplicatedStorage:FindFirstChild(name)
            if remote and remote:IsA("RemoteEvent") then
                return remote
            end
            for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                if child:IsA("Folder") then
                    local found = child:FindFirstChild(name)
                    if found and found:IsA("RemoteEvent") then
                        return found
                    end
                end
            end
        end

        local button = LocalPlayer:FindFirstChild("PlayerGui")
        if button then
            local parent = button
            for i = 1, 10 do
                if parent:IsA("RemoteEvent") then
                    return parent
                end
                parent = parent.Parent
                if not parent then break end
            end
        end

        return nil
    end

    rebirthRemote = findRebirthRemote()

    local function setupRemoteCapture()
        local button = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UI")
        if not button then return end
        button = button:FindFirstChild("Rebirth") and button.Rebirth:FindFirstChild("Frame") and button.Rebirth.Frame:FindFirstChild("Buttons") and button.Rebirth.Frame.Buttons:FindFirstChild("RebirthButton")
        if not button then return end

        local connections = getconnections(button.MouseButton1Click) or getconnections(button.Activated)
        if connections and #connections > 0 then
            local oldFire = connections[1].Fire
            connections[1].Fire = function(self, ...)
                local args = {...}
                for _, arg in ipairs(args) do
                    if arg and arg:IsA("RemoteEvent") then
                        rebirthRemote = arg
                        remoteArgs = {unpack(args)}
                        print("[AutoRebirth] Captured RemoteEvent:", arg:GetFullName())
                        break
                    end
                end
                oldFire(self, ...)
            end
            print("[AutoRebirth] Remote capture installed. Click the rebirth button manually once to teach the script.")
        end
    end

    if not rebirthRemote then
        setupRemoteCapture()
    end

    -- Function to perform rebirth (either via remote or UI click)
    local function performRebirth()
        if rebirthRemote then
            local args = {LocalPlayer}
            if #remoteArgs > 0 then
                args = remoteArgs
            end
            pcall(function()
                rebirthRemote:FireServer(unpack(args))
                print("[AutoRebirth] Fired RemoteEvent:", rebirthRemote:GetFullName())
            end)
            return true
        else
            local button = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UI")
            if button then
                button = button:FindFirstChild("Rebirth") and button.Rebirth:FindFirstChild("Frame") and button.Rebirth.Frame:FindFirstChild("Buttons") and button.Rebirth.Frame.Buttons:FindFirstChild("RebirthButton")
                if button then
                    local clicked = false
                    if typeof(firesignal) == "function" then
                        pcall(firesignal, button.MouseButton1Click)
                        clicked = true
                    end
                    if not clicked then
                        local connections = getconnections(button.MouseButton1Click)
                        if connections then
                            for _, conn in ipairs(connections) do
                                pcall(conn.Fire, conn)
                            end
                            clicked = true
                        end
                    end
                    if not clicked then
                        local vim = game:GetService("VirtualInputManager")
                        if vim then
                            local absPos = button.AbsolutePosition
                            local absSize = button.AbsoluteSize
                            vim:SendMouseButtonEvent(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2, 0, true, game, 0)
                            task.wait(0.01)
                            vim:SendMouseButtonEvent(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2, 0, false, game, 0)
                            clicked = true
                        end
                    end
                    if clicked then
                        print("[AutoRebirth] UI click fallback used.")
                        return true
                    end
                end
            end
            warn("[AutoRebirth] All methods failed.")
            return false
        end
    end

    -- ===== AUTO REBIRTH POLLING =====
    local loopRunning = false
    local characterAddedConn = nil

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

    local function startRebirthLoop()
        loopRunning = false
        task.wait(0.1) -- settle threads
        loopRunning = true

        task.spawn(function()
            while loopRunning and autoRebirthActive do
                pcall(function()
                    -- Get trophy amount
                    local _, trophyAmount = getUIElements()
                    local currentTrophies = 0
                    if trophyAmount and trophyAmount:IsA("TextLabel") then
                        currentTrophies = parseAbbreviatedNumber(trophyAmount.Text)
                    end

                    if currentTrophies >= requiredTrophies then
                        print(string.format("[AutoRebirth] Threshold met (%s). Attempting rebirth...", trophyAmount and trophyAmount.Text or "0"))
                        performRebirth()
                    end
                end)
                task.wait(1.0) -- Checking once per second allows the game events to process safely
            end
        end)
    end

    -- Handle respawn
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
            if not rebirthRemote then
                setupRemoteCapture()
                print("[AutoRebirth] Remote not found – click the Rebirth button once manually to capture the event.")
            end
        else
            loopRunning = false
        end
    end)

    parent.Destroying:Connect(function()
        loopRunning = false
        if characterAddedConn then characterAddedConn:Disconnect() end
    end)
end