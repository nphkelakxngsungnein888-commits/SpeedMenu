local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Config = {
    LockEnabled = false,
    LockMode = "NPC",
    LockStrength = 0.3,
    LockRange = 100,
    CurrentTarget = nil,
    ScanEnabled = false,
    ScanMode = "NPC",
    FleeEnabled = false,
    FleeMode = "NPC",
    FleeRange = 20,
    MenuSize = 10,
    MenuOpen = true,
}

local function getDistance(a, b)
    return (a - b).Magnitude
end

local function getCharacterRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("RootPart")
end

local function getCharacterHumanoid(char)
    return char:FindFirstChildOfClass("Humanoid")
end

local function getNearestTarget(mode)
    local nearest, nearestDist = nil, math.huge
    local myPos = HumanoidRootPart.Position
    if mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local root = getCharacterRoot(p.Character)
                local hum = getCharacterHumanoid(p.Character)
                if root and hum and hum.Health > 0 then
                    local d = getDistance(myPos, root.Position)
                    if d < Config.LockRange and d < nearestDist then
                        nearest = p.Character
                        nearestDist = d
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character then
                local hum = getCharacterHumanoid(obj)
                local root = getCharacterRoot(obj)
                if hum and hum.Health > 0 and root and not Players:GetPlayerFromCharacter(obj) then
                    local d = getDistance(myPos, root.Position)
                    if d < Config.LockRange and d < nearestDist then
                        nearest = obj
                        nearestDist = d
                    end
                end
            end
        end
    end
    return nearest
end

local function getTargetUnderCrosshair(mode)
    local nearest, nearestDot = nil, -math.huge
    local camCF = Camera.CFrame
    local myPos = HumanoidRootPart.Position
    local function check(char)
        if char == Character then return end
        local root = getCharacterRoot(char)
        local hum = getCharacterHumanoid(char)
        if not root or not hum or hum.Health <= 0 then return end
        local d = getDistance(myPos, root.Position)
        if d > Config.LockRange then return end
        local dir = (root.Position - camCF.Position).Unit
        local dot = camCF.LookVector:Dot(dir)
        if dot > nearestDot then
            nearest = char
            nearestDot = dot
        end
    end
    if mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then check(p.Character) end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
                check(obj)
            end
        end
    end
    return nearest
end

-- Target Lock
RunService.RenderStepped:Connect(function()
    Character = LocalPlayer.Character
    if not Character then return end
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    Humanoid = Character:FindFirstChild("Humanoid")
    if not HumanoidRootPart or not Humanoid then return end
    if Config.LockEnabled then
        if Config.CurrentTarget then
            local hum = getCharacterHumanoid(Config.CurrentTarget)
            if not hum or hum.Health <= 0 then
                Config.CurrentTarget = getNearestTarget(Config.LockMode)
            end
        else
            Config.CurrentTarget = getTargetUnderCrosshair(Config.LockMode)
        end
        if Config.CurrentTarget then
            local root = getCharacterRoot(Config.CurrentTarget)
            if root then
                local targetPos = root.Position
                local currentCF = Camera.CFrame
                local direction = (targetPos - currentCF.Position).Unit
                local newCF = CFrame.new(currentCF.Position, currentCF.Position + direction)
                Camera.CFrame = currentCF:Lerp(newCF, Config.LockStrength)
            end
        end
    end
end)

Humanoid.HealthChanged:Connect(function()
    if not Config.LockEnabled then return end
    local attacker = getNearestTarget(Config.LockMode)
    if attacker then Config.CurrentTarget = attacker end
end)

-- Flee
RunService.Heartbeat:Connect(function()
    Character = LocalPlayer.Character
    if not Character then return end
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not HumanoidRootPart or not Humanoid then return end
    if not Config.FleeEnabled then return end
    local myPos = HumanoidRootPart.Position
    local fleeDir = Vector3.new(0,0,0)
    local found = false
    local function checkFlee(char)
        if char == Character then return end
        local root = getCharacterRoot(char)
        local hum = getCharacterHumanoid(char)
        if not root or not hum or hum.Health <= 0 then return end
        local d = getDistance(myPos, root.Position)
        if d < Config.FleeRange then
            local away = (myPos - root.Position)
            local speed = math.max(1, hum.WalkSpeed)
            local weight = (Config.FleeRange - d) / Config.FleeRange * speed
            fleeDir = fleeDir + away.Unit * weight
            found = true
        end
    end
    if Config.FleeMode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then checkFlee(p.Character) end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj ~= Character then
                checkFlee(obj)
            end
        end
    end
    if found and fleeDir.Magnitude > 0 then
        local flatDir = Vector3.new(fleeDir.X, 0, fleeDir.Z).Unit
        HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + flatDir)
        Humanoid:MoveTo(HumanoidRootPart.Position + flatDir * 5)
    end
end)

local scanBoxes = {}

local function clearScanBoxes()
    for _, v in pairs(scanBoxes) do v:Remove() end
    scanBoxes = {}
end

RunService.RenderStepped:Connect(function()
    if not Config.ScanEnabled then return end
    clearScanBoxes()
    Character = LocalPlayer.Character
    if not Character then return end
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    local function addBox(char)
        if char == Character then return end
        local root = getCharacterRoot(char)
        local hum = getCharacterHumanoid(char)
        if not root or not hum or hum.Health <= 0 then return end

        local bb = Instance.new("BillboardGui")
        bb.Adornee = root
        bb.Size = UDim2.new(0, 60, 0, 80)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = game.CoreGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Parent = bb

        local corners = {
            {pos=UDim2.new(0,0,0,0),size=UDim2.new(0.3,0,0,2)},
            {pos=UDim2.new(0,0,0,0),size=UDim2.new(0,2,0.3,0)},
            {pos=UDim2.new(0.7,0,0,0),size=UDim2.new(0.3,0,0,2)},
            {pos=UDim2.new(1,-2,0,0),size=UDim2.new(0,2,0.3,0)},
            {pos=UDim2.new(0,0,1,-2),size=UDim2.new(0.3,0,0,2)},
            {pos=UDim2.new(0,0,0.7,0),size=UDim2.new(0,2,0.3,0)},
            {pos=UDim2.new(0.7,0,1,-2),size=UDim2.new(0.3,0,0,2)},
            {pos=UDim2.new(1,-2,0.7,0),size=UDim2.new(0,2,0.3,0)},
        }
        for _, c in ipairs(corners) do
            local line = Instance.new("Frame")
            line.Position = c.pos
            line.Size = c.size
            line.BackgroundColor3 = Color3.fromRGB(255,220,50)
            line.BorderSizePixel = 0
            line.Parent = frame
        end

        local dist = math.floor(getDistance(HumanoidRootPart.Position, root.Position))
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,0,14)
        label.Position = UDim2.new(0,0,1,2)
        label.BackgroundTransparency = 1
        label.Text = dist.."m"
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.TextSize = 11
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        table.insert(scanBoxes, bb)
    end

    if Config.ScanMode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then addBox(p.Character) end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj ~= Character then
                addBox(obj)
            end
        end
    end
end)

-- ══════════════════════════════════════
-- GUI
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KuyKuyMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = game.CoreGui

local BASE = 10
local function scale(n) return math.floor(n * (Config.MenuSize / BASE)) end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, scale(220), 0, scale(320))
MainFrame.Position = UDim2.new(0, 20, 0, 60)
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, scale(8))
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(80,80,80)
Stroke.Thickness = 1

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, scale(28))
TitleBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, scale(8))

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -scale(90), 1, 0)
TitleLabel.Position = UDim2.new(0, scale(8), 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ KuyKuy Script"
TitleLabel.TextColor3 = Color3.fromRGB(220,220,220)
TitleLabel.TextSize = scale(11)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local SizeBox = Instance.new("TextBox")
SizeBox.Size = UDim2.new(0, scale(30), 0, scale(18))
SizeBox.Position = UDim2.new(1, -scale(82), 0.5, -scale(9))
SizeBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
SizeBox.BorderSizePixel = 0
SizeBox.Text = "10"
SizeBox.TextColor3 = Color3.fromRGB(200,200,200)
SizeBox.TextSize = scale(10)
SizeBox.Font = Enum.Font.Gotham
SizeBox.Parent = TitleBar
Instance.new("UICorner", SizeBox).CornerRadius = UDim.new(0, 4)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, scale(34), 0, scale(18))
ToggleBtn.Position = UDim2.new(1, -scale(48), 0.5, -scale(9))
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "▼"
ToggleBtn.TextColor3 = Color3.fromRGB(200,200,200)
ToggleBtn.TextSize = scale(10)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = TitleBar
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, scale(18), 0, scale(18))
CloseBtn.Position = UDim2.new(1, -scale(10), 0.5, -scale(9))
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = scale(9)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    clearScanBoxes()
end)

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, 0, 1, -scale(30))
ContentFrame.Position = UDim2.new(0, 0, 0, scale(30))
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, scale(480))
ContentFrame.Parent = MainFrame
local ListLayout = Instance.new("UIListLayout", ContentFrame)
ListLayout.Padding = UDim.new(0, scale(4))
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local Pad = Instance.new("UIPadding", ContentFrame)
Pad.PaddingTop = UDim.new(0, scale(6))
Pad.PaddingLeft = UDim.new(0, scale(6))
Pad.PaddingRight = UDim.new(0, scale(6))

local function makeSection(title)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, scale(16))
    lbl.BackgroundTransparency = 1
    lbl.Text = "── "..title.." ──"
    lbl.TextColor3 = Color3.fromRGB(140,140,140)
    lbl.TextSize = scale(9)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = ContentFrame
end

local function makeToggleRow(labelText, state, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, scale(24))
    row.BackgroundColor3 = Color3.fromRGB(25,25,25)
    row.BorderSizePixel = 0
    row.Parent = ContentFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, scale(5))
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -scale(50), 1, 0)
    lbl.Position = UDim2.new(0, scale(8), 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.TextSize = scale(10)
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, scale(42), 0, scale(16))
    btn.Position = UDim2.new(1, -scale(48), 0.5, -scale(8))
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = scale(9)
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, scale(4))
    local on = state
    local function refresh()
        btn.Text = on and "ON" or "OFF"
        btn.BackgroundColor3 = on and Color3.fromRGB(60,180,80) or Color3.fromRGB(60,60,60)
        btn.TextColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
    end
    refresh()
    btn.MouseButton1Click:Connect(function() on = not on refresh() callback(on) end)
end

local function makeModeRow(labelText, options, current, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, scale(24))
    row.BackgroundColor3 = Color3.fromRGB(25,25,25)
    row.BorderSizePixel = 0
    row.Parent = ContentFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, scale(5))
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, scale(8), 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160,160,160)
    lbl.TextSize = scale(9)
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local idx = 1
    for i, v in ipairs(options) do if v == current then idx = i end end
    local btns = {}
    for i, opt in ipairs(options) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, scale(38), 0, scale(16))
        b.Position = UDim2.new(0.48, (i-1)*scale(40), 0.5, -scale(8))
        b.BorderSizePixel = 0
        b.Text = opt
        b.TextSize = scale(9)
        b.Font = Enum.Font.GothamBold
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, scale(4))
        btns[i] = b
        local function refreshBtns()
            for j, bb in ipairs(btns) do
                bb.BackgroundColor3 = j==idx and Color3.fromRGB(200,200,200) or Color3.fromRGB(50,50,50)
                bb.TextColor3 = j==idx and Color3.fromRGB(20,20,20) or Color3.fromRGB(150,150,150)
            end
        end
        refreshBtns()
        b.MouseButton1Click:Connect(function() idx=i refreshBtns() callback(options[idx]) end)
    end
end

local function makeInputRow(labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, scale(24))
    row.BackgroundColor3 = Color3.fromRGB(25,25,25)
    row.BorderSizePixel = 0
    row.Parent = ContentFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, scale(5))
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Position = UDim2.new(0, scale(8), 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160,160,160)
    lbl.TextSize = scale(9)
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, scale(52), 0, scale(16))
    box.Position = UDim2.new(1, -scale(58), 0.5, -scale(8))
    box.BackgroundColor3 = Color3.fromRGB(40,40,40)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(220,220,220)
    box.TextSize = scale(10)
    box.Font = Enum.Font.Gotham
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, scale(4))
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then callback(v) end
    end)
end

-- Build Menu
makeSection("🎯 Target Lock")
makeToggleRow("Lock Target", false, function(v) Config.LockEnabled=v if not v then Config.CurrentTarget=nil end end)
makeModeRow("Mode", {"Player","NPC"}, Config.LockMode, function(v) Config.LockMode=v Config.CurrentTarget=nil end)
makeInputRow("Strength (0.1-1)", Config.LockStrength, function(v) Config.LockStrength=math.clamp(v,0.01,1) end)
makeInputRow("Range (studs)", Config.LockRange, function(v) Config.LockRange=v end)

makeSection("📡 Enemy Scan")
makeToggleRow("Show ESP", false, function(v) Config.ScanEnabled=v if not v then clearScanBoxes() end end)
makeModeRow("Mode", {"Player","NPC"}, Config.ScanMode, function(v) Config.ScanMode=v end)

makeSection("🏃 Flee System")
makeToggleRow("Auto Flee", false, function(v) Config.FleeEnabled=v end)
makeModeRow("Mode", {"Player","NPC"}, Config.FleeMode, function(v) Config.FleeMode=v end)
makeInputRow("Flee Range (studs)", Config.FleeRange, function(v) Config.FleeRange=math.max(1,v) end)

-- Draggable
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Toggle Menu
ToggleBtn.MouseButton1Click:Connect(function()
    Config.MenuOpen = not Config.MenuOpen
    ContentFrame.Visible = Config.MenuOpen
    MainFrame.Size = Config.MenuOpen and UDim2.new(0,scale(220),0,scale(320)) or UDim2.new(0,scale(220),0,scale(28))
    ToggleBtn.Text = Config.MenuOpen and "▼" or "▶"
end)

-- Resize
SizeBox.FocusLost:Connect(function()
    local v = tonumber(SizeBox.Text)
    if not v then return end
    Config.MenuSize = math.max(4, v)
    local function s(n) return math.floor(n*(Config.MenuSize/BASE)) end
    MainFrame.Size = UDim2.new(0,s(220),0,s(320))
    TitleBar.Size = UDim2.new(1,0,0,s(28))
    TitleLabel.TextSize = s(11)
    ToggleBtn.Size = UDim2.new(0,s(34),0,s(18))
    ToggleBtn.Position = UDim2.new(1,-s(48),0.5,-s(9))
    CloseBtn.Size = UDim2.new(0,s(18),0,s(18))
    SizeBox.Size = UDim2.new(0,s(30),0,s(18))
    SizeBox.Position = UDim2.new(1,-s(82),0.5,-s(9))
end)
