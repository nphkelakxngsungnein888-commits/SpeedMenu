-- Lock Menu v15 | Codex Android | Smooth Lock + ESP + CamSystem + TP
-- Heartbeat only | ESP every 0.2s | No shake any strength

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()

-- SAVE/LOAD
local _S = _G.LockMenuSave or {}
local Settings = {
    LockStrength  = _S.LockStrength or 0.3,
    LockRange     = _S.LockRange    or 100,
    Mode          = _S.Mode         or "NPC",
    Enabled       = false,
    NearestMode   = _S.NearestMode  or false,
    FilterColor   = nil,
    ESPEnabled    = false,
    ExcludeColors = {},
    AimMode       = _S.AimMode      or "body",
}
local CAM_DISTANCE  = _S.CAM_DISTANCE or 15
local CAM_HEIGHT    = 3
local SCAN_INTERVAL = 0.1
local ESP_INTERVAL  = 0.2

local function SaveSettings()
    _G.LockMenuSave = {
        LockStrength = Settings.LockStrength,
        LockRange    = Settings.LockRange,
        Mode         = Settings.Mode,
        NearestMode  = Settings.NearestMode,
        CAM_DISTANCE = CAM_DISTANCE,
        AimMode      = Settings.AimMode,
    }
end

-- STATE
local Character     = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local currentTarget = nil
local targetList    = {}
local targetIndex   = 1
local lockConn      = nil
local foundColors   = {}
local forceRescan   = false
local espBoxes      = {}
local espTimer      = 0
local tpSaves       = {}
local tpSelected    = nil
local clickTP       = false
local lockPos       = nil
local camEnabled    = false
local camFreecam    = false
local camDistance   = 50
local camAngleX, camAngleY = 0, 0
local camSpeed      = 5
local camMove       = Vector3.new()
local camFreePos    = Vector3.new()

-- GUI CLEANUP
pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("LockMenu_v15")
        if old then old:Destroy() end
    end
end)

local PGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockMenu_v15"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PGui

-- HELPERS
local function Hex(c)
    return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
end

local function Frame(par,sz,pos,bg,clip,r)
    local f=Instance.new("Frame")
    f.Size=sz; f.Position=pos
    f.BackgroundColor3=bg or Color3.fromRGB(14,14,20)
    f.BorderSizePixel=0
    if clip then f.ClipsDescendants=true end
    f.Parent=par
    if r~=false then Instance.new("UICorner",f).CornerRadius=UDim.new(0,r or 8) end
    return f
end

local function Btn(par,txt,sz,pos,bg,tc,ts)
    local b=Instance.new("TextButton")
    b.Size=sz; b.Position=pos
    b.BackgroundColor3=bg or Color3.fromRGB(30,30,46)
    b.BorderSizePixel=0; b.Text=txt
    b.TextColor3=tc or Color3.fromRGB(210,210,255)
    b.TextSize=ts or 11; b.Font=Enum.Font.GothamBold
    b.Parent=par
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    return b
end

local function Lbl(par,txt,sz,pos,ts,tc,font,xa)
    local l=Instance.new("TextLabel")
    l.Size=sz; l.Position=pos; l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=tc or Color3.fromRGB(160,160,210)
    l.TextSize=ts or 10; l.Font=font or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.Parent=par; return l
end

local function Inp(par,def,sz,pos)
    local b=Instance.new("TextBox")
    b.Size=sz; b.Position=pos
    b.BackgroundColor3=Color3.fromRGB(20,20,32); b.BorderSizePixel=0
    b.Text=tostring(def); b.TextColor3=Color3.fromRGB(230,230,255)
    b.TextSize=11; b.Font=Enum.Font.Gotham; b.Parent=par
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end

local function Div(par,y)
    local d=Instance.new("Frame")
    d.Size=UDim2.new(1,-16,0,1); d.Position=UDim2.new(0,8,0,y)
    d.BackgroundColor3=Color3.fromRGB(38,38,58); d.BorderSizePixel=0; d.Parent=par
end

local function AccLine(par)
    local a=Instance.new("Frame"); a.Size=UDim2.new(1,0,0,2)
    a.Position=UDim2.new(0,0,1,-2)
    a.BackgroundColor3=Color3.fromRGB(75,115,255); a.BorderSizePixel=0; a.Parent=par
end

local function Drag(frame,handle,lockFn)
    local drag,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(i)
        if lockFn and lockFn() then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=frame.Position
        end
    end)
    local function mv(i)
        if drag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end
    local function en(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end
    handle.InputChanged:Connect(mv); UserInputService.InputChanged:Connect(mv)
    handle.InputEnded:Connect(en); UserInputService.InputEnded:Connect(en)
end

-- MAIN FRAME
local menuLocked=false
local MF=Frame(ScreenGui,UDim2.new(0,230,0,410),UDim2.new(0.5,-115,0.5,-205),Color3.fromRGB(11,11,17),true)
local TBar=Frame(MF,UDim2.new(1,0,0,32),UDim2.new(0,0,0,0),Color3.fromRGB(18,18,30),false,8)
TBar.ClipsDescendants=false; AccLine(TBar)
Drag(MF,TBar,function() return menuLocked end)
Lbl(TBar,"⚔ Lock Menu v15",UDim2.new(1,-112,1,0),UDim2.new(0,10,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local LockMenuBtn=Btn(TBar,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-72,0.5,-11),Color3.fromRGB(42,42,64),Color3.fromRGB(200,200,255),12)
local MinBtn=Btn(TBar,"–",UDim2.new(0,22,0,22),UDim2.new(1,-48,0.5,-11),Color3.fromRGB(42,42,64),Color3.fromRGB(255,255,255),14)
local CloseBtn=Btn(TBar,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-24,0.5,-11),Color3.fromRGB(155,34,34),Color3.fromRGB(255,255,255),12)

local Con=Instance.new("Frame"); Con.Size=UDim2.new(1,0,1,-32); Con.Position=UDim2.new(0,0,0,32)
Con.BackgroundTransparency=1; Con.Parent=MF

Lbl(Con,"🎯 MODE",UDim2.new(0,80,0,13),UDim2.new(0,8,0,6),9)
local ModePlayer=Btn(Con,"👤 Player",UDim2.new(0,99,0,26),UDim2.new(0,8,0,21),Color3.fromRGB(30,30,48),Color3.fromRGB(150,160,220))
local ModeNPC   =Btn(Con,"🤖 NPC",   UDim2.new(0,99,0,26),UDim2.new(0,115,0,21),Color3.fromRGB(65,95,210),Color3.fromRGB(255,255,255))

local function UpdateModeUI()
    if Settings.Mode=="Player" then
        ModePlayer.BackgroundColor3=Color3.fromRGB(65,95,210); ModePlayer.TextColor3=Color3.fromRGB(255,255,255)
        ModeNPC.BackgroundColor3=Color3.fromRGB(30,30,48);    ModeNPC.TextColor3=Color3.fromRGB(150,160,220)
    else
        ModeNPC.BackgroundColor3=Color3.fromRGB(65,95,210);   ModeNPC.TextColor3=Color3.fromRGB(255,255,255)
        ModePlayer.BackgroundColor3=Color3.fromRGB(30,30,48); ModePlayer.TextColor3=Color3.fromRGB(150,160,220)
    end
end; UpdateModeUI()

Div(Con,53)
Lbl(Con,"⚡ Strength",UDim2.new(0,100,0,13),UDim2.new(0,8,0,57),9)
Lbl(Con,"📏 Range",   UDim2.new(0,100,0,13),UDim2.new(0,120,0,57),9)
local StrBox  =Inp(Con,Settings.LockStrength,UDim2.new(0,96,0,24),UDim2.new(0,8,0,70))
local RangeBox=Inp(Con,Settings.LockRange,   UDim2.new(0,96,0,24),UDim2.new(0,120,0,70))

Div(Con,100)
Lbl(Con,"🎯 Aim Mode", UDim2.new(0,100,0,13),UDim2.new(0,8,0,104),9)
Lbl(Con,"📷 Cam Dist", UDim2.new(0,100,0,13),UDim2.new(0,120,0,104),9)
local AimHead =Btn(Con,"🗣 Head",UDim2.new(0,46,0,24),UDim2.new(0,8,0,117),
    Settings.AimMode=="head" and Color3.fromRGB(65,95,210) or Color3.fromRGB(30,30,48),Color3.fromRGB(220,220,255),10)
local AimBody =Btn(Con,"🧍 Body",UDim2.new(0,46,0,24),UDim2.new(0,58,0,117),
    Settings.AimMode=="body" and Color3.fromRGB(65,95,210) or Color3.fromRGB(30,30,48),Color3.fromRGB(220,220,255),10)
local CamDistBox=Inp(Con,CAM_DISTANCE,UDim2.new(0,96,0,24),UDim2.new(0,120,0,117))

Div(Con,147)
local LockBtn=Btn(Con,"🔓 Lock : OFF",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,153),Color3.fromRGB(26,26,42),Color3.fromRGB(180,180,255),12)
local NearBtn=Btn(Con,"📍 Nearest : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,187),Color3.fromRGB(26,26,42),Color3.fromRGB(155,155,215),11)

local PrevBtn=Btn(Con,"◀",UDim2.new(0,38,0,26),UDim2.new(0,8,0,219),Color3.fromRGB(30,30,48),Color3.fromRGB(180,180,255),13)
local TLbl=Instance.new("TextLabel"); TLbl.Size=UDim2.new(0,122,0,26); TLbl.Position=UDim2.new(0,50,0,219)
TLbl.BackgroundColor3=Color3.fromRGB(16,16,28); TLbl.BorderSizePixel=0; TLbl.Text="No Target"
TLbl.TextColor3=Color3.fromRGB(135,175,255); TLbl.TextSize=10; TLbl.Font=Enum.Font.GothamBold
TLbl.TextTruncate=Enum.TextTruncate.AtEnd; TLbl.Parent=Con
Instance.new("UICorner",TLbl).CornerRadius=UDim.new(0,5)
local NextBtn=Btn(Con,"▶",UDim2.new(0,38,0,26),UDim2.new(0,176,0,219),Color3.fromRGB(30,30,48),Color3.fromRGB(180,180,255),13)

Div(Con,251)
local ESPBtn   =Btn(Con,"👁 ESP",  UDim2.new(0,50,0,26),UDim2.new(0,8,0,257),  Color3.fromRGB(26,26,42),Color3.fromRGB(155,155,215),10)
local ScanBtn  =Btn(Con,"🔍 Scan", UDim2.new(0,50,0,26),UDim2.new(0,62,0,257), Color3.fromRGB(26,26,42),Color3.fromRGB(155,155,215),10)
local CamSysBtn=Btn(Con,"📷 Cam",  UDim2.new(0,50,0,26),UDim2.new(0,116,0,257),Color3.fromRGB(26,26,42),Color3.fromRGB(155,155,215),10)
local TPBtn    =Btn(Con,"🚀 TP",   UDim2.new(0,46,0,26),UDim2.new(0,170,0,257),Color3.fromRGB(26,26,42),Color3.fromRGB(155,155,215),10)

Div(Con,289)
local StatusLbl=Lbl(Con,"● Idle",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,294),10,Color3.fromRGB(70,70,100))

-- SCAN FRAME
local SF=Frame(ScreenGui,UDim2.new(0,220,0,340),UDim2.new(0.5,125,0.5,-170),Color3.fromRGB(11,11,17),true)
SF.Visible=false
local STBar=Frame(SF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(18,18,30),false,8); AccLine(STBar)
Drag(SF,STBar,nil)
Lbl(STBar,"🔍 Scan",UDim2.new(1,-108,1,0),UDim2.new(0,8,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local CPBtn2   =Btn(STBar,"🎨",UDim2.new(0,22,0,22),UDim2.new(1,-92,0.5,-11),Color3.fromRGB(50,50,165),Color3.fromRGB(255,255,255),11)
local ExcBtn   =Btn(STBar,"🚫",UDim2.new(0,22,0,22),UDim2.new(1,-68,0.5,-11),Color3.fromRGB(105,32,32),Color3.fromRGB(255,175,175),11)
local SMinBtn  =Btn(STBar,"–", UDim2.new(0,20,0,20),UDim2.new(1,-44,0.5,-10),Color3.fromRGB(42,42,64),Color3.fromRGB(255,255,255),12)
local SCloseBtn=Btn(STBar,"✕", UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(155,34,34),Color3.fromRGB(255,255,255),10)

local FBar=Frame(SF,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,32),Color3.fromRGB(17,17,27),false,5)
local FLbl=Lbl(FBar,"🎨 Filter: ทั้งหมด",UDim2.new(1,-30,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(125,125,175))
local CFBtn=Btn(FBar,"✕",UDim2.new(0,22,0,16),UDim2.new(1,-24,0.5,-8),Color3.fromRGB(66,26,26),Color3.fromRGB(255,145,145),9)

local EBar=Frame(SF,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,56),Color3.fromRGB(22,11,11),false,5)
local ELbl=Lbl(EBar,"🚫 Exclude: ไม่มี",UDim2.new(1,-30,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(175,110,110))
local CEBtn=Btn(EBar,"✕",UDim2.new(0,22,0,16),UDim2.new(1,-24,0.5,-8),Color3.fromRGB(66,26,26),Color3.fromRGB(255,145,145),9)

local DoScan  =Btn(SF,"🔍 Scan Now",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,80),Color3.fromRGB(34,34,68),Color3.fromRGB(185,185,255),11)
local SCntLbl =Lbl(SF,"0 found",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,108),9,Color3.fromRGB(75,75,115))
local SSroll  =Instance.new("ScrollingFrame")
SSroll.Size=UDim2.new(1,-8,1,-125); SSroll.Position=UDim2.new(0,4,0,124)
SSroll.BackgroundTransparency=1; SSroll.BorderSizePixel=0
SSroll.ScrollBarThickness=3; SSroll.CanvasSize=UDim2.new(0,0,0,0); SSroll.Parent=SF
local SLayout=Instance.new("UIListLayout"); SLayout.Padding=UDim.new(0,3); SLayout.Parent=SSroll

-- COLOR PICKER
local CPop=Frame(ScreenGui,UDim2.new(0,200,0,230),UDim2.new(0.5,125,0.5,175),Color3.fromRGB(12,12,19),true)
CPop.Visible=false; CPop.ZIndex=10
local CPBar=Frame(CPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,18,30),false,8); CPBar.ZIndex=10
Drag(CPop,CPBar,nil)
Lbl(CPBar,"🎨 Filter Color",UDim2.new(1,-30,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local CPClose=Btn(CPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(155,34,34),Color3.fromRGB(255,255,255),10); CPClose.ZIndex=10
local CPAll  =Btn(CPop,"✅ แสดงทั้งหมด",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,30),Color3.fromRGB(28,48,28),Color3.fromRGB(175,255,175),9); CPAll.ZIndex=10
local CPScr  =Instance.new("ScrollingFrame")
CPScr.Size=UDim2.new(1,-8,1,-56); CPScr.Position=UDim2.new(0,4,0,54)
CPScr.BackgroundTransparency=1; CPScr.BorderSizePixel=0; CPScr.ScrollBarThickness=3
CPScr.CanvasSize=UDim2.new(0,0,0,0); CPScr.ZIndex=10; CPScr.Parent=CPop
local CPLayout=Instance.new("UIListLayout"); CPLayout.Padding=UDim.new(0,3); CPLayout.Parent=CPScr

-- EXCLUDE POPUP
local EPop=Frame(ScreenGui,UDim2.new(0,200,0,260),UDim2.new(0.5,125,0.5,175),Color3.fromRGB(17,9,9),true)
EPop.Visible=false; EPop.ZIndex=10
local EPBar=Frame(EPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(26,14,14),false,8); EPBar.ZIndex=10
Drag(EPop,EPBar,nil)
Lbl(EPBar,"🚫 Exclude Color",UDim2.new(1,-30,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,195,195),Enum.Font.GothamBold)
local EPClose=Btn(EPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(155,34,34),Color3.fromRGB(255,255,255),10); EPClose.ZIndex=10
Lbl(EPop,"กดเลือกสีที่ไม่ต้องการล็อค",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,30),9,Color3.fromRGB(195,155,155))
local EPOk=Btn(EPop,"✅ OK ยืนยัน",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,52),Color3.fromRGB(28,52,28),Color3.fromRGB(175,255,175),9); EPOk.ZIndex=10
local EPScr=Instance.new("ScrollingFrame")
EPScr.Size=UDim2.new(1,-8,1,-80); EPScr.Position=UDim2.new(0,4,0,78)
EPScr.BackgroundTransparency=1; EPScr.BorderSizePixel=0; EPScr.ScrollBarThickness=3
EPScr.CanvasSize=UDim2.new(0,0,0,0); EPScr.ZIndex=10; EPScr.Parent=EPop
local EPLayout=Instance.new("UIListLayout"); EPLayout.Padding=UDim.new(0,3); EPLayout.Parent=EPScr

-- CAMERA SYSTEM FRAME
local CamF=Frame(ScreenGui,UDim2.new(0,190,0,200),UDim2.new(0.5,-340,0.5,-100),Color3.fromRGB(11,11,17),true)
CamF.Visible=false
local CamBar=Frame(CamF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(18,18,30),false,8)
local cA=Instance.new("Frame"); cA.Size=UDim2.new(1,0,0,2); cA.Position=UDim2.new(0,0,1,-2)
cA.BackgroundColor3=Color3.fromRGB(255,155,55); cA.BorderSizePixel=0; cA.Parent=CamBar
Drag(CamF,CamBar,nil)
Lbl(CamBar,"📷 Camera System",UDim2.new(1,-55,1,0),UDim2.new(0,8,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local CamMin  =Btn(CamBar,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(42,42,64),Color3.fromRGB(255,255,255),13)
local CamClose=Btn(CamBar,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(155,34,34),Color3.fromRGB(255,255,255),12)
local CamCon=Instance.new("Frame"); CamCon.Size=UDim2.new(1,0,1,-30); CamCon.Position=UDim2.new(0,0,0,30)
CamCon.BackgroundTransparency=1; CamCon.Parent=CamF
local CamLockBtn=Btn(CamCon,"🔒 Lock Cam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,5), Color3.fromRGB(155,34,34),Color3.fromRGB(255,195,195),11)
local CamFreeBtn=Btn(CamCon,"🎥 FreeCam OFF", UDim2.new(1,-10,0,30),UDim2.new(0,5,0,40),Color3.fromRGB(155,34,34),Color3.fromRGB(255,195,195),11)
Lbl(CamCon,"📏 Distance",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,76),9)
local CamDistInp =Inp(CamCon,camDistance,UDim2.new(1,-10,0,26),UDim2.new(0,5,0,89))
Lbl(CamCon,"⚡ Speed",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,120),9)
local CamSpeedInp=Inp(CamCon,camSpeed,   UDim2.new(1,-10,0,26),UDim2.new(0,5,0,133))

local CtrlPad=Frame(ScreenGui,UDim2.new(0,160,0,160),UDim2.new(0.75,0,0.6,0),nil,false,0)
CtrlPad.BackgroundTransparency=1; CtrlPad.Visible=false
local function CPBtn(txt,pos)
    return Btn(CtrlPad,txt,UDim2.new(0,45,0,45),pos,Color3.fromRGB(42,42,64),Color3.fromRGB(255,255,255),13)
end
local bF=CPBtn("↑",UDim2.new(0.5,-22,0,0)); local bB=CPBtn("↓",UDim2.new(0.5,-22,0,90))
local bL=CPBtn("←",UDim2.new(0,0,0.5,-22)); local bR=CPBtn("→",UDim2.new(0,90,0.5,-22))
local bU=CPBtn("▲",UDim2.new(0,0,0,0));     local bD=CPBtn("▼",UDim2.new(0,90,0,0))
local function BindPad(btn,vec)
    btn.MouseButton1Down:Connect(function() camMove=camMove+vec end)
    btn.MouseButton1Up:Connect(function()   camMove=camMove-vec end)
end
BindPad(bF,Vector3.new(0,0,-1)); BindPad(bB,Vector3.new(0,0,1))
BindPad(bL,Vector3.new(-1,0,0)); BindPad(bR,Vector3.new(1,0,0))
BindPad(bU,Vector3.new(0,1,0));  BindPad(bD,Vector3.new(0,-1,0))

-- TP FRAME
local TF=Frame(ScreenGui,UDim2.new(0,210,0,260),UDim2.new(0.5,-340,0.5,110),Color3.fromRGB(11,11,17),true)
TF.Visible=false
local TFBar=Frame(TF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(18,18,30),false,8)
local tA=Instance.new("Frame"); tA.Size=UDim2.new(1,0,0,2); tA.Position=UDim2.new(0,0,1,-2)
tA.BackgroundColor3=Color3.fromRGB(55,195,115); tA.BorderSizePixel=0; tA.Parent=TFBar
Drag(TF,TFBar,nil)
Lbl(TFBar,"🚀 Teleport Save",UDim2.new(1,-55,1,0),UDim2.new(0,8,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local TFMin  =Btn(TFBar,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(42,42,64),Color3.fromRGB(255,255,255),13)
local TFClose=Btn(TFBar,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(155,34,34),Color3.fromRGB(255,255,255),12)
local TPSave=Btn(TF,"+ Save",    UDim2.new(0,60,0,26),UDim2.new(0,5,0,34),  Color3.fromRGB(22,70,22),Color3.fromRGB(175,255,175),11)
local TPClic=Btn(TF,"Click TP OFF",UDim2.new(0,80,0,26),UDim2.new(0,68,0,34), Color3.fromRGB(135,34,34),Color3.fromRGB(255,175,175),10)
local TPDel =Btn(TF,"Delete",    UDim2.new(0,55,0,26),UDim2.new(0,152,0,34), Color3.fromRGB(75,26,26),Color3.fromRGB(255,145,145),10)
local TPScr =Instance.new("ScrollingFrame")
TPScr.Size=UDim2.new(1,-10,1,-68); TPScr.Position=UDim2.new(0,5,0,64)
TPScr.BackgroundColor3=Color3.fromRGB(14,14,21); TPScr.BorderSizePixel=0
TPScr.ScrollBarThickness=3; TPScr.CanvasSize=UDim2.new(0,0,0,0); TPScr.Parent=TF
Instance.new("UICorner",TPScr).CornerRadius=UDim.new(0,5)
local TPLayout=Instance.new("UIListLayout"); TPLayout.Padding=UDim.new(0,4); TPLayout.Parent=TPScr

-- LOGIC HELPERS
local function GetTeamColor(model)
    local p=Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    if p then
        local mt=LocalPlayer.Team
        if mt and p.Team then return p.Team==mt and Color3.fromRGB(55,195,95) or Color3.fromRGB(215,55,55) end
    end
    return Color3.fromRGB(215,115,45)
end

local function IsExcluded(color)
    local h=Hex(color)
    for _,eh in ipairs(Settings.ExcludeColors) do if eh==h then return true end end
    return false
end

local function GetRoot(model)
    local r=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model.PrimaryPart
    if not r then for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then return p end end end
    return r
end

local function GetAimOffset(model)
    local hum=model:FindFirstChildOfClass("Humanoid")
    if Settings.AimMode=="head" then
        local head=model:FindFirstChild("Head")
        if head then
            local hrp=GetRoot(model)
            if hrp then return head.Position.Y-hrp.Position.Y end
        end
        if hum and hum.HipHeight>0 then return hum.HipHeight*1.8 end
        return 2.5
    else
        if hum and hum.HipHeight>0 then return hum.HipHeight*0.5 end
        return 0.5
    end
end

local function GetTargetList()
    local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list={}; local range=tonumber(RangeBox.Text) or Settings.LockRange
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
                    local hrp=GetRoot(obj)
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
    local fh=Hex(Settings.FilterColor); local out={}
    for _,e in ipairs(list) do if Hex(e.color)==fh then table.insert(out,e) end end
    return out
end

local function SetTarget(model)
    currentTarget=model
    if model then
        TLbl.Text=model.Name; StatusLbl.Text="🔒 "..model.Name; StatusLbl.TextColor3=Color3.fromRGB(95,185,255)
    else
        TLbl.Text="No Target"; StatusLbl.Text="● Idle"; StatusLbl.TextColor3=Color3.fromRGB(65,65,95)
    end
end

-- ESP
local function ClearESP()
    for _,bb in pairs(espBoxes) do pcall(function() bb:Destroy() end) end; espBoxes={}
end

local function UpdateESP()
    local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then ClearESP(); return end
    local list=GetTargetList(); local active={}
    for _,e in ipairs(list) do
        local m=e.model; active[m]=true
        local hrp=GetRoot(m); if not hrp then continue end
        if not espBoxes[m] then
            local bb=Instance.new("BillboardGui")
            bb.Adornee=hrp; bb.AlwaysOnTop=true; bb.LightInfluence=0
            bb.Size=UDim2.new(0,40,0,50); bb.Parent=hrp
            local box=Instance.new("Frame"); box.Size=UDim2.new(1,0,1,0)
            box.BackgroundTransparency=1; box.BorderSizePixel=0; box.Parent=bb
            local sk=Instance.new("UIStroke"); sk.Color=Color3.fromRGB(255,255,255)
            sk.Thickness=1.5; sk.Parent=box
            local dl=Instance.new("TextLabel"); dl.Name="D"
            dl.Size=UDim2.new(1,0,0,14); dl.Position=UDim2.new(0,0,1,2)
            dl.BackgroundTransparency=1; dl.Text="0m"
            dl.TextColor3=Color3.fromRGB(255,255,255); dl.TextSize=11
            dl.Font=Enum.Font.GothamBold; dl.Parent=bb
            espBoxes[m]=bb
        end
        local s=math.clamp(80/math.max(e.dist,5),1.5,6)
        espBoxes[m].Size=UDim2.new(0,s*8,0,s*12)
        local dl=espBoxes[m]:FindFirstChild("D")
        if dl then dl.Text=string.format("%.0fm",e.dist) end
    end
    for m,bb in pairs(espBoxes) do
        if not active[m] then pcall(function() bb:Destroy() end); espBoxes[m]=nil end
    end
end

-- COLOR PICKER
local function UpdateCPicker()
    for _,c in ipairs(CPScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hs,col in pairs(foundColors) do
        n=n+1
        local b=Btn(CPScr,"  #"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left; b.ZIndex=11
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        if Settings.FilterColor and Hex(Settings.FilterColor)==hs then
            local sk=Instance.new("UIStroke"); sk.Color=Color3.fromRGB(255,255,255); sk.Thickness=2; sk.Parent=b
        end
        b.Activated:Connect(function()
            Settings.FilterColor=col; FLbl.Text="🎨 #"..hs; FLbl.TextColor3=col
            CPBtn2.BackgroundColor3=col; CPop.Visible=false; UpdateCPicker()
        end)
    end
    CPScr.CanvasSize=UDim2.new(0,0,0,CPLayout.AbsoluteContentSize.Y+4)
    if n==0 then Lbl(CPScr,"Scan ก่อน",UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),9,Color3.fromRGB(95,95,125)).ZIndex=11 end
end

-- EXCLUDE PICKER
local pendEx={}
local function UpdateEPicker()
    for _,c in ipairs(EPScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hs,col in pairs(foundColors) do
        n=n+1; local sel=false
        for _,h in ipairs(pendEx) do if h==hs then sel=true; break end end
        local b=Btn(EPScr,(sel and "✓ " or "  ").."#"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),
            sel and Color3.fromRGB(95,34,34) or col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left; b.ZIndex=11
        b.Activated:Connect(function()
            local found=false
            for i,h in ipairs(pendEx) do if h==hs then table.remove(pendEx,i); found=true; break end end
            if not found then table.insert(pendEx,hs) end; UpdateEPicker()
        end)
    end
    EPScr.CanvasSize=UDim2.new(0,0,0,EPLayout.AbsoluteContentSize.Y+4)
    if n==0 then Lbl(EPScr,"Scan ก่อน",UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),9,Color3.fromRGB(125,75,75)).ZIndex=11 end
    ELbl.Text=#Settings.ExcludeColors>0 and "🚫 Exclude: "..#Settings.ExcludeColors.." สี" or "🚫 Exclude: ไม่มี"
    ELbl.TextColor3=#Settings.ExcludeColors>0 and Color3.fromRGB(255,125,125) or Color3.fromRGB(175,105,105)
end

-- LOCK CORE (v13 style + no shake)
local function StartLock()
    if lockConn then lockConn:Disconnect(); lockConn=nil end
    local timer=0
    lockConn=RunService.Heartbeat:Connect(function(dt)
        local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        -- clamp 0.01-0.99 ป้องกันสั่น ไม่ว่าจะปรับค่าเท่าไหร่
        local str=math.clamp(tonumber(StrBox.Text) or Settings.LockStrength, 0.01, 0.99)
        if currentTarget then
            local hum=currentTarget:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health<=0 or not currentTarget.Parent then SetTarget(nil); forceRescan=true end
        end
        if not currentTarget or Settings.NearestMode or forceRescan then
            timer=timer+dt
            if forceRescan or timer>=SCAN_INTERVAL then
                timer=0; forceRescan=false
                local raw=GetTargetList(); local fil=FilterList(raw); targetList=fil
                if #fil>0 and(Settings.NearestMode or not currentTarget) then SetTarget(fil[1].model); targetIndex=1 end
            end
        end
        if not currentTarget then return end
        local hrp=GetRoot(currentTarget)
        local hum=currentTarget:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 or not currentTarget.Parent then SetTarget(nil); forceRescan=true; return end
        local offset=GetAimOffset(currentTarget)
        local aimPos=hrp.Position+Vector3.new(0,offset,0)
        local myPos=myHRP.Position
        local diff=Vector3.new(aimPos.X-myPos.X,0,aimPos.Z-myPos.Z)
        if diff.Magnitude<0.01 then return end
        local dir=diff.Unit
        local targetCF=CFrame.lookAt(myPos-dir*CAM_DISTANCE+Vector3.new(0,CAM_HEIGHT,0),aimPos)
        -- frame-independent lerp ไม่สั่น
        local alpha=1-(1-str)^(math.min(dt,0.05)*60)
        Camera.CFrame=Camera.CFrame:Lerp(targetCF,alpha)
        local bg=CFrame.new(myPos)*CFrame.Angles(0,math.atan2(-dir.X,-dir.Z),0)
        myHRP.CFrame=myHRP.CFrame:Lerp(bg,alpha)
    end)
end

local function StopLock()
    if lockConn then lockConn:Disconnect(); lockConn=nil end; SetTarget(nil)
end

-- MAIN LOOP
RunService.Heartbeat:Connect(function(dt)
    if Settings.ESPEnabled then
        espTimer=espTimer+dt
        if espTimer>=ESP_INTERVAL then espTimer=0; UpdateESP() end
    end
    if camEnabled and not camFreecam then
        local char=LocalPlayer.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local look=Camera.CFrame.LookVector
        Camera.CFrame=CFrame.new(root.Position-look*camDistance,root.Position)
    end
    if camFreecam then
        local rot=CFrame.Angles(0,math.rad(camAngleX),0)*CFrame.Angles(math.rad(camAngleY),0,0)
        local dir=rot.LookVector
        camFreePos=camFreePos+dir*camMove.Z*camSpeed+rot.RightVector*camMove.X*camSpeed+Vector3.new(0,camMove.Y*camSpeed,0)
        Camera.CFrame=CFrame.new(camFreePos,camFreePos+dir)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if camFreecam and(input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        camAngleX=camAngleX-input.Delta.X*0.2
        camAngleY=math.clamp(camAngleY-input.Delta.Y*0.2,-80,80)
    end
end)

-- TP HELPERS
local function TPRefresh()
    for _,c in ipairs(TPScr:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for i,pos in ipairs(tpSaves) do
        local b=Btn(TPScr,string.format("📍 %d  (%.0f,%.0f,%.0f)",i,pos.x,pos.y,pos.z),
            UDim2.new(1,-5,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(20,20,32),Color3.fromRGB(165,185,255),10)
        b.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        b.Activated:Connect(function()
            tpSelected=i
            local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root=char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame=CFrame.new(pos.x,pos.y,pos.z) end
            for _,c2 in ipairs(TPScr:GetChildren()) do
                if c2:IsA("TextButton") then c2.BackgroundColor3=Color3.fromRGB(20,20,32) end
            end
            b.BackgroundColor3=Color3.fromRGB(34,52,86)
        end)
    end
    TPScr.CanvasSize=UDim2.new(0,0,0,#tpSaves*30)
end

-- RESPAWN
LocalPlayer.CharacterAdded:Connect(function(c)
    Character=c; c:WaitForChild("HumanoidRootPart"); currentTarget=nil; ClearESP()
    if Settings.Enabled then task.wait(0.5); StartLock() end
end)

-- INPUT HANDLERS
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
CamDistInp.FocusLost:Connect(function()
    local v=tonumber(CamDistInp.Text); if v then camDistance=v else CamDistInp.Text=tostring(camDistance) end
end)
CamSpeedInp.FocusLost:Connect(function()
    local v=tonumber(CamSpeedInp.Text); if v then camSpeed=v else CamSpeedInp.Text=tostring(camSpeed) end
end)

-- CONNECTIONS
ModePlayer.Activated:Connect(function() Settings.Mode="Player"; currentTarget=nil; UpdateModeUI(); SaveSettings() end)
ModeNPC.Activated:Connect(function()   Settings.Mode="NPC";    currentTarget=nil; UpdateModeUI(); SaveSettings() end)
AimHead.Activated:Connect(function()
    Settings.AimMode="head"; SaveSettings()
    AimHead.BackgroundColor3=Color3.fromRGB(65,95,210); AimBody.BackgroundColor3=Color3.fromRGB(30,30,48)
end)
AimBody.Activated:Connect(function()
    Settings.AimMode="body"; SaveSettings()
    AimBody.BackgroundColor3=Color3.fromRGB(65,95,210); AimHead.BackgroundColor3=Color3.fromRGB(30,30,48)
end)
LockBtn.Activated:Connect(function()
    Settings.Enabled=not Settings.Enabled
    if Settings.Enabled then LockBtn.Text="🔒 Lock : ON"; LockBtn.BackgroundColor3=Color3.fromRGB(22,60,22); StartLock()
    else LockBtn.Text="🔓 Lock : OFF"; LockBtn.BackgroundColor3=Color3.fromRGB(26,26,42); StopLock() end
end)
NearBtn.Activated:Connect(function()
    Settings.NearestMode=not Settings.NearestMode
    NearBtn.Text=Settings.NearestMode and "📍 Nearest : ON" or "📍 Nearest : OFF"
    NearBtn.BackgroundColor3=Settings.NearestMode and Color3.fromRGB(22,60,22) or Color3.fromRGB(26,26,42); SaveSettings()
end)
PrevBtn.Activated:Connect(function()
    if #targetList==0 then targetList=FilterList(GetTargetList()) end
    if #targetList>0 then targetIndex=targetIndex-1; if targetIndex<1 then targetIndex=#targetList end; SetTarget(targetList[targetIndex].model) end
end)
NextBtn.Activated:Connect(function()
    if #targetList==0 then targetList=FilterList(GetTargetList()) end
    if #targetList>0 then targetIndex=targetIndex+1; if targetIndex>#targetList then targetIndex=1 end; SetTarget(targetList[targetIndex].model) end
end)
ESPBtn.Activated:Connect(function()
    Settings.ESPEnabled=not Settings.ESPEnabled
    ESPBtn.Text=Settings.ESPEnabled and "👁 ESP ON" or "👁 ESP"
    ESPBtn.BackgroundColor3=Settings.ESPEnabled and Color3.fromRGB(22,52,76) or Color3.fromRGB(26,26,42)
    if not Settings.ESPEnabled then ClearESP() end
end)
LockMenuBtn.Activated:Connect(function()
    menuLocked=not menuLocked
    LockMenuBtn.Text=menuLocked and "🔒" or "🔓"
    LockMenuBtn.BackgroundColor3=menuLocked and Color3.fromRGB(76,56,18) or Color3.fromRGB(42,42,64)
end)
local minimized=false
MinBtn.Activated:Connect(function()
    minimized=not minimized; Con.Visible=not minimized
    MF.Size=minimized and UDim2.new(0,230,0,32) or UDim2.new(0,230,0,410)
end)
CloseBtn.Activated:Connect(function() StopLock(); ClearESP(); ScreenGui:Destroy() end)

local scanVis=false
ScanBtn.Activated:Connect(function()
    scanVis=not scanVis; SF.Visible=scanVis
    ScanBtn.BackgroundColor3=scanVis and Color3.fromRGB(26,42,76) or Color3.fromRGB(26,26,42)
end)
SCloseBtn.Activated:Connect(function()
    scanVis=false; SF.Visible=false; CPop.Visible=false; EPop.Visible=false
    ScanBtn.BackgroundColor3=Color3.fromRGB(26,26,42)
end)
local sMin=false
SMinBtn.Activated:Connect(function()
    sMin=not sMin; SSroll.Visible=not sMin; DoScan.Visible=not sMin
    SCntLbl.Visible=not sMin; FBar.Visible=not sMin; EBar.Visible=not sMin
    SF.Size=sMin and UDim2.new(0,220,0,30) or UDim2.new(0,220,0,340)
    if sMin then CPop.Visible=false; EPop.Visible=false end
end)
DoScan.Activated:Connect(function()
    for _,c in ipairs(SSroll:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local raw=GetTargetList(); foundColors={}
    for _,e in ipairs(raw) do local h=Hex(e.color); if not foundColors[h] then foundColors[h]=e.color end end
    local list=FilterList(raw); targetList=list
    SCntLbl.Text=#list.." found  (raw:"..#raw..")"
    for i,e in ipairs(list) do
        local b=Btn(SSroll,string.format("  [%d] %s  %.0fm",i,e.name,e.dist),
            UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(15,15,24),e.color,9)
        b.TextXAlignment=Enum.TextXAlignment.Left
        local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,6,0,6); dot.Position=UDim2.new(0,4,0.5,-3)
        dot.BackgroundColor3=e.color; dot.BorderSizePixel=0; dot.Parent=b
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        b.Activated:Connect(function() targetIndex=i; SetTarget(e.model) end)
    end
    SSroll.CanvasSize=UDim2.new(0,0,0,SLayout.AbsoluteContentSize.Y+4)
    UpdateCPicker(); UpdateEPicker()
end)
CPBtn2.Activated:Connect(function() CPop.Visible=not CPop.Visible; EPop.Visible=false; if CPop.Visible then UpdateCPicker() end end)
CPClose.Activated:Connect(function() CPop.Visible=false end)
CPAll.Activated:Connect(function()
    Settings.FilterColor=nil; FLbl.Text="🎨 Filter: ทั้งหมด"; FLbl.TextColor3=Color3.fromRGB(125,125,175)
    CPBtn2.BackgroundColor3=Color3.fromRGB(50,50,165); CPop.Visible=false; UpdateCPicker()
end)
CFBtn.Activated:Connect(function()
    Settings.FilterColor=nil; FLbl.Text="🎨 Filter: ทั้งหมด"; FLbl.TextColor3=Color3.fromRGB(125,125,175)
    CPBtn2.BackgroundColor3=Color3.fromRGB(50,50,165); UpdateCPicker()
end)
ExcBtn.Activated:Connect(function()
    EPop.Visible=not EPop.Visible; CPop.Visible=false
    if EPop.Visible then pendEx={}; for _,h in ipairs(Settings.ExcludeColors) do table.insert(pendEx,h) end; UpdateEPicker() end
end)
EPClose.Activated:Connect(function() EPop.Visible=false; pendEx={} end)
EPOk.Activated:Connect(function()
    Settings.ExcludeColors={}; for _,h in ipairs(pendEx) do table.insert(Settings.ExcludeColors,h) end
    UpdateEPicker(); EPop.Visible=false; pendEx={}
end)
CEBtn.Activated:Connect(function() Settings.ExcludeColors={}; pendEx={}; UpdateEPicker() end)

local camVis=false
CamSysBtn.Activated:Connect(function()
    camVis=not camVis; CamF.Visible=camVis
    CamSysBtn.BackgroundColor3=camVis and Color3.fromRGB(76,52,18) or Color3.fromRGB(26,26,42)
end)
local camMin2=false
CamMin.Activated:Connect(function()
    camMin2=not camMin2; CamCon.Visible=not camMin2
    CamF.Size=camMin2 and UDim2.new(0,190,0,30) or UDim2.new(0,190,0,200)
    if camMin2 then CtrlPad.Visible=false end
end)
CamClose.Activated:Connect(function()
    camVis=false; CamF.Visible=false; CtrlPad.Visible=false; camFreecam=false
    CamSysBtn.BackgroundColor3=Color3.fromRGB(26,26,42)
end)
CamLockBtn.Activated:Connect(function()
    camEnabled=not camEnabled
    CamLockBtn.Text=camEnabled and "🔒 Lock Cam ON" or "🔒 Lock Cam OFF"
    CamLockBtn.BackgroundColor3=camEnabled and Color3.fromRGB(22,86,22) or Color3.fromRGB(155,34,34)
end)
CamFreeBtn.Activated:Connect(function()
    camFreecam=not camFreecam
    CamFreeBtn.Text=camFreecam and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    CamFreeBtn.BackgroundColor3=camFreecam and Color3.fromRGB(22,86,22) or Color3.fromRGB(155,34,34)
    CtrlPad.Visible=camFreecam
    if camFreecam then camFreePos=Camera.CFrame.Position end
end)
local tpVis=false
TPBtn.Activated:Connect(function()
    tpVis=not tpVis; TF.Visible=tpVis
    TPBtn.BackgroundColor3=tpVis and Color3.fromRGB(18,52,28) or Color3.fromRGB(26,26,42)
    if tpVis then TPRefresh() end
end)
local tpMin=false
TFMin.Activated:Connect(function()
    tpMin=not tpMin; TPScr.Visible=not tpMin
    TPSave.Visible=not tpMin; TPClic.Visible=not tpMin; TPDel.Visible=not tpMin
    TF.Size=tpMin and UDim2.new(0,210,0,30) or UDim2.new(0,210,0,260)
end)
TFClose.Activated:Connect(function() tpVis=false; TF.Visible=false; TPBtn.BackgroundColor3=Color3.fromRGB(26,26,42) end)
TPSave.Activated:Connect(function()
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    table.insert(tpSaves,{x=root.Position.X,y=root.Position.Y,z=root.Position.Z}); TPRefresh()
end)
TPDel.Activated:Connect(function()
    if tpSelected then table.remove(tpSaves,tpSelected); tpSelected=nil; TPRefresh() end
end)
TPClic.Activated:Connect(function()
    clickTP=not clickTP; if not clickTP then lockPos=nil end
    TPClic.Text=clickTP and "Click TP ON" or "Click TP OFF"
    TPClic.BackgroundColor3=clickTP and Color3.fromRGB(22,95,42) or Color3.fromRGB(135,34,34)
end)
Mouse.Button1Down:Connect(function()
    if not clickTP then return end
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local hit=Mouse.Hit
    if hit then lockPos=hit.Position; root.CFrame=CFrame.new(lockPos+Vector3.new(0,3,0)) end
end)
RunService.Heartbeat:Connect(function()
    if not(clickTP and lockPos) then return end
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    if(root.Position-lockPos).Magnitude>10 then root.CFrame=CFrame.new(lockPos+Vector3.new(0,3,0)) end
end)

-- INIT
if Settings.NearestMode then NearBtn.Text="📍 Nearest : ON"; NearBtn.BackgroundColor3=Color3.fromRGB(22,60,22) end
if Settings.AimMode=="head" then
    AimHead.BackgroundColor3=Color3.fromRGB(65,95,210); AimBody.BackgroundColor3=Color3.fromRGB(30,30,48)
else
    AimBody.BackgroundColor3=Color3.fromRGB(65,95,210); AimHead.BackgroundColor3=Color3.fromRGB(30,30,48)
end
