getgenv().mainaccount = getgenv().mainaccount or "YourMainUsername"
getgenv().mainhelpers = getgenv().mainhelpers or {"alt1", "alt2"}
getgenv().webhookURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"
getgenv().checkInterval = 60
getgenv().killMilestone = 100
getgenv().lastKillCount = getgenv().lastKillCount or 0

if not _G.InfiniteYieldLoaded then
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    _G.InfiniteYieldLoaded = true
end

local Services = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    HttpService = game:GetService("HttpService"),
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    StarterGui = game:GetService("StarterGui")
}

local player = Services.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local State = {
    Farming = false,
    KeyPress = false,
    FpsCap = false,
    AccountChecker = false,
    AntiAFK = false,
    StartTime = 0,
    LastUpdate = 0,
    LastKeyPress = 0,
    LastFpsCheck = 0,
    LastAccountCheck = 0,
    CachedKills = 0,
    CurrentFps = 60
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmingOverlay"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- MODIFIED: Completely black opaque overlay
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0 -- Changed from 0.3 to 0 (fully opaque)
overlay.BorderSizePixel = 0
overlay.ZIndex = 10
overlay.Visible = false
overlay.Parent = screenGui

-- MODIFIED: Added a black background panel for the status label
local statusPanel = Instance.new("Frame")
statusPanel.Name = "StatusPanel"
statusPanel.Size = UDim2.new(0, 400, 0, 180)
statusPanel.Position = UDim2.new(0.5, -200, 0.5, -90)
statusPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statusPanel.BackgroundTransparency = 0
statusPanel.BorderSizePixel = 0
statusPanel.ZIndex = 11
statusPanel.Parent = overlay

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -40, 1, -40)
statusLabel.Position = UDim2.new(0, 20, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Inactive\nKills: 0\nTime: 00:00:00"
statusLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
statusLabel.TextSize = 24
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.LineHeight = 1.8
statusLabel.Parent = statusPanel

-- MODIFIED: Added a title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BackgroundTransparency = 0
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 12
titleBar.Parent = statusPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "FARMING STATUS"
titleLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = titleBar

local function formatTime(seconds)
    return string.format("%02d:%02d:%02d", 
        math.floor(seconds / 3600),
        math.floor((seconds % 3600) / 60),
        math.floor(seconds % 60))
end

local lastKillStat
local function getKills()
    local now = tick()
    if now - State.LastUpdate < 0.5 and lastKillStat then
        return State.CachedKills
    end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
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

local Keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.G}
local KeyIndex = 1
local function handleKeyPress()
    if not State.KeyPress or tick() - State.LastKeyPress < 0.2 then return end
    
    local key = Keys[KeyIndex]
    Services.VirtualInputManager:SendKeyEvent(true, key, false, game)
    Services.RunService.RenderStepped:Wait()
    Services.VirtualInputManager:SendKeyEvent(false, key, false, game)
    
    KeyIndex = KeyIndex < 5 and KeyIndex + 1 or 1
    State.LastKeyPress = tick()
end

local function updateFPS()
    if not State.FpsCap or tick() - State.LastFpsCheck < 2 then return end
    
    local targetFPS = 60
    
    if player.Name:lower() == getgenv().mainaccount:lower() then
        targetFPS = 240
    else
        local isHelper = false
        for _, helper in ipairs(getgenv().mainhelpers) do
            if player.Name:lower() == helper:lower() then
                isHelper = true
                break
            end
        end
        
        if isHelper then
            targetFPS = 3
        else
            targetFPS = 60
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

local function teleport(x, y, z)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
        return true
    end
    return false
end

local lastWebhookTime = 0
local function sendWebhook(title, description, color, ping)
    local now = tick()
    if now - lastWebhookTime < 5 then return false end
    
    local url = getgenv().webhookURL
    if not url or url == "" or url:find("YOUR_WEBHOOK") then return false end
    
    local success, result = pcall(function()
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
    if not success then
        warn("Webhook failed:", result)
    end
    return success
end

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
    
    local serverInfo = "Server: " .. game.PlaceId
    local statusText = string.format("**Account Status Report**\n\nMain Account: %s\nHelpers Online: %d/%d\n\n%s", 
        mainOnline and "✅ Online" or "❌ Offline", 
        helpersOnline, 
        totalHelpers,
        serverInfo)
    
    local allMonitoredAccounts = {}
    table.insert(allMonitoredAccounts, getgenv().mainaccount)
    for _, helper in ipairs(getgenv().mainhelpers) do
        table.insert(allMonitoredAccounts, helper)
    end
    
    local accountDetails = "\n\n**Monitored Accounts:**\n"
    for _, accountName in ipairs(allMonitoredAccounts) do
        local onlineStatus = playerCache[accountName:lower()] and "🟢 Online" or "🔴 Offline"
        accountDetails = accountDetails .. string.format("- %s: %s\n", accountName, onlineStatus)
    end
    
    statusText = statusText .. accountDetails
    
    sendWebhook(
        "📊 Account Status",
        statusText,
        mainOnline and 65280 or 16711680,
        false
    )
    
    if mainOnline and getgenv().killMilestone > 0 then
        local kills = getKills()
        local lastKills = getgenv().lastKillCount or 0
        local currentMilestone = math.floor(kills / getgenv().killMilestone)
        local lastMilestone = math.floor(lastKills / getgenv().killMilestone)
        
        if currentMilestone > lastMilestone and kills > 0 then
            sendWebhook(
                "🎉 Kill Milestone Reached!",
                string.format("**%s** has reached **%d kills**! (Every %d kills)", 
                    getgenv().mainaccount, kills, getgenv().killMilestone),
                16766720,
                true)
            getgenv().lastKillCount = kills
        end
    end
    
    return mainOnline, helpersOnline, totalHelpers
end

local antiAFKConnection
local function setupAntiAFK()
    if State.AntiAFK then
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
        end
        
        antiAFKConnection = player.Idled:Connect(function()
            Services.VirtualUser:CaptureController()
            Services.VirtualUser:ClickButton2(Vector2.new())
        end)
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Anti-AFK",
            Text = "Anti-AFK Activated",
            Duration = 5
        })
    else
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
            antiAFKConnection = nil
        end
        
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Anti-AFK",
            Text = "Anti-AFK Deactivated",
            Duration = 5
        })
    end
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Automation Hub",
    SubTitle = "Farming System",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Automation = Window:AddTab({ Title = "Automation", Icon = "gamepad-2" }),
    Monitor = Window:AddTab({ Title = "Monitor", Icon = "users" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

Tabs.Automation:AddToggle("FarmingToggle", {
    Title = "Farming Mode",
    Description = "Enable farming overlay",
    Default = false,
    Callback = function(value)
        State.Farming = value
        overlay.Visible = value
        if value then
            State.StartTime = tick()
            State.CachedKills = getKills()
        end
    end
})

Tabs.Automation:AddToggle("KeyPressToggle", {
    Title = "Auto Key Press",
    Description = "Press keys 1-4 and G automatically",
    Default = false,
    Callback = function(value)
        State.KeyPress = value
        if value then
            KeyIndex = 1
        end
    end
})

Tabs.Automation:AddToggle("FpsToggle", {
    Title = "FPS Control",
    Description = "Main: 240 FPS | Helpers: 3 FPS",
    Default = false,
    Callback = function(value)
        State.FpsCap = value
        if not value then
            State.CurrentFps = 60
            pcall(function() setfpscap(60) end)
        end
    end
})

Tabs.Automation:AddToggle("AntiAFKToggle", {
    Title = "Anti-AFK",
    Description = "Prevent being kicked for AFK",
    Default = false,
    Callback = function(value)
        State.AntiAFK = value
        setupAntiAFK()
    end
})

local monitorStatus = Tabs.Monitor:AddParagraph({
    Title = "Status",
    Content = "Monitoring: Inactive"
})

Tabs.Monitor:AddToggle("MonitorToggle", {
    Title = "Account Monitor",
    Description = "Track accounts and send webhooks",
    Default = false,
    Callback = function(value)
        State.AccountChecker = value
        monitorStatus:SetDesc(value and "🟢 Monitoring Active" or "🔴 Monitoring Inactive")
    end
})

Tabs.Monitor:AddButton({
    Title = "Check Now",
    Description = "Manual status check",
    Callback = function()
        local success, result = pcall(function()
            local mainOnline, helpersOnline, totalHelpers = checkAccounts()
            monitorStatus:SetDesc(string.format("Main: %s | Helpers: %d/%d",
                mainOnline and "✅" or "❌", helpersOnline, totalHelpers))
        end)
        
        if not success then
            warn("Check accounts error:", result)
            Fluent:Notify({
                Title = "Error",
                Content = "Failed to check accounts: " .. tostring(result),
                Duration = 5
            })
        end
    end
})

local coords = {x = 438.7, y = 441.8, z = -376.2}
local coordInput = Tabs.Teleport:AddInput("CoordInput", {
    Title = "Coordinates",
    Default = "438.7, 441.8, -376.2",
    Placeholder = "X, Y, Z",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        local parts = string.split(value, ",")
        if #parts >= 3 then
            coords.x = tonumber(parts[1]) or 438.7
            coords.y = tonumber(parts[2]) or 441.8
            coords.z = tonumber(parts[3]) or -376.2
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport",
    Description = "Teleport to coordinates",
    Callback = function()
        if teleport(coords.x, coords.y, coords.z) then
            Window:Dialog({
                Title = "Success",
                Content = string.format("Teleported to: %.1f, %.1f, %.1f", coords.x, coords.y, coords.z),
                Buttons = {
                    {
                        Title = "OK",
                        Callback = function() end
                    }
                }
            })
        end
    end
})

Tabs.Settings:AddInput("WebhookInput", {
    Title = "Webhook URL",
    Default = getgenv().webhookURL,
    Placeholder = "Discord webhook URL",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        getgenv().webhookURL = value
    end
})

Tabs.Settings:AddInput("MilestoneInput", {
    Title = "Kill Milestone",
    Default = tostring(getgenv().killMilestone),
    Placeholder = "Ping every X kills",
    Numeric = true,
    Finished = false,
    Callback = function(value)
        getgenv().killMilestone = math.max(1, tonumber(value) or 100)
    end
})

local accountType = ""
if player.Name:lower() == getgenv().mainaccount:lower() then
    accountType = "Main Account (240 FPS)"
else
    local isHelper = false
    for _, helper in ipairs(getgenv().mainhelpers) do
        if player.Name:lower() == helper:lower() then
            isHelper = true
            break
        end
    end
    accountType = isHelper and "Helper Account (3 FPS)" or "Regular Account (60 FPS)"
end

Tabs.Settings:AddParagraph({
    Title = "Account Info",
    Content = string.format("Name: %s\nType: %s", player.Name, accountType)
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AutomationHub")
SaveManager:SetFolder("AutomationHub/config")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Automation Hub",
    Content = "System loaded successfully",
    Duration = 3
})

local MainConnection
MainConnection = Services.RunService.Heartbeat:Connect(function()
    local now = tick()
    
    if State.Farming then
        local elapsed = now - State.StartTime
        local kills = getKills()
        statusLabel.Text = string.format("Status: Farming\nKills: %d\nTime: %s", 
            kills, formatTime(elapsed))
    end
    -- MODIFIED: Fixed reference from overlay:FindFirstChild("StatusLabel") to statusLabel
    
    if State.KeyPress then
        handleKeyPress()
    end
    
    if State.FpsCap then
        updateFPS()
    end
    
    if State.AccountChecker and now - State.LastAccountCheck >= getgenv().checkInterval then
        pcall(checkAccounts)
    end
end)

local playerDebounce = false
Services.Players.PlayerAdded:Connect(function()
    if playerDebounce then return end
    playerDebounce = true
    
    task.delay(2, function()
        playerDebounce = false
        if State.AccountChecker then
            updatePlayerCache()
        end
    end)
end)

Services.Players.PlayerRemoving:Connect(function()
    if playerDebounce then return end
    playerDebounce = true
    
    task.delay(2, function()
        playerDebounce = false
        if State.AccountChecker then
            updatePlayerCache()
        end
    end)
end)

Services.UserInputService.WindowFocused:Connect(function()
    if State.Farming then
        overlay.Visible = true
    end
end)

Services.UserInputService.WindowFocusReleased:Connect(function()
    if State.Farming then
        overlay.Visible = false
    end
end)

updatePlayerCache()
pcall(function() setfpscap(60) end)
State.CurrentFps = 60

print("Automation Hub Loaded")
