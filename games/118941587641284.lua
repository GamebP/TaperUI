-- ============================================================
--  TAPERUI - STANDALONE GAME SCRIPT
--  Place ID: 118941587641284 | World 1 - 7 Unified Edition
-- ============================================================

-- 1. Enable Developer Mode to bypass the automatic multi-game hub loader
getgenv().TaperUI_DeveloperMode = true

-- 2. Load the TaperUI framework library
local TaperUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/UI.lua"))()

-- 3. Create a Custom Window
local Window = TaperUI:CreateWindow({
    Name = "Basketball",
    LoadingTitle = "Just plating the game",
    LoadingSubtitle = "Basketball Trainer",
    LoadingVersion = "v5.1",
    ProfileSubtitle = "bum lad"
})

-- 4. Create custom tabs
local FarmTab = Window:CreateTab("Autofarm", TaperAssets.list)
local EggTab = Window:CreateTab("Eggs & Pets", TaperAssets.eye)
local UpgradeTab = Window:CreateTab("Upgrades", TaperAssets.unlock)
local ShopTab = Window:CreateTab("Shop & World", TaperAssets.script)
local SocialTab = Window:CreateTab("Socials", TaperAssets.user)

-- 5. Auto-inject the standard TaperUI settings tab
Window:CreateSettingsTab()

-- ============================================================
--  CORE DATA & SETUP
-- ============================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Safely resolve events folder
local Events = ReplicatedStorage:WaitForChild("Events", 5)
local RequestServerAction = Events and Events:WaitForChild("RequestServerAction", 5)
local InvokeServerAction = Events and Events:WaitForChild("InvokeServerAction", 5)
local ClientAction = Events and Events:WaitForChild("ClientAction", 5)

-- Explicitly wait for leaderstats to load to prevent nil errors during early execution
local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
local powerObj = leaderstats and leaderstats:WaitForChild("Power", 10)
local moneyObj = leaderstats and leaderstats:WaitForChild("Money", 10)

-- State Variables
local activeWorldID = 1 -- 1 to 7

local autoTrainActive = false
local trainMethod = "Dynamic (Auto)"
local trainInterval = 0.1

local autoWinActive = false
local winInterval = 1.0

local autoDunkActive = false
local autoHatchActive = false
local selectedEggW1 = "Basic"
local selectedEggW2 = "Cactus"
local selectedEggW3 = "Nut"
local selectedEggW4 = "Hot Chocolate"
local selectedEggW5 = "Ocean"
local selectedEggW6 = "Molten Lava"
local selectedEggW7 = "Enchanted"

-- Auto-Delete state variables
local deleteCommon = false
local deleteUncommon = false
local deleteRare = false
local deleteEpic = false
local keepMultiplierThreshold = 1.5
local autoDeleteActive = false

-- Forward declaration for visual UI alignment
local updateEggDropdownVisibility

local autoRebirthActive = false
local rebirthAmount = 1

local autoBuyToolsActive = false
local buyToolsInterval = 1.0

local autoUpgradeActive = false
local selectedUpgradeTarget = "None"

local targetZoneID = "2"

-- Retrieve and parse the live data.json directory from GitHub
local gameList = {}
local fetchSuccess, rawData = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/helper/data.json")
end)

if fetchSuccess and rawData then
    local decodeSuccess, decoded = pcall(function()
        return HttpService:JSONDecode(rawData)
    end)
    if decodeSuccess and decoded and decoded.gameList then
        gameList = decoded.gameList
    end
end

-- Caching Table for Rebirth Costs
local cachedCosts = {}

-- Safely retrieve numerical values
local function getMyStrength()
    return powerObj and powerObj.Value or 0
end

local function getMyMoney()
    return moneyObj and moneyObj.Value or 0
end

-- Case-insensitive Suffix Map scaling up to Centillion (1e303)
local suffixMap = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24, oc = 1e27, no = 1e30, dc = 1e33,
    ud = 1e36, dd = 1e39, td = 1e42, qtd = 1e45, qid = 1e48, sxd = 1e51, spd = 1e54, ocd = 1e57, nod = 1e60, vg = 1e63,
    uvg = 1e66, dvg = 1e69, tvg = 1e72, qavg = 1e75, qivg = 1e78, sxvg = 1e81, spvg = 1e84, ocvg = 1e87, novg = 1e90, tg = 1e93,
    utg = 1e96, dtg = 1e99, ttg = 1e102, qatg = 1e105, qitg = 1e108,
    qd = 1e123, uqd = 1e126, dqd = 1e129, tqd = 1e132, qaqd = 1e135, qiqd = 1e138, sxqd = 1e141, spqd = 1e144, ocqd = 1e147, noqd = 1e150,
    qn = 1e153, uqn = 1e156, dqn = 1e159, tqn = 1e162, qaqn = 1e165, qiqn = 1e168, sxqn = 1e171, spqn = 1e174, ocqn = 1e177, noqn = 1e180,
    sxg = 1e183, usxg = 1e186, dsxg = 1e189, tsxg = 1e192, qasxg = 1e195, qisxg = 1e198, sxsxg = 1e201, spsxg = 1e204, ocsxg = 1e207, nosxg = 1e210,
    spg = 1e213, uspg = 1e216, dspg = 1e219, tspg = 1e222, qaspg = 1e225, qispg = 1e228, sxspg = 1e231, spspg = 1e234, ocspg = 1e237, nospg = 1e240,
    ocg = 1e243, uocg = 1e246, docg = 1e249, tocg = 1e252, qaocg = 1e255, qiocg = 1e258, sxocg = 1e261, spocg = 1e264, ococg = 1e267, noocg = 1e270,
    nog = 1e273, unog = 1e276, dnog = 1e279, tnog = 1e282, qanog = 1e285, qinog = 1e288, sxnog = 1e291, spnog = 1e294, ocnog = 1e297, nonog = 1e300,
    ce = 1e303
}

local function parsePriceText(text)
    if not text then return 0 end
    local cleanText = text:gsub("[Mm]oney", ""):gsub("[Cc]ash", ""):gsub("%s+", "")
    
    -- Evaluate natively if string is already formatted as scientific notation (e.g. 1e+24)
    local maybeNum = tonumber(cleanText)
    if maybeNum then
        return maybeNum
    end

    local valStr, suffix = cleanText:match("^([%d%.]+)([A-Za-z]*)$")
    if not valStr then return 0 end
    local num = tonumber(valStr) or 0
    
    if suffix and suffix ~= "" then
        local lowerSuffix = suffix:lower()
        if suffixMap[lowerSuffix] then
            num = num * suffixMap[lowerSuffix]
        end
    end
    return num
end

-- Read & Cache rebirth costs dynamically from local PlayerGui to avoid execution lag
local function getRebirthCost(amount)
    if cachedCosts[amount] then
        return cachedCosts[amount]
    end
    
    local path = LocalPlayer:FindFirstChild("PlayerGui")
        and LocalPlayer.PlayerGui:FindFirstChild("MainUI")
        and LocalPlayer.PlayerGui:FindFirstChild("Menus")
        and LocalPlayer.PlayerGui.MainUI.Menus:FindFirstChild("Rebirths")
        and LocalPlayer.PlayerGui.MainUI.Menus:FindFirstChild("ScrollingFrameContainer")
        and LocalPlayer.PlayerGui.MainUI.Menus.Rebirths.ScrollingFrameContainer:FindFirstChild("ScrollingFrame")
        
    if path then
        local targetFrame = path:FindFirstChild(tostring(amount))
        if targetFrame and targetFrame:FindFirstChild("Price") and targetFrame.Price:FindFirstChild("TextLabel") then
            local text = targetFrame.Price.TextLabel.Text
            local parsed = parsePriceText(text)
            if parsed > 0 then
                cachedCosts[amount] = parsed
                return parsed
            end
        end
    end
    return nil
end

-- Validate high rebirth options availability prior to purchase requests
local function checkRebirthAvailability(amount)
    if amount < 2500 then return true end -- Standard tiers are always available
    
    local path = LocalPlayer:FindFirstChild("PlayerGui")
        and LocalPlayer.PlayerGui:FindFirstChild("MainUI")
        and LocalPlayer.PlayerGui:FindFirstChild("Menus")
        and LocalPlayer.PlayerGui.MainUI.Menus:FindFirstChild("Rebirths")
        and LocalPlayer.PlayerGui.MainUI.Menus.Rebirths:FindFirstChild("ScrollingFrameContainer")
        and LocalPlayer.PlayerGui.MainUI.Menus.Rebirths.ScrollingFrameContainer:FindFirstChild("ScrollingFrame")
        
    if path then
        return path:FindFirstChild(tostring(amount)) ~= nil
    end
    return false
end

-- Dynamic hoop selector supporting World 1 through 7 thresholds
local function getBestHoopID(world, power)
    if world == 1 then
        if power >= 2.5e6 then return 12          -- 2.5M
        elseif power >= 1.5e6 then return 11      -- 1.5M
        elseif power >= 650e3 then return 10      -- 650K
        elseif power >= 250e3 then return 9       -- 250K
        elseif power >= 125e3 then return 8       -- 125K
        elseif power >= 70e3 then return 7        -- 70K
        elseif power >= 50e3 then return 6        -- 50K
        elseif power >= 25e3 then return 5        -- 25K
        elseif power >= 10e3 then return 4        -- 10K
        elseif power >= 2.5e3 then return 3       -- 2.5K
        elseif power >= 500 then return 2         -- 500
        else return 1 end
    elseif world == 2 then
        if power >= 1.25e9 then return 12         -- 1.25B
        elseif power >= 750e6 then return 11      -- 750M
        elseif power >= 500e6 then return 10      -- 500M
        elseif power >= 350e6 then return 9       -- 350M
        elseif power >= 250e6 then return 8       -- 250M
        elseif power >= 175e6 then return 7       -- 175M
        elseif power >= 100e6 then return 6       -- 100M
        elseif power >= 50e6 then return 5        -- 50M
        elseif power >= 25e6 then return 4        -- 25M
        elseif power >= 5e6 then return 3         -- 5M
        elseif power >= 2.5e6 then return 2       -- 2.5M
        else return 1 end
    elseif world == 3 then
        if power >= 750e9 then return 12          -- 750B
        elseif power >= 400e9 then return 11      -- 400B
        elseif power >= 250e9 then return 10      -- 250B
        elseif power >= 150e9 then return 9       -- 150B
        elseif power >= 90e9 then return 8        -- 90B
        elseif power >= 55e9 then return 7        -- 55B
        elseif power >= 35e9 then return 6        -- 35B
        elseif power >= 18e9 then return 5        -- 18B
        elseif power >= 9e9 then return 4         -- 9B
        elseif power >= 3e9 then return 3         -- 3B
        elseif power >= 1.5e9 then return 2       -- 1.5B
        else return 1 end
    elseif world == 4 then
        if power >= 1e15 then return 12           -- 1Qa
        elseif power >= 500e12 then return 11     -- 500T
        elseif power >= 285e12 then return 10     -- 285T
        elseif power >= 175e12 then return 9      -- 175T
        elseif power >= 125e12 then return 8      -- 125T
        elseif power >= 85e12 then return 7       -- 85T
        elseif power >= 57e12 then return 6       -- 57T
        elseif power >= 45e12 then return 5       -- 45T
        elseif power >= 30e12 then return 4       -- 30T
        elseif power >= 15e12 then return 3       -- 15T
        elseif power >= 7e12 then return 2        -- 7T
        else return 1 end
    elseif world == 5 then
        if power >= 2e18 then return 12           -- 2Qi
        elseif power >= 1.2e18 then return 11     -- 1.2Qi
        elseif power >= 700e15 then return 10     -- 700Qa
        elseif power >= 400e15 then return 9      -- 400Qa
        elseif power >= 250e15 then return 8      -- 250Qa
        elseif power >= 150e15 then return 7      -- 150Qa
        elseif power >= 90e15 then return 6       -- 90Qa
        elseif power >= 50e15 then return 5       -- 50Qa
        elseif power >= 25e15 then return 4       -- 25Qa
        elseif power >= 12.5e15 then return 3     -- 12.5Qa
        elseif power >= 5e15 then return 2        -- 5Qa
        else return 1 end
    elseif world == 6 then
        if power >= 15e21 then return 12          -- 15Sx
        elseif power >= 7.5e21 then return 11     -- 7.5Sx
        elseif power >= 4e21 then return 10       -- 4Sx
        elseif power >= 2.5e21 then return 9      -- 2.5Sx
        elseif power >= 1.5e21 then return 8      -- 1.5Sx
        elseif power >= 850e18 then return 7      -- 850Qi
        elseif power >= 500e18 then return 6      -- 500Qi
        elseif power >= 250e18 then return 5      -- 250Qi
        elseif power >= 120e18 then return 4      -- 120Qi
        elseif power >= 60e18 then return 3       -- 60Qi
        elseif power >= 25e18 then return 2       -- 25Qi
        else return 1 end
    else
        -- World 7 Thresholds
        if power >= 175e24 then return 12         -- 175Sp
        elseif power >= 90e24 then return 11      -- 90Sp
        elseif power >= 50e24 then return 10      -- 50Sp
        elseif power >= 30e24 then return 9       -- 30Sp
        elseif power >= 18e24 then return 8       -- 18Sp
        elseif power >= 10e24 then return 7       -- 10Sp
        elseif power >= 6e24 then return 6        -- 6Sp
        elseif power >= 3.25e24 then return 5     -- 3.25Sp
        elseif power >= 1.6e24 then return 4      -- 1.6Sp
        elseif power >= 800e21 then return 3      -- 800Sx
        elseif power >= 350e21 then return 2      -- 350Sx
        else return 1 end
    end
end

-- Safe retrieval of local player inventory UI folder
local function getPetsFolder()
    local mainUI = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainUI")
    local menus = mainUI and mainUI:FindFirstChild("Menus")
    local petsInventory = menus and menus:FindFirstChild("PetsInventory")
    local main = petsInventory and petsInventory:FindFirstChild("Main")
    local pets = main and main:FindFirstChild("Pets")
    return pets and pets:FindFirstChild("Pets")
end

-- Rarity analyzer based on color sequence gradient matching
local function getPetRarityAndMultiplier(petFrame)
    local scribble = petFrame:FindFirstChild("Scribble")
    local tierGradient = scribble and scribble:FindFirstChild("Tier Gradient")
    local rarity = nil

    if tierGradient then
        if tierGradient.Rotation == -135 then
            rarity = "Legendary"
        else
            local colStr = tostring(tierGradient.Color)
            if colStr:find("0.796078") or colStr:find("0.592157") then
                rarity = "Common"
            elseif colStr:find("0.819608") or colStr:find("0.74902") then
                rarity = "Uncommon"
            elseif colStr:find("0.917647") or colStr:find("0.380392") then
                rarity = "Rare"
            elseif colStr:find("0.854902") or colStr:find("0.619608") then
                rarity = "Epic"
            end
        end
    end

    local infoContainer = petFrame:FindFirstChild("InfoContainer")
    local boost = infoContainer and infoContainer:FindFirstChild("Boost")
    local multiplier = 1.0
    if boost and boost:IsA("TextLabel") then
        local numText = boost.Text:match("[%d%.]+")
        if numText then
            multiplier = tonumber(numText) or 1.0
        end
    end

    return rarity, multiplier
end

-- Auto-delete scanner loop
local function runAutoDeleteLoop()
    task.spawn(function()
        while autoDeleteActive do
            local petsFolder = getPetsFolder()
            if petsFolder then
                local uuidsToDelete = {}
                for _, petFrame in ipairs(petsFolder:GetChildren()) do
                    if petFrame:IsA("Frame") or petFrame:IsA("GuiObject") then
                        local uuid = petFrame.Name
                        if #uuid >= 20 then -- Verify valid UUID string length
                            local rarity, multiplier = getPetRarityAndMultiplier(petFrame)
                            if rarity then
                                local shouldDelete = false
                                if rarity == "Common" and deleteCommon then
                                    shouldDelete = true
                                elseif rarity == "Uncommon" and deleteUncommon then
                                    shouldDelete = true
                                elseif rarity == "Rare" and deleteRare then
                                    shouldDelete = true
                                elseif rarity == "Epic" and deleteEpic then
                                    shouldDelete = true
                                end

                                -- Check multiplier threshold safety limits
                                if shouldDelete and multiplier >= keepMultiplierThreshold then
                                    shouldDelete = false
                                end

                                if shouldDelete then
                                    table.insert(uuidsToDelete, uuid)
                                end
                            end
                        end
                    end
                end

                if #uuidsToDelete > 0 then
                    -- Fire bulk delete remote action
                    pcall(function()
                        InvokeServerAction:InvokeServer("Pets", "Delete", uuidsToDelete)
                    end)
                    -- Redundant fallback for single-target deletion
                    for _, uuid in ipairs(uuidsToDelete) do
                        pcall(function()
                            InvokeServerAction:InvokeServer("Pets", "Delete", uuid)
                        end)
                    end
                end
            end
            task.wait(1.5)
        end
    end)
end

-- ============================================================
--  TAB 1: AUTOFARM CONTROLS
-- ============================================================
FarmTab:CreateLabel("🌍 World Settings")

FarmTab:CreateSelector("Active World", {"World 1", "World 2", "World 3", "World 4", "World 5", "World 6", "World 7"}, "World 1", function(choice)
    local worldMap = {
        ["World 1"] = 1, ["World 2"] = 2, ["World 3"] = 3, 
        ["World 4"] = 4, ["World 5"] = 5, ["World 6"] = 6, ["World 7"] = 7
    }
    activeWorldID = worldMap[choice] or 1
    
    -- Sync egg dropdown visibility if defined
    if updateEggDropdownVisibility then
        updateEggDropdownVisibility()
    end
end)

FarmTab:CreateSpacer(5)
FarmTab:CreateLabel("💪 Training Automation")

-- Training Method Selector
FarmTab:CreateDropdown("Train Method", {
    "Dynamic (Auto)", "Hoop 1", "Hoop 2", "Hoop 3", "Hoop 4", "Hoop 5", 
    "Hoop 6", "Hoop 7", "Hoop 8", "Hoop 9", "Hoop 10", "Hoop 11", "Hoop 12"
}, "Dynamic (Auto)", function(choice)
    trainMethod = choice
end)

-- Auto Train Toggle
FarmTab:CreateToggle("Auto Train Hoop", false, function(state)
    autoTrainActive = state
    if autoTrainActive then
        task.spawn(function()
            while autoTrainActive do
                if RequestServerAction then
                    local hoopID = 1
                    if trainMethod == "Dynamic (Auto)" then
                        local currentPower = getMyStrength()
                        hoopID = getBestHoopID(activeWorldID, currentPower)
                    else
                        hoopID = tonumber(trainMethod:match("%d+")) or 1
                    end
                    pcall(function()
                        RequestServerAction:FireServer("Train", "Increment", hoopID, activeWorldID)
                    end)
                end
                task.wait(trainInterval)
            end
        end)
    end
end)

-- Train Speed Slider
FarmTab:CreateSlider("Train Speed (s)", 0.01, 1.0, trainInterval, 2, function(val)
    trainInterval = val
end)

FarmTab:CreateSpacer(5)
FarmTab:CreateLabel("🏆 Wins & Match Farming")

-- Auto Win Toggle (Consolidated throw-simulate and win flow)
FarmTab:CreateToggle("Auto Win Farm", false, function(state)
    autoWinActive = state
    if autoWinActive then
        task.spawn(function()
            while autoWinActive do
                if InvokeServerAction then
                    pcall(function()
                        InvokeServerAction:InvokeServer(
                            "Win",
                            "Ended",
                            activeWorldID, -- Dynamic World ID
                            99.98,
                            activeWorldID  -- Dynamic World ID
                        )
                    end)
                end
                task.wait(winInterval)
            end
        end)
    end
end)

-- Win Speed Slider (Controls the delay between win registers)
FarmTab:CreateSlider("Win Speed / Delay (s)", 0.1, 5.0, winInterval, 2, function(val)
    winInterval = val
end)

-- Auto Dunk Battle Toggle
FarmTab:CreateToggle("Auto Dunk Battle Win", false, function(state)
    autoDunkActive = state
    if autoDunkActive then
        task.spawn(function()
            while autoDunkActive do
                if RequestServerAction then
                    local currentOpponent = dunkOpponents[activeWorldID] or "Punk Kid"
                    pcall(function()
                        RequestServerAction:FireServer("DunkBattle", "DunkBattleWin", currentOpponent)
                    end)
                end
                task.wait(0.5)
            end
        end)
    end
end)

-- ============================================================
--  TAB 2: EGGS & PETS CONTROLS
-- ============================================================
EggTab:CreateLabel("🥚 Select Egg to Open")

-- Storing dropdown references for visual toggle synchronization
local eggW1Dropdown, eggW2Dropdown, eggW3Dropdown, eggW4Dropdown, eggW5Dropdown, eggW6Dropdown, eggW7Dropdown

-- Select World 1 Egg Dropdown
eggW1Dropdown = EggTab:CreateDropdown("Select World 1 Egg", {"Basic ($250)", "Flower ($25K)", "Tree ($1M)"}, "Basic ($250)", function(choice)
    selectedEggW1 = eggMapW1[choice] or "Basic"
end)

-- Select World 2 Egg Dropdown
eggW2Dropdown = EggTab:CreateDropdown("Select World 2 Egg", {"Cactus ($10M)", "Floatie ($1.25B)", "Pirate ($10B)"}, "Cactus ($10M)", function(choice)
    selectedEggW2 = eggMapW2[choice] or "Cactus"
end)

-- Select World 3 Egg Dropdown
eggW3Dropdown = EggTab:CreateDropdown("Select World 3 Egg", {"Nut ($15B)", "Snowflake ($5T)", "Snowman ($50T)"}, "Nut ($15B)", function(choice)
    selectedEggW3 = eggMapW3[choice] or "Nut"
end)

-- Select World 4 Egg Dropdown
eggW4Dropdown = EggTab:CreateDropdown("Select World 4 Egg", {"Hot Chocolate ($75T)", "Coctail ($12.5Qa)", "Candy Basket ($250Qa)"}, "Hot Chocolate ($75T)", function(choice)
    selectedEggW4 = eggMapW4[choice] or "Hot Chocolate"
end)

-- Select World 5 Egg Dropdown
eggW5Dropdown = EggTab:CreateDropdown("Select World 5 Egg", {"Ocean ($500Qa)", "Aqua ($75Qi)", "Silver Spire ($500Qi)"}, "Ocean ($500Qa)", function(choice)
    selectedEggW5 = eggMapW5[choice] or "Ocean"
end)

-- Select World 6 Egg Dropdown
eggW6Dropdown = EggTab:CreateDropdown("Select World 6 Egg", {"Molten Lava ($1Sx)", "Volcano ($125Sx)", "Dragon ($1Sp)"}, "Molten Lava ($1Sx)", function(choice)
    selectedEggW6 = eggMapW6[choice] or "Molten Lava"
end)

-- Select World 7 Egg Dropdown
eggW7Dropdown = EggTab:CreateDropdown("Select World 7 Egg", {"Enchanted ($125Sp)", "Voidspike ($15Oc)", "Serpent Amethyst ($1No)"}, "Enchanted ($125Sp)", function(choice)
    selectedEggW7 = eggMapW7[choice] or "Enchanted"
end)

-- UI Visual Sync Handler
function updateEggDropdownVisibility()
    if eggW1Dropdown then eggW1Dropdown.Visible = (activeWorldID == 1) end
    if eggW2Dropdown then eggW2Dropdown.Visible = (activeWorldID == 2) end
    if eggW3Dropdown then eggW3Dropdown.Visible = (activeWorldID == 3) end
    if eggW4Dropdown then eggW4Dropdown.Visible = (activeWorldID == 4) end
    if eggW5Dropdown then eggW5Dropdown.Visible = (activeWorldID == 5) end
    if eggW6Dropdown then eggW6Dropdown.Visible = (activeWorldID == 6) end
    if eggW7Dropdown then eggW7Dropdown.Visible = (activeWorldID == 7) end
end

-- Run initial sync alignment
updateEggDropdownVisibility()

EggTab:CreateSpacer(10)

-- Combined Auto Hatch Toggle
EggTab:CreateToggle("Auto Hatch Selected Egg", false, function(state)
    autoHatchActive = state
    if autoHatchActive then
        task.spawn(function()
            while autoHatchActive do
                if InvokeServerAction then
                    local eggName = "Basic"
                    if activeWorldID == 1 then eggName = selectedEggW1
                    elseif activeWorldID == 2 then eggName = selectedEggW2
                    elseif activeWorldID == 3 then eggName = selectedEggW3
                    elseif activeWorldID == 4 then eggName = selectedEggW4
                    elseif activeWorldID == 5 then eggName = selectedEggW5
                    elseif activeWorldID == 6 then eggName = selectedEggW6
                    elseif activeWorldID == 7 then eggName = selectedEggW7
                    end
                    
                    pcall(function()
                        InvokeServerAction:InvokeServer("Eggs", "RequestPurchase", {
                            PetsToAutoDelete = {},
                            EggAmount = "max",
                            EggName = eggName
                        })
                    end)
                end
                task.wait(1.5)
            end
        end)
    end
end)

EggTab:CreateSpacer(5)
EggTab:CreateLabel("🐾 Pet Management")

-- Equip Best Pets Action
EggTab:CreateButton("Equip Best Pets", function()
    if InvokeServerAction then
        pcall(function()
            InvokeServerAction:InvokeServer("Pets", "EquipBest", "EquipBest")
        end)
        if getgenv().showToast then
            getgenv().showToast("Pets Equipped", "Your best pets have been equipped!", TaperAssets.done, 2.0)
        end
    end
end)

EggTab:CreateSpacer(5)
EggTab:CreateLabel("🧹 Auto Delete Pets (Trash Inventory)")

EggTab:CreateToggle("Delete Common", false, function(state)
    deleteCommon = state
end)

EggTab:CreateToggle("Delete Uncommon", false, function(state)
    deleteUncommon = state
end)

EggTab:CreateToggle("Delete Rare", false, function(state)
    deleteRare = state
end)

EggTab:CreateToggle("Delete Epic", false, function(state)
    deleteEpic = state
end)

EggTab:CreateTextbox("Keep if Multiplier >= ", tostring(keepMultiplierThreshold), function(text)
    local val = tonumber(text)
    if val then
        keepMultiplierThreshold = val
    else
        warn("[TaperUI Warning] Please enter a valid number for multiplier protection.")
    end
end)

EggTab:CreateToggle("Auto Delete Loop", false, function(state)
    autoDeleteActive = state
    if autoDeleteActive then
        runAutoDeleteLoop()
    end
end)

-- ============================================================
--  TAB 3: UPGRADES CONTROLS
-- ============================================================
UpgradeTab:CreateLabel("⚡ Upgrades (World 5+)")

-- Auto Upgrade Selection
UpgradeTab:CreateDropdown("Auto Upgrade Target", {
    "None", "More Rebirth Skips", "More Inventory Space", "More Egg Luck", 
    "More Power", "More Money", "More Equips", "All (Loop)"
}, "None", function(choice)
    selectedUpgradeTarget = choice
end)

-- Auto Upgrade Toggle
UpgradeTab:CreateToggle("Auto Upgrade Toggle", false, function(state)
    autoUpgradeActive = state
    if autoUpgradeActive then
        task.spawn(function()
            while autoUpgradeActive do
                if InvokeServerAction and selectedUpgradeTarget ~= "None" then
                    if selectedUpgradeTarget == "All (Loop)" then
                        for _, upgradeName in ipairs(upgradesList) do
                            if not autoUpgradeActive then break end
                            pcall(function()
                                InvokeServerAction:InvokeServer("Upgrades", "Request", upgradeName)
                            end)
                            task.wait(0.2)
                        end
                    else
                        pcall(function()
                            InvokeServerAction:InvokeServer("Upgrades", "Request", selectedUpgradeTarget)
                        end)
                    end
                end
                task.wait(2.5)
            end
        end)
    end
end)

-- ============================================================
--  TAB 4: SHOP & PROGRESSION CONTROLS
-- ============================================================
ShopTab:CreateLabel("👑 Rebirth System")

-- Auto Rebirth Toggle with dynamic cost and availability validation
ShopTab:CreateToggle("Auto Rebirth", false, function(state)
    autoRebirthActive = state
    if autoRebirthActive then
        task.spawn(function()
            while autoRebirthActive do
                if InvokeServerAction then
                    local available = checkRebirthAvailability(rebirthAmount)
                    if available then
                        local cost = getRebirthCost(rebirthAmount)
                        local myMoney = getMyMoney()
                        if not cost or myMoney >= cost then
                            pcall(function()
                                InvokeServerAction:InvokeServer("Rebirths", "Request", rebirthAmount)
                            end)
                        end
                    end
                end
                task.wait(1.5)
            end
        end)
    end
end)

-- Rebirth Quantity Dropdown (Supported exact amounts including high-tier worlds)
ShopTab:CreateDropdown("Rebirth Amount", {"1", "5", "20", "50", "100", "250", "500", "1000", "2500", "10000", "50000"}, "1", function(choice)
    rebirthAmount = tonumber(choice) or 1
end)

ShopTab:CreateSpacer(5)
ShopTab:CreateLabel("🏀 Tool Shop (Auto Buy & Equip Balls)")

-- Auto Buy Next Tool Toggle (Corrected Server calls and integrated Client Equip)
ShopTab:CreateToggle("Auto Buy Next Tool", false, function(state)
    autoBuyToolsActive = state
    if autoBuyToolsActive then
        task.spawn(function()
            while autoBuyToolsActive do
                local currentMoney = getMyMoney()
                local list = toolList[activeWorldID]
                
                if list then
                    local bestAffordable = nil
                    for i = #list, 1, -1 do
                        if currentMoney >= list[i].price then
                            bestAffordable = list[i].name
                            break
                        end
                    end
                    
                    if bestAffordable then
                        if RequestServerAction then
                            pcall(function()
                                RequestServerAction:FireServer("Tools", "Action", bestAffordable, activeWorldID)
                            end)
                        end
                        
                        if ClientAction and firesignal then
                            pcall(function()
                                firesignal(ClientAction.OnClientEvent, "", bestAffordable)
                            end)
                        end
                    end
                end
                task.wait(buyToolsInterval)
            end
        end)
    end
end)

-- Purchase delay slider
ShopTab:CreateSlider("Purchase Delay (s)", 0.5, 10.0, buyToolsInterval, 1, function(val)
    buyToolsInterval = val
end)

ShopTab:CreateSpacer(5)
ShopTab:CreateLabel("🗺️ Progression & Expansion")

-- Target Zone Input Textbox
ShopTab:CreateTextbox("Target Zone ID", "2", function(text)
    targetZoneID = text
end)

-- Manual Purchase Zone Trigger Button
ShopTab:CreateButton("Unlock Selected Zone", function()
    if InvokeServerAction then
        local zoneNum = tonumber(targetZoneID) or 2
        local success, err = pcall(function()
            InvokeServerAction:InvokeServer("Zone", "PurchaseRequest", zoneNum)
        end)
        if success then
            if getgenv().showToast then
                getgenv().showToast("Zone Unlocked", "Requested zone purchase: " .. tostring(zoneNum), TaperAssets.checkmark, 2.0)
            end
        else
            warn("[Zone Error] Purchase request failed: " .. tostring(err))
        end
    end
end)

-- ============================================================
--  TAB 5: SOCIALS & CREDITS CONTROLS
-- ============================================================
SocialTab:CreateLabel("Credits")
SocialTab:CreateParagraph("Script Author", "This unified game hub and the TaperUI framework were both created by SkyDash.")

SocialTab:CreateSpacer(5)
SocialTab:CreateLabel("Play Other Games")
SocialTab:CreateParagraph("Discover More Scripts", "Click on any of the games below to instantly teleport and check out their respective script features.")

-- Dynamically generate standard launch buttons for all active games loaded from data.json
local dynamicCount = 0
for _, g in ipairs(gameList) do
    if g.isActiveInUI and tostring(g.gameID) ~= tostring(game.PlaceId) then
        dynamicCount = dynamicCount + 1
        local gameTitle = g.gameName
        local joinID = g.canJoinGame and g.gameID or g.joinAlternativeGameID
        
        SocialTab:CreateButton("Launch: " .. gameTitle, function()
            if joinID then
                TeleportService:Teleport(tonumber(joinID))
            end
        end)
    end
end

-- Fallback card if the network request fails or returns no options
if dynamicCount == 0 then
    SocialTab:CreateParagraph("Connection Error", "Unable to load the game directory. Please check your internet connection and verify that HTTP requests are enabled in your executor settings.")
end

-- ============================================================
--  CLEANUP & SHUTDOWN HANDLERS
-- ============================================================
Window.ScreenGui.Destroying:Connect(function()
    autoTrainActive = false
    autoWinActive = false
    autoDunkActive = false
    autoHatchActive = false
    autoRebirthActive = false
    autoBuyToolsActive = false
    autoUpgradeActive = false
    autoDeleteActive = false
end)

-- 6. Trigger play intro sequence
Window:PlayIntro()