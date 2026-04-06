-- Lock Menu v15 | Codex Android | All Features
-- Lock + ESP (no lag) + Camera System + Teleport + Exclude Color

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- LOAD / SAVE
local _S = _G.LockMenuSave or {}
local Settings = {
    LockStrength  = _S.LockStrength  or 0.3,
    LockRange     = _S.LockRange     or 100,
    Mode          = _S.Mode          or "NPC",
    NearestMode   = _S.NearestMode   or false,
    AimMode       = _S.AimMode       or "body",
    FilterColor   = nil,
    ESPEnabled    = false,
    Enabled       = false,
    ExcludeColors = {},
}
local CAM_DISTANCE  = _S.CAM_DISTANCE or 15
local CAM_HEIGHT    = 3
local SCAN_INTERVAL = 0.1

local function SaveSettings()
    _G.LockMenuSave = {
        LockStrength = Settings.LockStrength,
        LockRange    = Settings.LockRange,
        Mode         = Settings.Mode,
        NearestMode  = Settings.NearestMode,
        AimMode      = Settings.AimMode,
        CAM_DISTANCE = CAM_DISTANCE,
    }
end

-- STATE
local Character     = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local currentTarget = nil
local targetList    = {}
local targetIndex   = 1
local lockConn      = nil
local forceRescan   = false
local foundColors   = {}
local espBoxes      = {}
local tpSaves       = {}
local tpSelected    = nil
local clickTP       = false
local lockPos       = nil
local camLocked     = false
local camFree       = false
local camDistance   = 50
local camPos_free   = Vector3.new()
local angleX, angleY = 0, 0
local camSpeed      = 5
local camMove       = Vector3.new()

-- GUI CLEANUP
pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("LockMenu_v15")
        if old then old:Destroy() end
    end
end)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "LockMenu_v15"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- HELPERS
local function ColorToHex(c)
    return string.format("%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

local function MakeDraggable(frame, handle, lockFn)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if lockFn and lockFn() then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=frame.Position
        end
    end)
    local function mv(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end
    local function en(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end
    handle.InputChanged:Connect(mv)
    UserInputService.InputChanged:Connect(mv)
    handle.InputEnded:Connect(en)
    UserInputService.InputEnded:Connect(en)
end

local function MkFrame(parent, sz, pos, col, clip, z)
    local f = Instance.new("Frame")
    f.Size=sz; f.Position=pos
    f.BackgroundColor3=col or Color3.fromRGB(12,12,18)
    f.BorderSizePixel=0
    if clip then f.ClipsDescendants=true end
    if z then f.ZIndex=z end
    f.Parent=parent
    Instance.new("UICorner", f).CornerRadius=UDim.new(0,8)
    return f
end

local function MkLabel(parent, text, sz, pos, ts, col, font, xa, z)
    local l = Instance.new("TextLabel")
    l.Size=sz; l.Position=pos; l.BackgroundTransparency=1
    l.Text=text; l.TextSize=ts or 11
    l.TextColor3=col or Color3.fromRGB(200,200,200)
    l.Font=font or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    if z then l.ZIndex=z end
    l.Parent=parent; return l
end

local function MkBtn(parent, text, sz, pos, bg, tc, ts, z)
    local b = Instance.new("TextButton")
    b.Size=sz; b.Position=pos
    b.BackgroundColor3=bg or Color3.fromRGB(30,30,45)
    b.BorderSizePixel=0; b.Text=text
    b.TextColor3=tc or Color3.fromRGB(210,210,255)
    b.TextSize=ts or 11; b.Font=Enum.Font.GothamBold
    if z then b.ZIndex=z end
    b.Parent=parent
    Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
    return b
end

local function MkInput(parent, default, sz, pos, z)
    local b = Instance.new("TextBox")
    b.Size=sz; b.Position=pos
    b.BackgroundColor3=Color3.fromRGB(18,18,28)
    b.BorderSizePixel=0; b.Text=tostring(default)
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.TextSize=11; b.Font=Enum.Font.Gotham
    if z then b.ZIndex=z end
    b.Parent=parent
    Instance.new("UICorner", b).CornerRadius=UDim.new(0,5)
    return b
end

local function Divider(parent, y)
    local d = Instance.new("Frame")
    d.Size=UDim2.new(1,-16,0,1); d.Position=UDim2.new(0,8,0,y)
    d.BackgroundColor3=Color3.fromRGB(30,30,48); d.BorderSizePixel=0
    d.Parent=parent
end

local function Accent(parent, col)
    local a=Instance.new("Frame")
    a.Size=UDim2.new(1,0,0,2); a.Position=UDim2.new(0,0,1,-2)
    a.BackgroundColor3=col; a.BorderSizePixel=0; a.Parent=parent
end

-- MAIN FRAME
local menuLocked = false
local MainFrame = MkFrame(ScreenGui, UDim2.new(0,230,0,395),
    UDim2.new(0.5,-115,0.5,-198), Color3.fromRGB(11,11,17), true)

local TBar = MkFrame(MainFrame, UDim2.new(1,0,0,32), UDim2.new(0,0,0,0), Color3.fromRGB(17,17,26))
TBar.ClipsDescendants=false
Accent(TBar, Color3.fromRGB(70,110,255))
MakeDraggable(MainFrame, TBar, function() return menuLocked end)

MkLabel(TBar,"⚔  Lock Menu  v15",UDim2.new(1,-102,1,0),UDim2.new(0,10,0,0),
    12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)

local LockMenuBtn = MkBtn(TBar,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-96,0.5,-11),Color3.fromRGB(40,40,65),Color3.fromRGB(180,180,255),13)
local MinBtn      = MkBtn(TBar,"–", UDim2.new(0,22,0,22),UDim2.new(1,-71,0.5,-11),Color3.fromRGB(45,45,55),Color3.fromRGB(255,255,255),14)
local CloseBtn    = MkBtn(TBar,"✕", UDim2.new(0,22,0,22),UDim2.new(1,-47,0.5,-11),Color3.fromRGB(160,30,30),Color3.fromRGB(255,255,255),12)

local Content = Instance.new("Frame")
Content.Size=UDim2.new(1,0,1,-32); Content.Position=UDim2.new(0,0,0,32)
Content.BackgroundTransparency=1; Content.Parent=MainFrame

-- MODE
MkLabel(Content,"🎯  MODE",UDim2.new(1,0,0,13),UDim2.new(0,8,0,8),9,Color3.fromRGB(90,90,140))
local ModePlayer = MkBtn(Content,"👤 Player",UDim2.new(0,99,0,26),UDim2.new(0,8,0,22),Color3.fromRGB(28,28,46),Color3.fromRGB(150,150,200))
local ModeNPC    = MkBtn(Content,"🤖 NPC",   UDim2.new(0,99,0,26),UDim2.new(0,114,0,22),Color3.fromRGB(65,100,240),Color3.fromRGB(255,255,255))

local function UpdateModeUI()
    if Settings.Mode=="Player" then
        ModePlayer.BackgroundColor3=Color3.fromRGB(65,100,240); ModePlayer.TextColor3=Color3.fromRGB(255,255,255)
        ModeNPC.BackgroundColor3=Color3.fromRGB(28,28,46);      ModeNPC.TextColor3=Color3.fromRGB(150,150,200)
    else
        ModeNPC.BackgroundColor3=Color3.fromRGB(65,100,240);    ModeNPC.TextColor3=Color3.fromRGB(255,255,255)
        ModePlayer.BackgroundColor3=Color3.fromRGB(28,28,46);   ModePlayer.TextColor3=Color3.fromRGB(150,150,200)
    end
end
UpdateModeUI()

Divider(Content,54)

-- STRENGTH / RANGE
MkLabel(Content,"⚡ Strength",UDim2.new(0,100,0,13),UDim2.new(0,8,0,58),9,Color3.fromRGB(90,90,140))
MkLabel(Content,"📏 Range",   UDim2.new(0,100,0,13),UDim2.new(0,120,0,58),9,Color3.fromRGB(90,90,140))
local StrBox   = MkInput(Content,Settings.LockStrength,UDim2.new(0,96,0,24),UDim2.new(0,8,0,71))
local RangeBox = MkInput(Content,Settings.LockRange,   UDim2.new(0,96,0,24),UDim2.new(0,120,0,71))

Divider(Content,101)

-- CAM DIST / AIM MODE
MkLabel(Content,"📷 Cam Dist",UDim2.new(0,100,0,13),UDim2.new(0,8,0,105),9,Color3.fromRGB(90,90,140))
MkLabel(Content,"🎯 Aim",     UDim2.new(0,100,0,13),UDim2.new(0,120,0,105),9,Color3.fromRGB(90,90,140))
local CamDistBox = MkInput(Content,CAM_DISTANCE,UDim2.new(0,96,0,24),UDim2.new(0,8,0,118))
local AimHead    = MkBtn(Content,"🎯 Head",UDim2.new(0,46,0,24),UDim2.new(0,120,0,118),
    Settings.AimMode=="head" and Color3.fromRGB(65,100,240) or Color3.fromRGB(28,28,46),Color3.fromRGB(220,220,255),10)
local AimBody    = MkBtn(Content,"🧍 Body",UDim2.new(0,46,0,24),UDim2.new(0,170,0,118),
    Settings.AimMode=="body" and Color3.fromRGB(65,100,240) or Color3.fromRGB(28,28,46),Color3.fromRGB(220,220,255),10)

local function UpdateAimUI()
    AimHead.BackgroundColor3=Settings.AimMode=="head" and Color3.fromRGB(65,100,240) or Color3.fromRGB(28,28,46)
    AimBody.BackgroundColor3=Settings.AimMode=="body" and Color3.fromRGB(65,100,240) or Color3.fromRGB(28,28,46)
end

Divider(Content,148)

-- LOCK / NEAREST
local LockBtn = MkBtn(Content,"🔓 Lock : OFF",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,154),Color3.fromRGB(24,24,38),Color3.fromRGB(180,180,255),12)
local NearBtn = MkBtn(Content,"📍 Nearest : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,188),Color3.fromRGB(24,24,38),Color3.fromRGB(165,165,215),11)

-- PREV / TARGET / NEXT
local PrevBtn = MkBtn(Content,"◀",UDim2.new(0,38,0,26),UDim2.new(0,8,0,220),Color3.fromRGB(28,28,46),Color3.fromRGB(200,200,255),13)
local TgLabel = MkLabel(Content,"No Target",UDim2.new(0,120,0,26),UDim2.new(0,50,0,220),10,Color3.fromRGB(130,175,255),Enum.Font.GothamBold)
TgLabel.BackgroundColor3=Color3.fromRGB(16,16,28); TgLabel.BackgroundTransparency=0
TgLabel.TextTruncate=Enum.TextTruncate.AtEnd
Instance.new("UICorner",TgLabel).CornerRadius=UDim.new(0,5)
local NextBtn = MkBtn(Content,"▶",UDim2.new(0,38,0,26),UDim2.new(0,174,0,220),Color3.fromRGB(28,28,46),Color3.fromRGB(200,200,255),13)

Divider(Content,252)

-- FEATURE ROW
local ESPBtn  = MkBtn(Content,"👁 ESP",  UDim2.new(0,58,0,26),UDim2.new(0,8,0,258),  Color3.fromRGB(24,24,38),Color3.fromRGB(160,215,255),10)
local ScanBtn = MkBtn(Content,"🔍 Scan", UDim2.new(0,58,0,26),UDim2.new(0,70,0,258), Color3.fromRGB(24,24,38),Color3.fromRGB(160,195,255),10)
local TPBtn   = MkBtn(Content,"🚀 TP",   UDim2.new(0,44,0,26),UDim2.new(0,132,0,258),Color3.fromRGB(24,24,38),Color3.fromRGB(160,255,195),10)
local CamBtn  = MkBtn(Content,"📷 Cam",  UDim2.new(0,44,0,26),UDim2.new(0,180,0,258),Color3.fromRGB(24,24,38),Color3.fromRGB(255,200,140),10)

Divider(Content,290)
local StatusLabel = MkLabel(Content,"● Idle",UDim2.new(1,-16,0,18),UDim2.new(0,8,0,295),10,Color3.fromRGB(65,65,105))

-- SCAN FRAME
local ScanFrame = MkFrame(ScreenGui,UDim2.new(0,215,0,340),UDim2.new(0.5,120,0.5,-170),Color3.fromRGB(11,11,17),true)
ScanFrame.Visible=false
local STBar=MkFrame(ScanFrame,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,26))
STBar.ClipsDescendants=false; Accent(STBar,Color3.fromRGB(70,110,255))
MakeDraggable(ScanFrame,STBar,nil)
MkLabel(STBar,"🔍  Scan",UDim2.new(1,-115,1,0),UDim2.new(0,8,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local CPBtn2  = MkBtn(STBar,"🎨",UDim2.new(0,22,0,22),UDim2.new(1,-92,0.5,-11),Color3.fromRGB(50,50,170),Color3.fromRGB(255,255,255),11)
local ExclBtn = MkBtn(STBar,"🚫",UDim2.new(0,22,0,22),UDim2.new(1,-68,0.5,-11),Color3.fromRGB(95,30,30),Color3.fromRGB(255,180,180),11)
local ScanMinB= MkBtn(STBar,"–", UDim2.new(0,20,0,20),UDim2.new(1,-43,0.5,-10),Color3.fromRGB(45,45,55),Color3.fromRGB(255,255,255),13)
local ScanClsB= MkBtn(STBar,"✕", UDim2.new(0,20,0,20),UDim2.new(1,-21,0.5,-10),Color3.fromRGB(160,30,30),Color3.fromRGB(255,255,255),10)

local FBar=MkFrame(ScanFrame,UDim2.new(1,-16,0,21),UDim2.new(0,8,0,32),Color3.fromRGB(15,15,24))
FBar.ClipsDescendants=false
local FLabel =MkLabel(FBar,"🎨 Filter: ทั้งหมด",UDim2.new(1,-28,1,0),UDim2.new(0,5,0,0),9,Color3.fromRGB(115,115,175))
local FClrBtn=MkBtn(FBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(60,22,22),Color3.fromRGB(255,145,145),9)

local EBar=MkFrame(ScanFrame,UDim2.new(1,-16,0,21),UDim2.new(0,8,0,55),Color3.fromRGB(18,11,11))
EBar.ClipsDescendants=false
local ELabel =MkLabel(EBar,"🚫 Exclude: ไม่มี",UDim2.new(1,-28,1,0),UDim2.new(0,5,0,0),9,Color3.fromRGB(175,115,115))
local EClrBtn=MkBtn(EBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(60,22,22),Color3.fromRGB(255,145,145),9)

local DoScanB=MkBtn(ScanFrame,"🔍 Scan Now",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,78),Color3.fromRGB(32,32,68),Color3.fromRGB(195,195,255),11)
local ScanCnt=MkLabel(ScanFrame,"0 found",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,106),9,Color3.fromRGB(75,75,125))
local ScanScroll=Instance.new("ScrollingFrame")
ScanScroll.Size=UDim2.new(1,-8,1,-122); ScanScroll.Position=UDim2.new(0,4,0,121)
ScanScroll.BackgroundTransparency=1; ScanScroll.BorderSizePixel=0
ScanScroll.ScrollBarThickness=3; ScanScroll.CanvasSize=UDim2.new(0,0,0,0)
ScanScroll.ScrollBarImageColor3=Color3.fromRGB(50,50,95); ScanScroll.Parent=ScanFrame
local ScanLayout=Instance.new("UIListLayout"); ScanLayout.Padding=UDim.new(0,3); ScanLayout.Parent=ScanScroll

-- COLOR PICKER POPUP
local CPop=MkFrame(ScreenGui,UDim2.new(0,192,0,222),UDim2.new(0.5,120,0.5,170),Color3.fromRGB(12,12,20),true)
CPop.Visible=false; CPop.ZIndex=10
local CPTop=MkFrame(CPop,UDim2.new(1,0,0,27),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,26),false,10)
CPTop.ClipsDescendants=false; Accent(CPTop,Color3.fromRGB(70,110,255))
MakeDraggable(CPop,CPTop,nil)
MkLabel(CPTop,"🎨 Filter Color",UDim2.new(1,-28,1,0),UDim2.new(0,7,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold,nil,10)
local CPClsBtn=MkBtn(CPTop,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(160,30,30),Color3.fromRGB(255,255,255),10,10)
local CPAllBtn=MkBtn(CPop,"✅ แสดงทั้งหมด",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,29),Color3.fromRGB(22,42,22),Color3.fromRGB(155,255,155),9,10)
local CPScroll=Instance.new("ScrollingFrame")
CPScroll.Size=UDim2.new(1,-8,1,-54); CPScroll.Position=UDim2.new(0,4,0,53)
CPScroll.BackgroundTransparency=1; CPScroll.BorderSizePixel=0
CPScroll.ScrollBarThickness=3; CPScroll.CanvasSize=UDim2.new(0,0,0,0); CPScroll.ZIndex=10
CPScroll.Parent=CPop
local CPLayout=Instance.new("UIListLayout"); CPLayout.Padding=UDim.new(0,3); CPLayout.Parent=CPScroll

-- EXCLUDE POPUP
local EPop=MkFrame(ScreenGui,UDim2.new(0,192,0,248),UDim2.new(0.5,120,0.5,175),Color3.fromRGB(16,9,9),true)
EPop.Visible=false; EPop.ZIndex=10
local EPTop=MkFrame(EPop,UDim2.new(1,0,0,27),UDim2.new(0,0,0,0),Color3.fromRGB(21,13,13),false,10)
EPTop.ClipsDescendants=false; Accent(EPTop,Color3.fromRGB(200,55,55))
MakeDraggable(EPop,EPTop,nil)
MkLabel(EPTop,"🚫 Exclude Color",UDim2.new(1,-28,1,0),UDim2.new(0,7,0,0),10,Color3.fromRGB(255,195,195),Enum.Font.GothamBold,nil,10)
local EPClsBtn=MkBtn(EPTop,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(160,30,30),Color3.fromRGB(255,255,255),10,10)
MkLabel(EPop,"กดเลือกสีที่ไม่ต้องการล็อค",UDim2.new(1,-16,0,17),UDim2.new(0,8,0,29),9,Color3.fromRGB(195,155,155),nil,nil,10)
local EPOKBtn=MkBtn(EPop,"✅ OK ยืนยัน",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,48),Color3.fromRGB(22,42,22),Color3.fromRGB(155,255,155),9,10)
local EPScroll=Instance.new("ScrollingFrame")
EPScroll.Size=UDim2.new(1,-8,1,-73); EPScroll.Position=UDim2.new(0,4,0,72)
EPScroll.BackgroundTransparency=1; EPScroll.BorderSizePixel=0
EPScroll.ScrollBarThickness=3; EPScroll.CanvasSize=UDim2.new(0,0,0,0); EPScroll.ZIndex=10
EPScroll.Parent=EPop
local EPLayout=Instance.new("UIListLayout"); EPLayout.Padding=UDim.new(0,3); EPLayout.Parent=EPScroll

-- TELEPORT FRAME
local TPFrame=MkFrame(ScreenGui,UDim2.new(0,210,0,252),UDim2.new(0.5,-338,0.5,-126),Color3.fromRGB(11,11,17),true)
TPFrame.Visible=false
local TPTop=MkFrame(TPFrame,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(14,22,17))
TPTop.ClipsDescendants=false; Accent(TPTop,Color3.fromRGB(55,195,95))
MakeDraggable(TPFrame,TPTop,nil)
MkLabel(TPTop,"🚀  Teleport Save",UDim2.new(1,-88,1,0),UDim2.new(0,8,0,0),12,Color3.fromRGB(195,255,215),Enum.Font.GothamBold)
local TPMinBtn=MkBtn(TPTop,"–",UDim2.new(0,22,0,22),UDim2.new(1,-48,0.5,-11),Color3.fromRGB(45,45,55),Color3.fromRGB(255,255,255),13)
local TPClsBtn=MkBtn(TPTop,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-24,0.5,-11),Color3.fromRGB(160,30,30),Color3.fromRGB(255,255,255),12)
local TPSaveBtn =MkBtn(TPFrame,"+ Save",  UDim2.new(0,61,0,27),UDim2.new(0,5,0,33), Color3.fromRGB(22,70,22),Color3.fromRGB(175,255,175),10)
local TPClickBtn=MkBtn(TPFrame,"Click TP",UDim2.new(0,71,0,27),UDim2.new(0,70,0,33), Color3.fromRGB(125,35,35),Color3.fromRGB(255,175,175),10)
local TPDelBtn  =MkBtn(TPFrame,"Delete",  UDim2.new(0,56,0,27),UDim2.new(0,146,0,33),Color3.fromRGB(68,22,22),Color3.fromRGB(255,155,155),10)
local TPScroll=Instance.new("ScrollingFrame")
TPScroll.Size=UDim2.new(1,-10,1,-65); TPScroll.Position=UDim2.new(0,5,0,62)
TPScroll.BackgroundColor3=Color3.fromRGB(13,13,20); TPScroll.BorderSizePixel=0
TPScroll.ScrollBarThickness=3; TPScroll.CanvasSize=UDim2.new(0,0,0,0); TPScroll.Parent=TPFrame
Instance.new("UICorner",TPScroll).CornerRadius=UDim.new(0,5)
local TPLayout=Instance.new("UIListLayout"); TPLayout.Padding=UDim.new(0,4); TPLayout.Parent=TPScroll

-- CAMERA FRAME
local CamFrame=MkFrame(ScreenGui,UDim2.new(0,188,0,142),UDim2.new(0.05,0,0.3,0),Color3.fromRGB(11,11,17),true)
CamFrame.Visible=false
local CTop=MkFrame(CamFrame,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(20,16,10))
CTop.ClipsDescendants=false; Accent(CTop,Color3.fromRGB(255,165,55))
MakeDraggable(CamFrame,CTop,nil)
MkLabel(CTop,"📷  Camera",UDim2.new(1,-68,1,0),UDim2.new(0,8,0,0),12,Color3.fromRGB(255,205,145),Enum.Font.GothamBold)
local CMinBtn=MkBtn(CTop,"–",UDim2.new(0,22,0,22),UDim2.new(1,-48,0.5,-11),Color3.fromRGB(45,45,55),Color3.fromRGB(255,255,255),13)
local CClsBtn=MkBtn(CTop,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-24,0.5,-11),Color3.fromRGB(160,30,30),Color3.fromRGB(255,255,255),12)
local CamLockBtn=MkBtn(CamFrame,"🔒 Cam Lock OFF",UDim2.new(1,-10,0,26),UDim2.new(0,5,0,33),Color3.fromRGB(125,35,35),Color3.fromRGB(255,175,175),11)
local CamFreeBtn=MkBtn(CamFrame,"🎥 FreeCam OFF", UDim2.new(1,-10,0,26),UDim2.new(0,5,0,62),Color3.fromRGB(125,35,35),Color3.fromRGB(255,175,175),11)
MkLabel(CamFrame,"📏 Distance",UDim2.new(0,78,0,13),UDim2.new(0,5,0,91),9,Color3.fromRGB(90,90,140))
local CamDistInput=MkInput(CamFrame,camDistance,UDim2.new(1,-10,0,24),UDim2.new(0,5,0,104))

-- FreeCam mobile controls
local CamCtrl=Instance.new("Frame")
CamCtrl.Size=UDim2.new(0,162,0,162); CamCtrl.Position=UDim2.new(0.73,0,0.6,0)
CamCtrl.BackgroundTransparency=1; CamCtrl.Visible=false; CamCtrl.Parent=ScreenGui

local function MkCBtn(txt,pos)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,46,0,46); b.Position=pos; b.Text=txt
    b.BackgroundColor3=Color3.fromRGB(28,28,44); b.TextColor3=Color3.fromRGB(200,200,255)
    b.TextSize=14; b.Font=Enum.Font.GothamBold; b.BackgroundTransparency=0.25
    b.Parent=CamCtrl
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    return b
end
local cBF=MkCBtn("↑",UDim2.new(0.5,-23,0,0)); local cBB=MkCBtn("↓",UDim2.new(0.5,-23,0,94))
local cBL=MkCBtn("←",UDim2.new(0,0,0.5,-23)); local cBR=MkCBtn("→",UDim2.new(0,95,0.5,-23))
local cBU=MkCBtn("▲",UDim2.new(0,0,0,0));     local cBD=MkCBtn("▼",UDim2.new(0,95,0,0))
local function BindCam(btn,vec)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            camMove=camMove+vec end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            camMove=camMove-vec end
    end)
end
BindCam(cBF,Vector3.new(0,0,-1)); BindCam(cBB,Vector3.new(0,0,1))
BindCam(cBL,Vector3.new(-1,0,0)); BindCam(cBR,Vector3.new(1,0,0))
BindCam(cBU,Vector3.new(0,1,0));  BindCam(cBD,Vector3.new(0,-1,0))

-- CORE FUNCTIONS
local function GetTeamColor(model)
    local p=Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    if p then
        local mt=LocalPlayer.Team
        if mt and p.Team then return p.Team==mt and Color3.fromRGB(60,200,100) or Color3.fromRGB(220,60,60) end
    end
    return Color3.fromRGB(220,120,50)
end

local function IsExcluded(color)
    local h=ColorToHex(color)
    for _,eh in ipairs(Settings.ExcludeColors) do if eh==h then return true end end
    return false
end

local function GetModelRootAndHeight(model)
    local hrp=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model.PrimaryPart
    if not hrp then
        for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then hrp=p break end end
    end
    if not hrp then return nil,0 end
    local minY,maxY=hrp.Position.Y,hrp.Position.Y
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local h2=p.Size.Y*0.5
            if p.Position.Y-h2<minY then minY=p.Position.Y-h2 end
            if p.Position.Y+h2>maxY then maxY=p.Position.Y+h2 end
        end
    end
    return hrp, math.max(maxY-minY,0)
end

local function GetAimPos(model)
    local hrp,height=GetModelRootAndHeight(model)
    if not hrp then return nil end
    if Settings.AimMode=="head" then
        return hrp.Position+Vector3.new(0, height*0.48, 0)
    else
        return hrp.Position+Vector3.new(0, height*0.1, 0)
    end
end

local function GetTargetList()
    local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list={}
    local range=tonumber(RangeBox.Text) or Settings.LockRange
    if Settings.Mode=="Player" then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                local hum=p.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health>0 then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    if dist<=range then
                        local col=GetTeamColor(p.Character)
                        if not IsExcluded(col) then table.insert(list,{model=p.Character,name=p.Name,dist=dist,color=col}) end
                    end
                end
            end
        end
    else
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj~=Character and not Players:GetPlayerFromCharacter(obj) then
                local hum=obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    local hrp=obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("RootPart") or obj.PrimaryPart
                    if not hrp then for _,p in ipairs(obj:GetChildren()) do if p:IsA("BasePart") then hrp=p break end end end
                    if hrp then
                        local dist=(hrp.Position-myHRP.Position).Magnitude
                        if dist<=range then
                            local col=GetTeamColor(obj)
                            if not IsExcluded(col) then table.insert(list,{model=obj,name=obj.Name,dist=dist,color=col}) end
                        end
                    end
                end
            end
        end
    end
    table.sort(list,function(a,b) return a.dist<b.dist end)
    return list
end

local function FilterList(list)
    if not Settings.FilterColor then return list end
    local fh=ColorToHex(Settings.FilterColor); local out={}
    for _,e in ipairs(list) do if ColorToHex(e.color)==fh then table.insert(out,e) end end
    return out
end

local function SetTarget(model)
    currentTarget=model
    if model then
        TgLabel.Text=model.Name; StatusLabel.Text="🔒 "..model.Name
        StatusLabel.TextColor3=Color3.fromRGB(95,175,255)
    else
        TgLabel.Text="No Target"; StatusLabel.Text="● Idle"
        StatusLabel.TextColor3=Color3.fromRGB(60,60,100)
    end
end

-- ESP (reuse, low interval)
local function ClearESP()
    for _,data in pairs(espBoxes) do pcall(function() data.bb:Destroy() end) end
    espBoxes={}
end

local espTimer=0
local function TickESP(dt)
    if not Settings.ESPEnabled then return end
    espTimer=espTimer+dt
    if espTimer<0.1 then return end
    espTimer=0
    local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local active={}
    local list=GetTargetList()
    for _,entry in ipairs(list) do
        local model=entry.model; active[model]=true
        local hrp,height=GetModelRootAndHeight(model)
        if not hrp then continue end
        if not espBoxes[model] then
            local bb=Instance.new("BillboardGui")
            bb.Adornee=hrp; bb.AlwaysOnTop=true; bb.LightInfluence=0
            bb.Size=UDim2.new(0,4,0,6); bb.Parent=hrp
            local fr=Instance.new("Frame")
            fr.Size=UDim2.new(1,0,1,0); fr.BackgroundTransparency=1; fr.BorderSizePixel=0; fr.Parent=bb
            local st=Instance.new("UIStroke"); st.Color=Color3.fromRGB(255,255,255); st.Thickness=1.5; st.Parent=fr
            local dl=Instance.new("TextLabel")
            dl.Name="DL"; dl.Size=UDim2.new(1,0,0,14); dl.Position=UDim2.new(0,0,1,2)
            dl.BackgroundTransparency=1; dl.TextColor3=Color3.fromRGB(255,255,255)
            dl.TextSize=11; dl.Font=Enum.Font.GothamBold; dl.Text="0m"; dl.Parent=bb
            espBoxes[model]={bb=bb,dl=dl}
        end
        local dist=entry.dist
        local h2=math.max(height,1)
        local scale=math.clamp(55/math.max(dist,1),1.2,10)
        espBoxes[model].bb.Size=UDim2.new(0,scale*(h2*0.55),0,scale*h2)
        espBoxes[model].dl.Text=string.format("%.0fm",dist)
    end
    for model,data in pairs(espBoxes) do
        if not active[model] then pcall(function() data.bb:Destroy() end); espBoxes[model]=nil end
    end
end

-- LOCK CORE (เหมือน v13)
local function StartLock()
    if lockConn then lockConn:Disconnect(); lockConn=nil end
    local timer=0
    lockConn=RunService.Heartbeat:Connect(function(dt)
        local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local strength=tonumber(StrBox.Text) or Settings.LockStrength
        if not strength or strength<=0 then strength=0.3 end
        -- detect เป้าตาย
        if currentTarget then
            local hum=currentTarget:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health<=0 or not currentTarget.Parent then
                SetTarget(nil); forceRescan=true
            end
        end
        -- scan
        if not currentTarget or Settings.NearestMode or forceRescan then
            timer=timer+dt
            if forceRescan or timer>=SCAN_INTERVAL then
                timer=0; forceRescan=false
                local raw=GetTargetList(); local filtered=FilterList(raw)
                targetList=filtered
                if #filtered>0 then
                    if Settings.NearestMode or not currentTarget then
                        SetTarget(filtered[1].model); targetIndex=1
                    end
                end
            end
        end
        -- ESP ใน loop เดียวกัน
        TickESP(dt)
        if not currentTarget then return end
        local aimPos=GetAimPos(currentTarget)
        if not aimPos then SetTarget(nil); forceRescan=true; return end
        local hum=currentTarget:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 or not currentTarget.Parent then
            SetTarget(nil); forceRescan=true; return
        end
        local myPos=myHRP.Position
        local diff=Vector3.new(aimPos.X-myPos.X,0,aimPos.Z-myPos.Z)
        if diff.Magnitude<0.01 then return end
        local dir=diff.Unit
        local camGoal=myPos-dir*CAM_DISTANCE+Vector3.new(0,CAM_HEIGHT,0)
        local goalCF=CFrame.lookAt(camGoal,aimPos)
        local safeDt=math.min(dt,0.05)
        -- ป้องกันสั่น: cap strength 0.95
        local s=math.min(strength,0.95)
        local alpha=1-(1-s)^(safeDt*60)
        Camera.CFrame=Camera.CFrame:Lerp(goalCF,alpha)
        local bGoal=CFrame.new(myPos)*CFrame.Angles(0,math.atan2(-dir.X,-dir.Z),0)
        myHRP.CFrame=myHRP.CFrame:Lerp(bGoal,alpha)
    end)
end

local function StopLock()
    if lockConn then lockConn:Disconnect(); lockConn=nil end
    SetTarget(nil)
end

-- ESP idle loop
local espIdleConn=RunService.Heartbeat:Connect(function(dt)
    if not Settings.Enabled then TickESP(dt) end
end)

-- CAMERA LOOP
RunService.Heartbeat:Connect(function(dt)
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    if camLocked and not camFree then
        local look=Camera.CFrame.LookVector
        Camera.CFrame=CFrame.new(root.Position-look*camDistance,root.Position)
    end
    if camFree then
        local rot=CFrame.Angles(0,math.rad(angleX),0)*CFrame.Angles(math.rad(angleY),0,0)
        local dir=rot.LookVector
        camPos_free=camPos_free+dir*camMove.Z*camSpeed
        camPos_free=camPos_free+rot.RightVector*camMove.X*camSpeed
        camPos_free=camPos_free+Vector3.new(0,camMove.Y*camSpeed,0)
        Camera.CFrame=CFrame.new(camPos_free,camPos_free+dir)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if camFree then
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            angleX=angleX-input.Delta.X*0.2
            angleY=math.clamp(angleY-input.Delta.Y*0.2,-80,80)
        end
    end
end)

-- TP
local function TPRefresh()
    for _,c in ipairs(TPScroll:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for i,pos in ipairs(tpSaves) do
        local b=MkBtn(TPScroll,string.format("📍 %d  %.0f,%.0f,%.0f",i,pos.x,pos.y,pos.z),
            UDim2.new(1,-5,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(20,20,33),Color3.fromRGB(165,195,255),10)
        b.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,6)
        b.Activated:Connect(function()
            tpSelected=i
            local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local r=char:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame=CFrame.new(pos.x,pos.y,pos.z) end
            for _,c2 in ipairs(TPScroll:GetChildren()) do
                if c2:IsA("TextButton") then c2.BackgroundColor3=Color3.fromRGB(20,20,33) end
            end
            b.BackgroundColor3=Color3.fromRGB(32,52,88)
        end)
    end
    TPScroll.CanvasSize=UDim2.new(0,0,0,#tpSaves*30)
end

-- COLOR PICKER
local function RefreshCP()
    for _,c in ipairs(CPScroll:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hex,col in pairs(foundColors) do
        n=n+1
        local b=MkBtn(CPScroll,"  #"..hex,UDim2.new(1,0,0,24),UDim2.new(0,0,0,0),col,Color3.fromRGB(255,255,255),9,10)
        b.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,7)
        if Settings.FilterColor and ColorToHex(Settings.FilterColor)==hex then Instance.new("UIStroke",b).Color=Color3.fromRGB(255,255,255) end
        b.Activated:Connect(function()
            Settings.FilterColor=col; FLabel.Text="🎨 #"..hex; FLabel.TextColor3=col
            CPBtn2.BackgroundColor3=col; CPop.Visible=false; RefreshCP()
        end)
    end
    CPScroll.CanvasSize=UDim2.new(0,0,0,CPLayout.AbsoluteContentSize.Y+4)
    if n==0 then MkLabel(CPScroll,"Scan ก่อน",UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),9,Color3.fromRGB(95,95,135),nil,nil,10) end
end

-- EXCLUDE PICKER
local pendExcl={}
local function RefreshEP()
    for _,c in ipairs(EPScroll:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hex,col in pairs(foundColors) do
        n=n+1
        local sel=false
        for _,h in ipairs(pendExcl) do if h==hex then sel=true break end end
        local b=MkBtn(EPScroll,(sel and "✓ " or "  ").."#"..hex,UDim2.new(1,0,0,24),UDim2.new(0,0,0,0),
            sel and Color3.fromRGB(95,30,30) or col,Color3.fromRGB(255,255,255),9,10)
        b.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,7)
        b.Activated:Connect(function()
            local found=false
            for i,h in ipairs(pendExcl) do if h==hex then table.remove(pendExcl,i); found=true; break end end
            if not found then table.insert(pendExcl,hex) end
            RefreshEP()
        end)
    end
    EPScroll.CanvasSize=UDim2.new(0,0,0,EPLayout.AbsoluteContentSize.Y+4)
    if n==0 then MkLabel(EPScroll,"Scan ก่อน",UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),9,Color3.fromRGB(135,85,85),nil,nil,10) end
    ELabel.Text=#Settings.ExcludeColors>0 and "🚫 Exclude: "..#Settings.ExcludeColors.." สี" or "🚫 Exclude: ไม่มี"
    ELabel.TextColor3=#Settings.ExcludeColors>0 and Color3.fromRGB(255,135,135) or Color3.fromRGB(175,115,115)
end

-- RESPAWN
LocalPlayer.CharacterAdded:Connect(function(c)
    Character=c; c:WaitForChild("HumanoidRootPart"); currentTarget=nil; ClearESP()
    if Settings.Enabled then task.wait(0.5); StartLock() end
end)

-- INPUT BOXES
StrBox.FocusLost:Connect(function()
    local v=tonumber(StrBox.Text)
    if v then Settings.LockStrength=v; StrBox.Text=tostring(v); SaveSettings()
    else StrBox.Text=tostring(Settings.LockStrength) end
end)
RangeBox.FocusLost:Connect(function()
    local v=tonumber(RangeBox.Text)
    if v then Settings.LockRange=v; RangeBox.Text=tostring(v); SaveSettings()
    else RangeBox.Text=tostring(Settings.LockRange) end
end)
CamDistBox.FocusLost:Connect(function()
    local v=tonumber(CamDistBox.Text)
    if v then CAM_DISTANCE=v; CamDistBox.Text=tostring(v); SaveSettings()
    else CamDistBox.Text=tostring(CAM_DISTANCE) end
end)
CamDistInput.FocusLost:Connect(function()
    local v=tonumber(CamDistInput.Text)
    if v then camDistance=v; CamDistInput.Text=tostring(v) end
end)

-- BUTTONS
ModePlayer.Activated:Connect(function() Settings.Mode="Player"; currentTarget=nil; UpdateModeUI(); SaveSettings() end)
ModeNPC.Activated:Connect(function() Settings.Mode="NPC"; currentTarget=nil; UpdateModeUI(); SaveSettings() end)

AimHead.Activated:Connect(function() Settings.AimMode="head"; UpdateAimUI(); SaveSettings() end)
AimBody.Activated:Connect(function() Settings.AimMode="body"; UpdateAimUI(); SaveSettings() end)

LockBtn.Activated:Connect(function()
    Settings.Enabled=not Settings.Enabled
    if Settings.Enabled then
        LockBtn.Text="🔒 Lock : ON"; LockBtn.BackgroundColor3=Color3.fromRGB(22,62,22); StartLock()
    else
        LockBtn.Text="🔓 Lock : OFF"; LockBtn.BackgroundColor3=Color3.fromRGB(24,24,38); StopLock()
    end
end)

NearBtn.Activated:Connect(function()
    Settings.NearestMode=not Settings.NearestMode
    NearBtn.Text=Settings.NearestMode and "📍 Nearest : ON" or "📍 Nearest : OFF"
    NearBtn.BackgroundColor3=Settings.NearestMode and Color3.fromRGB(22,52,22) or Color3.fromRGB(24,24,38)
    SaveSettings()
end)

PrevBtn.Activated:Connect(function()
    if #targetList==0 then targetList=FilterList(GetTargetList()) end
    if #targetList>0 then
        targetIndex=targetIndex-1; if targetIndex<1 then targetIndex=#targetList end
        SetTarget(targetList[targetIndex].model)
    end
end)
NextBtn.Activated:Connect(function()
    if #targetList==0 then targetList=FilterList(GetTargetList()) end
    if #targetList>0 then
        targetIndex=targetIndex+1; if targetIndex>#targetList then targetIndex=1 end
        SetTarget(targetList[targetIndex].model)
    end
end)

ESPBtn.Activated:Connect(function()
    Settings.ESPEnabled=not Settings.ESPEnabled
    ESPBtn.Text=Settings.ESPEnabled and "👁 ESP : ON" or "👁 ESP"
    ESPBtn.BackgroundColor3=Settings.ESPEnabled and Color3.fromRGB(18,48,68) or Color3.fromRGB(24,24,38)
    if not Settings.ESPEnabled then ClearESP() end
end)

LockMenuBtn.Activated:Connect(function()
    menuLocked=not menuLocked
    LockMenuBtn.Text=menuLocked and "🔒" or "🔓"
    LockMenuBtn.BackgroundColor3=menuLocked and Color3.fromRGB(68,52,12) or Color3.fromRGB(40,40,65)
end)

local minimized=false
MinBtn.Activated:Connect(function()
    minimized=not minimized; Content.Visible=not minimized
    MainFrame.Size=minimized and UDim2.new(0,230,0,32) or UDim2.new(0,230,0,395)
end)
CloseBtn.Activated:Connect(function()
    StopLock(); ClearESP()
    pcall(function() espIdleConn:Disconnect() end)
    ScreenGui:Destroy()
end)

local scanVis=false
ScanBtn.Activated:Connect(function()
    scanVis=not scanVis; ScanFrame.Visible=scanVis
    ScanBtn.BackgroundColor3=scanVis and Color3.fromRGB(22,38,78) or Color3.fromRGB(24,24,38)
end)
ScanClsB.Activated:Connect(function()
    scanVis=false; ScanFrame.Visible=false; CPop.Visible=false; EPop.Visible=false
    ScanBtn.BackgroundColor3=Color3.fromRGB(24,24,38)
end)
local scanMin2=false
ScanMinB.Activated:Connect(function()
    scanMin2=not scanMin2
    ScanScroll.Visible=not scanMin2; DoScanB.Visible=not scanMin2
    ScanCnt.Visible=not scanMin2; FBar.Visible=not scanMin2; EBar.Visible=not scanMin2
    ScanFrame.Size=scanMin2 and UDim2.new(0,215,0,30) or UDim2.new(0,215,0,340)
    if scanMin2 then CPop.Visible=false; EPop.Visible=false end
end)

DoScanB.Activated:Connect(function()
    for _,c in ipairs(ScanScroll:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local raw=GetTargetList(); foundColors={}
    for _,e in ipairs(raw) do local h=ColorToHex(e.color); if not foundColors[h] then foundColors[h]=e.color end end
    local list=FilterList(raw); targetList=list
    ScanCnt.Text=#list.." found  (raw: "..#raw..")"
    for i,e in ipairs(list) do
        local b=MkBtn(ScanScroll,string.format("  [%d] %s  %.0fm",i,e.name,e.dist),
            UDim2.new(1,0,0,25),UDim2.new(0,0,0,0),Color3.fromRGB(14,14,24),e.color,9)
        b.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,6,0,6); dot.Position=UDim2.new(0,4,0.5,-3)
        dot.BackgroundColor3=e.color; dot.BorderSizePixel=0; dot.Parent=b
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        b.Activated:Connect(function() targetIndex=i; SetTarget(e.model) end)
    end
    ScanScroll.CanvasSize=UDim2.new(0,0,0,ScanLayout.AbsoluteContentSize.Y+4)
    RefreshCP(); RefreshEP()
end)

CPBtn2.Activated:Connect(function() CPop.Visible=not CPop.Visible; EPop.Visible=false; if CPop.Visible then RefreshCP() end end)
CPClsBtn.Activated:Connect(function() CPop.Visible=false end)
CPAllBtn.Activated:Connect(function()
    Settings.FilterColor=nil; FLabel.Text="🎨 Filter: ทั้งหมด"; FLabel.TextColor3=Color3.fromRGB(115,115,175)
    CPBtn2.BackgroundColor3=Color3.fromRGB(50,50,170); CPop.Visible=false; RefreshCP()
end)
FClrBtn.Activated:Connect(function()
    Settings.FilterColor=nil; FLabel.Text="🎨 Filter: ทั้งหมด"; FLabel.TextColor3=Color3.fromRGB(115,115,175); RefreshCP()
end)

ExclBtn.Activated:Connect(function()
    EPop.Visible=not EPop.Visible; CPop.Visible=false
    if EPop.Visible then pendExcl={}; for _,h in ipairs(Settings.ExcludeColors) do table.insert(pendExcl,h) end; RefreshEP() end
end)
EPClsBtn.Activated:Connect(function() EPop.Visible=false; pendExcl={} end)
EPOKBtn.Activated:Connect(function()
    Settings.ExcludeColors={}
    for _,h in ipairs(pendExcl) do table.insert(Settings.ExcludeColors,h) end
    RefreshEP(); EPop.Visible=false; pendExcl={}
end)
EClrBtn.Activated:Connect(function() Settings.ExcludeColors={}; pendExcl={}; RefreshEP() end)

local tpVis=false
TPBtn.Activated:Connect(function()
    tpVis=not tpVis; TPFrame.Visible=tpVis
    TPBtn.BackgroundColor3=tpVis and Color3.fromRGB(18,52,28) or Color3.fromRGB(24,24,38)
    if tpVis then TPRefresh() end
end)
TPClsBtn.Activated:Connect(function() tpVis=false; TPFrame.Visible=false; TPBtn.BackgroundColor3=Color3.fromRGB(24,24,38) end)
local tpMin2=false
TPMinBtn.Activated:Connect(function()
    tpMin2=not tpMin2
    TPScroll.Visible=not tpMin2; TPSaveBtn.Visible=not tpMin2; TPClickBtn.Visible=not tpMin2; TPDelBtn.Visible=not tpMin2
    TPFrame.Size=tpMin2 and UDim2.new(0,210,0,30) or UDim2.new(0,210,0,252)
end)
TPSaveBtn.Activated:Connect(function()
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local r=char:FindFirstChild("HumanoidRootPart"); if not r then return end
    table.insert(tpSaves,{x=r.Position.X,y=r.Position.Y,z=r.Position.Z}); TPRefresh()
end)
TPDelBtn.Activated:Connect(function()
    if tpSelected then table.remove(tpSaves,tpSelected); tpSelected=nil; TPRefresh() end
end)
TPClickBtn.Activated:Connect(function()
    clickTP=not clickTP
    if not clickTP then lockPos=nil end
    TPClickBtn.Text=clickTP and "Click TP ON" or "Click TP"
    TPClickBtn.BackgroundColor3=clickTP and Color3.fromRGB(22,88,38) or Color3.fromRGB(125,35,35)
end)
Mouse.Button1Down:Connect(function()
    if not clickTP then return end
    lockPos=nil
    local char=LocalPlayer.Character; if not char then return end
    local r=char:FindFirstChild("HumanoidRootPart"); if not r then return end
    local hit=Mouse.Hit
    if hit then lockPos=hit.Position; r.CFrame=CFrame.new(lockPos+Vector3.new(0,3,0)) end
end)
RunService.Heartbeat:Connect(function()
    if clickTP and lockPos then
        local char=LocalPlayer.Character; if not char then return end
        local r=char:FindFirstChild("HumanoidRootPart"); if not r then return end
        if (r.Position-lockPos).Magnitude>10 then r.CFrame=CFrame.new(lockPos+Vector3.new(0,3,0)) end
    end
end)

local camVis=false
CamBtn.Activated:Connect(function()
    camVis=not camVis; CamFrame.Visible=camVis
    CamBtn.BackgroundColor3=camVis and Color3.fromRGB(62,42,12) or Color3.fromRGB(24,24,38)
end)
CClsBtn.Activated:Connect(function()
    camVis=false; CamFrame.Visible=false; CamBtn.BackgroundColor3=Color3.fromRGB(24,24,38)
    camLocked=false; camFree=false; CamCtrl.Visible=false
end)
local camMin2=false
CMinBtn.Activated:Connect(function()
    camMin2=not camMin2
    CamLockBtn.Visible=not camMin2; CamFreeBtn.Visible=not camMin2; CamDistInput.Visible=not camMin2
    CamFrame.Size=camMin2 and UDim2.new(0,188,0,30) or UDim2.new(0,188,0,142)
end)
CamLockBtn.Activated:Connect(function()
    camLocked=not camLocked
    CamLockBtn.Text=camLocked and "🔒 Cam Lock ON" or "🔒 Cam Lock OFF"
    CamLockBtn.BackgroundColor3=camLocked and Color3.fromRGB(22,68,22) or Color3.fromRGB(125,35,35)
end)
CamFreeBtn.Activated:Connect(function()
    camFree=not camFree
    CamFreeBtn.Text=camFree and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    CamFreeBtn.BackgroundColor3=camFree and Color3.fromRGB(22,68,22) or Color3.fromRGB(125,35,35)
    CamCtrl.Visible=camFree
    if camFree then camPos_free=Camera.CFrame.Position end
end)

-- INIT
UpdateAimUI()
if Settings.NearestMode then
    NearBtn.Text="📍 Nearest : ON"; NearBtn.BackgroundColor3=Color3.fromRGB(22,52,22)
end
