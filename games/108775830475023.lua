--[[

To auto get a 5T wins you need to telport to 

X: 1111.34, Y: 680.42, Z: 3224.36
Vector3.new(1111.34, 680.42, 3224.36)

Then use script walk commands to walk to z - 3228.36 until you touch the `workspace.SectionAwardParts:GetChildren()[11]`

--]]

--[[

Note to auto rebirth you will always click the elements in the x,y center

1. To check if you can rebirth you will check `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth.LevelBar.Label` TextLabel and you will see `Level: 57/75`
-- So in this case you can't rebirth since 57 >= 75 is not correct. it needs to be equal as 75 for example 75 == 75 or 75 >= 75.
-- So when you are eligable and is `current_level >= required_level` then you can rebirth.
2. You will find `game:GetService("Players").LocalPlayer.PlayerGui.Main.HUD.Buttons._3Rebirth` and click center of x, y pos
3. You will find the button `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth.Rebirth` and click center of x, y pos.. this will rebirth you.
4. After rebirthing you will click `game:GetService("Players").LocalPlayer.PlayerGui.Main.Rebirth.Close` and click center of x, y pos to close the rebirth window.

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

    -- ===== ROBUST SIMULATED CLICK HELPER =====
    local function virtualClick(button)
        if not button then return false end
        
        local absPos = button.AbsolutePosition
        local absSize = button.AbsoluteSize
        local clickX = absPos.X + (absSize.X / 2)
        local clickY = absPos.Y + (absSize.Y / 2)
        
        -- Adjust for Topbar offset if IgnoreGuiInset is false on the ScreenGui
        local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
        if screenGui and not screenGui.IgnoreGuiInset then
            local inset = GuiService:GetGuiInset()
            clickX = clickX + inset.X
            clickY = clickY + inset.Y
        end
        
        -- Simulate hardware-level mouse event
        VirtualInputManager:SendMouseMoveEvent(clickX, clickY, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
        return true
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
            -- Parse numbers from formatted "Level: XX/YY" text
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

    -- ===== REBIRTH CLICK SEQUENCE =====
    local function performRebirth()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local main = playerGui and playerGui:FindFirstChild("Main")
        if not main then return false end

        -- Resolve paths to necessary interactive UI elements
        local hudRebirthButton = main:FindFirstChild("HUD")
            and main.HUD:FindFirstChild("Buttons")
            and main.HUD.Buttons:FindFirstChild("_3Rebirth")

        local rebirthMenu = main:FindFirstChild("Rebirth")
        local rebirthActionBtn = rebirthMenu and rebirthMenu:FindFirstChild("Rebirth")
        local closeMenuBtn = rebirthMenu and rebirthMenu:FindFirstChild("Close")

        if not hudRebirthButton then
            return false
        end

        -- Step 1: Click the main HUD Rebirth button to open the menu
        virtualClick(hudRebirthButton)
        task.wait(0.4)

        -- Step 2: Click the confirmation Rebirth button inside the menu
        if rebirthActionBtn then
            virtualClick(rebirthActionBtn)
            task.wait(0.4)
        end

        -- Step 3: Close the rebirth window
        if closeMenuBtn then
            virtualClick(closeMenuBtn)
        end

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