-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SpeedMenu v14                                               ║
-- ║  แก้จาก v13:                                                ║
-- ║  [FIX] pcall(readfile,...) crash บาง executor → ใช้ function wrap ║
-- ╚══════════════════════════════════════════════════════════════╝

local Svc={
    Players=game:GetService("Players"),
    Run=game:GetService("RunService"),
    UIS=game:GetService("UserInputService"),
    Http=game:GetService("HttpService"),
}
local LP=Svc.Players.LocalPlayer
local Cam=workspace.CurrentCamera
local Mouse=LP:GetMouse()

-- ══ SAVE ══
local SaveFile="SM12.json"
local function LoadSave()
    local ok,raw=pcall(function() return readfile(SaveFile) end)
    if ok and raw and #raw>2 then
        local ok2,d=pcall(function() return Svc.Http:JSONDecode(raw) end)
        if ok2 and type(d)=="table" then return d end
    end
    local ok3,d3=pcall(function() return _G["SM12"] or {} end)
    return (ok3 and type(d3)=="table") and d3 or {}
end
local function WriteSave(t) _G["SM12"]=t;pcall(function() writefile(SaveFile,Svc.Http:JSONEncode(t)) end) end
local S=LoadSave()

local Cfg={
    strength=S.strength or 1, range=S.range or 200,
    mode=S.mode or "NPC", enabled=false,
    nearest=S.nearest or false, filterColor=nil,
    esp=false, exclude={},
    aimY=S.aimY or 0, aimX=S.aimX or 0,
    wingSpd=S.wingSpd or 20, noClip=false,
    orbitOn=false, orbitSpd=S.orbitSpd or 40,
    orbitAlt=S.orbitAlt or false, orbitL=S.orbitL or 10, orbitR=S.orbitR or 5,
    fleeOn=false, fleeRadius=S.fleeRadius or 15,
    fleeMode=S.fleeMode or "walk", fleeSpd=S.fleeSpd or 30,
    fleeColors={},
}
local TpOff={L=S.tpL or 0,R=S.tpR or 0,U=S.tpU or 0,D=S.tpD or 0,F=S.tpF or 0,B=S.tpB or 0}
local Presets=S.presets or {}

local St={
    char=LP.Character,
    target=nil, tgList={}, tgIdx=1,
    lockConn=nil, colors={}, rescan=false,
    tpScan=false, espHL={}, espT=0,
    tpSaves=S.tpSaves or {}, tpSel=nil,
    clickTP=false, lockPos=nil,
    camLocked=false, camFree=false, camDist=50, camSpd=5,
    camAX=0, camAY=0, camMove=Vector3.new(), camFreePos=Vector3.new(),
    rapidConn=nil, rapidTgt=nil,
    tpModeSelect=1, tpRapidSpd=S.tpRapidSpd or 0.05,
    pendEx={}, fakePart=nil,
    wingOn=false, wingConn=nil, wingTgt=nil,
    wingLiftY=0, wingLiftTarget=0,
    autoScanOn=false, autoScanConn=nil, autoScanInterval=S.asi or 2,
    orbitConn=nil, orbitAngle=0, orbitDir=1, orbitTimer=0,
    fleeConn=nil, noClipConn=nil, terrainTrans=false,
}

local function SaveCfg()
    WriteSave({
        strength=Cfg.strength,range=Cfg.range,mode=Cfg.mode,nearest=Cfg.nearest,
        aimY=Cfg.aimY,aimX=Cfg.aimX,wingSpd=Cfg.wingSpd,
        orbitSpd=Cfg.orbitSpd,orbitAlt=Cfg.orbitAlt,orbitL=Cfg.orbitL,orbitR=Cfg.orbitR,
        fleeRadius=Cfg.fleeRadius,fleeMode=Cfg.fleeMode,fleeSpd=Cfg.fleeSpd,
        tpRapidSpd=St.tpRapidSpd,asi=St.autoScanInterval,
        tpL=TpOff.L,tpR=TpOff.R,tpU=TpOff.U,tpD=TpOff.D,tpF=TpOff.F,tpB=TpOff.B,
        tpSaves=St.tpSaves,presets=Presets,
    })
end

-- ══ CLEANUP ══
pcall(function()
    for _,n in ipairs({"SpeedMenu10","SpeedMenu11","SM11GUI","SM12GUI"}) do
        for _,pg in ipairs({LP:FindFirstChild("PlayerGui"),game:GetService("CoreGui")}) do
            if pg and pg:FindFirstChild(n) then pg[n]:Destroy() end
        end
    end
end)
local SG=Instance.new("ScreenGui")
SG.Name="SM12GUI";SG.ResetOnSpawn=false;SG.DisplayOrder=999
SG.IgnoreGuiInset=true;SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

-- [v13 FIX] ตั้ง char หลัง GUI สร้างแล้ว ไม่ block
if not St.char then St.char=LP.Character end

local fakePart=Instance.new("Part")
fakePart.Name="SMFake";fakePart.Size=Vector3.one*0.1;fakePart.Anchored=true
fakePart.CanCollide=false;fakePart.Transparency=1;fakePart.CastShadow=false
fakePart.Parent=workspace;St.fakePart=fakePart;Mouse.TargetFilter=fakePart

-- ═══════════════════════════════════════════════
--  CORE HELPERS
-- ═══════════════════════════════════════════════
local function Hex(c)
    return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
end

local ROOT_NAMES={"HumanoidRootPart","RootPart","Root","Torso","UpperTorso","Body","Neck"}
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

local function IsAlive(model)
    if not model or not model.Parent then return false end
    local hum=model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health>0 end
    local anim=model:FindFirstChildOfClass("AnimationController")
    if anim then return true end
    local hv=model:FindFirstChild("Health") or model:FindFirstChild("HP") or model:FindFirstChild("health")
    if hv then
        if hv:IsA("NumberValue") or hv:IsA("IntValue") then return hv.Value>0 end
    end
    return GetRoot(model) ~= nil
end

local function IsTargetable(model)
    if model==St.char then return false end
    if Svc.Players:GetPlayerFromCharacter(model) and Cfg.mode~="Player" then return false end
    if Cfg.mode=="Player" and not Svc.Players:GetPlayerFromCharacter(model) then return false end
    local hasHum=model:FindFirstChildOfClass("Humanoid")~=nil
    local hasAnim=model:FindFirstChildOfClass("AnimationController")~=nil
    local hasRoot=GetRoot(model)~=nil
    return (hasHum or hasAnim or hasRoot) and IsAlive(model)
end

local function GetTeamColor(model)
    local p=Svc.Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    local root=GetRoot(model)
    if root then
        local c=root.BrickColor.Color
        if (c.R+c.G+c.B)<2.8 then return c end
    end
    local hash=0
    for i=1,#model.Name do hash=hash+string.byte(model.Name,i) end
    return Color3.new((hash*137)%256/255,(hash*251)%256/255,(hash*337)%256/255)
end

local function IsExcluded(color)
    local h=Hex(color)
    for _,eh in ipairs(Cfg.exclude) do if eh==h then return true end end
    return false
end

local function GetTargetList()
    local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list={};local range=Cfg.range
    if Cfg.mode=="Player" then
        for _,p in ipairs(Svc.Players:GetPlayers()) do
            if p~=LP and p.Character then
                local hrp=GetRoot(p.Character)
                if hrp and IsAlive(p.Character) then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    if dist<=range then
                        local col=GetTeamColor(p.Character)
                        if not IsExcluded(col) then
                            table.insert(list,{model=p.Character,name=p.Name,dist=dist,color=col})
                        end
                    end
                end
            end
        end
    else
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj~=St.char
                and not Svc.Players:GetPlayerFromCharacter(obj) then
                if IsTargetable(obj) then
                    local hrp=GetRoot(obj)
                    if hrp then
                        local dist=(hrp.Position-myHRP.Position).Magnitude
                        if dist<=range then
                            local col=GetTeamColor(obj)
                            if not IsExcluded(col) then
                                table.insert(list,{model=obj,name=obj.Name,dist=dist,color=col})
                            end
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

-- ═══════════════════════════════════════════════
--  UI FACTORY
-- ═══════════════════════════════════════════════
local function mkFrame(par,sz,pos,bg,clip,r)
    local f=Instance.new("Frame")
    f.Size=sz;f.Position=pos
    f.BackgroundColor3=bg or Color3.fromRGB(13,13,19);f.BorderSizePixel=0
    if clip then f.ClipsDescendants=true end;f.Parent=par
    if r~=false then Instance.new("UICorner",f).CornerRadius=UDim.new(0,r or 8) end
    return f
end
local function mkBtn(par,txt,sz,pos,bg,tc,ts)
    local b=Instance.new("TextButton")
    b.Size=sz;b.Position=pos
    b.BackgroundColor3=bg or Color3.fromRGB(28,28,44);b.BorderSizePixel=0
    b.Text=txt;b.TextColor3=tc or Color3.fromRGB(205,205,255)
    b.TextSize=ts or 11;b.Font=Enum.Font.GothamBold
    b.AutoButtonColor=false;b.Parent=par
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    return b
end
local function mkLbl(par,txt,sz,pos,ts,tc,xa)
    local l=Instance.new("TextLabel")
    l.Size=sz;l.Position=pos;l.BackgroundTransparency=1
    l.Text=txt;l.TextColor3=tc or Color3.fromRGB(155,155,205)
    l.TextSize=ts or 10;l.Font=Enum.Font.Gotham
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
local function mkScroll(par,sz,pos,canH)
    local s=Instance.new("ScrollingFrame")
    s.Size=sz;s.Position=pos;s.BackgroundTransparency=1;s.BorderSizePixel=0
    s.ScrollBarThickness=3;s.CanvasSize=UDim2.new(0,0,0,canH or 0)
    s.ScrollingDirection=Enum.ScrollingDirection.Y;s.Parent=par
    return s
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

-- ══ LOCK BTN ══
local function mkMenuLock(tb,offR)
    local locked=false
    local btn=mkBtn(tb,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-(offR or 72),0.5,-11),Color3.fromRGB(40,40,62))
    btn.Activated:Connect(function()
        locked=not locked;btn.Text=locked and "🔒" or "🔓"
        btn.BackgroundColor3=locked and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62)
    end)
    return function() return locked end
end

-- ══ RESIZE ══
local function mkResize(tb,frame,bW,bH)
    local sz=mkBtn(tb,"⊡",UDim2.new(0,22,0,22),UDim2.new(0,4,0.5,-11),Color3.fromRGB(35,35,58),Color3.fromRGB(160,160,220),11)
    local pop=mkFrame(SG,UDim2.new(0,58,0,220),UDim2.new(0,0,0,0),Color3.fromRGB(14,14,24),true,6)
    pop.Visible=false;pop.ZIndex=90
    for n=10,1,-1 do
        local idx=11-n
        local b=mkBtn(pop,tostring(n),UDim2.new(1,0,0,20),UDim2.new(0,0,0,(idx-1)*22),
            n==10 and Color3.fromRGB(50,70,130) or Color3.fromRGB(22,22,36),Color3.fromRGB(200,200,255),10)
        b.ZIndex=91
        b.Activated:Connect(function()
            local sc=n/10
            frame.Size=UDim2.new(0,math.max(80,math.round(bW*sc)),0,math.max(50,math.round(bH*sc)))
            sz.Text=tostring(n);pop.Visible=false
        end)
    end
    sz.Activated:Connect(function()
        pop.Visible=not pop.Visible
        if pop.Visible then local a=sz.AbsolutePosition;pop.Position=UDim2.new(0,a.X,0,a.Y+24) end
    end)
    pop.Parent=SG
end

-- ══ MINI PANEL (triple-click) ══
local function mkMiniPanel(label,actionFn,getStateFn,isToggle)
    local F=mkFrame(SG,UDim2.new(0,92,0,52),UDim2.new(0,0,0,0),Color3.fromRGB(18,18,32),false,7)
    F.ZIndex=200;F.Visible=false
    local Bar=mkFrame(F,UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),Color3.fromRGB(28,28,48),false,7);Bar.ZIndex=201
    local locked=false
    mkDrag(F,Bar,function() return locked end)
    mkLbl(F,label,UDim2.new(1,-18,0,16),UDim2.new(0,2,0,0),7,Color3.fromRGB(200,200,255)).ZIndex=202
    local lk=mkBtn(Bar,"🔓",UDim2.new(0,14,0,14),UDim2.new(1,-15,0.5,-7),Color3.fromRGB(40,40,62),Color3.fromRGB(200,200,220),6);lk.ZIndex=203
    lk.Activated:Connect(function() locked=not locked;lk.Text=locked and "🔒" or "🔓";lk.BackgroundColor3=locked and Color3.fromRGB(100,70,20) or Color3.fromRGB(40,40,62) end)
    local del=mkBtn(F,"✕",UDim2.new(0,14,0,14),UDim2.new(1,-16,0,17),Color3.fromRGB(120,24,24),Color3.fromRGB(255,255,255),7);del.ZIndex=203
    del.Activated:Connect(function() F:Destroy() end)
    local act=mkBtn(F,"●",UDim2.new(1,-6,0,18),UDim2.new(0,3,0,18),Color3.fromRGB(30,30,55),Color3.fromRGB(180,180,255),9);act.ZIndex=203
    local function ref()
        if isToggle then
            local on=getStateFn and getStateFn() or false
            act.Text=on and "ON" or "OFF"
            act.BackgroundColor3=on and Color3.fromRGB(20,70,20) or Color3.fromRGB(70,20,20)
            act.TextColor3=on and Color3.fromRGB(150,255,150) or Color3.fromRGB(255,150,150)
        else act.Text="กด";act.BackgroundColor3=Color3.fromRGB(35,55,120);act.TextColor3=Color3.fromRGB(180,220,255) end
    end
    ref()
    act.Activated:Connect(function()
        if actionFn then actionFn() end;ref()
        if not isToggle then act.BackgroundColor3=Color3.fromRGB(70,110,200);task.delay(0.15,function() act.BackgroundColor3=Color3.fromRGB(35,55,120) end) end
    end)
    return F,ref
end

-- ══ MINI INPUT PANEL ══
local function mkMiniInput(label,applyFn,getValFn)
    local F=mkFrame(SG,UDim2.new(0,112,0,58),UDim2.new(0,0,0,0),Color3.fromRGB(18,18,32),false,7)
    F.ZIndex=200;F.Visible=false
    local Bar=mkFrame(F,UDim2.new(1,0,0,16),UDim2.new(0,0,0,0),Color3.fromRGB(28,28,48),false,7);Bar.ZIndex=201
    local locked=false
    mkDrag(F,Bar,function() return locked end)
    mkLbl(F,label,UDim2.new(1,-18,0,16),UDim2.new(0,2,0,0),7,Color3.fromRGB(200,200,255)).ZIndex=202
    local lk=mkBtn(Bar,"🔓",UDim2.new(0,14,0,14),UDim2.new(1,-15,0.5,-7),Color3.fromRGB(40,40,62),Color3.fromRGB(200,200,220),6);lk.ZIndex=203
    lk.Activated:Connect(function() locked=not locked;lk.Text=locked and "🔒" or "🔓";lk.BackgroundColor3=locked and Color3.fromRGB(100,70,20) or Color3.fromRGB(40,40,62) end)
    local del=mkBtn(F,"✕",UDim2.new(0,14,0,14),UDim2.new(1,-16,0,17),Color3.fromRGB(120,24,24),Color3.fromRGB(255,255,255),7);del.ZIndex=203
    del.Activated:Connect(function() F:Destroy() end)
    local inp=mkInp(F,getValFn and getValFn() or "",UDim2.new(1,-6,0,20),UDim2.new(0,3,0,18));inp.ZIndex=203
    local ok=mkBtn(F,"✓ OK",UDim2.new(1,-6,0,16),UDim2.new(0,3,0,40),Color3.fromRGB(20,70,20),Color3.fromRGB(170,255,170),9);ok.ZIndex=203
    ok.Activated:Connect(function() local v=tonumber(inp.Text);if applyFn and v then applyFn(v) end end)
    return F
end

-- ══ BIND TRIPLE CLICK ══
-- [FIX] รับแค่ 5 args: btn, label, actionFn, getStateFn, isToggle
local function bindTriple(btn,label,actionFn,getStateFn,isToggle)
    local clicks,lastT=0,0
    local ref_=nil;local mF=nil
    btn.Activated:Connect(function()
        local now=tick()
        if now-lastT>0.6 then clicks=0 end;lastT=now;clicks=clicks+1
        if clicks>=3 then
            clicks=0
            if not mF or not mF.Parent then mF,ref_=mkMiniPanel(label,actionFn,getStateFn,isToggle);mF.Parent=SG end
            mF.Visible=not mF.Visible
            if mF.Visible then
                local a=btn.AbsolutePosition;mF.Position=UDim2.new(0,a.X,0,a.Y-58)
                if ref_ then ref_() end
            end
        end
    end)
end

-- ══ BIND TRIPLE INPUT ══
local function bindTripleInp(inp,label,applyFn,getValFn)
    local clicks,lastT=0,0;local mF=nil
    local function tryTap()
        local now=tick()
        if now-lastT>0.6 then clicks=0 end;lastT=now;clicks=clicks+1
        if clicks>=3 then
            clicks=0
            if not mF or not mF.Parent then mF=mkMiniInput(label,applyFn,getValFn);mF.Parent=SG end
            mF.Visible=not mF.Visible
            if mF.Visible then local a=inp.AbsolutePosition;mF.Position=UDim2.new(0,a.X,0,a.Y-64) end
        end
    end
    inp.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then tryTap() end
    end)
end

-- ═══════════════════════════════════════════════
--  CROSSHAIR
-- ═══════════════════════════════════════════════
local CHF=Instance.new("Frame")
CHF.Size=UDim2.new(0,20,0,20);CHF.AnchorPoint=Vector2.new(0.5,0.5)
CHF.BackgroundTransparency=1;CHF.ZIndex=100;CHF.Parent=SG
local function mkCHL(sz,pos)
    local f=Instance.new("Frame",CHF);f.Size=sz;f.Position=pos
    f.BackgroundColor3=Color3.fromRGB(255,80,80);f.BorderSizePixel=0;f.ZIndex=100
end
mkCHL(UDim2.new(0,2,1,0),UDim2.new(0.5,-1,0,0));mkCHL(UDim2.new(1,0,0,2),UDim2.new(0,0,0.5,-1))
local cDot=Instance.new("Frame",CHF);cDot.Size=UDim2.new(0,6,0,6);cDot.Position=UDim2.new(0.5,-3,0.5,-3)
cDot.BackgroundColor3=Color3.fromRGB(255,255,255);cDot.BorderSizePixel=0;cDot.ZIndex=101
Instance.new("UICorner",cDot).CornerRadius=UDim.new(1,0)
CHF.Visible=false
local function UpdateCH() local vp=Cam.ViewportSize;CHF.Position=UDim2.new(0,vp.X/2-Cfg.aimX*4,0,vp.Y/2-Cfg.aimY*4) end

-- ═══════════════════════════════════════════════
--  MAIN FRAME
-- ═══════════════════════════════════════════════
local menuLocked=false
local MF=mkFrame(SG,UDim2.new(0,234,0,360),UDim2.new(0.5,-117,0.5,-180),Color3.fromRGB(11,11,17),true)
local MTB=mkFrame(MF,UDim2.new(1,0,0,32),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);MTB.ClipsDescendants=false;mkAccent(MTB)
mkDrag(MF,MTB,function() return menuLocked end)
mkLbl(MTB,"⚔ SpeedMenu v12",UDim2.new(1,-112,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255))
mkResize(MTB,MF,234,360)
local BtnMLock=mkBtn(MTB,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-72,0.5,-11),Color3.fromRGB(40,40,62))
local BtnMMin=mkBtn(MTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-48,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),14)
local BtnMClose=mkBtn(MTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-24,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local MScr=mkScroll(MF,UDim2.new(1,0,1,-32),UDim2.new(0,0,0,32),400)
local mMin=false
BtnMMin.Activated:Connect(function() mMin=not mMin;MScr.Visible=not mMin;MF.Size=mMin and UDim2.new(0,234,0,32) or UDim2.new(0,234,0,360) end)
BtnMLock.Activated:Connect(function() menuLocked=not menuLocked;BtnMLock.Text=menuLocked and "🔒" or "🔓";BtnMLock.BackgroundColor3=menuLocked and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62) end)

-- Main content
mkLbl(MScr,"🎯 MODE",UDim2.new(0,80,0,13),UDim2.new(0,8,0,6),9)
local BtnPlayer=mkBtn(MScr,"👤 Player",UDim2.new(0,100,0,26),UDim2.new(0,8,0,21),Color3.fromRGB(28,28,46),Color3.fromRGB(148,158,218))
local BtnNPC=mkBtn(MScr,"🤖 NPC",UDim2.new(0,100,0,26),UDim2.new(0,116,0,21),Color3.fromRGB(62,92,205),Color3.fromRGB(255,255,255))
local function UpdateModeUI()
    if Cfg.mode=="Player" then BtnPlayer.BackgroundColor3=Color3.fromRGB(62,92,205);BtnPlayer.TextColor3=Color3.fromRGB(255,255,255);BtnNPC.BackgroundColor3=Color3.fromRGB(28,28,46);BtnNPC.TextColor3=Color3.fromRGB(148,158,218)
    else BtnNPC.BackgroundColor3=Color3.fromRGB(62,92,205);BtnNPC.TextColor3=Color3.fromRGB(255,255,255);BtnPlayer.BackgroundColor3=Color3.fromRGB(28,28,46);BtnPlayer.TextColor3=Color3.fromRGB(148,158,218) end
end;UpdateModeUI()
mkDiv(MScr,53)
mkLbl(MScr,"📏 Range",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,57),9)
local InpRange=mkInp(MScr,Cfg.range,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,70))
mkDiv(MScr,100)
mkLbl(MScr,"⬆ Aim Y",UDim2.new(0,50,0,13),UDim2.new(0,8,0,104),9)
mkLbl(MScr,"↔ Aim X",UDim2.new(0,50,0,13),UDim2.new(0,120,0,104),9)
local InpAimY=mkInp(MScr,Cfg.aimY,UDim2.new(0,80,0,24),UDim2.new(0,8,0,117))
local InpAimX=mkInp(MScr,Cfg.aimX,UDim2.new(0,80,0,24),UDim2.new(0,120,0,117))
local BtnAYU=mkBtn(MScr,"+",UDim2.new(0,20,0,10),UDim2.new(0,90,0,117),Color3.fromRGB(35,55,35),Color3.fromRGB(175,255,175),10)
local BtnAYD=mkBtn(MScr,"–",UDim2.new(0,20,0,10),UDim2.new(0,90,0,131),Color3.fromRGB(55,28,28),Color3.fromRGB(255,175,175),10)
local BtnAXL=mkBtn(MScr,"+",UDim2.new(0,20,0,10),UDim2.new(0,202,0,117),Color3.fromRGB(35,35,65),Color3.fromRGB(175,175,255),10)
local BtnAXR=mkBtn(MScr,"–",UDim2.new(0,20,0,10),UDim2.new(0,202,0,131),Color3.fromRGB(65,28,28),Color3.fromRGB(255,175,175),10)
mkDiv(MScr,147)
local BtnLock=mkBtn(MScr,"🔓 Lock : OFF",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,153),Color3.fromRGB(24,24,40),Color3.fromRGB(175,175,255),12)
local BtnNear=mkBtn(MScr,"📍 Nearest : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,187),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),11)
local BtnPrev=mkBtn(MScr,"◀",UDim2.new(0,38,0,26),UDim2.new(0,8,0,219),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)
local TgtLbl=Instance.new("TextLabel");TgtLbl.Size=UDim2.new(0,122,0,26);TgtLbl.Position=UDim2.new(0,50,0,219)
TgtLbl.BackgroundColor3=Color3.fromRGB(15,15,26);TgtLbl.BorderSizePixel=0;TgtLbl.Text="No Target"
TgtLbl.TextColor3=Color3.fromRGB(130,170,255);TgtLbl.TextSize=10;TgtLbl.Font=Enum.Font.GothamBold
TgtLbl.TextTruncate=Enum.TextTruncate.AtEnd;TgtLbl.Parent=MScr
Instance.new("UICorner",TgtLbl).CornerRadius=UDim.new(0,5)
local BtnNext=mkBtn(MScr,"▶",UDim2.new(0,38,0,26),UDim2.new(0,176,0,219),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)
mkDiv(MScr,251)
local BtnESP=mkBtn(MScr,"👁 ESP",UDim2.new(0,50,0,26),UDim2.new(0,8,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnScan=mkBtn(MScr,"🔍 Scan",UDim2.new(0,50,0,26),UDim2.new(0,62,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnCamSys=mkBtn(MScr,"📷 Cam",UDim2.new(0,50,0,26),UDim2.new(0,116,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnTP=mkBtn(MScr,"🚀 TP",UDim2.new(0,46,0,26),UDim2.new(0,170,0,257),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
mkDiv(MScr,289)
local StatusLbl=mkLbl(MScr,"● Idle",UDim2.new(1,-40,0,20),UDim2.new(0,8,0,294),10,Color3.fromRGB(60,60,90))
local BtnSave=mkBtn(MScr,"💾",UDim2.new(0,26,0,20),UDim2.new(1,-32,0,294),Color3.fromRGB(28,42,28),Color3.fromRGB(170,255,140),10)
mkDiv(MScr,320)
local BtnFleeMenu=mkBtn(MScr,"🏃 หนีเป้าหมาย",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,326),Color3.fromRGB(24,24,40),Color3.fromRGB(255,200,140),10)

local function SetTarget(model)
    St.target=model
    if model then TgtLbl.Text=model.Name;StatusLbl.Text="🔒 "..model.Name;StatusLbl.TextColor3=Color3.fromRGB(90,178,255)
    else TgtLbl.Text="No Target";StatusLbl.Text="● Idle";StatusLbl.TextColor3=Color3.fromRGB(60,60,90) end
end

-- ═══════════════════════════════════════════════
--  SCAN FRAME
-- ═══════════════════════════════════════════════
local SF=mkFrame(SG,UDim2.new(0,220,0,400),UDim2.new(0.5,126,0.5,-200),Color3.fromRGB(11,11,17),true)
SF.Visible=false
local STBF=mkFrame(SF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);mkAccent(STBF)
local scanLockFn=mkMenuLock(STBF,120);mkDrag(SF,STBF,scanLockFn);mkResize(STBF,SF,220,400)
mkLbl(STBF,"🔍 Scan",UDim2.new(1,-160,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255))
local BtnSOpts=mkBtn(STBF,"⚙",UDim2.new(0,24,0,22),UDim2.new(1,-100,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(200,200,255),12)
local BtnSMin=mkBtn(STBF,"–",UDim2.new(0,20,0,20),UDim2.new(1,-46,0.5,-10),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),12)
local BtnSClose=mkBtn(STBF,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-24,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10)
local SDrop=mkFrame(SG,UDim2.new(0,192,0,210),UDim2.new(0,0,0,0),Color3.fromRGB(16,16,28),true,8)
SDrop.Visible=false;SDrop.ZIndex=60
local SDLayout=Instance.new("UIListLayout",SDrop);SDLayout.Padding=UDim.new(0,3)
local function mkSD(t,col,tc)
    local b=mkBtn(SDrop,t,UDim2.new(1,-8,0,30),UDim2.new(0,4,0,0),col or Color3.fromRGB(26,26,42),tc or Color3.fromRGB(200,200,255),10)
    b.ZIndex=61;return b
end
local BtnTPScan=mkSD("🚀 TP Scan",Color3.fromRGB(30,80,30),Color3.fromRGB(180,255,180))
local BtnAutoScanBtn=mkSD("🔄 Auto Scan OFF",Color3.fromRGB(24,24,44),Color3.fromRGB(140,140,210))
local BtnTPOffBtn=mkSD("📐 TP Offset",Color3.fromRGB(30,50,80),Color3.fromRGB(170,200,255))
local BtnCPBtn=mkSD("🎨 Filter Color",Color3.fromRGB(48,48,160))
local BtnExcBtn=mkSD("🚫 Exclude Color",Color3.fromRGB(100,30,30),Color3.fromRGB(255,170,170))
local BtnDoScanBtn=mkSD("🔍 Scan Now",Color3.fromRGB(32,32,66),Color3.fromRGB(180,180,255))
BtnSOpts.Activated:Connect(function()
    SDrop.Visible=not SDrop.Visible
    if SDrop.Visible then local a=BtnSOpts.AbsolutePosition;SDrop.Position=UDim2.new(0,a.X-4,0,a.Y+26) end
end)
local ScanScr=mkScroll(SF,UDim2.new(1,0,1,-30),UDim2.new(0,0,0,30),500)
local sSMin=false
BtnSMin.Activated:Connect(function()
    sSMin=not sSMin;ScanScr.Visible=not sSMin
    SF.Size=sSMin and UDim2.new(0,220,0,30) or UDim2.new(0,220,0,400)
    if sSMin then SDrop.Visible=false end
end)
BtnSClose.Activated:Connect(function() SF.Visible=false;SDrop.Visible=false end)
local FBar=mkFrame(ScanScr,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,4),Color3.fromRGB(16,16,26),false,5)
local FLbl=mkLbl(FBar,"🎨 Filter: ทั้งหมด",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(120,120,170))
local BtnCF=mkBtn(FBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)
local EBar=mkFrame(ScanScr,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,28),Color3.fromRGB(20,10,10),false,5)
local ELbl=mkLbl(EBar,"🚫 Exclude: ไม่มี",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(170,105,105))
local BtnCE=mkBtn(EBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)
local ScanCntLbl=mkLbl(ScanScr,"0 found",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,52),9,Color3.fromRGB(70,70,110))
local SScr=mkScroll(ScanScr,UDim2.new(1,-8,1,-70),UDim2.new(0,4,0,68),0)
local SLayout=Instance.new("UIListLayout");SLayout.Padding=UDim.new(0,3);SLayout.Parent=SScr

-- ═══════════════════════════════════════════════
--  TP OFFSET
-- ═══════════════════════════════════════════════
local TPOffPop=mkFrame(SG,UDim2.new(0,210,0,240),UDim2.new(0.5,126,0.5,185),Color3.fromRGB(10,14,22),true)
TPOffPop.Visible=false;TPOffPop.ZIndex=14
local TPOBar=mkFrame(TPOffPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,24,36),false,8);TPOBar.ZIndex=14
local tpoLockFn=mkMenuLock(TPOBar,46);mkDrag(TPOffPop,TPOBar,tpoLockFn);mkAccent(TPOBar,Color3.fromRGB(80,160,255))
mkResize(TPOBar,TPOffPop,210,240)
mkLbl(TPOBar,"📐 TP Offset",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(200,220,255))
local BtnTPOClose=mkBtn(TPOBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnTPOClose.ZIndex=14
local TPOScr=mkScroll(TPOffPop,UDim2.new(1,0,1,-28),UDim2.new(0,0,0,28),300)
mkLbl(TPOScr,"U=ลอยขึ้น | D=ดำดินก่อนวิ้ง",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,4),8,Color3.fromRGB(100,130,180))
local offDefs={{k="L",label="◀ ซ้าย",col=0},{k="R",label="▶ ขวา",col=1},
    {k="U",label="▲ บน (ลอย)",col=0},{k="D",label="▼ ล่าง (ดำดิน)",col=1},
    {k="F",label="▶ หน้า",col=0},{k="B",label="◀ หลัง",col=1}}
local offInputs={}
for i,d in ipairs(offDefs) do
    local row=math.floor((i-1)/2);local x=d.col==0 and 8 or 112;local y=22+row*46
    mkLbl(TPOScr,d.label,UDim2.new(0,90,0,14),UDim2.new(0,x,0,y),9,Color3.fromRGB(160,190,240))
    local inp=mkInp(TPOScr,TpOff[d.k],UDim2.new(0,90,0,24),UDim2.new(0,x,0,y+16));inp.ZIndex=14
    offInputs[d.k]=inp
    local dk=d.k
    bindTripleInp(inp,d.label,function(v) TpOff[dk]=v;SaveCfg() end,function() return TpOff[dk] end)
    inp.FocusLost:Connect(function() local v=tonumber(inp.Text);if v then TpOff[dk]=v;SaveCfg() else inp.Text=tostring(TpOff[dk]) end end)
end
local BtnTPOReset=mkBtn(TPOScr,"↺ Reset",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,162),Color3.fromRGB(40,30,60),Color3.fromRGB(190,170,255),9);BtnTPOReset.ZIndex=14
BtnTPOReset.Activated:Connect(function() for _,d in ipairs(offDefs) do TpOff[d.k]=0;offInputs[d.k].Text="0" end;SaveCfg() end)
BtnTPOClose.Activated:Connect(function() TPOffPop.Visible=false end)
BtnTPOffBtn.Activated:Connect(function() TPOffPop.Visible=not TPOffPop.Visible;SDrop.Visible=false end)

-- ═══════════════════════════════════════════════
--  COLOR PICKER
-- ═══════════════════════════════════════════════
local CPop=mkFrame(SG,UDim2.new(0,200,0,240),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,12,18),true)
CPop.Visible=false;CPop.ZIndex=10
local CPBar=mkFrame(CPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);CPBar.ZIndex=10
local cpLockFn=mkMenuLock(CPBar,46);mkDrag(CPop,CPBar,cpLockFn);mkResize(CPBar,CPop,200,240)
mkLbl(CPBar,"🎨 Filter Color",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255))
local BtnCPClose=mkBtn(CPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnCPClose.ZIndex=10
local BtnCPAll=mkBtn(CPop,"✅ ทั้งหมด",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,30),Color3.fromRGB(26,46,26),Color3.fromRGB(170,255,170),9);BtnCPAll.ZIndex=10
local CPScr=mkScroll(CPop,UDim2.new(1,-8,1,-56),UDim2.new(0,4,0,56),0)
local CPLayout=Instance.new("UIListLayout");CPLayout.Padding=UDim.new(0,3);CPLayout.Parent=CPScr
BtnCPClose.Activated:Connect(function() CPop.Visible=false end)

-- ═══════════════════════════════════════════════
--  EXCLUDE
-- ═══════════════════════════════════════════════
local EPop=mkFrame(SG,UDim2.new(0,200,0,260),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(16,8,8),true)
EPop.Visible=false;EPop.ZIndex=10
local EPBar=mkFrame(EPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(25,12,12),false,8);EPBar.ZIndex=10
local epLockFn=mkMenuLock(EPBar,46);mkDrag(EPop,EPBar,epLockFn);mkResize(EPBar,EPop,200,260)
mkLbl(EPBar,"🚫 Exclude Color",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,190,190))
local BtnEPClose=mkBtn(EPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnEPClose.ZIndex=10
mkLbl(EPop,"กดสีที่ไม่ต้องการล็อค",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,30),9,Color3.fromRGB(190,148,148))
local BtnEPOk=mkBtn(EPop,"✅ OK",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,46),Color3.fromRGB(26,50,26),Color3.fromRGB(170,255,170),9);BtnEPOk.ZIndex=10
local EPScr=mkScroll(EPop,UDim2.new(1,-8,1,-74),UDim2.new(0,4,0,72),0)
local EPLayout=Instance.new("UIListLayout");EPLayout.Padding=UDim.new(0,3);EPLayout.Parent=EPScr
BtnEPClose.Activated:Connect(function() EPop.Visible=false;St.pendEx={} end)

-- ═══════════════════════════════════════════════
--  TP MODE POPUP
-- ═══════════════════════════════════════════════
local TPMPop=mkFrame(SG,UDim2.new(0,220,0,380),UDim2.new(0.5,126,0.5,175),Color3.fromRGB(12,15,22),true)
TPMPop.Visible=false;TPMPop.ZIndex=12
local TPMBar=mkFrame(TPMPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,22,35),false,8);TPMBar.ZIndex=12
local tpmLockFn=mkMenuLock(TPMBar,46);mkDrag(TPMPop,TPMBar,tpmLockFn);mkAccent(TPMBar,Color3.fromRGB(50,200,120))
mkResize(TPMBar,TPMPop,220,380)
mkLbl(TPMBar,"🚀 TP Mode",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255))
local BtnTPMClose=mkBtn(TPMBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnTPMClose.ZIndex=12
local TPMScr=mkScroll(TPMPop,UDim2.new(1,0,1,-28),UDim2.new(0,0,0,28),480)
local BtnTPM1=mkBtn(TPMScr,"1️⃣ ปกติ",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,4),Color3.fromRGB(25,75,25),Color3.fromRGB(180,255,180),10);BtnTPM1.ZIndex=12
local BtnTPM2=mkBtn(TPMScr,"2️⃣ รัว",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,36),Color3.fromRGB(35,35,55),Color3.fromRGB(155,155,220),10);BtnTPM2.ZIndex=12
local BtnTPM3=mkBtn(TPMScr,"3️⃣ 🦋 วิ้งตาม",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,68),Color3.fromRGB(30,50,80),Color3.fromRGB(150,200,255),10);BtnTPM3.ZIndex=12
mkLbl(TPMScr,"⚡ TP Speed",UDim2.new(0,95,0,14),UDim2.new(0,8,0,102),9,Color3.fromRGB(120,120,170))
mkLbl(TPMScr,"🏃 Wing Speed",UDim2.new(0,95,0,14),UDim2.new(0,112,0,102),9,Color3.fromRGB(120,170,120))
local InpTPSpd=mkInp(TPMScr,St.tpRapidSpd,UDim2.new(0,95,0,24),UDim2.new(0,8,0,118));InpTPSpd.ZIndex=12
local InpWingSpd=mkInp(TPMScr,Cfg.wingSpd,UDim2.new(0,95,0,24),UDim2.new(0,112,0,118));InpWingSpd.ZIndex=12
mkLbl(TPMScr,"💪 Strength (0-1)",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,148),9,Color3.fromRGB(180,150,255))
local InpStr=mkInp(TPMScr,Cfg.strength,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,162));InpStr.ZIndex=12
mkDiv(TPMScr,192)
local BtnNoClip=mkBtn(TPMScr,"🧱 ทะลุกำแพง : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,198),Color3.fromRGB(60,30,80),Color3.fromRGB(210,170,255),10);BtnNoClip.ZIndex=12
mkDiv(TPMScr,230)
mkLbl(TPMScr,"🌀 หมุนรอบเป้าหมาย",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,236),9,Color3.fromRGB(180,220,255))
local BtnOrbit=mkBtn(TPMScr,"🌀 หมุนรอบ : OFF",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,252),Color3.fromRGB(30,40,70),Color3.fromRGB(180,220,255),10);BtnOrbit.ZIndex=12
mkLbl(TPMScr,"⚡ ความเร็วหมุน (°/วิ)",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,284),9,Color3.fromRGB(140,180,255))
local InpOrbitSpd=mkInp(TPMScr,Cfg.orbitSpd,UDim2.new(1,-16,0,22),UDim2.new(0,8,0,298));InpOrbitSpd.ZIndex=12
local BtnOrbitAlt=mkBtn(TPMScr,"🔁 สลับซ้าย/ขวา : OFF",UDim2.new(1,-16,0,24),UDim2.new(0,8,0,326),Color3.fromRGB(30,50,60),Color3.fromRGB(150,230,200),9);BtnOrbitAlt.ZIndex=12
mkLbl(TPMScr,"⏱ ซ้าย (วิ)",UDim2.new(0,95,0,13),UDim2.new(0,8,0,356),9,Color3.fromRGB(140,200,140))
mkLbl(TPMScr,"⏱ ขวา (วิ)",UDim2.new(0,95,0,13),UDim2.new(0,112,0,356),9,Color3.fromRGB(200,140,140))
local InpOrbitL=mkInp(TPMScr,Cfg.orbitL,UDim2.new(0,95,0,22),UDim2.new(0,8,0,370));InpOrbitL.ZIndex=12
local InpOrbitR=mkInp(TPMScr,Cfg.orbitR,UDim2.new(0,95,0,22),UDim2.new(0,112,0,370));InpOrbitR.ZIndex=12
local function UpdateTPMUI()
    BtnTPM1.BackgroundColor3=St.tpModeSelect==1 and Color3.fromRGB(25,100,25) or Color3.fromRGB(25,45,25)
    BtnTPM2.BackgroundColor3=St.tpModeSelect==2 and Color3.fromRGB(60,40,100) or Color3.fromRGB(35,35,55)
    BtnTPM3.BackgroundColor3=St.tpModeSelect==3 and Color3.fromRGB(20,50,100) or Color3.fromRGB(30,50,80)
end;UpdateTPMUI()

-- ═══════════════════════════════════════════════
--  CAM FRAME
-- ═══════════════════════════════════════════════
local CamF=mkFrame(SG,UDim2.new(0,200,0,210),UDim2.new(0.5,-340,0.5,-105),Color3.fromRGB(11,11,17),true)
CamF.Visible=false
local CamTB=mkFrame(CamF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);mkAccent(CamTB,Color3.fromRGB(245,150,50))
local camLockFn=mkMenuLock(CamTB,72);mkDrag(CamF,CamTB,camLockFn);mkResize(CamTB,CamF,200,210)
mkLbl(CamTB,"📷 Camera",UDim2.new(1,-80,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255))
local BtnCamMin=mkBtn(CamTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnCamClose=mkBtn(CamTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local CamScr=mkScroll(CamF,UDim2.new(1,0,1,-30),UDim2.new(0,0,0,30),230)
local BtnCamLock=mkBtn(CamScr,"🔒 Lock Cam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,5),Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
local BtnCamFree=mkBtn(CamScr,"🎥 FreeCam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,40),Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
mkLbl(CamScr,"📏 Distance",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,76),9);local InpCamDist=mkInp(CamScr,St.camDist,UDim2.new(1,-10,0,26),UDim2.new(0,5,0,89))
mkLbl(CamScr,"⚡ Speed",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,120),9);local InpCamSpd=mkInp(CamScr,St.camSpd,UDim2.new(1,-10,0,26),UDim2.new(0,5,0,133))
local camMin2=false
BtnCamMin.Activated:Connect(function() camMin2=not camMin2;CamScr.Visible=not camMin2;CamF.Size=camMin2 and UDim2.new(0,200,0,30) or UDim2.new(0,200,0,210) end)
BtnCamClose.Activated:Connect(function() CamF.Visible=false end)
local CtrlPad=mkFrame(SG,UDim2.new(0,160,0,160),UDim2.new(0.75,0,0.6,0),nil,false,0)
CtrlPad.BackgroundTransparency=1;CtrlPad.Visible=false
local function mkPad(t,pos) return mkBtn(CtrlPad,t,UDim2.new(0,45,0,45),pos,Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13) end
local function bindPad(b,v)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then St.camMove=St.camMove+v end end)
    b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then St.camMove=St.camMove-v end end)
end
bindPad(mkPad("↑",UDim2.new(0.5,-22,0,0)),Vector3.new(0,0,-1));bindPad(mkPad("↓",UDim2.new(0.5,-22,0,90)),Vector3.new(0,0,1))
bindPad(mkPad("←",UDim2.new(0,0,0.5,-22)),Vector3.new(-1,0,0));bindPad(mkPad("→",UDim2.new(0,90,0.5,-22)),Vector3.new(1,0,0))
bindPad(mkPad("▲",UDim2.new(0,0,0,0)),Vector3.new(0,1,0));bindPad(mkPad("▼",UDim2.new(0,90,0,0)),Vector3.new(0,-1,0))

-- ═══════════════════════════════════════════════
--  TP FRAME
-- ═══════════════════════════════════════════════
local TF=mkFrame(SG,UDim2.new(0,210,0,270),UDim2.new(0.5,-340,0.5,110),Color3.fromRGB(11,11,17),true)
TF.Visible=false
local TFTB=mkFrame(TF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);mkAccent(TFTB,Color3.fromRGB(50,190,110))
local tpLockFn=mkMenuLock(TFTB,72);mkDrag(TF,TFTB,tpLockFn);mkResize(TFTB,TF,210,270)
mkLbl(TFTB,"🚀 Teleport",UDim2.new(1,-80,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255))
local BtnTFMin=mkBtn(TFTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnTFClose=mkBtn(TFTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local TPHdr=mkFrame(TF,UDim2.new(1,0,0,34),UDim2.new(0,0,0,30),Color3.fromRGB(11,11,17),false,false)
local BtnTPSave=mkBtn(TPHdr,"+ Save",UDim2.new(0,60,0,26),UDim2.new(0,5,0,4),Color3.fromRGB(20,68,20),Color3.fromRGB(170,255,170),11)
local BtnTPClic=mkBtn(TPHdr,"ClickTP OFF",UDim2.new(0,80,0,26),UDim2.new(0,68,0,4),Color3.fromRGB(130,32,32),Color3.fromRGB(255,170,170),10)
local BtnTPDel=mkBtn(TPHdr,"Del",UDim2.new(0,48,0,26),UDim2.new(0,152,0,4),Color3.fromRGB(72,24,24),Color3.fromRGB(255,140,140),10)
local TPScr=mkScroll(TF,UDim2.new(1,-6,1,-68),UDim2.new(0,3,0,66),0)
Instance.new("UICorner",TPScr).CornerRadius=UDim.new(0,5)
local TPLayout2=Instance.new("UIListLayout",TPScr);TPLayout2.Padding=UDim.new(0,4)
local tpMin=false
BtnTFMin.Activated:Connect(function() tpMin=not tpMin;TPScr.Visible=not tpMin;TPHdr.Visible=not tpMin;TF.Size=tpMin and UDim2.new(0,210,0,30) or UDim2.new(0,210,0,270) end)
BtnTFClose.Activated:Connect(function() TF.Visible=false end)

