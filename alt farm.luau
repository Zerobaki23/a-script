getgenv().mainaccount = getgenv().mainaccount or "YourMainUsername"
getgenv().mainhelpers = getgenv().mainhelpers or {"alt1", "alt2"}

loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local farmingEnabled = false
local autoClickEnabled = false
local keyPressEnabled = false
local fpsCapEnabled = false
local startTime = 0
local elapsedTime = 0

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombinedAutomationGUI"
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

local farmButton = Instance.new("TextButton")
farmButton.Size = UDim2.new(0, 120, 0, 40)
farmButton.Position = UDim2.new(0, 20, 0, 20)
farmButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
farmButton.Text = "Farming OFF"
farmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
farmButton.TextSize = 16
farmButton.Font = Enum.Font.GothamBold
farmButton.Parent = screenGui

local farmCorner = Instance.new("UICorner")
farmCorner.CornerRadius = UDim.new(0, 8)
farmCorner.Parent = farmButton

local clickButton = Instance.new("TextButton")
clickButton.Size = UDim2.new(0, 120, 0, 40)
clickButton.Position = UDim2.new(0, 20, 0, 70)
clickButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
clickButton.Text = "Click OFF"
clickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
clickButton.TextSize = 16
clickButton.Font = Enum.Font.GothamBold
clickButton.Parent = screenGui

local clickCorner = Instance.new("UICorner")
clickCorner.CornerRadius = UDim.new(0, 8)
clickCorner.Parent = clickButton

local keyButton = Instance.new("TextButton")
keyButton.Size = UDim2.new(0, 120, 0, 40)
keyButton.Position = UDim2.new(0, 20, 0, 120)
keyButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
keyButton.Text = "Keys OFF"
keyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
keyButton.TextSize = 16
keyButton.Font = Enum.Font.GothamBold
keyButton.Parent = screenGui

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 8)
keyCorner.Parent = keyButton

local fpsButton = Instance.new("TextButton")
fpsButton.Size = UDim2.new(0, 120, 0, 40)
fpsButton.Position = UDim2.new(0, 150, 0, 20)
fpsButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
fpsButton.Text = "FPS Cap OFF"
fpsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fpsButton.TextSize = 16
fpsButton.Font = Enum.Font.GothamBold
fpsButton.Parent = screenGui

local fpsCorner = Instance.new("UICorner")
fpsCorner.CornerRadius = UDim.new(0, 8)
fpsCorner.Parent = fpsButton

local tpContainer = Instance.new("Frame")
tpContainer.Size = UDim2.new(0, 280, 0, 220)
tpContainer.Position = UDim2.new(0, 20, 0, 170)
tpContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tpContainer.BorderSizePixel = 0
tpContainer.Parent = screenGui

local tpContainerCorner = Instance.new("UICorner")
tpContainerCorner.CornerRadius = UDim.new(0, 10)
tpContainerCorner.Parent = tpContainer

local tpTitle = Instance.new("TextLabel")
tpTitle.Size = UDim2.new(1, 0, 0, 35)
tpTitle.Position = UDim2.new(0, 0, 0, 0)
tpTitle.BackgroundTransparency = 1
tpTitle.Text = "Teleport Coordinates"
tpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
tpTitle.TextSize = 18
tpTitle.Font = Enum.Font.GothamBold
tpTitle.Parent = tpContainer

local xLabel = Instance.new("TextLabel")
xLabel.Size = UDim2.new(0, 30, 0, 30)
xLabel.Position = UDim2.new(0, 10, 0, 45)
xLabel.BackgroundTransparency = 1
xLabel.Text = "X:"
xLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
xLabel.TextSize = 16
xLabel.Font = Enum.Font.GothamBold
xLabel.Parent = tpContainer

local xInput = Instance.new("TextBox")
xInput.Size = UDim2.new(0, 230, 0, 30)
xInput.Position = UDim2.new(0, 40, 0, 45)
xInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
xInput.Text = "438.7"
xInput.TextColor3 = Color3.fromRGB(255, 255, 255)
xInput.TextSize = 14
xInput.Font = Enum.Font.Gotham
xInput.PlaceholderText = "Enter X coordinate"
xInput.Parent = tpContainer

local xInputCorner = Instance.new("UICorner")
xInputCorner.CornerRadius = UDim.new(0, 5)
xInputCorner.Parent = xInput

local yLabel = Instance.new("TextLabel")
yLabel.Size = UDim2.new(0, 30, 0, 30)
yLabel.Position = UDim2.new(0, 10, 0, 85)
yLabel.BackgroundTransparency = 1
yLabel.Text = "Y:"
yLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
yLabel.TextSize = 16
yLabel.Font = Enum.Font.GothamBold
yLabel.Parent = tpContainer

local yInput = Instance.new("TextBox")
yInput.Size = UDim2.new(0, 230, 0, 30)
yInput.Position = UDim2.new(0, 40, 0, 85)
yInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
yInput.Text = "441.8"
yInput.TextColor3 = Color3.fromRGB(255, 255, 255)
yInput.TextSize = 14
yInput.Font = Enum.Font.Gotham
yInput.PlaceholderText = "Enter Y coordinate"
yInput.Parent = tpContainer

local yInputCorner = Instance.new("UICorner")
yInputCorner.CornerRadius = UDim.new(0, 5)
yInputCorner.Parent = yInput

local zLabel = Instance.new("TextLabel")
zLabel.Size = UDim2.new(0, 30, 0, 30)
zLabel.Position = UDim2.new(0, 10, 0, 125)
zLabel.BackgroundTransparency = 1
zLabel.Text = "Z:"
zLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
zLabel.TextSize = 16
zLabel.Font = Enum.Font.GothamBold
zLabel.Parent = tpContainer

local zInput = Instance.new("TextBox")
zInput.Size = UDim2.new(0, 230, 0, 30)
zInput.Position = UDim2.new(0, 40, 0, 125)
zInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
zInput.Text = "-376.2"
zInput.TextColor3 = Color3.fromRGB(255, 255, 255)
zInput.TextSize = 14
zInput.Font = Enum.Font.Gotham
zInput.PlaceholderText = "Enter Z coordinate"
zInput.Parent = tpContainer

local zInputCorner = Instance.new("UICorner")
zInputCorner.CornerRadius = UDim.new(0, 5)
zInputCorner.Parent = zInput

local tpButton = Instance.new("TextButton")
tpButton.Size = UDim2.new(0, 260, 0, 40)
tpButton.Position = UDim2.new(0, 10, 0, 170)
tpButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
tpButton.Text = "TELEPORT"
tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tpButton.TextSize = 16
tpButton.Font = Enum.Font.GothamBold
tpButton.Parent = tpContainer

local tpButtonCorner = Instance.new("UICorner")
tpButtonCorner.CornerRadius = UDim.new(0, 8)
tpButtonCorner.Parent = tpButton

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

farmButton.MouseButton1Click:Connect(function()
    farmingEnabled = not farmingEnabled
    
    if farmingEnabled then
        farmButton.Text = "Farming ON"
        farmButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        blackScreen.Visible = true
        startTime = tick()
        elapsedTime = 0
        updateKills()
    else
        farmButton.Text = "Farming OFF"
        farmButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        blackScreen.Visible = false
    end
end)

clickButton.MouseButton1Click:Connect(function()
    autoClickEnabled = not autoClickEnabled
    
    if autoClickEnabled then
        clickButton.Text = "Click ON"
        clickButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        task.spawn(autoClickLoop)
    else
        clickButton.Text = "Click OFF"
        clickButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

keyButton.MouseButton1Click:Connect(function()
    keyPressEnabled = not keyPressEnabled
    
    if keyPressEnabled then
        keyButton.Text = "Keys ON"
        keyButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        task.spawn(keyPressLoop)
    else
        keyButton.Text = "Keys OFF"
        keyButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    end
end)

fpsButton.MouseButton1Click:Connect(function()
    if not isMainHelper() and not isMainAccount() then
        fpsButton.Text = "Not Allowed!"
        fpsButton.BackgroundColor3 = Color3.fromRGB(255, 152, 0)
        task.wait(1)
        fpsButton.Text = "FPS Cap OFF"
        fpsButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        return
    end
    
    fpsCapEnabled = not fpsCapEnabled
    
    if fpsCapEnabled then
        fpsButton.Text = "FPS Cap ON"
        fpsButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
        task.spawn(fpsCapLoop)
    else
        fpsButton.Text = "FPS Cap OFF"
        fpsButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        setfpscap(60)
    end
end)

tpButton.MouseButton1Click:Connect(function()
    local x = tonumber(xInput.Text)
    local y = tonumber(yInput.Text)
    local z = tonumber(zInput.Text)
    
    if x and y and z then
        teleportToCoordinates(x, y, z)
        tpButton.Text = "TELEPORTED!"
        tpButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        task.wait(1)
        tpButton.Text = "TELEPORT"
        tpButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    else
        tpButton.Text = "INVALID COORDS!"
        tpButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
        task.wait(1)
        tpButton.Text = "TELEPORT"
        tpButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    end
end)
