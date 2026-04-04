-- Lock Menu v7 | NPC/Player | Scan + Color Filter | Third-Person Lock-On
-- Mobile friendly | Codex compatible

-- ══════════════════════════════
--   SERVICES
-- ══════════════════════════════
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer    = Players.LocalPlayer
local Camera         = workspace.CurrentCamera

-- ══════════════════════════════
--   STATE VARIABLES
-- ══════════════════════════════
local Character      = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local currentTarget  = nil
local targetList     = {}
local targetIndex    = 1
local lockConnection = nil
local foundColors    = {}
local SCAN_INTERVAL  = 0.5

local Settings = {
    MenuSize      = 10,
    ScanMenuSize  = 10,
    LockStrength  = 0.3,
    LockRange     = 100,
    Mode          = "NPC",
    Enabled       = false,
    NearestMode   = false,
    FilterColor   = nil,
}

-- Lock params (ปรับได้ผ่าน UI)
local HEIGHT_OFFSET = 1.5   -- offset เป้าหมายขึ้นบน (aim หัว)
local CAM_DISTANCE  = 15    -- ระยะกล้องถอยหลัง
local CAM_HEIGHT    = 3     -- ความสูงกล้องเหนือ HRP

-- ══════════════════════════════
--   GUI SETUP
-- ══════════════════════════════
pcall(function()
    local old = CoreGui:FindFirstChild("LockMenu")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local function S(n)  return n * (Settings.MenuSize / 10) end
local function SS(n) return n * (Settings.ScanMenuSize / 10) end

local function ColorToHex(c)
    return string.format("%02X%02X%02X",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

-- ══════════════════════════════
--   DRAG HELPER
-- ══════════════════════════════
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    local function onMove(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end
    local function onEnd(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end
    handle.InputChanged:Connect(onMove)
    UserInputService.InputChanged:Connect(onMove)
    handle.InputEnded:Connect(onEnd)
    UserInputService.InputEnded:Connect(onEnd)
end

-- ══════════════════════════════
--   UI HELPERS
-- ══════════════════════════════
local function Divider(parent, yPos)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -S(16), 0, 1)
    d.Position = UDim2.new(0, S(8), 0, yPos)
    d.BackgroundColor3 = Color3.fromRGB(50,50,50)
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function SmallLabel(parent, text, y, xPos)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, S(100), 0, S(14))
    l.Position = UDim2.new(0, S(xPos), 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(160,160,160)
    l.TextSize = S(10)
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function InputBox(parent, default, y, w, xPos)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, S(w), 0, S(24))
    box.Position = UDim2.new(0, S(xPos), 0, y)
    box.BackgroundColor3 = Color3.fromRGB(30,30,30)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.PlaceholderColor3 = Color3.fromRGB(100,100,100)
    box.TextSize = S(11)
    box.Font = Enum.Font.Gotham
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)
    return box
end

-- ══════════════════════════════
--   MAIN FRAME
-- ══════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, S(220), 0, S(380))
MainFrame.Position = UDim2.new(0.5, -S(110), 0.5, -S(190))
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

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -S(70), 1, 0)
TitleLabel.Position = UDim2.new(0, S(8), 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ Lock Menu v7"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextSize = S(12)
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

-- ══════════════════════════════
--   MODE BUTTONS
-- ══════════════════════════════
SmallLabel(Content, "🎯 MODE", S(6), 8)

local ModePlayer = Instance.new("TextButton")
ModePlayer.Size = UDim2.new(0, S(96), 0, S(26))
ModePlayer.Position = UDim2.new(0, S(8), 0, S(22))
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
ModeNPC.Position = UDim2.new(0, S(112), 0, S(22))
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

Divider(Content, S(54))

-- ══════════════════════════════
--   STRENGTH / RANGE
-- ══════════════════════════════
SmallLabel(Content, "⚡ Strength (0.01-1)", S(58), 8)
SmallLabel(Content, "📏 Range", S(58), 112)
local StrBox   = InputBox(Content, Settings.LockStrength, S(72), 90, 8)
local RangeBox = InputBox(Content, Settings.LockRange,    S(72), 90, 112)

StrBox.FocusLost:Connect(function()
    local v = tonumber(StrBox.Text)
    if v then
        Settings.LockStrength = v
        StrBox.Text = tostring(v)
    else
        StrBox.Text = tostring(Settings.LockStrength)
    end
end)

Divider(Content, S(102))

-- ══════════════════════════════
--   HEIGHT / CAM DISTANCE
-- ══════════════════════════════
SmallLabel(Content, "⬆ Height Offset", S(106), 8)
SmallLabel(Content, "📷 Cam Dist", S(106), 112)
local HeightBox  = InputBox(Content, HEIGHT_OFFSET, S(120), 90, 8)
local CamDistBox = InputBox(Content, CAM_DISTANCE,  S(120), 90, 112)

HeightBox.FocusLost:Connect(function()
    local v = tonumber(HeightBox.Text)
    if v then HEIGHT_OFFSET = v HeightBox.Text = tostring(v)
    else HeightBox.Text = tostring(HEIGHT_OFFSET) end
end)
CamDistBox.FocusLost:Connect(function()
    local v = tonumber(CamDistBox.Text)
    if v then CAM_DISTANCE = v CamDistBox.Text = tostring(v)
    else CamDistBox.Text = tostring(CAM_DISTANCE) end
end)

Divider(Content, S(150))

-- ══════════════════════════════
--   LOCK BUTTON
-- ══════════════════════════════
local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.new(1, -S(16), 0, S(28))
LockBtn.Position = UDim2.new(0, S(8), 0, S(156))
LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
LockBtn.BorderSizePixel = 0
LockBtn.Text = "🔓 Lock : OFF"
LockBtn.TextColor3 = Color3.fromRGB(220,220,220)
LockBtn.TextSize = S(12)
LockBtn.Font = Enum.Font.GothamBold
LockBtn.Parent = Content
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0,6)

-- ══════════════════════════════
--   NEAREST BUTTON
-- ══════════════════════════════
local NearBtn = Instance.new("TextButton")
NearBtn.Size = UDim2.new(1, -S(16), 0, S(26))
NearBtn.Position = UDim2.new(0, S(8), 0, S(190))
NearBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NearBtn.BorderSizePixel = 0
NearBtn.Text = "📍 Nearest : OFF"
NearBtn.TextColor3 = Color3.fromRGB(200,200,200)
NearBtn.TextSize = S(11)
NearBtn.Font = Enum.Font.GothamBold
NearBtn.Parent = Content
Instance.new("UICorner", NearBtn).CornerRadius = UDim.new(0,6)

-- ══════════════════════════════
--   PREV / TARGET / NEXT
-- ══════════════════════════════
local PrevBtn = Instance.new("TextButton")
PrevBtn.Size = UDim2.new(0, S(44), 0, S(26))
PrevBtn.Position = UDim2.new(0, S(8), 0, S(222))
PrevBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
PrevBtn.BorderSizePixel = 0
PrevBtn.Text = "◀"
PrevBtn.TextColor3 = Color3.fromRGB(220,220,220)
PrevBtn.TextSize = S(14)
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.Parent = Content
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0,6)

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(0, S(104), 0, S(26))
TargetLabel.Position = UDim2.new(0, S(56), 0, S(222))
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
NextBtn.Position = UDim2.new(0, S(166), 0, S(222))
NextBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NextBtn.BorderSizePixel = 0
NextBtn.Text = "▶"
NextBtn.TextColor3 = Color3.fromRGB(220,220,220)
NextBtn.TextSize = S(14)
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = Content
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(254))

-- ══════════════════════════════
--   SCAN TOGGLE
-- ══════════════════════════════
local ScanToggleBtn = Instance.new("TextButton")
ScanToggleBtn.Size = UDim2.new(1, -S(16), 0, S(26))
ScanToggleBtn.Position = UDim2.new(0, S(8), 0, S(260))
ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
ScanToggleBtn.BorderSizePixel = 0
ScanToggleBtn.Text = "🔍 Scan Menu : OFF"
ScanToggleBtn.TextColor3 = Color3.fromRGB(200,200,200)
ScanToggleBtn.TextSize = S(11)
ScanToggleBtn.Font = Enum.Font.GothamBold
ScanToggleBtn.Parent = Content
Instance.new("UICorner", ScanToggleBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(292))

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -S(16), 0, S(20))
StatusLabel.Position = UDim2.new(0, S(8), 0, S(297))
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● Idle"
StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
StatusLabel.TextSize = S(11)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Content

-- ══════════════════════════════
--   SCAN FRAME
-- ══════════════════════════════
local ScanFrame = Instance.new("Frame")
ScanFrame.Size = UDim2.new(0, SS(220), 0, SS(320))
ScanFrame.Position = UDim2.new(0.5, SS(120), 0.5, -SS(160))
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
MakeDraggable(ScanFrame, ScanTitleBar)

local ScanTitle = Instance.new("TextLabel")
ScanTitle.Size = UDim2.new(1, -SS(90), 1, 0)
ScanTitle.Position = UDim2.new(0, SS(8), 0, 0)
ScanTitle.BackgroundTransparency = 1
ScanTitle.Text = "🔍 Scan"
ScanTitle.TextColor3 = Color3.fromRGB(255,255,255)
ScanTitle.TextSize = SS(12)
ScanTitle.Font = Enum.Font.GothamBold
ScanTitle.TextXAlignment = Enum.TextXAlignment.Left
ScanTitle.Parent = ScanTitleBar

local ColorPickerBtn = Instance.new("TextButton")
ColorPickerBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ColorPickerBtn.Position = UDim2.new(1, -SS(56), 0.5, -SS(10))
ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(80,80,200)
ColorPickerBtn.BorderSizePixel = 0
ColorPickerBtn.Text = "🎨"
ColorPickerBtn.TextColor3 = Color3.fromRGB(255,255,255)
ColorPickerBtn.TextSize = SS(10)
ColorPickerBtn.Font = Enum.Font.GothamBold
ColorPickerBtn.Parent = ScanTitleBar
Instance.new("UICorner", ColorPickerBtn).CornerRadius = UDim.new(0,4)

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

local FilterBar = Instance.new("Frame")
FilterBar.Size = UDim2.new(1, -SS(16), 0, SS(22))
FilterBar.Position = UDim2.new(0, SS(8), 0, SS(30))
FilterBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
FilterBar.BorderSizePixel = 0
FilterBar.Parent = ScanFrame
Instance.new("UICorner", FilterBar).CornerRadius = UDim.new(0,5)

local FilterLabel = Instance.new("TextLabel")
FilterLabel.Size = UDim2.new(1, -SS(30), 1, 0)
FilterLabel.Position = UDim2.new(0, SS(6), 0, 0)
FilterLabel.BackgroundTransparency = 1
FilterLabel.Text = "🎨 Filter: ทั้งหมด"
FilterLabel.TextColor3 = Color3.fromRGB(160,160,160)
FilterLabel.TextSize = SS(9)
FilterLabel.Font = Enum.Font.Gotham
FilterLabel.TextXAlignment = Enum.TextXAlignment.Left
FilterLabel.Parent = FilterBar

local ClearFilterBtn = Instance.new("TextButton")
ClearFilterBtn.Size = UDim2.new(0, SS(24), 0, SS(18))
ClearFilterBtn.Position = UDim2.new(1, -SS(26), 0.5, -SS(9))
ClearFilterBtn.BackgroundColor3 = Color3.fromRGB(80,40,40)
ClearFilterBtn.BorderSizePixel = 0
ClearFilterBtn.Text = "✕"
ClearFilterBtn.TextColor3 = Color3.fromRGB(255,180,180)
ClearFilterBtn.TextSize = SS(9)
ClearFilterBtn.Font = Enum.Font.GothamBold
ClearFilterBtn.Parent = FilterBar
Instance.new("UICorner", ClearFilterBtn).CornerRadius = UDim.new(0,4)

local DoScanBtn = Instance.new("TextButton")
DoScanBtn.Size = UDim2.new(1, -SS(16), 0, SS(26))
DoScanBtn.Position = UDim2.new(0, SS(8), 0, SS(56))
DoScanBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
DoScanBtn.BorderSizePixel = 0
DoScanBtn.Text = "🔍 Scan Now"
DoScanBtn.TextColor3 = Color3.fromRGB(220,220,220)
DoScanBtn.TextSize = SS(11)
DoScanBtn.Font = Enum.Font.GothamBold
DoScanBtn.Parent = ScanFrame
Instance.new("UICorner", DoScanBtn).CornerRadius = UDim.new(0,6)

local ScanCountLabel = Instance.new("TextLabel")
ScanCountLabel.Size = UDim2.new(1, -SS(16), 0, SS(14))
ScanCountLabel.Position = UDim2.new(0, SS(8), 0, SS(84))
ScanCountLabel.BackgroundTransparency = 1
ScanCountLabel.Text = "0 found"
ScanCountLabel.TextColor3 = Color3.fromRGB(100,100,100)
ScanCountLabel.TextSize = SS(9)
ScanCountLabel.Font = Enum.Font.Gotham
ScanCountLabel.TextXAlignment = Enum.TextXAlignment.Left
ScanCountLabel.Parent = ScanFrame

local ScanScroll = Instance.new("ScrollingFrame")
ScanScroll.Size = UDim2.new(1, -SS(8), 1, -SS(100))
ScanScroll.Position = UDim2.new(0, SS(4), 0, SS(98))
ScanScroll.BackgroundTransparency = 1
ScanScroll.BorderSizePixel = 0
ScanScroll.ScrollBarThickness = 3
ScanScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
ScanScroll.CanvasSize = UDim2.new(0,0,0,0)
ScanScroll.Parent = ScanFrame

local ScanLayout = Instance.new("UIListLayout")
ScanLayout.Padding = UDim.new(0, SS(3))
ScanLayout.Parent = ScanScroll

-- ══════════════════════════════
--   COLOR PICKER POPUP
-- ══════════════════════════════
local ColorPopup = Instance.new("Frame")
ColorPopup.Size = UDim2.new(0, SS(200), 0, SS(220))
ColorPopup.Position = UDim2.new(0.5, SS(120), 0.5, SS(170))
ColorPopup.BackgroundColor3 = Color3.fromRGB(18,18,18)
ColorPopup.BorderSizePixel = 0
ColorPopup.ClipsDescendants = true
ColorPopup.Visible = false
ColorPopup.ZIndex = 10
ColorPopup.Parent = ScreenGui
Instance.new("UICorner", ColorPopup).CornerRadius = UDim.new(0,8)

local CPTitleBar = Instance.new("Frame")
CPTitleBar.Size = UDim2.new(1, 0, 0, SS(26))
CPTitleBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
CPTitleBar.BorderSizePixel = 0
CPTitleBar.ZIndex = 10
CPTitleBar.Parent = ColorPopup
MakeDraggable(ColorPopup, CPTitleBar)

local CPTitle = Instance.new("TextLabel")
CPTitle.Size = UDim2.new(1, -SS(30), 1, 0)
CPTitle.Position = UDim2.new(0, SS(8), 0, 0)
CPTitle.BackgroundTransparency = 1
CPTitle.Text = "🎨 เลือกสี Filter"
CPTitle.TextColor3 = Color3.fromRGB(255,255,255)
CPTitle.TextSize = SS(10)
CPTitle.Font = Enum.Font.GothamBold
CPTitle.TextXAlignment = Enum.TextXAlignment.Left
CPTitle.ZIndex = 10
CPTitle.Parent = CPTitleBar

local CPCloseBtn = Instance.new("TextButton")
CPCloseBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
CPCloseBtn.Position = UDim2.new(1, -SS(22), 0.5, -SS(10))
CPCloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CPCloseBtn.BorderSizePixel = 0
CPCloseBtn.Text = "✕"
CPCloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CPCloseBtn.TextSize = SS(10)
CPCloseBtn.Font = Enum.Font.GothamBold
CPCloseBtn.ZIndex = 10
CPCloseBtn.Parent = CPTitleBar
Instance.new("UICorner", CPCloseBtn).CornerRadius = UDim.new(0,4)

local CPNoColorBtn = Instance.new("TextButton")
CPNoColorBtn.Size = UDim2.new(1, -SS(16), 0, SS(22))
CPNoColorBtn.Position = UDim2.new(0, SS(8), 0, SS(30))
CPNoColorBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
CPNoColorBtn.BorderSizePixel = 0
CPNoColorBtn.Text = "✅ แสดงทั้งหมด (ไม่ filter)"
CPNoColorBtn.TextColor3 = Color3.fromRGB(200,200,200)
CPNoColorBtn.TextSize = SS(9)
CPNoColorBtn.Font = Enum.Font.GothamBold
CPNoColorBtn.ZIndex = 10
CPNoColorBtn.Parent = ColorPopup
Instance.new("UICorner", CPNoColorBtn).CornerRadius = UDim.new(0,5)

local CPScroll = Instance.new("ScrollingFrame")
CPScroll.Size = UDim2.new(1, -SS(8), 1, -SS(56))
CPScroll.Position = UDim2.new(0, SS(4), 0, SS(54))
CPScroll.BackgroundTransparency = 1
CPScroll.BorderSizePixel = 0
CPScroll.ScrollBarThickness = 3
CPScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
CPScroll.CanvasSize = UDim2.new(0,0,0,0)
CPScroll.ZIndex = 10
CPScroll.Parent = ColorPopup

local CPLayout = Instance.new("UIListLayout")
CPLayout.Padding = UDim.new(0, SS(3))
CPLayout.Parent = CPScroll

-- ══════════════════════════════
--   CORE FUNCTIONS (declare ก่อน connect)
-- ══════════════════════════════
local function GetTeamColor(model)
    local p = Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    local myTeam = LocalPlayer.Team
    if p and myTeam then
        if p.Team and p.Team == myTeam then return Color3.fromRGB(60,200,100)
        else return Color3.fromRGB(220,60,60) end
    end
    return Color3.fromRGB(220,120,50)
end

local function GetTargetList()
    local myHRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list  = {}
    local range = tonumber(RangeBox.Text) or Settings.LockRange

    if Settings.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist <= range then
                        table.insert(list, {model=p.Character, name=p.Name, dist=dist, color=GetTeamColor(p.Character)})
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character and not Players:GetPlayerFromCharacter(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                        or obj:FindFirstChild("RootPart")
                        or obj.PrimaryPart
                    if not hrp then
                        for _, part in ipairs(obj:GetChildren()) do
                            if part:IsA("BasePart") then hrp = part break end
                        end
                    end
                    if hrp then
                        local dist = (hrp.Position - myHRP.Position).Magnitude
                        if dist <= range then
                            table.insert(list, {model=obj, name=obj.Name, dist=dist, color=GetTeamColor(obj)})
                        end
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
    local out  = {}
    for _, e in ipairs(list) do
        if ColorToHex(e.color) == fHex then table.insert(out, e) end
    end
    return out
end

local function SetTarget(model)
    currentTarget = model
    if model then
        TargetLabel.Text = model.Name
        StatusLabel.Text = "🔒 " .. model.Name
        StatusLabel.TextColor3 = Color3.fromRGB(100,220,100)
    else
        TargetLabel.Text = "No Target"
        StatusLabel.Text = "● Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
    end
end

-- ══════════════════════════════
--   COLOR PICKER POPULATE
-- ══════════════════════════════
local function UpdateColorPicker()
    for _, c in ipairs(CPScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local count = 0
    for hexStr, col in pairs(foundColors) do
        count = count + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, SS(26))
        btn.BackgroundColor3 = col
        btn.BorderSizePixel = 0
        btn.Text = "  #" .. hexStr
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextSize = SS(9)
        btn.Font = Enum.Font.GothamBold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 11
        btn.Parent = CPScroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, SS(6))
        if Settings.FilterColor and ColorToHex(Settings.FilterColor) == hexStr then
            local outline = Instance.new("UIStroke")
            outline.Color = Color3.fromRGB(255,255,255)
            outline.Thickness = 2
            outline.Parent = btn
        end
        btn.Activated:Connect(function()
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
        local noData = Instance.new("TextLabel")
        noData.Size = UDim2.new(1, 0, 0, SS(30))
        noData.BackgroundTransparency = 1
        noData.Text = "Scan ก่อนเพื่อดูสี"
        noData.TextColor3 = Color3.fromRGB(120,120,120)
        noData.TextSize = SS(9)
        noData.Font = Enum.Font.Gotham
        noData.ZIndex = 11
        noData.Parent = CPScroll
    end
end

-- ══════════════════════════════
--   LOCK CORE (Third-Person)
-- ══════════════════════════════
local function StartLock()
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    local timer = 0

    lockConnection = RunService.RenderStepped:Connect(function(dt)
        -- ดึง character ล่าสุดเสมอ
        local myHRP = Character and Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local strength = tonumber(StrBox.Text) or Settings.LockStrength

        -- scan หาเป้า
        if not currentTarget or Settings.NearestMode then
            timer = timer + dt
            if timer >= SCAN_INTERVAL then
                timer = 0
                local raw      = GetTargetList()
                local filtered = FilterList(raw)
                targetList = filtered
                if #filtered > 0 then
                    if Settings.NearestMode or not currentTarget then
                        SetTarget(filtered[1].model)
                        targetIndex = 1
                    end
                end
            end
        end

        if currentTarget then
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local hum = currentTarget:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 or not currentTarget.Parent then
                SetTarget(nil)
                return
            end

            local myPos    = myHRP.Position
            local aimPos   = hrp.Position + Vector3.new(0, HEIGHT_OFFSET, 0)

            -- ทิศ XZ จาก ตัวละคร → เป้า
            local flatDiff = Vector3.new(aimPos.X - myPos.X, 0, aimPos.Z - myPos.Z)
            if flatDiff.Magnitude < 0.01 then return end
            local flatDir  = flatDiff.Unit

            -- คำนวณ position กล้อง: ถอยหลัง + ยกขึ้น
            local camPos   = myPos - flatDir * CAM_DISTANCE + Vector3.new(0, CAM_HEIGHT, 0)
            local goalCF   = CFrame.lookAt(camPos, aimPos)

            local safeDt   = math.min(dt, 0.05)
            local alpha    = 1 - (1 - strength) ^ (safeDt * 60)

            -- smooth กล้อง
            Camera.CFrame  = Camera.CFrame:Lerp(goalCF, alpha)

            -- หมุน HRP ตาม (ไม่กระตุก)
            local bodyGoal = CFrame.new(myPos) * CFrame.Angles(0, math.atan2(-flatDir.X, -flatDir.Z), 0)
            myHRP.CFrame   = myHRP.CFrame:Lerp(bodyGoal, alpha)
        end
    end)
end

local function StopLock()
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    SetTarget(nil)
end

-- ══════════════════════════════
--   CHARACTER RESPAWN
-- ══════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    c:WaitForChild("HumanoidRootPart")
    currentTarget = nil
    if Settings.Enabled then
        task.wait(0.5)
        StartLock()
    end
end)

-- ══════════════════════════════
--   BUTTON CONNECTIONS
-- ══════════════════════════════
ModePlayer.Activated:Connect(function()
    Settings.Mode = "Player"
    currentTarget = nil
    UpdateModeUI()
end)
ModeNPC.Activated:Connect(function()
    Settings.Mode = "NPC"
    currentTarget = nil
    UpdateModeUI()
end)

LockBtn.Activated:Connect(function()
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

NearBtn.Activated:Connect(function()
    Settings.NearestMode = not Settings.NearestMode
    NearBtn.Text = Settings.NearestMode and "📍 Nearest : ON" or "📍 Nearest : OFF"
    NearBtn.BackgroundColor3 = Settings.NearestMode and Color3.fromRGB(40,80,40) or Color3.fromRGB(35,35,35)
end)

PrevBtn.Activated:Connect(function()
    if #targetList == 0 then targetList = FilterList(GetTargetList()) end
    if #targetList > 0 then
        targetIndex = targetIndex - 1
        if targetIndex < 1 then targetIndex = #targetList end
        SetTarget(targetList[targetIndex].model)
    end
end)

NextBtn.Activated:Connect(function()
    if #targetList == 0 then targetList = FilterList(GetTargetList()) end
    if #targetList > 0 then
        targetIndex = targetIndex + 1
        if targetIndex > #targetList then targetIndex = 1 end
        SetTarget(targetList[targetIndex].model)
    end
end)

local minimized = false
MinBtn.Activated:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, S(220), 0, S(30)) or UDim2.new(0, S(220), 0, S(380))
end)

CloseBtn.Activated:Connect(function()
    StopLock()
    ScreenGui:Destroy()
end)

local scanVisible = false
ScanToggleBtn.Activated:Connect(function()
    scanVisible = not scanVisible
    ScanFrame.Visible = scanVisible
    ScanToggleBtn.Text = scanVisible and "🔍 Scan Menu : ON" or "🔍 Scan Menu : OFF"
    ScanToggleBtn.BackgroundColor3 = scanVisible and Color3.fromRGB(40,80,40) or Color3.fromRGB(35,35,35)
end)

ScanCloseBtn.Activated:Connect(function()
    scanVisible = false
    ScanFrame.Visible = false
    ColorPopup.Visible = false
    ScanToggleBtn.Text = "🔍 Scan Menu : OFF"
    ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
end)

local scanMin = false
ScanMinBtn.Activated:Connect(function()
    scanMin = not scanMin
    ScanScroll.Visible = not scanMin
    DoScanBtn.Visible = not scanMin
    ScanCountLabel.Visible = not scanMin
    FilterBar.Visible = not scanMin
    ScanFrame.Size = scanMin and UDim2.new(0, SS(220), 0, SS(28)) or UDim2.new(0, SS(220), 0, SS(320))
    if scanMin then ColorPopup.Visible = false end
end)

DoScanBtn.Activated:Connect(function()
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
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, SS(26))
        btn.BackgroundColor3 = Color3.fromRGB(22,22,22)
        btn.BorderSizePixel = 0
        btn.Text = string.format("  [%d] %s  %.0fm", i, entry.name, entry.dist)
        btn.TextColor3 = entry.color
        btn.TextSize = SS(9)
        btn.Font = Enum.Font.Gotham
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = ScanScroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, SS(6), 0, SS(6))
        dot.Position = UDim2.new(0, SS(4), 0.5, -SS(3))
        dot.BackgroundColor3 = entry.color
        dot.BorderSizePixel = 0
        dot.Parent = btn
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        btn.Activated:Connect(function()
            targetIndex = i
            SetTarget(entry.model)
        end)
    end
    ScanScroll.CanvasSize = UDim2.new(0, 0, 0, ScanLayout.AbsoluteContentSize.Y + SS(4))
    UpdateColorPicker()
end)

ColorPickerBtn.Activated:Connect(function()
    ColorPopup.Visible = not ColorPopup.Visible
    if ColorPopup.Visible then UpdateColorPicker() end
end)

CPCloseBtn.Activated:Connect(function()
    ColorPopup.Visible = false
end)

ClearFilterBtn.Activated:Connect(function()
    Settings.FilterColor = nil
    FilterLabel.Text = "🎨 Filter: ทั้งหมด"
    FilterLabel.TextColor3 = Color3.fromRGB(160,160,160)
    ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(80,80,200)
    UpdateColorPicker()
end)

CPNoColorBtn.Activated:Connect(function()
    Settings.FilterColor = nil
    FilterLabel.Text = "🎨 Filter: ทั้งหมด"
    FilterLabel.TextColor3 = Color3.fromRGB(160,160,160)
    ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(80,80,200)
    ColorPopup.Visible = false
    UpdateColorPicker()
end)
