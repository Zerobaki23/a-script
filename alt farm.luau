getgenv().mainaccount = getgenv().mainaccount or "YourMainUsername"
getgenv().mainhelpers = getgenv().mainhelpers or {"alt1", "alt2"}
getgenv().webhookURL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"
getgenv().localServerURL = "http://192.168.100.244:5000/webhook"
getgenv().checkInterval = 60
getgenv().killMilestone = 100
getgenv().lastKillCount = getgenv().lastKillCount or 0
getgenv().lastKillUpdate = getgenv().lastKillUpdate or 0

-- Command system storage
getgenv().CommandQueue = getgenv().CommandQueue or {}
getgenv().CommandHistory = getgenv().CommandHistory or {}

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
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    MessagingService = game:GetService("MessagingService")
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
    CurrentFps = 60,
    LastCommandCheck = 0
}

print("Creating GUI...")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmingOverlay"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999

local success, errorMsg = pcall(function()
    screenGui.Parent = playerGui
end)

if not success then
    print("Failed to parent to PlayerGui:", errorMsg)
    print("Trying CoreGui...")
    screenGui.Parent = Services.CoreGui
end

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0
overlay.BorderSizePixel = 0
overlay.ZIndex = 10
overlay.Visible = false
overlay.Parent = screenGui

print("Created overlay frame")

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

print("GUI created successfully")

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

local function getKillsForPlayer(playerName)
    local targetPlayer = Services.Players:FindFirstChild(playerName)
    if not targetPlayer then return 0 end
    
    local leaderstats = targetPlayer:FindFirstChild("leaderstats")
    if not leaderstats then return 0 end
    
    local killStat = leaderstats:FindFirstChild("Kills") or 
                     leaderstats:FindFirstChild("kills") or 
                     leaderstats:FindFirstChild("KOs") or 
                     leaderstats:FindFirstChild("Eliminations")
    
    if killStat then
        return killStat.Value
    end
    
    return 0
end

local function getAllAccountKills()
    local accountKills = {}
    
    accountKills[getgenv().mainaccount] = getKillsForPlayer(getgenv().mainaccount)
    
    for _, helper in ipairs(getgenv().mainhelpers) do
        accountKills[helper] = getKillsForPlayer(helper)
    end
    
    return accountKills
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
local lastLocalServerTime = 0

local function sendToLocalServer(data)
    local now = tick()
    if now - lastLocalServerTime < 5 then return false end
    
    local url = getgenv().localServerURL
    if not url or url == "" then 
        print("Local server URL not configured")
        return false 
    end
    
    local success, result = pcall(function()
        local response = request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = Services.HttpService:JSONEncode(data)
        })
        return response
    end)
    
    lastLocalServerTime = now
    if success then
        print("✓ Data sent to local server")
        return true
    else
        print("✗ Failed to send to local server:", result)
        return false
    end
end

local function sendKillUpdate()
    local now = tick()
    if now - getgenv().lastKillUpdate < 5 then return end
    
    local kills = getKills()
    local url = getgenv().localServerURL
    if not url or url == "" then return end
    
    local killData = {
        type = "kill_update",
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S"),
        account = player.Name,
        kills = kills
    }
    
    local success = sendToLocalServer(killData)
    
    if success then
        getgenv().lastKillUpdate = now
        print("✓ Kill update sent:", kills)
    end
end

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

-- ============================================================================
-- COMMAND SYSTEM
-- ============================================================================

local function broadcastCommand(commandType, data, target)
    target = target or "all"
    
    local command = {
        id = Services.HttpService:GenerateGUID(false),
        type = commandType,
        data = data,
        sender = player.Name,
        target = target,
        timestamp = tick()
    }
    
    if not getgenv().CommandQueue then
        getgenv().CommandQueue = {}
    end
    
    table.insert(getgenv().CommandQueue, command)
    
    print(string.format("[COMMAND] Broadcasting: %s to %s", commandType, target))
    
    return true
end

local function checkForCommands()
    if not getgenv().CommandQueue then
        getgenv().CommandQueue = {}
        return
    end
    
    local isHelper = false
    for _, helper in ipairs(getgenv().mainhelpers) do
        if player.Name:lower() == helper:lower() then
            isHelper = true
            break
        end
    end
    
    if not isHelper then return end
    
    local now = tick()
    local processedCommands = {}
    
    for i, command in ipairs(getgenv().CommandQueue) do
        if command.sender ~= player.Name then
            local shouldProcess = false
            
            if command.target == "all" then
                shouldProcess = true
            elseif command.target:lower() == player.Name:lower() then
                shouldProcess = true
            end
            
            if shouldProcess and (now - command.timestamp < 30) then
                if command.type == "message" then
                    print(string.format("[MESSAGE] From %s: %s", command.sender, command.data.message))
                    
                    pcall(function()
                        Services.StarterGui:SetCore("SendNotification", {
                            Title = "📢 " .. command.sender,
                            Text = command.data.message,
                            Duration = 8
                        })
                    end)
                    
                elseif command.type == "execute" then
                    print(string.format("[EXECUTE] From %s: Running code...", command.sender))
                    
                    local success, result = pcall(function()
                        loadstring(command.data.code)()
                    end)
                    
                    if success then
                        print("[EXECUTE] ✓ Code executed successfully")
                        pcall(function()
                            Services.StarterGui:SetCore("SendNotification", {
                                Title = "⚡ Code Executed",
                                Text = "From " .. command.sender,
                                Duration = 3
                            })
                        end)
                    else
                        warn("[EXECUTE] ✗ Error:", result)
                        pcall(function()
                            Services.StarterGui:SetCore("SendNotification", {
                                Title = "❌ Execution Error",
                                Text = tostring(result):sub(1, 50),
                                Duration = 5
                            })
                        end)
                    end
                end
                
                table.insert(processedCommands, i)
            end
        end
    end
    
    for i = #processedCommands, 1, -1 do
        table.remove(getgenv().CommandQueue, processedCommands[i])
    end
    
    local expireTime = now - 60
    for i = #getgenv().CommandQueue, 1, -1 do
        if getgenv().CommandQueue[i].timestamp < expireTime then
            table.remove(getgenv().CommandQueue, i)
        end
    end
end

-- ============================================================================
-- ACCOUNT CHECKING
-- ============================================================================

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
    
    local accountKills = getAllAccountKills()
    
    local serverInfo = "Server: " .. tostring(game.PlaceId)
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
        local kills = accountKills[accountName] or 0
        accountDetails = accountDetails .. string.format("- %s: %s | Kills: %d\n", accountName, onlineStatus, kills)
    end
    
    statusText = statusText .. accountDetails
    
    local localServerData = {
        type = "account_status",
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S"),
        placeId = tostring(game.PlaceId),
        mainAccount = {
            name = getgenv().mainaccount,
            online = mainOnline,
            kills = accountKills[getgenv().mainaccount] or 0
        },
        helpers = {
            online = helpersOnline,
            total = totalHelpers,
            details = {}
        },
        accountKills = accountKills,
        totalKills = 0
    }
    
    local totalKills = 0
    for _, accountName in ipairs(allMonitoredAccounts) do
        local kills = accountKills[accountName] or 0
        totalKills = totalKills + kills
        
        table.insert(localServerData.helpers.details, {
            name = accountName,
            online = playerCache[accountName:lower()] or false,
            kills = kills
        })
    end
    
    localServerData.totalKills = totalKills
    
    local playerNames = {}
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        table.insert(playerNames, plr.Name)
    end
    localServerData.allPlayers = playerNames
    
    local localSuccess = sendToLocalServer(localServerData)
    
    if localSuccess then
        print(string.format("✓ Sent data: Total Kills: %d", totalKills))
        for accountName, kills in pairs(accountKills) do
            print(string.format("  - %s: %d kills", accountName, kills))
        end
    end
    
    sendWebhook(
        "📊 Account Status",
        statusText,
        mainOnline and 65280 or 16711680,
        false
    )
    
    if mainOnline and getgenv().killMilestone > 0 then
        local kills = accountKills[getgenv().mainaccount] or 0
        local lastKills = getgenv().lastKillCount or 0
        local currentMilestone = math.floor(kills / getgenv().killMilestone)
        local lastMilestone = math.floor(lastKills / getgenv().killMilestone)
        
        if currentMilestone > lastMilestone and kills > 0 then
            local milestoneData = {
                type = "milestone",
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S"),
                account = getgenv().mainaccount,
                kills = kills,
                milestone = getgenv().killMilestone
            }
            
            sendToLocalServer(milestoneData)
            
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

print("Loading Fluent UI...")

local Fluent, SaveManager, InterfaceManager
local success, errorMsg = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Failed to load Fluent UI:", errorMsg)
    Services.StarterGui:SetCore("SendNotification", {
        Title = "Error",
        Text = "Failed to load Fluent UI. Check console.",
        Duration = 10
    })
    return
end

print("Fluent UI loaded successfully")

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
        print("Farming toggle:", value)
        State.Farming = value
        overlay.Visible = value
        if value then
            State.StartTime = tick()
            State.CachedKills = getKills()
            print("Farming started")
        else
            print("Farming stopped")
        end
    end
})

Tabs.Automation:AddToggle("KeyPressToggle", {
    Title = "Auto Key Press",
    Description = "Press keys 1-4 and G automatically",
    Default = false,
    Callback = function(value)
        print("Key press toggle:", value)
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
        print("FPS toggle:", value)
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
        print("Anti-AFK toggle:", value)
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
        print("Account monitor toggle:", value)
        State.AccountChecker = value
        monitorStatus:SetDesc(value and "🟢 Monitoring Active" or "🔴 Monitoring Inactive")
    end
})

Tabs.Monitor:AddButton({
    Title = "Check Now",
    Description = "Manual status check",
    Callback = function()
        print("Manual check triggered")
        local success, result = pcall(function()
            local mainOnline, helpersOnline, totalHelpers = checkAccounts()
            
            local accountKills = getAllAccountKills()
            local totalKills = 0
            for _, kills in pairs(accountKills) do
                totalKills = totalKills + kills
            end
            
            monitorStatus:SetDesc(string.format("Main: %s | Helpers: %d/%d | Total Kills: %d",
                mainOnline and "✅" or "❌", helpersOnline, totalHelpers, totalKills))
            
            if getgenv().localServerURL and getgenv().localServerURL ~= "" then
                Fluent:Notify({
                    Title = "Data Sent",
                    Content = string.format("Account data sent\nTotal Kills: %d", totalKills),
                    Duration = 3
                })
            end
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
        print("Teleporting to coordinates:", coords.x, coords.y, coords.z)
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

Tabs.Settings:AddInput("LocalServerInput", {
    Title = "Local Server URL",
    Default = getgenv().localServerURL,
    Placeholder = "http://192.168.100.244:5000/webhook",
    Numeric = false,
    Finished = false,
    Callback = function(value)
        getgenv().localServerURL = value
        print("Local server URL updated to:", value)
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
        print("Webhook URL updated")
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
        print("Kill milestone updated to:", getgenv().killMilestone)
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

local localServerStatus = Tabs.Settings:AddParagraph({
    Title = "Local Server",
    Content = "Status: Not tested"
})

Tabs.Settings:AddButton({
    Title = "Test Local Server",
    Description = "Test connection to local server",
    Callback = function()
        print("Testing local server connection...")
        local testData = {
            type = "test",
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S"),
            message = "Connection test from Automation Hub",
            player = player.Name,
            placeId = tostring(game.PlaceId)
        }
        
        local success, result = pcall(function()
            local response = request({
                Url = getgenv().localServerURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = Services.HttpService:JSONEncode(testData)
            })
            return response
        end)
        
        if success then
            localServerStatus:SetDesc("Status: ✅ Connected")
            Fluent:Notify({
                Title = "Success",
                Content = "Local server connection test successful!",
                Duration = 5
            })
        else
            localServerStatus:SetDesc("Status: ❌ Failed")
            Fluent:Notify({
                Title = "Error",
                Content = "Local server connection failed: " .. tostring(result),
                Duration = 5
            })
        end
    end
})

-- ============================================================================
-- COMMAND CENTER TAB (Main Account Only)
-- ============================================================================

local isMainAccount = player.Name:lower() == getgenv().mainaccount:lower()

if isMainAccount then
    local CommandTab = Window:AddTab({ Title = "Command Center", Icon = "terminal" })
    
    local commandHistory = {}
    local maxHistory = 50
    
    CommandTab:AddParagraph({
        Title = "📢 Broadcast Message",
        Content = "Send messages to all helper accounts"
    })
    
    local messageInput = CommandTab:AddInput("MessageInput", {
        Title = "Message",
        Default = "",
        Placeholder = "Enter message to broadcast...",
        Numeric = false,
        Finished = false
    })
    
    CommandTab:AddButton({
        Title = "Send Message",
        Description = "Broadcast to all helpers",
        Callback = function()
            local message = Options.MessageInput.Value
            if not message or message == "" then
                Fluent:Notify({
                    Title = "Error",
                    Content = "Please enter a message",
                    Duration = 3
                })
                return
            end
            
            local success = broadcastCommand("message", {message = message}, "all")
            
            if success then
                table.insert(commandHistory, 1, {
                    time = os.date("%H:%M:%S"),
                    type = "Message",
                    content = message,
                    status = "✅ Sent"
                })
                if #commandHistory > maxHistory then
                    table.remove(commandHistory)
                end
                
                Fluent:Notify({
                    Title = "Message Sent",
                    Content = "Broadcast to all helpers",
                    Duration = 3
                })
                
                Options.MessageInput:SetValue("")
            else
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to send message",
                    Duration = 3
                })
            end
        end
    })
    
    CommandTab:AddParagraph({
        Title = "⚡ Execute Code",
        Content = "Run Lua code on helper accounts"
    })
    
    local codeInput = CommandTab:AddInput("CodeInput", {
        Title = "Lua Code",
        Default = "",
        Placeholder = 'print("Hello from main!")',
        Numeric = false,
        Finished = false
    })
    
    local targetDropdown = CommandTab:AddDropdown("TargetDropdown", {
        Title = "Target Accounts",
        Values = {"All Helpers"},
        Multi = false,
        Default = 1
    })
    
    task.spawn(function()
        task.wait(0.5)
        local targets = {"All Helpers"}
        for _, helper in ipairs(getgenv().mainhelpers) do
            table.insert(targets, helper)
        end
        targetDropdown:SetValues(targets)
    end)
    
    CommandTab:AddButton({
        Title = "Execute Code",
        Description = "Run code on selected accounts",
        Callback = function()
            local code = Options.CodeInput.Value
            if not code or code == "" then
                Fluent:Notify({
                    Title = "Error",
                    Content = "Please enter code to execute",
                    Duration = 3
                })
                return
            end
            
            local target = Options.TargetDropdown.Value == "All Helpers" and "all" or Options.TargetDropdown.Value
            
            local success = broadcastCommand("execute", {code = code}, target)
            
            if success then
                table.insert(commandHistory, 1, {
                    time = os.date("%H:%M:%S"),
                    type = "Execute",
                    content = code:sub(1, 50) .. (code:len() > 50 and "..." or ""),
                    target = target,
                    status = "✅ Sent"
                })
                if #commandHistory > maxHistory then
                    table.remove(commandHistory)
                end
                
                Fluent:Notify({
                    Title = "Code Sent",
                    Content = "Executing on: " .. (target == "all" and "All Helpers" or target),
                    Duration = 3
                })
                
                Options.CodeInput:SetValue("")
            else
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to send code",
                    Duration = 3
                })
            end
        end
    })
    
    CommandTab:AddParagraph({
        Title = "🎮 Quick Actions",
        Content = "Common commands for helpers"
    })
    
    local quickActions = {
        {
            name = "Teleport All to Main",
            code = function()
                local mainPlayer = Services.Players:FindFirstChild(getgenv().mainaccount)
                if mainPlayer and mainPlayer.Character and mainPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = mainPlayer.Character.HumanoidRootPart.Position
                    return string.format([[
local char = game.Players.LocalPlayer.Character
if char and char:FindFirstChild("HumanoidRootPart") then
    char.HumanoidRootPart.CFrame = CFrame.new(%f, %f, %f)
end]], pos.X, pos.Y, pos.Z)
                end
                return nil
            end
        },
        {
            name = "Teleport All to Coords",
            code = string.format([[
local char = game.Players.LocalPlayer.Character
if char and char:FindFirstChild("HumanoidRootPart") then
    char.HumanoidRootPart.CFrame = CFrame.new(%f, %f, %f)
end]], coords.x, coords.y, coords.z)
        },
        {
            name = "Reset All Characters",
            code = 'game.Players.LocalPlayer.Character:FindFirstChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)'
        },
        {
            name = "Show Helper Positions",
            code = [[
local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if hrp then
    local pos = hrp.Position
    print(string.format("%s Position: %.1f, %.1f, %.1f", game.Players.LocalPlayer.Name, pos.X, pos.Y, pos.Z))
end]]
        },
        {
            name = "Toggle Farming (All)",
            code = [[
State.Farming = not State.Farming
overlay.Visible = State.Farming
if State.Farming then 
    State.StartTime = tick() 
end]]
        },
        {
            name = "Start Farming (All)",
            code = [[
State.Farming = true
overlay.Visible = true
State.StartTime = tick()]]
        },
        {
            name = "Stop Farming (All)",
            code = [[
State.Farming = false
overlay.Visible = false]]
        }
    }
    
    for _, action in ipairs(quickActions) do
        CommandTab:AddButton({
            Title = action.name,
            Description = "Execute: " .. action.name,
            Callback = function()
                local code = action.code
                
                if type(code) == "function" then
                    code = code()
                    if not code then
                        Fluent:Notify({
                            Title = "Error",
                            Content = "Cannot execute - main account not found",
                            Duration = 3
                        })
                        return
                    end
                end
                
                local success = broadcastCommand("execute", {code = code}, "all")
                
                if success then
                    table.insert(commandHistory, 1, {
                        time = os.date("%H:%M:%S"),
                        type = "Quick Action",
                        content = action.name,
                        status = "✅ Sent"
                    })
                    if #commandHistory > maxHistory then
                        table.remove(commandHistory)
                    end
                    
                    Fluent:Notify({
                        Title = "Action Sent",
                        Content = action.name .. " → All Helpers",
                        Duration = 3
                    })
                end
            end
        })
    end
    
    local historyText = CommandTab:AddParagraph({
        Title = "📋 Command History",
        Content = "No commands sent yet"
    })
    
    CommandTab:AddButton({
        Title = "Refresh History",
        Description = "Update command history display",
        Callback = function()
            if #commandHistory == 0 then
                historyText:SetDesc("No commands sent yet")
            else
                local historyStr = ""
                for i = 1, math.min(5, #commandHistory) do
                    local cmd = commandHistory[i]
                    historyStr = historyStr .. string.format("[%s] %s: %s %s\n", 
                        cmd.time, cmd.type, cmd.content, cmd.status)
                end
                historyText:SetDesc(historyStr)
            end
        end
    })
    
    CommandTab:AddButton({
        Title = "Clear History",
        Description = "Clear command history",
        Callback = function()
            table.clear(commandHistory)
            historyText:SetDesc("History cleared")
            Fluent:Notify({
                Title = "Cleared",
                Content = "Command history cleared",
                Duration = 2
            })
        end
    })
    
    local commandStatus = CommandTab:AddParagraph({
        Title = "📡 Command System",
        Content = "Status: Active | Queue: 0"
    })
    
    CommandTab:AddButton({
        Title = "Check Queue Status",
        Description = "View command queue",
        Callback = function()
            local queueSize = getgenv().CommandQueue and #getgenv().CommandQueue or 0
            commandStatus:SetDesc(string.format("Status: Active | Queue: %d commands", queueSize))
            
            Fluent:Notify({
                Title = "Queue Status",
                Content = string.format("%d commands in queue", queueSize),
                Duration = 3
            })
        end
    })
    
    CommandTab:AddButton({
        Title = "Clear Command Queue",
        Description = "Remove all pending commands",
        Callback = function()
            if getgenv().CommandQueue then
                local oldSize = #getgenv().CommandQueue
                table.clear(getgenv().CommandQueue)
                commandStatus:SetDesc("Status: Active | Queue: 0 commands")
                
                Fluent:Notify({
                    Title = "Queue Cleared",
                    Content = string.format("Removed %d commands", oldSize),
                    Duration = 3
                })
            end
        end
    })
    
    print("✓ Command Center loaded for main account")
end

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

print("Automation Hub GUI loaded")

local MainConnection
MainConnection = Services.RunService.Heartbeat:Connect(function()
    local now = tick()
    
    if State.Farming then
        local elapsed = now - State.StartTime
        local kills = getKills()
        statusLabel.Text = string.format("Status: Farming\nKills: %d\nTime: %s", 
            kills, formatTime(elapsed))
        
        sendKillUpdate()
    end
    
    if State.KeyPress then
        handleKeyPress()
    end
    
    if State.FpsCap then
        updateFPS()
    end
    
    if State.AccountChecker and now - State.LastAccountCheck >= getgenv().checkInterval then
        pcall(checkAccounts)
    end
    
    if now - State.LastCommandCheck >= 2 then
        State.LastCommandCheck = now
        pcall(checkForCommands)
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

print("========================================")
print("Automation Hub Loaded Successfully")
print("========================================")
print("Account Type:", accountType)
print("Local Server URL:", getgenv().localServerURL or "Not set")
if isMainAccount then
    print("✓ Command Center: ENABLED (Main Account)")
    print("  - Send messages to helpers")
    print("  - Execute code on helpers")
    print("  - Quick action buttons")
else
    local isHelper = false
    for _, helper in ipairs(getgenv().mainhelpers) do
        if player.Name:lower() == helper:lower() then
            isHelper = true
            break
        end
    end
    if isHelper then
        print("✓ Command Receiver: ENABLED (Helper Account)")
        print("  - Listening for commands from main")
        print("  - Auto-executing received code")
    end
end
print("========================================")
print("Ready to use!")
