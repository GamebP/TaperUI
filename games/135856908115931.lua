return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    -- ===== CONFIGURATION & STATE =====
    local espEnabled = true
    local teamCheck = true
    local aimbotEnabled = true
    local aimbotToggleKeyStr = "R" -- Defaulted to 'R' as requested
    local fovDegrees = 15

    local triggerbotActive = false
    local triggerKeyStr = "LeftControl"
    local triggerMode = "Hold" -- "Hold" or "Toggle"
    local triggerCooldown = 0.1
    
    local triggerbotRunning = false
    local lastTriggerTime = 0

    -- ESP data and lifecycle tracking
    local espData = {}
    local connections = {}

    -- ===== FOV CIRCLE INITIALIZATION =====
    local hasDrawing = (typeof(Drawing) == "table" or typeof(Drawing) == "userdata") and typeof(Drawing.new) == "function"
    local fovCircle
    if hasDrawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Radius = fovDegrees
        fovCircle.Filled = false
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Visible = false
    end

    -- Helper: track event connections for cleanup on destroy
    local function track(conn)
        table.insert(connections, conn)
        return conn
    end

    -- Helper: translate key strings to KeyCodes
    local function getKeyCode(keyName)
        local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
        return ok and kc or nil
    end

    -- Helper: safely update UI visual components when toggled via hotkey
    local function setToggleVisual(toggleFrame, state)
        if not toggleFrame then return end
        local toggleBg = toggleFrame:FindFirstChild("togglebg")
        local knob = toggleBg and toggleBg:FindFirstChild("leftrightlol")
        if toggleBg and knob then
            local bgTarget = state and Color3.fromRGB(59, 164, 57) or Color3.fromRGB(164, 58, 58)
            local posTarget = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = bgTarget }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = posTarget }):Play()
        end
    end

    local function isAlive(player)
        local char = player.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        return humanoid and humanoid.Health > 0
    end

    local function getEnemyPlayers()
        local enemies = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and isAlive(plr) then
                if teamCheck and LocalPlayer.Team and plr.Team and plr.Team == LocalPlayer.Team then
                    continue
                end
                table.insert(enemies, plr)
            end
        end
        return enemies
    end

    local function angleBetween(v1, v2)
        return math.deg(math.acos(math.clamp(v1:Dot(v2), -1, 1)))
    end

    local function getClosestEnemyInFOV()
        local enemies = getEnemyPlayers()
        if #enemies == 0 then return nil end

        local camLook = Camera.CFrame.LookVector
        local bestAngle = fovDegrees
        local bestPlayer = nil
        local bestPart = nil

        for _, plr in ipairs(enemies) do
            local char = plr.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dir = (hrp.Position - Camera.CFrame.Position).Unit
                local angle = angleBetween(camLook, dir)
                if angle < bestAngle then
                    bestAngle = angle
                    bestPlayer = plr
                    bestPart = hrp
                end
            end
        end
        return bestPlayer, bestPart
    end

    -- ===== ESP MANAGEMENT =====
    local function createESPForPlayer(player)
        if espData[player] then
            if espData[player].Container then pcall(function() espData[player].Container:Destroy() end) end
            espData[player] = nil
        end

        local char = player.Character
        if not char then return end

        local container = Instance.new("Folder")
        container.Name = "ESP_Container"
        container.Parent = char

        local highlight = Instance.new("Highlight")
        highlight.Name = "HL"
        highlight.Parent = container
        highlight.Adornee = char
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.1
        highlight.Enabled = false

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "BB"
        billboard.Size = UDim2.new(0, 150, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = container

        local adorneePart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        billboard.Adornee = adorneePart
        billboard.Enabled = false

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TL"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.TextSize = 14
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Parent = billboard

        -- Cached entry now tracks the CharacterInstance
        espData[player] = {
            Container = container,
            Highlight = highlight,
            Billboard = billboard,
            TextLabel = textLabel,
            Player = player,
            CharacterInstance = char
        }
    end

    local function clearAllESP()
        for plr, data in pairs(espData) do
            if data.Container then
                pcall(function() data.Container:Destroy() end)
            end
            espData[plr] = nil
        end
    end

    local function updateESP()
        if not espEnabled then
            clearAllESP()
            return
        end

        -- 1. SANITIZE CACHE: Purge entries if players leave, respawn, or have invalid folder structures
        for plr, data in pairs(espData) do
            if not plr or not plr.Parent or not Players:FindFirstChild(plr.Name) then
                if data.Container then pcall(function() data.Container:Destroy() end) end
                espData[plr] = nil
            elseif not plr.Character or plr.Character ~= data.CharacterInstance or not data.Container or data.Container.Parent ~= plr.Character then
                if data.Container then pcall(function() data.Container:Destroy() end) end
                espData[plr] = nil
            end
        end

        -- 2. DRAW/UPDATE ACTIVE ESP COVERS
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then
                continue
            end

            if not isAlive(plr) then
                if espData[plr] then
                    espData[plr].Highlight.Enabled = false
                    espData[plr].Billboard.Enabled = false
                end
                continue
            end

            -- Automatically generates fresh visuals if purged or newly connected
            if not espData[plr] then
                createESPForPlayer(plr)
                if not espData[plr] then continue end
            end

            local data = espData[plr]
            local char = plr.Character
            if not char then
                continue
            end

            local color = teamCheck and (plr.Team and plr.Team.TeamColor and plr.Team.TeamColor.Color) or Color3.new(1, 0, 0)
            if not color then color = Color3.new(1, 0, 0) end
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
            data.Highlight.Enabled = true

            local adorneePart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if adorneePart then
                data.Billboard.Adornee = adorneePart
                data.Billboard.Enabled = true
            else
                data.Billboard.Enabled = false
            end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                data.TextLabel.Text = plr.Name .. " [" .. healthPercent .. "%]"
                data.TextLabel.TextColor3 = color
            else
                data.TextLabel.Text = plr.Name
            end
        end
    end

    -- ===== AIMBOT =====
    local function doAimbot()
        if not aimbotEnabled then return end
        local target, targetPart = getClosestEnemyInFOV()
        if target and targetPart then
            local head = target.Character:FindFirstChild("Head")
            local aimPoint = head and head.Position or targetPart.Position
            local camPos = Camera.CFrame.Position
            Camera.CFrame = CFrame.new(camPos, aimPoint)
        end
    end

    -- ===== FOV CIRCLE UPDATE =====
    local function updateFovCircle()
        if not hasDrawing or not fovCircle then return end
        
        if not aimbotEnabled then
            fovCircle.Visible = false
            return
        end
        
        fovCircle.Position = Camera.ViewportSize / 2
        
        local fovRad = math.rad(fovDegrees)
        local cameraFovRad = math.rad(Camera.FieldOfView)
        local viewportY = Camera.ViewportSize.Y
        
        local success, radius = pcall(function()
            return (math.tan(fovRad) / math.tan(cameraFovRad / 2)) * (viewportY / 2)
        end)
        
        if success and radius then
            fovCircle.Radius = radius
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end
    end

    -- ===== TRIGGERBOT =====
    local function resetTriggerbotState()
        triggerbotRunning = false
    end

    local function doTriggerbot()
        if not triggerbotActive or not triggerbotRunning then return end
        local target, targetPart = getClosestEnemyInFOV()
        if target and targetPart then
            local now = tick()
            if now - lastTriggerTime >= triggerCooldown then
                lastTriggerTime = now
                if mouse1click then
                    mouse1click()
                else
                    local vim = game:GetService("VirtualInputManager")
                    if vim then
                        vim:SendButtonInputToController(Enum.UserInputType.MouseButton1, true)
                        task.wait(0.01)
                        vim:SendButtonInputToController(Enum.UserInputType.MouseButton1, false)
                    end
                end
            end
        end
    end

    -- ===== UI ELEMENTS =====
    elements:Label("👁️ Visuals (ESP)", parent)

    elements:Toggle("ESP Active", parent, espEnabled, function(state)
        espEnabled = state
        if not espEnabled then
            clearAllESP()
        end
    end)

    elements:Toggle("Team Check", parent, teamCheck, function(state)
        teamCheck = state
    end)

    elements:Label("🎯 Combat (Aimbot)", parent)

    -- Storing reference to dynamic visual synchronization
    local aimbotToggleUI
    aimbotToggleUI = elements:Toggle("Aimbot Active", parent, aimbotEnabled, function(state)
        aimbotEnabled = state
    end)

    elements:Keybind("Aimbot Toggle Key", parent, aimbotToggleKeyStr, function(key)
        aimbotToggleKeyStr = key
    end)

    elements:Slider("Aimbot FOV", parent, 5, 180, fovDegrees, 0, function(value)
        fovDegrees = value
    end)

    elements:Label("🔫 Automation (Triggerbot)", parent)

    elements:Toggle("Triggerbot Module", parent, triggerbotActive, function(state)
        triggerbotActive = state
        resetTriggerbotState()
    end)

    elements:Keybind("Trigger Key Bind", parent, triggerKeyStr, function(key)
        triggerKeyStr = key
        resetTriggerbotState()
    end)

    elements:Dropdown("Triggerbot Mode", parent, {"Hold", "Toggle"}, triggerMode, function(mode)
        triggerMode = mode
        resetTriggerbotState()
    end)

    elements:Slider("Triggerbot Cooldown", parent, 0.01, 1.0, triggerCooldown, 2, function(value)
        triggerCooldown = value
    end)

    -- ===== KEY HANDLING =====
    track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            -- Handle Aimbot Toggle via Keyboard
            local aimbotKC = getKeyCode(aimbotToggleKeyStr)
            if aimbotKC and input.KeyCode == aimbotKC then
                aimbotEnabled = not aimbotEnabled
                setToggleVisual(aimbotToggleUI, aimbotEnabled) -- Safely sync visually
                
                if getgenv().showToast then
                    getgenv().showToast("Aimbot", "Aimbot is now " .. (aimbotEnabled and "Enabled" or "Disabled"), 1.5)
                end
            end

            -- Handle Triggerbot Ignition
            local triggerKC = getKeyCode(triggerKeyStr)
            if triggerKC and input.KeyCode == triggerKC then
                if triggerMode == "Hold" then
                    triggerbotRunning = true
                elseif triggerMode == "Toggle" then
                    triggerbotRunning = not triggerbotRunning
                end
            end
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            -- Stop Triggerbot on key release if set to hold mode
            local triggerKC = getKeyCode(triggerKeyStr)
            if triggerKC and input.KeyCode == triggerKC then
                if triggerMode == "Hold" then
                    triggerbotRunning = false
                end
            end
        end
    end))

    -- ===== MAIN EXECUTION LOOP =====
    track(RunService.RenderStepped:Connect(function()
        updateESP()
        doAimbot()
        updateFovCircle()
        doTriggerbot()
    end))

    -- ===== CLEANUP =====
    parent.Destroying:Connect(function()
        for _, conn in ipairs(connections) do
            if conn then conn:Disconnect() end
        end
        clearAllESP()
        if hasDrawing and fovCircle then
            pcall(function() fovCircle:Remove() end)
        end
    end)
end