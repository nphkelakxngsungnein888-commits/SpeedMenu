-- Lock Menu v3 FIXED | kuy kuy
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
    Humanoid = c:WaitForChild("Humanoid")
end)

local Settings = {
    MenuSize = 10, ScanMenuSize = 10,
    LockStrength = 0.3, LockRange = 100,
    Mode = "NPC", Enabled = false,
    NearestMode = false, FilterColor = nil,
}

local currentTarget = nil
local targetList = {}
local targetIndex = 1
local lockConnection = nil
local foundColors = {}
local SCAN_INTERVAL = 0.5

pcall(function()
    local old = CoreGui:FindFirstChild("LockMenu")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local function S(n) return n * (Settings.MenuSize / 10) end
local function SS(n) return n * (Settings.ScanMenuSize / 10) end

local function ColorToHex(c)
    return string.format("%02X%02X%02X",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
        end
    end)
    local function onMove(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end
    handle.InputChanged:Connect(onMove)
    UserInputService.InputChanged:Connect(onMove)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- ══════════════════════════════
--  CORE FUNCTIONS (ประกาศก่อน UI)
-- ══════════════════════════════
local SetTarget
local TargetLabel, StatusLabel -- forward declare UI refs

local function GetTeamColor(model)
    local p = Players:GetPlayerFromCharacter(model)
    local myTeam = LocalPlayer.Team
    if p then
        if myTeam and p.Team == myTeam then return Color3.fromRGB(60,200,100)
        elseif p.Team then return Color3.fromRGB(220,60,60) end
        return Color3.fromRGB(180,180,255)
    end
    return Color3.fromRGB(220,120,50)
end

local function GetTargetList()
    if not HumanoidRootPart then return {} end
    local list = {}
    local range = Settings.LockRange
    if Settings.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                    if dist <= range then
                        table.insert(list, {model=p.Character, name=p.Name, dist=dist, color=GetTeamColor(p.Character)})
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                    local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                    if dist <= range then
                        table.insert(list, {model=obj, name=obj.Name, dist=dist, color=GetTeamColor(obj)})
                    end
                end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

local function FilterList(list)
    if not Settings.FilterColor then return list end
    local fHex = ColorToHex(Settings.FilterColor)
    local out = {}
    for _, e in ipairs(list) do
        if ColorToHex(e.color) == fHex then table.insert(out, e) end
    end
    return out
end

local function FindRoot(model)
    return model and model:FindFirstChild("HumanoidRootPart")
end
local function FindHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

-- ══════════════════════════════
--  MAIN FRAME
-- ══════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, S(220), 0, S(310))
MainFrame.Position = UDim2.new(0.5, -S(110), 0.5, -S(155))
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
MakeDraggable(MainFrame, TitleBar)

local TitleLabel2 = Instance.new("TextLabel", TitleBar)
TitleLabel2.Size = UDim2.new(1, -S(70), 1, 0)
TitleLabel2.Position = UDim2.new(0, S(8), 0, 0)
TitleLabel2.BackgroundTransparency = 1
TitleLabel2.Text = "⚔ Lock Menu"
TitleLabel2.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel2.TextSize = S(13)
TitleLabel2.Font = Enum.Font.GothamBold
TitleLabel2.TextXAlignment = Enum.TextXAlignment.Left

-- Size box ข้างปุ่มพับ
local SizeBox = Instance.new("TextBox", TitleBar)
SizeBox.Size = UDim2.new(0, S(28), 0, S(20))
SizeBox.Position = UDim2.new(1, -S(90), 0.5, -S(10))
SizeBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
SizeBox.BorderSizePixel = 0
SizeBox.Text = "10"
SizeBox.TextColor3 = Color3.fromRGB(200,200,200)
SizeBox.TextSize = S(11)
SizeBox.Font = Enum.Font.Gotham
SizeBox.ClearTextOnFocus = false
Instance.new("UICorner", SizeBox).CornerRadius = UDim.new(0,4)

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0, S(22), 0, S(22))
MinBtn.Position = UDim2.new(1, -S(58), 0.5, -S(11))
MinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.TextSize = S(14)
MinBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,4)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, S(22), 0, S(22))
CloseBtn.Position = UDim2.new(1, -S(30), 0.5, -S(11))
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = S(12)
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,4)

local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, 0, 1, -S(30))
Content.Position = UDim2.new(0, 0, 0, S(30))
Content.BackgroundTransparency = 1

-- ══════════════════════════════
--  HELPERS
-- ══════════════════════════════
local function Divider(parent, yPos)
    local d = Instance.new("Frame", parent)
    d.Size = UDim2.new(1, -S(16), 0, 1)
    d.Position = UDim2.new(0, S(8), 0, yPos)
    d.BackgroundColor3 = Color3.fromRGB(50,50,50)
    d.BorderSizePixel = 0
end

local function SmallLabel(parent, text, y, xPos)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(0, S(100), 0, S(14))
    l.Position = UDim2.new(0, S(xPos), 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(160,160,160)
    l.TextSize = S(10)
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function InputBox(parent, default, y, w, xPos)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0, S(w), 0, S(24))
    box.Position = UDim2.new(0, S(xPos), 0, y)
    box.BackgroundColor3 = Color3.fromRGB(30,30,30)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.PlaceholderColor3 = Color3.fromRGB(100,100,100)
    box.TextSize = S(11)
    box.Font = Enum.Font.Gotham
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)
    return box
end

-- ══════════════════════════════
--  MODE BUTTONS
-- ══════════════════════════════
SmallLabel(Content, "🎯 MODE", S(6), 8)

local ModePlayer = Instance.new("TextButton", Content)
ModePlayer.Size = UDim2.new(0, S(96), 0, S(26))
ModePlayer.Position = UDim2.new(0, S(8), 0, S(22))
ModePlayer.BackgroundColor3 = Color3.fromRGB(40,40,40)
ModePlayer.BorderSizePixel = 0
ModePlayer.Text = "👤 Player"
ModePlayer.TextColor3 = Color3.fromRGB(180,180,180)
ModePlayer.TextSize = S(11)
ModePlayer.Font = Enum.Font.GothamBold
Instance.new("UICorner", ModePlayer).CornerRadius = UDim.new(0,6)

local ModeNPC = Instance.new("TextButton", Content)
ModeNPC.Size = UDim2.new(0, S(96), 0, S(26))
ModeNPC.Position = UDim2.new(0, S(112), 0, S(22))
ModeNPC.BackgroundColor3 = Color3.fromRGB(200,200,200)
ModeNPC.BorderSizePixel = 0
ModeNPC.Text = "🤖 NPC"
ModeNPC.TextColor3 = Color3.fromRGB(20,20,20)
ModeNPC.TextSize = S(11)
ModeNPC.Font = Enum.Font.GothamBold
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

Divider(Content, S(54))

-- ══════════════════════════════
--  STRENGTH / RANGE
-- ══════════════════════════════
SmallLabel(Content, "⚡ Strength", S(58), 8)
SmallLabel(Content, "📏 Range", S(58), 112)

local StrBox = InputBox(Content, Settings.LockStrength, S(72), 90, 8)
local RangeBox = InputBox(Content, Settings.LockRange, S(72), 90, 112)

StrBox.FocusLost:Connect(function()
    local v = tonumber(StrBox.Text)
    if v then Settings.LockStrength = math.clamp(v, 0.01, 1)
    else StrBox.Text = tostring(Settings.LockStrength) end
end)

RangeBox.FocusLost:Connect(function()
    local v = tonumber(RangeBox.Text)
    if v then Settings.LockRange = v
    else RangeBox.Text = tostring(Settings.LockRange) end
end)

Divider(Content, S(102))

-- ══════════════════════════════
--  LOCK / NEAREST / NAV BUTTONS
-- ══════════════════════════════
local LockBtn = Instance.new("TextButton", Content)
LockBtn.Size = UDim2.new(1, -S(16), 0, S(28))
LockBtn.Position = UDim2.new(0, S(8), 0, S(108))
LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
LockBtn.BorderSizePixel = 0
LockBtn.Text = "🔓 Lock : OFF"
LockBtn.TextColor3 = Color3.fromRGB(220,220,220)
LockBtn.TextSize = S(12)
LockBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0,6)

local NearBtn = Instance.new("TextButton", Content)
NearBtn.Size = UDim2.new(1, -S(16), 0, S(26))
NearBtn.Position = UDim2.new(0, S(8), 0, S(142))
NearBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NearBtn.BorderSizePixel = 0
NearBtn.Text = "📍 Nearest : OFF"
NearBtn.TextColor3 = Color3.fromRGB(200,200,200)
NearBtn.TextSize = S(11)
NearBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", NearBtn).CornerRadius = UDim.new(0,6)

local PrevBtn = Instance.new("TextButton", Content)
PrevBtn.Size = UDim2.new(0, S(44), 0, S(26))
PrevBtn.Position = UDim2.new(0, S(8), 0, S(174))
PrevBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
PrevBtn.BorderSizePixel = 0
PrevBtn.Text = "◀"
PrevBtn.TextColor3 = Color3.fromRGB(220,220,220)
PrevBtn.TextSize = S(14)
PrevBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0,6)

TargetLabel = Instance.new("TextLabel", Content)
TargetLabel.Size = UDim2.new(0, S(104), 0, S(26))
TargetLabel.Position = UDim2.new(0, S(56), 0, S(174))
TargetLabel.BackgroundColor3 = Color3.fromRGB(25,25,25)
TargetLabel.BorderSizePixel = 0
TargetLabel.Text = "No Target"
TargetLabel.TextColor3 = Color3.fromRGB(200,200,200)
TargetLabel.TextSize = S(10)
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
Instance.new("UICorner", TargetLabel).CornerRadius = UDim.new(0,5)

local NextBtn = Instance.new("TextButton", Content)
NextBtn.Size = UDim2.new(0, S(44), 0, S(26))
NextBtn.Position = UDim2.new(0, S(166), 0, S(174))
NextBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NextBtn.BorderSizePixel = 0
NextBtn.Text = "▶"
NextBtn.TextColor3 = Color3.fromRGB(220,220,220)
NextBtn.TextSize = S(14)
NextBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(206))

local ScanToggleBtn = Instance.new("TextButton", Content)
ScanToggleBtn.Size = UDim2.new(1, -S(16), 0, S(26))
ScanToggleBtn.Position = UDim2.new(0, S(8), 0, S(212))
ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
ScanToggleBtn.BorderSizePixel = 0
ScanToggleBtn.Text = "🔍 Scan Menu : OFF"
ScanToggleBtn.TextColor3 = Color3.fromRGB(200,200,200)
ScanToggleBtn.TextSize = S(11)
ScanToggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ScanToggleBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(244))

StatusLabel = Instance.new("TextLabel", Content)
StatusLabel.Size = UDim2.new(1, -S(16), 0, S(20))
StatusLabel.Position = UDim2.new(0, S(8), 0, S(249))
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● Idle"
StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
StatusLabel.TextSize = S(11)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ══════════════════════════════
--  SET TARGET (ประกาศตอนนี้ได้แล้ว)
-- ══════════════════════════════
SetTarget = function(model)
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

-- ══════════════════════════════
--  SCAN FRAME
-- ══════════════════════════════
local ScanFrame = Instance.new("Frame", ScreenGui)
ScanFrame.Size = UDim2.new(0, SS(220), 0, SS(320))
ScanFrame.Position = UDim2.new(0.5, SS(120), 0.5, -SS(160))
ScanFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
ScanFrame.BorderSizePixel = 0
ScanFrame.ClipsDescendants = true
ScanFrame.Visible = false
Instance.new("UICorner", ScanFrame).CornerRadius = UDim.new(0,8)

local ScanTitleBar = Instance.new("Frame", ScanFrame)
ScanTitleBar.Size = UDim2.new(1, 0, 0, SS(28))
ScanTitleBar.BackgroundColor3 = Color3.fromRGB(28,28,28)
ScanTitleBar.BorderSizePixel = 0
MakeDraggable(ScanFrame, ScanTitleBar)

local ScanTitle = Instance.new("TextLabel", ScanTitleBar)
ScanTitle.Size = UDim2.new(1, -SS(90), 1, 0)
ScanTitle.Position = UDim2.new(0, SS(8), 0, 0)
ScanTitle.BackgroundTransparency = 1
ScanTitle.Text = "🔍 Scan"
ScanTitle.TextColor3 = Color3.fromRGB(255,255,255)
ScanTitle.TextSize = SS(12)
ScanTitle.Font = Enum.Font.GothamBold
ScanTitle.TextXAlignment = Enum.TextXAlignment.Left

local ColorPickerBtn = Instance.new("TextButton", ScanTitleBar)
ColorPickerBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ColorPickerBtn.Position = UDim2.new(1, -SS(56), 0.5, -SS(10))
ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(80,80,200)
ColorPickerBtn.BorderSizePixel = 0
ColorPickerBtn.Text = "🎨"
ColorPickerBtn.TextColor3 = Color3.fromRGB(255,255,255)
ColorPickerBtn.TextSize = SS(10)
ColorPickerBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ColorPickerBtn).CornerRadius = UDim.new(0,4)

local ScanMinBtn = Instance.new("TextButton", ScanTitleBar)
ScanMinBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ScanMinBtn.Position = UDim2.new(1, -SS(34), 0.5, -SS(10))
ScanMinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
ScanMinBtn.BorderSizePixel = 0
ScanMinBtn.Text = "–"
ScanMinBtn.TextColor3 = Color3.fromRGB(255,255,255)
ScanMinBtn.TextSize = SS(12)
ScanMinBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ScanMinBtn).CornerRadius = UDim.new(0,4)

local ScanCloseBtn = Instance.new("TextButton", ScanTitleBar)
ScanCloseBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ScanCloseBtn.Position = UDim2.new(1, -SS(12), 0.5, -SS(10))
ScanCloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
ScanCloseBtn.BorderSizePixel = 0
ScanCloseBtn.Text = "✕"
ScanCloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
ScanCloseBtn.TextSize = SS(10)
ScanCloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ScanCloseBtn).CornerRadius = UDim.new(0,4)

local FilterBar = Instance.new("Frame", ScanFrame)
FilterBar.Size = UDim2.new(1, -SS(16), 0, SS(22))
FilterBar.Position = UDim2.new(0, SS(8), 0, SS(30))
FilterBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
FilterBar.BorderSizePixel = 0
Instance.new("UICorner", FilterBar).CornerRadius = UDim.new(0,5)

local FilterLabel = Instance.new("TextLabel", FilterBar)
FilterLabel.Size = UDim2.new(1, -SS(30), 1, 0)
FilterLabel.Position = UDim2.new(0, SS(6), 0, 0)
FilterLabel.BackgroundTransparency = 1
FilterLabel.Text = "🎨 Filter: ทั้งหมด"
FilterLabel.TextColor3 = Color3.fromRGB(160,160,160)
FilterLabel.TextSize = SS(9)
FilterLabel.Font = Enum.Font.Gotham
FilterLabel.TextXAlignment = Enum.TextXAlignment.Left

local ClearFilterBtn = Instance.new("TextButton", FilterBar)
ClearFilterBtn.Size = UDim2.new(0, SS(24), 0, SS(18))
ClearFilterBtn.Position = UDim2.new(1, -SS(26), 0.5, -SS(9))
ClearFilterBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
ClearFilterBtn.BorderSizePixel = 0
ClearFilterBtn.Text = "✕"
ClearFilterBtn.TextColor3 = Color3.fromRGB(255,255,255)
ClearFilterBtn.TextSize = SS(9)
ClearFilterBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ClearFilterBtn).CornerRadius = UDim.new(0,4)

local DoScanBtn = Instance.new("TextButton", ScanFrame)
DoScanBtn.Size = UDim2.new(1, -SS(16), 0, SS(22))
DoScanBtn.Position = UDim2.new(0, SS(8), 0, SS(56))
DoScanBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
DoScanBtn.BorderSizePixel = 0
DoScanBtn.Text = "▶ SCAN"
DoScanBtn.TextColor3 = Color3.fromRGB(220,220,220)
DoScanBtn.TextSize = SS(11)
DoScanBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", DoScanBtn).CornerRadius = UDim.new(0,6)

local ScanCountLabel = Instance.new("TextLabel", ScanFrame)
ScanCountLabel.Size = UDim2.new(1, -SS(16), 0, SS(14))
ScanCountLabel.Position = UDim2.new(0, SS(8), 0, SS(84))
ScanCountLabel.BackgroundTransparency = 1
ScanCountLabel.Text = "0 found"
ScanCountLabel.TextColor3 = Color3.fromRGB(100,100,100)
ScanCountLabel.TextSize = SS(9)
ScanCountLabel.Font = Enum.Font.Gotham
ScanCountLabel.TextXAlignment = Enum.TextXAlignment.Left

local ScanScroll = Instance.new("ScrollingFrame", ScanFrame)
ScanScroll.Size = UDim2.new(1, -SS(8), 1, -SS(100))
ScanScroll.Position = UDim2.new(0, SS(4), 0, SS(98))
ScanScroll.BackgroundTransparency = 1
ScanScroll.BorderSizePixel = 0
ScanScroll.ScrollBarThickness = 3
ScanScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
ScanScroll.CanvasSize = UDim2.new(0,0,0,0)

local ScanLayout = Instance.new("UIListLayout", ScanScroll)
ScanLayout.Padding = UDim.new(0, SS(3))

-- ══════════════════════════════
--  COLOR PICKER POPUP
-- ══════════════════════════════
local ColorPopup = Instance.new("Frame", ScreenGui)
ColorPopup.Size = UDim2.new(0, SS(200), 0, SS(220))
ColorPopup.Position = UDim2.new(0.5, SS(120), 0.5, SS(170))
ColorPopup.BackgroundColor3 = Color3.fromRGB(18,18,18)
ColorPopup.BorderSizePixel = 0
ColorPopup.ClipsDescendants = true
ColorPopup.Visible = false
ColorPopup.ZIndex = 10
Instance.new("UICorner", ColorPopup).CornerRadius = UDim.new(0,8)

local CPTitleBar = Instance.new("Frame", ColorPopup)
CPTitleBar.Size = UDim2.new(1, 0, 0, SS(26))
CPTitleBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
CPTitleBar.BorderSizePixel = 0
CPTitleBar.ZIndex = 10
MakeDraggable(ColorPopup, CPTitleBar)

local CPTitle = Instance.new("TextLabel", CPTitleBar)
CPTitle.Size = UDim2.new(1, -SS(30), 1, 0)
CPTitle.Position = UDim2.new(0, SS(8), 0, 0)
CPTitle.BackgroundTransparency = 1
CPTitle.Text = "🎨 เลือกสี Filter"
CPTitle.TextColor3 = Color3.fromRGB(255,255,255)
CPTitle.TextSize = SS(10)
CPTitle.Font = Enum.Font.GothamBold
CPTitle.TextXAlignment = Enum.TextXAlignment.Left
CPTitle.ZIndex = 10

local CPCloseBtn = Instance.new("TextButton", CPTitleBar)
CPCloseBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
CPCloseBtn.Position = UDim2.new(1, -SS(22), 0.5, -SS(10))
CPCloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CPCloseBtn.BorderSizePixel = 0
CPCloseBtn.Text = "✕"
CPCloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CPCloseBtn.TextSize = SS(10)
CPCloseBtn.Font = Enum.Font.GothamBold
CPCloseBtn.ZIndex = 10
Instance.new("UICorner", CPCloseBtn).CornerRadius = UDim.new(0,4)

local CPNoColorBtn = Instance.new("TextButton", ColorPopup)
CPNoColorBtn.Size = UDim2.new(1, -SS(16), 0, SS(22))
CPNoColorBtn.Position = UDim2.new(0, SS(8), 0, SS(30))
CPNoColorBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
CPNoColorBtn.BorderSizePixel = 0
CPNoColorBtn.Text = "✅ แสดงทั้งหมด (ไม่ filter)"
CPNoColorBtn.TextColor3 = Color3.fromRGB(200,200,200)
CPNoColorBtn.TextSize = SS(9)
CPNoColorBtn.Font = Enum.Font.GothamBold
CPNoColorBtn.ZIndex = 10
Instance.new("UICorner", CPNoColorBtn).CornerRadius = UDim.new(0,5)

local CPScroll = Instance.new("ScrollingFrame", ColorPopup)
CPScroll.Size = UDim2.new(1, -SS(8), 1, -SS(56))
CPScroll.Position = UDim2.new(0, SS(4), 0, SS(54))
CPScroll.BackgroundTransparency = 1
CPScroll.BorderSizePixel = 0
CPScroll.ScrollBarThickness = 3
CPScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
CPScroll.CanvasSize = UDim2.new(0,0,0,0)
CPScroll.ZIndex = 10

local CPLayout = Instance.new("UIListLayout", CPScroll)
CPLayout.Padding = UDim.new(0, SS(3))

-- ══════════════════════════════
--  UPDATE COLOR PICKER
-- ══════════════════════════════
local function UpdateColorPicker()
    for _, c in ipairs(CPScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local count = 0
    for hexStr, col in pairs(foundColors) do
        count = count + 1
        local btn = Instance.new("TextButton", CPScroll)
        btn.Size = UDim2.new(1, 0, 0, SS(26))
        btn.BackgroundColor3 = col
        btn.BorderSizePixel = 0
        btn.Text = "  #" .. hexStr
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextSize = SS(9)
        btn.Font = Enum.Font.GothamBold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, SS(6))
        if Settings.FilterColor and ColorToHex(Settings.FilterColor) == hexStr then
            local s = Instance.new("UIStroke", btn)
            s.Color = Color3.fromRGB(255,255,255) s.Thickness = 2
        end
        btn.MouseButton1Click:Connect(function()
            Settings.FilterColor = col
            FilterLabel.Text = "🎨 Filter: #" .. hexStr
            FilterLabel.TextColor3 = col
            ColorPickerBtn.BackgroundColor3 = col
            ColorPopup.Visible = false
            UpdateColorPicker()
        end)
    end
    CPScroll.CanvasSize = UDim2.new(0, 0, 0, CPLayout.AbsoluteContentSize.Y + SS(4))
    if count == 0 then
        local noData = Instance.new("TextLabel", CPScroll)
        noData.Size = UDim2.new(1, 0, 0, SS(30))
        noData.BackgroundTransparency = 1
        noData.Text = "Scan ก่อนเพื่อดูสี"
        noData.TextColor3 = Color3.fromRGB(120,120,120)
        noData.TextSize = SS(9)
        noData.Font = Enum.Font.Gotham
        noData.ZIndex = 11
    end
end

-- ══════════════════════════════
--  LOCK CORE
-- ══════════════════════════════
local originalCameraType = Enum.CameraType.Custom

local function StartLock()
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    originalCameraType = Camera.CameraType
    Camera.CameraType = Enum.CameraType.Scriptable
    local timer = 0
    lockConnection = RunService.RenderStepped:Connect(function(dt)
        if not HumanoidRootPart then return end
        Camera.CameraType = Enum.CameraType.Scriptable
        if not currentTarget or Settings.NearestMode then
            timer = timer + dt
            if timer >= SCAN_INTERVAL then
                timer = 0
                local raw = GetTargetList()
                local filtered = FilterList(raw)
                targetList = filtered
                if #filtered > 0 then
                    if Settings.NearestMode then
                        SetTarget(filtered[1].model) targetIndex = 1
                    elseif not currentTarget then
                        SetTarget(filtered[1].model) targetIndex = 1
                    end
                end
            end
        end
        if currentTarget then
            local hrp = FindRoot(currentTarget)
            local hum = FindHumanoid(currentTarget)
            if not hrp or not hum or hum.Health <= 0 then
                SetTarget(nil) return
            end
            local targetPos = hrp.Position
            HumanoidRootPart.CFrame = CFrame.new(
                HumanoidRootPart.Position,
                Vector3.new(targetPos.X, HumanoidRootPart.Position.Y, targetPos.Z)
            )
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end)
end

local function StopLock()
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    pcall(function() Camera.CameraType = originalCameraType end)
    SetTarget(nil)
end

-- ══════════════════════════════
--  BUTTON CONNECTIONS
-- ══════════════════════════════
LockBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        LockBtn.Text = "🔒 Lock : ON"
        LockBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
        StartLock()
    else
        LockBtn.Text = "🔓 Lock : OFF"
        LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        StopLock()
    end
end)

NearBtn.MouseButton1Click:Connect(function()
    Settings.NearestMode = not Settings.NearestMode
    NearBtn.Text = Settings.NearestMode and "📍 Nearest : ON" or "📍 Nearest : OFF"
    NearBtn.BackgroundColor3 = Settings.NearestMode
        and Color3.fromRGB(40,80,40) or Color3.fromRGB(35,35,35)
end)

PrevBtn.MouseButton1Click:Connect(function()
    if #targetList == 0 then targetList = FilterList(GetTargetList()) end
    if #targetList > 0 then
        targetIndex = targetIndex - 1
        if targetIndex < 1 then targetIndex = #targetList end
        SetTarget(targetList[targetIndex].model)
    end
end)

NextBtn.MouseButton1Click:Connect(function()
    if #targetList == 0 then targetList = FilterList(GetTargetList()) end
    if #targetList > 0 then
        targetIndex = targetIndex + 1
        if targetIndex > #targetList then targetIndex = 1 end
        SetTarget(targetList[targetIndex].model)
    end
end)

SizeBox.FocusLost:Connect(function()
    local v = tonumber(SizeBox.Text)
    if v then
        v = math.max(1, v)
        Settings.MenuSize = v
        -- resize
        local sc = v / 10
        MainFrame.Size = UDim2.new(0, 220*sc, 0, 310*sc)
    end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized
        and UDim2.new(0, S(220), 0, S(30))
        or UDim2.new(0, S(220), 0, S(310))
end)

CloseBtn.MouseButton1Click:Connect(function()
    StopLock() ScreenGui:Destroy()
end)

local scanVisible = false
ScanToggleBtn.MouseButton1Click:Connect(function()
    scanVisible = not scanVisible
    ScanFrame.Visible = scanVisible
    ScanToggleBtn.Text = scanVisible and "🔍 Scan Menu : ON" or "🔍 Scan Menu : OFF"
    ScanToggleBtn.BackgroundColor3 = scanVisible
        and Color3.fromRGB(40,80,40) or Color3.fromRGB(35,35,35)
end)

ScanCloseBtn.MouseButton1Click:Connect(function()
    scanVisible = false
    ScanFrame.Visible = false
    ColorPopup.Visible = false
    ScanToggleBtn.Text = "🔍 Scan Menu : OFF"
    ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
end)

local scanMin = false
ScanMinBtn.MouseButton1Click:Connect(function()
    scanMin = not scanMin
    ScanScroll.Visible = not scanMin
    DoScanBtn.Visible = not scanMin
    ScanCountLabel.Visible = not scanMin
    FilterBar.Visible = not scanMin
    ScanFrame.Size = scanMin
        and UDim2.new(0, SS(220), 0, SS(28))
        or UDim2.new(0, SS(220), 0, SS(320))
    if scanMin then ColorPopup.Visible = false end
end)

DoScanBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(ScanScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local raw = GetTargetList()
    foundColors = {}
    for _, entry in ipairs(raw) do
        local hex = ColorToHex(entry.color)
        if not foundColors[hex] then foundColors[hex] = entry.color end
    end
    local list = FilterList(raw)
    targetList = list
    ScanCountLabel.Text = #list .. " found  (raw: " .. #raw .. ")"
    for i, entry in ipairs(list) do
        local btn = Instance.new("TextButton", ScanScroll)
        btn.Size = UDim2.new(1, 0, 0, SS(26))
        btn.BackgroundColor3 = Color3.fromRGB(22,22,22)
        btn.BorderSizePixel = 0
        btn.Text = string.format("  [%d] %s  %.0fm", i, entry.name, entry.dist)
        btn.TextColor3 = entry.color
        btn.TextSize = SS(9)
        btn.Font = Enum.Font.Gotham
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        local dot = Instance.new("Frame", btn)
        dot.Size = UDim2.new(0, SS(6), 0, SS(6))
        dot.Position = UDim2.new(0, SS(4), 0.5, -SS(3))
        dot.BackgroundColor3 = entry.color
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        btn.MouseButton1Click:Connect(function()
            targetIndex = i SetTarget(entry.model)
        end)
    end
    ScanScroll.CanvasSize = UDim2.new(0, 0, 0, ScanLayout.AbsoluteContentSize.Y + SS(4))
    UpdateColorPicker()
end)

ColorPickerBtn.MouseButton1Click:Connect(function()
    ColorPopup.Visible = not ColorPopup.Visible
    if ColorPopup.Visible then UpdateColorPicker() end
end)

CPCloseBtn.MouseButton1Click:Connect(function()
    ColorPopup.Visible = false
end)

ClearFilterBtn.MouseButton1Click:Connect(function()
    Settings.FilterColor = nil
    FilterLabel.Text = "🎨 Filter: ทั้งหมด"
    FilterLabel.TextColor3 = Color3.fromRGB(160,160,160)
    ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(80,80,200)
    UpdateColorPicker()
end)

CPNoColorBtn.MouseButton1Click:Connect(function()
    Settings.FilterColor = nil
    FilterLabel.Text = "🎨 Filter: ทั้งหมด"
    FilterLabel.TextColor3 = Color3.fromRGB(160,160,160)
    ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(80,80,200)
    ColorPopup.Visible = false
    UpdateColorPicker()
end)
