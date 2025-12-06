getgenv().mainaccount = getgenv().mainaccount or "YourMainUsername"
getgenv().mainhelpers = getgenv().mainhelpers or {"alt1", "alt2"}
getgenv().webhookURL = "https://discord.com/api/webhooks/1265355595582537809/rAYW0kkZl4MnKE6Q-TcHPvncwdXJDY39y6d9nYcy54JUlmN8BCJXgxKGKKk3lKj8hPPe"
getgenv().checkInterval = 60 -- Check every 60 seconds

loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()

-- Load Luna UI Library
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

local Window = Luna:CreateWindow({
	Name = "Automation Hub",
	Subtitle = "Advanced Farming System",
	LogoID = nil,
	LoadingEnabled = true,
	LoadingTitle = "Automation Hub",
	LoadingSubtitle = "Loading System...",
	ConfigSettings = {
		RootFolder = nil,
		ConfigFolder = "AutomationHub"
	},
	KeySystem = false
})

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local farmingEnabled = false
local autoClickEnabled = false
local keyPressEnabled = false
local fpsCapEnabled = false
local accountCheckerEnabled = false
local startTime = 0
local elapsedTime = 0

-- Create black screen overlay
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmingOverlay"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local blackScreen = Instance.new("Frame")
blackScreen.Size = UDim2.new(1, 0, 1, 0)
blackScreen.Position = UDim2.new(0, 0, 0, 0)
blackScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackScreen.BorderSizePixel = 0
blackScreen.Visible = false
blackScreen.Parent = screenGui

local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(0, 400, 0, 200)
statusContainer.Position = UDim2.new(0.5, -200, 0.5, -100)
statusContainer.BackgroundTransparency = 1
statusContainer.Parent = blackScreen

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 50)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status : Farming"
statusLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
statusLabel.TextSize = 32
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = statusContainer

local killsLabel = Instance.new("TextLabel")
killsLabel.Size = UDim2.new(1, 0, 0, 50)
killsLabel.Position = UDim2.new(0, 0, 0, 70)
killsLabel.BackgroundTransparency = 1
killsLabel.Text = "Kills : 0"
killsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
killsLabel.TextSize = 28
killsLabel.Font = Enum.Font.GothamBold
killsLabel.Parent = statusContainer

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, 0, 0, 50)
timeLabel.Position = UDim2.new(0, 0, 0, 140)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Time : 00:00:00"
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.TextSize = 28
timeLabel.Font = Enum.Font.GothamBold
timeLabel.Parent = statusContainer

-- Helper Functions
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function updateKills()
    local leaderstats = player:FindFirstChild("leaderstats")
    
    if leaderstats then
        local killStat = leaderstats:FindFirstChild("Kills") 
                      or leaderstats:FindFirstChild("kills")
                      or leaderstats:FindFirstChild("KOs")
                      or leaderstats:FindFirstChild("Eliminations")
        
        if killStat then
            killsLabel.Text = "Kills : " .. tostring(killStat.Value)
        else
            killsLabel.Text = "Kills : N/A"
        end
    else
        killsLabel.Text = "Kills : 0"
    end
end

local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
end

local function clickM1()
    local mouse = player:GetMouse()
    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0)
end

local function teleportToCoordinates(x, y, z)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
    end
end

local function isMainHelper()
    for _, helperName in ipairs(getgenv().mainhelpers) do
        if player.Name:lower() == helperName:lower() then
            return true
        end
    end
    return false
end

local function isMainAccount()
    return player.Name:lower() == getgenv().mainaccount:lower()
end

local function fpsCapLoop()
    while fpsCapEnabled do
        task.wait(0.5)
        if isMainAccount() then
            setfpscap(240)
        else
            setfpscap(3)
        end
    end
end

local function autoClickLoop()
    while autoClickEnabled do
        clickM1()
        task.wait(0.1)
    end
end

local function keyPressLoop()
    local keys = {"One", "Two", "Three", "Four", "G"}
    while keyPressEnabled do
        for _, key in ipairs(keys) do
            if not keyPressEnabled then break end
            pressKey(key)
            task.wait(0.1)
        end
    end
end

-- Account Checker Functions
function SendMessageEMBED(url, embed)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["footer"] = {
                    ["text"] = embed.footer.text
                },
                ["timestamp"] = embed.timestamp
            }
        }
    }
    local body = HttpService:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
    print("✓ Webhook sent successfully")
end

local function getAllMonitoredAccounts()
    local accounts = {}
    
    table.insert(accounts, {
        name = getgenv().mainaccount,
        type = "Main Account"
    })
    
    for _, helperName in ipairs(getgenv().mainhelpers) do
        table.insert(accounts, {
            name = helperName,
            type = "Helper Account"
        })
    end
    
    return accounts
end

local function isPlayerInServer(playerName)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == playerName:lower() then
            return true, plr
        end
    end
    return false, nil
end

local function getPlayerStats(plr)
    local stats = {
        kills = "N/A",
        level = "N/A",
        team = "N/A"
    }
    
    local leaderstats = plr:FindFirstChild("leaderstats")
    if leaderstats then
        local killStat = leaderstats:FindFirstChild("Kills") 
                      or leaderstats:FindFirstChild("kills")
                      or leaderstats:FindFirstChild("KOs")
                      or leaderstats:FindFirstChild("Eliminations")
        if killStat then
            stats.kills = tostring(killStat.Value)
        end
        
        local levelStat = leaderstats:FindFirstChild("Level")
                       or leaderstats:FindFirstChild("level")
        if levelStat then
            stats.level = tostring(levelStat.Value)
        end
    end
    
    if plr.Team then
        stats.team = plr.Team.Name
    end
    
    return stats
end

local function checkAccounts()
    local monitoredAccounts = getAllMonitoredAccounts()
    local connectedCount = 0
    local disconnectedCount = 0
    local accountLines = {}
    
    for _, account in ipairs(monitoredAccounts) do
        local isConnected, plr = isPlayerInServer(account.name)
        
        if isConnected then
            connectedCount = connectedCount + 1
            local stats = getPlayerStats(plr)
            
            local line = string.format(
                "🟢 **%s** (%s)\n├ Kills: %s | Level: %s\n└ Team: %s\n",
                account.name,
                account.type,
                stats.kills,
                stats.level,
                stats.team
            )
            table.insert(accountLines, line)
        else
            disconnectedCount = disconnectedCount + 1
            
            local line = string.format(
                "🔴 **%s** (%s)\n└ Status: Disconnected\n",
                account.name,
                account.type
            )
            table.insert(accountLines, line)
        end
    end
    
    local totalAccounts = #monitoredAccounts
    local serverName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    
    local description = string.format(
        "**Server:** %s\n**Total:** %d | **Connected:** 🟢 %d | **Disconnected:** 🔴 %d\n\n" ..
        "━━━━━━━━━━━━━━━━━━━━━━\n\n%s",
        serverName,
        totalAccounts,
        connectedCount,
        disconnectedCount,
        table.concat(accountLines, "\n")
    )
    
    local color = 65280
    if connectedCount == 0 then
        color = 16711680
    elseif disconnectedCount > 0 then
        color = 16776960
    end
    
    local embed = {
        ["title"] = "📊 Account Status Report",
        ["description"] = description,
        ["color"] = color,
        ["footer"] = {
            ["text"] = "Automation Hub • Account Checker"
        },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
    }
    
    SendMessageEMBED(getgenv().webhookURL, embed)
end

-- Create Home Tab
Window:CreateHomeTab({
	SupportedExecutors = {
		"Synapse X",
		"Wave",
		"Solara",
		"Executor"
	},
	DiscordInvite = nil,
	Icon = 1
})

-- Automation Tab
local AutomationTab = Window:CreateTab({
	Name = "Automation",
	Icon = "sports_esports",
	ImageSource = "Material",
	ShowTitle = true
})

AutomationTab:CreateSection("Farming Controls")

local FarmingToggle = AutomationTab:CreateToggle({
	Name = "Enable Farming Mode",
	Description = "Activates farming overlay and tracking",
	CurrentValue = false,
	Callback = function(Value)
		farmingEnabled = Value
		
		if farmingEnabled then
			blackScreen.Visible = true
			startTime = tick()
			elapsedTime = 0
			updateKills()
			Luna:Notification({
				Title = "Farming Started",
				Icon = "check_circle",
				ImageSource = "Material",
				Content = "Farming mode has been activated!"
			})
		else
			blackScreen.Visible = false
			Luna:Notification({
				Title = "Farming Stopped",
				Icon = "cancel",
				ImageSource = "Material",
				Content = "Farming mode has been deactivated."
			})
		end
	end
}, "FarmingToggle")

AutomationTab:CreateDivider()
AutomationTab:CreateSection("Automation Features")

local AutoClickToggle = AutomationTab:CreateToggle({
	Name = "Auto Click",
	Description = "Automatically clicks at intervals",
	CurrentValue = false,
	Callback = function(Value)
		autoClickEnabled = Value
		
		if autoClickEnabled then
			task.spawn(autoClickLoop)
		end
	end
}, "AutoClickToggle")

local KeyPressToggle = AutomationTab:CreateToggle({
	Name = "Auto Key Press",
	Description = "Automatically presses keys 1-4 and G",
	CurrentValue = false,
	Callback = function(Value)
		keyPressEnabled = Value
		
		if keyPressEnabled then
			task.spawn(keyPressLoop)
		end
	end
}, "KeyPressToggle")

local FPSCapToggle = AutomationTab:CreateToggle({
	Name = "FPS Cap Control",
	Description = "Manages FPS based on account type",
	CurrentValue = false,
	Callback = function(Value)
		if not isMainHelper() and not isMainAccount() then
			FPSCapToggle:Set(false)
			Luna:Notification({
				Title = "Access Denied",
				Icon = "block",
				ImageSource = "Material",
				Content = "FPS Cap is only available for main and helper accounts!"
			})
			return
		end
		
		fpsCapEnabled = Value
		
		if fpsCapEnabled then
			task.spawn(fpsCapLoop)
			Luna:Notification({
				Title = "FPS Cap Enabled",
				Icon = "speed",
				ImageSource = "Material",
				Content = "FPS cap control is now active."
			})
		else
			setfpscap(60)
		end
	end
}, "FPSCapToggle")

-- Account Checker Tab
local AccountCheckerTab = Window:CreateTab({
	Name = "Acc Checker",
	Icon = "group",
	ImageSource = "Material",
	ShowTitle = true
})

AccountCheckerTab:CreateSection("Account Monitoring")

local accountStatusLabel = AccountCheckerTab:CreateLabel({
	Text = "Account Checker: Disabled",
	Style = 2
})

local CheckerToggle = AccountCheckerTab:CreateToggle({
	Name = "Enable Account Checker",
	Description = "Monitor accounts and send Discord webhooks",
	CurrentValue = false,
	Callback = function(Value)
		accountCheckerEnabled = Value
		
		if accountCheckerEnabled then
			accountStatusLabel:Set("Account Checker: 🟢 Enabled")
			Luna:Notification({
				Title = "Account Checker Started",
				Icon = "check_circle",
				ImageSource = "Material",
				Content = "Now monitoring accounts!"
			})
			
			-- Send initial check
			task.spawn(function()
				task.wait(2)
				checkAccounts()
			end)
		else
			accountStatusLabel:Set("Account Checker: 🔴 Disabled")
			Luna:Notification({
				Title = "Account Checker Stopped",
				Icon = "cancel",
				ImageSource = "Material",
				Content = "Account monitoring disabled."
			})
		end
	end
}, "AccountCheckerToggle")

AccountCheckerTab:CreateDivider()
AccountCheckerTab:CreateSection("Manual Check")

local ManualCheckButton = AccountCheckerTab:CreateButton({
	Name = "Send Status Now",
	Description = "Manually send account status to Discord",
	Callback = function()
		checkAccounts()
		Luna:Notification({
			Title = "Status Sent",
			Icon = "send",
			ImageSource = "Material",
			Content = "Account status sent to Discord!"
		})
	end
})

AccountCheckerTab:CreateDivider()
AccountCheckerTab:CreateSection("Monitored Accounts")

AccountCheckerTab:CreateParagraph({
	Title = "Main Account",
	Text = "📌 " .. getgenv().mainaccount
})

local helperText = ""
for i, helper in ipairs(getgenv().mainhelpers) do
    helperText = helperText .. "• " .. helper
    if i < #getgenv().mainhelpers then
        helperText = helperText .. "\n"
    end
end

AccountCheckerTab:CreateParagraph({
	Title = "Helper Accounts (" .. #getgenv().mainhelpers .. ")",
	Text = helperText
})

AccountCheckerTab:CreateDivider()
AccountCheckerTab:CreateSection("Settings")

local WebhookInput = AccountCheckerTab:CreateInput({
	Name = "Discord Webhook URL",
	Description = "Enter your Discord webhook URL",
	PlaceholderText = "https://discord.com/api/webhooks/...",
	CurrentValue = getgenv().webhookURL,
	Numeric = false,
	MaxCharacters = nil,
	Enter = false,
	Callback = function(Text)
		getgenv().webhookURL = Text
		Luna:Notification({
			Title = "Webhook Updated",
			Icon = "check_circle",
			ImageSource = "Material",
			Content = "Discord webhook URL has been saved!"
		})
	end
}, "WebhookURL")

AccountCheckerTab:CreateParagraph({
	Title = "Check Interval",
	Text = "Currently set to: " .. getgenv().checkInterval .. " seconds"
})

-- Teleport Tab
local TeleportTab = Window:CreateTab({
	Name = "Teleport",
	Icon = "location_on",
	ImageSource = "Material",
	ShowTitle = true
})

TeleportTab:CreateSection("Coordinate Teleportation")

local currentX = "438.7"
local currentY = "441.8"
local currentZ = "-376.2"

local XCoordInput = TeleportTab:CreateInput({
	Name = "X Coordinate",
	Description = "Enter X position",
	PlaceholderText = "438.7",
	CurrentValue = "438.7",
	Numeric = true,
	MaxCharacters = nil,
	Enter = false,
	Callback = function(Text)
		currentX = Text
	end
}, "XCoord")

local YCoordInput = TeleportTab:CreateInput({
	Name = "Y Coordinate",
	Description = "Enter Y position",
	PlaceholderText = "441.8",
	CurrentValue = "441.8",
	Numeric = true,
	MaxCharacters = nil,
	Enter = false,
	Callback = function(Text)
		currentY = Text
	end
}, "YCoord")

local ZCoordInput = TeleportTab:CreateInput({
	Name = "Z Coordinate",
	Description = "Enter Z position",
	PlaceholderText = "-376.2",
	CurrentValue = "-376.2",
	Numeric = true,
	MaxCharacters = nil,
	Enter = false,
	Callback = function(Text)
		currentZ = Text
	end
}, "ZCoord")

local TeleportButton = TeleportTab:CreateButton({
	Name = "Teleport to Coordinates",
	Description = "Click to teleport to entered coordinates",
	Callback = function()
		local x = tonumber(currentX)
		local y = tonumber(currentY)
		local z = tonumber(currentZ)
		
		if x and y and z then
			teleportToCoordinates(x, y, z)
			Luna:Notification({
				Title = "Teleport Success",
				Icon = "check_circle",
				ImageSource = "Material",
				Content = string.format("Teleported to: %.1f, %.1f, %.1f", x, y, z)
			})
		else
			Luna:Notification({
				Title = "Teleport Failed",
				Icon = "error",
				ImageSource = "Material",
				Content = "Invalid coordinates! Please enter valid numbers."
			})
		end
	end
})

-- Settings Tab
local SettingsTab = Window:CreateTab({
	Name = "Settings",
	Icon = "settings",
	ImageSource = "Material",
	ShowTitle = true
})

SettingsTab:CreateSection("Account Information")

local accountType = isMainAccount() and "Main Account" or (isMainHelper() and "Helper Account" or "Regular Account")

SettingsTab:CreateLabel({
	Text = "Current User: " .. player.Name,
	Style = 2
})

SettingsTab:CreateLabel({
	Text = "Account Type: " .. accountType,
	Style = 2
})

SettingsTab:CreateDivider()
SettingsTab:CreateSection("Configuration")

SettingsTab:CreateParagraph({
	Title = "Main Account",
	Text = "Configured Main Account: " .. getgenv().mainaccount
})

local helpersList = table.concat(getgenv().mainhelpers, ", ")
if helpersList == "" then helpersList = "None configured" end

SettingsTab:CreateParagraph({
	Title = "Helper Accounts",
	Text = "Configured Helpers: " .. helpersList
})

SettingsTab:CreateLabel({
	Text = "To change accounts, edit the script configuration",
	Style = 3
})

-- Config Tab
local ConfigTab = Window:CreateTab({
	Name = "Config",
	Icon = "save",
	ImageSource = "Material",
	ShowTitle = true
})

ConfigTab:BuildConfigSection()

-- Background Update Loops
task.spawn(function()
    while true do
        task.wait(0.1)
        if farmingEnabled then
            elapsedTime = tick() - startTime
            timeLabel.Text = "Time : " .. formatTime(elapsedTime)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if farmingEnabled then
            updateKills()
        end
    end
end)

-- Account Checker Background Loop
task.spawn(function()
    while true do
        task.wait(getgenv().checkInterval)
        if accountCheckerEnabled then
            print("🔄 Running periodic account check...")
            checkAccounts()
        end
    end
end)

-- Monitor player joins/leaves for account checker
Players.PlayerAdded:Connect(function(plr)
    if not accountCheckerEnabled then return end
    
    task.wait(1)
    local isMonitored = false
    
    if plr.Name:lower() == getgenv().mainaccount:lower() then
        isMonitored = true
    end
    
    for _, helperName in ipairs(getgenv().mainhelpers) do
        if plr.Name:lower() == helperName:lower() then
            isMonitored = true
            break
        end
    end
    
    if isMonitored then
        print("✅ Monitored account joined:", plr.Name)
        checkAccounts()
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if not accountCheckerEnabled then return end
    
    local isMonitored = false
    
    if plr.Name:lower() == getgenv().mainaccount:lower() then
        isMonitored = true
    end
    
    for _, helperName in ipairs(getgenv().mainhelpers) do
        if plr.Name:lower() == helperName:lower() then
            isMonitored = true
            break
        end
    end
    
    if isMonitored then
        print("❌ Monitored account left:", plr.Name)
        task.wait(1)
        checkAccounts()
    end
end)

Luna:Notification({
	Title = "Automation Hub Loaded",
	Icon = "check_circle",
	ImageSource = "Material",
	Content = string.format("Welcome %s! System loaded successfully.", player.Name)
})

print("✓ Automation Hub loaded successfully!")
print("✓ User:", player.Name, "| Type:", accountType)
print("✓ Account Checker ready! Monitoring", 1 + #getgenv().mainhelpers, "account(s)")
