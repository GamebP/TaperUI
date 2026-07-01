-- auto_clean.lua
-- Paste this into your executor (or place in TaperUI/games/<game_id>.lua)

return function(parent, config)
    -- Import TaperUI elements (if available)
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport and taperImport("helper/elements")

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Workspace = game:GetService("Workspace")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local RunService = game:GetService("RunService")

    -- State
    local cleanActive = false
    local loopInterval = 1.0

    -- Helper: Teleport to a position
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(pos)
        return true
    end

    -- Helper: Simulate touching a part (to trigger cleaning)
    local function touchPart(part)
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Save original CFrame
        local origCF = root.CFrame

        -- Teleport root on top of the part
        root.CFrame = part.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.05)

        -- Fire touch events (if available)
        if typeof(firetouchinterest) == "function" then
            firetouchinterest(part, root, 0)  -- touch begin
            task.wait(0.05)
            firetouchinterest(part, root, 1)  -- touch end
        end

        -- Also try clicking if the part has a ClickDetector or ProximityPrompt
        local clickDetector = part:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            clickDetector:Click()
        end

        local prompt = part:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            if typeof(fireproximityprompt) == "function" then
                fireproximityprompt(prompt)
            else
                -- Simulate key press (E by default)
                local key = prompt.KeyboardKeyCode or Enum.KeyCode.E
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end

        -- Restore position
        root.CFrame = origCF
    end

    -- Main cleaning loop
    local function cleanLoop()
        while cleanActive do
            pcall(function()
                -- Find all dirt spots (CleanDot) in Workspace
                local dirtSpots = {}
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "CleanDot" then
                        table.insert(dirtSpots, obj)
                    end
                end

                if #dirtSpots == 0 then
                    warn("[AutoClean] No CleanDot found. Waiting...")
                    task.wait(loopInterval)
                    return
                end

                -- Sort by distance (optional) to clean nearest first
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    table.sort(dirtSpots, function(a, b)
                        return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
                    end)
                end

                for _, spot in ipairs(dirtSpots) do
                    if not cleanActive then break end
                    if not spot.Parent then continue end -- might have been cleaned

                    -- Teleport to the dirt
                    local success = teleportTo(spot.Position + Vector3.new(0, 2, 0))
                    if success then
                        task.wait(0.1)
                        touchPart(spot)
                        task.wait(0.3)  -- allow time for cleaning animation
                    end
                end
            end)

            task.wait(loopInterval)
        end
    end

    -- UI (if using TaperUI)
    if elements then
        elements:Label("🧹 Auto Clean", parent)

        elements:Toggle("Auto Clean", parent, false, function(state)
            cleanActive = state
            if cleanActive then
                task.spawn(cleanLoop)
            end
        end)

        elements:Textbox("Loop Interval (s)", parent, tostring(loopInterval), function(text)
            local val = tonumber(text)
            if val and val > 0 then
                loopInterval = val
            else
                warn("[AutoClean] Invalid interval, keeping " .. loopInterval)
            end
        end)

        elements:Button("Clean Once (Test)", parent, function()
            -- Find all CleanDot and clean them once
            local spots = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == "CleanDot" then
                    table.insert(spots, obj)
                end
            end
            for _, spot in ipairs(spots) do
                teleportTo(spot.Position + Vector3.new(0, 2, 0))
                task.wait(0.1)
                touchPart(spot)
                task.wait(0.2)
            end
        end)
    else
        -- Standalone version: start automatically with a keybind
        print("[AutoClean] No UI found. Press F5 to toggle cleaning.")
        local toggled = false
        game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.F5 then
                cleanActive = not cleanActive
                toggled = true
                print("[AutoClean] " .. (cleanActive and "Started" or "Stopped"))
                if cleanActive then task.spawn(cleanLoop) end
            end
        end)
    end

    -- Cleanup on destroy
    parent.Destroying:Connect(function()
        cleanActive = false
    end)
end