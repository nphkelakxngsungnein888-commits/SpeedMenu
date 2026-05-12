-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SpeedMenu v11                                               ║
-- ║  + ทุกเมนู scroll/drag/lock/resize ครบ                     ║
-- ║  + Triple-click ทุกปุ่ม/input → mini panel                 ║
-- ║  + Scan รองรับ Humanoid + AnimationController (CoS etc.)   ║
-- ║  + GetRoot หา RootPart ทุกรูปแบบ                           ║
-- ║  + IsAlive เช็คทั้ง Humanoid.Health + custom health         ║
-- ║  + Wing U=ลอย D=ดำดิน terrain โปร่ง                        ║
-- ║  + Auto Scan ใส่ความเร็วก่อน OK                            ║
-- ║  + ESP Highlight คลุมบอดี้จริง                              ║
-- ║  + หมุนรอบ 2 ช่องเวลา สลับซ้าย/ขวา                        ║
-- ║  + ทะลุกำแพง ON/OFF                                         ║
-- ║  + หนีเป้าหมาย เดิน/TP เลือกสีหนี                         ║
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

-- ══ FORWARD DECLARATIONS ══
local DoScan,stopRapidTP,startRapidTP,startWingFollow,stopWing
local startOrbit,stopOrbit,startFlee,stopFlee
local startAutoScan,stopAutoScan,startNoClip,stopNoClip
local UpdateESP,ClearESP,TPRefresh,UpdateFleeModeUI
local UpdateCPicker,UpdateEPicker,UpdateFleeColorUI,SetTarget
local GetRoot,IsAlive,IsTargetable,GetTargetList,FilterList
local CalcTPOffset,doTP

-- ══ DEBUG STEP (ลบออกหลัง debug) ══
local _step=0
local function _chk(n)
    _step=n
end

-- ══ SAVE ══
local SaveFile="SM11.json"
local function LoadSave()
    -- ลอง _G ก่อน (ไม่ต้องใช้ readfile)
    if type(_G["SM11"])=="table" then return _G["SM11"] end
    -- ลอง readfile ถ้ามี
    local ok,raw=pcall(function()
        if not (isfolder and isfile) then return nil end
        if not isfile(SaveFile) then return nil end
        return readfile(SaveFile)
    end)
    if ok and raw and type(raw)=="string" and #raw>2 then
        local ok2,d=pcall(function() return Svc.Http:JSONDecode(raw) end)
        if ok2 and type(d)=="table" then return d end
    end
    return {}
end
local function WriteSave(t)
    _G["SM11"]=t
    pcall(function()
        if writefile then writefile(SaveFile,Svc.Http:JSONEncode(t)) end
    end)
end
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
    char=LP.Character or LP.CharacterAdded:Wait(),
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
    for _,n in ipairs({"SpeedMenu10","SpeedMenu11","SM11GUI"}) do
        for _,pg in ipairs({LP:FindFirstChild("PlayerGui"),game:GetService("CoreGui")}) do
            if pg and pg:FindFirstChild(n) then pg[n]:Destroy() end
        end
    end
end)
local SG=Instance.new("ScreenGui")
_chk(1) -- SG created
SG.Name="SM11GUI";SG.ResetOnSpawn=false;SG.DisplayOrder=999
SG.IgnoreGuiInset=true;SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

local fakePart=Instance.new("Part")
fakePart.Name="SMFake";fakePart.Size=Vector3.new(0.1,0.1,0.1);fakePart.Anchored=true
fakePart.CanCollide=false;fakePart.Transparency=1;fakePart.CastShadow=false
fakePart.Parent=workspace;St.fakePart=fakePart;Mouse.TargetFilter=fakePart

-- ═══════════════════════════════════════════════
--  CORE HELPERS — รองรับ non-Humanoid
-- ═══════════════════════════════════════════════
local function Hex(c)
    return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
end

-- หา root part ทุกรูปแบบ
local ROOT_NAMES={"HumanoidRootPart","RootPart","Root","Torso","UpperTorso","Body","Neck"}
function GetRoot(model)
    if not model or not model.Parent then return nil end
    -- ลอง PrimaryPart ก่อน
    if model.PrimaryPart and model.PrimaryPart.Parent then return model.PrimaryPart end
    -- ลองชื่อ standard
    for _,n in ipairs(ROOT_NAMES) do
        local p=model:FindFirstChild(n,true)
        if p and p:IsA("BasePart") then return p end
    end
    -- fallback: BasePart ตัวใหญ่สุด
    local biggest,bigSz=nil,0
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local vol=p.Size.X*p.Size.Y*p.Size.Z
            if vol>bigSz then bigSz=vol;biggest=p end
        end
    end
    return biggest
end

-- เช็ค alive รองรับทั้ง Humanoid และ non-Humanoid
function IsAlive(model)
    if not model or not model.Parent then return false end
    -- Humanoid
    local hum=model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health>0 end
    -- AnimationController (CoS style) — ถ้ามีก็ถือว่า alive (ยังอยู่ใน workspace)
    local anim=model:FindFirstChildOfClass("AnimationController")
    if anim then return true end
    -- ลองหา health value
    local hv=model:FindFirstChild("Health") or model:FindFirstChild("HP") or model:FindFirstChild("health")
    if hv then
        if hv:IsA("NumberValue") or hv:IsA("IntValue") then return hv.Value>0 end
        if hv:IsA("Configuration") then
            local cur=hv:FindFirstChild("Current") or hv:FindFirstChild("Value")
            if cur and (cur:IsA("NumberValue") or cur:IsA("IntValue")) then return cur.Value>0 end
        end
    end
    -- ถ้าไม่มี health ระบบเลย → ถือว่า alive ถ้ายังอยู่ใน workspace
    return GetRoot(model) ~= nil
end

-- ตรวจว่า model เป็น target ได้ (มี rig หรือ controller)
function IsTargetable(model)
    if model==St.char then return false end
    if Svc.Players:GetPlayerFromCharacter(model) and Cfg.mode~="Player" then return false end
    if Cfg.mode=="Player" and not Svc.Players:GetPlayerFromCharacter(model) then return false end
    -- ต้องมี Humanoid หรือ AnimationController หรือ root part
    local hasHum=model:FindFirstChildOfClass("Humanoid")~=nil
    local hasAnim=model:FindFirstChildOfClass("AnimationController")~=nil
    local hasRoot=GetRoot(model)~=nil
    return (hasHum or hasAnim or hasRoot) and IsAlive(model)
end

local function GetTeamColor(model)
    local p=Svc.Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    -- สำหรับ NPC: ใช้สีของ root part หรือ random จาก name hash
    local root=GetRoot(model)
    if root then
        -- ถ้า part มีสีที่ไม่ใช่ขาว/เทา ใช้สีนั้น
        local c=root.BrickColor.Color
        if (c.R+c.G+c.B)<2.8 then return c end
    end
    -- hash จากชื่อ → สีคงที่ต่อ model
    local hash=0
    for i=1,#model.Name do hash=hash+string.byte(model.Name,i) end
    local r=(hash*137)%256/255
    local g=(hash*251)%256/255
    local b=(hash*337)%256/255
    return Color3.new(r,g,b)
end

local function IsExcluded(color)
    local h=Hex(color)
    for _,eh in ipairs(Cfg.exclude) do if eh==h then return true end end
    return false
end

function GetTargetList()
    local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list={}
    local range=Cfg.range
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
        -- NPC mode: scan workspace ทั้งหมด
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

function FilterList(list)
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

-- ══ BIND TRIPLE CLICK (btn) ══
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
_chk(2) -- MF created
local MTB=mkFrame(MF,UDim2.new(1,0,0,32),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);MTB.ClipsDescendants=false;mkAccent(MTB)
mkDrag(MF,MTB,function() return menuLocked end)
mkLbl(MTB,"⚔ SpeedMenu v11",UDim2.new(1,-112,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255))
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

function SetTarget(model)
    St.target=model
    if model then TgtLbl.Text=model.Name;StatusLbl.Text="🔒 "..model.Name;StatusLbl.TextColor3=Color3.fromRGB(90,178,255)
    else TgtLbl.Text="No Target";StatusLbl.Text="● Idle";StatusLbl.TextColor3=Color3.fromRGB(60,60,90) end
end

-- ═══════════════════════════════════════════════
--  SCAN FRAME
-- ═══════════════════════════════════════════════
local SF=mkFrame(SG,UDim2.new(0,220,0,400),UDim2.new(0,242,0,40),Color3.fromRGB(11,11,17),true)
_chk(3) -- SF created
SF.Visible=false
local STBF=mkFrame(SF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(17,17,28),false,8);mkAccent(STBF)
local scanLockFn=mkMenuLock(STBF,120);mkDrag(SF,STBF,scanLockFn);mkResize(STBF,SF,220,400)
mkLbl(STBF,"🔍 Scan",UDim2.new(1,-160,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255))
local BtnSOpts=mkBtn(STBF,"⚙",UDim2.new(0,24,0,22),UDim2.new(1,-100,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(200,200,255),12)
local BtnSMin=mkBtn(STBF,"–",UDim2.new(0,20,0,20),UDim2.new(1,-46,0.5,-10),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),12)
local BtnSClose=mkBtn(STBF,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-24,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10)
-- dropdown
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
-- scan content scroll
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
local TPOffPop=mkFrame(SG,UDim2.new(0,210,0,240),UDim2.new(0,4,0,40),Color3.fromRGB(10,14,22),true)
TPOffPop.Visible=false;TPOffPop.ZIndex=14
local TPOBar=mkFrame(TPOffPop,UDim2.new(1,0,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(18,24,36),false,8);TPOBar.ZIndex=14
local tpoLockFn=mkMenuLock(TPOBar,46);mkDrag(TPOffPop,TPOBar,tpoLockFn);mkAccent(TPOBar,Color3.fromRGB(80,160,255))
mkResize(TPOBar,TPOffPop,210,240)
mkLbl(TPOBar,"📐 TP Offset",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(200,220,255))
local BtnTPOClose=mkBtn(TPOBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnTPOClose.ZIndex=14
local TPOScr=mkScroll(TPOffPop,UDim2.new(1,0,1,-28),UDim2.new(0,0,0,28),300)
mkLbl(TPOScr,"ค่า U=ลอยขึ้น | D=ดำดินก่อนวิ้ง",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,4),8,Color3.fromRGB(100,130,180))
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
local CPop=mkFrame(SG,UDim2.new(0,200,0,240),UDim2.new(0,4,0,40),Color3.fromRGB(12,12,18),true)
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
local EPop=mkFrame(SG,UDim2.new(0,200,0,260),UDim2.new(0,4,0,40),Color3.fromRGB(16,8,8),true)
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
local TPMPop=mkFrame(SG,UDim2.new(0,220,0,380),UDim2.new(0,242,0,40),Color3.fromRGB(12,15,22),true)
_chk(4) -- TPMPop created
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
local CamF=mkFrame(SG,UDim2.new(0,200,0,210),UDim2.new(0,4,0,40),Color3.fromRGB(11,11,17),true)
_chk(5) -- CamF created
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
local TF=mkFrame(SG,UDim2.new(0,210,0,270),UDim2.new(0,4,0,40),Color3.fromRGB(11,11,17),true)
_chk(6) -- TF created
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

-- ═══════════════════════════════════════════════
--  FLEE FRAME
-- ═══════════════════════════════════════════════
_chk(7) -- FleeF created
local FleeF=mkFrame(SG,UDim2.new(0,220,0,320),UDim2.new(0,4,0,40),Color3.fromRGB(11,14,11),true)
FleeF.Visible=false
local FleeTB=mkFrame(FleeF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(18,22,18),false,8);mkAccent(FleeTB,Color3.fromRGB(255,140,50))
local fleeLockFn=mkMenuLock(FleeTB,72);mkDrag(FleeF,FleeTB,fleeLockFn);mkResize(FleeTB,FleeF,220,320)
mkLbl(FleeTB,"🏃 หนีเป้าหมาย",UDim2.new(1,-80,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,220,150))
local BtnFleeMin=mkBtn(FleeTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnFleeClose=mkBtn(FleeTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local FleeScr=mkScroll(FleeF,UDim2.new(1,0,1,-30),UDim2.new(0,0,0,30),400)
local BtnFleeOn=mkBtn(FleeScr,"🏃 หนีเป้าหมาย : OFF",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,6),Color3.fromRGB(24,24,40),Color3.fromRGB(255,200,140),11)
mkLbl(FleeScr,"📏 รัศมีที่หนี (studs)",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,40),9,Color3.fromRGB(200,200,180))
local InpFleeRadius=mkInp(FleeScr,Cfg.fleeRadius,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,54))
mkLbl(FleeScr,"🔧 โหมดหนี",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,84),9,Color3.fromRGB(200,200,180))
local BtnFleeWalk=mkBtn(FleeScr,"🦶 เดินหนี",UDim2.new(0,94,0,26),UDim2.new(0,8,0,98),Color3.fromRGB(40,70,40),Color3.fromRGB(180,255,180),10)
local BtnFleeTP=mkBtn(FleeScr,"⚡ วาปหนี",UDim2.new(0,94,0,26),UDim2.new(0,110,0,98),Color3.fromRGB(24,24,50),Color3.fromRGB(180,180,255),10)
mkLbl(FleeScr,"🏃 ความเร็วเดินหนี",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,130),9,Color3.fromRGB(200,200,180))
local InpFleeSpd=mkInp(FleeScr,Cfg.fleeSpd,UDim2.new(1,-16,0,24),UDim2.new(0,8,0,144))
mkDiv(FleeScr,174)
mkLbl(FleeScr,"🎨 สีที่ต้องหนี",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,180),9,Color3.fromRGB(255,190,120))
local FleeCS=mkScroll(FleeScr,UDim2.new(1,-16,0,80),UDim2.new(0,8,0,196),0)
FleeCS.BackgroundColor3=Color3.fromRGB(14,14,20);FleeCS.BackgroundTransparency=0
Instance.new("UICorner",FleeCS).CornerRadius=UDim.new(0,5)
local FleeCL=Instance.new("UIListLayout");FleeCL.Padding=UDim.new(0,3);FleeCL.Parent=FleeCS
local BtnFleeClear=mkBtn(FleeScr,"🗑 ล้างสีที่เลือก",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,282),Color3.fromRGB(60,20,20),Color3.fromRGB(255,150,150),9)
local fleeMin=false
BtnFleeMin.Activated:Connect(function() fleeMin=not fleeMin;FleeScr.Visible=not fleeMin;FleeF.Size=fleeMin and UDim2.new(0,220,0,30) or UDim2.new(0,220,0,320) end)
BtnFleeClose.Activated:Connect(function() FleeF.Visible=false end)
function UpdateFleeModeUI()
    BtnFleeWalk.BackgroundColor3=Cfg.fleeMode=="walk" and Color3.fromRGB(20,80,20) or Color3.fromRGB(40,70,40)
    BtnFleeTP.BackgroundColor3=Cfg.fleeMode=="tp" and Color3.fromRGB(50,50,120) or Color3.fromRGB(24,24,50)
end;UpdateFleeModeUI()
BtnFleeWalk.Activated:Connect(function() Cfg.fleeMode="walk";UpdateFleeModeUI() end)
BtnFleeTP.Activated:Connect(function() Cfg.fleeMode="tp";UpdateFleeModeUI() end)

-- ═══════════════════════════════════════════════
--  SAVE FRAME
_chk(8) -- SaveF created
-- ═══════════════════════════════════════════════
local SaveF=mkFrame(SG,UDim2.new(0,220,0,260),UDim2.new(0,4,0,40),Color3.fromRGB(10,12,20),true)
SaveF.Visible=false;SaveF.ZIndex=20
local SaveTB=mkFrame(SaveF,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(16,20,34),false,8);SaveTB.ZIndex=20
local saveLockFn=mkMenuLock(SaveTB,46);mkDrag(SaveF,SaveTB,saveLockFn);mkAccent(SaveTB,Color3.fromRGB(255,180,50))
mkResize(SaveTB,SaveF,220,260);mkLbl(SaveTB,"💾 Presets",UDim2.new(1,-52,1,0),UDim2.new(0,8,0,0),11,Color3.fromRGB(255,220,100))
local BtnSaveClose=mkBtn(SaveTB,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10);BtnSaveClose.ZIndex=20
local SaveScr=mkScroll(SaveF,UDim2.new(1,0,1,-30),UDim2.new(0,0,0,30),250)
for i=1,3 do
    local y=(i-1)*74
    local lbl=mkLbl(SaveScr,"Slot "..i.." : ว่าง",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,y+2),9,Color3.fromRGB(140,140,180));lbl.ZIndex=20
    local bSv=mkBtn(SaveScr,"💾",UDim2.new(0,52,0,24),UDim2.new(0,8,0,y+18),Color3.fromRGB(20,60,20),Color3.fromRGB(170,255,170),10);bSv.ZIndex=20
    local bLd=mkBtn(SaveScr,"▶ Load",UDim2.new(0,68,0,24),UDim2.new(0,64,0,y+18),Color3.fromRGB(20,40,80),Color3.fromRGB(160,200,255),10);bLd.ZIndex=20
    local bDl=mkBtn(SaveScr,"🗑",UDim2.new(0,36,0,24),UDim2.new(0,136,0,y+18),Color3.fromRGB(70,22,22),Color3.fromRGB(255,140,140),10);bDl.ZIndex=20
    local cF2=mkFrame(SaveScr,UDim2.new(1,-16,0,26),UDim2.new(0,8,0,y+46),Color3.fromRGB(40,14,14),false,5);cF2.Visible=false;cF2.ZIndex=21
    mkLbl(cF2,"ลบ Slot "..i.."?",UDim2.new(0,80,1,0),UDim2.new(0,4,0,0),9,Color3.fromRGB(255,180,180)).ZIndex=21
    local bOk2=mkBtn(cF2,"OK",UDim2.new(0,36,0,18),UDim2.new(0,88,0,4),Color3.fromRGB(80,20,20),Color3.fromRGB(255,200,200),9);bOk2.ZIndex=21
    local bCx2=mkBtn(cF2,"ยกเลิก",UDim2.new(0,54,0,18),UDim2.new(0,128,0,4),Color3.fromRGB(30,30,60),Color3.fromRGB(180,180,255),9);bCx2.ZIndex=21
    if Presets[i] then lbl.Text="Slot "..i.." : ✅";lbl.TextColor3=Color3.fromRGB(100,220,120) end
    bDl.Activated:Connect(function() cF2.Visible=true end)
    bCx2.Activated:Connect(function() cF2.Visible=false end)
    bOk2.Activated:Connect(function() Presets[i]=nil;cF2.Visible=false;SaveCfg();lbl.Text="Slot "..i.." : ว่าง";lbl.TextColor3=Color3.fromRGB(140,140,180) end)
    bSv.Activated:Connect(function()
        Presets[i]={strength=Cfg.strength,range=Cfg.range,mode=Cfg.mode,nearest=Cfg.nearest,
            aimY=Cfg.aimY,aimX=Cfg.aimX,wingSpd=Cfg.wingSpd,tpRapidSpd=St.tpRapidSpd,
            tpL=TpOff.L,tpR=TpOff.R,tpU=TpOff.U,tpD=TpOff.D,tpF=TpOff.F,tpB=TpOff.B}
        SaveCfg();lbl.Text="Slot "..i.." : ✅";lbl.TextColor3=Color3.fromRGB(100,220,120)
    end)
    bLd.Activated:Connect(function()
        local p=Presets[i];if not p then return end
        Cfg.strength=p.strength or Cfg.strength;Cfg.range=p.range or Cfg.range
        Cfg.mode=p.mode or Cfg.mode;Cfg.nearest=p.nearest~=nil and p.nearest or Cfg.nearest
        Cfg.aimY=p.aimY or Cfg.aimY;Cfg.aimX=p.aimX or Cfg.aimX;Cfg.wingSpd=p.wingSpd or Cfg.wingSpd
        St.tpRapidSpd=p.tpRapidSpd or St.tpRapidSpd
        TpOff.L=p.tpL or 0;TpOff.R=p.tpR or 0;TpOff.U=p.tpU or 0;TpOff.D=p.tpD or 0;TpOff.F=p.tpF or 0;TpOff.B=p.tpB or 0
        InpRange.Text=tostring(Cfg.range);InpAimY.Text=tostring(Cfg.aimY);InpAimX.Text=tostring(Cfg.aimX)
        InpWingSpd.Text=tostring(Cfg.wingSpd);InpTPSpd.Text=tostring(St.tpRapidSpd)
        for _,d in ipairs(offDefs) do if offInputs[d.k] then offInputs[d.k].Text=tostring(TpOff[d.k]) end end
        UpdateModeUI()
    end)
end
BtnSaveClose.Activated:Connect(function() SaveF.Visible=false end)
BtnSave.Activated:Connect(function() SaveF.Visible=not SaveF.Visible end)

-- ═══════════════════════════════════════════════
--  AUTO SCAN PROMPT
-- ═══════════════════════════════════════════════
local ASprompt=mkFrame(SG,UDim2.new(0,200,0,96),UDim2.new(0,4,0,40),Color3.fromRGB(14,14,24),true,8)
ASprompt.Visible=false;ASprompt.ZIndex=100
mkLbl(ASprompt,"🔄 ความเร็ว Auto Scan (วิ)",UDim2.new(1,-16,0,18),UDim2.new(0,8,0,8),9,Color3.fromRGB(180,180,255))
local InpASSpd=mkInp(ASprompt,St.autoScanInterval,UDim2.new(1,-16,0,26),UDim2.new(0,8,0,28));InpASSpd.ZIndex=101
local BtnASOK=mkBtn(ASprompt,"✓ OK เริ่ม",UDim2.new(0,88,0,24),UDim2.new(0,8,0,60),Color3.fromRGB(20,70,20),Color3.fromRGB(170,255,170),10);BtnASOK.ZIndex=101
local BtnASCx=mkBtn(ASprompt,"ยกเลิก",UDim2.new(0,88,0,24),UDim2.new(0,102,0,60),Color3.fromRGB(60,20,20),Color3.fromRGB(255,150,150),9);BtnASCx.ZIndex=101
BtnASCx.Activated:Connect(function() ASprompt.Visible=false end)

function startAutoScan()
    if St.autoScanConn then St.autoScanConn:Disconnect();St.autoScanConn=nil end
    St.autoScanOn=true;BtnAutoScanBtn.Text="🔄 Auto ON";BtnAutoScanBtn.BackgroundColor3=Color3.fromRGB(20,60,20)
    local t=0
    St.autoScanConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not St.autoScanOn then return end;t=t+dt
        if t>=St.autoScanInterval then t=0;
            pcall(function() if DoScan then DoScan() end end) end
    end)
end
function stopAutoScan()
    St.autoScanOn=false
    if St.autoScanConn then St.autoScanConn:Disconnect();St.autoScanConn=nil end
    BtnAutoScanBtn.Text="🔄 Auto OFF";BtnAutoScanBtn.BackgroundColor3=Color3.fromRGB(24,24,44)
end
BtnASOK.Activated:Connect(function()
    local v=tonumber(InpASSpd.Text);if v and v>0 then St.autoScanInterval=v;SaveCfg() end
    ASprompt.Visible=false;startAutoScan()
end)
BtnAutoScanBtn.Activated:Connect(function()
    if St.autoScanOn then stopAutoScan();SDrop.Visible=false
    else ASprompt.Visible=true;SDrop.Visible=false;local a=BtnAutoScanBtn.AbsolutePosition;ASprompt.Position=UDim2.new(0,a.X-80,0,a.Y+32) end
end)

-- ═══════════════════════════════════════════════
--  ESP — Highlight คลุมบอดี้จริง
-- ═══════════════════════════════════════════════
function ClearESP()
    for _,t in pairs(St.espHL) do
        pcall(function() if t.hl then t.hl:Destroy() end end)
        pcall(function() if t.bb then t.bb:Destroy() end end)
    end;St.espHL={}
end
function UpdateESP()
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

-- ═══════════════════════════════════════════════
--  COLOR PICKER UPDATES
-- ═══════════════════════════════════════════════
function UpdateFleeColorUI()
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

function UpdateCPicker()
    for _,c in ipairs(CPScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hs,col in pairs(St.colors) do
        n=n+1
        local b=mkBtn(CPScr,"  #"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left;b.ZIndex=11
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        b.Activated:Connect(function() Cfg.filterColor=col;FLbl.Text="🎨 #"..hs;FLbl.TextColor3=col;CPop.Visible=false;UpdateCPicker() end)
    end
    CPScr.CanvasSize=UDim2.new(0,0,0,CPLayout.AbsoluteContentSize.Y+4)
    if n==0 then mkLbl(CPScr,"Scan ก่อน",UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),9,Color3.fromRGB(90,90,120)).ZIndex=11 end
end
function UpdateEPicker()
    for _,c in ipairs(EPScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local n=0
    for hs,col in pairs(St.colors) do
        n=n+1;local sel=false
        for _,h in ipairs(St.pendEx) do if h==hs then sel=true;break end end
        local b=mkBtn(EPScr,(sel and "✓ " or "  ").."#"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),sel and Color3.fromRGB(90,30,30) or col,Color3.fromRGB(255,255,255),9)
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

-- ═══════════════════════════════════════════════
--  SCAN (DoScan)
-- ═══════════════════════════════════════════════
function DoScan()
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

-- ═══════════════════════════════════════════════
--  TP CORE
-- ═══════════════════════════════════════════════
function CalcTPOffset(hrp)
    local cf=hrp.CFrame
    return cf.RightVector*(TpOff.R-TpOff.L)+cf.UpVector*(TpOff.U-TpOff.D)+cf.LookVector*(TpOff.F-TpOff.B)
end
function doTP(hrp)
    local char=LP.Character;if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
    local offset=CalcTPOffset(hrp);if offset.Magnitude<0.01 then offset=Vector3.new(0,3,0) end
    local inV,seat=IsInVehicle()
    if inV and seat then pcall(function() (seat.AssemblyRootPart or seat).CFrame=CFrame.new(hrp.Position+offset) end)
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

-- ═══════════════════════════════════════════════
--  TERRAIN TRANSPARENT
-- ═══════════════════════════════════════════════
local function setTerrainTrans(on)
    if St.terrainTrans==on then return end;St.terrainTrans=on
    pcall(function()
        local t=workspace:FindFirstChildOfClass("Terrain")
        if t then t.Transparency=on and 1 or 0 end
    end)
end

-- ═══════════════════════════════════════════════
--  NO CLIP
-- ═══════════════════════════════════════════════
function startNoClip()
    if St.noClipConn then return end
    St.noClipConn=Svc.Run.Stepped:Connect(function()
        local c=LP.Character;if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
end
function stopNoClip()
    if St.noClipConn then St.noClipConn:Disconnect();St.noClipConn=nil end
    local c=LP.Character;if not c then return end
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end
end

-- ═══════════════════════════════════════════════
--  WING FOLLOW
-- ═══════════════════════════════════════════════
local function getStopDist()
    return math.max(0,Vector3.new(TpOff.R-TpOff.L,TpOff.U-TpOff.D,TpOff.F-TpOff.B).Magnitude)
end
function stopWing()
    if St.wingConn then St.wingConn:Disconnect();St.wingConn=nil end
    St.wingOn=false;St.wingTgt=nil;St.wingLiftY=0;St.wingLiftTarget=0
    setTerrainTrans(false)
    local c=LP.Character;if c then
        local hum=c:FindFirstChildOfClass("Humanoid");if hum then hum.PlatformStand=false end
        local hrp=c:FindFirstChild("HumanoidRootPart");if hrp then hrp.Anchored=false;pcall(function() hrp.AssemblyLinearVelocity=Vector3.zero end) end
    end
    if BtnTPM3 then BtnTPM3.BackgroundColor3=Color3.fromRGB(30,50,80) end
end
function startWingFollow(hrp)
    stopWing();stopRapidTP()
    St.wingOn=true;St.wingTgt=hrp;St.wingLiftY=0;St.wingLiftTarget=0
    BtnTPM3.BackgroundColor3=Color3.fromRGB(20,50,100)
    St.wingConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not St.wingOn or not St.wingTgt or not St.wingTgt.Parent then stopWing();return end
        local tPos=St.wingTgt.Position
        local offset=CalcTPOffset(St.wingTgt)
        -- U ลอยขึ้น D ดำดินลงไป
        local extraY=TpOff.U-TpOff.D
        if offset.Magnitude<0.01 then offset=Vector3.new(0,extraY~=0 and extraY or 3,0) end
        local dest=tPos+offset
        setTerrainTrans(TpOff.D>0)
        local stopDist=getStopDist();local spd=Cfg.wingSpd
        local c=LP.Character;if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart");if not root then return end
        local hum=c:FindFirstChildOfClass("Humanoid");if hum then hum.PlatformStand=true end
        root.Anchored=false;pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        local cur=root.Position;local diff=dest-cur;local dist=diff.Magnitude
        local horizDir=Vector3.new(diff.X,0,diff.Z)
        if not Cfg.noClip and horizDir.Magnitude>0.1 and dist>stopDist+0.05 then
            local hitCC=false
            pcall(function()
                local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Exclude;p.FilterDescendantsInstances={c}
                local res=workspace:Raycast(cur+Vector3.new(0,1,0),horizDir.Unit*(math.min(dist,spd*dt)+2),p)
                if res and res.Instance and res.Instance:IsA("BasePart") and res.Instance.CanCollide then hitCC=true end
            end)
            if hitCC then St.wingLiftTarget=math.min(St.wingLiftTarget+spd*dt*3,40)
            else St.wingLiftTarget=math.max(0,St.wingLiftTarget-spd*dt*1.5) end
        else St.wingLiftTarget=math.max(0,St.wingLiftTarget-spd*dt) end
        St.wingLiftY=St.wingLiftY+(St.wingLiftTarget-St.wingLiftY)*math.min(1,dt*8)
        local ld=(dest+Vector3.new(0,St.wingLiftY,0))-cur;local ldist=ld.Magnitude
        if ldist>stopDist+0.05 then
            local step=math.min(ldist,spd*dt);local newP=cur+ld.Unit*step
            local fd=Vector3.new(ld.X,0,ld.Z)
            if fd.Magnitude>0.1 then root.CFrame=CFrame.new(newP,newP+fd.Unit) else root.CFrame=CFrame.new(newP) end
            pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        else
            root.CFrame=CFrame.new(dest+Vector3.new(0,St.wingLiftY,0))
            pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
        end
    end)
end

-- ═══════════════════════════════════════════════
--  ORBIT
-- ═══════════════════════════════════════════════
function stopOrbit()
    if St.orbitConn then St.orbitConn:Disconnect();St.orbitConn=nil end
    Cfg.orbitOn=false;BtnOrbit.Text="🌀 หมุนรอบ : OFF";BtnOrbit.BackgroundColor3=Color3.fromRGB(30,40,70)
end
function startOrbit()
    stopOrbit();Cfg.orbitOn=true;St.orbitAngle=0;St.orbitDir=1;St.orbitTimer=0
    BtnOrbit.Text="🌀 หมุนรอบ : ON";BtnOrbit.BackgroundColor3=Color3.fromRGB(20,50,110)
    St.orbitConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not Cfg.orbitOn or not St.target or not St.target.Parent then if not St.target then stopOrbit() end;return end
        local hrp=GetRoot(St.target);if not hrp then return end
        local c=LP.Character;if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart");if not root then return end
        local stopDist=getStopDist();local dist=(root.Position-hrp.Position).Magnitude
        if dist>stopDist+2 then return end
        if Cfg.orbitAlt then
            St.orbitTimer=St.orbitTimer+dt
            local lim=St.orbitDir==1 and Cfg.orbitL or Cfg.orbitR
            if St.orbitTimer>=lim then St.orbitTimer=0;St.orbitDir=-St.orbitDir end
        end
        St.orbitAngle=St.orbitAngle+math.rad(Cfg.orbitSpd*dt)*St.orbitDir
        local radius=math.max(getStopDist(),2)
        local ox=hrp.Position.X+math.cos(St.orbitAngle)*radius
        local oz=hrp.Position.Z+math.sin(St.orbitAngle)*radius
        local oy=hrp.Position.Y+(TpOff.U-TpOff.D)
        root.CFrame=CFrame.new(Vector3.new(ox,oy,oz),hrp.Position)
        pcall(function() root.AssemblyLinearVelocity=Vector3.zero end)
    end)
end

-- ═══════════════════════════════════════════════
--  FLEE
-- ═══════════════════════════════════════════════
function stopFlee()
    if St.fleeConn then St.fleeConn:Disconnect();St.fleeConn=nil end
    Cfg.fleeOn=false;BtnFleeOn.Text="🏃 หนีเป้าหมาย : OFF";BtnFleeOn.BackgroundColor3=Color3.fromRGB(24,24,40)
    local c=LP.Character;if c then local hum=c:FindFirstChildOfClass("Humanoid");if hum then hum.WalkSpeed=16 end end
end
function startFlee()
    stopFlee();Cfg.fleeOn=true;BtnFleeOn.Text="🏃 หนีเป้าหมาย : ON";BtnFleeOn.BackgroundColor3=Color3.fromRGB(80,40,10)
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
            local away=(root.Position-hrp.Position)
            if away.Magnitude>0.1 then
                local awD=away.Unit
                if Cfg.fleeMode=="tp" then root.CFrame=CFrame.new(root.Position+awD*(radius+5))
                else hum.WalkSpeed=fspd;hum:MoveTo(root.Position+awD*10) end
            end
        else hum.WalkSpeed=16 end
    end)
end
BtnFleeOn.Activated:Connect(function() if Cfg.fleeOn then stopFlee() else startFlee() end end)
bindTriple(BtnFleeOn,"🏃หนีเป้า",function() if Cfg.fleeOn then stopFlee() else startFlee() end end,function() return Cfg.fleeOn end,true)

-- ═══════════════════════════════════════════════
--  LOCK CORE
-- ═══════════════════════════════════════════════
local function StartLock()
    if St.lockConn then St.lockConn:Disconnect();St.lockConn=nil end
    local timer=0;CHF.Visible=true
    local function snapCam()
        local myHRP=St.char and St.char:FindFirstChild("HumanoidRootPart");if not myHRP or not St.target then return end
        local hrp=GetRoot(St.target);if not hrp then return end
        local head=St.target:FindFirstChild("Head",true)
        local aim=(head and head.Position or hrp.Position)+Vector3.new(0,Cfg.aimY,0)
        local cp=Cam.CFrame.Position
        if (aim-cp).Magnitude>0.1 then Cam.CFrame=CFrame.lookAt(cp,aim) end
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
        local cp=Cam.CFrame.Position
        local aim=(head and head.Position or hrp.Position)+Vector3.new(0,Cfg.aimY,0)+Cam.CFrame.RightVector*Cfg.aimX
        Cam.CFrame=Cam.CFrame:Lerp(CFrame.lookAt(cp,aim),alpha)
        local inV,seat=IsInVehicle()
        if inV and seat then
            pcall(function()
                local r=seat.AssemblyRootPart or seat
                local fd=Vector3.new(aim.X-r.Position.X,0,aim.Z-r.Position.Z)
                if fd.Magnitude>0.5 then r.CFrame=CFrame.new(r.Position,r.Position+fd.Unit) end
            end)
        else
            local bl=Vector3.new(Cam.CFrame.LookVector.X,0,Cam.CFrame.LookVector.Z)
            if bl.Magnitude>0.1 then myHRP.CFrame=CFrame.new(myHRP.Position,myHRP.Position+bl.Unit) end
        end
        UpdateCH()
        if St.fakePart then St.fakePart.CFrame=CFrame.new(aim);Mouse.TargetFilter=St.fakePart end
        pcall(function() Mouse.Hit=CFrame.new(aim);Mouse.Target=head or hrp end)
    end)
    snapCam()
end
local function StopLock()
    if St.lockConn then St.lockConn:Disconnect();St.lockConn=nil end
    SetTarget(nil);CHF.Visible=false
    if St.fakePart then St.fakePart.CFrame=CFrame.new(0,-10000,0) end
end

-- ═══════════════════════════════════════════════
--  TP REFRESH
-- ═══════════════════════════════════════════════
function TPRefresh()
    for _,c in ipairs(TPScr:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for i,pos in ipairs(St.tpSaves) do
        local b=mkBtn(TPScr,string.format("📍 %d (%.0f,%.0f,%.0f)",i,pos.x,pos.y,pos.z),
            UDim2.new(1,-5,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(19,19,30),Color3.fromRGB(160,180,255),10)
        b.TextXAlignment=Enum.TextXAlignment.Left;Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        b.Activated:Connect(function()
            St.tpSel=i;local c2=LP.Character or LP.CharacterAdded:Wait()
            local root=c2:FindFirstChild("HumanoidRootPart");if root then root.CFrame=CFrame.new(pos.x,pos.y,pos.z) end
            for _,c3 in ipairs(TPScr:GetChildren()) do if c3:IsA("TextButton") then c3.BackgroundColor3=Color3.fromRGB(19,19,30) end end
            b.BackgroundColor3=Color3.fromRGB(32,50,84)
        end)
    end
    TPScr.CanvasSize=UDim2.new(0,0,0,#St.tpSaves*30)
end

-- ═══════════════════════════════════════════════
--  MAIN LOOPS
-- ═══════════════════════════════════════════════
Svc.Run.RenderStepped:Connect(function(dt)
    UpdateCH()
    if not Cfg.enabled then
        if St.camLocked and not St.camFree then
            local c=LP.Character;if c then local r=c:FindFirstChild("HumanoidRootPart");if r then Cam.CFrame=CFrame.new(r.Position-Cam.CFrame.LookVector*St.camDist,r.Position) end end
        end
        if St.camFree then
            local rot=CFrame.Angles(0,math.rad(St.camAX),0)*CFrame.Angles(math.rad(St.camAY),0,0)
            local d=rot.LookVector
            St.camFreePos=St.camFreePos+d*St.camMove.Z*St.camSpd*dt*60+rot.RightVector*St.camMove.X*St.camSpd*dt*60+Vector3.new(0,1,0)*St.camMove.Y*St.camSpd*dt*60
            Cam.CFrame=CFrame.new(St.camFreePos,St.camFreePos+d)
        end
    end
end)
Svc.Run.Heartbeat:Connect(function(dt)
    if Cfg.esp then St.espT=St.espT+dt;if St.espT>=0.3 then St.espT=0;UpdateESP() end end
    if St.clickTP and St.lockPos then
        local c=LP.Character;if not c then return end
        local r=c:FindFirstChild("HumanoidRootPart");if not r then return end
        if (r.Position-St.lockPos).Magnitude>10 then r.CFrame=CFrame.new(St.lockPos+Vector3.new(0,3,0)) end
    end
end)
Svc.UIS.InputChanged:Connect(function(i)
    if St.camFree and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        St.camAX=St.camAX-i.Delta.X*0.2;St.camAY=math.clamp(St.camAY-i.Delta.Y*0.2,-80,80)
    end
end)
LP.CharacterAdded:Connect(function(c)
    St.char=c;c:WaitForChild("HumanoidRootPart");St.target=nil;ClearESP()
    stopWing();stopOrbit()
    if Cfg.enabled then task.wait(0.5);StartLock() end
end)

-- ═══════════════════════════════════════════════
--  CONNECTIONS
-- ═══════════════════════════════════════════════
InpRange.FocusLost:Connect(function() local v=tonumber(InpRange.Text);if v then Cfg.range=v;SaveCfg() else InpRange.Text=tostring(Cfg.range) end end)
bindTripleInp(InpRange,"📏 Range",function(v) Cfg.range=v;SaveCfg() end,function() return Cfg.range end)
InpAimY.FocusLost:Connect(function() local v=tonumber(InpAimY.Text);if v then Cfg.aimY=v;SaveCfg() else InpAimY.Text=tostring(Cfg.aimY) end end)
bindTripleInp(InpAimY,"⬆ Aim Y",function(v) Cfg.aimY=v;SaveCfg() end,function() return Cfg.aimY end)
InpAimX.FocusLost:Connect(function() local v=tonumber(InpAimX.Text);if v then Cfg.aimX=v;SaveCfg() else InpAimX.Text=tostring(Cfg.aimX) end end)
bindTripleInp(InpAimX,"↔ Aim X",function(v) Cfg.aimX=v;SaveCfg() end,function() return Cfg.aimX end)
BtnAYU.Activated:Connect(function() Cfg.aimY=Cfg.aimY+0.5;InpAimY.Text=tostring(Cfg.aimY);SaveCfg() end)
BtnAYD.Activated:Connect(function() Cfg.aimY=Cfg.aimY-0.5;InpAimY.Text=tostring(Cfg.aimY);SaveCfg() end)
BtnAXL.Activated:Connect(function() Cfg.aimX=Cfg.aimX+1;InpAimX.Text=tostring(Cfg.aimX);SaveCfg() end)
BtnAXR.Activated:Connect(function() Cfg.aimX=Cfg.aimX-1;InpAimX.Text=tostring(Cfg.aimX);SaveCfg() end)
InpCamDist.FocusLost:Connect(function() local v=tonumber(InpCamDist.Text);if v then St.camDist=v else InpCamDist.Text=tostring(St.camDist) end end)
InpCamSpd.FocusLost:Connect(function() local v=tonumber(InpCamSpd.Text);if v then St.camSpd=v else InpCamSpd.Text=tostring(St.camSpd) end end)
InpTPSpd.FocusLost:Connect(function() local v=tonumber(InpTPSpd.Text);if v and v>0 then St.tpRapidSpd=v;SaveCfg() else InpTPSpd.Text=tostring(St.tpRapidSpd) end end)
bindTripleInp(InpTPSpd,"⚡TP Speed",function(v) St.tpRapidSpd=v;SaveCfg() end,function() return St.tpRapidSpd end)
InpWingSpd.FocusLost:Connect(function() local v=tonumber(InpWingSpd.Text);if v and v>0 then Cfg.wingSpd=v;SaveCfg() else InpWingSpd.Text=tostring(Cfg.wingSpd) end end)
bindTripleInp(InpWingSpd,"🏃Wing Speed",function(v) Cfg.wingSpd=v;SaveCfg() end,function() return Cfg.wingSpd end)
InpStr.FocusLost:Connect(function() local v=tonumber(InpStr.Text);if v then Cfg.strength=math.clamp(v,0,1);SaveCfg() else InpStr.Text=tostring(Cfg.strength) end end)
bindTripleInp(InpStr,"💪Strength",function(v) Cfg.strength=math.clamp(v,0,1);SaveCfg() end,function() return Cfg.strength end)
InpOrbitSpd.FocusLost:Connect(function() local v=tonumber(InpOrbitSpd.Text);if v then Cfg.orbitSpd=v;SaveCfg() else InpOrbitSpd.Text=tostring(Cfg.orbitSpd) end end)
bindTripleInp(InpOrbitSpd,"⚡Orbit Spd",function(v) Cfg.orbitSpd=v;SaveCfg() end,function() return Cfg.orbitSpd end)
InpOrbitL.FocusLost:Connect(function() local v=tonumber(InpOrbitL.Text);if v then Cfg.orbitL=v;SaveCfg() else InpOrbitL.Text=tostring(Cfg.orbitL) end end)
bindTripleInp(InpOrbitL,"⏱ซ้าย(วิ)",function(v) Cfg.orbitL=v;SaveCfg() end,function() return Cfg.orbitL end)
InpOrbitR.FocusLost:Connect(function() local v=tonumber(InpOrbitR.Text);if v then Cfg.orbitR=v;SaveCfg() else InpOrbitR.Text=tostring(Cfg.orbitR) end end)
bindTripleInp(InpOrbitR,"⏱ขวา(วิ)",function(v) Cfg.orbitR=v;SaveCfg() end,function() return Cfg.orbitR end)
InpFleeRadius.FocusLost:Connect(function() local v=tonumber(InpFleeRadius.Text);if v then Cfg.fleeRadius=v;SaveCfg() else InpFleeRadius.Text=tostring(Cfg.fleeRadius) end end)
bindTripleInp(InpFleeRadius,"📏รัศมีหนี",function(v) Cfg.fleeRadius=v;SaveCfg() end,function() return Cfg.fleeRadius end)
InpFleeSpd.FocusLost:Connect(function() local v=tonumber(InpFleeSpd.Text);if v then Cfg.fleeSpd=v;SaveCfg() else InpFleeSpd.Text=tostring(Cfg.fleeSpd) end end)
bindTripleInp(InpFleeSpd,"🏃ความเร็วหนี",function(v) Cfg.fleeSpd=v;SaveCfg() end,function() return Cfg.fleeSpd end)

BtnPlayer.Activated:Connect(function() Cfg.mode="Player";St.target=nil;UpdateModeUI();SaveCfg() end)
BtnNPC.Activated:Connect(function() Cfg.mode="NPC";St.target=nil;UpdateModeUI();SaveCfg() end)
BtnLock.Activated:Connect(function()
    Cfg.enabled=not Cfg.enabled
    if Cfg.enabled then BtnLock.Text="🔒 Lock : ON";BtnLock.BackgroundColor3=Color3.fromRGB(20,58,20);StartLock()
    else BtnLock.Text="🔓 Lock : OFF";BtnLock.BackgroundColor3=Color3.fromRGB(24,24,40);StopLock() end
end)
bindTriple(BtnLock,"🔒Lock",function()
    Cfg.enabled=not Cfg.enabled
    if Cfg.enabled then BtnLock.Text="🔒 Lock : ON";BtnLock.BackgroundColor3=Color3.fromRGB(20,58,20);StartLock()
    else BtnLock.Text="🔓 Lock : OFF";BtnLock.BackgroundColor3=Color3.fromRGB(24,24,40);StopLock() end
end,function() return Cfg.enabled end,true)
BtnNear.Activated:Connect(function()
    Cfg.nearest=not Cfg.nearest;BtnNear.Text=Cfg.nearest and "📍 Nearest : ON" or "📍 Nearest : OFF"
    BtnNear.BackgroundColor3=Cfg.nearest and Color3.fromRGB(20,58,20) or Color3.fromRGB(24,24,40)
    if Cfg.nearest then St.target=nil;St.rescan=true end;SaveCfg()
end)
bindTriple(BtnNear,"📍Near",function()
    Cfg.nearest=not Cfg.nearest;BtnNear.Text=Cfg.nearest and "📍 Nearest : ON" or "📍 Nearest : OFF"
    BtnNear.BackgroundColor3=Cfg.nearest and Color3.fromRGB(20,58,20) or Color3.fromRGB(24,24,40)
    if Cfg.nearest then St.target=nil;St.rescan=true end;SaveCfg()
end,function() return Cfg.nearest end,true)
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
bindTriple(BtnESP,"👁ESP",function()
    Cfg.esp=not Cfg.esp;BtnESP.Text=Cfg.esp and "👁 ESP ON" or "👁 ESP"
    BtnESP.BackgroundColor3=Cfg.esp and Color3.fromRGB(20,50,74) or Color3.fromRGB(24,24,40)
    if not Cfg.esp then ClearESP() end
end,function() return Cfg.esp end,true)
local scanVis=false
BtnScan.Activated:Connect(function() scanVis=not scanVis;SF.Visible=scanVis;BtnScan.BackgroundColor3=scanVis and Color3.fromRGB(24,40,74) or Color3.fromRGB(24,24,40) end)
bindTriple(BtnScan,"🔍Scan",function() scanVis=not scanVis;SF.Visible=scanVis;BtnScan.BackgroundColor3=scanVis and Color3.fromRGB(24,40,74) or Color3.fromRGB(24,24,40) end,function() return scanVis end,true)
local camVis=false
BtnCamSys.Activated:Connect(function() camVis=not camVis;CamF.Visible=camVis;BtnCamSys.BackgroundColor3=camVis and Color3.fromRGB(74,50,16) or Color3.fromRGB(24,24,40) end)
bindTriple(BtnCamSys,"📷Cam",function() camVis=not camVis;CamF.Visible=camVis;BtnCamSys.BackgroundColor3=camVis and Color3.fromRGB(74,50,16) or Color3.fromRGB(24,24,40) end,function() return camVis end,true)
BtnCamLock.Activated:Connect(function() St.camLocked=not St.camLocked;BtnCamLock.Text=St.camLocked and "🔒 Lock Cam ON" or "🔒 Lock Cam OFF";BtnCamLock.BackgroundColor3=St.camLocked and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32) end)
bindTriple(BtnCamLock,"🔒CamLk",function() St.camLocked=not St.camLocked;BtnCamLock.Text=St.camLocked and "🔒 Lock Cam ON" or "🔒 Lock Cam OFF";BtnCamLock.BackgroundColor3=St.camLocked and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32) end,function() return St.camLocked end,true)
BtnCamFree.Activated:Connect(function()
    St.camFree=not St.camFree;BtnCamFree.Text=St.camFree and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    BtnCamFree.BackgroundColor3=St.camFree and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
    CtrlPad.Visible=St.camFree;if St.camFree then St.camFreePos=Cam.CFrame.Position end
end)
bindTriple(BtnCamFree,"🎥Free",function()
    St.camFree=not St.camFree;BtnCamFree.Text=St.camFree and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    BtnCamFree.BackgroundColor3=St.camFree and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
    CtrlPad.Visible=St.camFree;if St.camFree then St.camFreePos=Cam.CFrame.Position end
end,function() return St.camFree end,true)
local tpVis=false
BtnTP.Activated:Connect(function() tpVis=not tpVis;TF.Visible=tpVis;BtnTP.BackgroundColor3=tpVis and Color3.fromRGB(16,50,26) or Color3.fromRGB(24,24,40);if tpVis then TPRefresh() end end)
bindTriple(BtnTP,"🚀TP",function() tpVis=not tpVis;TF.Visible=tpVis;BtnTP.BackgroundColor3=tpVis and Color3.fromRGB(16,50,26) or Color3.fromRGB(24,24,40);if tpVis then TPRefresh() end end,function() return tpVis end,true)
BtnTPSave.Activated:Connect(function()
    local c=LP.Character or LP.CharacterAdded:Wait();local r=c:FindFirstChild("HumanoidRootPart");if not r then return end
    table.insert(St.tpSaves,{x=r.Position.X,y=r.Position.Y,z=r.Position.Z});SaveCfg();TPRefresh()
end)
BtnTPDel.Activated:Connect(function() if St.tpSel then table.remove(St.tpSaves,St.tpSel);St.tpSel=nil;SaveCfg();TPRefresh() end end)
BtnTPClic.Activated:Connect(function()
    St.clickTP=not St.clickTP;if not St.clickTP then St.lockPos=nil end
    BtnTPClic.Text=St.clickTP and "ClickTP ON" or "ClickTP OFF"
    BtnTPClic.BackgroundColor3=St.clickTP and Color3.fromRGB(20,92,40) or Color3.fromRGB(130,32,32)
end)
bindTriple(BtnTPClic,"ClickTP",function()
    St.clickTP=not St.clickTP;if not St.clickTP then St.lockPos=nil end
    BtnTPClic.Text=St.clickTP and "ClickTP ON" or "ClickTP OFF"
    BtnTPClic.BackgroundColor3=St.clickTP and Color3.fromRGB(20,92,40) or Color3.fromRGB(130,32,32)
end,function() return St.clickTP end,true)
Mouse.Button1Down:Connect(function()
    if not St.clickTP then return end
    local c=LP.Character;if not c then return end;local r=c:FindFirstChild("HumanoidRootPart");if not r then return end
    local h=Mouse.Hit;if h then St.lockPos=h.Position;r.CFrame=CFrame.new(St.lockPos+Vector3.new(0,3,0)) end
end)
BtnDoScanBtn.Activated:Connect(function() DoScan();SDrop.Visible=false end)
BtnTPScan.Activated:Connect(function()
    St.tpScan=not St.tpScan;BtnTPScan.BackgroundColor3=St.tpScan and Color3.fromRGB(20,120,20) or Color3.fromRGB(30,80,30)
    if St.tpScan then TPMPop.Visible=true else TPMPop.Visible=false;stopRapidTP();stopWing() end;SDrop.Visible=false
end)
bindTriple(BtnTPScan,"🚀TPScan",function()
    St.tpScan=not St.tpScan;BtnTPScan.BackgroundColor3=St.tpScan and Color3.fromRGB(20,120,20) or Color3.fromRGB(30,80,30)
    if not St.tpScan then stopRapidTP();stopWing() end
end,function() return St.tpScan end,true)
BtnCPBtn.Activated:Connect(function() CPop.Visible=not CPop.Visible;EPop.Visible=false;TPOffPop.Visible=false;SDrop.Visible=false;if CPop.Visible then UpdateCPicker() end end)
BtnCPAll.Activated:Connect(function() Cfg.filterColor=nil;FLbl.Text="🎨 Filter: ทั้งหมด";FLbl.TextColor3=Color3.fromRGB(120,120,170);CPop.Visible=false;UpdateCPicker() end)
BtnCF.Activated:Connect(function() Cfg.filterColor=nil;FLbl.Text="🎨 Filter: ทั้งหมด";FLbl.TextColor3=Color3.fromRGB(120,120,170);UpdateCPicker() end)
BtnExcBtn.Activated:Connect(function()
    EPop.Visible=not EPop.Visible;CPop.Visible=false;SDrop.Visible=false
    if EPop.Visible then St.pendEx={};for _,h in ipairs(Cfg.exclude) do table.insert(St.pendEx,h) end;UpdateEPicker() end
end)
BtnEPOk.Activated:Connect(function() Cfg.exclude={};for _,h in ipairs(St.pendEx) do table.insert(Cfg.exclude,h) end;UpdateEPicker();EPop.Visible=false;St.pendEx={} end)
BtnCE.Activated:Connect(function() Cfg.exclude={};St.pendEx={};UpdateEPicker() end)
BtnTPM1.Activated:Connect(function() St.tpModeSelect=1;stopWing();stopOrbit();UpdateTPMUI() end)
BtnTPM2.Activated:Connect(function() St.tpModeSelect=2;stopWing();stopOrbit();UpdateTPMUI() end)
BtnTPM3.Activated:Connect(function()
    St.tpModeSelect=3;stopRapidTP();UpdateTPMUI()
    if St.target then local hrp=GetRoot(St.target);if hrp then startWingFollow(hrp) end end
end)
bindTriple(BtnTPM1,"1️⃣ปกติ",function() St.tpModeSelect=1;stopWing();stopOrbit();UpdateTPMUI() end,nil,false)
bindTriple(BtnTPM2,"2️⃣รัว",function() St.tpModeSelect=2;stopWing();stopOrbit();UpdateTPMUI() end,nil,false)
bindTriple(BtnTPM3,"3️⃣วิ้ง",function() St.tpModeSelect=3;stopRapidTP();UpdateTPMUI();if St.target then local hrp=GetRoot(St.target);if hrp then startWingFollow(hrp) end end end,nil,false)
BtnTPMClose.Activated:Connect(function() TPMPop.Visible=false end)
BtnNoClip.Activated:Connect(function()
    Cfg.noClip=not Cfg.noClip;BtnNoClip.Text=Cfg.noClip and "🧱 ทะลุกำแพง : ON" or "🧱 ทะลุกำแพง : OFF"
    BtnNoClip.BackgroundColor3=Cfg.noClip and Color3.fromRGB(80,30,110) or Color3.fromRGB(60,30,80)
    if Cfg.noClip then startNoClip() else stopNoClip() end;SaveCfg()
end)
bindTriple(BtnNoClip,"🧱NoClip",function()
    Cfg.noClip=not Cfg.noClip;BtnNoClip.Text=Cfg.noClip and "🧱 ทะลุกำแพง : ON" or "🧱 ทะลุกำแพง : OFF"
    BtnNoClip.BackgroundColor3=Cfg.noClip and Color3.fromRGB(80,30,110) or Color3.fromRGB(60,30,80)
    if Cfg.noClip then startNoClip() else stopNoClip() end;SaveCfg()
end,function() return Cfg.noClip end,true)
BtnOrbit.Activated:Connect(function() if Cfg.orbitOn then stopOrbit() else startOrbit() end end)
bindTriple(BtnOrbit,"🌀หมุนรอบ",function() if Cfg.orbitOn then stopOrbit() else startOrbit() end end,function() return Cfg.orbitOn end,true)
BtnOrbitAlt.Activated:Connect(function()
    Cfg.orbitAlt=not Cfg.orbitAlt;BtnOrbitAlt.Text=Cfg.orbitAlt and "🔁 สลับซ้าย/ขวา : ON" or "🔁 สลับซ้าย/ขวา : OFF"
    BtnOrbitAlt.BackgroundColor3=Cfg.orbitAlt and Color3.fromRGB(20,80,60) or Color3.fromRGB(30,50,60);SaveCfg()
end)
bindTriple(BtnOrbitAlt,"🔁สลับหมุน",function()
    Cfg.orbitAlt=not Cfg.orbitAlt;BtnOrbitAlt.Text=Cfg.orbitAlt and "🔁 สลับซ้าย/ขวา : ON" or "🔁 สลับซ้าย/ขวา : OFF"
    BtnOrbitAlt.BackgroundColor3=Cfg.orbitAlt and Color3.fromRGB(20,80,60) or Color3.fromRGB(30,50,60);SaveCfg()
end,function() return Cfg.orbitAlt end,true)
BtnFleeMenu.Activated:Connect(function() FleeF.Visible=not FleeF.Visible end)
bindTriple(BtnFleeMenu,"🏃หนีเมนู",function() FleeF.Visible=not FleeF.Visible end,function() return FleeF.Visible end,true)
BtnMClose.Activated:Connect(function()
    StopLock();ClearESP();stopWing();stopOrbit();stopAutoScan();stopFlee();stopNoClip()
    setTerrainTrans(false);if St.fakePart then St.fakePart:Destroy() end;SG:Destroy()
end)

-- ══ INIT ══
if Cfg.nearest then BtnNear.Text="📍 Nearest : ON";BtnNear.BackgroundColor3=Color3.fromRGB(20,58,20) end
if Cfg.orbitAlt then BtnOrbitAlt.Text="🔁 สลับซ้าย/ขวา : ON";BtnOrbitAlt.BackgroundColor3=Color3.fromRGB(20,80,60) end
TPRefresh();UpdateFleeModeUI()
-- notify โหลดสำเร็จ
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",{
        Title="✅ SpeedMenu v11",
        Text="โหลดสำเร็จ step="..tostring(_step),
        Duration=5,
    })
end)