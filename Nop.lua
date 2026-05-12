-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SpeedMenu v11b (base: v10)                                  ║
-- ║  + Scan รองรับ AnimationController (non-Humanoid)           ║
-- ║  + ESP Highlight คลุมบอดี้จริง                              ║
-- ║  + หนีเป้าหมาย (Flee) เดิน/TP เลือกสีหนี                  ║
-- ║  + หมุนรอบเป้าหมาย (Orbit) สลับซ้าย/ขวา                   ║
-- ║  + ทะลุกำแพง (NoClip) ON/OFF                                ║
-- ╚══════════════════════════════════════════════════════════════╝

local Svc={
    Players=game:GetService("Players"),
    Run=game:GetService("RunService"),
    UIS=game:GetService("UserInputService"),
}
local LP=Svc.Players.LocalPlayer
local Cam=workspace.CurrentCamera
local Mouse=LP:GetMouse()

-- ══ PERSISTENT SAVE ══
local SaveFile="SpeedMenu_v11b.json"
local function LoadSave()
    local ok,raw=pcall(function() return readfile(SaveFile) end)
    if ok and raw and #raw>2 then
        local ok2,data=pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
        if ok2 and type(data)=="table" then return data end
    end
    local ok3,data=pcall(function() return _G["SpeedMenu_v11b"] or {} end)
    return (ok3 and type(data)=="table") and data or {}
end
local function WriteSave(t)
    _G["SpeedMenu_v11b"]=t
    pcall(function()
        writefile(SaveFile,game:GetService("HttpService"):JSONEncode(t))
    end)
end

local S=LoadSave()
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
    wingSpd=S.wingSpd or 20,
    noClip=false,
    orbitOn=false,
    orbitSpd=S.orbitSpd or 40,
    orbitAlt=S.orbitAlt or false,
    orbitL=S.orbitL or 10,
    orbitR=S.orbitR or 5,
    fleeOn=false,
    fleeRadius=S.fleeRadius or 15,
    fleeMode=S.fleeMode or "walk",
    fleeSpd=S.fleeSpd or 30,
    fleeColors={},
}
local TpOff={L=S.tpL or 0,R=S.tpR or 0,U=S.tpU or 0,D=S.tpD or 0,F=S.tpF or 0,B=S.tpB or 0}
local Presets=S.presets or {}

local St={
    char=LP.Character or LP.CharacterAdded:Wait(),
    target=nil,
    tgList={},
    tgIdx=1,
    lockConn=nil,
    colors={},
    rescan=false,
    tpScan=false,
    espHL={},
    espT=0,
    tpSaves=S.tpSaves or {},
    tpSel=nil,
    clickTP=false,
    lockPos=nil,
    camLocked=false,
    camFree=false,
    camDist=50,
    camSpd=5,
    camAX=0,camAY=0,
    camMove=Vector3.new(),
    camFreePos=Vector3.new(),
    rapidConn=nil,
    rapidTgt=nil,
    tpModeSelect=1,
    tpRapidSpd=S.tpRapidSpd or 0.05,
    pendEx={},
    fakePart=nil,
    wingOn=false,
    wingConn=nil,
    wingTgt=nil,
    wingLiftY=0,
    wingLiftTarget=0,
    autoScanOn=false,
    autoScanConn=nil,
    orbitConn=nil,
    orbitAngle=0,
    orbitDir=1,
    orbitTimer=0,
    fleeConn=nil,
    noClipConn=nil,
}

local function SaveCfg()
    WriteSave({
        strength=Cfg.strength,range=Cfg.range,mode=Cfg.mode,
        nearest=Cfg.nearest,aimY=Cfg.aimY,aimX=Cfg.aimX,
        wingSpd=Cfg.wingSpd,
        orbitSpd=Cfg.orbitSpd,orbitAlt=Cfg.orbitAlt,orbitL=Cfg.orbitL,orbitR=Cfg.orbitR,
        fleeRadius=Cfg.fleeRadius,fleeMode=Cfg.fleeMode,fleeSpd=Cfg.fleeSpd,
        tpRapidSpd=St.tpRapidSpd,
        tpL=TpOff.L,tpR=TpOff.R,tpU=TpOff.U,tpD=TpOff.D,tpF=TpOff.F,tpB=TpOff.B,
        tpSaves=St.tpSaves,
        presets=Presets,
    })
end

-- ══ GUI CLEANUP ══
pcall(function()
    for _,n in ipairs({"LM_v18","LM_v16","LM_v19","SpeedMenu","SpeedMenu2","SpeedMenu3",
        "SpeedMenu4","SpeedMenu5","SpeedMenu6","SpeedMenu9","SpeedMenu10","SpeedMenu11","SpeedMenu11b"}) do
        local pg=LP:FindFirstChild("PlayerGui")
        local cg=game:GetService("CoreGui")
        if pg and pg:FindFirstChild(n) then pg:FindFirstChild(n):Destroy() end
        if cg and cg:FindFirstChild(n) then cg:FindFirstChild(n):Destroy() end
    end
end)
local SG=Instance.new("ScreenGui")
SG.Name="SpeedMenu11b";SG.ResetOnSpawn=false
SG.DisplayOrder=999;SG.IgnoreGuiInset=true
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

-- ══ FAKE PART ══
local fakePart=Instance.new("Part")
fakePart.Name="FakeAimPart";fakePart.Size=Vector3.new(0.1,0.1,0.1)
fakePart.Anchored=true;fakePart.CanCollide=false
fakePart.Transparency=1;fakePart.CastShadow=false
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

-- ══ DRAG ══
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

-- ══ LOCK BUTTON ══
local function mkMenuLock(tb,offFromRight)
    local locked=false
    local btn=mkBtn(tb,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-(offFromRight or 72),0.5,-11),Color3.fromRGB(40,40,62))
    btn.Activated:Connect(function()
        locked=not locked
        btn.Text=locked and "🔒" or "🔓"
        btn.BackgroundColor3=locked and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62)
    end)
    return function() return locked end
end

-- ══ RESIZE ══
local function mkResizeInput(tb,frame,baseW,baseH)
    local BtnSize=mkBtn(tb,"⊡",UDim2.new(0,22,0,22),UDim2.new(0,4,0.5,-11),Color3.fromRGB(35,35,58),Color3.fromRGB(160,160,220),11)
    local pop=mkFrame(SG,UDim2.new(0,60,0,220),UDim2.new(0,0,0,0),Color3.fromRGB(14,14,24),true,6)
    pop.Visible=false;pop.ZIndex=80
    for n=10,1,-1 do
        local idx=11-n
        local b=mkBtn(pop,tostring(n),UDim2.new(1,0,0,20),UDim2.new(0,0,0,(idx-1)*22),
            n==10 and Color3.fromRGB(50,70,130) or Color3.fromRGB(22,22,36),Color3.fromRGB(200,200,255),10)
        b.ZIndex=81
        b.Activated:Connect(function()
            local sc=n/10
            frame.Size=UDim2.new(0,math.max(100,math.round(baseW*sc)),0,math.max(60,math.round(baseH*sc)))
            BtnSize.Text=tostring(n);pop.Visible=false
        end)
    end
    BtnSize.Activated:Connect(function()
        pop.Visible=not pop.Visible
        if pop.Visible then
            local abs=BtnSize.AbsolutePosition
            pop.Position=UDim2.new(0,abs.X,0,abs.Y+24)
        end
    end)
    pop.Parent=SG
end

-- ══ MINI-UI SYSTEM ══
local function mkMiniUI(btnRef,label,toggleFn,getStateFn)
    local miniF=mkFrame(SG,UDim2.new(0,80,0,40),btnRef.Position,Color3.fromRGB(20,20,36),false,6)
    miniF.ZIndex=200;miniF.Visible=false
    local miniBar=mkFrame(miniF,UDim2.new(1,0,0,14),UDim2.new(0,0,0,0),Color3.fromRGB(30,30,50),false,6)
    miniBar.ZIndex=201
    local miniLocked=false
    mkDrag(miniF,miniBar,function() return miniLocked end)
    local miniLbl=mkLbl(miniF,label,UDim2.new(1,-22,0,14),UDim2.new(0,2,0,0),7,Color3.fromRGB(200,200,255),Enum.Font.GothamBold)
    miniLbl.ZIndex=202
    local miniLockBtn=mkBtn(miniBar,"🔓",UDim2.new(0,12,0,12),UDim2.new(1,-13,0.5,-6),Color3.fromRGB(40,40,62),Color3.fromRGB(200,200,220),6)
    miniLockBtn.ZIndex=203
    miniLockBtn.Activated:Connect(function()
        miniLocked=not miniLocked
        miniLockBtn.Text=miniLocked and "🔒" or "🔓"
        miniLockBtn.BackgroundColor3=miniLocked and Color3.fromRGB(100,70,20) or Color3.fromRGB(40,40,62)
    end)
    local miniClose=mkBtn(miniF,"✕",UDim2.new(0,16,0,16),UDim2.new(0.5,-8,1,-18),Color3.fromRGB(120,24,24),Color3.fromRGB(255,255,255),8)
    miniClose.ZIndex=203
    miniClose.Activated:Connect(function() miniF:Destroy() end)
    local isToggle=(getStateFn~=nil)
    local miniToggle=mkBtn(miniF,"●",UDim2.new(1,-4,0,16),UDim2.new(0,2,0,16),Color3.fromRGB(24,24,44),Color3.fromRGB(180,180,255),9)
    miniToggle.ZIndex=203
    local function refreshMiniToggle()
        if isToggle then
            local on=getStateFn()
            miniToggle.Text=on and "ON" or "OFF"
            miniToggle.BackgroundColor3=on and Color3.fromRGB(20,70,20) or Color3.fromRGB(70,20,20)
            miniToggle.TextColor3=on and Color3.fromRGB(150,255,150) or Color3.fromRGB(255,150,150)
        else
            miniToggle.Text="กด"
            miniToggle.BackgroundColor3=Color3.fromRGB(40,60,120)
            miniToggle.TextColor3=Color3.fromRGB(180,220,255)
        end
    end
    refreshMiniToggle()
    miniToggle.Activated:Connect(function()
        if toggleFn then toggleFn() end
        refreshMiniToggle()
        if not isToggle then
            miniToggle.BackgroundColor3=Color3.fromRGB(70,120,200)
            task.delay(0.15,function() miniToggle.BackgroundColor3=Color3.fromRGB(40,60,120) end)
        end
    end)
    return miniF,refreshMiniToggle
end

-- ══ TRIPLE-CLICK BIND ══
local function bindTripleClick(btn,label,toggleFn,getStateFn)
    local clicks=0
    local lastT=0
    local miniRef=nil
    local miniRefresh=nil
    btn.Activated:Connect(function()
        local now=tick()
        if now-lastT>0.6 then clicks=0 end
        lastT=now;clicks=clicks+1
        if clicks>=3 then
            clicks=0
            if not miniRef or not miniRef.Parent then
                miniRef,miniRefresh=mkMiniUI(btn,label,toggleFn,getStateFn)
                miniRef.Parent=SG
            end
            miniRef.Visible=not miniRef.Visible
            if miniRef.Visible then
                local abs=btn.AbsolutePosition
                miniRef.Position=UDim2.new(0,abs.X,0,abs.Y-48)
                if miniRefresh then miniRefresh() end
            end
        end
    end)
end

-- ══ CROSSHAIR ══
local CHF=Instance.new("Frame")
CHF.Name="Crosshair";CHF.Size=UDim2.new(0,20,0,20)
CHF.AnchorPoint=Vector2.new(0.5,0.5);CHF.BackgroundTransparency=1;CHF.ZIndex=100;CHF.Parent=SG
local cvL=Instance.new("Frame",CHF);cvL.Size=UDim2.new(0,2,1,0);cvL.Position=UDim2.new(0.5,-1,0,0)
cvL.BackgroundColor3=Color3.fromRGB(255,80,80);cvL.BorderSizePixel=0;cvL.ZIndex=100
local chL=Instance.new("Frame",CHF);chL.Size=UDim2.new(1,0,0,2);chL.Position=UDim2.new(0,0,0.5,-1)
chL.BackgroundColor3=Color3.fromRGB(255,80,80);chL.BorderSizePixel=0;chL.ZIndex=100
local cDot=Instance.new("Frame",CHF);cDot.Size=UDim2.new(0,6,0,6);cDot.Position=UDim2.new(0.5,-3,0.5,-3)
cDot.BackgroundColor3=Color3.fromRGB(255,255,255);cDot.BorderSizePixel=0;cDot.ZIndex=101
Instance.new("UICorner",cDot).CornerRadius=UDim.new(1,0)
CHF.Visible=false
local function UpdateCH()
    local vp=Cam.ViewportSize
    CHF.Position=UDim2.new(0,vp.X/2-Cfg.aimX*4,0,vp.Y/2-Cfg.aimY*4)
end

-- ══ MAIN FRAME ══
local menuLocked=false
local MF=mkFrame(SG,UDim2.new(0,232,0,360),UDim2.new(0.5,-116,0.5,-180),Color3.fromRGB(11,11,17),true)
local TB=mkFrame(MF,UDim2.new(1,0,0,32),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8)
TB.ClipsDescendants=false;mkAccent(TB)
mkDrag(MF,TB,function() return menuLocked end)
mkLbl(TB,"⚔ SpeedMenu v11b",UDim2.new(1,-112,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResizeInput(TB,MF,232,360)
local BtnLockMenu=mkBtn(TB,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-72,0.5,-11),Color3.fromRGB(40,40,62))
local BtnMin=mkBtn(TB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-48,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),14)
local BtnClose=mkBtn(TB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-24,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)

local ConOuter=Instance.new("Frame")
ConOuter.Size=UDim2.new(1,0,1,-32);ConOuter.Position=UDim2.new(0,0,0,32)
ConOuter.BackgroundTransparency=1;ConOuter.Parent=MF;ConOuter.ClipsDescendants=true

local Con=Instance.new("ScrollingFrame")
Con.Size=UDim2.new(1,0,1,0);Con.Position=UDim2.new(0,0,0,0)
Con.BackgroundTransparency=1;Con.BorderSizePixel=0
Con.ScrollBarThickness=3;Con.CanvasSize=UDim2.new(0,0,0,400)
Con.ScrollingDirection=Enum.ScrollingDirection.Y
Con.Parent=ConOuter

-- Main content (ส่วน v10 เดิม)
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
mkLbl(Con,"📏 Range",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,57),9)
local InpRange=mkInp(Con,Cfg.range,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,70))
mkDiv(Con,100)
mkLbl(Con,"⬆ Aim Y",UDim2.new(0,50,0,13),UDim2.new(0,8,0,104),9)
mkLbl(Con,"↔ Aim X",UDim2.new(0,50,0,13),UDim2.new(0,120,0,104),9)
local InpAimY=mkInp(Con,Cfg.aimY,UDim2.new(0,80,0,24),UDim2.new(0,8,0,117))
local InpAimX=mkInp(Con,Cfg.aimX,UDim2.new(0,80,0,24),UDim2.new(0,120,0,117))
local BtnAimYU=mkBtn(Con,"+",UDim2.new(0,20,0,10),UDim2.new(0,90,0,117),Color3.fromRGB(35,55,35),Color3.fromRGB(175,255,175),10)
local BtnAimYD=mkBtn(Con,"–",UDim2.new(0,20,0,10),UDim2.new(0,90,0,131),Color3.fromRGB(55,28,28),Color3.fromRGB(255,175,175),10)
local BtnAimXL=mkBtn(Con,"+",UDim2.new(0,20,0,10),UDim2.new(0,202,0,117),Color3.fromRGB(35,35,65),Color3.fromRGB(175,175,255),10)
local BtnAimXR=mkBtn(Con,"–",UDim2.new(0,20,0,10),UDim2.new(0,202,0,131),Color3.fromRGB(65,28,28),Color3.fromRGB(255,175,175),10)
mkDiv(Con,147)
local BtnLock=mkBtn(Con,"🔓 Lock : OFF",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,153),Color3.fromRGB(24,24,40),Color3.fromRGB(175,175,255),12)
local BtnNear=mkBtn(Con,"📍 Nearest : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,187),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),11)
local BtnPrev=mkBtn(Con,"◀",UDim2.new(0,38,0,26),UDim2.new(0,8,0,219),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)
local TgtLbl=Instance.new("TextLabel");TgtLbl.Size=UDim2.new(0,122,0,26);TgtLbl.Position=UDim2.new(0,50,0,219)
TgtLbl.BackgroundColor3=Color3.fromRGB(15,15,26);TgtLbl.BorderSizePixel=0;TgtLbl.Text="No Target"
TgtLbl.TextColor3=Color3.fromRGB(130,170,255);TgtLbl.TextSize=10;TgtLbl.Font=Enum.Font.GothamBold
TgtLbl.TextTruncate=Enum.TextTruncate.AtEnd;TgtLbl.Parent=Con
Instance.new("UICorner",TgtLbl).CornerRadius=UDim.new(0,5)
local BtnNext=mkBtn(Con,"▶",UDim2.new(0,38,0,26),UDim2.new(0,176,0,219),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)
mkDiv(Con,251)
local BtnESP=mkBtn(Con,"👁 ESP",UDim2.new(0,50,0,26),UDim2.new(0,8,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnScan=mkBtn(Con,"🔍 Scan",UDim2.new(0,50,0,26),UDim2.new(0,62,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnCamSys=mkBtn(Con,"📷 Cam",UDim2.new(0,50,0,26),UDim2.new(0,116,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnTP=mkBtn(Con,"🚀 TP",UDim2.new(0,46,0,26),UDim2.new(0,170,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
mkDiv(Con,289)
local StatusLbl=mkLbl(Con,"● Idle",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,294),10,Color3.fromRGB(60,60,90))
local BtnSaveMenu=mkBtn(Con,"💾",UDim2.new(0,26,0,20),UDim2.new(1,-32,0,294),Color3.fromRGB(28,42,28),Color3.fromRGB(170,255,140),10)
mkDiv(Con,320)
-- ปุ่มใหม่ v11b
local BtnFleeMenu=mkBtn(Con,"🏃 หนีเป้าหมาย",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,326),Color3.fromRGB(24,24,40),Color3.fromRGB(255,200,140),10)

-- ══ SCAN FRAME ══
local SF=mkFrame(SG,UDim2.new(0,220,0,380),UDim2.new(0.5,126,0.5,-190),Color3.fromRGB(11,11,17),true)
SF.Visible=false
local STB=mkFrame(SF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);mkAccent(STB)
local scanLocked=mkMenuLock(STB,118)
mkDrag(SF,STB,scanLocked)
mkResizeInput(STB,SF,220,380)
mkLbl(STB,"🔍 Scan",UDim2.new(1,-150,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)

local BtnScanOpts=mkBtn(STB,"⚙",UDim2.new(0,24,0,22),UDim2.new(1,-98,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(200,200,255),12)
local ScanOptsDrop=mkFrame(SG,UDim2.new(0,185,0,216),UDim2.new(0,0,0,0),Color3.fromRGB(16,16,28),true,8)
ScanOptsDrop.Visible=false;ScanOptsDrop.ZIndex=60
local SOLayout=Instance.new("UIListLayout",ScanOptsDrop);SOLayout.Padding=UDim.new(0,3)
local function mkSOBtn(t,col,tc)
    local b=mkBtn(ScanOptsDrop,t,UDim2.new(1,-8,0,30),UDim2.new(0,4,0,0),col or Color3.fromRGB(26,26,42),tc or Color3.fromRGB(200,200,255),10)
    b.ZIndex=61;return b
end
local BtnSOTPScan=mkSOBtn("🚀 TP Scan",Color3.fromRGB(30,80,30),Color3.fromRGB(180,255,180))
local BtnSOAutoScan=mkSOBtn("🔄 Auto Scan OFF",Color3.fromRGB(24,24,44),Color3.fromRGB(140,140,210))
local BtnSOTPOff=mkSOBtn("📐 TP Offset",Color3.fromRGB(30,50,80),Color3.fromRGB(170,200,255))
local BtnSOColor=mkSOBtn("🎨 Filter Color",Color3.fromRGB(48,48,160))
local BtnSOExclude=mkSOBtn("🚫 Exclude",Color3.fromRGB(100,30,30),Color3.fromRGB(255,170,170))
local BtnSODoScan=mkSOBtn("🔍 Scan Now",Color3.fromRGB(32,32,66),Color3.fromRGB(180,180,255))
local BtnSONoClip=mkSOBtn("🧱 NoClip OFF",Color3.fromRGB(60,30,80),Color3.fromRGB(210,170,255))

BtnScanOpts.Activated:Connect(function()
    ScanOptsDrop.Visible=not ScanOptsDrop.Visible
    if ScanOptsDrop.Visible then
        local abs=BtnScanOpts.AbsolutePosition
        ScanOptsDrop.Position=UDim2.new(0,abs.X-4,0,abs.Y+26)
    end
end)

local BtnTPScan=BtnSOTPScan
local BtnTPOff=BtnSOTPOff
local BtnCP2=BtnSOColor
local BtnExc=BtnSOExclude
local BtnAutoScan=BtnSOAutoScan
local BtnDoScan2=BtnSODoScan
local BtnNoClipBtn=BtnSONoClip

local BtnSMin=mkBtn(STB,"–",UDim2.new(0,20,0,20),UDim2.new(1,-44,0.5,-10),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),12)
local BtnSClose=mkBtn(STB,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10)

local ScanConOuter=Instance.new("Frame")
ScanConOuter.Size=UDim2.new(1,0,1,-30);ScanConOuter.Position=UDim2.new(0,0,0,30)
ScanConOuter.BackgroundTransparency=1;ScanConOuter.ClipsDescendants=true;ScanConOuter.Parent=SF

local ScanCon=Instance.new("ScrollingFrame")
ScanCon.Size=UDim2.new(1,0,1,0);ScanCon.Position=UDim2.new(0,0,0,0)
ScanCon.BackgroundTransparency=1;ScanCon.BorderSizePixel=0
ScanCon.ScrollBarThickness=3;ScanCon.CanvasSize=UDim2.new(0,0,0,400)
ScanCon.ScrollingDirection=Enum.ScrollingDirection.Y;ScanCon.Parent=ScanConOuter

local FBar=mkFrame(ScanCon,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,4),Color3.fromRGB(16,16,26),false,5)
local FLbl=mkLbl(FBar,"🎨 Filter: ทั้งหมด",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(120,120,170))
local BtnCF=mkBtn(FBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)
local EBar=mkFrame(ScanCon,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,28),Color3.fromRGB(20,10,10),false,5)
local ELbl=mkLbl(EBar,"🚫 Exclude: ไม่มี",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(170,105,105))
local BtnCE=mkBtn(EBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)
local ScanCntLbl=mkLbl(ScanCon,"0 found",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,52),9,Color3.fromRGB(70,70,110))
local SScr=Instance.new("ScrollingFrame");SScr.Size=UDim2.new(1,-8,1,-70);SScr.Position=UDim2.new(0,4,0,68)
SScr.BackgroundTransparency=1;SScr.BorderSizePixel=0;SScr.ScrollBarThickness=3
SScr.CanvasSize=UDim2.new(0,0,0,0);SScr.Parent=ScanCon
local SLayout=Instance.new("UIListLayout");SLayout.Padding=UDim.new(0,3);SLayout.Parent=SScr

-- ══ TP OFFSET POPUP ══
local TPOffPop=mkFrame(SG,UDim2.new(0,210,0,230),UDim2.new(0.5,126,0.5,185),Color3.fromRGB(10,14,22),true)
TPOffPop.Visible=false;TPOffPop.ZIndex=14
local TPOffBar=mkFrame(TPOffPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,24,36),false,8);TPOffBar.ZIndex=14
local tpOffLocked=mkMenuLock(TPOffBar,46)
mkDrag(TPOffPop,TPOffBar,tpOffLocked);mkAccent(TPOffBar,Color3.fromRGB(80,160,255))
mkResizeInput(TPOffBar,TPOffPop,210,230)
mkLbl(TPOffBar,"📐 TP Offset",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(200,220,255),Enum.Font.GothamBold)
local BtnTPOffClose=mkBtn(TPOffBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnTPOffClose.ZIndex=14
mkLbl(TPOffPop,"ใส่ 0 = ชิดเป้า | มากกว่า = ห่างออก",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,30),8,Color3.fromRGB(100,130,180))
local offDefs={{k="L",label="◀ ซ้าย",col=0},{k="R",label="▶ ขวา",col=1},
    {k="U",label="▲ บน",col=0},{k="D",label="▼ ล่าง",col=1},
    {k="F",label="▶ หน้า",col=0},{k="B",label="◀ หลัง",col=1}}
local offInputs={}
for i,d in ipairs(offDefs) do
    local row=math.floor((i-1)/2)
    local x=d.col==0 and 8 or 112
    local y=46+row*46
    mkLbl(TPOffPop,d.label,UDim2.new(0,90,0,14),UDim2.new(0,x,0,y),9,Color3.fromRGB(160,190,240))
    local inp=mkInp(TPOffPop,TpOff[d.k],UDim2.new(0,90,0,24),UDim2.new(0,x,0,y+16));inp.ZIndex=14
    offInputs[d.k]=inp
    inp.FocusLost:Connect(function()
        local v=tonumber(inp.Text)
        if v then TpOff[d.k]=v;SaveCfg() else inp.Text=tostring(TpOff[d.k]) end
    end)
end
local BtnTPOffReset=mkBtn(TPOffPop,"↺ Reset",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,190),Color3.fromRGB(40,30,60),Color3.fromRGB(190,170,255),9);BtnTPOffReset.ZIndex=14
BtnTPOffReset.Activated:Connect(function()
    for _,d in ipairs(offDefs) do TpOff[d.k]=0;offInputs[d.k].Text="0" end;SaveCfg()
end)
BtnTPOffClose.Activated:Connect(function() TPOffPop.Visible=false end)
BtnTPOff.Activated:Connect(function() TPOffPop.Visible=not TPOffPop.Visible;ScanOptsDrop.Visible=false end)

-- ══ COLOR PICKER ══
local CPop=mkFrame(SG,UDim2.new(0,200,0,230),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,12,18),true)
CPop.Visible=false;CPop.ZIndex=10
local CPBar=mkFrame(CPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);CPBar.ZIndex=10
local cpLocked=mkMenuLock(CPBar,46)
mkDrag(CPop,CPBar,cpLocked)
mkResizeInput(CPBar,CPop,200,230)
mkLbl(CPBar,"🎨 Filter Color",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
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
local epLocked=mkMenuLock(EPBar,46)
mkDrag(EPop,EPBar,epLocked)
mkResizeInput(EPBar,EPop,200,260)
mkLbl(EPBar,"🚫 Exclude Color",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,190,190),Enum.Font.GothamBold)
local BtnEPClose=mkBtn(EPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnEPClose.ZIndex=10
mkLbl(EPop,"กดสีที่ไม่ต้องการล็อค → OK",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,30),9,Color3.fromRGB(190,148,148))
local BtnEPOk=mkBtn(EPop,"✅ OK",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,52),Color3.fromRGB(26,50,26),Color3.fromRGB(170,255,170),9);BtnEPOk.ZIndex=10
local EPScr=Instance.new("ScrollingFrame");EPScr.Size=UDim2.new(1,-8,1,-80);EPScr.Position=UDim2.new(0,4,0,78)
EPScr.BackgroundTransparency=1;EPScr.BorderSizePixel=0;EPScr.ScrollBarThickness=3
EPScr.CanvasSize=UDim2.new(0,0,0,0);EPScr.ZIndex=10;EPScr.Parent=EPop
local EPLayout=Instance.new("UIListLayout");EPLayout.Padding=UDim.new(0,3);EPLayout.Parent=EPScr

-- ══ TP MODE POPUP ══
local TPMPop=mkFrame(SG,UDim2.new(0,220,0,380),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,15,22),true)
TPMPop.Visible=false;TPMPop.ZIndex=12
local TPMBar=mkFrame(TPMPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,22,35),false,8);TPMBar.ZIndex=12
local tpmLocked=mkMenuLock(TPMBar,46)
mkDrag(TPMPop,TPMBar,tpmLocked);mkAccent(TPMBar,Color3.fromRGB(50,200,120))
mkResizeInput(TPMBar,TPMPop,220,380)
mkLbl(TPMBar,"🚀 TP Mode",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnTPMClose=mkBtn(TPMBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnTPMClose.ZIndex=12

local TPMScr=Instance.new("ScrollingFrame")
TPMScr.Size=UDim2.new(1,0,1,-28);TPMScr.Position=UDim2.new(0,0,0,28)
TPMScr.BackgroundTransparency=1;TPMScr.BorderSizePixel=0
TPMScr.ScrollBarThickness=3;TPMScr.CanvasSize=UDim2.new(0,0,0,480)
TPMScr.ScrollingDirection=Enum.ScrollingDirection.Y;TPMScr.Parent=TPMPop

local BtnTPM1=mkBtn(TPMScr,"1️⃣ ปกติ",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,4),Color3.fromRGB(25,75,25),Color3.fromRGB(180,255,180),10);BtnTPM1.ZIndex=12
local BtnTPM2=mkBtn(TPMScr,"2️⃣ รัว",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,36),Color3.fromRGB(35,35,55),Color3.fromRGB(155,155,220),10);BtnTPM2.ZIndex=12
local BtnTPM3=mkBtn(TPMScr,"3️⃣ 🦋 วิ้งตาม",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,68),Color3.fromRGB(30,50,80),Color3.fromRGB(150,200,255),10);BtnTPM3.ZIndex=12
mkLbl(TPMScr,"⚡ ความเร็วรัว",UDim2.new(0,95,0,14),UDim2.new(0,8,0,102),9,Color3.fromRGB(120,120,170))
mkLbl(TPMScr,"🏃 ความเร็ววิ้ง",UDim2.new(0,95,0,14),UDim2.new(0,110,0,102),9,Color3.fromRGB(120,170,120))
local InpTPSpd=mkInp(TPMScr,St.tpRapidSpd,UDim2.new(0,95,0,24),UDim2.new(0,8,0,118));InpTPSpd.ZIndex=12
local InpWingSpd=mkInp(TPMScr,Cfg.wingSpd,UDim2.new(0,95,0,24),UDim2.new(0,110,0,118));InpWingSpd.ZIndex=12
mkLbl(TPMScr,"💪 Strength (0-1)",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,148),9,Color3.fromRGB(180,150,255))
local InpStr=mkInp(TPMScr,Cfg.strength,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,162));InpStr.ZIndex=12
mkDiv(TPMScr,192)
-- Orbit
mkLbl(TPMScr,"🌀 หมุนรอบเป้าหมาย",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,198),9,Color3.fromRGB(180,220,255))
local BtnOrbit=mkBtn(TPMScr,"🌀 หมุนรอบ : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,214),Color3.fromRGB(30,40,70),Color3.fromRGB(180,220,255),10);BtnOrbit.ZIndex=12
mkLbl(TPMScr,"⚡ ความเร็วหมุน (°/วิ)",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,246),9,Color3.fromRGB(140,180,255))
local InpOrbitSpd=mkInp(TPMScr,Cfg.orbitSpd,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,262));InpOrbitSpd.ZIndex=12
local BtnOrbitAlt=mkBtn(TPMScr,"🔁 สลับซ้าย/ขวา : OFF",UDim2.new(1,-16,0,24),UDim2.new(0,8,0,290),Color3.fromRGB(30,50,60),Color3.fromRGB(150,230,200),9);BtnOrbitAlt.ZIndex=12
mkLbl(TPMScr,"⏱ ซ้าย (วิ)",UDim2.new(0,95,0,13),UDim2.new(0,8,0,320),9,Color3.fromRGB(140,200,140))
mkLbl(TPMScr,"⏱ ขวา (วิ)",UDim2.new(0,95,0,13),UDim2.new(0,112,0,320),9,Color3.fromRGB(200,140,140))
local InpOrbitL=mkInp(TPMScr,Cfg.orbitL,UDim2.new(0,95,0,22),UDim2.new(0,8,0,336));InpOrbitL.ZIndex=12
local InpOrbitR=mkInp(TPMScr,Cfg.orbitR,UDim2.new(0,95,0,22),UDim2.new(0,112,0,336));InpOrbitR.ZIndex=12

local function UpdateTPMUI()
    BtnTPM1.BackgroundColor3=St.tpModeSelect==1 and Color3.fromRGB(25,100,25) or Color3.fromRGB(25,45,25)
    BtnTPM2.BackgroundColor3=St.tpModeSelect==2 and Color3.fromRGB(60,40,100) or Color3.fromRGB(35,35,55)
    BtnTPM3.BackgroundColor3=St.tpModeSelect==3 and Color3.fromRGB(20,50,100) or Color3.fromRGB(30,50,80)
end;UpdateTPMUI()

-- ══ FLEE FRAME ══
local FleeF=mkFrame(SG,UDim2.new(0,220,0,300),UDim2.new(0.5,-110,0.5,-150),Color3.fromRGB(11,14,11),true)
FleeF.Visible=false
local FleeTB=mkFrame(FleeF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(18,22,18),false,8)
mkAccent(FleeTB,Color3.fromRGB(255,140,50))
local fleeLocked=mkMenuLock(FleeTB,72)
mkDrag(FleeF,FleeTB,fleeLocked)
mkResizeInput(FleeTB,FleeF,220,300)
mkLbl(FleeTB,"🏃 หนีเป้าหมาย",UDim2.new(1,-80,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,220,150),Enum.Font.GothamBold)
local BtnFleeMin=mkBtn(FleeTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnFleeClose=mkBtn(FleeTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local FleeScr=Instance.new("ScrollingFrame")
FleeScr.Size=UDim2.new(1,0,1,-30);FleeScr.Position=UDim2.new(0,0,0,30)
FleeScr.BackgroundTransparency=1;FleeScr.BorderSizePixel=0
FleeScr.ScrollBarThickness=3;FleeScr.CanvasSize=UDim2.new(0,0,0,380)
FleeScr.ScrollingDirection=Enum.ScrollingDirection.Y;FleeScr.Parent=FleeF
local BtnFleeOn=mkBtn(FleeScr,"🏃 หนีเป้าหมาย : OFF",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,6),Color3.fromRGB(24,24,40),Color3.fromRGB(255,200,140),11)
mkLbl(FleeScr,"📏 รัศมีที่หนี (studs)",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,40),9,Color3.fromRGB(200,200,180))
local InpFleeRadius=mkInp(FleeScr,Cfg.fleeRadius,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,54))
mkLbl(FleeScr,"🔧 โหมดหนี",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,84),9,Color3.fromRGB(200,200,180))
local BtnFleeWalk=mkBtn(FleeScr,"🦶 เดินหนี",UDim2.new(0,94,0,26),UDim2.new(0,8,0,98),Color3.fromRGB(40,70,40),Color3.fromRGB(180,255,180),10)
local BtnFleeTP=mkBtn(FleeScr,"⚡ วาปหนี",UDim2.new(0,94,0,26),UDim2.new(0,110,0,98),Color3.fromRGB(24,24,50),Color3.fromRGB(180,180,255),10)
mkLbl(FleeScr,"🏃 ความเร็วเดิน",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,130),9,Color3.fromRGB(200,200,180))
local InpFleeSpd=mkInp(FleeScr,Cfg.fleeSpd,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,144))
mkDiv(FleeScr,174)
mkLbl(FleeScr,"🎨 สีที่ต้องหนี (Scan ก่อน)",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,180),9,Color3.fromRGB(255,190,120))
local FleeCS=Instance.new("ScrollingFrame")
FleeCS.Size=UDim2.new(1,-16,0,80);FleeCS.Position=UDim2.new(0,8,0,196)
FleeCS.BackgroundColor3=Color3.fromRGB(14,14,20);FleeCS.BackgroundTransparency=0
FleeCS.BorderSizePixel=0;FleeCS.ScrollBarThickness=3
FleeCS.CanvasSize=UDim2.new(0,0,0,0);FleeCS.Parent=FleeScr
Instance.new("UICorner",FleeCS).CornerRadius=UDim.new(0,5)
local FleeCL=Instance.new("UIListLayout");FleeCL.Padding=UDim.new(0,3);FleeCL.Parent=FleeCS
local BtnFleeClear=mkBtn(FleeScr,"🗑 ล้างสีที่เลือก",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,282),Color3.fromRGB(60,20,20),Color3.fromRGB(255,150,150),9)
local fleeMin=false
BtnFleeMin.Activated:Connect(function()
    fleeMin=not fleeMin;FleeScr.Visible=not fleeMin
    FleeF.Size=fleeMin and UDim2.new(0,220,0,30) or UDim2.new(0,220,0,300)
end)
BtnFleeClose.Activated:Connect(function() FleeF.Visible=false end)
local function UpdateFleeModeUI()
    BtnFleeWalk.BackgroundColor3=Cfg.fleeMode=="walk" and Color3.fromRGB(20,80,20) or Color3.fromRGB(40,70,40)
    BtnFleeTP.BackgroundColor3=Cfg.fleeMode=="tp" and Color3.fromRGB(50,50,120) or Color3.fromRGB(24,24,50)
end;UpdateFleeModeUI()
BtnFleeWalk.Activated:Connect(function() Cfg.fleeMode="walk";UpdateFleeModeUI() end)
BtnFleeTP.Activated:Connect(function() Cfg.fleeMode="tp";UpdateFleeModeUI() end)

-- ══ CAM FRAME ══
local CamF=mkFrame(SG,UDim2.new(0,190,0,200),UDim2.new(0.5,-340,0.5,-100),Color3.fromRGB(11,11,17),true)
CamF.Visible=false
local CamTB=mkFrame(CamF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8)
mkAccent(CamTB,Color3.fromRGB(245,150,50))
local camLock2=mkMenuLock(CamTB,72)
mkDrag(CamF,CamTB,camLock2)
mkResizeInput(CamTB,CamF,190,200)
mkLbl(CamTB,"📷 Camera",UDim2.new(1,-80,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local CamConOuter=Instance.new("Frame")
CamConOuter.Size=UDim2.new(1,0,1,-30);CamConOuter.Position=UDim2.new(0,0,0,30)
CamConOuter.BackgroundTransparency=1;CamConOuter.ClipsDescendants=true;CamConOuter.Parent=CamF
local CamCon=Instance.new("ScrollingFrame")
CamCon.Size=UDim2.new(1,0,1,0);CamCon.Position=UDim2.new(0,0,0,0)
CamCon.BackgroundTransparency=1;CamCon.BorderSizePixel=0
CamCon.ScrollBarThickness=3;CamCon.CanvasSize=UDim2.new(0,0,0,200)
CamCon.ScrollingDirection=Enum.ScrollingDirection.Y;CamCon.Parent=CamConOuter
local BtnCamMin=mkBtn(CamTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnCamClose=mkBtn(CamTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local BtnCamLock=mkBtn(CamCon,"🔒 Lock Cam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,5),Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
local BtnCamFree=mkBtn(CamCon,"🎥 FreeCam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,40),Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
mkLbl(CamCon,"📏 Distance",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,76),9)
local InpCamDist=mkInp(CamCon,St.camDist,UDim2.new(1,-10,0,26),UDim2.new(0,5,0,89))
mkLbl(CamCon,"⚡ Speed",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,120),9)
local InpCamSpd=mkInp(CamCon,St.camSpd,UDim2.new(1,-10,0,26),UDim2.new(0,5,0,133))
local CtrlPad=mkFrame(SG,UDim2.new(0,160,0,160),UDim2.new(0.75,0,0.6,0),nil,false,0)
CtrlPad.BackgroundTransparency=1;CtrlPad.Visible=false
local function mkPad(txt,pos) return mkBtn(CtrlPad,txt,UDim2.new(0,45,0,45),pos,Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13) end
local function bindPad(b,v)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then St.camMove=St.camMove+v end end)
    b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then St.camMove=St.camMove-v end end)
end
bindPad(mkPad("↑",UDim2.new(0.5,-22,0,0)),Vector3.new(0,0,-1));bindPad(mkPad("↓",UDim2.new(0.5,-22,0,90)),Vector3.new(0,0,1))
bindPad(mkPad("←",UDim2.new(0,0,0.5,-22)),Vector3.new(-1,0,0));bindPad(mkPad("→",UDim2.new(0,90,0.5,-22)),Vector3.new(1,0,0))
bindPad(mkPad("▲",UDim2.new(0,0,0,0)),Vector3.new(0,1,0));bindPad(mkPad("▼",UDim2.new(0,90,0,0)),Vector3.new(0,-1,0))

-- ══ TP FRAME ══
local TF=mkFrame(SG,UDim2.new(0,210,0,260),UDim2.new(0.5,-340,0.5,110),Color3.fromRGB(11,11,17),true)
TF.Visible=false
local TFTB=mkFrame(TF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8)
mkAccent(TFTB,Color3.fromRGB(50,190,110))
local tpLock=mkMenuLock(TFTB,72)
mkDrag(TF,TFTB,tpLock)
mkResizeInput(TFTB,TF,210,260)
mkLbl(TFTB,"🚀 Teleport",UDim2.new(1,-80,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnTFMin=mkBtn(TFTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnTFClose=mkBtn(TFTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local BtnTPSave=mkBtn(TF,"+ Save",UDim2.new(0,60,0,26),UDim2.new(0,5,0,34),Color3.fromRGB(20,68,20),Color3.fromRGB(170,255,170),11)
local BtnTPClic=mkBtn(TF,"Click TP OFF",UDim2.new(0,80,0,26),UDim2.new(0,68,0,34),Color3.fromRGB(130,32,32),Color3.fromRGB(255,170,170),10)
local BtnTPDel=mkBtn(TF,"Delete",UDim2.new(0,55,0,26),UDim2.new(0,152,0,34),Color3.fromRGB(72,24,24),Color3.fromRGB(255,140,140),10)
local TPScr=Instance.new("ScrollingFrame");TPScr.Size=UDim2.new(1,-10,1,-68);TPScr.Position=UDim2.new(0,5,0,64)
TPScr.BackgroundColor3=Color3.fromRGB(13,13,20);TPScr.BorderSizePixel=0
TPScr.ScrollBarThickness=3;TPScr.CanvasSize=UDim2.new(0,0,0,0);TPScr.Parent=TF
Instance.new("UICorner",TPScr).CornerRadius=UDim.new(0,5)
local TPLayout2=Instance.new("UIListLayout",TPScr);TPLayout2.Padding=UDim.new(0,4)

-- ══ SAVE MENU ══
local SaveF=mkFrame(SG,UDim2.new(0,220,0,260),UDim2.new(0.5,-110,0.5,-130),Color3.fromRGB(10,12,20),true)
SaveF.Visible=false;SaveF.ZIndex=20
local SaveTB=mkFrame(SaveF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(16,20,34),false,8);SaveTB.ZIndex=20
local saveLocked=mkMenuLock(SaveTB,46)
mkDrag(SaveF,SaveTB,saveLocked);mkAccent(SaveTB,Color3.fromRGB(255,180,50))
mkResizeInput(SaveTB,SaveF,220,260)
mkLbl(SaveTB,"💾 Save Settings",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),11,Color3.fromRGB(255,220,100),Enum.Font.GothamBold)
local BtnSaveClose=mkBtn(SaveTB,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnSaveClose.ZIndex=20
for i=1,3 do
    local y=32+(i-1)*70
    local lbl=mkLbl(SaveF,"Slot "..i.." : ว่าง",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,y),9,Color3.fromRGB(140,140,180));lbl.ZIndex=20
    local bSave=mkBtn(SaveF,"💾 Save",UDim2.new(0,68,0,24),UDim2.new(0,8,0,y+16),Color3.fromRGB(20,60,20),Color3.fromRGB(170,255,170),10);bSave.ZIndex=20
    local bLoad=mkBtn(SaveF,"▶ Load",UDim2.new(0,68,0,24),UDim2.new(0,80,0,y+16),Color3.fromRGB(20,40,80),Color3.fromRGB(160,200,255),10);bLoad.ZIndex=20
    local bDel=mkBtn(SaveF,"🗑",UDim2.new(0,36,0,24),UDim2.new(0,152,0,y+16),Color3.fromRGB(70,22,22),Color3.fromRGB(255,140,140),10);bDel.ZIndex=20
    local cF=mkFrame(SaveF,UDim2.new(1,-16,0,26),UDim2.new(0,8,0,y+44),Color3.fromRGB(40,14,14),false,5);cF.Visible=false;cF.ZIndex=21
    mkLbl(cF,"ลบ Slot "..i.."?",UDim2.new(0,80,1,0),UDim2.new(0,4,0,0),9,Color3.fromRGB(255,180,180)).ZIndex=21
    local bOk=mkBtn(cF,"OK",UDim2.new(0,36,0,18),UDim2.new(0,88,0,4),Color3.fromRGB(80,20,20),Color3.fromRGB(255,200,200),9);bOk.ZIndex=21
    local bCancel=mkBtn(cF,"ยกเลิก",UDim2.new(0,54,0,18),UDim2.new(0,128,0,4),Color3.fromRGB(30,30,60),Color3.fromRGB(180,180,255),9);bCancel.ZIndex=21
    if Presets[i] then lbl.Text="Slot "..i.." : ✅";lbl.TextColor3=Color3.fromRGB(100,220,120) end
    bDel.Activated:Connect(function() cF.Visible=true end)
    bCancel.Activated:Connect(function() cF.Visible=false end)
    bOk.Activated:Connect(function()
        Presets[i]=nil;cF.Visible=false;SaveCfg()
        lbl.Text="Slot "..i.." : ว่าง";lbl.TextColor3=Color3.fromRGB(140,140,180)
    end)
    bSave.Activated:Connect(function()
        Presets[i]={strength=Cfg.strength,range=Cfg.range,mode=Cfg.mode,nearest=Cfg.nearest,
            aimY=Cfg.aimY,aimX=Cfg.aimX,wingSpd=Cfg.wingSpd,tpRapidSpd=St.tpRapidSpd,
            tpL=TpOff.L,tpR=TpOff.R,tpU=TpOff.U,tpD=TpOff.D,tpF=TpOff.F,tpB=TpOff.B}
        SaveCfg();lbl.Text="Slot "..i.." : ✅";lbl.TextColor3=Color3.fromRGB(100,220,120)
    end)
    bLoad.Activated:Connect(function()
        local p=Presets[i];if not p then return end
        Cfg.strength=p.strength or Cfg.strength;Cfg.range=p.range or Cfg.range
        Cfg.mode=p.mode or Cfg.mode;Cfg.nearest=p.nearest~=nil and p.nearest or Cfg.nearest
        Cfg.aimY=p.aimY or Cfg.aimY;Cfg.aimX=p.aimX or Cfg.aimX;Cfg.wingSpd=p.wingSpd or Cfg.wingSpd
        St.tpRapidSpd=p.tpRapidSpd or St.tpRapidSpd
        TpOff.L=p.tpL or 0;TpOff.R=p.tpR or 0;TpOff.U=p.tpU or 0
        TpOff.D=p.tpD or 0;TpOff.F=p.tpF or 0;TpOff.B=p.tpB or 0
        InpRange.Text=tostring(Cfg.range);InpAimY.Text=tostring(Cfg.aimY);InpAimX.Text=tostring(Cfg.aimX)
        InpWingSpd.Text=tostring(Cfg.wingSpd);InpTPSpd.Text=tostring(St.tpRapidSpd)
        for _,d in ipairs(offDefs) do if offInputs[d.k] then offInputs[d.k].Text=tostring(TpOff[d.k]) end end
        UpdateModeUI()
        BtnNear.Text=Cfg.nearest and "📍 Nearest : ON" or "📍 Nearest : OFF"
        BtnNear.BackgroundColor3=Cfg.nearest and Color3.fromRGB(20,58,20) or Color3.fromRGB(24,24,40)
    end)
end
BtnSaveClose.Activated:Connect(function() SaveF.Visible=false end)
BtnSaveMenu.Activated:Connect(function() SaveF.Visible=not SaveF.Visible end)

-- ══ CORE HELPERS ══
local ROOT_NAMES={"HumanoidRootPart","RootPart","Root","Torso","UpperTorso","Body"}
local function GetRoot(model)
    if not model or not model.Parent then return nil end
    if model.PrimaryPart and model.PrimaryPart.Parent then return model.PrimaryPart end
    for _,n in ipairs(ROOT_NAMES) do
        local p=model:FindFirstChild(n,true)
        if p and p:IsA("BasePart") then return p end
    end
    local biggest,bigSz=nil,0
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local vol=p.Size.X*p.Size.Y*p.Size.Z
            if vol>bigSz then bigSz=vol;biggest=p end
        end
    end
    return biggest
end

-- IsAlive รองรับ AnimationController (non-Humanoid)
local function IsAlive(model)
    if not model or not model.Parent then return false end
    local hum=model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health>0 end
    local anim=model:FindFirstChildOfClass("AnimationController")
    if anim then return true end
    local hv=model:FindFirstChild("Health") or model:FindFirstChild("HP")
    if hv and (hv:IsA("NumberValue") or hv:IsA("IntValue")) then return hv.Value>0 end
    return GetRoot(model)~=nil
end

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
local function GetTargetList()
    local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list={};local range=tonumber(InpRange.Text) or Cfg.range
    if Cfg.mode=="Player" then
        for _,p in ipairs(Svc.Players:GetPlayers()) do
            if p~=LP and p.Character then
                local hrp=GetRoot(p.Character)
                if hrp and IsAlive(p.Character) then
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
                -- รองรับ Humanoid + AnimationController
                local hasHum=obj:FindFirstChildOfClass("Humanoid")~=nil
                local hasAnim=obj:FindFirstChildOfClass("AnimationController")~=nil
                if (hasHum or hasAnim) and IsAlive(obj) then
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
local function IsInVehicle()
    local char=LP.Character;if not char then return false,nil end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then return true,hum.SeatPart end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local as=hrp.AssemblyRootPart
        if as and as~=hrp then return true,as end
    end
    return false,nil
end

-- ══ ESP (Highlight แบบใหม่) ══
local function ClearESP()
    for _,t in pairs(St.espHL) do
        pcall(function() if t.hl then t.hl:Destroy() end end)
        pcall(function() if t.bb then t.bb:Destroy() end end)
    end;St.espHL={}
end
local function UpdateESP()
    local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart");if not myHRP then ClearESP();return end
    local list=GetTargetList();local active={}
    for _,e in ipairs(list) do
        local m=e.model;active[m]=true
        if not St.espHL[m] then
            local hl=Instance.new("Highlight")
            hl.FillColor=Color3.fromRGB(255,255,255);hl.OutlineColor=Color3.fromRGB(255,255,255)
            hl.FillTransparency=0.65;hl.OutlineTransparency=0
            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Adornee=m;hl.Parent=m
            local hrp=GetRoot(m);local bb,dl=nil,nil
            if hrp then
                bb=Instance.new("BillboardGui");bb.Adornee=hrp;bb.AlwaysOnTop=true;bb.LightInfluence=0
                bb.Size=UDim2.new(0,60,0,16);bb.StudsOffset=Vector3.new(0,3,0);bb.Parent=hrp
                dl=Instance.new("TextLabel");dl.Size=UDim2.new(1,0,1,0);dl.BackgroundTransparency=1
                dl.TextColor3=Color3.fromRGB(255,255,255);dl.TextSize=11;dl.Font=Enum.Font.GothamBold;dl.Text="0m";dl.Parent=bb
            end
            St.espHL[m]={hl=hl,bb=bb,dl=dl}
        end
        local hrp=GetRoot(m)
        if St.espHL[m] and St.espHL[m].dl and hrp then
            St.espHL[m].dl.Text=string.format("%.0fm",e.dist)
        end
    end
    for m,t in pairs(St.espHL) do
        if not active[m] then
            pcall(function() if t.hl then t.hl:Destroy() end end)
            pcall(function() if t.bb then t.bb:Destroy() end end)
            St.espHL[m]=nil
        end
    end
end

-- ══ COLOR PICKER / EXCLUDE ══
local function UpdateFleeColorUI()
    for _,c in ipairs(FleeCS:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hs,col in pairs(St.colors) do
        n=n+1;local sel=false
        for _,fh in ipairs(Cfg.fleeColors) do if fh==hs then sel=true;break end end
        local b=mkBtn(FleeCS,(sel and "✓ " or "  ").."#"..hs,UDim2.new(1,0,0,22),UDim2.new(0,0,0,0),sel and Color3.fromRGB(120,50,20) or col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left
        b.Activated:Connect(function()
            local found=false
            for i,fh in ipairs(Cfg.fleeColors) do if fh==hs then table.remove(Cfg.fleeColors,i);found=true;break end end
            if not found then table.insert(Cfg.fleeColors,hs) end;UpdateFleeColorUI()
        end)
    end
    FleeCS.CanvasSize=UDim2.new(0,0,0,FleeCL.AbsoluteContentSize.Y+4)
    if n==0 then mkLbl(FleeCS,"Scan ก่อน",UDim2.new(1,0,0,22),UDim2.new(0,0,0,0),9,Color3.fromRGB(90,90,120)) end
end
BtnFleeClear.Activated:Connect(function() Cfg.fleeColors={};UpdateFleeColorUI() end)

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
    ELbl.Text=#Cfg.exclude>0 and "🚫 "..#Cfg.exclude.." สี" or "🚫 Exclude: ไม่มี"
end

-- ══ SCAN ══
local function DoScan()
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
                    elseif St.tpModeSelect==2 then startRapidTP(hrp)
                    elseif St.tpModeSelect==3 then startWingFollow(hrp) end
                end
            end
        end)
    end
    SScr.CanvasSize=UDim2.new(0,0,0,SLayout.AbsoluteContentSize.Y+4)
    UpdateCPicker();UpdateEPicker();UpdateFleeColorUI()
end

-- ══ TP CORE ══
local function CalcTPOffset(hrp)
    local cf=hrp.CFrame
    return cf.RightVector*(TpOff.R-TpOff.L)+cf.UpVector*(TpOff.U-TpOff.D)+cf.LookVector*(TpOff.F-TpOff.B)
end
local function doTP(hrp)
    local char=LP.Character;if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
    local offset=CalcTPOffset(hrp)
    if offset.Magnitude<0.01 then offset=Vector3.new(0,3,0) end
    local inV,seat=IsInVehicle()
    if inV and seat then
        pcall(function() (seat.AssemblyRootPart or seat).CFrame=CFrame.new(hrp.Position+offset) end)
    else root.CFrame=CFrame.new(hrp.Position+offset) end
end
function stopRapidTP()
    if St.rapidConn then St.rapidConn:Disconnect();St.rapidConn=nil end;St.rapidTgt=nil
end
function startRapidTP(hrp)
    stopRapidTP();St.rapidTgt=hrp
    St.rapidConn=Svc.Run.Heartbeat:Connect(function()
        if not St.tpScan or not St.rapidTgt or not St.rapidTgt.Parent then stopRapidTP();return end
        doTP(St.rapidTgt)
    end)
end

-- ══ NO CLIP ══
local function startNoClip()
    if St.noClipConn then return end
    St.noClipConn=Svc.Run.Stepped:Connect(function()
        local c=LP.Character;if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
    BtnNoClipBtn.Text="🧱 NoClip ON";BtnNoClipBtn.BackgroundColor3=Color3.fromRGB(80,30,110)
end
local function stopNoClip()
    if St.noClipConn then St.noClipConn:Disconnect();St.noClipConn=nil end
    local c=LP.Character;if not c then return end
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end
    BtnNoClipBtn.Text="🧱 NoClip OFF";BtnNoClipBtn.BackgroundColor3=Color3.fromRGB(60,30,80)
end

-- ══ WING FOLLOW ══
local function getWingStopDist()
    local off=Vector3.new(TpOff.R-TpOff.L,TpOff.U-TpOff.D,TpOff.F-TpOff.B)
    return math.max(0,off.Magnitude)
end
local function stopWing()
    if St.wingConn then St.wingConn:Disconnect();St.wingConn=nil end
    St.wingOn=false;St.wingTgt=nil;St.wingLiftY=0;St.wingLiftTarget=0
    local char=LP.Character;if char then
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=false end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored=false;pcall(function() hrp.AssemblyLinearVelocity=Vector3.zero end) end
    end
    if BtnTPM3 then BtnTPM3.BackgroundColor3=Color3.fromRGB(30,50,80) end
end
function startWingFollow(hrp)
    stopWing();stopRapidTP()
    St.wingOn=true;St.wingTgt=hrp
    St.wingLiftY=0;St.wingLiftTarget=0
    BtnTPM3.BackgroundColor3=Color3.fromRGB(20,50,100)
    St.wingConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not St.wingOn or not St.wingTgt or not St.wingTgt.Parent then stopWing();return end
        local tPos=St.wingTgt.Position
        local offset=CalcTPOffset(St.wingTgt)
        if offset.Magnitude<0.01 then offset=Vector3.new(0,3,0) end
        local dest=tPos+offset
        local stopDist=getWingStopDist()
        local spd=Cfg.wingSpd
        local char=LP.Character;if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=true end
        root.Anchored=false
        pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        local cur=root.Position
        local diff=dest-cur
        local dist=diff.Magnitude
        local horizDir=Vector3.new(diff.X,0,diff.Z)
        if not Cfg.noClip and horizDir.Magnitude>0.1 and dist>stopDist+0.05 then
            local hitCanCollide=false
            pcall(function()
                local params=RaycastParams.new()
                params.FilterType=Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances={char}
                local origin=cur+Vector3.new(0,1,0)
                local dir=horizDir.Unit*(math.min(dist,spd*dt)+2)
                local result=workspace:Raycast(origin,dir,params)
                if result and result.Instance and result.Instance:IsA("BasePart") and result.Instance.CanCollide then
                    hitCanCollide=true
                end
            end)
            if hitCanCollide then
                St.wingLiftTarget=math.min(St.wingLiftTarget+spd*dt*3,40)
            else
                St.wingLiftTarget=math.max(0,St.wingLiftTarget-spd*dt*1.5)
            end
        else St.wingLiftTarget=math.max(0,St.wingLiftTarget-spd*dt) end
        St.wingLiftY=St.wingLiftY+(St.wingLiftTarget-St.wingLiftY)*math.min(1,dt*8)
        local liftedDest=dest+Vector3.new(0,St.wingLiftY,0)
        local ld=liftedDest-cur
        local ldist=ld.Magnitude
        if ldist>stopDist+0.05 then
            local step2=math.min(ldist,spd*dt)
            local newPos=cur+ld.Unit*step2
            local fd=Vector3.new(ld.X,0,ld.Z)
            if fd.Magnitude>0.1 then root.CFrame=CFrame.new(newPos,newPos+fd.Unit)
            else root.CFrame=CFrame.new(newPos) end
            pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        else
            root.CFrame=CFrame.new(liftedDest)
            pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        end
    end)
end

-- ══ ORBIT ══
local function stopOrbit()
    if St.orbitConn then St.orbitConn:Disconnect();St.orbitConn=nil end
    Cfg.orbitOn=false
    BtnOrbit.Text="🌀 หมุนรอบ : OFF";BtnOrbit.BackgroundColor3=Color3.fromRGB(30,40,70)
end
local function startOrbit()
    stopOrbit();Cfg.orbitOn=true;St.orbitAngle=0;St.orbitDir=1;St.orbitTimer=0
    BtnOrbit.Text="🌀 หมุนรอบ : ON";BtnOrbit.BackgroundColor3=Color3.fromRGB(20,50,110)
    St.orbitConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not Cfg.orbitOn or not St.target or not St.target.Parent then
            if not St.target then stopOrbit() end;return
        end
        local hrp=GetRoot(St.target);if not hrp then return end
        local c=LP.Character;if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart");if not root then return end
        if Cfg.orbitAlt then
            St.orbitTimer=St.orbitTimer+dt
            local lim=St.orbitDir==1 and Cfg.orbitL or Cfg.orbitR
            if St.orbitTimer>=lim then St.orbitTimer=0;St.orbitDir=-St.orbitDir end
        end
        St.orbitAngle=St.orbitAngle+math.rad(Cfg.orbitSpd*dt)*St.orbitDir
        local radius=math.max(getWingStopDist(),2)
        local ox=hrp.Position.X+math.cos(St.orbitAngle)*radius
        local oz=hrp.Position.Z+math.sin(St.orbitAngle)*radius
        local oy=hrp.Position.Y+(TpOff.U-TpOff.D)
        root.CFrame=CFrame.new(Vector3.new(ox,oy,oz),hrp.Position)
        pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
    end)
end

-- ══ FLEE ══
local function stopFlee()
    if St.fleeConn then St.fleeConn:Disconnect();St.fleeConn=nil end
    Cfg.fleeOn=false
    BtnFleeOn.Text="🏃 หนีเป้าหมาย : OFF";BtnFleeOn.BackgroundColor3=Color3.fromRGB(24,24,40)
    local c=LP.Character;if c then local hum=c:FindFirstChildOfClass("Humanoid");if hum then hum.WalkSpeed=16 end end
end
local function startFlee()
    stopFlee();Cfg.fleeOn=true
    BtnFleeOn.Text="🏃 หนีเป้าหมาย : ON";BtnFleeOn.BackgroundColor3=Color3.fromRGB(80,40,10)
    St.fleeConn=Svc.Run.Heartbeat:Connect(function()
        if not Cfg.fleeOn then return end
        local c=LP.Character;if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart");if not root then return end
        local hum=c:FindFirstChildOfClass("Humanoid");if not hum then return end
        local radius=tonumber(InpFleeRadius.Text) or Cfg.fleeRadius
        local fspd=tonumber(InpFleeSpd.Text) or Cfg.fleeSpd
        local list=GetTargetList();local danger=nil
        for _,e in ipairs(list) do
            if e.dist<=radius then
                if #Cfg.fleeColors==0 then danger=e;break
                else
                    local h=Hex(e.color)
                    for _,fh in ipairs(Cfg.fleeColors) do if fh==h then danger=e;break end end
                    if danger then break end
                end
            end
        end
        if danger then
            local hrp=GetRoot(danger.model);if not hrp then return end
            local away=root.Position-hrp.Position
            if away.Magnitude>0.1 then
                local awD=away.Unit
                if Cfg.fleeMode=="tp" then root.CFrame=CFrame.new(root.Position+awD*(radius+5))
                else hum.WalkSpeed=fspd;hum:MoveTo(root.Position+awD*10) end
            end
        else hum.WalkSpeed=16 end
    end)
end
BtnFleeOn.Activated:Connect(function() if Cfg.fleeOn then stopFlee() else startFlee() end end)
bindTripleClick(BtnFleeOn,"🏃หนีเป้า",function() if Cfg.fleeOn then stopFlee() else startFlee() end end,function() return Cfg.fleeOn end)

-- ══ LOCK CORE ══
local function StartLock()
    if St.lockConn then St.lockConn:Disconnect();St.lockConn=nil end
    local timer=0;CHF.Visible=true
    local function snapCam()
        local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart");if not myHRP or not St.target then return end
        local hrp=GetRoot(St.target);if not hrp then return end
        local head=St.target:FindFirstChild("Head",true)
        local aimPoint=(head and head.Position or hrp.Position)+Vector3.new(0,Cfg.aimY,0)
        local camPos=Cam.CFrame.Position
        if (aimPoint-camPos).Magnitude>0.1 then Cam.CFrame=CFrame.lookAt(camPos,aimPoint) end
        local bl=Vector3.new(Cam.CFrame.LookVector.X,0,Cam.CFrame.LookVector.Z)
        if bl.Magnitude>0.1 then myHRP.CFrame=CFrame.new(myHRP.Position,myHRP.Position+bl.Unit) end
    end
    St.lockConn=Svc.Run.RenderStepped:Connect(function(dt)
        local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart");if not myHRP then return end
        local str=math.clamp(Cfg.strength,0.01,1.0)
        local alpha=str>=0.99 and 1 or (1-(1-str)^(math.min(dt,0.05)*60))
        if St.target then
            if not IsAlive(St.target) or not St.target.Parent then SetTarget(nil);St.rescan=true end
        end
        if not St.target or Cfg.nearest or St.rescan then
            timer=timer+dt
            if St.rescan or timer>=0.1 then
                timer=0;St.rescan=false
                local fil=FilterList(GetTargetList());St.tgList=fil
                if #fil>0 and (Cfg.nearest or not St.target) then SetTarget(fil[1].model);St.tgIdx=1;snapCam() end
            end
        end
        if not St.target then return end
        local hrp=GetRoot(St.target)
        if not hrp or not IsAlive(St.target) then SetTarget(nil);St.rescan=true;return end
        local head=St.target:FindFirstChild("Head",true)
        local camPos=Cam.CFrame.Position
        local aimPoint=(head and head.Position or hrp.Position)+Vector3.new(0,Cfg.aimY,0)+Cam.CFrame.RightVector*Cfg.aimX
        Cam.CFrame=Cam.CFrame:Lerp(CFrame.lookAt(camPos,aimPoint),alpha)
        local inV,seat=IsInVehicle()
        if inV and seat then
            pcall(function()
                local r=seat.AssemblyRootPart or seat
                local fd=Vector3.new(aimPoint.X-r.Position.X,0,aimPoint.Z-r.Position.Z)
                if fd.Magnitude>0.5 then r.CFrame=CFrame.new(r.Position,r.Position+fd.Unit) end
            end)
        else
            local bl=Vector3.new(Cam.CFrame.LookVector.X,0,Cam.CFrame.LookVector.Z)
            if bl.Magnitude>0.1 then myHRP.CFrame=CFrame.new(myHRP.Position,myHRP.Position+bl.Unit) end
        end
        UpdateCH()
        if St.fakePart then St.fakePart.CFrame=CFrame.new(aimPoint);Mouse.TargetFilter=St.fakePart end
        pcall(function() Mouse.Hit=CFrame.new(aimPoint);Mouse.Target=head or hrp end)
    end)
    snapCam()
end
local function StopLock()
    if St.lockConn then St.lockConn:Disconnect();St.lockConn=nil end
    SetTarget(nil);CHF.Visible=false
    if St.fakePart then St.fakePart.CFrame=CFrame.new(0,-10000,0) end
end

-- ══ AUTO SCAN ══
local function startAutoScan()
    if St.autoScanConn then St.autoScanConn:Disconnect();St.autoScanConn=nil end
    St.autoScanOn=true
    BtnAutoScan.Text="🔄 Auto ON";BtnAutoScan.BackgroundColor3=Color3.fromRGB(20,60,20)
    local t=0
    St.autoScanConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not St.autoScanOn then return end;t=t+dt
        if t>=2 then t=0;DoScan() end
    end)
end
local function stopAutoScan()
    St.autoScanOn=false
    if St.autoScanConn then St.autoScanConn:Disconnect();St.autoScanConn=nil end
    BtnAutoScan.Text="🔄 Auto OFF";BtnAutoScan.BackgroundColor3=Color3.fromRGB(24,24,44)
end

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
            for _,c2 in ipairs(TPScr:GetChildren()) do if c2:IsA("TextButton") then c2.BackgroundColor3=Color3.fromRGB(19,19,30) end end
            b.BackgroundColor3=Color3.fromRGB(32,50,84)
        end)
    end
    TPScr.CanvasSize=UDim2.new(0,0,0,#St.tpSaves*30)
end

-- ══ LOOPS ══
Svc.Run.RenderStepped:Connect(function(dt)
    UpdateCH()
    if not Cfg.enabled then
        if St.camLocked and not St.camFree then
            local char=LP.Character;if char then
                local root=char:FindFirstChild("HumanoidRootPart");if root then
                    Cam.CFrame=CFrame.new(root.Position-Cam.CFrame.LookVector*St.camDist,root.Position)
                end
            end
        end
        if St.camFree then
            local rot=CFrame.Angles(0,math.rad(St.camAX),0)*CFrame.Angles(math.rad(St.camAY),0,0)
            local d=rot.LookVector
            St.camFreePos=St.camFreePos+d*St.camMove.Z*St.camSpd*dt*60
                +rot.RightVector*St.camMove.X*St.camSpd*dt*60+Vector3.new(0,1,0)*St.camMove.Y*St.camSpd*dt*60
            Cam.CFrame=CFrame.new(St.camFreePos,St.camFreePos+d)
        end
    end
end)
Svc.Run.Heartbeat:Connect(function(dt)
    if Cfg.esp then St.espT=St.espT+dt;if St.espT>=0.3 then St.espT=0;UpdateESP() end end
    if St.clickTP and St.lockPos then
        local char=LP.Character;if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
        if (root.Position-St.lockPos).Magnitude>10 then root.CFrame=CFrame.new(St.lockPos+Vector3.new(0,3,0)) end
    end
end)
Svc.UIS.InputChanged:Connect(function(input)
    if St.camFree and(input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        St.camAX=St.camAX-input.Delta.X*0.2;St.camAY=math.clamp(St.camAY-input.Delta.Y*0.2,-80,80)
    end
end)
LP.CharacterAdded:Connect(function(c)
    St.char=c;c:WaitForChild("HumanoidRootPart");St.target=nil;ClearESP()
    stopWing();stopOrbit()
    if St.noClipConn then stopNoClip();if Cfg.noClip then task.wait(0.5);startNoClip() end end
    if Cfg.enabled then task.wait(0.5);StartLock() end
end)

-- ══ CONNECTIONS ══
InpRange.FocusLost:Connect(function() local v=tonumber(InpRange.Text);if v then Cfg.range=v;SaveCfg() else InpRange.Text=tostring(Cfg.range) end end)
InpAimY.FocusLost:Connect(function() local v=tonumber(InpAimY.Text);if v then Cfg.aimY=v;SaveCfg() else InpAimY.Text=tostring(Cfg.aimY) end end)
BtnAimYU.Activated:Connect(function() Cfg.aimY=Cfg.aimY+0.5;InpAimY.Text=tostring(Cfg.aimY);SaveCfg() end)
BtnAimYD.Activated:Connect(function() Cfg.aimY=Cfg.aimY-0.5;InpAimY.Text=tostring(Cfg.aimY);SaveCfg() end)
InpAimX.FocusLost:Connect(function() local v=tonumber(InpAimX.Text);if v then Cfg.aimX=v;SaveCfg() else InpAimX.Text=tostring(Cfg.aimX) end end)
BtnAimXL.Activated:Connect(function() Cfg.aimX=Cfg.aimX+1;InpAimX.Text=tostring(Cfg.aimX);SaveCfg() end)
BtnAimXR.Activated:Connect(function() Cfg.aimX=Cfg.aimX-1;InpAimX.Text=tostring(Cfg.aimX);SaveCfg() end)
InpCamDist.FocusLost:Connect(function() local v=tonumber(InpCamDist.Text);if v then St.camDist=v else InpCamDist.Text=tostring(St.camDist) end end)
InpCamSpd.FocusLost:Connect(function() local v=tonumber(InpCamSpd.Text);if v then St.camSpd=v else InpCamSpd.Text=tostring(St.camSpd) end end)
BtnPlayer.Activated:Connect(function() Cfg.mode="Player";St.target=nil;UpdateModeUI();SaveCfg() end)
BtnNPC.Activated:Connect(function() Cfg.mode="NPC";St.target=nil;UpdateModeUI();SaveCfg() end)

BtnLock.Activated:Connect(function()
    Cfg.enabled=not Cfg.enabled
    if Cfg.enabled then BtnLock.Text="🔒 Lock : ON";BtnLock.BackgroundColor3=Color3.fromRGB(20,58,20);StartLock()
    else BtnLock.Text="🔓 Lock : OFF";BtnLock.BackgroundColor3=Color3.fromRGB(24,24,40);StopLock() end
end)
bindTripleClick(BtnLock,"🔒Lock",function()
    Cfg.enabled=not Cfg.enabled
    if Cfg.enabled then BtnLock.Text="🔒 Lock : ON";BtnLock.BackgroundColor3=Color3.fromRGB(20,58,20);StartLock()
    else BtnLock.Text="🔓 Lock : OFF";BtnLock.BackgroundColor3=Color3.fromRGB(24,24,40);StopLock() end
end,function() return Cfg.enabled end)

BtnNear.Activated:Connect(function()
    Cfg.nearest=not Cfg.nearest
    BtnNear.Text=Cfg.nearest and "📍 Nearest : ON" or "📍 Nearest : OFF"
    BtnNear.BackgroundColor3=Cfg.nearest and Color3.fromRGB(20,58,20) or Color3.fromRGB(24,24,40)
    if Cfg.nearest then St.target=nil;St.rescan=true end;SaveCfg()
end)
bindTripleClick(BtnNear,"📍Near",function()
    Cfg.nearest=not Cfg.nearest
    BtnNear.Text=Cfg.nearest and "📍 Nearest : ON" or "📍 Nearest : OFF"
    BtnNear.BackgroundColor3=Cfg.nearest and Color3.fromRGB(20,58,20) or Color3.fromRGB(24,24,40)
    if Cfg.nearest then St.target=nil;St.rescan=true end;SaveCfg()
end,function() return Cfg.nearest end)

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
bindTripleClick(BtnESP,"👁ESP",function()
    Cfg.esp=not Cfg.esp;BtnESP.Text=Cfg.esp and "👁 ESP ON" or "👁 ESP"
    BtnESP.BackgroundColor3=Cfg.esp and Color3.fromRGB(20,50,74) or Color3.fromRGB(24,24,40)
    if not Cfg.esp then ClearESP() end
end,function() return Cfg.esp end)

BtnLockMenu.Activated:Connect(function()
    menuLocked=not menuLocked;BtnLockMenu.Text=menuLocked and "🔒" or "🔓"
    BtnLockMenu.BackgroundColor3=menuLocked and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62)
end)
local minimized=false
BtnMin.Activated:Connect(function()
    minimized=not minimized;ConOuter.Visible=not minimized
    MF.Size=minimized and UDim2.new(0,232,0,32) or UDim2.new(0,232,0,360)
end)
BtnClose.Activated:Connect(function()
    StopLock();ClearESP();stopWing();stopOrbit();stopAutoScan();stopFlee();stopNoClip()
    if St.fakePart then St.fakePart:Destroy();St.fakePart=nil end;SG:Destroy()
end)

local scanVis=false
BtnScan.Activated:Connect(function()
    scanVis=not scanVis;SF.Visible=scanVis
    BtnScan.BackgroundColor3=scanVis and Color3.fromRGB(24,40,74) or Color3.fromRGB(24,24,40)
end)
bindTripleClick(BtnScan,"🔍Scan",function()
    scanVis=not scanVis;SF.Visible=scanVis
    BtnScan.BackgroundColor3=scanVis and Color3.fromRGB(24,40,74) or Color3.fromRGB(24,24,40)
end,function() return scanVis end)

BtnSClose.Activated:Connect(function()
    scanVis=false;SF.Visible=false;CPop.Visible=false;EPop.Visible=false
    TPOffPop.Visible=false;ScanOptsDrop.Visible=false
    BtnScan.BackgroundColor3=Color3.fromRGB(24,24,40)
end)
local sMin=false
BtnSMin.Activated:Connect(function()
    sMin=not sMin;ScanConOuter.Visible=not sMin
    SF.Size=sMin and UDim2.new(0,220,0,30) or UDim2.new(0,220,0,380)
    if sMin then CPop.Visible=false;EPop.Visible=false;TPOffPop.Visible=false;ScanOptsDrop.Visible=false end
end)

BtnDoScan2.Activated:Connect(function() DoScan();ScanOptsDrop.Visible=false end)
BtnAutoScan.Activated:Connect(function()
    if St.autoScanOn then stopAutoScan() else startAutoScan() end
    ScanOptsDrop.Visible=false
end)
bindTripleClick(BtnAutoScan,"🔄Auto",function()
    if St.autoScanOn then stopAutoScan() else startAutoScan() end
end,function() return St.autoScanOn end)

BtnCP2.Activated:Connect(function()
    CPop.Visible=not CPop.Visible;EPop.Visible=false;TPOffPop.Visible=false;ScanOptsDrop.Visible=false
    if CPop.Visible then UpdateCPicker() end
end)
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
    EPop.Visible=not EPop.Visible;CPop.Visible=false;TPOffPop.Visible=false;ScanOptsDrop.Visible=false
    if EPop.Visible then St.pendEx={};for _,h in ipairs(Cfg.exclude) do table.insert(St.pendEx,h) end;UpdateEPicker() end
end)
BtnEPClose.Activated:Connect(function() EPop.Visible=false;St.pendEx={} end)
BtnEPOk.Activated:Connect(function()
    Cfg.exclude={};for _,h in ipairs(St.pendEx) do table.insert(Cfg.exclude,h) end
    UpdateEPicker();EPop.Visible=false;St.pendEx={}
end)
BtnCE.Activated:Connect(function() Cfg.exclude={};St.pendEx={};UpdateEPicker() end)

-- NoClip
BtnNoClipBtn.Activated:Connect(function()
    Cfg.noClip=not Cfg.noClip
    if Cfg.noClip then startNoClip() else stopNoClip() end
    ScanOptsDrop.Visible=false;SaveCfg()
end)
bindTripleClick(BtnNoClipBtn,"🧱NoClip",function()
    Cfg.noClip=not Cfg.noClip
    if Cfg.noClip then startNoClip() else stopNoClip() end;SaveCfg()
end,function() return Cfg.noClip end)

BtnTPScan.Activated:Connect(function()
    St.tpScan=not St.tpScan
    if St.tpScan then BtnTPScan.BackgroundColor3=Color3.fromRGB(20,120,20);TPMPop.Visible=true
    else BtnTPScan.BackgroundColor3=Color3.fromRGB(30,80,30);TPMPop.Visible=false;stopRapidTP();stopWing() end
    ScanOptsDrop.Visible=false
end)
bindTripleClick(BtnTPScan,"🚀TPScan",function()
    St.tpScan=not St.tpScan
    if St.tpScan then BtnTPScan.BackgroundColor3=Color3.fromRGB(20,120,20);TPMPop.Visible=true
    else BtnTPScan.BackgroundColor3=Color3.fromRGB(30,80,30);TPMPop.Visible=false;stopRapidTP();stopWing() end
end,function() return St.tpScan end)

local camVis=false
BtnCamSys.Activated:Connect(function()
    camVis=not camVis;CamF.Visible=camVis
    BtnCamSys.BackgroundColor3=camVis and Color3.fromRGB(74,50,16) or Color3.fromRGB(24,24,40)
end)
bindTripleClick(BtnCamSys,"📷Cam",function()
    camVis=not camVis;CamF.Visible=camVis
    BtnCamSys.BackgroundColor3=camVis and Color3.fromRGB(74,50,16) or Color3.fromRGB(24,24,40)
end,function() return camVis end)
local camMin2=false
BtnCamMin.Activated:Connect(function()
    camMin2=not camMin2;CamConOuter.Visible=not camMin2
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
end)
bindTripleClick(BtnCamLock,"🔒CamLk",function()
    St.camLocked=not St.camLocked
    BtnCamLock.Text=St.camLocked and "🔒 Lock Cam ON" or "🔒 Lock Cam OFF"
    BtnCamLock.BackgroundColor3=St.camLocked and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
end,function() return St.camLocked end)
BtnCamFree.Activated:Connect(function()
    St.camFree=not St.camFree
    BtnCamFree.Text=St.camFree and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    BtnCamFree.BackgroundColor3=St.camFree and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
    CtrlPad.Visible=St.camFree
    if St.camFree then St.camFreePos=Cam.CFrame.Position end
end)
bindTripleClick(BtnCamFree,"🎥Free",function()
    St.camFree=not St.camFree
    BtnCamFree.Text=St.camFree and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    BtnCamFree.BackgroundColor3=St.camFree and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
    CtrlPad.Visible=St.camFree
    if St.camFree then St.camFreePos=Cam.CFrame.Position end
end,function() return St.camFree end)

local tpVis=false
BtnTP.Activated:Connect(function()
    tpVis=not tpVis;TF.Visible=tpVis
    BtnTP.BackgroundColor3=tpVis and Color3.fromRGB(16,50,26) or Color3.fromRGB(24,24,40)
    if tpVis then TPRefresh() end
end)
bindTripleClick(BtnTP,"🚀TP",function()
    tpVis=not tpVis;TF.Visible=tpVis
    BtnTP.BackgroundColor3=tpVis and Color3.fromRGB(16,50,26) or Color3.fromRGB(24,24,40)
    if tpVis then TPRefresh() end
end,function() return tpVis end)
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
    table.insert(St.tpSaves,{x=root.Position.X,y=root.Position.Y,z=root.Position.Z});SaveCfg();TPRefresh()
end)
BtnTPDel.Activated:Connect(function()
    if St.tpSel then table.remove(St.tpSaves,St.tpSel);St.tpSel=nil;SaveCfg();TPRefresh() end
end)
BtnTPClic.Activated:Connect(function()
    St.clickTP=not St.clickTP;if not St.clickTP then St.lockPos=nil end
    BtnTPClic.Text=St.clickTP and "Click TP ON" or "Click TP OFF"
    BtnTPClic.BackgroundColor3=St.clickTP and Color3.fromRGB(20,92,40) or Color3.fromRGB(130,32,32)
end)
bindTripleClick(BtnTPClic,"ClickTP",function()
    St.clickTP=not St.clickTP;if not St.clickTP then St.lockPos=nil end
    BtnTPClic.Text=St.clickTP and "Click TP ON" or "Click TP OFF"
    BtnTPClic.BackgroundColor3=St.clickTP and Color3.fromRGB(20,92,40) or Color3.fromRGB(130,32,32)
end,function() return St.clickTP end)

Mouse.Button1Down:Connect(function()
    if not St.clickTP then return end
    local char=LP.Character;if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
    local hit=Mouse.Hit;if hit then St.lockPos=hit.Position;root.CFrame=CFrame.new(St.lockPos+Vector3.new(0,3,0)) end
end)

-- TP Mode buttons
BtnTPM1.Activated:Connect(function() St.tpModeSelect=1;stopWing();stopOrbit();UpdateTPMUI() end)
BtnTPM2.Activated:Connect(function() St.tpModeSelect=2;stopWing();stopOrbit();UpdateTPMUI() end)
BtnTPM3.Activated:Connect(function()
    St.tpModeSelect=3;stopRapidTP();UpdateTPMUI()
    if St.target then local hrp=GetRoot(St.target);if hrp then startWingFollow(hrp) end end
end)
BtnTPMClose.Activated:Connect(function() TPMPop.Visible=false end)
InpTPSpd.FocusLost:Connect(function()
    local v=tonumber(InpTPSpd.Text);if v and v>0 then St.tpRapidSpd=v;SaveCfg() else InpTPSpd.Text=tostring(St.tpRapidSpd) end
end)
InpWingSpd.FocusLost:Connect(function()
    local v=tonumber(InpWingSpd.Text);if v and v>0 then Cfg.wingSpd=v;SaveCfg() else InpWingSpd.Text=tostring(Cfg.wingSpd) end
end)
InpStr.FocusLost:Connect(function()
    local v=tonumber(InpStr.Text)
    if v then Cfg.strength=math.clamp(v,0,1);SaveCfg() else InpStr.Text=tostring(Cfg.strength) end
end)

-- Orbit buttons
BtnOrbit.Activated:Connect(function() if Cfg.orbitOn then stopOrbit() else startOrbit() end end)
bindTripleClick(BtnOrbit,"🌀หมุนรอบ",function() if Cfg.orbitOn then stopOrbit() else startOrbit() end end,function() return Cfg.orbitOn end)
BtnOrbitAlt.Activated:Connect(function()
    Cfg.orbitAlt=not Cfg.orbitAlt
    BtnOrbitAlt.Text=Cfg.orbitAlt and "🔁 สลับซ้าย/ขวา : ON" or "🔁 สลับซ้าย/ขวา : OFF"
    BtnOrbitAlt.BackgroundColor3=Cfg.orbitAlt and Color3.fromRGB(20,80,60) or Color3.fromRGB(30,50,60);SaveCfg()
end)
bindTripleClick(BtnOrbitAlt,"🔁สลับหมุน",function()
    Cfg.orbitAlt=not Cfg.orbitAlt
    BtnOrbitAlt.Text=Cfg.orbitAlt and "🔁 สลับซ้าย/ขวา : ON" or "🔁 สลับซ้าย/ขวา : OFF"
    BtnOrbitAlt.BackgroundColor3=Cfg.orbitAlt and Color3.fromRGB(20,80,60) or Color3.fromRGB(30,50,60);SaveCfg()
end,function() return Cfg.orbitAlt end)
InpOrbitSpd.FocusLost:Connect(function()
    local v=tonumber(InpOrbitSpd.Text);if v then Cfg.orbitSpd=v;SaveCfg() else InpOrbitSpd.Text=tostring(Cfg.orbitSpd) end
end)
InpOrbitL.FocusLost:Connect(function()
    local v=tonumber(InpOrbitL.Text);if v then Cfg.orbitL=v;SaveCfg() else InpOrbitL.Text=tostring(Cfg.orbitL) end
end)
InpOrbitR.FocusLost:Connect(function()
    local v=tonumber(InpOrbitR.Text);if v then Cfg.orbitR=v;SaveCfg() else InpOrbitR.Text=tostring(Cfg.orbitR) end
end)

-- Flee menu
BtnFleeMenu.Activated:Connect(function() FleeF.Visible=not FleeF.Visible end)
bindTripleClick(BtnFleeMenu,"🏃หนีเมนู",function() FleeF.Visible=not FleeF.Visible end,function() return FleeF.Visible end)

InpFleeRadius.FocusLost:Connect(function()
    local v=tonumber(InpFleeRadius.Text);if v then Cfg.fleeRadius=v;SaveCfg() else InpFleeRadius.Text=tostring(Cfg.fleeRadius) end
end)
InpFleeSpd.FocusLost:Connect(function()
    local v=tonumber(InpFleeSpd.Text);if v then Cfg.fleeSpd=v;SaveCfg() else InpFleeSpd.Text=tostring(Cfg.fleeSpd) end
end)

-- ══ INIT ══
if Cfg.nearest then BtnNear.Text="📍 Nearest : ON";BtnNear.BackgroundColor3=Color3.fromRGB(20,58,20) end
if Cfg.orbitAlt then BtnOrbitAlt.Text="🔁 สลับซ้าย/ขวา : ON";BtnOrbitAlt.BackgroundColor3=Color3.fromRGB(20,80,60) end
TPRefresh()
