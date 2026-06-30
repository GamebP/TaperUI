return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player references
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- ===== STATE VARIABLES =====
    local winFarmActive = false
    local loopInterval = 1.0
    local autoRebirthActive = false

    -- ===== POSITIONAL CONSTANTS =====
    local TELEPORT_START_POS = Vector3.new(-1754.66, 680.42, 3225.36)
    local WALK_TARGET_POS = Vector3.new(-1754.66, 680.42, 3230.36)

    -- ===== OPTIMIZED CACHED REMOTE REBIRTH BYPASS =====
    local cachedRebirthRemote = nil

    local function fireRebirthRemote()
        -- Use cached reference if we have already located the remote
        if cachedRebirthRemote then
            pcall(function()
                if cachedRebirthRemote:IsA("RemoteEvent") then
                    cachedRebirthRemote:FireServer()
                    cachedRebirthRemote:FireServer(1)
                    cachedRebirthRemote:FireServer(true)
                elseif cachedRebirthRemote:IsA("RemoteFunction") then
                    cachedRebirthRemote:InvokeServer()
                    cachedRebirthRemote:InvokeServer(1)
                    cachedRebirthRemote:InvokeServer(true)
                end
            end)
            return
        end

        -- Fallback: Scan ReplicatedStorage if not cached
        local replicatedStorage = game:GetService("ReplicatedStorage")
        for _, desc in ipairs(replicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
                local nameLower = string.lower(desc.Name)
                -- Avoid auto-rebirth toggles and scan for common alternate names
                if (string.find(nameLower, "rebirth") or string.find(nameLower, "reborn")) and not string.find(nameLower, "auto") then
                    cachedRebirthRemote = desc
                    pcall(function()
                        if desc:IsA("RemoteEvent") then
                            desc:FireServer()
                            desc:FireServer(1)
                            desc:FireServer(true)
                        elseif desc:IsA("RemoteFunction") then
                            desc:InvokeServer()
                            desc:InvokeServer(1)
                            desc:InvokeServer(true)
                        end
                    end)
                    break
                end
            end
        end
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
            -- Match pattern: try parsing "Level: 57/75" or standard format "57/75"
            local current, target = text:match("(%d+)%s*/%s*(%d+)")
            if not current or not target then
                current, target = text:match("Level%s*:?%s*(%d+)%s*/%s*(%d+)")
            end

            if current and target then
                local curLvl = tonumber(current)
                local tgtLvl = tonumber(target)
                if curLvl and tgtLvl then
                    return curLvl >= tgtLvl
                end
            else
                warn("[AutoRebirth] Could not parse your level text: " .. tostring(text))
            end
        else
            warn("[AutoRebirth] Level Label UI element not found or invalid.")
        end
        return false
    end

    -- ===== REBIRTH VIA NETWORK REMOTE =====
    local function performRebirth()
        -- Fire direct Remotes as the sole rebirth method
        fireRebirthRemote()
        task.wait(0.5)

        -- Verify eligibility (if the remote succeeded, your level will have reset, ending execution)
        if not checkRebirthEligibility() then
            print("[AutoRebirth] Successfully rebirthed via RemoteEvent!")
            return true
        end

        return false
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