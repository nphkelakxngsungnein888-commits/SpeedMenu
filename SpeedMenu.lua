-- Advanced Combat Script by kuy kuy v2
-- Target Lock | Enemy Scan | Auto Evade | Auto Lock Attacker

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Config = {
    LockEnabled = false,
    LockMode = "NPC",
    LockStrength = 0.15,
    LockRange = 100,
    CurrentTarget = nil,
    ScanEnabled = false,
    ScanMode = "NPC",
    EvadeEnabled = false,
    EvadeMode = "NPC",
    EvadeRange = 20,
    EvadeSpeed = 50,
    MenuOpen = true,
    MenuScale = 10,
}

-- ===================== GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CombatMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(0, 280, 0, 32)
TopBar.Position = UDim2.new(0, 60, 0, 60)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TopBar.BorderSizePixel = 0
TopBar.Parent = ScreenGui
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -150, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ Combat v2"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local ScaleLabel = Instance.new("TextLabel")
ScaleLabel.Size = UDim2.new(0, 30, 1, 0)
ScaleLabel.Position = UDim2.new(1, -138, 0, 0)
ScaleLabel.BackgroundTransparency = 1
ScaleLabel.Text = "Sz:"
ScaleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ScaleLabel.TextSize = 11
ScaleLabel.Font = Enum.Font.Gotham
ScaleLabel.Parent = TopBar

local ScaleBox = Instance.new("TextBox")
ScaleBox.Size = UDim2.new(0, 36, 0, 20)
ScaleBox.Position = UDim2.new(1, -108, 0.5, -10)
ScaleBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ScaleBox.BorderSizePixel = 0
ScaleBox.Text = "10"
ScaleBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ScaleBox.TextSize = 11
ScaleBox.Font = Enum.Font.Gotham
ScaleBox.Parent = TopBar
Instance.new("UICorner", ScaleBox).CornerRadius = UDim.new(0, 4)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 58, 0, 22)
ToggleBtn.Position = UDim2.new(1, -66, 0.5, -11)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "▼ Hide"
ToggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
ToggleBtn.TextSize = 11
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = TopBar
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

local MenuFrame = Instance.new("Frame")
MenuFrame.Name = "MenuFrame"
MenuFrame.Size = UDim2.new(0, 280, 0, 310)
MenuFrame.Position = UDim2.new(0, 60, 0, 94)
MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MenuFrame.BorderSizePixel = 0
MenuFrame.Parent = ScreenGui
Instance.new("UICorner", MenuFrame).CornerRadius = UDim.new(0, 8)

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color = Color3.fromRGB(70, 70, 70)
MenuStroke.Thickness = 1
MenuStroke.Parent = MenuFrame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MenuFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = ScrollFrame

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 8)
Padding.PaddingLeft = UDim.new(0, 8)
Padding.PaddingRight = UDim.new(0, 8)
Padding.Parent = ScrollFrame

local function MakeSection(title)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. title .. " ──"
    lbl.TextColor3 = Color3.fromRGB(140, 140, 140)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = ScrollFrame
    return lbl
end

local function MakeToggle(labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    row.BorderSizePixel = 0
    row.Parent = ScrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -46, 0.5, -10)
    btn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(80, 80, 80)
    btn.BorderSizePixel = 0
    btn.Text = state and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(80, 80, 80)
        }):Play()
        callback(state)
    end)
    return btn
end

local function MakeModeSelector(labelText, opt1, opt2, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    row.BorderSizePixel = 0
    row.Parent = ScrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 80, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local current = default
    local function makeBtn(txt, xPos)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 72, 0, 20)
        b.Position = UDim2.new(1, xPos, 0.5, -10)
        b.BackgroundColor3 = (txt == current) and Color3.fromRGB(200,200,200) or Color3.fromRGB(55,55,55)
        b.BorderSizePixel = 0
        b.Text = txt
        b.TextColor3 = (txt == current) and Color3.fromRGB(0,0,0) or Color3.fromRGB(200,200,200)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        return b
    end

    local b1 = makeBtn(opt1, -150)
    local b2 = makeBtn(opt2, -74)

    local function update(sel)
        current = sel
        b1.BackgroundColor3 = (sel==opt1) and Color3.fromRGB(200,200,200) or Color3.fromRGB(55,55,55)
        b1.TextColor3 = (sel==opt1) and Color3.fromRGB(0,0,0) or Color3.fromRGB(200,200,200)
        b2.BackgroundColor3 = (sel==opt2) and Color3.fromRGB(200,200,200) or Color3.fromRGB(55,55,55)
        b2.TextColor3 = (sel==opt2) and Color3.fromRGB(0,0,0) or Color3.fromRGB(200,200,200)
        callback(sel)
    end
    b1.MouseButton1Click:Connect(function() update(opt1) end)
    b2.MouseButton1Click:Connect(function() update(opt2) end)
end

local function MakeSliderBox(labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    row.BorderSizePixel = 0
    row.Parent = ScrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 58, 0, 20)
    box.Position = UDim2.new(1, -64, 0.5, -10)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then callback(val)
        else box.Text = tostring(default) end
    end)
end

-- ===================== MENU ITEMS =====================
MakeSection("🎯 TARGET LOCK")
MakeToggle("Lock Target", false, function(v)
    Config.LockEnabled = v
    if not v then Config.CurrentTarget = nil end
end)
MakeModeSelector("Mode:", "Player", "NPC", "NPC", function(v)
    Config.LockMode = v
    Config.CurrentTarget = nil
end)
MakeSliderBox("Strength (0.01-1)", Config.LockStrength, function(v)
    Config.LockStrength = math.clamp(v, 0.01, 1)
end)
MakeSliderBox("Range (studs)", Config.LockRange, function(v)
    Config.LockRange = v
end)

MakeSection("👁 ENEMY SCAN")
MakeToggle("Show Scan", false, function(v)
    Config.ScanEnabled = v
end)
MakeModeSelector("Mode:", "Player", "NPC", "NPC", function(v)
    Config.ScanMode = v
end)

MakeSection("🏃 AUTO EVADE")
MakeToggle("Auto Evade", false, function(v)
    Config.EvadeEnabled = v
end)
MakeModeSelector("Mode:", "Player", "NPC", "NPC", function(v)
    Config.EvadeMode = v
end)
MakeSliderBox("Evade Range", Config.EvadeRange, function(v)
    Config.EvadeRange = v
end)
MakeSliderBox("Evade Speed", Config.EvadeSpeed, function(v)
    Config.EvadeSpeed = v
end)

-- ===================== DRAG =====================
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = TopBar.Position
    end
end)
TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        TopBar.Position = newPos
        MenuFrame.Position = UDim2.new(
            newPos.X.Scale, newPos.X.Offset,
            newPos.Y.Scale, newPos.Y.Offset + 34
        )
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    Config.MenuOpen = not Config.MenuOpen
    MenuFrame.Visible = Config.MenuOpen
    ToggleBtn.Text = Config.MenuOpen and "▼ Hide" or "▶ Show"
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

ScaleBox.FocusLost:Connect(function()
    local v = tonumber(ScaleBox.Text)
    if v then
        Config.MenuScale = math.max(1, v)
        local s = Config.MenuScale / 10
        TopBar.Size = UDim2.new(0, 280 * s, 0, 32 * s)
        MenuFrame.Size = UDim2.new(0, 280 * s, 0, 310 * s)
        MenuFrame.Position = UDim2.new(
            TopBar.Position.X.Scale, TopBar.Position.X.Offset,
            TopBar.Position.Y.Scale, TopBar.Position.Y.Offset + 34 * s
        )
    else
        ScaleBox.Text = tostring(Config.MenuScale)
    end
end)

-- ===================== HELPERS =====================
local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(char)
    local h = getHumanoid(char)
    return h and h.Health > 0
end

local function isSameTeam(player)
    if not player or not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function distanceTo(hrp)
    if not hrp or not HumanoidRootPart then return math.huge end
    return (HumanoidRootPart.Position - hrp.Position).Magnitude
end

local function getTargets(mode, rangeOverride)
    local range = rangeOverride or Config.LockRange
    local list = {}
    if mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c = p.Character
                if c and isAlive(c) then
                    local hrp = getHRP(c)
                    if hrp and distanceTo(hrp) <= range and not isSameTeam(p) then
                        table.insert(list, {char=c, hrp=hrp, player=p})
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 then
                local c = obj.Parent
                if c ~= Character then
                    local hrp = getHRP(c)
                    if hrp and distanceTo(hrp) <= range then
                        table.insert(list, {char=c, hrp=hrp, player=nil})
                    end
                end
            end
        end
    end
    return list
end

local function getNearestTarget(mode)
    local targets = getTargets(mode)
    local best, bestDist = nil, math.huge
    for _, t in ipairs(targets) do
        local d = distanceTo(t.hrp)
        if d < bestDist then bestDist = d; best = t end
    end
    return best
end

local function getLookedAtTarget(mode)
    local targets = getTargets(mode)
    local best, bestDot = nil, 0.7
    local camCF = Camera.CFrame
    for _, t in ipairs(targets) do
        local dir = (t.hrp.Position - camCF.Position).Unit
        local dot = camCF.LookVector:Dot(dir)
        if dot > bestDot then bestDot = dot; best = t end
    end
    return best
end

-- ===================== HIGHLIGHT =====================
local lastHighlight = nil
local function setHighlight(hrp)
    if lastHighlight then
        pcall(function() lastHighlight:Destroy() end)
        lastHighlight = nil
    end
    if not hrp then return end
    local h = Instance.new("SelectionBox")
    h.Color3 = Color3.fromRGB(255, 60, 60)
    h.LineThickness = 0.05
    h.SurfaceTransparency = 0.8
    h.SurfaceColor3 = Color3.fromRGB(255, 60, 60)
    h.Adornee = hrp.Parent
    h.Parent = workspace
    lastHighlight = h
end

-- ===================== AUTO LOCK ATTACKER =====================
-- ล็อคตัวที่โจมตีเราทันที ไม่สนว่ากำลังล็อคอะไรอยู่
local lastHealth = Humanoid.Health

local function findAttacker()
    -- หา target ที่ใกล้ที่สุดในระยะ 60 studs (มักจะเป็นคนที่ตีเรา)
    local best, bestDist = nil, math.huge
    local searchMode = Config.LockMode

    if searchMode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c = p.Character
                if c and isAlive(c) then
                    local hrp = getHRP(c)
                    if hrp then
                        local d = distanceTo(hrp)
                        if d < bestDist and d <= 60 then
                            bestDist = d; best = {char=c, hrp=hrp, player=p}
                        end
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 then
                local c = obj.Parent
                if c ~= Character then
                    local hrp = getHRP(c)
                    if hrp then
                        local d = distanceTo(hrp)
                        if d < bestDist and d <= 60 then
                            bestDist = d; best = {char=c, hrp=hrp, player=nil}
                        end
                    end
                end
            end
        end
    end
    return best
end

Humanoid.HealthChanged:Connect(function(hp)
    if hp < lastHealth then
        -- โดนโจมตี → ล็อคตัวที่ใกล้ที่สุดทันที
        if Config.LockEnabled then
            local attacker = findAttacker()
            if attacker then
                Config.CurrentTarget = attacker
                setHighlight(attacker.hrp)
            end
        end
    end
    lastHealth = hp
end)

-- ===================== SCAN (Optimized Pool) =====================
-- ใช้ pool ลด instance create/destroy ทุก frame
local scanPool = {}     -- { bb, frame, dlbl, used }
local activeScan = {}   -- bb ที่กำลังใช้อยู่

local function getScanBillboard()
    for _, item in ipairs(scanPool) do
        if not item.used then
            item.used = true
            item.bb.Enabled = true
            return item
        end
    end
    -- สร้างใหม่เมื่อ pool หมด
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 60, 0, 60)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = workspace

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = bb
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local dlbl = Instance.new("TextLabel")
    dlbl.Size = UDim2.new(1, 0, 0, 14)
    dlbl.Position = UDim2.new(0, 0, -0.4, 0)
    dlbl.BackgroundTransparency = 1
    dlbl.TextColor3 = Color3.fromRGB(255, 220, 60)
    dlbl.TextSize = 11
    dlbl.Font = Enum.Font.GothamBold
    dlbl.Parent = bb

    local item = {bb=bb, dlbl=dlbl, used=true}
    table.insert(scanPool, item)
    return item
end

local function releaseScanPool()
    for _, item in ipairs(scanPool) do
        item.used = false
        item.bb.Adornee = nil
        item.bb.Enabled = false
    end
end

local function updateScan()
    releaseScanPool()
    if not Config.ScanEnabled then return end

    local targets = getTargets(Config.ScanMode, 200)
    for _, t in ipairs(targets) do
        local dist = math.floor(distanceTo(t.hrp))
        local item = getScanBillboard()
        item.bb.Adornee = t.hrp
        item.bb.Enabled = true
        item.dlbl.Text = dist .. "m"
        -- เปลี่ยนสีตามระยะ
        if dist <= 30 then
            item.dlbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        elseif dist <= 60 then
            item.dlbl.TextColor3 = Color3.fromRGB(255, 200, 60)
        else
            item.dlbl.TextColor3 = Color3.fromRGB(100, 220, 100)
        end
    end
end

-- =======
