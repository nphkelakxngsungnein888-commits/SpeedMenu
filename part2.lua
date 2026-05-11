-- ═══════════════════════════════════════════════
--  FLEE FRAME
-- ═══════════════════════════════════════════════
local FleeF=mkFrame(SG,UDim2.new(0,220,0,320),UDim2.new(0.5,-110,0.5,-160),Color3.fromRGB(11,14,11),true)
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
local function UpdateFleeModeUI()
    BtnFleeWalk.BackgroundColor3=Cfg.fleeMode=="walk" and Color3.fromRGB(20,80,20) or Color3.fromRGB(40,70,40)
    BtnFleeTP.BackgroundColor3=Cfg.fleeMode=="tp" and Color3.fromRGB(50,50,120) or Color3.fromRGB(24,24,50)
end;UpdateFleeModeUI()
BtnFleeWalk.Activated:Connect(function() Cfg.fleeMode="walk";UpdateFleeModeUI() end)
BtnFleeTP.Activated:Connect(function() Cfg.fleeMode="tp";UpdateFleeModeUI() end)

-- ═══════════════════════════════════════════════
--  SAVE FRAME
-- ═══════════════════════════════════════════════
local SaveF=mkFrame(SG,UDim2.new(0,220,0,260),UDim2.new(0.5,-110,0.5,-130),Color3.fromRGB(10,12,20),true)
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
local ASprompt=mkFrame(SG,UDim2.new(0,200,0,96),UDim2.new(0.5,-100,0.5,-48),Color3.fromRGB(14,14,24),true,8)
ASprompt.Visible=false;ASprompt.ZIndex=100
mkLbl(ASprompt,"🔄 ความเร็ว Auto Scan (วิ)",UDim2.new(1,-16,0,18),UDim2.new(0,8,0,8),9,Color3.fromRGB(180,180,255))
local InpASSpd=mkInp(ASprompt,St.autoScanInterval,UDim2.new(1,-16,0,26),UDim2.new(0,8,0,28));InpASSpd.ZIndex=101
local BtnASOK=mkBtn(ASprompt,"✓ OK เริ่ม",UDim2.new(0,88,0,24),UDim2.new(0,8,0,60),Color3.fromRGB(20,70,20),Color3.fromRGB(170,255,170),10);BtnASOK.ZIndex=101
local BtnASCx=mkBtn(ASprompt,"ยกเลิก",UDim2.new(0,88,0,24),UDim2.new(0,102,0,60),Color3.fromRGB(60,20,20),Color3.fromRGB(255,150,150),9);BtnASCx.ZIndex=101
BtnASCx.Activated:Connect(function() ASprompt.Visible=false end)

-- [FIX] ประกาศ DoScan เป็น upvalue ก่อน แล้วกำหนดทีหลัง
--       เพื่อให้ startAutoScan อ้างอิงได้ถูกต้อง
local DoScan

local function startAutoScan()
    if St.autoScanConn then St.autoScanConn:Disconnect();St.autoScanConn=nil end
    St.autoScanOn=true;BtnAutoScanBtn.Text="🔄 Auto ON";BtnAutoScanBtn.BackgroundColor3=Color3.fromRGB(20,60,20)
    local t=0
    St.autoScanConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not St.autoScanOn then return end;t=t+dt
        if t>=St.autoScanInterval then t=0
            if DoScan then DoScan() end   -- [FIX] ตรวจก่อนเรียก
        end
    end)
end
local function stopAutoScan()
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
--  ESP — Highlight
-- ═══════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════
--  COLOR PICKER UPDATES
-- ═══════════════════════════════════════════════
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
        b.Activated:Connect(function() Cfg.filterColor=col;FLbl.Text="🎨 #"..hs;FLbl.TextColor3=col;CPop.Visible=false;UpdateCPicker() end)
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
--  SCAN (DoScan) — กำหนดค่าจริงที่นี่
-- ═══════════════════════════════════════════════
DoScan=function()
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
local function CalcTPOffset(hrp)
    local cf=hrp.CFrame
    return cf.RightVector*(TpOff.R-TpOff.L)+cf.UpVector*(TpOff.U-TpOff.D)+cf.LookVector*(TpOff.F-TpOff.B)
end
local function doTP(hrp)
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
local function startNoClip()
    if St.noClipConn then return end
    St.noClipConn=Svc.Run.Stepped:Connect(function()
        local c=LP.Character;if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
end
local function stopNoClip()
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
local function stopWing()
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
local function stopOrbit()
    if St.orbitConn then St.orbitConn:Disconnect();St.orbitConn=nil end
    Cfg.orbitOn=false;BtnOrbit.Text="🌀 หมุนรอบ : OFF";BtnOrbit.BackgroundColor3=Color3.fromRGB(30,40,70)
end
local function startOrbit()
    stopOrbit();Cfg.orbitOn=true;St.orbitAngle=0;St.orbitDir=1;St.orbitTimer=0
    BtnOrbit.Text="🌀 หมุนรอบ : ON";BtnOrbit.BackgroundColor3=Color3.fromRGB(20,50,110)
    St.orbitConn=Svc.Run.Heartbeat:Connect(function(dt)
        if not Cfg.orbitOn or not St.target or not St.target.Parent then if not St.target then stopOrbit() end;return end
        local hrp=GetRoot(St.target);if not hrp then return end
        local c=LP.Character;if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart");if not root then return end
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
local function stopFlee()
    if St.fleeConn then St.fleeConn:Disconnect();St.fleeConn=nil end
    Cfg.fleeOn=false;BtnFleeOn.Text="🏃 หนีเป้าหมาย : OFF";BtnFleeOn.BackgroundColor3=Color3.fromRGB(24,24,40)
    local c=LP.Character;if c then local hum=c:FindFirstChildOfClass("Humanoid");if hum then hum.WalkSpeed=16 end end
end
local function startFlee()
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
local function TPRefresh()
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

-- [FIX] bindTriple ใช้แค่ 5 args (ลบ arg ที่ 6 ที่ผิดออก)
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
