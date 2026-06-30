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

    -- State Variables
    local winFarmActive = false
    local loopInterval = 1.0
    local autoRebirthActive = false
    
    local currentTargetLevel = nil -- Cached target level (prevents menu flashing)
    local lastForceCheck = 0       -- Prevent spamming force-checks

    -- Target Position for 100 Billion Wins
    local TARGET_POS = Vector3.new(3568.008, 2.045, 8.190)

    -- Helper: Teleport Local Player
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- Helper: Robust Virtual Click Simulation
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

    -- Safely read current level directly from your leaderstats
    local function getCurrentLevel()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local levelVal = leaderstats and leaderstats:FindFirstChild("Level")
        if levelVal then
            return tonumber(levelVal.Value) or 0
        end
        return 0
    end

    -- Read target level from Rebirth bar when the window is open
    local function updateTargetLevel()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local gui = playerGui and playerGui:FindFirstChild("GUI")
        local levelLabel = gui and gui:FindFirstChild("Frames")
            and gui.Frames:FindFirstChild("Rebirth")
            and gui.Frames.Rebirth:FindFirstChild("Frame")
            and gui.Frames.Rebirth.Frame:FindFirstChild("Bar")
            and gui.Frames.Rebirth.Frame.Bar:FindFirstChild("LevelLabel")

        if levelLabel and levelLabel:IsA("TextLabel") then
            local text = levelLabel.Text
            -- Match the two numeric values from format pattern: e.g., "Level 2/12"
            local current, target = text:match("(%d+)/(%d+)")
            if current and target then
                local curLvl = tonumber(current)
                local tgtLvl = tonumber(target)
                if curLvl and tgtLvl and curLvl >= tgtLvl then
                    return true
                end
            end
        end
        return false
    end

    -- Perform Rebirth Sequence (Open Rebirth Menu -> Wait -> Close Menu)
    local function performRebirth()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local gui = playerGui and playerGui:FindFirstChild("GUI")
        
        -- HUD Open Rebirth Button
        local hudButton = gui and gui:FindFirstChild("HUD") 
            and gui.HUD:FindFirstChild("Left") 
            and gui.HUD.Left:FindFirstChild("Buttons1") 
            and gui.HUD.Left.Buttons1:FindFirstChild("Rebirth")
            
        -- Rebirth Window Close Button
        local closeButton = gui and gui:FindFirstChild("Frames") 
            and gui.Frames:FindFirstChild("Rebirth") 
            and gui.Frames.Rebirth:FindFirstChild("Title") 
            and gui.Frames.Rebirth.Title:FindFirstChild("Close")
        
        if not hudButton then
            return false
        end
        
        -- Step 1: Click HUD Button to open/re-open menu
        virtualClick(hudButton)
        task.wait(0.8) -- Delay to allow the server to register rebirth
        
        -- Step 2: Grab the next escalated target requirement while the menu is open
        updateTargetLevel()
        
        -- Step 3: Click the close button to close the rebirth window
        if closeButton then
            virtualClick(closeButton)
        end
        
        return true
    end

    -- Rebirth Loop Worker
    local rebirthThread = nil
    local function startRebirthLoop()
        if rebirthThread then
            task.cancel(rebirthThread)
            rebirthThread = nil
        end

        rebirthThread = task.spawn(function()
            while autoRebirthActive do
                pcall(function()
                    local currentLevel = getCurrentLevel()
                    
                    -- Step 1: Initialize target level or force update every 30s
                    if not currentTargetLevel or (tick() - lastForceCheck > 30) then
                        lastForceCheck = tick()
                        
                        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                        local gui = playerGui and playerGui:FindFirstChild("GUI")
                        local hudButton = gui and gui:FindFirstChild("HUD") 
                            and gui.HUD:FindFirstChild("Left") 
                            and gui.HUD.Left:FindFirstChild("Buttons1") 
                            and gui.HUD.Left.Buttons1:FindFirstChild("Rebirth")
                            
                        if hudButton then
                            virtualClick(hudButton)
                            task.wait(0.3) -- Wait for frame instantiation
                            updateTargetLevel()
                            
                            -- Close it immediately
                            local closeButton = gui and gui:FindFirstChild("Frames") 
                                and gui.Frames:FindFirstChild("Rebirth") 
                                and gui.Frames.Rebirth:FindFirstChild("Title") 
                                and gui.Frames.Rebirth.Title:FindFirstChild("Close")
                            if closeButton then
                                virtualClick(closeButton)
                            end
                        end
                    end
                    
                    -- Step 2: Trigger rebirth sequence when requirement met
                    if currentTargetLevel and currentLevel >= currentTargetLevel then
                        performRebirth()
                    end
                end)
                task.wait(1.0)
            end
        end)
    end

    -- ===== UI ELEMENTS =====
    elements:Label("🔥 Automation Utilities", parent)

    -- Toggle for Auto Win Farm
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

    -- Slider to control how fast you teleport to the win button
    elements:Slider("Win Teleport Delay (s)", parent, 0.1, 5.0, loopInterval, 1, function(val)
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

    -- Cleanup connection on GUI destroy
    parent.Destroying:Connect(function()
        winFarmActive = false
        autoRebirthActive = false
        if rebirthThread then
            task.cancel(rebirthThread)
        end
    end)
end