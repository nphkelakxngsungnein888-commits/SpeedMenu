-- // Target Lock + ESP + Auto Evade System
-- // By: kuy kuy | Roblox Lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════
-- // SETTINGS
-- ═══════════════════════════════════════
local Settings = {
    TargetLock = {
        Enabled = false,
        Mode = "NPC",
        Strength = 0.15,
        Range = 100,
    },
    ESP = {
        Enabled = false,
        Mode = "NPC",
    },
    Evade = {
        Enabled = false,
        Mode = "NPC",
        Range = 20,
        Speed = 30,
    },
}

local CurrentTarget = nil

-- ═══════════════════════════════════════
-- // HELPER FUNCTIONS
-- ═══════════════════════════════════════
local function getCharacter(player)
    return player and player.Character
end

local function getRootPart(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(char)
    local hum = getHumanoid(char)
    return hum and hum.Health > 0
end

local function getDistance(a, b)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

local function getAllEnemies()
    local enemies = {}
    local myRoot = getRootPart(LocalPlayer.Character)
    if not myRoot then return enemies end

    if Settings.TargetLock.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                if char and isAlive(char) then
                    local root = getRootPart(char)
                    if root and getDistance(myRoot, root) <= Settings.TargetLock.Range then
                        table.insert(enemies, char)
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                local hum = getHumanoid(obj)
                local root = getRootPart(obj)
                if hum and hum.Health > 0 and root then
                    local isPlayer = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character == obj then isPlayer = true break end
                    end
                    if not isPlayer and getDistance(myRoot, root) <= Settings.TargetLock.Range then
                        table.insert(enemies, obj)
                    end
                end
            end
        end
    end
    return enemies
end

local function getNearestEnemy()
    local myRoot = getRootPart(LocalPlayer.Character)
    if not myRoot then return nil end
    local nearest, nearDist = nil, math.huge
    for _, char in ipairs(getAllEnemies()) do
        local root = getRootPart(char)
        if root then
            local d = getDistance(myRoot, root)
            if d < nearDist then nearest = char nearDist = d end
        end
    end
    return nearest
end

local function getLookedEnemy()
    local myRoot = getRootPart(LocalPlayer.Character)
    if not myRoot then return nil end
    local bestChar, bestDot = nil, -1
    local camCF = Camera.CFrame
    for _, char in ipairs(getAllEnemies()) do
        local root = getRootPart(char)
        if root then
            local dir = (root.Position - camCF.Position).Unit
            local dot = camCF.LookVector:Dot(dir)
            if dot > bestDot then bestChar = char bestDot = dot end
        end
    end
    return bestChar
end

-- ═══════════════════════════════════════
-- // DAMAGE DETECTION
-- ═══════════════════════════════════════
local function setupDamageDetection()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = getHumanoid(char)
    if not hum then return end
    hum.HealthChanged:Connect(function(newHealth)
        if newHealth < hum.MaxHealth then
            local attacker = getNearestEnemy()
            if attacker then CurrentTarget = attacker end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    setupDamageDetection()
end)
if LocalPlayer.Character then
    task.wait(0.5)
    setupDamageDetection()
end

-- ═══════════════════════════════════════
-- // TARGET LOCK LOGIC
-- ═══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not Settings.TargetLock.Enabled then return end
    if CurrentTarget then
        if not isAlive(CurrentTarget) then
            CurrentTarget = getNearestEnemy()
        end
    else
        CurrentTarget = getLookedEnemy()
    end
    if CurrentTarget then
        local root = getRootPart(CurrentTarget)
        local myRoot = getRootPart(LocalPlayer.Character)
        if root and myRoot then
            local targetCF = CFrame.new(myRoot.Position, root.Position)
            Camera.CFrame = Camera.CFrame:Lerp(
                targetCF + (Camera.CFrame.Position - myRoot.Position),
                Settings.TargetLock.Strength
            )
        end
    end
end)

-- ═══════════════════════════════════════
-- // ESP SYSTEM
-- ═══════════════════════════════════════
local ESPFolder = Instance.new("Folder", game.CoreGui)
ESPFolder.Name = "ESP_Folder"

local function clearESP()
    for _, v in ipairs(ESPFolder:GetChildren()) do v:Destroy() end
end

local espConnections = {}

local function updateESP()
    clearESP()
    for _, c in ipairs(espConnections) do c:Disconnect() end
    espConnections = {}
    if not Settings.ESP.Enabled then return end

    local function drawESP(char)
        local root = getRootPart(char)
        if not root then return end
        local billGui = Instance.new("BillboardGui")
        billGui.Adornee = root
        billGui.Size = UDim2.new(0, 60, 0, 60)
        billGui.StudsOffset = Vector3.new(0, 2, 0)
        billGui.AlwaysOnTop = true
        billGui.Parent = ESPFolder

        local frame = Instance.new("Frame", billGui)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0

        local box = Instance.new("Frame", frame)
        box.Size = UDim2.new(1, 0, 1, 0)
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 2
        box.BorderColor3 = Color3.fromRGB(255, 255, 255)

        local distLabel = Instance.new("TextLabel", billGui)
        distLabel.Size = UDim2.new(0, 80, 0, 16)
        distLabel.Position = UDim2.new(0.5, -40, -0.6, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
        distLabel.TextSize = 11
        distLabel.Font = Enum.Font.GothamBold
        distLabel.Text = "..."

        local conn = RunService.Heartbeat:Connect(function()
            local myRoot = getRootPart(LocalPlayer.Character)
            if not myRoot or not root or not root.Parent then
                billGui:Destroy()
                return
            end
            distLabel.Text = math.floor(getDistance(myRoot, root)) .. " st"
        end)
        table.insert(espConnections, conn)
    end

    if Settings.ESP.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then drawESP(p.Character) end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local hum = getHumanoid(obj)
                if hum and hum.Health > 0 then
                    local isPlayer = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character == obj then isPlayer = true break end
                    end
                    if not isPlayer then drawESP(obj) end
                end
            end
        end
    end
end

-- ═══════════════════════════════════════
-- // EVADE SYSTEM
-- ═══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not Settings.Evade.Enabled then return end
    local myChar = LocalPlayer.Character
    local myRoot = getRootPart(myChar)
    if not myRoot then return end
    local hum = getHumanoid(myChar)
    if not hum then return end

    local threats = {}

    local function addThreat(root)
        if getDistance(myRoot, root) < Settings.Evade.Range then
            table.insert(threats, root)
        end
    end

    if Settings.Evade.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local r = getRootPart(p.Character)
                if r then addThreat(r) end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local h = getHumanoid(obj)
                local r = getRootPart(obj)
                if h and h.Health > 0 and r then
                    local isP = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character == obj then isP = true break end
                    end
                    if not isP then addThreat(r) end
                end
            end
        end
    end

    if #threats == 0 then hum.WalkSpeed = 16 return end

    local evadeDir = Vector3.new(0, 0, 0)
    local avgThreatPos = Vector3.new(0, 0, 0)
    for _, threatRoot in ipairs(threats) do
        local away = myRoot.Position - threatRoot.Position
        away = Vector3.new(away.X, 0, away.Z)
        if away.Magnitude > 0 then evadeDir = evadeDir + away.Unit end
        avgThreatPos = avgThreatPos + threatRoot.Position
    end
    avgThreatPos = avgThreatPos / #threats

    if evadeDir.Magnitude > 0 then
        evadeDir = evadeDir.Unit
        hum.WalkSpeed = Settings.Evade.Speed
        myRoot.CFrame = CFrame.new(myRoot.Position,
            Vector3.new(avgThreatPos.X, myRoot.Position.Y, avgThreatPos.Z))
        myRoot.CFrame = myRoot.CFrame * CFrame.new(evadeDir * Settings.Evade.Speed * 0.01)
    end
end)

-- ═══════════════════════════════════════
-- // GUI SYSTEM
-- ═══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KuyMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

local menuSize = 10

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 300)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(70, 70, 70)
UIStroke.Thickness = 1

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ KuyLock"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Size Box
local SizeBox = Instance.new("TextBox", TitleBar)
SizeBox.Size = UDim2.new(0, 30, 0, 20)
SizeBox.Position = UDim2.new(1, -80, 0, 4)
SizeBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SizeBox.BorderSizePixel = 0
SizeBox.Text = "10"
SizeBox.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeBox.TextSize = 11
SizeBox.Font = Enum.Font.Gotham
SizeBox.ClearTextOnFocus = false
Instance.new("UICorner", SizeBox).CornerRadius = UDim.new(0, 4)

SizeBox.FocusLost:Connect(function()
    local val = tonumber(SizeBox.Text)
    if val then
        val = math.max(1, val)
        menuSize = val
        local scale = val / 10
        MainFrame.Size = UDim2.new(0, 200 * scale, 0, 300 * scale)
    end
end)

-- Toggle Button
local ToggleBtn = Instance.new("TextButton", TitleBar)
ToggleBtn.Size = UDim2.new(0, 36, 0, 20)
ToggleBtn.Position = UDim2.new(1, -42, 0, 4)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "━"
ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ToggleBtn.TextSize = 12
ToggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

-- Close Button
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 22, 0, 20)
CloseBtn.Position = UDim2.new(1, -16, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 11
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    clearESP()
end)

-- Content Frame
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, 0, 1, -28)
ContentFrame.Position = UDim2.new(0, 0, 0, 28)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Parent = MainFrame

local UIPadding = Instance.new("UIPadding", ContentFrame)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)
UIPadding.PaddingTop = UDim.new(0, 6)

local UIListLayout = Instance.new("UIListLayout", ContentFrame)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

-- ═══════════════════════════════
-- // UI BUILDERS
-- ═══════════════════════════════
local function makeSection(title)
    local lbl = Instance.new("TextLabel", ContentFrame)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. title
    lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeToggle(label, callback)
    local row = Instance.new("Frame", ContentFrame)
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -48, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = false
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 38, 0, 16)
    btn.Position = UDim2.new(1, -44, 0.5, -8)
    btn.BorderSizePixel = 0
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local function refresh()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            btn.Text = "OFF"
        end
    end
    refresh()

    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        callback(state)
    end)
end

local function makeModeSelector(options, default, callback)
    local row = Instance.new("Frame", ContentFrame)
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)

    local current = default
    local buttons = {}

    local function refreshBtns()
        for _, data in ipairs(buttons) do
            if data.value == current then
                data.btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                data.btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            else
                data.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                data.btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end

    for _, opt in ipairs(options) do
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.BorderSizePixel = 0
        btn.Text = opt
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        table.insert(buttons, {btn = btn, value = opt})
        btn.MouseButton1Click:Connect(function()
            current = opt
            refreshBtns()
            callback(opt)
        end)
    end
    refreshBtns()
end

local function makeInput(label, default, callback)
    local row = Instance.new("Frame", ContentFrame)
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.38, 0, 0, 18)
    box.Position = UDim2.new(0.58, 0, 0.5, -9)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(220, 220, 220)
    box.TextSize = 10
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then callback(val) end
    end)
end

-- ═══════════════════════════════
-- // BUILD MENU
-- ═══════════════════════════════
makeSection("TARGET LOCK")
makeToggle("Lock Target", function(v)
    Settings.TargetLock.Enabled = v
    if v then CurrentTarget = getLookedEnemy() else CurrentTarget = nil end
end)
makeModeSelector({"Player","NPC"}, "NPC", function(v)
    Settings.TargetLock.Mode = v
    CurrentTarget = nil
end)
makeInput("Strength", 0.15, function(v)
    Settings.TargetLock.Strength = math.clamp(v, 0.01, 1)
end)
makeInput("Range (st)", 100, function(v)
    Settings.TargetLock.Range = v
end)
makeToggle("Next Target", function(v)
    if v then CurrentTarget = getNearestEnemy() end
end)

makeSection("ESP SCAN")
makeToggle("Show ESP", function(v)
    Settings.ESP.Enabled = v
    updateESP()
    if v then
        task.spawn(function()
            while Settings.ESP.Enabled do
                updateESP()
                task.wait(3)
            end
        end)
    end
end)
makeModeSelector({"Player","NPC"}, "NPC", function(v)
    Settings.ESP.Mode = v
    updateESP()
end)

makeSection("AUTO EVADE")
makeToggle("Evade Enable", function(v)
    Settings.Evade.Enabled = v
    if not v then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum then hum.WalkSpeed = 16 end
    end
end)
makeModeSelector({"Player","NPC"}, "NPC", function(v)
    Settings.Evade.Mode = v
end)
makeInput("Evade Range", 20, function(v) Settings.Evade.Range = v end)
makeInput("Evade Speed", 30, function(v) Settings.Evade.Speed = v end)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- ═══════════════════════════════
-- // DRAG
-- ═══════════════════════════════
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ═══════════════════════════════
-- // FOLD
-- ═══════════════════════════════
local folded = false
ToggleBtn.MouseButton1Click:Connect(function()
    folded = not folded
    ContentFrame.Visible = not folded
    if folded then
        MainFrame.Size = UDim2.new(MainFrame.Size.X.Scale, MainFrame.Size.X.Offset, 0, 28)
        ToggleBtn.Text = "▲"
    else
        local scale = menuSize / 10
        MainFrame.Size = UDim2.new(0, 200 * scale, 0, 300 * scale)
        ToggleBtn.Text = "━"
    end
end)
