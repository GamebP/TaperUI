-- helper/elements.lua
local taperImport = getgenv().taperImport or function(path)
    local localPath = "TaperUI/" .. path .. ".lua"
    local isFolderSupported = typeof(isfolder) == "function"
    local isDirectory = isFolderSupported and isfolder(localPath)
    if isfile(localPath) and not isDirectory then
        return loadstring(readfile(localPath))()
    else
        error("[TaperUI] Fallback import failed for " .. path)
    end
end

local creator = taperImport("helper/creator")

local TweenService = game:GetService("TweenService")
local ExperienceService = game:GetService("ExperienceService")
local UserInputService = game:GetService("UserInputService")
local create = creator.create
local TaperAssets = getgenv().TaperAssets or {}

local elements = {}

function elements:Label(str, parent)
    return create("Frame", {
        Size = UDim2.new(0.98, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(35, 35, 40), Thickness = 1 }),
        create("TextLabel", {
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = str,
            TextColor3 = Color3.fromRGB(220, 220, 225),
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })
end

function elements:Button(str, parent, cb)
    local btn = create("TextButton", {
        Size = UDim2.new(0.98, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(28, 28, 32),
        AutoButtonColor = false,
        Text = "",
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 }),
        create("TextLabel", {
            Name = "TextLabel",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = str,
            TextColor3 = Color3.fromRGB(240, 240, 245),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center
        })
    })

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(36, 36, 42) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(28, 28, 32) }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(22, 22, 26) }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(36, 36, 42) }):Play()
        cb()
    end)

    return btn
end

function elements:Toggle(str, parent, def, cb)
    local state = def or false
    
    local toggleFrame = create("TextButton", {
        Size = UDim2.new(0.98, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        AutoButtonColor = false,
        Text = "",
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(35, 35, 40), Thickness = 1 }),
        create("TextLabel", {
            Name = "TextLabel",
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = str,
            TextColor3 = Color3.fromRGB(210, 210, 215),
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        create("Frame", {
            Name = "togglebg",
            Size = UDim2.new(0, 36, 0, 20),
            Position = UDim2.new(1, -48, 0.5, -10),
            BackgroundColor3 = state and Color3.fromRGB(59, 164, 57) or Color3.fromRGB(164, 58, 58)
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            create("Frame", {
                Name = "leftrightlol",
                Size = UDim2.new(0, 14, 0, 14),
                Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }, {
                create("UICorner", { CornerRadius = UDim.new(1, 0) })
            })
        })
    })

    local toggleBg = toggleFrame.togglebg
    local knob = toggleBg.leftrightlol

    local function updateVisuals()
        local bgTarget = state and Color3.fromRGB(59, 164, 57) or Color3.fromRGB(164, 58, 58)
        local posTarget = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        
        TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = bgTarget }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = posTarget }):Play()
    end

    toggleFrame.MouseButton1Click:Connect(function()
        state = not state
        updateVisuals()
        cb(state)
    end)

    task.defer(function() cb(state) end)
    return toggleFrame
end

function elements:Textbox(str, parent, def, cb)
    local newTb = create("Frame", {
        Size = UDim2.new(0.98, 0, 0, 44),
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(35, 35, 40), Thickness = 1 }),
        create("TextLabel", {
            Name = "TextLabel",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = str,
            TextColor3 = Color3.fromRGB(200, 200, 205),
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        create("Frame", {
            Name = "tbbg",
            Size = UDim2.new(0.4, 0, 0, 28),
            Position = UDim2.new(0.6, -12, 0.5, -14),
            BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 }),
            create("TextBox", {
                Name = "Inp",
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = def or "",
                PlaceholderText = "...",
                TextColor3 = Color3.fromRGB(240, 240, 245),
                PlaceholderColor3 = Color3.fromRGB(100, 100, 105),
                TextSize = 13,
                Font = Enum.Font.Gotham
            })
        })
    })

    newTb.tbbg.Inp.FocusLost:Connect(function()
        cb(newTb.tbbg.Inp.Text)
    end)

    return newTb
end

function elements:Keybind(str, parent, def, cb)
    local currentKey = def or "K"
    local checkingForKey = false

    local kbFrame = create("TextButton", {
        Size = UDim2.new(0.98, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        AutoButtonColor = false,
        Text = "",
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(35, 35, 40), Thickness = 1 }),
        create("TextLabel", {
            Name = "TextLabel",
            Size = UDim2.new(0.6, 0, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = str,
            TextColor3 = Color3.fromRGB(210, 210, 215),
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        create("Frame", {
            Name = "keybg",
            Size = UDim2.new(0, 45, 0, 24),
            Position = UDim2.new(1, -57, 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 }),
            create("TextLabel", {
                Name = "KeyLabel",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = currentKey,
                TextColor3 = Color3.fromRGB(240, 240, 245),
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center
            })
        })
    })

    local keyLabel = kbFrame.keybg.KeyLabel

    kbFrame.MouseButton1Click:Connect(function()
        checkingForKey = true
        keyLabel.Text = "..."
        keyLabel.TextColor3 = Color3.fromRGB(220, 180, 50)
    end)

    local inputConnection
    inputConnection = UserInputService.InputBegan:Connect(function(input)
        if checkingForKey then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local keyPressed = input.KeyCode.Name
                if keyPressed ~= "Escape" then
                    checkingForKey = false
                    currentKey = keyPressed
                    keyLabel.Text = currentKey
                    keyLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
                    cb(currentKey)
                end
            end
        end
    end)

    kbFrame.Destroying:Connect(function()
        if inputConnection then inputConnection:Disconnect() end
    end)

    return kbFrame
end

function elements:Unsupported(parent, cb)
    local frame = create("Frame", {
        Size = UDim2.new(0.9, 0, 0, 115),
        Position = UDim2.new(0.5, 0, 0.5, -25),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24, 24, 28),
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 }),
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 40),
            Position = UDim2.new(0, 0, 0, 12),
            BackgroundTransparency = 1,
            Text = "This place is currently unsupported.",
            TextColor3 = Color3.fromRGB(220, 100, 100),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center
        }),
        create("TextButton", {
            Name = "suggestbtn",
            Size = UDim2.new(0.43, 0, 0, 36),
            Position = UDim2.new(0.05, 0, 0, 60),
            BackgroundColor3 = Color3.fromRGB(32, 32, 38),
            Text = "Suggest Game",
            TextColor3 = Color3.fromRGB(220, 220, 225),
            TextSize = 12,
            Font = Enum.Font.GothamBold
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 })
        }),
        create("TextButton", {
            Name = "glbtn",
            Size = UDim2.new(0.43, 0, 0, 36),
            Position = UDim2.new(0.52, 0, 0, 60),
            BackgroundColor3 = Color3.fromRGB(32, 32, 38),
            Text = "Browse Games",
            TextColor3 = Color3.fromRGB(220, 220, 225),
            TextSize = 12,
            Font = Enum.Font.GothamBold
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 })
        })
    })

    frame.suggestbtn.MouseButton1Click:Connect(function()
        setclipboard("")
        frame.suggestbtn.Text = "Copied Link!"
        task.wait(1)
        frame.suggestbtn.Text = "Suggest Game"
    end)
    frame.glbtn.MouseButton1Click:Connect(cb)

    return frame
end

function elements:addGame(parent, gname, gstate, cb)
    local statusColor = Color3.fromRGB(164, 58, 58)
    if gstate == "🟢" then
        statusColor = Color3.fromRGB(59, 164, 57)
    elseif gstate == "🟡" then
        statusColor = Color3.fromRGB(220, 180, 50)
    end

    local gameItem = create("Frame", {
        Name = "GameElement",
        Size = UDim2.new(0.98, 0, 0, 48),
        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(35, 35, 40), Thickness = 1 }),
        create("Frame", {
            Name = "status",
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0, 14, 0.5, -5),
            BackgroundColor3 = statusColor
        }, {
            create("UICorner", { CornerRadius = UDim.new(1, 0) })
        }),
        create("TextLabel", {
            Name = "header",
            Size = UDim2.new(0.65, 0, 1, 0),
            Position = UDim2.new(0, 34, 0, 0),
            BackgroundTransparency = 1,
            Text = gname,
            TextColor3 = Color3.fromRGB(220, 220, 225),
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        create("TextButton", {
            Name = "ButtonElement",
            Size = UDim2.new(0, 70, 0, 28),
            Position = UDim2.new(1, -82, 0.5, -14),
            BackgroundColor3 = Color3.fromRGB(32, 32, 38),
            Text = "Launch",
            TextColor3 = Color3.fromRGB(240, 240, 245),
            TextSize = 11,
            Font = Enum.Font.GothamBold
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 })
        })
    })

    gameItem.ButtonElement.MouseButton1Click:Connect(cb)
    return gameItem
end

function elements:Searchbar(parent, gameList)
    local searchBar = create("Frame", {
        Name = "searchBar",
        Size = UDim2.new(0.98, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(24, 24, 28),
        Parent = parent
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        create("UIStroke", { Color = Color3.fromRGB(45, 45, 50), Thickness = 1 }),
        create("Frame", {
            Name = "searchbar",
            Size = UDim2.new(1, -24, 0, 28),
            Position = UDim2.new(0, 12, 0.5, -14),
            BackgroundTransparency = 1
        }, {
            create("ImageLabel", {
                Name = "SearchIcon",
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 4, 0.5, -7),
                BackgroundTransparency = 1,
                Image = TaperAssets.search,
                ImageColor3 = Color3.fromRGB(110, 110, 115)
            }),
            create("TextBox", {
                Name = "Inp",
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.new(0, 24, 0, 0),
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = "Search for available brainrot games...",
                TextColor3 = Color3.fromRGB(240, 240, 245),
                PlaceholderColor3 = Color3.fromRGB(110, 110, 115),
                TextSize = 13,
                Font = Enum.Font.Gotham
            })
        })
    })

    searchBar.searchbar.Inp:GetPropertyChangedSignal("Text"):Connect(function()
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "GameElement" then
                child:Destroy()
            end
        end
        local searchText = searchBar.searchbar.Inp.Text:lower()
        for _, g in ipairs(gameList) do
            if g.game:lower():find(searchText) then
                elements:addGame(parent, g.game, g.status, function()
                    ExperienceService:LaunchExperience({placeId = g.id})
                end)
            end
        end
    end)

    return searchBar
end

function elements:CredHead(parent, txt)
    return create("TextLabel", {
        Size = UDim2.new(0.98, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = "> " .. txt,
        TextColor3 = Color3.fromRGB(150, 150, 255),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
end

function elements:CredPerson(parent, txt)
    return create("TextLabel", {
        Size = UDim2.new(0.98, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = "      + " .. txt,
        TextColor3 = Color3.fromRGB(210, 210, 215),
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
end

return elements