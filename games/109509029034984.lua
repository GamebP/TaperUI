return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local GuiService = game:GetService("GuiService")

    -- State
    local winFarmActive = false
    local loopInterval = 1.0
    local autoRebirthActive = false
    local requiredTrophiesString = "1K"
    local TARGET_POS = Vector3.new(-3204.50, 53.29, -20.50)

    -- Suffix multipliers
        local suffixMultiplier = {
        K = 1e3,
        M = 1e6,
        B = 1e9,
        T = 1e12,
        Qa = 1e15,
        Qd = 1e15,
        Qi = 1e18,
        Qt = 1e18,
        Sx = 1e21,
        Sp = 1e24,
        Oc = 1e27,
        No = 1e30,
        Nn = 1e30,
        Dc = 1e33,
        Ud = 1e36,
        Dd = 1e39,
        Td = 1e42,
        Qu = 1e45,
        Qn = 1e48,
        Se = 1e51,
        Ss = 1e54,
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

    -- ===== ROBUST SIMULATED CLICK HELPER =====
    local function virtualClick(button)
        if not button then return false end
        
        local absPos = button.AbsolutePosition
        local absSize = button.AbsoluteSize
        local clickX = absPos.X + (absSize.X / 2)
        local clickY = absPos.Y + (absSize.Y / 2)
        
        -- Fix scaling errors if IgnoreGuiInset is false on the ScreenGui
        local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
        if screenGui and not screenGui.IgnoreGuiInset then
            local inset = GuiService:GetGuiInset()
            clickX = clickX + inset.X
            clickY = clickY + inset.Y
        end
        
        -- Simulate hovering and pressing the mouse
        VirtualInputManager:SendMouseMoveEvent(clickX, clickY, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
        return true
    end

    -- ===== REBIRTH EXECUTION (UI CLICK SEQUENCE) =====
    local function performRebirth()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local ui = playerGui and playerGui:FindFirstChild("UI")
        
        -- Resolve Button 1: Left HUD Open Button
        local hudButton = ui and ui:FindFirstChild("HUD") 
            and ui.HUD:FindFirstChild("LeftBar") 
            and ui.HUD.LeftBar:FindFirstChild("Buttons") 
            and ui.HUD.LeftBar.Buttons:FindFirstChild("RebirthButton")
            
        -- Resolve Button 2 & 3: Rebirth Menu Buttons
        local rebirthFrame = ui and ui:FindFirstChild("Rebirth") and ui.Rebirth:FindFirstChild("Frame")
        local frameButton = rebirthFrame and rebirthFrame:FindFirstChild("Buttons") and rebirthFrame.Buttons:FindFirstChild("RebirthButton")
        local closeButton = rebirthFrame and rebirthFrame:FindFirstChild("CloseButton")
        
        if not hudButton then
            return false
        end
        
        -- Step 1: Click HUD Button to open/re-open menu
        virtualClick(hudButton)
        task.wait(0.35) -- Wait for menu animation to complete
        
        -- Step 2: Click Rebirth confirmation Button inside the frame
        if frameButton then
            virtualClick(frameButton)
            task.wait(0.35) -- Wait for server data update
        end
        
        -- Step 3: Click Close Button to hide/minimize the menu
        if closeButton then
            virtualClick(closeButton)
        end
        
        return true
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
                            performRebirth()
                        end
                    end
                end)
                task.wait(1.2)  -- Check frequency interval
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
end