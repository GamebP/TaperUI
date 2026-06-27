-- UI.lua
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ExperienceService = game:GetService("ExperienceService")

local hui = gethui or get_hidden_gui
local getexec = identifyexecutor or function() return "Unknown Executor" end

if not isfolder("TaperUI") then makefolder("TaperUI") end
if not isfile("TaperUI/Config.json") then
    writefile("TaperUI/Config.json", HttpService:JSONEncode({
        settings = {
            auto_rejoin_on_kick = false,
            disable_3d_rendering = false,
            toggle_keybind = "K"
        }
    }))
end

local env = getgenv()

function env.getgitpath(where)
    local mainBuild = "https://raw.githubusercontent.com/GamebP/TaperUI/main/"
    if where == "src" then
        return mainBuild
    elseif where == "games" then
        return mainBuild .. "games/"
    end
end

local function getAsset(path)
    local localPath = "TaperUI/" .. path
    if not isfile(localPath) then
        local dirParts = string.split(localPath, "/")
        local currentDir = ""
        for i = 1, #dirParts - 1 do
            currentDir = currentDir .. dirParts[i] .. "/"
            if not isfolder(currentDir) then
                makefolder(currentDir)
            end
        end

        local gitUrl = env.getgitpath("src") .. path
        local ok, content = pcall(game.HttpGet, game, gitUrl)
        if ok and content and #content > 0 and content ~= "404: Not Found" then
            writefile(localPath, content)
        else
            return ""
        end
    end

    local getcustom = getcustomasset or getsynasset
    if getcustom then
        return getcustom(localPath)
    end
    return ""
end

local assetPaths = {
    -- Images path
    logo_transparent = "images/logo-transparent.png",
    logo_img = "images/logo.png",
    -- Icons path
    home = "images/icons/home.png",
    game = "images/icons/game.png",
    list = "images/icons/list.png",
    collapse = "images/icons/collapse-arrow.png",
    expand = "images/icons/expand-arrow.png",
    search = "images/icons/magnifying-glass.png",
    settings = "images/icons/settings.png",
    user = "images/icons/user.png",
    close = "images/icons/close.png",
    checkmark = "images/icons/check-mark.png",
    done = "images/icons/done.png",
    error = "images/icons/error.png",
    info = "images/icons/info.png"
}

getgenv().TaperAssets = {}
for key, path in pairs(assetPaths) do
    TaperAssets[key] = getAsset(path)
end

function env.setconfig(key, value)
    local dec = HttpService:JSONDecode(readfile("TaperUI/Config.json"))
    dec[tostring(game.PlaceId)] = dec[tostring(game.PlaceId)] or {}
    dec[tostring(game.PlaceId)][key] = value
    writefile("TaperUI/Config.json", HttpService:JSONEncode(dec))
end

env.autorejoin = false

local errorConnection
errorConnection = GuiService.ErrorMessageChanged:Connect(function()
    if env.autorejoin then
        TeleportService:Teleport(game.PlaceId)
    end
end)
GuiService:SetGameplayPausedNotificationEnabled(false)

local function import(path)
    local localPath = "TaperUI/" .. path .. ".lua"
    local isFolderSupported = typeof(isfolder) == "function"
    local isDirectory = isFolderSupported and isfolder(localPath)
    
    if isfile(localPath) and not isDirectory then
        return loadstring(readfile(localPath))()
    else
        local gitUrl = env.getgitpath("src") .. path .. ".lua"
        local ok, content = pcall(game.HttpGet, game, gitUrl)
        if ok and content and #content > 0 and content ~= "404: Not Found" then
            return loadstring(content)()
        else
            error("[TaperUI] Module file not found: " .. localPath)
        end
    end
end
getgenv().taperImport = import

local function importJson(path)
    local localPath = "TaperUI/" .. path .. ".json"
    local isFolderSupported = typeof(isfolder) == "function"
    local isDirectory = isFolderSupported and isfolder(localPath)
    
    if isfile(localPath) and not isDirectory then
        return HttpService:JSONDecode(readfile(localPath))
    else
        local gitUrl = env.getgitpath("src") .. path .. ".json"
        local ok, content = pcall(game.HttpGet, game, gitUrl)
        if ok and content and #content > 0 and content ~= "404: Not Found" then
            return HttpService:JSONDecode(content)
        else
            error("[TaperUI] JSON file not found: " .. localPath)
        end
    end
end

local creator = import("helper/creator")
local elements = import("helper/elements")
local data = importJson("helper/data")

local create = creator.create
local dragify = creator.dragify
local convertToScrolling = creator.convertToScrolling

local gameList = data.gameList
local creditsList = data.creditsList

local configSettings = HttpService:JSONDecode(readfile("TaperUI/Config.json"))
if not configSettings.settings.toggle_keybind then
    configSettings.settings.toggle_keybind = "K"
    writefile("TaperUI/Config.json", HttpService:JSONEncode(configSettings))
end
local activeKeybind = configSettings.settings.toggle_keybind or "K"

local screenGui = create("ScreenGui", {
    Name = "TaperUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
screenGui.Parent = hui and hui() or CoreGui

local ToastContainer = create("Frame", {
    Name = "ToastContainer",
    Size = UDim2.new(0, 280, 0, 400),
    Position = UDim2.new(1, -20, 1, -20),
    AnchorPoint = Vector2.new(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 100000,
    Parent = screenGui
}, {
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    })
})

local function showToast(title, message, duration)
    duration = duration or 3
    
    local Toast = create("Frame", {
        Name = "Toast",
        Size = UDim2.new(0, 0, 0, 60),
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Name = "Stroke", Color = Color3.fromRGB(45, 45, 50), Thickness = 1, Transparency = 1 }),
        create("TextLabel", {
            Name = "ToastTitle",
            Size = UDim2.new(1, -24, 0, 20),
            Position = UDim2.new(0, 12, 0, 8),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Color3.fromRGB(240, 240, 245),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1
        }),
        create("TextLabel", {
            Name = "ToastMessage",
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.new(0, 12, 0, 28),
            BackgroundTransparency = 1,
            Text = message,
            TextColor3 = Color3.fromRGB(160, 160, 165),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1
        })
    })
    Toast.Parent = ToastContainer

    local stroke = Toast:FindFirstChild("Stroke")
    
    TweenService:Create(Toast, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 0.05
    }):Play()

    if stroke then
        TweenService:Create(stroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), { Transparency = 0.5 }):Play()
    end

    task.delay(0.05, function()
        TweenService:Create(Toast.ToastTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
        TweenService:Create(Toast.ToastMessage, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
    end)

    task.delay(duration, function()
        TweenService:Create(Toast.ToastTitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
        TweenService:Create(Toast.ToastMessage, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
        
        local fadeOut = TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0)
        })
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
        end
        fadeOut:Play()
        
        fadeOut.Completed:Connect(function()
            Toast:Destroy()
        end)
    end)
end

local MainFrame = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 420, 0, 100),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(15, 15, 17),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = true
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 12) }),
    create("UIStroke", { Name = "MainStroke", Color = Color3.fromRGB(38, 38, 43), Thickness = 1.5, Transparency = 1 })
})
MainFrame.Parent = screenGui

dragify(MainFrame)

local Sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 170, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
    BorderSizePixel = 0,
    Visible = false
}, {
    create("UICorner", { CornerRadius = UDim.new(0, 12) }),
    create("Frame", {
        Size = UDim2.new(0, 15, 1, 0),
        Position = UDim2.new(1, -15, 0, 0),
        BackgroundColor3 = Color3.fromRGB(18, 18, 22),
        BorderSizePixel = 0
    }),
    create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Color3.fromRGB(32, 32, 36),
        BorderSizePixel = 0
    }),
    create("TextLabel", {
        Name = "SidebarTitle",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 20, 0, 10),
        BackgroundTransparency = 1,
        Text = "TaperUI",
        TextColor3 = Color3.fromRGB(240, 240, 245),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTransparency = 1
    })
})
Sidebar.Parent = MainFrame

local TabButtonContainer = create("Frame", {
    Name = "TabButtonContainer",
    Size = UDim2.new(1, -16, 1, -60),
    Position = UDim2.new(0, 8, 0, 55),
    BackgroundTransparency = 1
}, {
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6)
    })
})
TabButtonContainer.Parent = Sidebar

local ContentArea = create("Frame", {
    Name = "ContentArea",
    Size = UDim2.new(1, -170, 1, 0),
    Position = UDim2.new(0, 170, 0, 0),
    BackgroundTransparency = 1,
    Visible = false
})
ContentArea.Parent = MainFrame

local Topbar = create("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1
}, {
    create("ImageButton", {
        Name = "hidebtn",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0.5, -10),
        BackgroundTransparency = 1,
        Image = TaperAssets.close,
        ImageColor3 = Color3.fromRGB(180, 180, 185)
    })
})
Topbar.Parent = ContentArea

local HideButton = Topbar.hidebtn

local SectionContainers = create("Frame", {
    Name = "SectionContainers",
    Size = UDim2.new(1, 0, 1, -50),
    Position = UDim2.new(0, 0, 0, 50),
    BackgroundTransparency = 1
})
SectionContainers.Parent = ContentArea

local function createSectionFrame(name, visible)
    return create("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Visible = visible,
        BackgroundTransparency = 1
    })
end

local homeFrame = createSectionFrame("homeframe", true)
homeFrame.Parent = SectionContainers

local gameFrame = createSectionFrame("gameFrame", false)
gameFrame.Parent = SectionContainers

local gamelistFrame = createSectionFrame("gamelistFrame", false)
gamelistFrame.Parent = SectionContainers

local settingsFrame = createSectionFrame("settingsFrame", false)
settingsFrame.Parent = SectionContainers

local creditsFrame = createSectionFrame("creditsFrame", false)
creditsFrame.Parent = SectionContainers

local homeContainer = create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1
}, {
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    }),
    create("UIPadding", { PaddingTop = UDim.new(0, 16) }),
    create("TextLabel", {
        Name = "versionLabel",
        Size = UDim2.new(0.9, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = "Version: Loading",
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 13,
        Font = Enum.Font.GothamMedium
    }),
    create("TextLabel", {
        Name = "execLabel",
        Size = UDim2.new(0.9, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = "Executor: Loading",
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 13,
        Font = Enum.Font.GothamMedium
    })
})
homeContainer.Parent = homeFrame

local function createTabBtn(text, iconAsset, layoutOrder)
    return create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(24, 24, 28),
        BackgroundTransparency = layoutOrder == 1 and 0 or 1,
        Text = "",
        LayoutOrder = layoutOrder,
        AutoButtonColor = false
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 12, 0.5, -8),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = layoutOrder == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 185)
        }),
        create("TextLabel", {
            Name = "LabelText",
            Size = UDim2.new(1, -38, 1, 0),
            Position = UDim2.new(0, 36, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = layoutOrder == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 185),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center
        })
    })
end

local Tabs = {
    HomeTab = createTabBtn("Home", TaperAssets.home, 1),
    GameTab = createTabBtn("Game", TaperAssets.game, 2),
    GameslistTab = createTabBtn("Games List", TaperAssets.list, 3),
    SettingsTab = createTabBtn("Settings", TaperAssets.settings, 4),
    CreditsTab = createTabBtn("Credits", TaperAssets.user, 5)
}
for _, btn in pairs(Tabs) do
    btn.Parent = TabButtonContainer
end

local Sections = {
    Home = {
        TabBtn = Tabs.HomeTab,
        Container = homeFrame,
        Content = homeContainer
    },
    Game = {
        TabBtn = Tabs.GameTab,
        Container = gameFrame,
        Content = convertToScrolling(gameFrame)
    },
    GamesList = {
        TabBtn = Tabs.GameslistTab,
        Container = gamelistFrame,
        Content = convertToScrolling(gamelistFrame)
    },
    Settings = {
        TabBtn = Tabs.SettingsTab,
        Container = settingsFrame,
        Content = convertToScrolling(settingsFrame)
    },
    Credits = {
        TabBtn = Tabs.CreditsTab,
        Container = creditsFrame,
        Content = convertToScrolling(creditsFrame)
    }
}

local CurSection = Sections.Home

for _, sect in pairs(Sections) do
    sect.TabBtn.MouseEnter:Connect(function()
        if CurSection ~= sect then
            TweenService:Create(sect.TabBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(32, 32, 36) }):Play()
        end
    end)

    sect.TabBtn.MouseLeave:Connect(function()
        if CurSection ~= sect then
            TweenService:Create(sect.TabBtn, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
        end
    end)

    sect.TabBtn.MouseButton1Click:Connect(function()
        if CurSection == sect then return end

        if CurSection then
            TweenService:Create(CurSection.TabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(CurSection.TabBtn.LabelText, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(180, 180, 185) }):Play()
            TweenService:Create(CurSection.TabBtn.Icon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(180, 180, 185) }):Play()
            CurSection.Container.Visible = false
        end

        sect.Container.Visible = true
        
        TweenService:Create(sect.TabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(28, 28, 32) }):Play()
        TweenService:Create(sect.TabBtn.LabelText, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
        TweenService:Create(sect.TabBtn.Icon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()

        CurSection = sect
    end)
end

local function toggleUI()
    if MainFrame.Visible then
        MainFrame.Visible = false
        showToast("TaperUI", "Interface hidden. Press [" .. activeKeybind .. "] to show again.", 2.5)
    else
        MainFrame.Visible = true
        showToast("TaperUI", "Interface opened successfully.", 2.5)
    end
end

HideButton.MouseButton1Click:Connect(function()
    if MainFrame.Visible then
        toggleUI()
    end
end)

local keybindConnection
keybindConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode.Name == activeKeybind then
            toggleUI()
        end
    end
end)

local function replaceRedacted()
    local c = Sections.Home.Content
    c.execLabel.Text = "Executor: " .. getexec()
    c.versionLabel.Text = "Ver: " .. (data.version or "N/A") .. " | Updated: " .. (data.updatedDate or "N/A")
end
replaceRedacted()

local ok, gamePath = pcall(function()
    return game:HttpGet(env.getgitpath("games") .. tostring(game.PlaceId) .. ".lua")
end)

local gameTargetContent = Sections.Game.Content or Sections.Game.Container

if not ok or #gamePath == 0 or gamePath == "404: Not Found" then
    local handledLocally = false

    if getgenv().FileScripts then
        if isfile("TaperUI/" .. tostring(game.PlaceId) .. ".lua") then
            local gameModule = loadstring(readfile("TaperUI/" .. tostring(game.PlaceId) .. ".lua"))()
            gameModule(gameTargetContent, HttpService:JSONDecode(readfile("TaperUI/Config.json")))
            handledLocally = true
        end
    end

    if not handledLocally then
        elements:Unsupported(Sections.Game.Container, function()
            if CurSection then
                TweenService:Create(CurSection.TabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                TweenService:Create(CurSection.TabBtn.LabelText, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(180, 180, 185) }):Play()
                TweenService:Create(CurSection.TabBtn.Icon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(180, 180, 185) }):Play()
                CurSection.Container.Visible = false
            end

            Sections.GamesList.Container.Visible = true
            
            TweenService:Create(Sections.GamesList.TabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(28, 28, 32) }):Play()
            TweenService:Create(Sections.GamesList.TabBtn.LabelText, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            TweenService:Create(Sections.GamesList.TabBtn.Icon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()

            CurSection = Sections.GamesList
        end)
    end
else
    local gameModule = loadstring(gamePath)()
    gameModule(gameTargetContent, HttpService:JSONDecode(readfile("TaperUI/Config.json")))
end

local activeGames = {}
for _, g in ipairs(gameList) do
    if g.isActiveInUI == true then
        table.insert(activeGames, g)
    end
end

elements:Searchbar(Sections.GamesList.Content, activeGames)
if #activeGames == 0 then
    create("TextLabel", {
        Name = "NoGamesLabel",
        Size = UDim2.new(0.98, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "No available games found.",
        TextColor3 = Color3.fromRGB(130, 130, 135),
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Sections.GamesList.Content
    })
else
    for _, g in ipairs(activeGames) do
        elements:addGame(Sections.GamesList.Content, g.gameName, g.gameStatus, function()
            ExperienceService:LaunchExperience({placeId = g.gameID})
        end)
    end
end

for sect, c in pairs(creditsList) do
    if #c > 0 then
        elements:CredHead(Sections.Credits.Content, sect)
        for _, person in ipairs(c) do
            elements:CredPerson(Sections.Credits.Content, person)
        end
    end
end

local dec1 = HttpService:JSONDecode(readfile("TaperUI/Config.json"))

elements:Toggle("Disable 3D Rendering", Sections.Settings.Content, dec1.settings.disable_3d_rendering, function(v)
    local dec = HttpService:JSONDecode(readfile("TaperUI/Config.json"))
    dec.settings.disable_3d_rendering = v
    writefile("TaperUI/Config.json", HttpService:JSONEncode(dec))
    RunService:Set3dRenderingEnabled(not v)
end)

elements:Toggle("Auto Rejoin (when kicked)", Sections.Settings.Content, dec1.settings.auto_rejoin_on_kick, function(v)
    local dec = HttpService:JSONDecode(readfile("TaperUI/Config.json"))
    dec.settings.auto_rejoin_on_kick = v
    writefile("TaperUI/Config.json", HttpService:JSONEncode(dec))
    getgenv().autorejoin = v
end)

elements:Keybind("Toggle UI Keybind", Sections.Settings.Content, activeKeybind, function(newKey)
    activeKeybind = newKey
    local dec = HttpService:JSONDecode(readfile("TaperUI/Config.json"))
    dec.settings.toggle_keybind = newKey
    writefile("TaperUI/Config.json", HttpService:JSONEncode(dec))
    showToast("Keybind Updated", "New open/close key: [" .. newKey .. "]", 2.5)
end)

local LoadingFrame = create("Frame", {
    Name = "LoadingFrame",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = true,
    Parent = MainFrame
}, {
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center
    }),
    create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "Taper Interface Suite",
        TextColor3 = Color3.fromRGB(240, 240, 245),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextTransparency = 1,
        LayoutOrder = 1
    }),
    create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "by SkyDash",
        TextColor3 = Color3.fromRGB(160, 160, 165),
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextTransparency = 1,
        LayoutOrder = 2
    }),
    create("TextLabel", {
        Name = "Version",
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = "" .. tostring(dec1.version),
        TextColor3 = Color3.fromRGB(120, 120, 125),
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextTransparency = 1,
        LayoutOrder = 3
    })
})

local function playIntro()
    local mainStroke = MainFrame:FindFirstChild("MainStroke")

    task.wait(0.5)

    TweenService:Create(MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()

    if mainStroke then
        TweenService:Create(mainStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Transparency = 0
        }):Play()
    end

    task.wait(0.1)
    TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()

    task.wait(0.05)
    TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()

    task.wait(0.05)
    TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()

    task.wait(1.1)

    TweenService:Create(MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
        Size = UDim2.new(0, 390, 0, 90)
    }):Play()

    task.wait(0.3)
    TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
        TextTransparency = 1
    }):Play()
    TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
        TextTransparency = 1
    }):Play()

    task.wait(0.1)

    LoadingFrame:Destroy()
    
    local expandTween = TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 620, 0, 420)
    })
    expandTween:Play()

    expandTween.Completed:Connect(function()
        Sidebar.Visible = true
        ContentArea.Visible = true

        local SidebarTitle = Sidebar:FindFirstChild("SidebarTitle")
        if SidebarTitle then
            TweenService:Create(SidebarTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0
            }):Play()
        end
    end)
end

playIntro()

elements:Button("Uninject UI", Sections.Settings.Content, function()
    if errorConnection then
        errorConnection:Disconnect()
    end
    if keybindConnection then
        keybindConnection:Disconnect()
    end

    pcall(function()
        RunService:Set3dRenderingEnabled(true)
    end)

    if screenGui then
        screenGui:Destroy()
    end

    getgenv().TaperAssets = nil
    getgenv().taperImport = nil
    getgenv().autorejoin = nil
end)