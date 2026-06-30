--[[

Note to auto rebirth you will always click the elements in the x,y center

1. To check if you can rebirth you will check `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth.LevelBar.Label` TextLabel and you will see `Level: 57/75`
-- So in this case you can't rebirth since 57 >= 75 is not correct. it needs to be equal as 75 for example 75 == 75 or 75 >= 75.
-- So when you are eligable and is `current_level >= required_level` then you can rebirth.
2. You will find `game:GetService("Players").LocalPlayer.PlayerGui.Main.HUD.Buttons._3Rebirth` and click center of x, y pos
3. You will find the button `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth.Rebirth` and click center of x, y pos.. this will rebirth you.
4. After rebirthing you will click `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth.Close` and click center of x, y pos to close the rebirth window.


UPDATE:

1. Find `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth` and change :Visible from false to true
2. Click `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth.Rebirth` center of x, y pos
3. Change `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth` :Visible from true to false

--]]

return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local GuiService = game:GetService("GuiService")

    -- ===== STATE VARIABLES =====
    local winFarmActive = false
    local loopInterval = 1.0
    local autoRebirthActive = false

    -- ===== POSITIONAL CONSTANTS =====
    local TELEPORT_START_POS = Vector3.new(-1754.66, 680.42, 3225.36)
    local WALK_TARGET_POS = Vector3.new(-1754.66, 680.42, 3230.36)

    -- ===== RECURSIVE CLICKABLE RESOLVER =====
    local function getClickableTarget(element)
        if not element then return nil end
        if element:IsA("GuiButton") then
            return element
        end
        -- Search through nested children to locate the actual TextButton/ImageButton
        for _, desc in ipairs(element:GetDescendants()) do
            if desc:IsA("GuiButton") then
                return desc
            end
        end
        return element -- Fallback if no nested button exists
    end

    -- ===== ROBUST SIMULATED CLICK HELPER =====
    local function virtualClick(button)
        if not button then return false end
        
        local absPos = button.AbsolutePosition
        local absSize = button.AbsoluteSize
        local clickX = absPos.X + (absSize.X / 2)
        local clickY = absPos.Y + (absSize.Y / 2)
        
        local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
        if screenGui and not screenGui.IgnoreGuiInset then
            local inset = GuiService:GetGuiInset()
            clickX = clickX + inset.X
            clickY = clickY + inset.Y
        end
        
        VirtualInputManager:SendMouseMoveEvent(clickX, clickY, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
        return true
    end

    -- ===== UNIVERSAL PHYSICAL/CONNECTION CLICKER =====
    local function robustClick(element)
        if not element then return false end
        
        -- Automatically resolve nested clickable target
        local button = getClickableTarget(element)
        local clicked = false

        -- Calculate exact click coordinates of the target button
        local absPos = button.AbsolutePosition
        local absSize = button.AbsoluteSize
        local clickX = absPos.X + (absSize.X / 2)
        local clickY = absPos.Y + (absSize.Y / 2)
        
        local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
        if screenGui and not screenGui.IgnoreGuiInset then
            local inset = GuiService:GetGuiInset()
            clickX = clickX + inset.X
            clickY = clickY + inset.Y
        end

        print(string.format("[Click Debug] Element: %s | Target: %s (%s) | Pos: %d, %d", 
            element.Name, button.Name, button.ClassName, clickX, clickY))

        -- 1. Direct Connection Fire (Fires ALL click and input events on the actual button)
        if typeof(getconnections) == "function" then
            pcall(function()
                local events = {
                    "MouseButton1Click",
                    "MouseButton1Down",
                    "MouseButton1Up",
                    "Activated",
                    "InputBegan",
                    "InputEnded"
                }
                for _, eventName in ipairs(events) do
                    local event = button[eventName]
                    if event then
                        for _, conn in ipairs(getconnections(event)) do
                            if conn.Fire then 
                                pcall(conn.Fire, conn) 
                                clicked = true
                            end
                        end
                    end
                end
            end)
        end

        -- 2. Native OS Mouse Move + Hold Click (the most reliable background/physical method)
        pcall(function()
            if mousemoveabs then
                mousemoveabs(clickX, clickY)
            else
                VirtualInputManager:SendMouseMoveEvent(clickX, clickY, game)
            end
            task.wait(0.1) -- Allow hover to register in the UI

            if mouse1press and mouse1release then
                mouse1press()
                task.wait(0.1) -- 100ms hold duration to guarantee click registration
                mouse1release()
                clicked = true
            elseif mouse1click then
                mouse1click()
                clicked = true
            end
        end)

        -- 3. Native GuiService Selection Focus + Return Key (Roblox Engine Action)
        pcall(function()
            local oldSelectable = button.Selectable
            button.Selectable = true
            local oldSelected = GuiService.SelectedObject
            
            GuiService.SelectedObject = button
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            
            GuiService.SelectedObject = oldSelected
            button.Selectable = oldSelectable
            clicked = true
        end)

        -- 4. VirtualInputManager Fallback Click
        if not clicked then
            pcall(function()
                VirtualInputManager:SendMouseMoveEvent(clickX, clickY, game)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                clicked = true
            end)
        end

        return clicked
    end

    -- ===== AUTO WIN FARM EXECUTION =====
    local function performWinFarm()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        -- Step 1: Teleport to the starting line
        root.CFrame = CFrame.new(TELEPORT_START_POS)
        task.wait(0.1)

        -- Step 2: Input standard walk command toward the touch trigger target
        local timeout = tick()
        while winFarmActive and (root.Position - WALK_TARGET_POS).Magnitude > 0.5 and (tick() - timeout) < 1.5 do
            hum:MoveTo(WALK_TARGET_POS)
            task.wait(0.05)
        end
    end

    -- ===== REBIRTH ELIGIBILITY CHECK =====
    local function checkRebirthEligibility()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        local rebirthFrame = main and main:FindFirstChild("Rebirth")
        local levelBar = rebirthFrame and rebirthFrame:FindFirstChild("LevelBar")
        local label = levelBar and levelBar:FindFirstChild("Label")

        if label and label:IsA("TextLabel") then
            local text = label.Text
            -- Match pattern handles optional spaces around the slash
            local current, target = text:match("(%d+)%s*/%s*(%d+)")
            if current and target then
                local curLvl = tonumber(current)
                local tgtLvl = tonumber(target)
                if curLvl and tgtLvl then
                    if curLvl >= tgtLvl then
                        return true
                    end
                end
            else
                warn("[AutoRebirth] Could not parse your level text: " .. tostring(text))
            end
        else
            warn("[AutoRebirth] Level Label UI element not found or invalid.")
        end
        return false
    end

    -- ===== REBIRTH CLICK SEQUENCE =====
    local function performRebirth()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        if not main then 
            warn("[AutoRebirth] Main PlayerGui not found.")
            return false 
        end

        local rebirthMenu = main:FindFirstChild("Rebirth")
        if not rebirthMenu then
            warn("[AutoRebirth] Rebirth Menu frame could not be resolved.")
            return false
        end

        local rebirthActionBtn = rebirthMenu:FindFirstChild("Rebirth")
        if not rebirthActionBtn then
            warn("[AutoRebirth] Rebirth confirmation button inside menu was missing.")
            return false
        end

        -- Step 1: Force visibility of the rebirth menu to true
        print("[AutoRebirth] Opening Rebirth UI manually...")
        rebirthMenu.Visible = true
        task.wait(0.15) -- Minimal latency window to register UI active bounds

        -- Step 2: Trigger the click sequence inside the confirmation button
        print("[AutoRebirth] Sending click to confirm button.")
        robustClick(rebirthActionBtn)
        task.wait(0.5) -- Wait for configuration values to update

        -- Step 3: Change visibility of the rebirth menu to false
        print("[AutoRebirth] Closing Rebirth UI manually...")
        rebirthMenu.Visible = false

        return true
    end

    -- ===== AUTO REBIRTH LOOP =====
    local rebirthThread = nil
    local function startRebirthLoop()
        if rebirthThread then
            task.cancel(rebirthThread)
            rebirthThread = nil
        end

        rebirthThread = task.spawn(function()
            while autoRebirthActive do
                pcall(function()
                    if checkRebirthEligibility() then
                        performRebirth()
                    end
                end)
                task.wait(1.5)
            end
        end)
    end

    -- Re-bind loops if the character respawns
    local characterAddedConn
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        if autoRebirthActive then
            startRebirthLoop()
        end
    end)

    -- ===== TAPERUI INTERFACE ELEMENTS =====
    elements:Label("🔥 Automation Utilities", parent)

    -- Toggle for Auto Win Farm
    elements:Toggle("Auto Win Farm", parent, false, function(state)
        winFarmActive = state
        if winFarmActive then
            task.spawn(function()
                while winFarmActive do
                    performWinFarm()
                    task.wait(loopInterval)
                end
            end)
        end
    end)

    -- Slider to control speed between teleports
    elements:Slider("Farm Teleport Delay (s)", parent, 0.1, 5.0, loopInterval, 1, function(val)
        loopInterval = val
    end)

    -- Toggle for Auto Rebirth
    elements:Toggle("Auto Rebirth", parent, false, function(state)
        autoRebirthActive = state
        if autoRebirthActive then
            startRebirthLoop()
        else
            if rebirthThread then
                task.cancel(rebirthThread)
                rebirthThread = nil
            end
        end
    end)

    -- Cleanup listeners on UI Destroy
    parent.Destroying:Connect(function()
        winFarmActive = false
        autoRebirthActive = false
        if rebirthThread then
            task.cancel(rebirthThread)
        end
        if characterAddedConn then
            characterAddedConn:Disconnect()
        end
    end)
end