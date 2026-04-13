-- Lock Menu v18 | Codex Android
-- Camera Mode: Free / Face-Lock / PVP Crosshair | AimOffset Y+X | Lock on all menus

local Svc={
    Players=game:GetService("Players"),
    Run=game:GetService("RunService"),
    UIS=game:GetService("UserInputService"),
}
local LP=Svc.Players.LocalPlayer
local Cam=workspace.CurrentCamera
local Mouse=LP:GetMouse()

-- ══ STATE (รวมไว้ใน table เดียวลด local) ══
local S=_G.LockMenuSave or {}
local Cfg={
    strength=S.strength or 1,
    range=S.range or 200,
    mode=S.mode or "NPC",
    enabled=false,
    nearest=S.nearest or false,
    filterColor=nil,
    esp=false,
    exclude={},
    aimY=S.aimY or 0,
    aimX=S.aimX or 0,
    camMode=S.camMode or 1,
}
local St={
    char=LP.Character or LP.CharacterAdded:Wait(),
    target=nil,
    tgList={},
    tgIdx=1,
    lockConn=nil,
    colors={},
    rescan=false,
    tpScan=false,
    espBoxes={},
    espT=0,
    tpSaves={},
    tpSel=nil,
    clickTP=false,
    lockPos=nil,
    camLocked=false,
    camFree=false,
    camDist=50,
    camSpd=5,
    camAX=0,
    camAY=0,
    camMove=Vector3.new(),
    camFreePos=Vector3.new(),
    mvChar=nil,
    mvHum=nil,
    mvRoot=nil,
    mvFlying=false,
    mvFlyBV=nil,
    mvFlyBG=nil,
    mvStateConn=nil,
    mvLastPos=nil,
    mvJumpCount=0,
    mvCanJump=false,
    mvJumpDB=false,
    rapidConn=nil,
    rapidTgt=nil,
    tpModeSelect=1,
    tpRapidSpd=0.05,
    pendEx={},
    fakePart=nil,
}
local MvCfg={
    walkSpeed=16,jumpPower=50,multiJump=5,flySpeed=60,heightLock=0,
    speed=false,jump=false,mJump=false,fly=false,height=false,noclip=false,antiTP=true,
}

local function SaveCfg()
    _G.LockMenuSave={
        strength=Cfg.strength,range=Cfg.range,mode=Cfg.mode,
        nearest=Cfg.nearest,aimY=Cfg.aimY,aimX=Cfg.aimX,camMode=Cfg.camMode,
    }
end

-- ══ GUI CLEANUP ══
pcall(function()
    for _,n in ipairs({"LM_v18","LM_v16"}) do
        local pg=LP:FindFirstChild("PlayerGui")
        local cg=game:GetService("CoreGui")
        if pg and pg:FindFirstChild(n) then pg:FindFirstChild(n):Destroy() end
        if cg and cg:FindFirstChild(n) then cg:FindFirstChild(n):Destroy() end
    end
end)
local SG=Instance.new("ScreenGui")
SG.Name="LM_v18";SG.ResetOnSpawn=false
SG.DisplayOrder=999;SG.IgnoreGuiInset=true
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

-- ══ FAKE PART (หลอก Mouse.Hit ให้ยิงตรงเป้า) ══
local fakePart=Instance.new("Part")
fakePart.Name="FakeAimPart"
fakePart.Size=Vector3.new(0.1,0.1,0.1)
fakePart.Anchored=true
fakePart.CanCollide=false
fakePart.Transparency=1
fakePart.CastShadow=false
fakePart.Parent=workspace
St.fakePart=fakePart
Mouse.TargetFilter=fakePart

-- ══ UI FACTORY ══
local function Hex(c)
    return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
end
local function mkFrame(par,sz,pos,bg,clip,r)
    local f=Instance.new("Frame")
    f.Size=sz;f.Position=pos
    f.BackgroundColor3=bg or Color3.fromRGB(13,13,19)
    f.BorderSizePixel=0
    if clip then f.ClipsDescendants=true end
    f.Parent=par
    if r~=false then Instance.new("UICorner",f).CornerRadius=UDim.new(0,r or 8) end
    return f
end
local function mkBtn(par,txt,sz,pos,bg,tc,ts)
    local b=Instance.new("TextButton")
    b.Size=sz;b.Position=pos
    b.BackgroundColor3=bg or Color3.fromRGB(28,28,44)
    b.BorderSizePixel=0;b.Text=txt
    b.TextColor3=tc or Color3.fromRGB(205,205,255)
    b.TextSize=ts or 11;b.Font=Enum.Font.GothamBold
    b.AutoButtonColor=false;b.Parent=par
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    return b
end
local function mkLbl(par,txt,sz,pos,ts,tc,font,xa)
    local l=Instance.new("TextLabel")
    l.Size=sz;l.Position=pos;l.BackgroundTransparency=1
    l.Text=txt;l.TextColor3=tc or Color3.fromRGB(155,155,205)
    l.TextSize=ts or 10;l.Font=font or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.Parent=par;return l
end
local function mkInp(par,def,sz,pos)
    local b=Instance.new("TextBox")
    b.Size=sz;b.Position=pos
    b.BackgroundColor3=Color3.fromRGB(19,19,30);b.BorderSizePixel=0
    b.Text=tostring(def);b.TextColor3=Color3.fromRGB(225,225,255)
    b.TextSize=11;b.Font=Enum.Font.Gotham;b.Parent=par
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
local function mkDiv(par,y)
    local d=Instance.new("Frame")
    d.Size=UDim2.new(1,-16,0,1);d.Position=UDim2.new(0,8,0,y)
    d.BackgroundColor3=Color3.fromRGB(36,36,55);d.BorderSizePixel=0;d.Parent=par
end
local function mkAccent(par,col)
    local a=Instance.new("Frame");a.Size=UDim2.new(1,0,0,2);a.Position=UDim2.new(0,0,1,-2)
    a.BackgroundColor3=col or Color3.fromRGB(72,110,245);a.BorderSizePixel=0;a.Parent=par
end
local function mkDrag(frame,handle,lockFn)
    local drag,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(i)
        if lockFn and lockFn() then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true;ds=i.Position;sp=frame.Position
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
    handle.InputChanged:Connect(mv);Svc.UIS.InputChanged:Connect(mv)
    handle.InputEnded:Connect(en);Svc.UIS.InputEnded:Connect(en)
end
local function mkResize(tb,frame,mnW,mxW,mnH,mxH)
    local bS=mkBtn(tb,"◀",UDim2.new(0,18,0,18),UDim2.new(0,4,0.5,-9),Color3.fromRGB(28,28,46),Color3.fromRGB(150,150,210),9)
    local bL=mkBtn(tb,"▶",UDim2.new(0,18,0,18),UDim2.new(0,24,0.5,-9),Color3.fromRGB(28,28,46),Color3.fromRGB(150,150,210),9)
    bS.Activated:Connect(function()
        local s=frame.AbsoluteSize
        frame.Size=UDim2.new(0,math.max(mnW,s.X-20),0,math.max(mnH,s.Y-20))
    end)
    bL.Activated:Connect(function()
        local s=frame.AbsoluteSize
        frame.Size=UDim2.new(0,math.min(mxW,s.X+20),0,math.min(mxH,s.Y+20))
    end)
end
local function mkMenuLock(tb,off)
    local locked=false
    local btn=mkBtn(tb,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-(off or 72),0.5,-11),Color3.fromRGB(40,40,62))
    btn.Activated:Connect(function()
        locked=not locked
        btn.Text=locked and "🔒" or "🔓"
        btn.BackgroundColor3=locked and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62)
    end)
    return function() return locked end
end

-- ══ CROSSHAIR ══
local CHF=Instance.new("Frame")
CHF.Name="Crosshair";CHF.Size=UDim2.new(0,20,0,20)
CHF.AnchorPoint=Vector2.new(0.5,0.5);CHF.BackgroundTransparency=1
CHF.ZIndex=100;CHF.Parent=SG
local cvL=Instance.new("Frame",CHF);cvL.Size=UDim2.new(0,2,1,0);cvL.Position=UDim2.new(0.5,-1,0,0)
cvL.BackgroundColor3=Color3.fromRGB(255,255,255);cvL.BorderSizePixel=0;cvL.ZIndex=100
local chL=Instance.new("Frame",CHF);chL.Size=UDim2.new(1,0,0,2);chL.Position=UDim2.new(0,0,0.5,-1)
chL.BackgroundColor3=Color3.fromRGB(255,255,255);chL.BorderSizePixel=0;chL.ZIndex=100
local cDot=Instance.new("Frame",CHF);cDot.Size=UDim2.new(0,6,0,6);cDot.Position=UDim2.new(0.5,-3,0.5,-3)
cDot.BackgroundColor3=Color3.fromRGB(255,80,80);cDot.BorderSizePixel=0;cDot.ZIndex=101
Instance.new("UICorner",cDot).CornerRadius=UDim.new(1,0)
CHF.Visible=false

local function UpdateCH()
    local vp=Cam.ViewportSize
    CHF.Position=UDim2.new(0,vp.X/2-Cfg.aimX*4,0,vp.Y/2-Cfg.aimY*4)
end

-- ══ MAIN FRAME ══
local menuLocked=false
local MF=mkFrame(SG,UDim2.new(0,232,0,440),UDim2.new(0.5,-116,0.5,-220),Color3.fromRGB(11,11,17),true)
local TB=mkFrame(MF,UDim2.new(1,0,0,32),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8)
TB.ClipsDescendants=false;mkAccent(TB)
mkDrag(MF,TB,function() return menuLocked end)
mkLbl(TB,"⚔ Lock Menu v18",UDim2.new(1,-112,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(TB,MF,180,320,380,540)
local BtnLockMenu=mkBtn(TB,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-72,0.5,-11),Color3.fromRGB(40,40,62))
local BtnMin=mkBtn(TB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-48,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),14)
local BtnClose=mkBtn(TB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-24,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local Con=Instance.new("Frame");Con.Size=UDim2.new(1,0,1,-32);Con.Position=UDim2.new(0,0,0,32)
Con.BackgroundTransparency=1;Con.Parent=MF

-- MODE
mkLbl(Con,"🎯 MODE",UDim2.new(0,80,0,13),UDim2.new(0,8,0,6),9)
local BtnPlayer=mkBtn(Con,"👤 Player",UDim2.new(0,100,0,26),UDim2.new(0,8,0,21),Color3.fromRGB(28,28,46),Color3.fromRGB(148,158,218))
local BtnNPC=mkBtn(Con,"🤖 NPC",UDim2.new(0,100,0,26),UDim2.new(0,116,0,21),Color3.fromRGB(62,92,205),Color3.fromRGB(255,255,255))
local function UpdateModeUI()
    if Cfg.mode=="Player" then
        BtnPlayer.BackgroundColor3=Color3.fromRGB(62,92,205);BtnPlayer.TextColor3=Color3.fromRGB(255,255,255)
        BtnNPC.BackgroundColor3=Color3.fromRGB(28,28,46);BtnNPC.TextColor3=Color3.fromRGB(148,158,218)
    else
        BtnNPC.BackgroundColor3=Color3.fromRGB(62,92,205);BtnNPC.TextColor3=Color3.fromRGB(255,255,255)
        BtnPlayer.BackgroundColor3=Color3.fromRGB(28,28,46);BtnPlayer.TextColor3=Color3.fromRGB(148,158,218)
    end
end;UpdateModeUI()
mkDiv(Con,53)

-- RANGE
mkLbl(Con,"📏 Range",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,57),9)
local InpRange=mkInp(Con,Cfg.range,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,70))
mkDiv(Con,100)

-- CAMERA MODE
mkLbl(Con,"📷 Camera Mode",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,104),9,Color3.fromRGB(180,180,255))
local BtnCM1=mkBtn(Con,"1.อิสระ",UDim2.new(0,68,0,24),UDim2.new(0,8,0,119),Color3.fromRGB(28,28,46),Color3.fromRGB(148,158,218),9)
local BtnCM2=mkBtn(Con,"2.ล็อคหัน",UDim2.new(0,68,0,24),UDim2.new(0,80,0,119),Color3.fromRGB(28,28,46),Color3.fromRGB(148,158,218),9)
local BtnCM3=mkBtn(Con,"3.PVP🎯",UDim2.new(0,68,0,24),UDim2.new(0,152,0,119),Color3.fromRGB(28,28,46),Color3.fromRGB(148,158,218),9)
local function UpdateCamModeUI()
    local hi=Color3.fromRGB(62,92,205);local lo=Color3.fromRGB(28,28,46)
    local th=Color3.fromRGB(255,255,255);local tl=Color3.fromRGB(148,158,218)
    BtnCM1.BackgroundColor3=Cfg.camMode==1 and hi or lo;BtnCM1.TextColor3=Cfg.camMode==1 and th or tl
    BtnCM2.BackgroundColor3=Cfg.camMode==2 and hi or lo;BtnCM2.TextColor3=Cfg.camMode==2 and th or tl
    BtnCM3.BackgroundColor3=Cfg.camMode==3 and hi or lo;BtnCM3.TextColor3=Cfg.camMode==3 and th or tl
    CHF.Visible=(Cfg.camMode==3)
end;UpdateCamModeUI()
BtnCM1.Activated:Connect(function() Cfg.camMode=1;UpdateCamModeUI();SaveCfg() end)
BtnCM2.Activated:Connect(function() Cfg.camMode=2;UpdateCamModeUI();SaveCfg() end)
BtnCM3.Activated:Connect(function() Cfg.camMode=3;UpdateCamModeUI();SaveCfg() end)
mkDiv(Con,149)

-- AIM Y
mkLbl(Con,"⬆ Aim Y (0=กลาง ↑บน ↓ล่าง)",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,153),9)
local InpAimY=mkInp(Con,Cfg.aimY,UDim2.new(0,80,0,24),UDim2.new(0,8,0,166))
local BtnAimYU=mkBtn(Con,"+",UDim2.new(0,26,0,22),UDim2.new(0,92,0,166),Color3.fromRGB(35,55,35),Color3.fromRGB(175,255,175),12)
local BtnAimYD=mkBtn(Con,"–",UDim2.new(0,26,0,22),UDim2.new(0,120,0,166),Color3.fromRGB(55,28,28),Color3.fromRGB(255,175,175),12)

-- AIM X
mkLbl(Con,"↔ Aim X (1=ซ้าย -1=ขวา)",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,193),9)
local InpAimX=mkInp(Con,Cfg.aimX,UDim2.new(0,80,0,24),UDim2.new(0,8,0,206))
local BtnAimXL=mkBtn(Con,"+",UDim2.new(0,26,0,22),UDim2.new(0,92,0,206),Color3.fromRGB(35,55,35),Color3.fromRGB(175,255,175),12)
local BtnAimXR=mkBtn(Con,"–",UDim2.new(0,26,0,22),UDim2.new(0,120,0,206),Color3.fromRGB(55,28,28),Color3.fromRGB(255,175,175),12)
mkDiv(Con,236)

-- LOCK
local BtnLock=mkBtn(Con,"🔓 Lock : OFF",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,242),Color3.fromRGB(24,24,40),Color3.fromRGB(175,175,255),12)
local BtnNear=mkBtn(Con,"📍 Nearest : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,276),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),11)
local BtnPrev=mkBtn(Con,"◀",UDim2.new(0,38,0,26),UDim2.new(0,8,0,308),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)
local TgtLbl=Instance.new("TextLabel");TgtLbl.Size=UDim2.new(0,122,0,26);TgtLbl.Position=UDim2.new(0,50,0,308)
TgtLbl.BackgroundColor3=Color3.fromRGB(15,15,26);TgtLbl.BorderSizePixel=0;TgtLbl.Text="No Target"
TgtLbl.TextColor3=Color3.fromRGB(130,170,255);TgtLbl.TextSize=10;TgtLbl.Font=Enum.Font.GothamBold
TgtLbl.TextTruncate=Enum.TextTruncate.AtEnd;TgtLbl.Parent=Con
Instance.new("UICorner",TgtLbl).CornerRadius=UDim.new(0,5)
local BtnNext=mkBtn(Con,"▶",UDim2.new(0,38,0,26),UDim2.new(0,176,0,308),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)
mkDiv(Con,340)

-- FEATURE ROW
local BtnESP=mkBtn(Con,"👁 ESP",UDim2.new(0,42,0,26),UDim2.new(0,8,0,346),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnScan=mkBtn(Con,"🔍 Scan",UDim2.new(0,42,0,26),UDim2.new(0,54,0,346),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnCamSys=mkBtn(Con,"📷 Cam",UDim2.new(0,42,0,26),UDim2.new(0,100,0,346),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnTP=mkBtn(Con,"🚀 TP",UDim2.new(0,38,0,26),UDim2.new(0,146,0,346),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnMove=mkBtn(Con,"🏃 Move",UDim2.new(0,42,0,26),UDim2.new(0,188,0,346),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
mkDiv(Con,378)
local StatusLbl=mkLbl(Con,"● Idle",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,383),10,Color3.fromRGB(60,60,90))

-- ══ SCAN FRAME ══
local SF=mkFrame(SG,UDim2.new(0,220,0,340),UDim2.new(0.5,126,0.5,-170),Color3.fromRGB(11,11,17),true)
SF.Visible=false
local STB=mkFrame(SF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);mkAccent(STB)
local scanLocked=mkMenuLock(STB,72)
mkDrag(SF,STB,scanLocked)
mkLbl(STB,"🔍 Scan",UDim2.new(1,-108,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(STB,SF,160,320,200,500)
local BtnTPScan=mkBtn(STB,"🚀",UDim2.new(0,22,0,22),UDim2.new(1,-116,0.5,-11),Color3.fromRGB(30,80,30))
local BtnCP2=mkBtn(STB,"🎨",UDim2.new(0,22,0,22),UDim2.new(1,-92,0.5,-11),Color3.fromRGB(48,48,160))
local BtnExc=mkBtn(STB,"🚫",UDim2.new(0,22,0,22),UDim2.new(1,-68,0.5,-11),Color3.fromRGB(100,30,30),Color3.fromRGB(255,170,170))
local BtnSMin=mkBtn(STB,"–",UDim2.new(0,20,0,20),UDim2.new(1,-44,0.5,-10),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),12)
local BtnSClose=mkBtn(STB,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10)
local FBar=mkFrame(SF,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,32),Color3.fromRGB(16,16,26),false,5)
local FLbl=mkLbl(FBar,"🎨 Filter: ทั้งหมด",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(120,120,170))
local BtnCF=mkBtn(FBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)
local EBar=mkFrame(SF,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,56),Color3.fromRGB(20,10,10),false,5)
local ELbl=mkLbl(EBar,"🚫 Exclude: ไม่มี",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(170,105,105))
local BtnCE=mkBtn(EBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)
local BtnDoScan=mkBtn(SF,"🔍 Scan Now",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,80),Color3.fromRGB(32,32,66),Color3.fromRGB(180,180,255),11)
local ScanCntLbl=mkLbl(SF,"0 found",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,108),9,Color3.fromRGB(70,70,110))
local SScr=Instance.new("ScrollingFrame");SScr.Size=UDim2.new(1,-8,1,-125);SScr.Position=UDim2.new(0,4,0,124)
SScr.BackgroundTransparency=1;SScr.BorderSizePixel=0;SScr.ScrollBarThickness=3
SScr.CanvasSize=UDim2.new(0,0,0,0);SScr.Parent=SF
local SLayout=Instance.new("UIListLayout");SLayout.Padding=UDim.new(0,3);SLayout.Parent=SScr

-- ══ COLOR PICKER ══
local CPop=mkFrame(SG,UDim2.new(0,200,0,230),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,12,18),true)
CPop.Visible=false;CPop.ZIndex=10
local CPBar=mkFrame(CPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);CPBar.ZIndex=10
mkDrag(CPop,CPBar,nil)
mkLbl(CPBar,"🎨 Filter Color",UDim2.new(1,-28,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnCPClose=mkBtn(CPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnCPClose.ZIndex=10
local BtnCPAll=mkBtn(CPop,"✅ แสดงทั้งหมด",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,30),Color3.fromRGB(26,46,26),Color3.fromRGB(170,255,170),9);BtnCPAll.ZIndex=10
local CPScr=Instance.new("ScrollingFrame");CPScr.Size=UDim2.new(1,-8,1,-56);CPScr.Position=UDim2.new(0,4,0,54)
CPScr.BackgroundTransparency=1;CPScr.BorderSizePixel=0;CPScr.ScrollBarThickness=3
CPScr.CanvasSize=UDim2.new(0,0,0,0);CPScr.ZIndex=10;CPScr.Parent=CPop
local CPLayout=Instance.new("UIListLayout");CPLayout.Padding=UDim.new(0,3);CPLayout.Parent=CPScr

-- ══ EXCLUDE POPUP ══
local EPop=mkFrame(SG,UDim2.new(0,200,0,260),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(16,8,8),true)
EPop.Visible=false;EPop.ZIndex=10
local EPBar=mkFrame(EPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(25,12,12),false,8);EPBar.ZIndex=10
mkDrag(EPop,EPBar,nil)
mkLbl(EPBar,"🚫 Exclude Color",UDim2.new(1,-28,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,190,190),Enum.Font.GothamBold)
local BtnEPClose=mkBtn(EPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnEPClose.ZIndex=10
mkLbl(EPop,"กดสีที่ไม่ต้องการล็อค → OK",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,30),9,Color3.fromRGB(190,148,148))
local BtnEPOk=mkBtn(EPop,"✅ OK",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,52),Color3.fromRGB(26,50,26),Color3.fromRGB(170,255,170),9);BtnEPOk.ZIndex=10
local EPScr=Instance.new("ScrollingFrame");EPScr.Size=UDim2.new(1,-8,1,-80);EPScr.Position=UDim2.new(0,4,0,78)
EPScr.BackgroundTransparency=1;EPScr.BorderSizePixel=0;EPScr.ScrollBarThickness=3
EPScr.CanvasSize=UDim2.new(0,0,0,0);EPScr.ZIndex=10;EPScr.Parent=EPop
local EPLayout=Instance.new("UIListLayout");EPLayout.Padding=UDim.new(0,3);EPLayout.Parent=EPScr

-- ══ TP MODE POPUP ══
local TPMPop=mkFrame(SG,UDim2.new(0,200,0,160),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,15,22),true)
TPMPop.Visible=false;TPMPop.ZIndex=12
local TPMBar=mkFrame(TPMPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,22,35),false,8);TPMBar.ZIndex=12
mkDrag(TPMPop,TPMBar,nil);mkAccent(TPMBar,Color3.fromRGB(50,200,120))
mkLbl(TPMBar,"🚀 TP Mode",UDim2.new(1,-30,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnTPMClose=mkBtn(TPMBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnTPMClose.ZIndex=12
local BtnTPM1=mkBtn(TPMPop,"1️⃣ ปกติ",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,32),Color3.fromRGB(25,75,25),Color3.fromRGB(180,255,180),10);BtnTPM1.ZIndex=12
local BtnTPM2=mkBtn(TPMPop,"2️⃣ รัว",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,64),Color3.fromRGB(35,35,55),Color3.fromRGB(155,155,220),10);BtnTPM2.ZIndex=12
mkLbl(TPMPop,"⚡ ความเร็วรัว (วิ)",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,96),9,Color3.fromRGB(120,120,170))
local InpTPSpd=mkInp(TPMPop,St.tpRapidSpd,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,112));InpTPSpd.ZIndex=12
local function UpdateTPMUI()
    BtnTPM1.BackgroundColor3=St.tpModeSelect==1 and Color3.fromRGB(25,100,25) or Color3.fromRGB(25,45,25)
    BtnTPM2.BackgroundColor3=St.tpModeSelect==2 and Color3.fromRGB(60,40,100) or Color3.fromRGB(35,35,55)
end;UpdateTPMUI()

-- ══ COLOR PICKER ══
local CPop=mkFrame(SG,UDim2.new(0,200,0,230),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,12,18),true)
CPop.Visible=false;CPop.ZIndex=10
local CPBar=mkFrame(CPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);CPBar.ZIndex=10
mkDrag(CPop,CPBar,nil)
mkLbl(CPBar,"🎨 Filter Color",UDim2.new(1,-28,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnCPClose=mkBtn(CPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnCPClose.ZIndex=10
local BtnCPAll=mkBtn(CPop,"✅ แสดงทั้งหมด",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,30),Color3.fromRGB(26,46,26),Color3.fromRGB(170,255,170),9);BtnCPAll.ZIndex=10
local CPScr=Instance.new("ScrollingFrame");CPScr.Size=UDim2.new(1,-8,1,-56);CPScr.Position=UDim2.new(0,4,0,54)
CPScr.BackgroundTransparency=1;CPScr.BorderSizePixel=0;CPScr.ScrollBarThickness=3
CPScr.CanvasSize=UDim2.new(0,0,0,0);CPScr.ZIndex=10;CPScr.Parent=CPop
local CPLayout=Instance.new("UIListLayout");CPLayout.Padding=UDim.new(0,3);CPLayout.Parent=CPScr

-- ══ EXCLUDE POPUP ══
local EPop=mkFrame(SG,UDim2.new(0,200,0,260),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(16,8,8),true)
EPop.Visible=false;EPop.ZIndex=10
local EPBar=mkFrame(EPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(25,12,12),false,8);EPBar.ZIndex=10
mkDrag(EPop,EPBar,nil)
mkLbl(EPBar,"🚫 Exclude Color",UDim2.new(1,-28,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,190,190),Enum.Font.GothamBold)
local BtnEPClose=mkBtn(EPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnEPClose.ZIndex=10
mkLbl(EPop,"กดสีที่ไม่ต้องการล็อค → OK",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,30),9,Color3.fromRGB(190,148,148))
local BtnEPOk=mkBtn(EPop,"✅ OK",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,52),Color3.fromRGB(26,50,26),Color3.fromRGB(170,255,170),9);BtnEPOk.ZIndex=10
local EPScr=Instance.new("ScrollingFrame");EPScr.Size=UDim2.new(1,-8,1,-80);EPScr.Position=UDim2.new(0,4,0,78)
EPScr.BackgroundTransparency=1;EPScr.BorderSizePixel=0;EPScr.ScrollBarThickness=3
EPScr.CanvasSize=UDim2.new(0,0,0,0);EPScr.ZIndex=10;EPScr.Parent=EPop
local EPLayout=Instance.new("UIListLayout");EPLayout.Padding=UDim.new(0,3);EPLayout.Parent=EPScr

-- ══ TP MODE POPUP ══
local TPMPop=mkFrame(SG,UDim2.new(0,200,0,160),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,15,22),true)
TPMPop.Visible=false;TPMPop.ZIndex=12
local TPMBar=mkFrame(TPMPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,22,35),false,8);TPMBar.ZIndex=12
mkDrag(TPMPop,TPMBar,nil);mkAccent(TPMBar,Color3.fromRGB(50,200,120))
mkLbl(TPMBar,"🚀 TP Mode",UDim2.new(1,-30,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnTPMClose=mkBtn(TPMBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnTPMClose.ZIndex=12
local BtnTPM1=mkBtn(TPMPop,"1️⃣ ปกติ",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,32),Color3.fromRGB(25,75,25),Color3.fromRGB(180,255,180),10);BtnTPM1.ZIndex=12
local BtnTPM2=mkBtn(TPMPop,"2️⃣ รัว",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,64),Color3.fromRGB(35,35,55),Color3.fromRGB(155,155,220),10);BtnTPM2.ZIndex=12
mkLbl(TPMPop,"⚡ ความเร็วรัว (วิ)",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,96),9,Color3.fromRGB(120,120,170))
local InpTPSpd=mkInp(TPMPop,St.tpRapidSpd,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,112));InpTPSpd.ZIndex=12
local function UpdateTPMUI()
    BtnTPM1.BackgroundColor3=St.tpModeSelect==1 and Color3.fromRGB(25,100,25) or Color3.fromRGB(25,45,25)
    BtnTPM2.BackgroundColor3=St.tpModeSelect==2 and Color3.fromRGB(60,40,100) or Color3.fromRGB(35,35,55)
end;UpdateTPMUI()

-- ══ CAM FRAME ══
local CamF=mkFrame(SG,UDim2.new(0,190,0,200),UDim2.new(0.5,-340,0.5,-100),Color3.fromRGB(11,11,17),true)
CamF.Visible=false
local CamTB=mkFrame(CamF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8)
mkAccent(CamTB,Color3.fromRGB(245,150,50));local camLock2=mkMenuLock(CamTB,72)
mkDrag(CamF,CamTB,camLock2)
mkLbl(CamTB,"📷 Camera",UDim2.new(1,-55,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(CamTB,CamF,160,280,160,320)
local BtnCamMin=mkBtn(CamTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnCamClose=mkBtn(CamTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local CamCon=Instance.new("Frame");CamCon.Size=UDim2.new(1,0,1,-30);CamCon.Position=UDim2.new(0,0,0,30)
CamCon.BackgroundTransparency=1;CamCon.Parent=CamF
local BtnCamLock=mkBtn(CamCon,"🔒 Lock Cam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,5),Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
local BtnCamFree=mkBtn(CamCon,"🎥 FreeCam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,40),Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
mkLbl(CamCon,"📏 Distance",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,76),9)
local InpCamDist=mkInp(CamCon,St.camDist,UDim2.new(1,-10,0,26),UDim2.new(0,5,0,89))
mkLbl(CamCon,"⚡ Speed",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,120),9)
local InpCamSpd=mkInp(CamCon,St.camSpd,UDim2.new(1,-10,0,26),UDim2.new(0,5,0,133))

-- CtrlPad
local CtrlPad=mkFrame(SG,UDim2.new(0,160,0,160),UDim2.new(0.75,0,0.6,0),nil,false,0)
CtrlPad.BackgroundTransparency=1;CtrlPad.Visible=false
local function mkPad(txt,pos)
    return mkBtn(CtrlPad,txt,UDim2.new(0,45,0,45),pos,Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
end
local function bindPad(b,v)
    b.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then St.camMove=St.camMove+v end end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then St.camMove=St.camMove-v end end)
end
bindPad(mkPad("↑",UDim2.new(0.5,-22,0,0)),Vector3.new(0,0,-1))
bindPad(mkPad("↓",UDim2.new(0.5,-22,0,90)),Vector3.new(0,0,1))
bindPad(mkPad("←",UDim2.new(0,0,0.5,-22)),Vector3.new(-1,0,0))
bindPad(mkPad("→",UDim2.new(0,90,0.5,-22)),Vector3.new(1,0,0))
bindPad(mkPad("▲",UDim2.new(0,0,0,0)),Vector3.new(0,1,0))
bindPad(mkPad("▼",UDim2.new(0,90,0,0)),Vector3.new(0,-1,0))

-- ══ TP FRAME ══
local TF=mkFrame(SG,UDim2.new(0,210,0,260),UDim2.new(0.5,-340,0.5,110),Color3.fromRGB(11,11,17),true)
TF.Visible=false
local TFTB=mkFrame(TF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8)
mkAccent(TFTB,Color3.fromRGB(50,190,110));local tpLock=mkMenuLock(TFTB,72)
mkDrag(TF,TFTB,tpLock)
mkLbl(TFTB,"🚀 Teleport",UDim2.new(1,-55,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(TFTB,TF,160,320,200,400)
local BtnTFMin=mkBtn(TFTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnTFClose=mkBtn(TFTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local BtnTPSave=mkBtn(TF,"+ Save",UDim2.new(0,60,0,26),UDim2.new(0,5,0,34),Color3.fromRGB(20,68,20),Color3.fromRGB(170,255,170),11)
local BtnTPClic=mkBtn(TF,"Click TP OFF",UDim2.new(0,80,0,26),UDim2.new(0,68,0,34),Color3.fromRGB(130,32,32),Color3.fromRGB(255,170,170),10)
local BtnTPDel=mkBtn(TF,"Delete",UDim2.new(0,55,0,26),UDim2.new(0,152,0,34),Color3.fromRGB(72,24,24),Color3.fromRGB(255,140,140),10)
local TPScr=Instance.new("ScrollingFrame");TPScr.Size=UDim2.new(1,-10,1,-68);TPScr.Position=UDim2.new(0,5,0,64)
TPScr.BackgroundColor3=Color3.fromRGB(13,13,20);TPScr.BorderSizePixel=0
TPScr.ScrollBarThickness=3;TPScr.CanvasSize=UDim2.new(0,0,0,0);TPScr.Parent=TF
Instance.new("UICorner",TPScr).CornerRadius=UDim.new(0,5)
Instance.new("UIListLayout",TPScr).Padding=UDim.new(0,4)

-- ══ MOVE FRAME ══
local MvF=mkFrame(SG,UDim2.new(0,260,0,360),UDim2.new(0.5,-130,0.5,-180),Color3.fromRGB(11,11,17),true)
MvF.Visible=false
local MvTB=mkFrame(MvF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8)
mkAccent(MvTB,Color3.fromRGB(80,200,100));local mvLock=mkMenuLock(MvTB,72)
mkDrag(MvF,MvTB,mvLock)
mkLbl(MvTB,"🏃 Movement",UDim2.new(1,-55,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(MvTB,MvF,180,340,200,500)
local BtnMvMin=mkBtn(MvTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnMvClose=mkBtn(MvTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local MvScr=Instance.new("ScrollingFrame")
MvScr.Size=UDim2.new(1,-8,1,-36);MvScr.Position=UDim2.new(0,4,0,36)
MvScr.BackgroundTransparency=1;MvScr.BorderSizePixel=0;MvScr.ScrollBarThickness=3
MvScr.AutomaticCanvasSize=Enum.AutomaticSize.Y;MvScr.CanvasSize=UDim2.new(0,0,0,0);MvScr.Parent=MvF
local MvLayout=Instance.new("UIListLayout");MvLayout.Padding=UDim.new(0,6);MvLayout.Parent=MvScr
Instance.new("UIPadding",MvScr).PaddingTop=UDim.new(0,6)

-- ══ MOVEMENT LOGIC ══
local mvControls=nil
pcall(function()
    local PM=require(LP:WaitForChild("PlayerScripts",3):WaitForChild("PlayerModule",3))
    mvControls=PM:GetControls()
end)
local function mvSetup(char)
    St.mvChar=char;St.mvHum=char:WaitForChild("Humanoid");St.mvRoot=char:WaitForChild("HumanoidRootPart")
    St.mvJumpCount=0;St.mvCanJump=false;St.mvJumpDB=false;St.mvLastPos=nil
    if St.mvStateConn then St.mvStateConn:Disconnect() end
    St.mvStateConn=St.mvHum.StateChanged:Connect(function(_,new)
        if new==Enum.HumanoidStateType.Landed then St.mvJumpCount=0;St.mvCanJump=false
        elseif new==Enum.HumanoidStateType.Freefall then St.mvCanJump=true end
    end)
end
if LP.Character then mvSetup(LP.Character) end
LP.CharacterAdded:Connect(mvSetup)

Svc.UIS.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.Space and MvCfg.mJump and St.mvHum then
        if St.mvJumpDB then return end;St.mvJumpDB=true
        if St.mvCanJump and St.mvJumpCount<MvCfg.multiJump then
            St.mvJumpCount=St.mvJumpCount+1;St.mvCanJump=false
            St.mvHum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        task.delay(0.15,function() St.mvJumpDB=false end)
    end
end)

local function mvStartFly()
    if not St.mvRoot then return end;St.mvFlying=true
    St.mvFlyBV=Instance.new("BodyVelocity",St.mvRoot);St.mvFlyBV.MaxForce=Vector3.new(1e6,1e6,1e6)
    St.mvFlyBG=Instance.new("BodyGyro",St.mvRoot);St.mvFlyBG.MaxTorque=Vector3.new(1e6,1e6,1e6)
    St.mvHum.AutoRotate=false
end
local function mvStopFly()
    St.mvFlying=false
    if St.mvFlyBV then St.mvFlyBV:Destroy() end
    if St.mvFlyBG then St.mvFlyBG:Destroy() end
    if St.mvHum then St.mvHum.AutoRotate=true end
end
local mvRay=RaycastParams.new();mvRay.FilterType=Enum.RaycastFilterType.Blacklist

local function mkMvRow(emoji,name,def,onT,onV)
    local row=Instance.new("Frame");row.Size=UDim2.new(1,-8,0,44)
    row.BackgroundColor3=Color3.fromRGB(18,18,28);row.BorderSizePixel=0;row.Parent=MvScr
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel");lbl.Size=UDim2.new(0,120,1,0);lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1;lbl.Text=emoji.." "..name
    lbl.TextColor3=Color3.fromRGB(200,200,255);lbl.TextSize=10;lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.Parent=row
    local tog=mkBtn(row,"OFF",UDim2.new(0,44,0,26),UDim2.new(0,130,0.5,-13),Color3.fromRGB(140,30,30),Color3.fromRGB(255,200,200),10)
    local on=false
    tog.Activated:Connect(function()
        on=not on;tog.Text=on and "ON" or "OFF"
        tog.BackgroundColor3=on and Color3.fromRGB(25,90,25) or Color3.fromRGB(140,30,30)
        tog.TextColor3=on and Color3.fromRGB(180,255,180) or Color3.fromRGB(255,200,200)
        onT(on)
    end)
    if def~=-1 then
        local box=mkInp(row,def,UDim2.new(0,58,0,26),UDim2.new(1,-66,0.5,-13))
        box.FocusLost:Connect(function()
            local v=tonumber(box.Text);if v then onV(v) else box.Text=tostring(def) end
        end)
    end
end
mkMvRow("🏃","WalkSpeed",16,function(v) MvCfg.speed=v end,function(v) MvCfg.walkSpeed=v end)
mkMvRow("🦘","JumpPower",50,function(v) MvCfg.jump=v end,function(v) MvCfg.jumpPower=v end)
mkMvRow("🔁","MultiJump",5,function(v) MvCfg.mJump=v end,function(v) MvCfg.multiJump=v end)
mkMvRow("🕊️","FlySpeed",60,function(v) MvCfg.fly=v;if v then mvStartFly() else mvStopFly() end end,function(v) MvCfg.flySpeed=v end)
mkMvRow("📏","HeightLock",0,function(v) MvCfg.height=v end,function(v) MvCfg.heightLock=v end)
mkMvRow("🧱","Noclip",-1,function(v) MvCfg.noclip=v end,function() end)
mkMvRow("🛡️","AntiTP",-1,function(v) MvCfg.antiTP=v end,function() end)

-- ══ CORE HELPERS ══
local function GetTeamColor(model)
    local p=Svc.Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    return Color3.fromRGB(210,110,40)
end
local function IsExcluded(color)
    local h=Hex(color)
    for _,eh in ipairs(Cfg.exclude) do if eh==h then return true end end
    return false
end
local function GetRoot(model)
    local r=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model.PrimaryPart
    if not r then for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then return p end end end
    return r
end
local function GetTargetList()
    local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list={};local range=tonumber(InpRange.Text) or Cfg.range
    if Cfg.mode=="Player" then
        for _,p in ipairs(Svc.Players:GetPlayers()) do
            if p~=LP and p.Character then
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
            if obj:IsA("Model") and obj~=St.char and not Svc.Players:GetPlayerFromCharacter(obj) then
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
    if not Cfg.filterColor then return list end
    local fh=Hex(Cfg.filterColor);local out={}
    for _,e in ipairs(list) do if Hex(e.color)==fh then table.insert(out,e) end end
    return out
end
local function SetTarget(model)
    St.target=model
    if model then
        TgtLbl.Text=model.Name;StatusLbl.Text="🔒 "..model.Name
        StatusLbl.TextColor3=Color3.fromRGB(90,178,255)
    else
        TgtLbl.Text="No Target";StatusLbl.Text="● Idle"
        StatusLbl.TextColor3=Color3.fromRGB(60,60,90)
    end
end

-- ══ ESP ══
local function ClearESP()
    for _,bb in pairs(St.espBoxes) do pcall(function() bb:Destroy() end) end
    St.espBoxes={}
end
local function UpdateESP()
    local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart")
    if not myHRP then ClearESP();return end
    local list=GetTargetList();local active={}
    for _,e in ipairs(list) do
        local m=e.model;active[m]=true
        local hrp=GetRoot(m);if not hrp then continue end
        if not St.espBoxes[m] then
            local bb=Instance.new("BillboardGui")
            bb.Adornee=hrp;bb.AlwaysOnTop=true;bb.LightInfluence=0
            bb.Size=UDim2.new(0,40,0,50);bb.Parent=hrp
            local box=Instance.new("Frame");box.Size=UDim2.new(1,0,1,0)
            box.BackgroundTransparency=1;box.BorderSizePixel=0;box.Parent=bb
            local sk=Instance.new("UIStroke");sk.Color=Color3.fromRGB(255,255,255);sk.Thickness=1.5;sk.Parent=box
            local dl=Instance.new("TextLabel");dl.Name="D"
            dl.Size=UDim2.new(1,0,0,14);dl.Position=UDim2.new(0,0,1,2)
            dl.BackgroundTransparency=1;dl.TextColor3=Color3.fromRGB(255,255,255)
            dl.TextSize=11;dl.Font=Enum.Font.GothamBold;dl.Text="0m";dl.Parent=bb
            St.espBoxes[m]=bb
        end
        local s=math.clamp(80/math.max(e.dist,5),1.2,5)
        St.espBoxes[m].Size=UDim2.new(0,s*8,0,s*12)
        local dl=St.espBoxes[m]:FindFirstChild("D")
        if dl then dl.Text=string.format("%.0fm",e.dist) end
    end
    for m,bb in pairs(St.espBoxes) do
        if not active[m] then pcall(function() bb:Destroy() end);St.espBoxes[m]=nil end
    end
end

-- ══ COLOR/EXCLUDE PICKERS ══
local function UpdateCPicker()
    for _,c in ipairs(CPScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hs,col in pairs(St.colors) do
        n=n+1
        local b=mkBtn(CPScr,"  #"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left;b.ZIndex=11
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        b.Activated:Connect(function()
            Cfg.filterColor=col;FLbl.Text="🎨 #"..hs;FLbl.TextColor3=col
            BtnCP2.BackgroundColor3=col;CPop.Visible=false;UpdateCPicker()
        end)
    end
    CPScr.CanvasSize=UDim2.new(0,0,0,CPLayout.AbsoluteContentSize.Y+4)
    if n==0 then mkLbl(CPScr,"Scan ก่อน",UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),9,Color3.fromRGB(90,90,120)).ZIndex=11 end
end
local function UpdateEPicker()
    for _,c in ipairs(EPScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hs,col in pairs(St.colors) do
        n=n+1;local sel=false
        for _,h in ipairs(St.pendEx) do if h==hs then sel=true;break end end
        local b=mkBtn(EPScr,(sel and "✓ " or "  ").."#"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),
            sel and Color3.fromRGB(90,30,30) or col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left;b.ZIndex=11
        b.Activated:Connect(function()
            local found=false
            for i,h in ipairs(St.pendEx) do if h==hs then table.remove(St.pendEx,i);found=true;break end end
            if not found then table.insert(St.pendEx,hs) end;UpdateEPicker()
        end)
    end
    EPScr.CanvasSize=UDim2.new(0,0,0,EPLayout.AbsoluteContentSize.Y+4)
    if n==0 then mkLbl(EPScr,"Scan ก่อน",UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),9,Color3.fromRGB(120,70,70)).ZIndex=11 end
    ELbl.Text=#Cfg.exclude>0 and "🚫 Exclude: "..#Cfg.exclude.." สี" or "🚫 Exclude: ไม่มี"
end

-- ══ LOCK CORE ══
local function doTP(hrp)
    local char=LP.Character;if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
    root.CFrame=hrp.CFrame+Vector3.new(0,3,0)
end
local function stopRapidTP()
    if St.rapidConn then St.rapidConn:Disconnect();St.rapidConn=nil end;St.rapidTgt=nil
end
local function startRapidTP(hrp)
    stopRapidTP();St.rapidTgt=hrp
    St.rapidConn=Svc.Run.Heartbeat:Connect(function()
        if not St.tpScan or not St.rapidTgt or not St.rapidTgt.Parent then stopRapidTP();return end
        doTP(St.rapidTgt);task.wait(St.tpRapidSpd)
    end)
end

local function StartLock()
    if St.lockConn then St.lockConn:Disconnect();St.lockConn=nil end
    local timer=0
    St.lockConn=Svc.Run.RenderStepped:Connect(function(dt)
        local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local str=math.clamp(Cfg.strength,0.01,0.99)
        if St.target then
            local hum=St.target:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health<=0 or not St.target.Parent then SetTarget(nil);St.rescan=true end
        end
        if not St.target or Cfg.nearest or St.rescan then
            timer=timer+dt
            if St.rescan or timer>=0.1 then
                timer=0;St.rescan=false
                local raw=GetTargetList();local fil=FilterList(raw);St.tgList=fil
                if #fil>0 and (Cfg.nearest or not St.target) then SetTarget(fil[1].model);St.tgIdx=1 end
            end
        end
        if not St.target then return end
        local hrp=GetRoot(St.target);local hum=St.target:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 or not St.target.Parent then SetTarget(nil);St.rescan=true;return end
        local myPos=myHRP.Position
        local head=St.target:FindFirstChild("Head")
        local tPos=head and head.Position or hrp.Position
        local camPos=Cam.CFrame.Position
        if (tPos-camPos).Magnitude<0.1 then return end
        local offCF=CFrame.lookAt(camPos,tPos)*CFrame.Angles(math.rad(-Cfg.aimY),math.rad(Cfg.aimX),0)
        local alpha=1-(1-str)^(math.min(dt,0.05)*60)
        Cam.CFrame=Cam.CFrame:Lerp(offCF,alpha)
        local cl=Cam.CFrame.LookVector
        local bl=Vector3.new(cl.X,0,cl.Z)
        if Cfg.camMode==1 then
            local ld=Vector3.new(tPos.X-myPos.X,0,tPos.Z-myPos.Z)
            if ld.Magnitude>0.1 then myHRP.CFrame=myHRP.CFrame:Lerp(CFrame.new(myPos,myPos+ld.Unit),alpha) end
        elseif Cfg.camMode==2 or Cfg.camMode==3 then
            if bl.Magnitude>0.1 then myHRP.CFrame=myHRP.CFrame:Lerp(CFrame.new(myPos,myPos+bl.Unit),alpha) end
            if Cfg.camMode==3 then UpdateCH() end
        end
        -- ══ Override Mouse.Hit → ยิงตรงเป้าเสมอ ══
        -- ใช้ fake part หลอก Mouse.Target แทน (Mouse.Hit เป็น read-only)
        local aimHRP=GetRoot(St.target)
        local aimHead=St.target:FindFirstChild("Head")
        local aimPos=aimHead and aimHead.Position or (aimHRP and aimHRP.Position)
        if aimPos and St.fakePart then
            St.fakePart.CFrame=CFrame.new(aimPos)
        end
    end)
end
local function StopLock()
    if St.lockConn then St.lockConn:Disconnect();St.lockConn=nil end
    SetTarget(nil)
end

-- ══ LOOPS ══
Svc.Run.RenderStepped:Connect(function(dt)
    if Cfg.camMode==3 and CHF.Visible then UpdateCH() end
    if St.camLocked and not St.camFree then
        local char=LP.Character;if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
        Cam.CFrame=CFrame.new(root.Position-Cam.CFrame.LookVector*St.camDist,root.Position)
    end
    if St.camFree then
        local rot=CFrame.Angles(0,math.rad(St.camAX),0)*CFrame.Angles(math.rad(St.camAY),0,0)
        local d=rot.LookVector
        St.camFreePos=St.camFreePos+d*St.camMove.Z*St.camSpd*dt*60
            +rot.RightVector*St.camMove.X*St.camSpd*dt*60
            +Vector3.new(0,1,0)*St.camMove.Y*St.camSpd*dt*60
        Cam.CFrame=CFrame.new(St.camFreePos,St.camFreePos+d)
    end
    if not St.mvHum or not St.mvRoot then return end
    St.mvHum.WalkSpeed=MvCfg.speed and MvCfg.walkSpeed or 16
    St.mvHum.JumpPower=MvCfg.jump and MvCfg.jumpPower or 50
    if MvCfg.fly and St.mvFlying and St.mvFlyBV and St.mvFlyBG then
        local cf=Cam.CFrame
        local mv=mvControls and mvControls:GetMoveVector() or Vector3.new()
        local dir=(cf.LookVector*-mv.Z)+(cf.RightVector*mv.X)+(cf.UpVector*-mv.Y)
        St.mvFlyBV.Velocity=dir*MvCfg.flySpeed
        St.mvFlyBG.CFrame=CFrame.new(St.mvRoot.Position,St.mvRoot.Position+cf.LookVector)
    end
    if MvCfg.height then
        mvRay.FilterDescendantsInstances={St.mvChar}
        local res=workspace:Raycast(St.mvRoot.Position,Vector3.new(0,-1000,0),mvRay)
        if res then
            local tgt=res.Position+res.Normal*MvCfg.heightLock
            St.mvRoot.CFrame=CFrame.new(St.mvRoot.Position.X,tgt.Y,St.mvRoot.Position.Z)
            St.mvRoot.Velocity=Vector3.new(St.mvRoot.Velocity.X,0,St.mvRoot.Velocity.Z)
        end
    end
    if St.mvChar then
        for _,v in pairs(St.mvChar:GetDescendants()) do
            if v:IsA("BasePart") then
                if MvCfg.noclip then
                    v.CanCollide=false;v.Massless=true
                else
                    -- คืนกลับปกติเมื่อปิด Noclip
                    v.CanCollide=true;v.Massless=false
                end
            end
        end
    end
    if MvCfg.antiTP then
        if St.mvLastPos then
            if (St.mvRoot.Position-St.mvLastPos).Magnitude>30 and St.mvRoot.Velocity.Magnitude<120 then
                St.mvRoot.CFrame=CFrame.new(St.mvLastPos)
            end
        end
        St.mvLastPos=St.mvRoot.Position
    else
        St.mvLastPos=nil  -- ล้างค่าเมื่อปิด AntiTP
    end
end)

Svc.Run.Heartbeat:Connect(function(dt)
    if Cfg.esp then
        St.espT=St.espT+dt
        if St.espT>=0.3 then St.espT=0;UpdateESP() end
    end
    if St.clickTP and St.lockPos then
        local char=LP.Character;if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
        if (root.Position-St.lockPos).Magnitude>10 then root.CFrame=CFrame.new(St.lockPos+Vector3.new(0,3,0)) end
    end
end)

Svc.UIS.InputChanged:Connect(function(input)
    if St.camFree and(input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        St.camAX=St.camAX-input.Delta.X*0.2
        St.camAY=math.clamp(St.camAY-input.Delta.Y*0.2,-80,80)
    end
end)

-- ══ TP REFRESH ══
local function TPRefresh()
    for _,c in ipairs(TPScr:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for i,pos in ipairs(St.tpSaves) do
        local b=mkBtn(TPScr,string.format("📍 %d (%.0f,%.0f,%.0f)",i,pos.x,pos.y,pos.z),
            UDim2.new(1,-5,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(19,19,30),Color3.fromRGB(160,180,255),10)
        b.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        b.Activated:Connect(function()
            St.tpSel=i
            local char=LP.Character or LP.CharacterAdded:Wait()
            local root=char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame=CFrame.new(pos.x,pos.y,pos.z) end
            for _,c2 in ipairs(TPScr:GetChildren()) do
                if c2:IsA("TextButton") then c2.BackgroundColor3=Color3.fromRGB(19,19,30) end
            end
            b.BackgroundColor3=Color3.fromRGB(32,50,84)
        end)
    end
    TPScr.CanvasSize=UDim2.new(0,0,0,#St.tpSaves*30)
end

-- ══ RESPAWN ══
LP.CharacterAdded:Connect(function(c)
    St.char=c;c:WaitForChild("HumanoidRootPart");St.target=nil;ClearESP()
    if Cfg.enabled then task.wait(0.5);StartLock() end
end)

-- ══ CONNECTIONS ══
InpRange.FocusLost:Connect(function()
    local v=tonumber(InpRange.Text);if v then Cfg.range=v;SaveCfg() else InpRange.Text=tostring(Cfg.range) end
end)
InpAimY.FocusLost:Connect(function()
    local v=tonumber(InpAimY.Text);if v then Cfg.aimY=v;SaveCfg() else InpAimY.Text=tostring(Cfg.aimY) end
end)
BtnAimYU.Activated:Connect(function() Cfg.aimY=Cfg.aimY+0.5;InpAimY.Text=tostring(Cfg.aimY);SaveCfg() end)
BtnAimYD.Activated:Connect(function() Cfg.aimY=Cfg.aimY-0.5;InpAimY.Text=tostring(Cfg.aimY);SaveCfg() end)
InpAimX.FocusLost:Connect(function()
    local v=tonumber(InpAimX.Text);if v then Cfg.aimX=v;SaveCfg() else InpAimX.Text=tostring(Cfg.aimX) end
end)
BtnAimXL.Activated:Connect(function() Cfg.aimX=Cfg.aimX+1;InpAimX.Text=tostring(Cfg.aimX);SaveCfg() end)
BtnAimXR.Activated:Connect(function() Cfg.aimX=Cfg.aimX-1;InpAimX.Text=tostring(Cfg.aimX);SaveCfg() end)
InpCamDist.FocusLost:Connect(function()
    local v=tonumber(InpCamDist.Text);if v then St.camDist=v else InpCamDist.Text=tostring(St.camDist) end
end)
InpCamSpd.FocusLost:Connect(function()
    local v=tonumber(InpCamSpd.Text);if v then St.camSpd=v else InpCamSpd.Text=tostring(St.camSpd) end
end)
BtnPlayer.Activated:Connect(function() Cfg.mode="Player";St.target=nil;UpdateModeUI();SaveCfg() end)
BtnNPC.Activated:Connect(function() Cfg.mode="NPC";St.target=nil;UpdateModeUI();SaveCfg() end)
BtnLock.Activated:Connect(function()
    Cfg.enabled=not Cfg.enabled
    if Cfg.enabled then BtnLock.Text="🔒 Lock : ON";BtnLock.BackgroundColor3=Color3.fromRGB(20,58,20);StartLock()
    else BtnLock.Text="🔓 Lock : OFF";BtnLock.BackgroundColor3=Color3.fromRGB(24,24,40);StopLock() end
end)
BtnNear.Activated:Connect(function()
    Cfg.nearest=not Cfg.nearest
    BtnNear.Text=Cfg.nearest and "📍 Nearest : ON" or "📍 Nearest : OFF"
    BtnNear.BackgroundColor3=Cfg.nearest and Color3.fromRGB(20,58,20) or Color3.fromRGB(24,24,40);SaveCfg()
end)
BtnPrev.Activated:Connect(function()
    if #St.tgList==0 then St.tgList=FilterList(GetTargetList()) end
    if #St.tgList>0 then St.tgIdx=St.tgIdx-1;if St.tgIdx<1 then St.tgIdx=#St.tgList end;SetTarget(St.tgList[St.tgIdx].model) end
end)
BtnNext.Activated:Connect(function()
    if #St.tgList==0 then St.tgList=FilterList(GetTargetList()) end
    if #St.tgList>0 then St.tgIdx=St.tgIdx+1;if St.tgIdx>#St.tgList then St.tgIdx=1 end;SetTarget(St.tgList[St.tgIdx].model) end
end)
BtnESP.Activated:Connect(function()
    Cfg.esp=not Cfg.esp;BtnESP.Text=Cfg.esp and "👁 ESP ON" or "👁 ESP"
    BtnESP.BackgroundColor3=Cfg.esp and Color3.fromRGB(20,50,74) or Color3.fromRGB(24,24,40)
    if not Cfg.esp then ClearESP() end
end)
BtnLockMenu.Activated:Connect(function()
    menuLocked=not menuLocked;BtnLockMenu.Text=menuLocked and "🔒" or "🔓"
    BtnLockMenu.BackgroundColor3=menuLocked and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62)
end)
local minimized=false
BtnMin.Activated:Connect(function()
    minimized=not minimized;Con.Visible=not minimized
    MF.Size=minimized and UDim2.new(0,232,0,32) or UDim2.new(0,232,0,440)
end)
BtnClose.Activated:Connect(function()
    StopLock();ClearESP();CHF.Visible=false
    if St.fakePart then St.fakePart:Destroy();St.fakePart=nil end
    SG:Destroy()
end)
local scanVis=false
BtnScan.Activated:Connect(function()
    scanVis=not scanVis;SF.Visible=scanVis
    BtnScan.BackgroundColor3=scanVis and Color3.fromRGB(24,40,74) or Color3.fromRGB(24,24,40)
end)
BtnSClose.Activated:Connect(function()
    scanVis=false;SF.Visible=false;CPop.Visible=false;EPop.Visible=false
    BtnScan.BackgroundColor3=Color3.fromRGB(24,24,40)
end)
local sMin=false
BtnSMin.Activated:Connect(function()
    sMin=not sMin;SScr.Visible=not sMin;BtnDoScan.Visible=not sMin
    ScanCntLbl.Visible=not sMin;FBar.Visible=not sMin;EBar.Visible=not sMin
    SF.Size=sMin and UDim2.new(0,220,0,30) or UDim2.new(0,220,0,340)
    if sMin then CPop.Visible=false;EPop.Visible=false end
end)
BtnDoScan.Activated:Connect(function()
    for _,c in ipairs(SScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local raw=GetTargetList();St.colors={}
    for _,e in ipairs(raw) do local h=Hex(e.color);if not St.colors[h] then St.colors[h]=e.color end end
    local list=FilterList(raw);St.tgList=list
    ScanCntLbl.Text=#list.." found (raw:"..#raw..")"
    for i,e in ipairs(list) do
        local b=mkBtn(SScr,string.format("  [%d] %s  %.0fm",i,e.name,e.dist),
            UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(14,14,22),e.color,9)
        b.TextXAlignment=Enum.TextXAlignment.Left
        local dot=Instance.new("Frame");dot.Size=UDim2.new(0,6,0,6);dot.Position=UDim2.new(0,4,0.5,-3)
        dot.BackgroundColor3=e.color;dot.BorderSizePixel=0;dot.Parent=b
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        b.Activated:Connect(function()
            St.tgIdx=i;SetTarget(e.model)
            if St.tpScan then
                local hrp=GetRoot(e.model)
                if hrp then
                    if St.tpModeSelect==1 then stopRapidTP();doTP(hrp)
                    else startRapidTP(hrp) end
                end
            end
        end)
    end
    SScr.CanvasSize=UDim2.new(0,0,0,SLayout.AbsoluteContentSize.Y+4)
    UpdateCPicker();UpdateEPicker()
end)
BtnCP2.Activated:Connect(function() CPop.Visible=not CPop.Visible;EPop.Visible=false;if CPop.Visible then UpdateCPicker() end end)
BtnCPClose.Activated:Connect(function() CPop.Visible=false end)
BtnCPAll.Activated:Connect(function()
    Cfg.filterColor=nil;FLbl.Text="🎨 Filter: ทั้งหมด";FLbl.TextColor3=Color3.fromRGB(120,120,170)
    BtnCP2.BackgroundColor3=Color3.fromRGB(48,48,160);CPop.Visible=false;UpdateCPicker()
end)
BtnCF.Activated:Connect(function()
    Cfg.filterColor=nil;FLbl.Text="🎨 Filter: ทั้งหมด";FLbl.TextColor3=Color3.fromRGB(120,120,170)
    BtnCP2.BackgroundColor3=Color3.fromRGB(48,48,160);UpdateCPicker()
end)
BtnExc.Activated:Connect(function()
    EPop.Visible=not EPop.Visible;CPop.Visible=false
    if EPop.Visible then St.pendEx={};for _,h in ipairs(Cfg.exclude) do table.insert(St.pendEx,h) end;UpdateEPicker() end
end)
BtnEPClose.Activated:Connect(function() EPop.Visible=false;St.pendEx={} end)
BtnEPOk.Activated:Connect(function()
    Cfg.exclude={};for _,h in ipairs(St.pendEx) do table.insert(Cfg.exclude,h) end
    UpdateEPicker();EPop.Visible=false;St.pendEx={}
end)
BtnCE.Activated:Connect(function() Cfg.exclude={};St.pendEx={};UpdateEPicker() end)
local camVis=false
BtnCamSys.Activated:Connect(function()
    camVis=not camVis;CamF.Visible=camVis
    BtnCamSys.BackgroundColor3=camVis and Color3.fromRGB(74,50,16) or Color3.fromRGB(24,24,40)
end)
local camMin2=false
BtnCamMin.Activated:Connect(function()
    camMin2=not camMin2;CamCon.Visible=not camMin2
    CamF.Size=camMin2 and UDim2.new(0,190,0,30) or UDim2.new(0,190,0,200)
    if camMin2 then CtrlPad.Visible=false end
end)
BtnCamClose.Activated:Connect(function()
    camVis=false;CamF.Visible=false;CtrlPad.Visible=false;St.camFree=false
    BtnCamSys.BackgroundColor3=Color3.fromRGB(24,24,40)
end)
BtnCamLock.Activated:Connect(function()
    St.camLocked=not St.camLocked
    BtnCamLock.Text=St.camLocked and "🔒 Lock Cam ON" or "🔒 Lock Cam OFF"
    BtnCamLock.BackgroundColor3=St.camLocked and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
end
BtnCamFree.Activated:Connect(function()
    St.camFree=not St.camFree
    BtnCamFree.Text=St.camFree and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    BtnCamFree.BackgroundColor3=St.camFree and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
    CtrlPad.Visible=St.camFree
    if St.camFree then St.camFreePos=Cam.CFrame.Position end
end)
local tpVis=false
BtnTP.Activated:Connect(function()
    tpVis=not tpVis;TF.Visible=tpVis
    BtnTP.BackgroundColor3=tpVis and Color3.fromRGB(16,50,26) or Color3.fromRGB(24,24,40)
    if tpVis then TPRefresh() end
end)
local tpMin=false
BtnTFMin.Activated:Connect(function()
    tpMin=not tpMin;TPScr.Visible=not tpMin
    BtnTPSave.Visible=not tpMin;BtnTPClic.Visible=not tpMin;BtnTPDel.Visible=not tpMin
    TF.Size=tpMin and UDim2.new(0,210,0,30) or UDim2.new(0,210,0,260)
end)
BtnTFClose.Activated:Connect(function() tpVis=false;TF.Visible=false;BtnTP.BackgroundColor3=Color3.fromRGB(24,24,40) end)
BtnTPSave.Activated:Connect(function()
    local char=LP.Character or LP.CharacterAdded:Wait()
    local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
    table.insert(St.tpSaves,{x=root.Position.X,y=root.Position.Y,z=root.Position.Z});TPRefresh()
end)
BtnTPDel.Activated:Connect(function()
    if St.tpSel then table.remove(St.tpSaves,St.tpSel);St.tpSel=nil;TPRefresh() end
end)
BtnTPClic.Activated:Connect(function()
    St.clickTP=not St.clickTP;if not St.clickTP then St.lockPos=nil end
    BtnTPClic.Text=St.clickTP and "Click TP ON" or "Click TP OFF"
    BtnTPClic.BackgroundColor3=St.clickTP and Color3.fromRGB(20,92,40) or Color3.fromRGB(130,32,32)
end)
Mouse.Button1Down:Connect(function()
    if not St.clickTP then return end
    local char=LP.Character;if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
    local hit=Mouse.Hit;if hit then St.lockPos=hit.Position;root.CFrame=CFrame.new(St.lockPos+Vector3.new(0,3,0)) end
end)
local mvVis=false
BtnMove.Activated:Connect(function()
    mvVis=not mvVis;MvF.Visible=mvVis
    BtnMove.BackgroundColor3=mvVis and Color3.fromRGB(20,70,25) or Color3.fromRGB(24,24,40)
end)
local mvMin=false
BtnMvMin.Activated:Connect(function()
    mvMin=not mvMin;MvScr.Visible=not mvMin
    MvF.Size=mvMin and UDim2.new(0,260,0,30) or UDim2.new(0,260,0,360)
end)
BtnMvClose.Activated:Connect(function()
    mvVis=false;MvF.Visible=false;BtnMove.BackgroundColor3=Color3.fromRGB(24,24,40)
end)
BtnTPScan.Activated:Connect(function()
    St.tpScan=not St.tpScan
    if St.tpScan then BtnTPScan.BackgroundColor3=Color3.fromRGB(20,120,20);TPMPop.Visible=true
    else BtnTPScan.BackgroundColor3=Color3.fromRGB(30,80,30);TPMPop.Visible=false;stopRapidTP() end
end)
BtnTPM1.Activated:Connect(function() St.tpModeSelect=1;UpdateTPMUI() end)
BtnTPM2.Activated:Connect(function() St.tpModeSelect=2;UpdateTPMUI() end)
BtnTPMClose.Activated:Connect(function() TPMPop.Visible=false end)
InpTPSpd.FocusLost:Connect(function()
    local v=tonumber(InpTPSpd.Text);if v and v>0 then St.tpRapidSpd=v else InpTPSpd.Text=tostring(St.tpRapidSpd) end
end)

-- ══ INIT ══
if Cfg.nearest then BtnNear.Text="📍 Nearest : ON";BtnNear.BackgroundColor3=Color3.fromRGB(20,58,20) end
UpdateCamModeUI()
