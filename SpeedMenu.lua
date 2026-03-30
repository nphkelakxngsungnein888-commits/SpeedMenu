--โอเค แก้ทั้งหมดเลย:
--สิ่งที่แก้/เพิ่ม:
--ลด lag NPC lock (throttle scan ทุก 0.5s แทน Heartbeat ทุก frame)
--ปุ่ม Nearest Lock — ล็อคใกล้สุดตลอดเวลา
--เมนู Scan แยกหน้าต่างเล็ก ลากได้ ปรับขนาดได้
--แสดงชื่อ NPC/Player ตามระยะ กดเลือกล็อคได้
--แยกสีทีม (Team color) ถ้า game มี team
-- Lock Menu | NPC/Player | Nearest + Scan | Team Color
-- Fixed lag, Scan menu, Mobile friendly

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local lastHealth = Humanoid.Health

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
    Humanoid = c:WaitForChild("Humanoid")
    lastHealth = Humanoid.Health
end)

local Settings = {
    MenuSize = 10,
    ScanMenuSize = 10,
    LockStrength = 0.3,
    LockRange = 100,
    Mode = "NPC",
    Enabled = false,
    NearestMode = false,
}

local currentTarget = nil
local targetList = {}
local targetIndex = 1
local lockConnection = nil
local damageCheckConnection = nil
local scanThrottle = 0
local SCAN_INTERVAL = 0.5

pcall(function()
    if CoreGui:FindFirstChild("LockMenu") then CoreGui:FindFirstChild("LockMenu"):Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local function S(n) return n * (Settings.MenuSize / 10) end
local function SS(n) return n * (Settings.ScanMenuSize / 10) end

-- ══════════════════════════════
--         MAIN FRAME
-- ══════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, S(220), 0, S(330))
MainFrame.Position = UDim2.new(0.5, -S(110), 0.5, -S(165))
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,8)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, S(30))
TitleBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -S(70), 1, 0)
TitleLabel.Position = UDim2.new(0, S(8), 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ Lock Menu"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextSize = S(13)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, S(22), 0, S(22))
MinBtn.Position = UDim2.new(1, -S(46), 0.5, -S(11))
MinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.TextSize = S(14)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, S(22), 0, S(22))
CloseBtn.Position = UDim2.new(1, -S(22), 0.5, -S(11))
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = S(12)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,4)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -S(30))
Content.Position = UDim2.new(0, 0, 0, S(30))
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- helpers
local function Divider(parent, yPos, scale)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -(scale or S(16)), 0, 1)
    d.Position = UDim2.new(0, (scale or S(16))/2, 0, yPos)
    d.BackgroundColor3 = Color3.fromRGB(50,50,50)
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function Label(parent, text, y, size, fn)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -(fn or S)(16), 0, (fn or S)(18))
    l.Position = UDim2.new(0, (fn or S)(8), 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(180,180,180)
    l.TextSize = size or (fn or S)(11)
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function InputBox(parent, placeholder, default, y, w, x, fn)
    local box = Instance.new("TextBox")
    local f = fn or S
    box.Size = UDim2.new(0, f(w or 80), 0, f(24))
    box.Position = UDim2.new(0, f(x or 8), 0, y)
    box.BackgroundColor3 = Color3.fromRGB(30,30,30)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.PlaceholderColor3 = Color3.fromRGB(100,100,100)
    box.TextSize = f(11)
    box.Font = Enum.Font.Gotham
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)
    return box
end

-- MODE
Label(Content, "🎯 MODE", S(6), S(11))

local ModePlayer = Instance.new("TextButton")
ModePlayer.Size = UDim2.new(0, S(96), 0, S(26))
ModePlayer.Position = UDim2.new(0, S(8), 0, S(26))
ModePlayer.BackgroundColor3 = Color3.fromRGB(40,40,40)
ModePlayer.BorderSizePixel = 0
ModePlayer.Text = "👤 Player"
ModePlayer.TextColor3 = Color3.fromRGB(180,180,180)
ModePlayer.TextSize = S(11)
ModePlayer.Font = Enum.Font.GothamBold
ModePlayer.Parent = Content
Instance.new("UICorner", ModePlayer).CornerRadius = UDim.new(0,6)

local ModeNPC = Instance.new("TextButton")
ModeNPC.Size = UDim2.new(0, S(96), 0, S(26))
ModeNPC.Position = UDim2.new(0, S(112), 0, S(26))
ModeNPC.BackgroundColor3 = Color3.fromRGB(200,200,200)
ModeNPC.BorderSizePixel = 0
ModeNPC.Text = "🤖 NPC"
ModeNPC.TextColor3 = Color3.fromRGB(20,20,20)
ModeNPC.TextSize = S(11)
ModeNPC.Font = Enum.Font.GothamBold
ModeNPC.Parent = Content
Instance.new("UICorner", ModeNPC).CornerRadius = UDim.new(0,6)

local function UpdateModeUI()
    if Settings.Mode == "Player" then
        ModePlayer.BackgroundColor3 = Color3.fromRGB(200,200,200)
        ModePlayer.TextColor3 = Color3.fromRGB(20,20,20)
        ModeNPC.BackgroundColor3 = Color3.fromRGB(40,40,40)
        ModeNPC.TextColor3 = Color3.fromRGB(180,180,180)
    else
        ModeNPC.BackgroundColor3 = Color3.fromRGB(200,200,200)
        ModeNPC.TextColor3 = Color3.fromRGB(20,20,20)
        ModePlayer.BackgroundColor3 = Color3.fromRGB(40,40,40)
        ModePlayer.TextColor3 = Color3.fromRGB(180,180,180)
    end
end
UpdateModeUI()

ModePlayer.MouseButton1Click:Connect(function()
    Settings.Mode = "Player" currentTarget = nil UpdateModeUI()
end)
ModeNPC.MouseButton1Click:Connect(function()
    Settings.Mode = "NPC" currentTarget = nil UpdateModeUI()
end)

Divider(Content, S(58))

-- SETTINGS ROW
Label(Content, "⚡ Strength", S(63), S(10))
Label(Content, "📏 Range", S(63), S(10))

-- fix: แยก y ของ label และ input
local function MakeSmallLabel(parent, text, y, xPos)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, S(90), 0, S(14))
    l.Position = UDim2.new(0, S(xPos), 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(160,160,160)
    l.TextSize = S(10)
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
end

MakeSmallLabel(Content, "⚡ Strength", S(62), 8)
MakeSmallLabel(Content, "📏 Range", S(62), 112)

local StrBox = InputBox(Content, "0.3", Settings.LockStrength, S(78), 90, 8)
local RangeBox = InputBox(Content, "100", Settings.LockRange, S(78), 90, 112)

Divider(Content, S(108))

-- LOCK BUTTON
local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.new(1, -S(16), 0, S(28))
LockBtn.Position = UDim2.new(0, S(8), 0, S(114))
LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
LockBtn.BorderSizePixel = 0
LockBtn.Text = "🔓 Lock : OFF"
LockBtn.TextColor3 = Color3.fromRGB(220,220,220)
LockBtn.TextSize = S(12)
LockBtn.Font = Enum.Font.GothamBold
LockBtn.Parent = Content
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0,6)

-- NEAREST BUTTON
local NearBtn = Instance.new("TextButton")
NearBtn.Size = UDim2.new(1, -S(16), 0, S(26))
NearBtn.Position = UDim2.new(0, S(8), 0, S(148))
NearBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NearBtn.BorderSizePixel = 0
NearBtn.Text = "📍 Nearest : OFF"
NearBtn.TextColor3 = Color3.fromRGB(200,200,200)
NearBtn.TextSize = S(11)
NearBtn.Font = Enum.Font.GothamBold
NearBtn.Parent = Content
Instance.new("UICorner", NearBtn).CornerRadius = UDim.new(0,6)

-- PREV / TARGET / NEXT
local PrevBtn = Instance.new("TextButton")
PrevBtn.Size = UDim2.new(0, S(44), 0, S(26))
PrevBtn.Position = UDim2.new(0, S(8), 0, S(182))
PrevBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
PrevBtn.BorderSizePixel = 0
PrevBtn.Text = "◀"
PrevBtn.TextColor3 = Color3.fromRGB(220,220,220)
PrevBtn.TextSize = S(14)
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.Parent = Content
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0,6)

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(0, S(100), 0, S(26))
TargetLabel.Position = UDim2.new(0, S(58), 0, S(182))
TargetLabel.BackgroundColor3 = Color3.fromRGB(25,25,25)
TargetLabel.BorderSizePixel = 0
TargetLabel.Text = "No Target"
TargetLabel.TextColor3 = Color3.fromRGB(200,200,200)
TargetLabel.TextSize = S(10)
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
TargetLabel.Parent = Content
Instance.new("UICorner", TargetLabel).CornerRadius = UDim.new(0,5)

local NextBtn = Instance.new("TextButton")
NextBtn.Size = UDim2.new(0, S(44), 0, S(26))
NextBtn.Position = UDim2.new(0, S(164), 0, S(182))
NextBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NextBtn.BorderSizePixel = 0
NextBtn.Text = "▶"
NextBtn.TextColor3 = Color3.fromRGB(220,220,220)
NextBtn.TextSize = S(14)
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = Content
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(216))

-- SCAN TOGGLE BUTTON
local ScanToggleBtn = Instance.new("TextButton")
ScanToggleBtn.Size = UDim2.new(1, -S(16), 0, S(26))
ScanToggleBtn.Position = UDim2.new(0, S(8), 0, S(222))
ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
ScanToggleBtn.BorderSizePixel = 0
ScanToggleBtn.Text = "🔍 Scan Menu : OFF"
ScanToggleBtn.TextColor3 = Color3.fromRGB(200,200,200)
ScanToggleBtn.TextSize = S(11)
ScanToggleBtn.Font = Enum.Font.GothamBold
ScanToggleBtn.Parent = Content
Instance.new("UICorner", ScanToggleBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(256))

local StatusLabel = Label(Content, "● Idle", S(262), S(11))
StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)

-- ══════════════════════════════
--       SCAN MENU (แยก)
-- ══════════════════════════════
local ScanFrame = Instance.new("Frame")
ScanFrame.Size = UDim2.new(0, SS(200), 0, SS(280))
ScanFrame.Position = UDim2.new(0.5, SS(120), 0.5, -SS(140))
ScanFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
ScanFrame.BorderSizePixel = 0
ScanFrame.ClipsDescendants = true
ScanFrame.Visible = false
ScanFrame.Parent = ScreenGui
Instance.new("UICorner", ScanFrame).CornerRadius = UDim.new(0,8)

local ScanTitleBar = Instance.new("Frame")
ScanTitleBar.Size = UDim2.new(1, 0, 0, SS(28))
ScanTitleBar.BackgroundColor3 = Color3.fromRGB(28,28,28)
ScanTitleBar.BorderSizePixel = 0
ScanTitleBar.Parent = ScanFrame

local ScanTitle = Instance.new("TextLabel")
ScanTitle.Size = UDim2.new(1, -SS(60), 1, 0)
ScanTitle.Position = UDim2.new(0, SS(8), 0, 0)
ScanTitle.BackgroundTransparency = 1
ScanTitle.Text = "🔍 Scan"
ScanTitle.TextColor3 = Color3.fromRGB(255,255,255)
ScanTitle.TextSize = SS(12)
ScanTitle.Font = Enum.Font.GothamBold
ScanTitle.TextXAlignment = Enum.TextXAlignment.Left
ScanTitle.Parent = ScanTitleBar

-- Size box scan
local ScanSizeBox = Instance.new("TextBox")
ScanSizeBox.Size = UDim2.new(0, SS(24), 0, SS(18))
ScanSizeBox.Position = UDim2.new(1, -SS(56), 0.5, -SS(9))
ScanSizeBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
ScanSizeBox.BorderSizePixel = 0
ScanSizeBox.Text = tostring(Settings.ScanMenuSize)
ScanSizeBox.TextColor3 = Color3.fromRGB(255,255,255)
ScanSizeBox.TextSize = SS(10)
ScanSizeBox.Font = Enum.Font.Gotham
ScanSizeBox.Parent = ScanTitleBar
Instance.new("UICorner", ScanSizeBox).CornerRadius = UDim.new(0,4)

local ScanMinBtn = Instance.new("TextButton")
ScanMinBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ScanMinBtn.Position = UDim2.new(1, -SS(34), 0.5, -SS(10))
ScanMinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
ScanMinBtn.BorderSizePixel = 0
ScanMinBtn.Text = "–"
ScanMinBtn.TextColor3 = Color3.fromRGB(255,255,255)
ScanMinBtn.TextSize = SS(12)
ScanMinBtn.Font = Enum.Font.GothamBold
ScanMinBtn.Parent = ScanTitleBar
Instance.new("UICorner", ScanMinBtn).CornerRadius = UDim.new(0,4)

local ScanCloseBtn = Instance.new("TextButton")
ScanCloseBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ScanCloseBtn.Position = UDim2.new(1, -SS(12), 0.5, -SS(10))
ScanCloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
ScanCloseBtn.BorderSizePixel = 0
ScanCloseBtn.Text = "✕"
ScanCloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
ScanCloseBtn.TextSize = SS(10)
ScanCloseBtn.Font = Enum.Font.GothamBold
ScanCloseBtn.Parent = ScanTitleBar
Instance.new("UICorner", ScanCloseBtn).CornerRadius = UDim.new(0,4)

-- Scan button
local DoScanBtn = Instance.new("TextButton")
DoScanBtn.Size = UDim2.new(1, -SS(16), 0, SS(26))
DoScanBtn.Position = UDim2.new(0, SS(8), 0, SS(34))
DoScanBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
DoScanBtn.BorderSizePixel = 0
DoScanBtn.Text = "🔍 Scan Now"
DoScanBtn.TextColor3 = Color3.fromRGB(220,220,220)
DoScanBtn.TextSize = SS(11)
DoScanBtn.Font = Enum.Font.GothamBold
DoScanBtn.Parent = ScanFrame
Instance.new("UICorner", DoScanBtn).CornerRadius = UDim.new(0,6)

-- Scroll list
local ScanScroll = Instance.new("ScrollingFrame")
ScanScroll.Size = UDim2.new(1, -SS(8), 1, -SS(68))
ScanScroll.Position = UDim2.new(0, SS(4), 0, SS(66))
ScanScroll.BackgroundTransparency = 1
ScanScroll.BorderSizePixel = 0
ScanScroll.ScrollBarThickness = 3
ScanScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
ScanScroll.CanvasSize = UDim2.new(0,0,0,0)
ScanScroll.Parent = ScanFrame

local ScanLayout = Instance.new("UIListLayout")
ScanLayout.Padding = UDim.new(0, SS(3))
ScanLayout.Parent = ScanScroll

local ScanCountLabel = Instance.new("TextLabel")
ScanCountLabel.Size = UDim2.new(1, -SS(16), 0, SS(14))
ScanCountLabel.Position = UDim2.new(0, SS(8), 0, SS(52))
ScanCountLabel.BackgroundTransparency = 1
ScanCountLabel.Text = "0 found"
ScanCountLabel.TextColor3 = Color3.fromRGB(100,100,100)
ScanCountLabel.TextSize = SS(9)
ScanCountLabel.Font = Enum.Font.Gotham
ScanCountLabel.TextXAlignment = Enum.TextXAlignment.Left
ScanCountLabel.Parent = ScanFrame

-- ══════════════════════════════
--        TEAM COLOR
-- ══════════════════════════════
local function GetTeamColor(model)
    -- Player team
    local p = Players:GetPlayerFromCharacter(model)
    if p and p.Team then
        return p.Team.TeamColor.Color
    end
    -- NPC team tag (ถ้า game ติด Team value ใน model)
    local teamVal = model:FindFirstChild("Team") or model:FindFirstChild("TeamColor")
    if teamVal then
        if teamVal:IsA("StringValue") then
            for _, t in ipairs(Teams:GetTeams()) do
                if t.Name == teamVal.Value then
                    return t.TeamColor.Color
                end
            end
        elseif teamVal:IsA("Color3Value") then
            return teamVal.Value
        end
    end
    -- ศัตรูของ localplayer ทีม
    if p then
        local myTeam = LocalPlayer.Team
        if myTeam and p.Team and p.Team ~= myTeam then
            return Color3.fromRGB(220, 60, 60) -- แดง = ศัตรู
        elseif myTeam and p.Team and p.Team == myTeam then
            return Color3.fromRGB(60, 200, 100) -- เขียว = พวก
        end
    end
    return Color3.fromRGB(180,180,180) -- default
end

-- ══════════════════════════════
--       CORE FUNCTIONS
-- ══════════════════════════════
local function GetTargetList()
    local list = {}
    local range = tonumber(RangeBox.Text) or Settings.LockRange
    if Settings.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                    if dist <= range then
                        table.insert(list, {model = p.Character, name = p.Name, dist = dist})
                    end
                end
            end
        end
    else
        -- NPC: scan ครั้งเดียว เก็บ descendants ไว้ใช้
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                    local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                    if dist <= range then
                        table.insert(list, {model = obj, name = obj.Name, dist = dist})
                    end
                end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

local function SetTarget(model)
    currentTarget = model
    if model then
        TargetLabel.Text = model.Name
        StatusLabel.Text = "🔒 " .. model.Name
        StatusLabel.TextColor3 = Color3.fromRGB(220,220,220)
    else
        TargetLabel.Text = "No Target"
        StatusLabel.Text = "● Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
    end
end

local function StartLock()
    if lockConnection then lockConnection:Disconnect() end
    local timer = 0
    lockConnection = RunService.Heartbeat:Connect(function(dt)
        Settings.LockStrength = tonumber(StrBox.Text) or 0.3

        -- throttle NPC scan ทุก SCAN_INTERVAL วิ ลด lag
        if not currentTarget or (Settings.NearestMode) then
            timer = timer + dt
            if timer >= SCAN_INTERVAL then
                timer = 0
                local list = GetTargetList()
                targetList = list
                if #list > 0 then
                    if Settings.NearestMode then
                        -- nearest mode: เลือกใกล้สุดเสมอ
                        SetTarget(list[1].model)
                        targetIndex = 1
                    elseif not currentTarget then
                        SetTarget(list[1].model)
                        targetIndex = 1
                    end
                end
            end
        end

        if currentTarget then
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local hum = currentTarget:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                SetTarget(nil)
                return
            end
            local targetPos = hrp.Position
            local currentCF = Camera.CFrame
            local lookAt = CFrame.lookAt(currentCF.Position, targetPos)
            Camera.CFrame = currentCF:Lerp(lookAt, Settings.LockStrength)
        end
    end)
end

local function StopLock()
    if lockConnection then lockConnection:Disconnect() lockConnecti
