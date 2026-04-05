-- Lock Menu v14 | All Features | Codex Android Compatible
-- Lock + Scan + ESP + Teleport + Color Exclude + Menu Lock

-- ══════════════════════════════
--   SERVICES
-- ══════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ══════════════════════════════
--   LOAD / SAVE (_G)
-- ══════════════════════════════
local _S = _G.LockMenuSave or {}

local Settings = {
    MenuSize      = 10,
    ScanMenuSize  = 10,
    LockStrength  = _S.LockStrength  or 0.3,
    LockRange     = _S.LockRange     or 100,
    Mode          = _S.Mode          or "NPC",
    Enabled       = false,
    NearestMode   = _S.NearestMode   or false,
    FilterColor   = nil,
    ESPEnabled    = false,
    ExcludeColors = {},  -- สีที่ไม่ต้องการล็อค
}

local HEIGHT_OFFSET  = _S.HEIGHT_OFFSET or 1.5
local CAM_DISTANCE   = _S.CAM_DISTANCE  or 15
local CAM_HEIGHT     = 3
local SCAN_INTERVAL  = 0.1

local function SaveSettings()
    _G.LockMenuSave = {
        LockStrength  = Settings.LockStrength,
        LockRange     = Settings.LockRange,
        Mode          = Settings.Mode,
        NearestMode   = Settings.NearestMode,
        HEIGHT_OFFSET = HEIGHT_OFFSET,
        CAM_DISTANCE  = CAM_DISTANCE,
    }
end

-- ══════════════════════════════
--   STATE
-- ══════════════════════════════
local Character      = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local currentTarget  = nil
local targetList     = {}
local targetIndex    = 1
local lockConnection = nil
local espConnection  = nil
local foundColors    = {}
local forceRescan    = false
local espBoxes       = {}  -- { model = billboardGui }
local tpSaves        = {}
local tpSelected     = nil
local clickTP        = false
local lockPos        = nil

-- ══════════════════════════════
--   GUI CLEANUP
-- ══════════════════════════════
pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("LockMenu_v14")
        if old then old:Destroy() end
    end
end)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockMenu_v14"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- ══════════════════════════════
--   SCALE HELPERS
-- ══════════════════════════════
local function S(n)  return n * (Settings.MenuSize / 10) end
local function SS(n) return n * (Settings.ScanMenuSize / 10) end

local function ColorToHex(c)
    return string.format("%02X%02X%02X",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

-- ══════════════════════════════
--   DRAG HELPER
-- ══════════════════════════════
local function MakeDraggable(frame, handle, lockRef)
    -- lockRef = function ที่ return bool ว่าล็อคอยู่มั้ย
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if lockRef and lockRef() then return end
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
local function MakeFrame(parent, size, pos, color, clip)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color or Color3.fromRGB(15,15,15)
    f.BorderSizePixel = 0
    if clip then f.ClipsDescendants = true end
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)
    return f
end

local function MakeLabel(parent, text, size, pos, textSize, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(200,200,200)
    l.TextSize = textSize or S(11)
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function MakeBtn(parent, text, size, pos, bg, textColor, textSize)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bg or Color3.fromRGB(35,35,35)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = textColor or Color3.fromRGB(220,220,220)
    b.TextSize = textSize or S(11)
    b.Font = Enum.Font.GothamBold
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local function MakeInput(parent, default, size, pos)
    local box = Instance.new("TextBox")
    box.Size = size
    box.Position = pos
    box.BackgroundColor3 = Color3.fromRGB(25,25,25)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.PlaceholderColor3 = Color3.fromRGB(80,80,80)
    box.TextSize = S(11)
    box.Font = Enum.Font.Gotham
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)
    return box
end

local function Divider(parent, yPos)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -S(16), 0, 1)
    d.Position = UDim2.new(0, S(8), 0, yPos)
    d.BackgroundColor3 = Color3.fromRGB(45,45,45)
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function SmLabel(parent, text, y, x, w)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, S(w or 100), 0, S(13))
    l.Position = UDim2.new(0, S(x), 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(130,130,130)
    l.TextSize = S(9)
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- ══════════════════════════════
--   MAIN FRAME
-- ══════════════════════════════
local menuLocked = false
local MainFrame = MakeFrame(ScreenGui,
    UDim2.new(0, S(230), 0, S(420)),
    UDim2.new(0.5, -S(115), 0.5, -S(210)),
    Color3.fromRGB(12,12,12), true)

-- gradient บน frame
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,  Color3.fromRGB(20,20,28)),
    ColorSequenceKeypoint.new(1,  Color3.fromRGB(10,10,15)),
})
grad.Rotation = 90
grad.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, S(32))
TitleBar.BackgroundColor3 = Color3.fromRGB(22,22,32)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,8)

MakeDraggable(MainFrame, TitleBar, function() return menuLocked end)

-- accent line under title
local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 2)
accent.Position = UDim2.new(0, 0, 1, -2)
accent.BackgroundColor3 = Color3.fromRGB(80,120,255)
accent.BorderSizePixel = 0
accent.Parent = TitleBar

local TitleLabel = MakeLabel(TitleBar, "⚔  Lock Menu  v14",
    UDim2.new(1, -S(100), 1, 0), UDim2.new(0, S(10), 0, 0),
    S(12), Color3.fromRGB(255,255,255), Enum.Font.GothamBold)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ปุ่ม lock menu
local LockMenuBtn = MakeBtn(TitleBar, "🔓", UDim2.new(0,S(22),0,S(22)),
    UDim2.new(1,-S(72),0.5,-S(11)), Color3.fromRGB(50,50,70), Color3.fromRGB(200,200,255), S(12))

-- minimize
local MinBtn = MakeBtn(TitleBar, "–", UDim2.new(0,S(22),0,S(22)),
    UDim2.new(1,-S(48),0.5,-S(11)), Color3.fromRGB(50,50,50), Color3.fromRGB(255,255,255), S(14))

-- close
local CloseBtn = MakeBtn(TitleBar, "✕", UDim2.new(0,S(22),0,S(22)),
    UDim2.new(1,-S(24),0.5,-S(11)), Color3.fromRGB(180,40,40), Color3.fromRGB(255,255,255), S(12))

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -S(32))
Content.Position = UDim2.new(0, 0, 0, S(32))
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ══════════════════════════════
--   SECTION: MODE
-- ══════════════════════════════
SmLabel(Content, "🎯  MODE", S(8), 8)

local ModePlayer = MakeBtn(Content, "👤 Player",
    UDim2.new(0,S(99),0,S(26)), UDim2.new(0,S(8),0,S(22)),
    Color3.fromRGB(35,35,50), Color3.fromRGB(160,160,200))
local ModeNPC = MakeBtn(Content, "🤖 NPC",
    UDim2.new(0,S(99),0,S(26)), UDim2.new(0,S(114),0,S(22)),
    Color3.fromRGB(80,120,255), Color3.fromRGB(255,255,255))

local function UpdateModeUI()
    if Settings.Mode == "Player" then
        ModePlayer.BackgroundColor3 = Color3.fromRGB(80,120,255)
        ModePlayer.TextColor3 = Color3.fromRGB(255,255,255)
        ModeNPC.BackgroundColor3 = Color3.fromRGB(35,35,50)
        ModeNPC.TextColor3 = Color3.fromRGB(160,160,200)
    else
        ModeNPC.BackgroundColor3 = Color3.fromRGB(80,120,255)
        ModeNPC.TextColor3 = Color3.fromRGB(255,255,255)
        ModePlayer.BackgroundColor3 = Color3.fromRGB(35,35,50)
        ModePlayer.TextColor3 = Color3.fromRGB(160,160,200)
    end
end
UpdateModeUI()

Divider(Content, S(55))

-- ══════════════════════════════
--   SECTION: STRENGTH / RANGE
-- ══════════════════════════════
SmLabel(Content, "⚡ Strength", S(59), 8)
SmLabel(Content, "📏 Range", S(59), 120)
local StrBox   = MakeInput(Content, Settings.LockStrength,
    UDim2.new(0,S(96),0,S(24)), UDim2.new(0,S(8),0,S(72)))
local RangeBox = MakeInput(Content, Settings.LockRange,
    UDim2.new(0,S(96),0,S(24)), UDim2.new(0,S(120),0,S(72)))

Divider(Content, S(103))

-- ══════════════════════════════
--   SECTION: HEIGHT / CAM DIST
-- ══════════════════════════════
SmLabel(Content, "⬆ Height Offset", S(107), 8)
SmLabel(Content, "📷 Cam Dist", S(107), 120)
local HeightBox  = MakeInput(Content, HEIGHT_OFFSET,
    UDim2.new(0,S(96),0,S(24)), UDim2.new(0,S(8),0,S(120)))
local CamDistBox = MakeInput(Content, CAM_DISTANCE,
    UDim2.new(0,S(96),0,S(24)), UDim2.new(0,S(120),0,S(120)))

Divider(Content, S(151))

-- ══════════════════════════════
--   SECTION: LOCK BUTTON
-- ══════════════════════════════
local LockBtn = MakeBtn(Content, "🔓 Lock : OFF",
    UDim2.new(1,-S(16),0,S(28)), UDim2.new(0,S(8),0,S(157)),
    Color3.fromRGB(30,30,45), Color3.fromRGB(200,200,255), S(12))

local NearBtn = MakeBtn(Content, "📍 Nearest : OFF",
    UDim2.new(1,-S(16),0,S(26)), UDim2.new(0,S(8),0,S(191)),
    Color3.fromRGB(30,30,45), Color3.fromRGB(180,180,220), S(11))

-- ══════════════════════════════
--   SECTION: PREV/TARGET/NEXT
-- ══════════════════════════════
local PrevBtn = MakeBtn(Content, "◀",
    UDim2.new(0,S(40),0,S(26)), UDim2.new(0,S(8),0,S(223)),
    Color3.fromRGB(35,35,55), Color3.fromRGB(200,200,255), S(13))
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(0,S(118),0,S(26))
TargetLabel.Position = UDim2.new(0,S(52),0,S(223))
TargetLabel.BackgroundColor3 = Color3.fromRGB(20,20,30)
TargetLabel.BorderSizePixel = 0
TargetLabel.Text = "No Target"
TargetLabel.TextColor3 = Color3.fromRGB(160,200,255)
TargetLabel.TextSize = S(10)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
TargetLabel.Parent = Content
Instance.new("UICorner", TargetLabel).CornerRadius = UDim.new(0,5)

local NextBtn = MakeBtn(Content, "▶",
    UDim2.new(0,S(40),0,S(26)), UDim2.new(0,S(174),0,S(223)),
    Color3.fromRGB(35,35,55), Color3.fromRGB(200,200,255), S(13))

Divider(Content, S(256))

-- ══════════════════════════════
--   SECTION: FEATURE BUTTONS ROW
-- ══════════════════════════════
-- ESP Toggle
local ESPBtn = MakeBtn(Content, "👁 ESP : OFF",
    UDim2.new(0,S(99),0,S(26)), UDim2.new(0,S(8),0,S(262)),
    Color3.fromRGB(30,30,45), Color3.fromRGB(180,180,220), S(10))

-- Scan Menu Toggle
local ScanToggleBtn = MakeBtn(Content, "🔍 Scan",
    UDim2.new(0,S(57),0,S(26)), UDim2.new(0,S(114),0,S(262)),
    Color3.fromRGB(30,30,45), Color3.fromRGB(180,180,220), S(10))

-- TP Menu Toggle
local TPToggleBtn = MakeBtn(Content, "🚀 TP",
    UDim2.new(0,S(38),0,S(26)), UDim2.new(0,S(178),0,S(262)),
    Color3.fromRGB(30,30,45), Color3.fromRGB(180,180,220), S(10))

Divider(Content, S(295))

-- Status
local StatusLabel = MakeLabel(Content, "● Idle",
    UDim2.new(1,-S(16),0,S(20)), UDim2.new(0,S(8),0,S(300)),
    S(10), Color3.fromRGB(100,100,130), Enum.Font.Gotham)

-- ══════════════════════════════
--   SCAN FRAME
-- ══════════════════════════════
local ScanFrame = MakeFrame(ScreenGui,
    UDim2.new(0,SS(220),0,SS(340)),
    UDim2.new(0.5,SS(125),0.5,-SS(170)),
    Color3.fromRGB(12,12,18), true)
ScanFrame.Visible = false

local ScanTitleBar = Instance.new("Frame")
ScanTitleBar.Size = UDim2.new(1,0,0,SS(30))
ScanTitleBar.BackgroundColor3 = Color3.fromRGB(22,22,32)
ScanTitleBar.BorderSizePixel = 0
ScanTitleBar.Parent = ScanFrame
Instance.new("UICorner", ScanTitleBar).CornerRadius = UDim.new(0,8)
MakeDraggable(ScanFrame, ScanTitleBar, nil)

local scanAccent = Instance.new("Frame")
scanAccent.Size = UDim2.new(1,0,0,2)
scanAccent.Position = UDim2.new(0,0,1,-2)
scanAccent.BackgroundColor3 = Color3.fromRGB(80,120,255)
scanAccent.BorderSizePixel = 0
scanAccent.Parent = ScanTitleBar

MakeLabel(ScanTitleBar, "🔍  Scan",
    UDim2.new(1,-SS(110),1,0), UDim2.new(0,SS(8),0,0),
    SS(12), Color3.fromRGB(255,255,255), Enum.Font.GothamBold)

-- Color Picker btn
local ColorPickerBtn = MakeBtn(ScanTitleBar, "🎨",
    UDim2.new(0,SS(22),0,SS(22)), UDim2.new(1,-SS(90),0.5,-SS(11)),
    Color3.fromRGB(60,60,180), Color3.fromRGB(255,255,255), SS(11))

-- Exclude Color btn
local ExcludeBtn = MakeBtn(ScanTitleBar, "🚫",
    UDim2.new(0,SS(22),0,SS(22)), UDim2.new(1,-SS(66),0.5,-SS(11)),
    Color3.fromRGB(100,40,40), Color3.fromRGB(255,180,180), SS(11))

local ScanMinBtn = MakeBtn(ScanTitleBar, "–",
    UDim2.new(0,SS(20),0,SS(20)), UDim2.new(1,-SS(42),0.5,-SS(10)),
    Color3.fromRGB(50,50,50), Color3.fromRGB(255,255,255), SS(12))

local ScanCloseBtn = MakeBtn(ScanTitleBar, "✕",
    UDim2.new(0,SS(20),0,SS(20)), UDim2.new(1,-SS(20),0.5,-SS(10)),
    Color3.fromRGB(180,40,40), Color3.fromRGB(255,255,255), SS(10))

-- Filter bar
local FilterBar = Instance.new("Frame")
FilterBar.Size = UDim2.new(1,-SS(16),0,SS(22))
FilterBar.Position = UDim2.new(0,SS(8),0,SS(32))
FilterBar.BackgroundColor3 = Color3.fromRGB(18,18,28)
FilterBar.BorderSizePixel = 0
FilterBar.Parent = ScanFrame
Instance.new("UICorner", FilterBar).CornerRadius = UDim.new(0,5)

local FilterLabel = MakeLabel(FilterBar, "🎨 Filter: ทั้งหมด",
    UDim2.new(1,-SS(30),1,0), UDim2.new(0,SS(6),0,0),
    SS(9), Color3.fromRGB(140,140,180), Enum.Font.Gotham)

local ClearFilterBtn = MakeBtn(FilterBar, "✕",
    UDim2.new(0,SS(22),0,SS(16)), UDim2.new(1,-SS(24),0.5,-SS(8)),
    Color3.fromRGB(70,30,30), Color3.fromRGB(255,160,160), SS(9))

-- Exclude bar
local ExcludeBar = Instance.new("Frame")
ExcludeBar.Size = UDim2.new(1,-SS(16),0,SS(22))
ExcludeBar.Position = UDim2.new(0,SS(8),0,SS(56))
ExcludeBar.BackgroundColor3 = Color3.fromRGB(22,14,14)
ExcludeBar.BorderSizePixel = 0
ExcludeBar.Parent = ScanFrame
Instance.new("UICorner", ExcludeBar).CornerRadius = UDim.new(0,5)

local ExcludeLabel = MakeLabel(ExcludeBar, "🚫 Exclude: ไม่มี",
    UDim2.new(1,-SS(30),1,0), UDim2.new(0,SS(6),0,0),
    SS(9), Color3.fromRGB(180,120,120), Enum.Font.Gotham)

local ClearExcludeBtn = MakeBtn(ExcludeBar, "✕",
    UDim2.new(0,SS(22),0,SS(16)), UDim2.new(1,-SS(24),0.5,-SS(8)),
    Color3.fromRGB(70,30,30), Color3.fromRGB(255,160,160), SS(9))

local DoScanBtn = MakeBtn(ScanFrame, "🔍 Scan Now",
    UDim2.new(1,-SS(16),0,SS(26)), UDim2.new(0,SS(8),0,SS(80)),
    Color3.fromRGB(40,40,80), Color3.fromRGB(200,200,255), SS(11))

local ScanCountLabel = MakeLabel(ScanFrame, "0 found",
    UDim2.new(1,-SS(16),0,SS(14)), UDim2.new(0,SS(8),0,SS(108)),
    SS(9), Color3.fromRGB(90,90,130), Enum.Font.Gotham)

local ScanScroll = Instance.new("ScrollingFrame")
ScanScroll.Size = UDim2.new(1,-SS(8),1,-SS(125))
ScanScroll.Position = UDim2.new(0,SS(4),0,SS(124))
ScanScroll.BackgroundTransparency = 1
ScanScroll.BorderSizePixel = 0
ScanScroll.ScrollBarThickness = 3
ScanScroll.ScrollBarImageColor3 = Color3.fromRGB(60,60,100)
ScanScroll.CanvasSize = UDim2.new(0,0,0,0)
ScanScroll.Parent = ScanFrame

local ScanLayout = Instance.new("UIListLayout")
ScanLayout.Padding = UDim.new(0,SS(3))
ScanLayout.Parent = ScanScroll

-- ══════════════════════════════
--   COLOR PICKER POPUP
-- ══════════════════════════════
local ColorPopup = MakeFrame(ScreenGui,
    UDim2.new(0,SS(200),0,SS(230)),
    UDim2.new(0.5,SS(125),0.5,SS(175)),
    Color3.fromRGB(14,14,22), true)
ColorPopup.Visible = false
ColorPopup.ZIndex = 10

local CPTitleBar = Instance.new("Frame")
CPTitleBar.Size = UDim2.new(1,0,0,SS(28))
CPTitleBar.BackgroundColor3 = Color3.fromRGB(22,22,32)
CPTitleBar.BorderSizePixel = 0
CPTitleBar.ZIndex = 10
CPTitleBar.Parent = ColorPopup
Instance.new("UICorner", CPTitleBar).CornerRadius = UDim.new(0,8)
MakeDraggable(ColorPopup, CPTitleBar, nil)

MakeLabel(CPTitleBar, "🎨 Filter Color",
    UDim2.new(1,-SS(30),1,0), UDim2.new(0,SS(8),0,0),
    SS(10), Color3.fromRGB(255,255,255), Enum.Font.GothamBold)

local CPCloseBtn = MakeBtn(CPTitleBar, "✕",
    UDim2.new(0,SS(20),0,SS(20)), UDim2.new(1,-SS(22),0.5,-SS(10)),
    Color3.fromRGB(180,40,40), Color3.fromRGB(255,255,255), SS(10))
CPCloseBtn.ZIndex = 10

local CPNoColorBtn = MakeBtn(ColorPopup, "✅ แสดงทั้งหมด",
    UDim2.new(1,-SS(16),0,SS(22)), UDim2.new(0,SS(8),0,SS(30)),
    Color3.fromRGB(35,50,35), Color3.fromRGB(180,255,180), SS(9))
CPNoColorBtn.ZIndex = 10

local CPScroll = Instance.new("ScrollingFrame")
CPScroll.Size = UDim2.new(1,-SS(8),1,-SS(56))
CPScroll.Position = UDim2.new(0,SS(4),0,SS(54))
CPScroll.BackgroundTransparency = 1
CPScroll.BorderSizePixel = 0
CPScroll.ScrollBarThickness = 3
CPScroll.ScrollBarImageColor3 = Color3.fromRGB(60,60,100)
CPScroll.CanvasSize = UDim2.new(0,0,0,0)
CPScroll.ZIndex = 10
CPScroll.Parent = ColorPopup

local CPLayout = Instance.new("UIListLayout")
CPLayout.Padding = UDim.new(0,SS(3))
CPLayout.Parent = CPScroll

-- ══════════════════════════════
--   EXCLUDE COLOR POPUP
-- ══════════════════════════════
local ExcludePopup = MakeFrame(ScreenGui,
    UDim2.new(0,SS(200),0,SS(260)),
    UDim2.new(0.5,SS(125),0.5,SS(175)),
    Color3.fromRGB(18,10,10), true)
ExcludePopup.Visible = false
ExcludePopup.ZIndex = 10

local EPTitleBar = Instance.new("Frame")
EPTitleBar.Size = UDim2.new(1,0,0,SS(28))
EPTitleBar.BackgroundColor3 = Color3.fromRGB(28,16,16)
EPTitleBar.BorderSizePixel = 0
EPTitleBar.ZIndex = 10
EPTitleBar.Parent = ExcludePopup
Instance.new("UICorner", EPTitleBar).CornerRadius = UDim.new(0,8)
MakeDraggable(ExcludePopup, EPTitleBar, nil)

MakeLabel(EPTitleBar, "🚫 Exclude Color",
    UDim2.new(1,-SS(30),1,0), UDim2.new(0,SS(8),0,0),
    SS(10), Color3.fromRGB(255,200,200), Enum.Font.GothamBold)

local EPCloseBtn = MakeBtn(EPTitleBar, "✕",
    UDim2.new(0,SS(20),0,SS(20)), UDim2.new(1,-SS(22),0.5,-SS(10)),
    Color3.fromRGB(180,40,40), Color3.fromRGB(255,255,255), SS(10))
EPCloseBtn.ZIndex = 10

local EPSelectingLabel = MakeLabel(ExcludePopup,
    "กดเลือกสีที่ไม่ต้องการล็อค",
    UDim2.new(1,-SS(16),0,SS(22)), UDim2.new(0,SS(8),0,SS(30)),
    SS(9), Color3.fromRGB(200,160,160), Enum.Font.Gotham)
EPSelectingLabel.ZIndex = 10
EPSelectingLabel.TextWrapped = true

local EPOKBtn = MakeBtn(ExcludePopup, "✅ OK",
    UDim2.new(1,-SS(16),0,SS(22)), UDim2.new(0,SS(8),0,SS(54)),
    Color3.fromRGB(35,60,35), Color3.fromRGB(180,255,180), SS(9))
EPOKBtn.ZIndex = 10

local EPScroll = Instance.new("ScrollingFrame")
EPScroll.Size = UDim2.new(1,-SS(8),1,-SS(82))
EPScroll.Position = UDim2.new(0,SS(4),0,SS(80))
EPScroll.BackgroundTransparency = 1
EPScroll.BorderSizePixel = 0
EPScroll.ScrollBarThickness = 3
EPScroll.CanvasSize = UDim2.new(0,0,0,0)
EPScroll.ZIndex = 10
EPScroll.Parent = ExcludePopup

local EPLayout = Instance.new("UIListLayout")
EPLayout.Padding = UDim.new(0,SS(3))
EPLayout.Parent = EPScroll

-- ══════════════════════════════
--   TELEPORT FRAME
-- ══════════════════════════════
local TPFrame = MakeFrame(ScreenGui,
    UDim2.new(0,210,0,260),
    UDim2.new(0.5,-340,0.5,-130),
    Color3.fromRGB(12,12,18), true)
TPFrame.Visible = false

local TPTitleBar = Instance.new("Frame")
TPTitleBar.Size = UDim2.new(1,0,0,30)
TPTitleBar.BackgroundColor3 = Color3.fromRGB(22,22,32)
TPTitleBar.BorderSizePixel = 0
TPTitleBar.Parent = TPFrame
Instance.new("UICorner", TPTitleBar).CornerRadius = UDim.new(0,8)
MakeDraggable(TPFrame, TPTitleBar, nil)

local tpAccent = Instance.new("Frame")
tpAccent.Size = UDim2.new(1,0,0,2)
tpAccent.Position = UDim2.new(0,0,1,-2)
tpAccent.BackgroundColor3 = Color3.fromRGB(80,200,120)
tpAccent.BorderSizePixel = 0
tpAccent.Parent = TPTitleBar

MakeLabel(TPTitleBar, "🚀  Teleport Save",
    UDim2.new(1,-90,1,0), UDim2.new(0,10,0,0),
    13, Color3.fromRGB(255,255,255), Enum.Font.GothamBold)

local TPMinBtn = MakeBtn(TPTitleBar, "–", UDim2.new(0,22,0,22),
    UDim2.new(1,-46,0.5,-11), Color3.fromRGB(50,50,50), Color3.fromRGB(255,255,255), 13)
local TPCloseBtn = MakeBtn(TPTitleBar, "✕", UDim2.new(0,22,0,22),
    UDim2.new(1,-23,0.5,-11), Color3.fromRGB(180,40,40), Color3.fromRGB(255,255,255), 12)

-- TP buttons row
local TPSaveBtn = MakeBtn(TPFrame, "+ Save", UDim2.new(0,63,0,28),
    UDim2.new(0,5,0,33), Color3.fromRGB(30,90,30), Color3.fromRGB(180,255,180), 11)
local TPClickBtn = MakeBtn(TPFrame, "Click TP OFF", UDim2.new(0,72,0,28),
    UDim2.new(0,71,0,33), Color3.fromRGB(150,40,40), Color3.fromRGB(255,180,180), 10)
local TPDeleteBtn = MakeBtn(TPFrame, "Delete", UDim2.new(0,57,0,28),
    UDim2.new(0,147,0,33), Color3.fromRGB(80,30,30), Color3.fromRGB(255,160,160), 11)

local TPScroll = Instance.new("ScrollingFrame")
TPScroll.Size = UDim2.new(1,-10,1,-70)
TPScroll.Position = UDim2.new(0,5,0,65)
TPScroll.BackgroundColor3 = Color3.fromRGB(16,16,24)
TPScroll.BorderSizePixel = 0
TPScroll.ScrollBarThickness = 3
TPScroll.ScrollBarImageColor3 = Color3.fromRGB(60,60,100)
TPScroll.CanvasSize = UDim2.new(0,0,0,0)
TPScroll.Parent = TPFrame
Instance.new("UICorner", TPScroll).CornerRadius = UDim.new(0,5)

local TPLayout = Instance.new("UIListLayout")
TPLayout.Padding = UDim.new(0,4)
TPLayout.Parent = TPScroll

-- ══════════════════════════════
--   CORE FUNCTIONS
-- ══════════════════════════════
local function GetTeamColor(model)
    local p = Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    if p then
        local myTeam = LocalPlayer.Team
        if myTeam and p.Team then
            return p.Team == myTeam and Color3.fromRGB(60,200,100) or Color3.fromRGB(220,60,60)
        end
    end
    return Color3.fromRGB(220,120,50)
end

local function IsExcluded(color)
    local hex = ColorToHex(color)
    for _, exHex in ipairs(Settings.ExcludeColors) do
        if exHex == hex then return true end
    end
    return false
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
                        local col = GetTeamColor(p.Character)
                        if not IsExcluded(col) then
                            table.insert(list, {model=p.Character, name=p.Name, dist=dist, color=col})
                        end
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
                            local col = GetTeamColor(obj)
                            if not IsExcluded(col) then
                                table.insert(list, {model=obj, name=obj.Name, dist=dist, color=col})
                            end
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
        StatusLabel.TextColor3 = Color3.fromRGB(100,200,255)
    else
        TargetLabel.Text = "No Target"
        StatusLabel.Text = "● Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(80,80,110)
    end
end

-- ══════════════════════════════
--   ESP SYSTEM
-- ══════════════════════════════
local function ClearESP()
    for model, bb in pairs(espBoxes) do
        pcall(function() bb:Destroy() end)
    end
    espBoxes = {}
end

local function UpdateESP()
    if not Settings.ESPEnabled then ClearESP() return end
    local myHRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local range   = tonumber(RangeBox.Text) or Settings.LockRange
    local active  = {}

    local list = GetTargetList()
    for _, entry in ipairs(list) do
        local model = entry.model
        active[model] = true

        local hrp = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("RootPart")
            or model.PrimaryPart
        if not hrp then
            for _, part in ipairs(model:GetChildren()) do
                if part:IsA("BasePart") then hrp = part break end
            end
        end
        if not hrp then continue end

        if not espBoxes[model] then
            -- สร้าง BillboardGui
            local bb = Instance.new("BillboardGui")
            bb.Name = "ESP_Box"
            bb.Adornee = hrp
            bb.Size = UDim2.new(0, 4, 0, 5)  -- scale กับ dist
            bb.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
            bb.AlwaysOnTop = true
            bb.LightInfluence = 0
            bb.Parent = hrp

            -- กรอบสีขาว
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundTransparency = 1
            frame.BorderSizePixel = 0
            frame.Parent = bb

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Thickness = 1.5
            stroke.Parent = frame

            -- label ระยะ
            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistLabel"
            distLabel.Size = UDim2.new(1, 0, 0, 20)
            distLabel.Position = UDim2.new(0, 0, 1, 2)
            distLabel.BackgroundTransparency = 1
            distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            distLabel.TextSize = 11
            distLabel.Font = Enum.Font.GothamBold
            distLabel.Text = "0m"
            distLabel.Parent = bb

            espBoxes[model] = bb
        end

        -- อัป dist และ size ตาม distance
        local dist  = entry.dist
        local scale = math.clamp(60 / math.max(dist, 1), 1.5, 8)
        espBoxes[model].Size = UDim2.new(0, scale * 1.2, 0, scale * 1.8)

        local dl = espBoxes[model]:FindFirstChild("DistLabel")
        if dl then dl.Text = string.format("%.0fm", dist) end
    end

    -- ลบ ESP ที่ไม่อยู่ใน range แล้ว
    for model, bb in pairs(espBoxes) do
        if not active[model] then
            pcall(function() bb:Destroy() end)
            espBoxes[model] = nil
        end
    end
end

-- ══════════════════════════════
--   COLOR PICKER
-- ══════════════════════════════
local function UpdateColorPicker()
    for _, c in ipairs(CPScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local count = 0
    for hexStr, col in pairs(foundColors) do
        count = count + 1
        local btn = MakeBtn(CPScroll, "  #"..hexStr,
            UDim2.new(1,0,0,SS(26)), UDim2.new(0,0,0,0),
            col, Color3.fromRGB(255,255,255), SS(9))
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 11
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0,SS(8))
        if Settings.FilterColor and ColorToHex(Settings.FilterColor) == hexStr then
            local s = Instance.new("UIStroke")
            s.Color = Color3.fromRGB(255,255,255)
            s.Thickness = 2
            s.Parent = btn
        end
        btn.MouseButton1Click:Connect(function()
            Settings.FilterColor = col
            FilterLabel.Text = "🎨 #"..hexStr
            FilterLabel.TextColor3 = col
            ColorPickerBtn.BackgroundColor3 = col
            ColorPopup.Visible = false
            UpdateColorPicker()
        end)
    end
    CPScroll.CanvasSize = UDim2.new(0,0,0,CPLayout.AbsoluteContentSize.Y + SS(4))
    if count == 0 then
        local l = MakeLabel(CPScroll, "Scan ก่อน",
            UDim2.new(1,0,0,SS(30)), UDim2.new(0,0,0,0), SS(9),
            Color3.fromRGB(100,100,130))
        l.ZIndex = 11
    end
end

-- ══════════════════════════════
--   EXCLUDE PICKER
-- ══════════════════════════════
local pendingExcludes = {}  -- hex ที่เลือกไว้ก่อน OK

local function UpdateExcludePicker()
    for _, c in ipairs(EPScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local count = 0
    for hexStr, col in pairs(foundColors) do
        count = count + 1
        local isPending = false
        for _, h in ipairs(pendingExcludes) do
            if h == hexStr then isPending = true break end
        end
        local btn = MakeBtn(EPScroll,
            (isPending and "✓ " or "  ").."#"..hexStr,
            UDim2.new(1,0,0,SS(26)), UDim2.new(0,0,0,0),
            isPending and Color3.fromRGB(100,40,40) or col,
            Color3.fromRGB(255,255,255), SS(9))
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 11
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0,SS(8))

        btn.MouseButton1Click:Connect(function()
            local found = false
            for i, h in ipairs(pendingExcludes) do
                if h == hexStr then
                    table.remove(pendingExcludes, i)
                    found = true
                    break
                end
            end
            if not found then
                table.insert(pendingExcludes, hexStr)
            end
            UpdateExcludePicker()
        end)
    end
    EPScroll.CanvasSize = UDim2.new(0,0,0,EPLayout.AbsoluteContentSize.Y + SS(4))
    if count == 0 then
        local l = MakeLabel(EPScroll, "Scan ก่อน",
            UDim2.new(1,0,0,SS(30)), UDim2.new(0,0,0,0),
            SS(9), Color3.fromRGB(130,80,80))
        l.ZIndex = 11
    end

    -- update label
    if #Settings.ExcludeColors > 0 then
        ExcludeLabel.Text = "🚫 Exclude: "..#Settings.ExcludeColors.." สี"
        ExcludeLabel.TextColor3 = Color3.fromRGB(255,140,140)
    else
        ExcludeLabel.Text = "🚫 Exclude: ไม่มี"
        ExcludeLabel.TextColor3 = Color3.fromRGB(180,120,120)
    end
end

-- ══════════════════════════════
--   LOCK CORE
-- ══════════════════════════════
local function StartLock()
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    local timer = 0

    lockConnection = RunService.Heartbeat:Connect(function(dt)
        local myHRP = Character and Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local strength = tonumber(StrBox.Text) or Settings.LockStrength
        if not strength or strength <= 0 then strength = 0.3 end

        -- detect เป้าตาย → scan ทันที
        if currentTarget then
            local hum = currentTarget:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 or not currentTarget.Parent then
                SetTarget(nil)
                forceRescan = true
            end
        end

        -- scan
        if not currentTarget or Settings.NearestMode or forceRescan then
            timer = timer + dt
            if forceRescan or timer >= SCAN_INTERVAL then
                timer = 0
                forceRescan = false
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

        if not currentTarget then return end

        local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            or currentTarget:FindFirstChild("RootPart")
            or currentTarget.PrimaryPart
        if not hrp then
            for _, part in ipairs(currentTarget:GetChildren()) do
                if part:IsA("BasePart") then hrp = part break end
            end
        end
        local hum = currentTarget:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 or not currentTarget.Parent then
            SetTarget(nil)
            forceRescan = true
            return
        end

        local myPos   = myHRP.Position
        local aimPos  = hrp.Position + Vector3.new(0, HEIGHT_OFFSET, 0)
        local diff    = Vector3.new(aimPos.X-myPos.X, 0, aimPos.Z-myPos.Z)
        if diff.Magnitude < 0.01 then return end
        local dir     = diff.Unit

        local camPos  = myPos - dir * CAM_DISTANCE + Vector3.new(0, CAM_HEIGHT, 0)
        local goalCF  = CFrame.lookAt(camPos, aimPos)

        local safeDt  = math.min(dt, 0.05)
        local alpha   = 1 - (1 - math.min(strength, 0.99)) ^ (safeDt * 60)

        Camera.CFrame = Camera.CFrame:Lerp(goalCF, alpha)

        local bodyGoal = CFrame.new(myPos) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
        myHRP.CFrame   = myHRP.CFrame:Lerp(bodyGoal, alpha)
    end)
end

local function StopLock()
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    SetTarget(nil)
end

-- ESP loop แยก
espConnection = RunService.Heartbeat:Connect(function()
    if Settings.ESPEnabled then
        UpdateESP()
    end
end)

-- ══════════════════════════════
--   TELEPORT FUNCTIONS
-- ══════════════════════════════
local function TPRefresh()
    for _, c in ipairs(TPScroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    for i, pos in ipairs(tpSaves) do
        local btn = MakeBtn(TPScroll,
            string.format("📍 Save %d  (%.0f, %.0f, %.0f)", i, pos.x, pos.y, pos.z),
            UDim2.new(1,-5,0,26), UDim2.new(0,0,0,0),
            Color3.fromRGB(28,28,40), Color3.fromRGB(180,200,255), 10)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0,8)
        btn.MouseButton1Click:Connect(function()
            tpSelected = i
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(pos.x, pos.y, pos.z) end
            -- highlight
            for _, c2 in ipairs(TPScroll:GetChildren()) do
                if c2:IsA("TextButton") then
                    c2.BackgroundColor3 = Color3.fromRGB(28,28,40)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(40,60,100)
        end)
    end
    TPScroll.CanvasSize = UDim2.new(0,0,0,#tpSaves*30)
end

-- ══════════════════════════════
--   CHARACTER RESPAWN
-- ══════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    c:WaitForChild("HumanoidRootPart")
    currentTarget = nil
    ClearESP()
    if Settings.Enabled then
        task.wait(0.5)
        StartLock()
    end
end)

-- ══════════════════════════════
--   INPUT HANDLERS
-- ══════════════════════════════
StrBox.FocusLost:Connect(function()
    local v = tonumber(StrBox.Text)
    if v then Settings.LockStrength = v StrBox.Text = tostring(v) SaveSettings()
    else StrBox.Text = tostring(Settings.LockStrength) end
end)

RangeBox.FocusLost:Connect(function()
    local v = tonumber(RangeBox.Text)
    if v then Settings.LockRange = v RangeBox.Text = tostring(v) SaveSettings()
    else RangeBox.Text = tostring(Settings.LockRange) end
end)

HeightBox.FocusLost:Connect(function()
    local v = tonumber(HeightBox.Text)
    if v then HEIGHT_OFFSET = v HeightBox.Text = tostring(v) SaveSettings()
    else HeightBox.Text = tostring(HEIGHT_OFFSET) end
end)

CamDistBox.FocusLost:Connect(function()
    local v = tonumber(CamDistBox.Text)
    if v then CAM_DISTANCE = v CamDistBox.Text = tostring(v) SaveSettings()
    else CamDistBox.Text = tostring(CAM_DISTANCE) end
end)

-- ══════════════════════════════
--   BUTTON CONNECTIONS
-- ══════════════════════════════
ModePlayer.MouseButton1Click:Connect(function()
    Settings.Mode = "Player" currentTarget = nil UpdateModeUI() SaveSettings()
end)
ModeNPC.MouseButton1Click:Connect(function()
    Settings.Mode = "NPC" currentTarget = nil UpdateModeUI() SaveSettings()
end)

LockBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        LockBtn.Text = "🔒 Lock : ON"
        LockBtn.BackgroundColor3 = Color3.fromRGB(30,70,30)
        StartLock()
    else
        LockBtn.Text = "🔓 Lock : OFF"
        LockBtn.BackgroundColor3 = Color3.fromRGB(30,30,45)
        StopLock()
    end
end)

NearBtn.MouseButton1Click:Connect(function()
    Settings.NearestMode = not Settings.NearestMode
    NearBtn.Text = Settings.NearestMode and "📍 Nearest : ON" or "📍 Nearest : OFF"
    NearBtn.BackgroundColor3 = Settings.NearestMode
        and Color3.fromRGB(30,60,30) or Color3.fromRGB(30,30,45)
    SaveSettings()
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

ESPBtn.MouseButton1Click:Connect(function()
    Settings.ESPEnabled = not Settings.ESPEnabled
    ESPBtn.Text = Settings.ESPEnabled and "👁 ESP : ON" or "👁 ESP : OFF"
    ESPBtn.BackgroundColor3 = Settings.ESPEnabled
        and Color3.fromRGB(30,60,80) or Color3.fromRGB(30,30,45)
    if not Settings.ESPEnabled then ClearESP() end
end)

-- Menu Lock
LockMenuBtn.MouseButton1Click:Connect(function()
    menuLocked = not menuLocked
    LockMenuBtn.Text = menuLocked and "🔒" or "🔓"
    LockMenuBtn.BackgroundColor3 = menuLocked
        and Color3.fromRGB(80,60,20) or Color3.fromRGB(50,50,70)
end)

-- Minimize / Close
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized
        and UDim2.new(0,S(230),0,S(32))
        or  UDim2.new(0,S(230),0,S(420))
end)

CloseBtn.MouseButton1Click:Connect(function()
    StopLock()
    ClearESP()
    if espConnection then espConnection:Disconnect() end
    ScreenGui:Destroy()
end)

-- Scan Menu
local scanVisible = false
ScanToggleBtn.MouseButton1Click:Connect(function()
    scanVisible = not scanVisible
    ScanFrame.Visible = scanVisible
    ScanToggleBtn.BackgroundColor3 = scanVisible
        and Color3.fromRGB(30,50,90) or Color3.fromRGB(30,30,45)
end)

ScanCloseBtn.MouseButton1Click:Connect(function()
    scanVisible = false
    ScanFrame.Visible = false
    ColorPopup.Visible = false
    ExcludePopup.Visible = false
    ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,45)
end)

local scanMin = false
ScanMinBtn.MouseButton1Click:Connect(function()
    scanMin = not scanMin
    ScanScroll.Visible = not scanMin
    DoScanBtn.Visible = not scanMin
    ScanCountLabel.Visible = not scanMin
    FilterBar.Visible = not scanMin
    ExcludeBar.Visible = not scanMin
    ScanFrame.Size = scanMin
        and UDim2.new(0,SS(220),0,SS(30))
        or  UDim2.new(0,SS(220),0,SS(340))
    if scanMin then ColorPopup.Visible = false ExcludePopup.Visible = false end
end)

-- Scan Now
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
    ScanCountLabel.Text = #list.." found  (raw: "..#raw..")"

    for i, entry in ipairs(list) do
        local btn = MakeBtn(ScanScroll,
            string.format("  [%d] %s  %.0fm", i, entry.name, entry.dist),
            UDim2.new(1,0,0,SS(26)), UDim2.new(0,0,0,0),
            Color3.fromRGB(18,18,28), entry.color, SS(9))
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0,SS(6),0,SS(6))
        dot.Position = UDim2.new(0,SS(4),0.5,-SS(3))
        dot.BackgroundColor3 = entry.color
        dot.BorderSizePixel = 0
        dot.Parent = btn
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        btn.MouseButton1Click:Connect(function()
            targetIndex = i
            SetTarget(entry.model)
        end)
    end
    ScanScroll.CanvasSize = UDim2.new(0,0,0,ScanLayout.AbsoluteContentSize.Y+SS(4))
    UpdateColorPicker()
    UpdateExcludePicker()
end)

-- Color Picker
ColorPickerBtn.MouseButton1Click:Connect(function()
    ColorPopup.Visible = not ColorPopup.Visible
    ExcludePopup.Visible = false
    if ColorPopup.Visible then UpdateColorPicker() end
end)

CPCloseBtn.MouseButton1Click:Connect(function() ColorPopup.Visible = false end)

CPNoColorBtn.MouseButton1Click:Connect(function()
    Settings.FilterColor = nil
    FilterLabel.Text = "🎨 Filter: ทั้งหมด"
    FilterLabel.TextColor3 = Color3.fromRGB(140,140,180)
    ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(60,60,180)
    ColorPopup.Visible = false
    UpdateColorPicker()
end)

ClearFilterBtn.MouseButton1Click:Connect(function()
    Settings.FilterColor = nil
    FilterLabel.Text = "🎨 Filter: ทั้งหมด"
    FilterLabel.TextColor3 = Color3.fromRGB(140,140,180)
    ColorPickerBtn.BackgroundColor3 = Color3.fromRGB(60,60,180)
    UpdateColorPicker()
end)

-- Exclude Color
ExcludeBtn.MouseButton1Click:Connect(function()
    ExcludePopup.Visible = not ExcludePopup.Visible
    ColorPopup.Visible = false
    if ExcludePopup.Visible then
        pendingExcludes = {}
        for _, h in ipairs(Settings.ExcludeColors) do
            table.insert(pendingExcludes, h)
        end
        UpdateExcludePicker()
    end
end)

EPCloseBtn.MouseButton1Click:Connect(function()
    ExcludePopup.Visible = false
    pendingExcludes = {}
end)

EPOKBtn.MouseButton1Click:Connect(function()
    Settings.ExcludeColors = {}
    for _, h in ipairs(pendingExcludes) do
        table.insert(Settings.ExcludeColors, h)
    end
    UpdateExcludePicker()
    ExcludePopup.Visible = false
    pendingExcludes = {}
end)

ClearExcludeBtn.MouseButton1Click:Connect(function()
    Settings.ExcludeColors = {}
    pendingExcludes = {}
    UpdateExcludePicker()
end)

-- TP Menu
local tpVisible = false
TPToggleBtn.MouseButton1Click:Connect(function()
    tpVisible = not tpVisible
    TPFrame.Visible = tpVisible
    TPToggleBtn.BackgroundColor3 = tpVisible
        and Color3.fromRGB(25,60,35) or Color3.fromRGB(30,30,45)
    if tpVisible then TPRefresh() end
end)

local tpMin = false
TPMinBtn.MouseButton1Click:Connect(function()
    tpMin = not tpMin
    TPScroll.Visible = not tpMin
    TPSaveBtn.Visible = not tpMin
    TPClickBtn.Visible = not tpMin
    TPDeleteBtn.Visible = not tpMin
    TPFrame.Size = tpMin
        and UDim2.new(0,210,0,30)
        or  UDim2.new(0,210,0,260)
end)

TPCloseBtn.MouseButton1Click:Connect(function()
    tpVisible = false
    TPFrame.Visible = false
    TPToggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,45)
end)

TPSaveBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    table.insert(tpSaves, {x=root.Position.X, y=root.Position.Y, z=root.Position.Z})
    TPRefresh()
end)

TPDeleteBtn.MouseButton1Click:Connect(function()
    if tpSelected then
        table.remove(tpSaves, tpSelected)
        tpSelected = nil
        TPRefresh()
    end
end)

TPClickBtn.MouseButton1Click:Connect(function()
    clickTP = not clickTP
    if not clickTP then lockPos = nil end
    TPClickBtn.Text = clickTP and "Click TP ON" or "Click TP OFF"
    TPClickBtn.BackgroundColor3 = clickTP
        and Color3.fromRGB(30,120,50) or Color3.fromRGB(150,40,40)
end)

Mouse.Button1Down:Connect(function()
    if not clickTP then return end
    lockPos = nil
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local hit = Mouse.Hit
    if hit then
        lockPos = hit.Position
        root.CFrame = CFrame.new(lockPos + Vector3.new(0,3,0))
    end
end)

RunService.Heartbeat:Connect(function()
    if clickTP and lockPos then
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if (root.Position - lockPos).Magnitude > 10 then
            root.CFrame = CFrame.new(lockPos + Vector3.new(0,3,0))
        end
    end
end)

-- ══════════════════════════════
--   INIT: restore NearestMode UI
-- ══════════════════════════════
if Settings.NearestMode then
    NearBtn.Text = "📍 Nearest : ON"
    NearBtn.BackgroundColor3 = Color3.fromRGB(30,60,30)
end
