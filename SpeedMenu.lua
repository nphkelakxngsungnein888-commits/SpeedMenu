นี่คือสคริปเต็มๆ พร้อมใช้:
-- Advanced Combat Script by kuy kuy
-- Features: Target Lock, Enemy Scan, Flee System

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ══════════════════════════════════════
-- SETTINGS
-- ══════════════════════════════════════
local Config = {
    -- Target Lock
    LockEnabled = false,
    LockMode = "NPC", -- "Player" or "NPC"
    LockStrength = 0.3,
    LockRange = 100,
    CurrentTarget = nil,

    -- Scan
    ScanEnabled = false,
    ScanMode = "NPC", -- "Player" or "NPC"

    -- Flee
    FleeEnabled = false,
    FleeMode = "NPC",
    FleeRange = 20,

    -- UI
    MenuSize = 10,
    MenuOpen = true,
}

-- ══════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════
local function getDistance(a, b)
    return (a - b).Magnitude
end

local function isEnemy(character)
    if not character then return false end
    local player = Players:GetPlayerFromCharacter(character)
    if Config.LockMode == "Player" or Config.ScanMode == "Player" or Config.FleeMode == "Player" then
        if player and player ~= LocalPlayer then return true end
    end
    if Config.LockMode == "NPC" or Config.ScanMode == "NPC" or Config.FleeMode == "NPC" then
        if not player then
            local hum = character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then return true end
        end
    end
    return false
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

-- ══════════════════════════════════════
-- TARGET LOCK LOGIC
-- ══════════════════════════════════════
RunService.RenderStepped:Connect(function()
    Character = LocalPlayer.Character
    if not Character then return end
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    Humanoid = Character:FindFirstChild("Humanoid")
    if not HumanoidRootPart or not Humanoid then return end

    -- Lock Target
    if Config.LockEnabled then
        -- Check current target alive
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

-- Damage detection → auto lock attacker
Humanoid.HealthChanged:Connect(function(newHealth)
    if not Config.LockEnabled then return end
    -- Find nearest enemy when damaged
    local attacker = getNearestTarget(Config.LockMode)
    if attacker then
        Config.CurrentTarget = attacker
    end
end)

-- ══════════════════════════════════════
-- FLEE LOGIC
-- ══════════════════════════════════════
local fleeConnection
RunService.Heartbeat:Connect(function(dt)
    Character = LocalPlayer.Character
    if not Character then return end
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not HumanoidRootPart or not Humanoid then return end
    if not Config.FleeEnabled then return end

    local myPos = HumanoidRootPart.Position
    local fleeDir = Vector3.new(0, 0, 0)
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

-- ══════════════════════════════════════
-- SCAN (ESP) LOGIC
-- ══════════════════════════════════════
local scanBoxes = {}

local function clearScanBoxes()
    for _, v in pairs(scanBoxes) do v:Remove() end
    scanBoxes = {}
end

local function updateScan()
    clearScanBoxes()
    if not Config.ScanEnabled then return end

    local function addBox(char)
        if char == Character then return end
        local root = getCharacterRoot(char)
        local hum = getCharacterHumanoid(char)
        if not root or not hum or hum.Health <= 0 then return end

        -- BillboardGui
        local bb = Instance.new("BillboardGui")
        bb.Adornee = root
        bb.Size = UDim2.new(0, 60, 0, 80)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = game.CoreGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Parent = bb

        -- Box border
        local corners = {
            {pos = UDim2.new(0,0,0,0), size = UDim2.new(0.3,0,0,2)},
            {pos = UDim2.new(0,0,0,0), size = UDim2.new(0,2,0.3,0)},
            {pos = UDim2.new(0.7,0,0,0), size = UDim2.new(0.3,0,0,2)},
            {pos = UDim2.new(1,-2,0,0), size = UDim2.new(0,2,0.3,0)},
            {pos = UDim2.new(0,0,1,-2), size = UDim2.new(0.3,0,0,2)},
            {pos = UDim2.new(0,0,0.7,0), size = UDim2.new(0,2,0.3,0)},
            {pos = UDim2.new(0.7,0,1,-2), size = UDim2.new(0.3,0,0,2)},
            {pos = UDim2.new(1,-2,0.7,0), size = UDim2.new(0,2,0.3,0)},
        }
        for _, c in ipairs(corners) do
            local line = Instance.new("Frame")
            line.Position = c.pos
            line.Size = c.size
            line.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
            line.BorderSizePixel = 0
            line.Parent = frame
        end

        -- Distance label
        local dist = math.floor(getDistance(HumanoidRootPart.Position, root.Position))
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 14)
        label.Position = UDim2.new(0, 0, 1, 2)
        label.BackgroundTransparency = 1
        label.Text = dist .. "m"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
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
end

RunService.RenderStepped:Connect(function()
    if Config.ScanEnabled then updateScan() end
end)

-- ══════════════════════════════════════
-- GUI
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KuyKuyMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = game.CoreGui

-- Scale factor
local BASE = 10
local function scale(n) return math.floor(n * (Config.MenuSize / BASE)) end

-- ── Main Frame ──
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, scale(220), 0, scale(320))
MainFrame.Position = UDim2.new(0, 20, 0, 60)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, scale(8))

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(80, 80, 80)
Stroke.Thickness = 1

-- ── Title Bar ──
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, scale(28))
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, scale(8))

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -scale(90), 1, 0)
TitleLabel.Position = UDim2.new(0, scale(8), 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ KuyKuy Script"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
TitleLabel.TextSize = scale(11)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Size input
local SizeBox = Instance.new("TextBox")
SizeBox.Size = UDim2.new(0, scale(30), 0, scale(18))
SizeBox.Position = UDim2.new(1, -scale(82), 0.5, -scale(9))
SizeBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SizeBox.BorderSizePixel = 0
SizeBox.Text = tostring(Config.MenuSize)
SizeBox.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeBox.TextSize = scale(10)
SizeBox.Font = Enum.Font.Gotham
SizeBox.Parent = TitleBar
Instance.new("UICorner", SizeBox).CornerRadius = UDim.new(0, 4)

-- Toggle Menu Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, scale(34), 0, scale(18))
ToggleBtn.Position = UDim2.new(1, -scale(48), 0.5, -scale(9))
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "▼"
ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ToggleBtn.TextSize = scale(10)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = TitleBar
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, scale(18), 0, scale(18))
CloseBtn.Position = UDim2.new(1, -scale(10), 0.5, -scale(9))
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = scale(9)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    clearScanBoxes()
end)

-- ── Scroll Content ──
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, 0, 1, -scale(30))
ContentFrame.Position = UDim2.new(0, 0, 0, scale(30))
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, scale(480))
ContentFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout", ContentFrame)
ListLayout.Padding = UDim.new(0, scale(4))
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local Padding = Instance.new("UIPadding", ContentFrame)
Padding.PaddingTop = UDim.new(0, scale(6))
Padding.PaddingLeft = UDim.new(0, scale(6))
Padding.PaddingRight = UDim.new(0, scale(6))

-- ── Helper UI Functions ──
local function makeSection(title)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, scale(16))
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. title .. " ──"
    lbl.TextColor3 = Color3.fromRGB(140, 140, 140)
    lbl.TextSize = scale(9)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = ContentFrame
    return lbl
end

local function makeToggleRow(labelText, state, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, scale(24))
    row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    row.BorderSizePixel = 0
    row.Parent = ContentFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, scale(5))

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -scale(50), 1, 0)
    lbl.Position = UDim2.new(0, scale(8), 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
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
        if on then
            btn.Text = "ON"
            btn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.Text = "OFF"
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
    refresh()

    btn.MouseButton1Click:Connect(function()
        on = not on
        refresh()
        callback(on)
    end)
    return row
end

local function makeModeRow(labelText, options, current, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, scale(24))
    row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    row.BorderSizePixel = 0
    row.Parent = ContentFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, scale(5))

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, scale(8), 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160, 160, 160)
    lbl.TextSize = scale(9)
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local idx = 1
    for i, v in ipairs(options) do if v == current then idx = i end end

    local btns = {}
    local totalW = scale(38) * #options + scale(4) * (#options - 1)
    local startX = scale(8) + scale(8) + lbl.Size.X.Offset

    for i, opt in ipairs(options) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, scale(38), 0, scale(16))
        b.Position = UDim2.new(0.48, (i-1)*(scale(40)), 0.5, -scale(8))
        b.BorderSizePixel = 0
        b.Text = opt
        b.TextSize = scale(9)
        b.Font = Enum.Font.GothamBold
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, scale(4))
        btns[i] = b

        local function refreshBtns()
            for j, bb in ipairs(btns) do
                if j == idx then
                    bb.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                    bb.TextColor3 = Color3.fromRGB(20, 20, 20)
                else
                    bb.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    bb.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
        end
        refreshBtns()

        b.MouseButton1Click:Connect(function()
            idx = i
            refreshBtns()
            callback(options[idx])
        end)
    end
    return row
end

local function makeInputRow(labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, scale(24))
    row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    row.BorderSizePixel = 0
    row.Parent = ContentFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, scale(5))

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Position = UDim2.new(0, scale(8), 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(160, 160, 160)
    lbl.TextSize = scale(9)
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, scale(52), 0, scale(16))
    box.Position = UDim2.new(1, -scale(58), 0.5, -scale(8))
    box.Bac
