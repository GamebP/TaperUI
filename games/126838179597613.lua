-- TOOD: Fix money silent platform teleport.

-- TOOD: Add other upgradables
-- TODO: Add auto win Soccer AI

return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store player and service references
    local Players = game:GetService("Players")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local LocalPlayer = Players.LocalPlayer

    -- Defensive initialization guard to block fake executor clicks during UI construction
    local scriptInitTime = tick()
    local function isReady()
        return (tick() - scriptInitTime) > 1.0
    end

    -- Localized State Configuration for Win Farm
    local winFarmActive = false
    local loopInterval = 0.5
    local selectedWorld = "World1"
    local selectedGate = "4"
    local lastLockWarning = 0

    -- Localized State Configuration for Auto Rebirth
    local autoRebirthActive = false

    -- Tracks selected gates individually per world
    local selectedGates = {
        World1 = "4",
        World2 = "11",
        World3 = "21",
        World4 = "31"
    }

    -- Build separated static lists for the gates
    local gatesW1 = {}
    for i = 1, 10 do table.insert(gatesW1, tostring(i)) end

    local gatesW2 = {}
    for i = 11, 20 do table.insert(gatesW2, tostring(i)) end

    local gatesW3 = {}
    for i = 21, 30 do table.insert(gatesW3, tostring(i)) end

    local gatesW4 = {}
    for i = 31, 40 do table.insert(gatesW4, tostring(i)) end

    local worlds = {"World1", "World2", "World3", "World4"}

    -- Localized State Configuration for AFK Training
    local autoTrainActive = false
    local selectedTrainingSpot = "World 1 - 1x (0 Rebirth)"
    local lastTrainWarning = 0
    
    local trainingSpots = {
        ["World 1 - 1x (0 Rebirth)"] = {pos = Vector3.new(791, 9, 635), req = 0},
        ["World 1 - 1.5x (1 Rebirth)"] = {pos = Vector3.new(791, 9, 608), req = 1},
        ["World 1 - 2x (3 Rebirth)"] = {pos = Vector3.new(791, 9, 578), req = 3},
        ["World 1 - 3x (5 Rebirth)"] = {pos = Vector3.new(790, 9, 549), req = 5},
        
        ["World 2 - 4x (2 Rebirth)"] = {pos = Vector3.new(-53, 9, 34), req = 2},
        ["World 2 - 6x (3 Rebirth)"] = {pos = Vector3.new(-53, 9, 7), req = 3},
        ["World 2 - 10x (5 Rebirth)"] = {pos = Vector3.new(-53, 9, -23), req = 5},
        ["World 2 - 15x (10 Rebirth)"] = {pos = Vector3.new(-53, 9, -50), req = 10},
        
        ["World 3 - 5x (4 Rebirth)"] = {pos = Vector3.new(-764, 9, 754), req = 4},
        ["World 3 - 8x (7 Rebirth)"] = {pos = Vector3.new(-764, 9, 726), req = 7},
        ["World 3 - 12x (10 Rebirth)"] = {pos = Vector3.new(-764, 9, 697), req = 10},
        ["World 3 - 15x (12 Rebirth)"] = {pos = Vector3.new(-764, 9, 670), req = 12},
        
        ["World 4 - 8x (6 Rebirth)"] = {pos = Vector3.new(-868, 9, 34), req = 6},
        ["World 4 - 12x (10 Rebirth)"] = {pos = Vector3.new(-868, 9, 7), req = 10},
        ["World 4 - 18x (15 Rebirth)"] = {pos = Vector3.new(-868, 9, -23), req = 15},
        ["World 4 - 25x (20 Rebirth)"] = {pos = Vector3.new(-868, 9, -50), req = 20}
    }

    local trainingChoices = {
        "World 1 - 1x (0 Rebirth)",
        "World 1 - 1.5x (1 Rebirth)",
        "World 1 - 2x (3 Rebirth)",
        "World 1 - 3x (5 Rebirth)",
        "World 2 - 4x (2 Rebirth)",
        "World 2 - 6x (3 Rebirth)",
        "World 2 - 10x (5 Rebirth)",
        "World 2 - 15x (10 Rebirth)",
        "World 3 - 5x (4 Rebirth)",
        "World 3 - 8x (7 Rebirth)",
        "World 3 - 12x (10 Rebirth)",
        "World 3 - 15x (12 Rebirth)",
        "World 4 - 8x (6 Rebirth)",
        "World 4 - 12x (10 Rebirth)",
        "World 4 - 18x (15 Rebirth)",
        "World 4 - 25x (20 Rebirth)"
    }

    -- Localized State Configuration for Hatching
    local autoHatchActive = false
    local hatchInterval = 1.0
    local selectedEggCombo = "World1 - Egg1"
    local selectedHatchKey = Enum.KeyCode.E
    local hasPressedT = false
    local lastAffordWarning = 0

    -- Static mappings for targetable Eggs
    local eggChoices = {
        "World1 - Egg1", "World1 - Egg2",
        "World2 - Egg3", "World2 - Egg4",
        "World3 - Egg5", "World3 - Egg6",
        "World4 - Egg7", "World4 - Egg8"
    }

    -- Helper: Safely reads the client's rebirth count from leaderstats
    local function getRebirthCount()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local rebirthVal = leaderstats:FindFirstChild("Rebirth")
            if rebirthVal then
                return tonumber(rebirthVal.Value) or 0
            end
        end
        return 0
    end

    -- Suffix multipliers to evaluate simulator values
    local suffixMultiplier = {
        K = 1e3,
        M = 1e6,
        B = 1e9,
        T = 1e12,
        QA = 1e15,
        QD = 1e15,
        QI = 1e18,
        QT = 1e18,
        SX = 1e21,
        SP = 1e24,
        OC = 1e27,
        NO = 1e30,
        NN = 1e30,
        DC = 1e33
    }

    -- Helper: Parses abbreviated formatted numbers into raw numerical values
    local function parseAbbreviatedNumber(str)
        if not str then return 0 end
        str = str:gsub(",", ""):match("^%s*(.-)%s*$")
        local numPart, suffixPart = str:match("^([%d%.]+)%s*([%a]*)")
        if not numPart then return 0 end
        
        local num = tonumber(numPart) or 0
        if suffixPart and suffixPart ~= "" then
            local suffix = suffixPart:upper()
            local multiplier = suffixMultiplier[suffix]
            if multiplier then
                return num * multiplier
            end
        end
        return num
    end

    -- Helper: Formats numbers back into standard abbreviations for debug logging
    local function formatBigNumber(val)
        if not val then return "0" end
        if val >= 1e33 then return string.format("%.2fDC", val / 1e33)
        elseif val >= 1e30 then return string.format("%.2fNO", val / 1e30)
        elseif val >= 1e27 then return string.format("%.2fOC", val / 1e27)
        elseif val >= 1e24 then return string.format("%.2fSP", val / 1e24)
        elseif val >= 1e21 then return string.format("%.2fSX", val / 1e21)
        elseif val >= 1e18 then return string.format("%.2fQI", val / 1e18)
        elseif val >= 1e15 then return string.format("%.2fQD", val / 1e15)
        elseif val >= 1e12 then return string.format("%.2fT", val / 1e12)
        elseif val >= 1e9 then return string.format("%.2fB", val / 1e9)
        elseif val >= 1e6 then return string.format("%.2fM", val / 1e6)
        elseif val >= 1e3 then return string.format("%.2fK", val / 1e3)
        end
        return string.format("%.2f", val)
    end

    -- Helper: Safely reads the client's current Wins balance from leaderstats
    local function getWinsCount()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local winsVal = leaderstats:FindFirstChild("Wins") or leaderstats:FindFirstChild("Win")
            if winsVal then
                if winsVal:IsA("StringValue") then
                    return parseAbbreviatedNumber(winsVal.Value)
                else
                    return tonumber(winsVal.Value) or 0
                end
            end
        end
        return 0
    end

    -- Helper: Checks whether the player's balance allows the targeted hatch purchase
    local function canAffordEgg()
        local eggWorld, eggName = selectedEggCombo:match("^(World%d+)%s*-%s*(Egg%d+)$")
        if not eggWorld or not eggName then return true, 0, 0 end

        local costParsed = nil
        local success = pcall(function()
            local eggsFolder = workspace:FindFirstChild("Eggs")
            if not eggsFolder then return end
            local worldFolder = eggsFolder:FindFirstChild(eggWorld)
            if not worldFolder then return end
            local eggFolder = worldFolder:FindFirstChild(eggName)
            if not eggFolder then return end
            
            local primary = eggFolder:FindFirstChild("PetSystemEggModel") and eggFolder.PetSystemEggModel:FindFirstChild("Primary")
            if not primary then return end
            
            local priceTemplate = primary:FindFirstChild("Template_Egg_Price")
            if not priceTemplate then return end
            
            local frame = priceTemplate:FindFirstChild("Frame")
            if not frame then return end
            
            local textLabel = frame:FindFirstChild("TextLabel")
            if textLabel and textLabel:IsA("TextLabel") then
                costParsed = parseAbbreviatedNumber(textLabel.Text)
            end
        end)

        -- If path failed to resolve, proceed to prevent blocking the hatch loop on game structural changes
        if not success or costParsed == nil then
            return true, 0, 0
        end

        local currentWins = getWinsCount()
        return currentWins >= costParsed, costParsed, currentWins
    end

    -- Helper: Returns the upgraded hatch limit count dynamically from PlayerGui
    local function getUpgradedHatchAmount()
        local amount = 2 -- Fallback default is 2
        pcall(function()
            local upgradesFrame = LocalPlayer.PlayerGui.MainUI.Frames.Upgrades.UpgradesFrame
            local scrollingFrame = upgradesFrame:FindFirstChild("ScrollingFrame")
            if scrollingFrame then
                local targetLabel = nil
                local template = scrollingFrame:FindFirstChild("Template")
                if template then
                    local stats = template:FindFirstChild("Stats")
                    targetLabel = stats and stats:FindFirstChild("current")
                end
                
                -- Fallback lookup if templates are renamed dynamically
                if not targetLabel or not targetLabel:IsA("TextLabel") then
                    for _, child in ipairs(scrollingFrame:GetChildren()) do
                        local stats = child:FindFirstChild("Stats")
                        local current = stats and stats:FindFirstChild("current")
                        if current and current:IsA("TextLabel") then
                            local text = current.Text
                            if text:find("-") or text:find("%%") then
                                targetLabel = current
                                break
                            end
                        end
                    end
                end

                if targetLabel and targetLabel:IsA("TextLabel") then
                    local cleanText = targetLabel.Text:gsub("%-", ""):gsub("%%", "")
                    local parsedVal = tonumber(cleanText)
                    if parsedVal and parsedVal > 2 then
                        amount = parsedVal
                    end
                end
            end
        end)
        return amount
    end

    -- Helper: Parses active Level progress and safely triggers the rebirth button signals
    local function checkAndExecuteRebirth()
        pcall(function()
            local rebirthFrame = LocalPlayer.PlayerGui.MainUI.Frames.Rebirth.RebirthFrame
            local amountLabel = rebirthFrame:FindFirstChild("Cost") and rebirthFrame.Cost:FindFirstChild("Amount")
            local rebirthButton = rebirthFrame:FindFirstChild("RebirthButton")

            if amountLabel and amountLabel:IsA("TextLabel") and rebirthButton then
                local text = amountLabel.Text -- expected format: "Level: 82/85"
                local currentStr, requiredStr = text:match("(%d+)%s*/%s*(%d+)")
                
                if currentStr and requiredStr then
                    local currentLevel = tonumber(currentStr)
                    local requiredLevel = tonumber(requiredStr)
                    
                    if currentLevel and requiredLevel and currentLevel >= requiredLevel then
                        if typeof(firesignal) == "function" then
                            firesignal(rebirthButton.MouseButton1Click)
                            firesignal(rebirthButton.Activated)
                        end
                    end
                end
            end
        end)
    end

    -- Helper: Teleports player's character to a Vector3 position
    local function teleportTo(pos)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = UDim2 or CFrame.new(pos)
            return true
        end
        return false
    end

    -- Helper: Verifies unlock status of specific goal markers dynamically
    local function isSpecificGateUnlocked(worldName, gateName)
        local success, result = pcall(function()
            local goalFolder = workspace.Goals:FindFirstChild(worldName)
            if not goalFolder then 
                -- If previous world is streamed out, assume unlocked as we have transitioned beyond it
                return true 
            end
            
            local gateFolder = goalFolder:FindFirstChild(gateName)
            if not gateFolder then return true end
            
            local keeperStatus = gateFolder:FindFirstChild("KeeperStatus")
            if not keeperStatus then 
                return true
            end

            local status = keeperStatus.Anchor.BillboardGui.Frame.Status
            local unlocked = status:FindFirstChild("Unlocked")

            if unlocked then
                if unlocked:IsA("BoolValue") then
                    return unlocked.Value
                elseif unlocked:IsA("StringValue") then
                    return unlocked.Value:lower() == "unlocked" or unlocked.Value == "true"
                elseif unlocked:IsA("GuiObject") then
                    return unlocked.Visible
                end
                return true
            end

            if status:IsA("TextLabel") then
                return status.Text:lower():find("unlocked") ~= nil
            end

            return false
        end)
        
        if not success then
            return true -- Fallback to prevent locking the loop on standard path errors
        end
        return result
    end

    -- Helper: Verifies if the selected gate's keeper status is Unlocked
    local function isGateUnlocked()
        -- Boundaries transition checks matching game gate structures
        if selectedGate == "11" then
            return isSpecificGateUnlocked("World1", "10")
        elseif selectedGate == "21" then
            return isSpecificGateUnlocked("World2", "20")
        elseif selectedGate == "31" then
            return isSpecificGateUnlocked("World3", "30")
        end

        return isSpecificGateUnlocked(selectedWorld, selectedGate)
    end

    -- Helper: Safely resolve the path to the selected target part
    local function getTargetPart()
        local success, part = pcall(function()
            return workspace.Goals[selectedWorld][selectedGate].Wins.Anchor
        end)
        return success and part or nil
    end

    -- Helper: Simulates physical touch interaction at target location and returns to original position
    local function fireTouch()
        if not isGateUnlocked() then
            local now = tick()
            if now - lastLockWarning > 5 then
                warn("[Auto Win] Selected Gate is locked. Farms will resume once unlocked.")
                lastLockWarning = now
            end
            return
        end

        local targetPart = getTargetPart()
        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")

        if targetPart and rootPart then
            -- 1. Cache the original CFrame before the sequence begins
            local originalCFrame = rootPart.CFrame

            -- 2. Teleport client to the target win trigger to process server collision bounds
            rootPart.CFrame = targetPart.CFrame
            task.wait(0.08) -- Minimum physical latency allowance for engine update

            -- 3. Execute touch bounds verification via client pipeline
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(targetPart, rootPart, 0) -- Touch began
                task.wait(0.02)
                firetouchinterest(targetPart, rootPart, 1) -- Touch ended
            end

            -- 4. Restore character positioning seamlessly to original vector coordinates
            rootPart.CFrame = originalCFrame
        else
            warn("[Error] Target part or your character's HumanoidRootPart was not found.")
        end
    end

    -- Safely resolve the path to the ProximityPrompt and its parent part on each tick
    local function getPromptAndParent()
        local eggWorld, eggName = selectedEggCombo:match("^(World%d+)%s*-%s*(Egg%d+)$")
        if not eggWorld or not eggName then return nil end

        local success, result = pcall(function()
            local eggFolder = workspace.Eggs[eggWorld][eggName]
            local primary = eggFolder.PetSystemEggModel.Primary
            local prompt = primary:FindFirstChildOfClass("ProximityPrompt") or primary:FindFirstChild(eggName)
            return {Prompt = prompt, Part = primary}
        end)
        return success and result or nil
    end

    -- Simulates an actual physical key hold/release using the game engine input pipeline
    local function simulatePhysicalKeyPress(duration, keyCode)
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game) -- Press designated key down
            task.wait(duration + 0.05) -- Hold for the prompt duration + a tiny buffer
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game) -- Release designated key
        else
            warn("[Unsupported] VirtualInputManager is not available on this executor.")
        end
    end

    -- Teleports the egg directly to you, physically holds selected key, and teleports the egg back
    local function executeInteraction()
        -- Affordability Check
        local affordable, cost, currentWins = canAffordEgg()
        if not affordable then
            local now = tick()
            if now - lastAffordWarning > 5 then
                warn(string.format("[Auto Hatch] Cannot afford selected egg. Cost: %s, Current Wins: %s", formatBigNumber(cost), formatBigNumber(currentWins)))
                lastAffordWarning = now
            end
            return
        end

        local target = getPromptAndParent()
        if not target or not target.Prompt or not target.Part then
            return
        end

        local prompt = target.Prompt
        local parentPart = target.Part

        local char = LocalPlayer.Character
        local rootPart = char and char:FindFirstChild("HumanoidRootPart")

        if rootPart and parentPart then
            -- 1. Store the egg's original position
            local originalCFrame = parentPart.CFrame 
            
            -- 2. Teleport the EGG directly to your position client-side (You do not move)
            parentPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2) -- Places it 2 studs in front of you
            
            -- 3. Let the client engine register the prompt's updated close-range position
            task.wait(0.1)
            
            -- 4. Simulate the hardware keypress on the prompt with chosen key
            local holdTime = prompt.HoldDuration or 0
            simulatePhysicalKeyPress(holdTime, selectedHatchKey)
            
            -- 5. Give the server a moment to accept the transaction, then restore the egg to its spot
            task.wait(0.05)
            parentPart.CFrame = originalCFrame
        end
    end

    -- UI: Automation Utilities Section
    elements:Label("🔥 Automation Utilities", parent)

    -- Pre-declare the dropdown variables to reference them in the callbacks
    local dropdownW1, dropdownW2, dropdownW3, dropdownW4

    local function updateGateDropdownVisibility()
        if dropdownW1 then dropdownW1.Visible = (selectedWorld == "World1") end
        if dropdownW2 then dropdownW2.Visible = (selectedWorld == "World2") end
        if dropdownW3 then dropdownW3.Visible = (selectedWorld == "World3") end
        if dropdownW4 then dropdownW4.Visible = (selectedWorld == "World4") end
    end

    -- Dropdown to pick the World
    elements:Dropdown("Select World", parent, worlds, selectedWorld, function(value)
        selectedWorld = value
        selectedGate = selectedGates[value] or "4"
        updateGateDropdownVisibility()
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 1
    dropdownW1 = elements:Dropdown("Select Win Anchor (World 1)", parent, gatesW1, "4", function(value)
        selectedGates.World1 = value
        selectedGate = value
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 2
    dropdownW2 = elements:Dropdown("Select Win Anchor (World 2)", parent, gatesW2, "11", function(value)
        selectedGates.World2 = value
        selectedGate = value
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 3
    dropdownW3 = elements:Dropdown("Select Win Anchor (World 3)", parent, gatesW3, "21", function(value)
        selectedGates.World3 = value
        selectedGate = value
    end)

    -- Dropdown to pick the Win Anchor (Gate) for World 4
    dropdownW4 = elements:Dropdown("Select Win Anchor (World 4)", parent, gatesW4, "31", function(value)
        selectedGates.World4 = value
        selectedGate = value
    end)

    -- Align initial state visibility
    updateGateDropdownVisibility()

    -- Textbox to change how fast it transmits (in seconds)
    elements:Textbox("Transmit Interval (s)", parent, tostring(loopInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            loopInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number for the interval.")
        end
    end)

    -- Toggle for Auto Rebirth Checking
    elements:Toggle("Auto Rebirth", parent, false, function(state)
        if not isReady() or not state then
            autoRebirthActive = false
            return
        end

        autoRebirthActive = true
        task.spawn(function()
            while autoRebirthActive do
                checkAndExecuteRebirth()
                task.wait(2.0)
            end
        end)
    end)

    -- Toggle for Touch Farm Loop
    elements:Toggle("Auto Win Farm", parent, false, function(state)
        if not isReady() or not state then
            winFarmActive = false
            return
        end

        winFarmActive = true
        task.spawn(function()
            while winFarmActive do
                fireTouch()
                task.wait(loopInterval)
            end
        end)
    end)

    -- UI: AFK Training Section
    elements:Label("⚡ AFK Training", parent)

    -- Dropdown to choose a training target location
    elements:Dropdown("Select AFK Target", parent, trainingChoices, selectedTrainingSpot, function(value)
        selectedTrainingSpot = value
    end)

    -- Toggle to maintain teleport position on the training target
    elements:Toggle("Auto Train (AFK Loop)", parent, false, function(state)
        if not isReady() or not state then
            autoTrainActive = false
            return
        end

        autoTrainActive = true
        task.spawn(function()
            while autoTrainActive do
                local spotInfo = trainingSpots[selectedTrainingSpot]
                if spotInfo then
                    local currentRebirths = getRebirthCount()
                    if currentRebirths >= spotInfo.req then
                        teleportTo(spotInfo.pos)
                    else
                        local now = tick()
                        if now - lastTrainWarning > 5 then
                            warn(string.format("[Auto Train] Blocked. Requires %d Rebirths (You have %d).", spotInfo.req, currentRebirths))
                            lastTrainWarning = now
                        end
                    end
                end
                task.wait(1.5) -- Periodically re-aligns position against game reset scripts
            end
        end)
    end)

    -- UI: Egg Hatching Section
    elements:Label("🥚 Hatching Utilities", parent)

    -- Dropdown to pick the target Egg
    elements:Dropdown("Select Egg Target", parent, eggChoices, selectedEggCombo, function(value)
        selectedEggCombo = value
        hasPressedT = false
    end)

    -- Dynamically read player upgrades to determine true visual hatch limit options
    local dynamicHatchLimit = getUpgradedHatchAmount()
    local modeROption = string.format("R (%dx Open)", dynamicHatchLimit)
    local modeTOption = string.format("T (Auto %dx Open)", dynamicHatchLimit)

    -- Dropdown to select Key / Open Mode
    elements:Dropdown("Hatch Mode (Key)", parent, {"E (1x Open)", modeROption, modeTOption}, "E (1x Open)", function(value)
        if value:sub(1, 1) == "E" then
            selectedHatchKey = Enum.KeyCode.E
        elseif value:sub(1, 1) == "R" then
            selectedHatchKey = Enum.KeyCode.R
        elseif value:sub(1, 1) == "T" then
            selectedHatchKey = Enum.KeyCode.T
        end
        hasPressedT = false
    end)

    -- Textbox to adjust hatching speed (in seconds)
    elements:Textbox("Hatch Interval (s)", parent, tostring(hatchInterval), function(text)
        local customInterval = tonumber(text)
        if customInterval and customInterval >= 0 then
            hatchInterval = customInterval
        else
            warn("[Invalid] Please enter a valid positive number for the hatch interval.")
        end
    end)

    -- Toggle for Auto Hatch Loop
    elements:Toggle("Auto Hatch Eggs", parent, false, function(state)
        if not isReady() or not state then
            autoHatchActive = false
            hasPressedT = false
            return
        end

        autoHatchActive = true
        task.spawn(function()
            while autoHatchActive do
                if selectedHatchKey == Enum.KeyCode.T then
                    if not hasPressedT then
                        executeInteraction()
                        hasPressedT = true
                    end
                else
                    executeInteraction()
                end
                task.wait(hatchInterval)
            end
        end)
    end)
end