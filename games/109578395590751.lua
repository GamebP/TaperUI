--[[

To teleport to 1 billion wins in world 1

X: 5129.87, Y: 699.76, Z: -2559.64
Vector3.new(5129.87, 699.76, -2559.64)

--]]

--[[

How to auto rebirth?

Note: You always need to click the x, y center pos
Note: to get the current trophy count from `game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Frames.Rebirth.Progress.Title` for example it will be like this: `Wins x/y` so `x` will be current trophy count and `y` will be the needed trophy count to rebirth.
Note: When its x >= y the `game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Frames.Rebirth.Progress.Title` will change to `Ready` so its a clear indication to rebirth.

1. Find `game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Buttons.Left.Rebirth` and finds its center x,y pos and click it.
2. After clicking it will open a rebirt menu
3. After finishing the 0.step and before hand clicking 1. and 2. and 3. step then you are 100% sure that you can rebirth.
4. Then after the rebirth menu is opened by the script with clicks the things using a script it will open a rebirth menu.
5. So after opening the rebirth menu you will need to find `game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Frames.Rebirth.Rebirth` and click it by getting the center of x,y pos.
6. Then you will at the end click `game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Frames.Rebirth.Top.X` using the user input using the script.. and then it will be done

--]]

return function(parent, config)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local GuiService = game:GetService("GuiService")

    -- State
    local winFarmActive = false
    local loopInterval = 1.0
    local autoRebirthActive = false

    -- ===== TARGET POSITION (1 Billion Wins spot) =====
    local TARGET_POS = Vector3.new(5129.87, 699.76, -2559.64)

    -- ===== EXTENDED SUFFIX MULTIPLIERS (supports numbers up to 1e54) =====
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

    -- Teleport helper
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- ===== ROBUST VIRTUAL CLICK (center of button) =====
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

    -- ===== AUTO REBIRTH SEQUENCE =====
    local function performRebirth()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
        if not mainUI then return false end

        local leftButton = mainUI:FindFirstChild("Buttons") and mainUI.Buttons:FindFirstChild("Left") and mainUI.Buttons.Left:FindFirstChild("Rebirth")
        if not leftButton then
            warn("[AutoRebirth] Left Rebirth button not found")
            return false
        end

        local frames = mainUI:FindFirstChild("Frames")
        local rebirthFrame = frames and frames:FindFirstChild("Rebirth")
        if not rebirthFrame then
            warn("[AutoRebirth] Rebirth Frame not found")
            return false
        end

        local rebirthButton = rebirthFrame:FindFirstChild("Rebirth")
        local top = rebirthFrame:FindFirstChild("Top")
        local closeButton = top and top:FindFirstChild("X")

        virtualClick(leftButton)
        task.wait(0.4)

        if rebirthButton then
            virtualClick(rebirthButton)
            task.wait(0.4)
        else
            warn("[AutoRebirth] Rebirth button inside menu not found")
        end

        if closeButton then
            virtualClick(closeButton)
        else
            warn("[AutoRebirth] Close button (X) not found")
        end

        return true
    end

    -- ===== AUTO REBIRTH LOOP (dynamic target from UI) =====
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
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
                    local frames = mainUI and mainUI:FindFirstChild("Frames")
                    local rebirthFrame = frames and frames:FindFirstChild("Rebirth")
                    local progress = rebirthFrame and rebirthFrame:FindFirstChild("Progress")
                    local title = progress and progress:FindFirstChild("Title")

                    if title and title:IsA("TextLabel") then
                        local text = title.Text
                        local shouldRebirth = false

                        if text == "Ready" then
                            shouldRebirth = true
                        else
                            -- Parse "Wins x/y"
                            local current, target = text:match("Wins%s+(%S+)%s*/%s*(%S+)")
                            if current and target then
                                local cur = parseAbbreviatedNumber(current)
                                local tgt = parseAbbreviatedNumber(target)
                                if cur >= tgt then
                                    shouldRebirth = true
                                end
                            else
                                warn("[AutoRebirth] Could not parse title: " .. text)
                            end
                        end

                        if shouldRebirth then
                            print("[AutoRebirth] Conditions met – performing rebirth sequence.")
                            performRebirth()
                        end
                    else
                        warn("[AutoRebirth] Progress.Title not found")
                    end
                end)
                task.wait(1.2)
            end
        end)
    end

    -- Handle character respawn
    local characterAddedConn
    characterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        if autoRebirthActive then
            startRebirthLoop()
        end
    end)

    -- ===== UI ELEMENTS =====
    elements:Label("🔥 Automation Utilities", parent)

    elements:Textbox("Teleport Interval (s)", parent, tostring(loopInterval), function(text)
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

    -- Removed the manual target textbox – now fully dynamic.

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

    print("[AutoRebirth] +1 Speed Brick Escape script loaded (dynamic rebirth target).")
end