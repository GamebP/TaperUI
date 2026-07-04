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
            
            -- Verify if the boolean to send data to the server is checked
            if not sendToServer then return end

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

            -- Spoof and send the payload
            nyaEvent:FireServer({
                token = data.token,
                fps = finalFps,
                mem = finalMem,
                t = "metrics",
                res = Vector2.new(baseResX, baseResY),
                gfx = Enum.SavedQualitySetting.QualityLevel10
            })
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