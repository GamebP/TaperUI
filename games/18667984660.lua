return function(parent, config)
    -- 1. Import TaperUI's elements helper module
    local taperImport = getgenv().taperImport or function(path)
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/GamebP/TaperUI/main/" .. path .. ".lua"))()
    end
    local elements = taperImport("helper/elements")

    -- 2. Store references to game services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    -- ===== STATE CONFIGURATION =====
    local enabled = false
    local sendToServer = true -- Controls the boolean to allow/disallow firing the server
    local randomize = false   -- Controls whether values fluctuate dynamically
    local spoofedFps = "999"
    local spoofedMem = "1032322"
    local spoofedResX = "132232"  -- Custom Resolution X coordinate
    local spoofedResY = "1323232" -- Custom Resolution Y coordinate
    local spoofedGfx = "QualityLevel10" -- Target graphics quality
    local spoofedPlatform = "Windows"   -- Target spoofed subsystem

    -- Graphics Quality Enum Mapping
    local gfxEnums = {
        ["QualityLevel1"] = Enum.SavedQualitySetting.QualityLevel1,
        ["QualityLevel2"] = Enum.SavedQualitySetting.QualityLevel2,
        ["QualityLevel3"] = Enum.SavedQualitySetting.QualityLevel3,
        ["QualityLevel4"] = Enum.SavedQualitySetting.QualityLevel4,
        ["QualityLevel5"] = Enum.SavedQualitySetting.QualityLevel5,
        ["QualityLevel6"] = Enum.SavedQualitySetting.QualityLevel6,
        ["QualityLevel7"] = Enum.SavedQualitySetting.QualityLevel7,
        ["QualityLevel8"] = Enum.SavedQualitySetting.QualityLevel8,
        ["QualityLevel9"] = Enum.SavedQualitySetting.QualityLevel9,
        ["QualityLevel10"] = Enum.SavedQualitySetting.QualityLevel10,
        ["Automatic"] = Enum.SavedQualitySetting.Automatic
    }

    -- ===== NETWORK LISTENER =====
    local meowConnection = nil

    local function setupSpoofer()
        if meowConnection then
            meowConnection:Disconnect()
            meowConnection = nil
        end

        local meowEvent = ReplicatedStorage:WaitForChild("meow")
        local nyaEvent = ReplicatedStorage:WaitForChild("nya")

        meowConnection = meowEvent.OnClientEvent:Connect(function(data)
            if not enabled then return end
            if type(data) ~= "table" then return end
            
            -- Verify if the boolean to send data to the server is checked
            if not sendToServer then return end

            local token = data.token
            if not token then return end

            -- If the server requests platform "device" verification
            if data.t == "device" then
                local isVR = (spoofedPlatform == "VR")
                local isConsole = (spoofedPlatform == "Console")
                local isWindows = (spoofedPlatform == "Windows")
                local isMobile = (spoofedPlatform == "Android" or spoofedPlatform == "iOS")

                nyaEvent:FireServer({
                    t = "device",
                    token = token,
                    tbl = {
                        A = isVR,
                        B = isConsole,
                        C = isWindows,
                        D = "0.716.0.7160875",
                        E = isMobile, -- Gyroscope Enabled
                        F = isMobile, -- Touch Enabled
                        G = not isMobile, -- Keyboard Enabled
                        H = not isMobile, -- Mouse Enabled
                        I = true
                    }
                })
            else
                -- Fallback to standard "metrics" payload
                local baseFps = tonumber(spoofedFps) or 60
                local baseMem = tonumber(spoofedMem) or 1032322
                local baseResX = tonumber(spoofedResX) or 132232
                local baseResY = tonumber(spoofedResY) or 1323232

                local finalFps = baseFps
                local finalMem = baseMem

                -- Apply organic fluctuations if dynamic randomization is active
                if randomize then
                    finalFps = baseFps + math.random(-3, 3)       -- Fluctuates FPS by +/- 3
                    finalMem = baseMem + math.random(-15, 15)     -- Subtle, low-range Memory fluctuation
                end

                -- Ensure we don't accidentally send negative values
                finalFps = math.max(1, finalFps)
                finalMem = math.max(1, finalMem)

                local chosenGfx = gfxEnums[spoofedGfx] or Enum.SavedQualitySetting.QualityLevel10

                nyaEvent:FireServer({
                    token = token,
                    fps = finalFps,
                    mem = finalMem,
                    t = "metrics",
                    res = Vector2.new(baseResX, baseResY),
                    gfx = chosenGfx
                })
            end
        end)
    end

    -- ===== TAPERUI INTERFACE ELEMENTS =====

    elements:Label("🎯 Metric & FPS Spoofer", parent)

    elements:Toggle("Enable Spoofer", parent, enabled, function(state)
        enabled = state
        if enabled then
            setupSpoofer()
            if getgenv().showToast then
                getgenv().showToast("Spoofer Active", "Intercepting metric pings.", TaperAssets.eye, 2.5)
            end
        else
            if meowConnection then
                meowConnection:Disconnect()
                meowConnection = nil
            end
        end
    end)

    elements:Toggle("Send to Server", parent, sendToServer, function(state)
        sendToServer = state
    end)

    elements:Toggle("Organic Fluctuation", parent, randomize, function(state)
        randomize = state
    end)

    elements:Dropdown("Spoofed Platform (OS)", parent, {
        "Windows", "macOS", "Linux", "Android", "iOS", "Console", "VR"
    }, spoofedPlatform, function(option)
        spoofedPlatform = option
    end)

    elements:Dropdown("Spoofed Graphics (GFX)", parent, {
        "QualityLevel1", "QualityLevel2", "QualityLevel3", "QualityLevel4", "QualityLevel5",
        "QualityLevel6", "QualityLevel7", "QualityLevel8", "QualityLevel9", "QualityLevel10",
        "Automatic"
    }, spoofedGfx, function(option)
        spoofedGfx = option
    end)

    elements:Textbox("Spoofed FPS Value", parent, spoofedFps, function(text)
        spoofedFps = text
    end)

    elements:Textbox("Spoofed Memory", parent, spoofedMem, function(text)
        spoofedMem = text
    end)

    elements:Textbox("Spoofed Resolution X", parent, spoofedResX, function(text)
        spoofedResX = text
    end)

    elements:Textbox("Spoofed Resolution Y", parent, spoofedResY, function(text)
        spoofedResY = text
    end)

    elements:Spacer(8, parent)

    elements:Paragraph(
        "Metric Settings Details", 
        "• Send to Server: If disabled, TaperUI blocks your clients metrics payload from sending to the server entirely.\n• Organic Fluctuation: Gently fluctuates your metrics up and down on each ping to simulate authentic game performance.\n• Resolution X/Y: Configures the Vector2 screen size resolution metrics reported to the leaderboard.", 
        parent
    )

    -- Cleanup connection on GUI destroy
    parent.Destroying:Connect(function()
        enabled = false
        if meowConnection then
            meowConnection:Disconnect()
            meowConnection = nil
        end
    end)
end