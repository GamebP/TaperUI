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
    local remoteArgs = {}  -- store expected arguments

    -- Function to find the remote event
    local function findRebirthRemote()
        -- 1. Try to find a RemoteEvent in ReplicatedStorage with common names
        local remoteNames = {"Rebirth", "RebirthRemote", "RebirthEvent", "DoRebirth", "RebirthButton"}
        for _, name in ipairs(remoteNames) do
            local remote = ReplicatedStorage:FindFirstChild(name)
            if remote and remote:IsA("RemoteEvent") then
                return remote
            end
            -- Also search deeper (e.g., in a folder)
            for _, child in ipairs(ReplicatedStorage:GetChildren()) do
                if child:IsA("Folder") then
                    local found = child:FindFirstChild(name)
                    if found and found:IsA("RemoteEvent") then
                        return found
                    end
                end
            end
        end

        -- 2. Search the button's ancestors for a RemoteEvent
        local button = LocalPlayer:FindFirstChild("PlayerGui")
        if button then
            local parent = button
            for i = 1, 10 do  -- climb up to 10 levels
                if parent:IsA("RemoteEvent") then
                    return parent
                end
                parent = parent.Parent
                if not parent then break end
            end
        end

        -- 3. Use getconnections to intercept a manual click (first time you click the button manually)
        -- This is a fallback – we'll set up a one-time listener to capture the remote.
        return nil
    end

    -- Try to detect the remote
    rebirthRemote = findRebirthRemote()

    -- If not found, set up a one‑time capture when the user manually clicks the button
    local function setupRemoteCapture()
        local button = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UI")
        if not button then return end
        button = button:FindFirstChild("Rebirth") and button.Rebirth:FindFirstChild("Frame") and button.Rebirth.Frame:FindFirstChild("Buttons") and button.Rebirth.Frame.Buttons:FindFirstChild("RebirthButton")
        if not button then return end

        local connections = getconnections(button.MouseButton1Click) or getconnections(button.Activated)
        if connections and #connections > 0 then
            -- Hook the first connection to inspect what it fires
            local oldFire = connections[1].Fire
            connections[1].Fire = function(self, ...)
                local args = {...}
                -- Check if any argument is a RemoteEvent or contains one
                for _, arg in ipairs(args) do
                    if arg and arg:IsA("RemoteEvent") then
                        rebirthRemote = arg
                        remoteArgs = {unpack(args)}
                        print("[AutoRebirth] Captured RemoteEvent:", arg:GetFullName())
                        break
                    end
                end
                -- Call the original
                oldFire(self, ...)
            end
            print("[AutoRebirth] Remote capture installed. Click the rebirth button manually once to teach the script.")
        end
    end

    -- If we haven't found it yet, set up capture
    if not rebirthRemote then
        setupRemoteCapture()
    end

    -- Function to perform rebirth (either via remote or UI click)
    local function performRebirth()
        if rebirthRemote then
            -- Fire the remote – typically it expects the player as first argument
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
            -- Fallback: use UI clicking
            local button = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("UI")
            if button then
                button = button:FindFirstChild("Rebirth") and button.Rebirth:FindFirstChild("Frame") and button.Rebirth.Frame:FindFirstChild("Buttons") and button.Rebirth.Frame.Buttons:FindFirstChild("RebirthButton")
                if button then
                    -- Try to click using the robust method from earlier
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
                        -- VirtualInputManager fallback
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
    local rebirthLoopConnection = nil
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
        if rebirthLoopConnection then
            rebirthLoopConnection:Disconnect()
            rebirthLoopConnection = nil
        end

        rebirthLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not autoRebirthActive then return end

            -- Get trophy amount
            local _, trophyAmount = getUIElements()
            local currentTrophies = 0
            if trophyAmount and trophyAmount:IsA("TextLabel") then
                currentTrophies = parseAbbreviatedNumber(trophyAmount.Text)
            end

            -- Debug output every 10 seconds
            if tick() % 10 < 0.05 then
                print(string.format("[AutoRebirth] Trophies: %s (parsed: %.2e), Required: %.2e", 
                    trophyAmount and trophyAmount.Text or "??", currentTrophies, requiredTrophies))
            end

            if currentTrophies >= requiredTrophies then
                print("[AutoRebirth] Trophy threshold met. Attempting rebirth...")
                performRebirth()
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
            -- If remote not found, try to capture it again
            if not rebirthRemote then
                setupRemoteCapture()
                print("[AutoRebirth] Remote not found – click the Rebirth button once manually to capture the event.")
            end
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

    print("[AutoRebirth] Script loaded. If the remote isn't auto-detected, click the Rebirth button once manually to teach the script.")
end