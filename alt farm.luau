-- Optimized Configuration
getgenv().mainaccount = getgenv().mainaccount or "YourMainUsername"
getgenv().mainhelpers = getgenv().mainhelpers or {"alt1", "alt2"}
getgenv().webhookURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"
getgenv().checkInterval = 60
getgenv().killMilestone = 100
getgenv().lastKillCount = 0

-- Cache services for faster access
local Services = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService")
}

-- Cache player references
local player = Services.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Single state table for memory efficiency
local State = {
    Farming = false,
    KeyPress = false,
    FpsCap = false,
    AccountChecker = false,
    StartTime = 0,
    LastUpdate = 0,
    LastKeyPress = 0,
    LastFpsCheck = 0,
    LastAccountCheck = 0,
    CachedKills = 0,
    CurrentFps = 60
}

-- Optimized GUI with minimal elements
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmingOverlay"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Parent = playerGui

    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.3  -- Semi-transparent instead of full black
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 10
    overlay.Visible = false
    overlay.Parent = screenGui

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 300, 0, 120)
    statusLabel.Position = UDim2.new(0.5, -150, 0.5, -60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Inactive\nKills: 0\nTime: 00:00:00"
    statusLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
    statusLabel.TextSize = 22
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.LineHeight = 1.5
    statusLabel.Parent = overlay

    return screenGui, overlay, statusLabel
end

local ScreenGui, Overlay, StatusLabel = createGUI()

-- Optimized utility functions
local function formatTime(seconds)
    return string.format("%02d:%02d:%02d", 
        math.floor(seconds / 3600),
        math.floor((seconds % 3600) / 60),
        math.floor(seconds % 60)
    )
end

-- Optimized kill checking with frequency limiting
local lastKillStat
local function getKills()
    local now = tick()
    if now - State.LastUpdate < 0.5 and lastKillStat then
        return State.CachedKills
    end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        -- Cache the kill stat reference
        if not lastKillStat then
            lastKillStat = leaderstats:FindFirstChild("Kills") or 
                          leaderstats:FindFirstChild("kills") or 
                          leaderstats:FindFirstChild("KOs") or 
                          leaderstats:FindFirstChild("Eliminations")
        end
        
        if lastKillStat then
            State.CachedKills = lastKillStat.Value
        end
    end
    
    State.LastUpdate = now
    return State.CachedKills
end

-- Optimized key pressing with proper timing
local Keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
local KeyIndex = 1
local function handleKeyPress()
    if not State.KeyPress or tick() - State.LastKeyPress < 0.2 then return end
    
    local key = Keys[KeyIndex]
    Services.VirtualInputManager:SendKeyEvent(true, key, false, game)
    Services.RunService.RenderStepped:Wait()
    Services.VirtualInputManager:SendKeyEvent(false, key, false, game)
    
    KeyIndex = KeyIndex < 4 and KeyIndex + 1 or 1
    State.LastKeyPress = tick()
end

-- Optimized FPS management
local function updateFPS()
    if not State.FpsCap or tick() - State.LastFpsCheck < 2 then return end
    
    local targetFPS = 60  -- Default
    
    if player.Name:lower() == getgenv().mainaccount:lower() then
        targetFPS = 240  -- Main account gets 240 FPS
    else
        local isHelper = false
        for _, helper in ipairs(getgenv().mainhelpers) do
            if player.Name:lower() == helper:lower() then
                isHelper = true
                break
            end
        end
        
        if isHelper then
            targetFPS = 3  -- Helper accounts get 3 FPS
        else
            targetFPS = 60  -- Other accounts get 60 FPS
        end
    end
    
    if State.CurrentFps ~= targetFPS then
        pcall(function()
            setfpscap(targetFPS)
            State.CurrentFps = targetFPS
        end)
    end
    
    State.LastFpsCheck = tick()
end

-- Optimized teleport function
local function teleport(x, y, z)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
        return true
    end
    return false
end

-- Optimized webhook system with rate limiting
local lastWebhookTime = 0
local function sendWebhook(title, description, color, ping)
    local now = tick()
    if now - lastWebhookTime < 5 then return false end  -- Rate limit: 1 webhook per 5 seconds
    
    local url = getgenv().webhookURL
    if not url or url == "" or url:find("YOUR_WEBHOOK") then return false end
    
    local success = pcall(function()
        local data = {
            content = ping and "@everyone" or "",
            embeds = {{
                title = title,
                description = description,
                color = color or 65280,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
            }}
        }
        
        request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = Services.HttpService:JSONEncode(data)
        })
    end)
    
    lastWebhookTime = now
    return success
end

-- Optimized account monitoring with caching
local playerCache = {}
local function updatePlayerCache()
    table.clear(playerCache)
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        playerCache[plr.Name:lower()] = true
    end
end

local function checkAccounts()
    if tick() - State.LastAccountCheck < getgenv().checkInterval then return end
    
    updatePlayerCache()
    
    local mainOnline = playerCache[getgenv().mainaccount:lower()]
    local helpersOnline = 0
    local totalHelpers = #getgenv().mainhelpers
    
    for _, helper in ipairs(getgenv().mainhelpers) do
        if playerCache[helper:lower()] then
            helpersOnline = helpersOnline + 1
        end
    end
    
    State.LastAccountCheck = tick()
    
    -- Send milestone webhook if needed
    if mainOnline and getgenv().killMilestone > 0 then
        local kills = getKills()
        local currentMilestone = math.floor(kills / getgenv().killMilestone)
        local lastMilestone = math.floor(getgenv().lastKillCount / getgenv().killMilestone)
        
        if currentMilestone > lastMilestone and kills > 0 then
            sendWebhook(
                "🎉 Kill Milestone Reached!",
                string.format("**%s** has reached **%d kills**! (Every %d kills)", 
                    getgenv().mainaccount, kills, getgenv().killMilestone),
                16766720,  -- Orange
                true      -- Ping everyone
            )
            getgenv().lastKillCount = kills
        end
    end
    
    return mainOnline, helpersOnline, totalHelpers
end

-- Load InfiniteYield if needed
if not _G.InfiniteYieldLoaded then
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    _G.InfiniteYieldLoaded = true
end

-- Load Luna UI with performance optimizations
if not _G.LunaLoaded then
    local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()
    _G.LunaLoaded = true
    
    local Window = Luna:CreateWindow({
        Name = "Optimized Automation",
        Subtitle = "Performance-Focused Farming",
        LogoID = nil,
        LoadingEnabled = false,
        ConfigSettings = {
            RootFolder = nil,
            ConfigFolder = "AutomationHub"
        },
        KeySystem = false
    })
    
    -- Automation Tab
    local AutoTab = Window:CreateTab({Name = "Automation", Icon = "sports_esports", ShowTitle = true})
    
    AutoTab:CreateToggle({
        Name = "Farming Mode",
        Description = "Enable farming overlay and tracking",
        CurrentValue = State.Farming,
        Callback = function(value)
            State.Farming = value
            Overlay.Visible = value
            if value then
                State.StartTime = tick()
                State.CachedKills = getKills()
            end
        end
    })
    
    AutoTab:CreateToggle({
        Name = "Auto Key Press",
        Description = "Automatically press keys 1-4",
        CurrentValue = State.KeyPress,
        Callback = function(value)
            State.KeyPress = value
            if value then
                KeyIndex = 1
            end
        end
    })
    
    AutoTab:CreateToggle({
        Name = "FPS Control",
        Description = "Main: 240 FPS | Helpers: 3 FPS | Others: 60 FPS",
        CurrentValue = State.FpsCap,
        Callback = function(value)
            State.FpsCap = value
            if not value then
                State.CurrentFps = 60
                pcall(function() setfpscap(60) end)
            end
        end
    })
    
    -- Monitor Tab
    local MonitorTab = Window:CreateTab({Name = "Monitor", Icon = "group", ShowTitle = true})
    
    MonitorTab:CreateToggle({
        Name = "Account Monitor",
        Description = "Track accounts and send webhooks",
        CurrentValue = State.AccountChecker,
        Callback = function(value)
            State.AccountChecker = value
        end
    })
    
    local statusText = MonitorTab:CreateLabel({Text = "Monitoring: Inactive", Style = 2})
    
    MonitorTab:CreateButton({
        Name = "Check Now",
        Description = "Manual status check",
        Callback = function()
            local mainOnline, helpersOnline, totalHelpers = checkAccounts()
            statusText:Set(string.format("Main: %s | Helpers: %d/%d",
                mainOnline and "✅" or "❌", helpersOnline, totalHelpers))
        end
    })
    
    -- Teleport Tab
    local TeleTab = Window:CreateTab({Name = "Teleport", Icon = "location_on", ShowTitle = true})
    
    local coords = {x = 438.7, y = 441.8, z = -376.2}
    
    TeleTab:CreateInput({
        Name = "Coordinates",
        Placeholder = "X, Y, Z",
        CurrentValue = "438.7, 441.8, -376.2",
        Callback = function(val)
            local parts = string.split(val, ",")
            if #parts >= 3 then
                coords.x = tonumber(parts[1]) or 438.7
                coords.y = tonumber(parts[2]) or 441.8
                coords.z = tonumber(parts[3]) or -376.2
            end
        end
    })
    
    TeleTab:CreateButton({
        Name = "Teleport",
        Description = "Teleport to coordinates",
        Callback = function()
            if teleport(coords.x, coords.y, coords.z) then
                Luna:Notification({
                    Title = "Teleported",
                    Content = string.format("Position: %.1f, %.1f, %.1f", coords.x, coords.y, coords.z)
                })
            end
        end
    })
    
    -- Settings Tab
    local SettingsTab = Window:CreateTab({Name = "Settings", Icon = "settings", ShowTitle = true})
    
    SettingsTab:CreateInput({
        Name = "Webhook URL",
        Placeholder = "Discord webhook URL",
        CurrentValue = getgenv().webhookURL,
        Callback = function(val)
            getgenv().webhookURL = val
        end
    })
    
    SettingsTab:CreateInput({
        Name = "Kill Milestone",
        Placeholder = "Ping every X kills",
        CurrentValue = tostring(getgenv().killMilestone),
        Numeric = true,
        Callback = function(val)
            getgenv().killMilestone = math.max(1, tonumber(val) or 100)
        end
    })
    
    SettingsTab:CreateParagraph({
        Title = "Current Account",
        Text = string.format("Name: %s\nType: %s", 
            player.Name,
            player.Name:lower() == getgenv().mainaccount:lower() and "Main Account (240 FPS)" or 
            (function()
                for _, h in ipairs(getgenv().mainhelpers) do
                    if player.Name:lower() == h:lower() then
                        return "Helper Account (3 FPS)"
                    end
                end
                return "Regular Account (60 FPS)"
            end)()
        )
    })
end

-- Main optimized update loop
local MainConnection
MainConnection = Services.RunService.Heartbeat:Connect(function(deltaTime)
    local now = tick()
    
    -- Update farming overlay
    if State.Farming then
        local elapsed = now - State.StartTime
        local kills = getKills()
        StatusLabel.Text = string.format("Status: Farming\nKills: %d\nTime: %s", 
            kills, formatTime(elapsed))
    end
    
    -- Handle key pressing (optimized to only run when needed)
    if State.KeyPress then
        handleKeyPress()
    end
    
    -- Update FPS settings
    if State.FpsCap then
        updateFPS()
    end
    
    -- Account monitoring
    if State.AccountChecker and now - State.LastAccountCheck >= getgenv().checkInterval then
        checkAccounts()
    end
end)

-- Player tracking with debouncing
local playerDebounce = false
Services.Players.PlayerAdded:Connect(function(plr)
    if playerDebounce then return end
    playerDebounce = true
    
    task.delay(2, function()  -- Debounce for 2 seconds
        playerDebounce = false
        if State.AccountChecker then
            updatePlayerCache()
        end
    end)
end)

Services.Players.PlayerRemoving:Connect(function(plr)
    if playerDebounce then return end
    playerDebounce = true
    
    task.delay(2, function()
        playerDebounce = false
        if State.AccountChecker then
            updatePlayerCache()
        end
    end)
end)

-- Window focus handling (optimized)
Services.UserInputService.WindowFocused:Connect(function()
    if State.Farming then
        Overlay.Visible = true
    end
end)

Services.UserInputService.WindowFocusReleased:Connect(function()
    if State.Farming then
        Overlay.Visible = false
    end
end)

-- Initial setup
updatePlayerCache()
pcall(function() setfpscap(60) end)  -- Set initial FPS cap
State.CurrentFps = 60

print("Optimized Automation System Loaded")
print("Main Account: " .. getgenv().mainaccount .. " (240 FPS)")
print("Helper Accounts: " .. table.concat(getgenv().mainhelpers, ", ") .. " (3 FPS)")
