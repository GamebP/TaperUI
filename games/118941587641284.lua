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
    LoadingTitle = "Basketball Simulator",
    LoadingSubtitle = getexec(),
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
        and LocalPlayer.PlayerGui.MainUI.Menus.Rebirths:FindFirstChild("ScrollingFrameContainer")
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

-- Egg cost mappings
local eggMapW1 = {
    ["Basic ($250)"] = "Basic",
    ["Flower ($25K)"] = "Flower",
    ["Tree ($1M)"] = "Tree"
}
local eggMapW2 = {
    ["Cactus ($10M)"] = "Cactus",
    ["Floatie ($1.25B)"] = "Floatie",
    ["Pirate ($10B)"] = "Pirate"
}
local eggMapW3 = {
    ["Nut ($15B)"] = "Nut",
    ["Snowflake ($5T)"] = "Snowflake",
    ["Snowman ($50T)"] = "Snowman"
}
local eggMapW4 = {
    ["Hot Chocolate ($75T)"] = "Hot Chocolate",
    ["Coctail ($12.5Qa)"] = "Coctail",
    ["Candy Basket ($250Qa)"] = "Candy Basket"
}
local eggMapW5 = {
    ["Ocean ($500Qa)"] = "Ocean",
    ["Aqua ($75Qi)"] = "Aqua",
    ["Silver Spire ($500Qi)"] = "Silver Spire"
}
local eggMapW6 = {
    ["Molten Lava ($1Sx)"] = "Molten Lava",
    ["Volcano ($125Sx)"] = "Volcano",
    ["Dragon ($1Sp)"] = "Dragon"
}
local eggMapW7 = {
    ["Enchanted ($125Sp)"] = "Enchanted",
    ["Voidspike ($15Oc)"] = "Voidspike",
    ["Serpent Amethyst ($1No)"] = "Serpent Amethyst"
}

-- Target World Opponent Maps
local dunkOpponents = {
    [1] = "Punk Kid",
    [2] = "Korblox Deathspeaker",
    [3] = "Snow Gentleman",
    [4] = "Wizard",
    [5] = "Aquaman",
    [6] = "Magma Slammer",
    [7] = "TechnoWizard"
}

-- Consolidated Tool Shop Data mappings for World 1 to 7
local toolList = {
    [1] = {
        {name = "Tide", price = 5e3}, {name = "Ice", price = 170e3}, {name = "Wooden Theme", price = 302e3},
        {name = "Sweets", price = 472e3}, {name = "Ocean", price = 680e3}, {name = "Lava", price = 926e3},
        {name = "Enchanted", price = 1.2e6}, {name = "Hologramic", price = 1.53e6}, {name = "Halloween", price = 1.89e6},
        {name = "Nuclear", price = 2.28e6}, {name = "Crystal", price = 2.72e6}, {name = "Spectrum", price = 3.19e6},
        {name = "Pool", price = 3.7e6}, {name = "Glass", price = 4.25e6}, {name = "Pixel Art", price = 4.83e6},
        {name = "Comic", price = 5.46e6}, {name = "Swirl", price = 6.12e6}, {name = "Swirly Wirly", price = 6.82e6},
        {name = "White Swirls", price = 7.56e6}, {name = "Translucent", price = 8.33e6}, {name = "Slime", price = 9.14e6},
        {name = "Nurato", price = 10e6}
    },
    [2] = {
        {name = "Splashwater", price = 10e6}, {name = "Coral", price = 28.8e6}, {name = "Candy", price = 85.5e6},
        {name = "Candy Cane", price = 179e6}, {name = "Honeycomb", price = 312e6}, {name = "Marble", price = 482e6},
        {name = "Metallic", price = 689e6}, {name = "Gold", price = 935e6}, {name = "Black", price = 1.21e9},
        {name = "Street", price = 1.53e9}, {name = "Scrap", price = 1.89e9}, {name = "Money", price = 2.29e9},
        {name = "Floor", price = 2.72e9}, {name = "Desert Camo", price = 3.2e9}, {name = "Snake Scales", price = 3.71e9},
        {name = "Carbon Fibre", price = 4.25e9}, {name = "Cat", price = 4.84e9}, {name = "Blue Crystals", price = 5.46e9},
        {name = "Diamond", price = 6.12e9}, {name = "Neon Circuit", price = 6.82e9}, {name = "Ruby", price = 7.56e9},
        {name = "Cyberpunk", price = 8.33e9}, {name = "Futuristic", price = 9.15e9}, {name = "Futuristic Neon", price = 10e9}
    },
    [3] = {
        {name = "Plasma", price = 50e9}, {name = "DNA", price = 68.8e9}, {name = "Ice Shards", price = 125e9},
        {name = "Infested", price = 219e9}, {name = "Toxic", price = 350e9}, {name = "Molten", price = 520e9},
        {name = "Charred", price = 971e9}, {name = "Dark Storm", price = 1.25e12}, {name = "Dark Matter", price = 1.57e12},
        {name = "Void Lightning", price = 1.93e12}, {name = "Void Lover", price = 2.32e12}, {name = "Emojis", price = 2.75e12},
        {name = "News", price = 3.22e12}, {name = "Bandages", price = 3.73e12}, {name = "Ghost", price = 4.28e12},
        {name = "Holo", price = 4.86e12}, {name = "Vibrant", price = 5.48e12}, {name = "Shiny Floor", price = 6.14e12},
        {name = "Vibrant Prism", price = 6.84e12}, {name = "Prism Aurora", price = 7.57e12}, {name = "Pink Aurora", price = 8.34e12},
        {name = "Sun", price = 9.15e12}, {name = "Sunset Horizon", price = 10e12}
    },
    [4] = {
        {name = "Twilight Sky", price = 250e12}, {name = "Stars Theme", price = 722e12}, {name = "Sky", price = 2.12e15},
        {name = "Earth", price = 4.49e15}, {name = "Moon", price = 7.8e15}, {name = "Mars", price = 12e15},
        {name = "Mercury", price = 17.2e15}, {name = "Venus", price = 23.3e15}, {name = "Neptune", price = 30.4e15},
        {name = "Saturn", price = 38.4e15}, {name = "Jupiter", price = 47.4e15}, {name = "Fantasy", price = 57.3e15},
        {name = "Corrupted", price = 68.2e15}, {name = "Paint", price = 80e15}, {name = "Ink", price = 92.7e15},
        {name = "Cactus", price = 106e15}, {name = "Dragon Scale", price = 121e15}, {name = "Kraken", price = 136e15},
        {name = "Pirate", price = 153e15}, {name = "Samurai", price = 170e15}, {name = "Konoha", price = 189e15},
        {name = "Honoured", price = 208e15}, {name = "Disgraced", price = 228e15}, {name = "Demonic", price = 250e15}
    },
    [5] = {
        {name = "HellFire", price = 300e15}, {name = "Industrial Sphere", price = 340e15},
        {name = "BubbleGum", price = 385e15}, {name = "Frost Spike", price = 435e15},
        {name = "Mohogony", price = 490e15}, {name = "Parchment", price = 550e15},
        {name = "Space", price = 620e15}, {name = "Gold Map", price = 700e15},
        {name = "Leopard", price = 790e15}, {name = "Lemon", price = 890e15},
        {name = "Watermelon", price = 1e18}, {name = "Golf Ball", price = 1.15e18},
        {name = "Anciant Scribbles", price = 1.32e18}, {name = "Matrix", price = 1.5e18},
        {name = "Marble Scribble", price = 1.7e18}, {name = "Ringmesh", price = 1.93e18},
        {name = "Radar", price = 2.17e18}, {name = "Swirls", price = 2.43e18},
        {name = "Toxic Paint", price = 2.71e18}, {name = "Graffiti", price = 3.02e18},
        {name = "Perforated", price = 3.36e18}, {name = "Plaid", price = 3.73e18},
        {name = "Colorful", price = 4.13e18}, {name = "CyberGlitch", price = 4.56e18}
    },
    [6] = {
        {name = "Broken Porcelin", price = 5e18}, {name = "Topography Heigh", price = 5.5e18},
        {name = "Broken CDs", price = 6.05e18}, {name = "Melted Plastic", price = 6.65e18},
        {name = "Spilled Ink", price = 7.3e18}, {name = "Subway Routes", price = 8e18},
        {name = "Curropted VHS", price = 8.8e18}, {name = "Candy Pop", price = 9.7e18},
        {name = "Neon Strikes", price = 10.7e18}, {name = "Natural Call", price = 11.8e18},
        {name = "Graffiti Spam", price = 13e18}, {name = "Color Vomit", price = 14.3e18},
        {name = "Funky Draws", price = 15.7e18}, {name = "Color Pop", price = 17.2e18},
        {name = "Caution", price = 18.9e18}, {name = "Pink Bacteria", price = 20.8e18},
        {name = "Galvanised Glass", price = 22.7e18}, {name = "Violence", price = 24.9e18},
        {name = "Moai Funk", price = 27.3e18}, {name = "Toxicity", price = 29.9e18},
        {name = "Bar Party", price = 32.7e18}, {name = "Galactic Impact", price = 35.8e18},
        {name = "Holographic Disks", price = 39.2e18}, {name = "Neo Waves", price = 43e18}
    },
    [7] = {
        {name = "Red Life", price = 47e18}, {name = "Color Blobs", price = 51.5e18}, {name = "Night Life", price = 56.5e18},
        {name = "DreamCore", price = 62e18}, {name = "Aesthetic Mode", price = 68e18}, {name = "CityScape", price = 74.5e18},
        {name = "Flame and Ice", price = 81.5e18}, {name = "Spray Dance", price = 89e18}, {name = "Blue Pop", price = 97.5e18},
        {name = "Flame gone wrong", price = 107e18}, {name = "Mis Configured", price = 117e18}, {name = "Bismuth", price = 128e18},
        {name = "Evil", price = 140e18}, {name = "Rug", price = 153e18}, {name = "Binary", price = 167e18},
        {name = "Me when japan", price = 182e18}, {name = "Circuit Breaker", price = 198e18}, {name = "Gym Fit", price = 215e18},
        {name = "Green Roller", price = 234e18}, {name = "Gold Plated", price = 255e18}, {name = "Tattoo", price = 278e18},
        {name = "Creeps Over", price = 303e18}, {name = "City Delusion", price = 330e18}, {name = "Impact Frame", price = 360e18}
    }
}

local upgradesList = {
    "More Rebirth Skips",
    "More Inventory Space",
    "More Egg Luck",
    "More Power",
    "More Money",
    "More Equips"
}

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
EggTab:CreateLabel("🥚 World 1-3 Hatching")

-- Select World 1 Egg Dropdown
EggTab:CreateDropdown("Select World 1 Egg", {"Basic ($250)", "Flower ($25K)", "Tree ($1M)"}, "Basic ($250)", function(choice)
    selectedEggW1 = eggMapW1[choice] or "Basic"
end)

-- Select World 2 Egg Dropdown
EggTab:CreateDropdown("Select World 2 Egg", {"Cactus ($10M)", "Floatie ($1.25B)", "Pirate ($10B)"}, "Cactus ($10M)", function(choice)
    selectedEggW2 = eggMapW2[choice] or "Cactus"
end)

-- Select World 3 Egg Dropdown
EggTab:CreateDropdown("Select World 3 Egg", {"Nut ($15B)", "Snowflake ($5T)", "Snowman ($50T)"}, "Nut ($15B)", function(choice)
    selectedEggW3 = eggMapW3[choice] or "Nut"
end)

EggTab:CreateSpacer(5)
EggTab:CreateLabel("🌵 World 4-7 Hatching")

-- Select World 4 Egg Dropdown
EggTab:CreateDropdown("Select World 4 Egg", {"Hot Chocolate ($75T)", "Coctail ($12.5Qa)", "Candy Basket ($250Qa)"}, "Hot Chocolate ($75T)", function(choice)
    selectedEggW4 = eggMapW4[choice] or "Hot Chocolate"
end)

-- Select World 5 Egg Dropdown
EggTab:CreateDropdown("Select World 5 Egg", {"Ocean ($500Qa)", "Aqua ($75Qi)", "Silver Spire ($500Qi)"}, "Ocean ($500Qa)", function(choice)
    selectedEggW5 = eggMapW5[choice] or "Ocean"
end)

-- Select World 6 Egg Dropdown
EggTab:CreateDropdown("Select World 6 Egg", {"Molten Lava ($1Sx)", "Volcano ($125Sx)", "Dragon ($1Sp)"}, "Molten Lava ($1Sx)", function(choice)
    selectedEggW6 = eggMapW6[choice] or "Molten Lava"
end)

-- Select World 7 Egg Dropdown
EggTab:CreateDropdown("Select World 7 Egg", {"Enchanted ($125Sp)", "Voidspike ($15Oc)", "Serpent Amethyst ($1No)"}, "Enchanted ($125Sp)", function(choice)
    selectedEggW7 = eggMapW7[choice] or "Enchanted"
end)

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
end)

-- 6. Trigger play intro sequence
Window:PlayIntro()