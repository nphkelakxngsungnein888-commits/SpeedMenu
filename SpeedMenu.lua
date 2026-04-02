-- ╔══════════════════════════════════════╗
-- ║  KUY LOCK MENU v2 - ADVANCED FULL   ║
-- ║  Lock + Radar + Color Filter        ║
-- ║  Mobile + PC Ready                  ║
-- ╚══════════════════════════════════════╝

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local CoreGui      = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═════════════════════════════════
--  STATE
-- ═════════════════════════════════
local CFG = {
    menuSize   = 10,
    radarSize  = 10,
    mode       = "Monster", -- "Player"|"Monster"
    aimPart    = "Body",    -- "Body"|"Head"
    strength   = 0.15,
    range      = 120,
    enabled    = false,
    nearest    = false,
    colorFilter = nil,      -- Color3 or nil
}

local Char, HRP, Hum
local currentTarget = nil
local lockConn      = nil
local radarSG       = nil

-- ═════════════════════════════════
--  CHARACTER
-- ═════════════════════════════════
local function refreshChar(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart", 6)
    Hum  = c:FindFirstChildOfClass("Humanoid")
end
if LP.Character then refreshChar(LP.Character) end
LP.CharacterAdded:Connect(refreshChar)

-- ═════════════════════════════════
--  HELPERS
-- ═════════════════════════════════
local function getRoot(m)   return m and m:FindFirstChild("HumanoidRootPart") end
local function getHum(m)    return m and m:FindFirstChildOfClass("Humanoid") end
local function isAlive(m)   local h=getHum(m) return h and h.Health>0 end

local function getAimPos(m)
    if CFG.aimPart == "Head" then
        local head = m:FindFirstChild("Head")
        if head then return head.Position end
    end
    local r = getRoot(m)
    return r and r.Position
end

local function colorClose(a, b)
    return math.abs(a.R-b.R)<0.06 and math.abs(a.G-b.G)<0.06 and math.abs(a.B-b.B)<0.06
end

local function toHex(c)
    return string.format("%02X%02X%02X",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

-- ═════════════════════════════════
--  TEAM COLOR
-- ═════════════════════════════════
local function teamColor(model)
    local p = Players:GetPlayerFromCharacter(model)
    if p then
        local mt = LP.Team
        if mt and p.Team == mt then return Color3.fromRGB(70,210,100) end
        if p.Team then return Color3.fromRGB(225,65,65) end
        return Color3.fromRGB(140,140,255)
    end
    return Color3.fromRGB(225,135,50)
end

-- ═════════════════════════════════
--  GET TARGET LIST
-- ═════════════════════════════════
local function getTargets()
    if not HRP then return {} end
    local list = {}
    if CFG.mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and isAlive(p.Character) then
                local r = getRoot(p.Character)
                if r then
                    local d = (r.Position - HRP.Position).Magnitude
                    if d <= CFG.range then
                        table.insert(list,{
                            model=p.Character, name=p.Name,
                            dist=d, color=teamColor(p.Character)
                        })
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Char then
                local h = getHum(obj)
                local r = getRoot(obj)
                if h and h.Health>0 and r and not Players:GetPlayerFromCharacter(obj) then
                    local d = (r.Position - HRP.Position).Magnitude
                    if d <= CFG.range then
                        table.insert(list,{
                            model=obj, name=obj.Name,
                            dist=d, color=teamColor(obj)
                        })
                    end
                end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist<b.dist end)
    if CFG.colorFilter then
        local cf = CFG.colorFilter
        local filtered = {}
        for _, e in ipairs(list) do
            if colorClose(e.color, cf) then table.insert(filtered, e) end
        end
        return filtered
    end
    return list
end

local function getNearest()
    local l = getTargets()
    return l[1] and l[1].model or nil
end

local function getLooked()
    if not HRP then return nil end
    local l = getTargets()
    local best, bestDot = nil, -1
    local cl = Camera.CFrame.LookVector
    local cp = Camera.CFrame.Position
    for _, e in ipairs(l) do
        local r = getRoot(e.model)
        if r then
            local dot = cl:Dot((r.Position-cp).Unit)
            if dot > bestDot then best=e.model bestDot=dot end
        end
    end
    return best
end

-- ═════════════════════════════════
--  LOCK ENGINE
-- ═════════════════════════════════
local targetLabel -- will be set later (forward ref)

local function setTarget(m)
    currentTarget = m
    if targetLabel then
        targetLabel.Text = m and ("🔒 "..m.Name) or "● No Target"
        targetLabel.TextColor3 = m
            and Color3.fromRGB(120,255,120)
            or Color3.fromRGB(90,90,90)
    end
end

local function startLock()
    if lockConn then lockConn:Disconnect() end

    lockConn = RunService.Heartbeat:Connect(function()
        if not HRP then return end

        -- pick target ถ้ายังไม่มีหรือตายแล้ว
        if not currentTarget or not isAlive(currentTarget) then
            setTarget(CFG.nearest and getNearest() or getLooked())
        end

        if currentTarget then
            if not isAlive(currentTarget) then
                setTarget(getNearest())
                return
            end
            local aim = getAimPos(currentTarget)
            if not aim then return end

            -- หมุนเฉพาะ HumanoidRootPart หาเป้า (กล้องจะตามอัตโนมัติ)
            -- ไม่แตะ CameraType เลย → กล้อง Roblox ทำงานปกติ
            local targetDir = Vector3.new(aim.X, HRP.Position.Y, aim.Z)
            local newCFrame = CFrame.new(HRP.Position, targetDir)
            HRP.CFrame = HRP.CFrame:Lerp(newCFrame, CFG.strength)
        end
    end)
end

local function stopLock()
    if lockConn then lockConn:Disconnect() lockConn=nil end
    setTarget(nil)
end

-- ═════════════════════════════════
--  DRAGGABLE
-- ═════════════════════════════════
local function makeDrag(frame, handle)
    local drag, ds, fs = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=i.Position fs=frame.Position
        end
    end)
    local function mv(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            frame.Position=UDim2.new(fs.X.Scale,fs.X.Offset+d.X,fs.Y.Scale,fs.Y.Offset+d.Y)
        end
    end
    handle.InputChanged:Connect(mv)
    UIS.InputChanged:Connect(mv)
    local function stop(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end
    handle.InputEnded:Connect(stop)
    UIS.InputEnded:Connect(stop)
end

-- ═════════════════════════════════
--  UI PRIMITIVES
-- ═════════════════════════════════
local function cr(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 6) end
local function sk(p,c,t) local s=Instance.new("UIStroke",p) s.Color=c or Color3.fromRGB(55,55,55) s.Thickness=t or 1 end

local function lbl(parent,text,sz,col,xa)
    local l=Instance.new("TextLabel",parent)
    l.BackgroundTransparency=1 l.Text=text
    l.TextColor3=col or Color3.fromRGB(200,200,200)
    l.TextSize=sz or 11 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    return l
end

local function btn(parent,text,sz,bg,tc)
    local b=Instance.new("TextButton",parent)
    b.BackgroundColor3=bg or Color3.fromRGB(35,35,35)
    b.BorderSizePixel=0 b.Text=text
    b.TextColor3=tc or Color3.fromRGB(220,220,220)
    b.TextSize=sz or 11 b.Font=Enum.Font.GothamBold
    b.AutoButtonColor=false cr(b,6)
    return b
end

local function inp(parent,default,sz)
    local b=Instance.new("TextBox",parent)
    b.BackgroundColor3=Color3.fromRGB(25,25,25)
    b.BorderSizePixel=0 b.Text=tostring(default)
    b.TextColor3=Color3.fromRGB(220,220,220)
    b.TextSize=sz or 11 b.Font=Enum.Font.Gotham
    b.ClearTextOnFocus=false cr(b,5) sk(b,Color3.fromRGB(50,50,50))
    return b
end

-- ═════════════════════════════════
--  MAIN GUI BUILDER
-- ═════════════════════════════════
pcall(function() CoreGui:FindFirstChild("KuyLock_v2"):Destroy() end)
local sg=Instance.new("ScreenGui",CoreGui)
sg.Name="KuyLock_v2" sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local function buildMainMenu()
    local ms = CFG.menuSize/10
    local W,H = 215*ms, 390*ms

    local mf=Instance.new("Frame",sg)
    mf.Size=UDim2.new(0,W,0,H)
    mf.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
    mf.BackgroundColor3=Color3.fromRGB(12,12,12)
    mf.BorderSizePixel=0 cr(mf,9) sk(mf,Color3.fromRGB(50,50,50))

    -- title bar
    local tb=Instance.new("Frame",mf)
    tb.Size=UDim2.new(1,0,0,28*ms)
    tb.BackgroundColor3=Color3.fromRGB(20,20,20)
    tb.BorderSizePixel=0 cr(tb,9)
    makeDrag(mf,tb)

    local tl=lbl(tb,"⚔ KuyLock v2",11*ms,Color3.fromRGB(255,255,255))
    tl.Size=UDim2.new(1,-115*ms,1,0) tl.Position=UDim2.new(0,8*ms,0,0)

    local szBox=inp(tb,"10",9*ms)
    szBox.Size=UDim2.new(0,26*ms,0,20*ms)
    szBox.Position=UDim2.new(1,-110*ms,0.5,-10*ms)

    local minB=btn(tb,"–",13*ms,Color3.fromRGB(50,50,50))
    minB.Size=UDim2.new(0,22*ms,0,20*ms)
    minB.Position=UDim2.new(1,-80*ms,0.5,-10*ms)

    local foldB=btn(tb,"▼",10*ms,Color3.fromRGB(40,40,40))
    foldB.Size=UDim2.new(0,22*ms,0,20*ms)
    foldB.Position=UDim2.new(1,-55*ms,0.5,-10*ms)

    local clsB=btn(tb,"✕",11*ms,Color3.fromRGB(190,45,45))
    clsB.Size=UDim2.new(0,22*ms,0,20*ms)
    clsB.Position=UDim2.new(1,-30*ms,0.5,-10*ms)

    local delB=btn(tb,"🗑",11*ms,Color3.fromRGB(80,28,28))
    delB.Size=UDim2.new(0,22*ms,0,20*ms)
    delB.Position=UDim2.new(1,-5*ms,0.5,-10*ms)

    -- scroll
    local sc=Instance.new("ScrollingFrame",mf)
    sc.Size=UDim2.new(1,-4*ms,1,-30*ms)
    sc.Position=UDim2.new(0,2*ms,0,29*ms)
    sc.BackgroundTransparency=1 sc.BorderSizePixel=0
    sc.ScrollBarThickness=2
    sc.ScrollBarImageColor3=Color3.fromRGB(65,65,65)
    sc.CanvasSize=UDim2.new(0,0,0,0)

    local ll=Instance.new("UIListLayout",sc)
    ll.Padding=UDim.new(0,4*ms)
    ll.SortOrder=Enum.SortOrder.LayoutOrder
    local pd=Instance.new("UIPadding",sc)
    pd.PaddingLeft=UDim.new(0,6*ms) pd.PaddingRight=UDim.new(0,6*ms)
    pd.PaddingTop=UDim.new(0,5*ms)

    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sc.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+10*ms)
    end)

    -- ── helpers ──
    local function secRow(text)
        local f=Instance.new("Frame",sc)
        f.Size=UDim2.new(1,0,0,13*ms)
        f.BackgroundTransparency=1
        local l=lbl(f,"▸ "..text,8*ms,Color3.fromRGB(110,110,110))
        l.Size=UDim2.new(1,0,1,0)
    end

    local function divRow()
        local f=Instance.new("Frame",sc)
        f.Size=UDim2.new(1,0,0,1)
        f.BackgroundColor3=Color3.fromRGB(38,38,38)
        f.BorderSizePixel=0
    end

    local function togRow(label, cb)
        local f=Instance.new("Frame",sc)
        f.Size=UDim2.new(1,0,0,26*ms)
        f.BackgroundColor3=Color3.fromRGB(19,19,19)
        f.BorderSizePixel=0 cr(f,6)

        local l=lbl(f,label,10*ms)
        l.Size=UDim2.new(1,-50*ms,1,0)
        l.Position=UDim2.new(0,8*ms,0,0)

        local state=false
        local b=btn(f,"OFF",9*ms,Color3.fromRGB(42,42,42),Color3.fromRGB(120,120,120))
        b.Size=UDim2.new(0,40*ms,0,18*ms)
        b.Position=UDim2.new(1,-46*ms,0.5,-9*ms)

        local function ref()
            if state then
                b.BackgroundColor3=Color3.fromRGB(240,240,240)
                b.TextColor3=Color3.fromRGB(10,10,10)
                b.Text="ON"
            else
                b.BackgroundColor3=Color3.fromRGB(42,42,42)
                b.TextColor3=Color3.fromRGB(120,120,120)
                b.Text="OFF"
            end
        end
        b.MouseButton1Click:Connect(function()
            state=not state ref() cb(state)
        end)
        return f, function(v) state=v ref() end
    end

    local function inpRow(label, default, cb)
        local f=Instance.new("Frame",sc)
        f.Size=UDim2.new(1,0,0,26*ms)
        f.BackgroundColor3=Color3.fromRGB(19,19,19)
        f.BorderSizePixel=0 cr(f,6)

        local l=lbl(f,label,9*ms)
        l.Size=UDim2.new(0.55,0,1,0)
        l.Position=UDim2.new(0,8*ms,0,0)

        local b=inp(f,default,9*ms)
        b.Size=UDim2.new(0.38,0,0,18*ms)
        b.Position=UDim2.new(0.58,0,0.5,-9*ms)
        b.FocusLost:Connect(function()
            local v=tonumber(b.Text)
            if v then cb(v) else b.Text=tostring(default) end
        end)
    end

    local function modeRow2(opts, default, cb)
        local f=Instance.new("Frame",sc)
        f.Size=UDim2.new(1,0,0,26*ms)
        f.BackgroundTransparency=1
        local cur=default
        local bts={}
        local w=1/#opts
        for i,opt in ipairs(opts) do
            local b=btn(f,opt,9*ms)
            b.Size=UDim2.new(w,-3*ms,1,0)
            b.Position=UDim2.new((i-1)*w,2*ms,0,0)
            table.insert(bts,{b=b,v=opt})
            b.MouseButton1Click:Connect(function()
                cur=opt
                for _,d in ipairs(bts) do
                    d.b.BackgroundColor3=d.v==cur and Color3.fromRGB(230,230,230) or Color3.fromRGB(35,35,35)
                    d.b.TextColor3=d.v==cur and Color3.fromRGB(12,12,12) or Color3.fromRGB(175,175,175)
                end
                cb(opt)
            end)
        end
        for _,d in ipairs(bts) do
            d.b.BackgroundColor3=d.v==cur and Color3.fromRGB(230,230,230) or Color3.fromRGB(35,35,35)
            d.b.TextColor3=d.v==cur and Color3.fromRGB(12,12,12) or Color3.fromRGB(175,175,175)
        end
    end

    -- ── status label ──
    local stRow=Instance.new("Frame",sc)
    stRow.Size=UDim2.new(1,0,0,22*ms)
    stRow.BackgroundColor3=Color3.fromRGB(16,16,16) stRow.BorderSizePixel=0 cr(stRow,6)
    targetLabel=lbl(stRow,"● No Target",9*ms,Color3.fromRGB(85,85,85))
    targetLabel.Size=UDim2.new(1,-10*ms,1,0)
    targetLabel.Position=UDim2.new(0,8*ms,0,0)

    -- ── build sections ──
    secRow("TARGET MODE")
    modeRow2({"Player","Monster"}, CFG.mode, function(v)
        CFG.mode=v currentTarget=nil setTarget(nil)
    end)

    divRow()
    secRow("AIM PART")
    modeRow2({"Body","Head"}, CFG.aimPart, function(v)
        CFG.aimPart=v
    end)

    divRow()
    secRow("LOCK SETTINGS")
    togRow("🔒 Lock Enable", function(v)
        CFG.enabled=v
        if v then startLock() else stopLock() end
    end)
    togRow("📍 Auto Nearest", function(v)
        CFG.nearest=v
    end)
    inpRow("⚡ Strength (0.01–1)", CFG.strength, function(v)
        CFG.strength=math.clamp(v,0.01,1)
    end)
    inpRow("📏 Range (studs)", CFG.range, function(v)
        CFG.range=math.max(1,v)
    end)

    divRow()
    secRow("SWITCH TARGET")
    local navF=Instance.new("Frame",sc)
    navF.Size=UDim2.new(1,0,0,26*ms) navF.BackgroundTransparency=1
    local pvB=btn(navF,"◀ Prev",9*ms,Color3.fromRGB(32,32,32))
    pvB.Size=UDim2.new(0.48,0,1,0) pvB.Position=UDim2.new(0,0,0,0)
    local nxB=btn(navF,"Next ▶",9*ms,Color3.fromRGB(32,32,32))
    nxB.Size=UDim2.new(0.48,0,1,0) nxB.Position=UDim2.new(0.52,0,0,0)

    pvB.MouseButton1Click:Connect(function()
        local l=getTargets()
        if #l==0 then return end
        local idx=1
        for i,e in ipairs(l) do if e.model==currentTarget then idx=i break end end
        idx=idx-1 if idx<1 then idx=#l end
        setTarget(l[idx].model)
    end)
    nxB.MouseButton1Click:Connect(function()
        local l=getTargets()
        if #l==0 then return end
        local idx=1
        for i,e in ipairs(l) do if e.model==currentTarget then idx=i break end end
        idx=idx+1 if idx>#l then idx=1 end
        setTarget(l[idx].model)
    end)

    divRow()
    stRow.Parent=nil stRow.Parent=sc

    divRow()
    secRow("RADAR")
    local _, setRadarToggle
    _, setRadarToggle = togRow("🔍 Open Radar Menu", function(v)
        if v then
            buildRadarMenu()
        else
            if radarSG then pcall(function() radarSG:Destroy() end) radarSG=nil end
        end
    end)

    -- ── title bar logic ──
    szBox.FocusLost:Connect(function()
        local v=tonumber(szBox.Text)
        if v then
            v=math.max(1,v) CFG.menuSize=v
            local ns=v/10
            mf.Size=UDim2.new(0,215*ns,0,390*ns)
        end
    end)

    local minimized=false
    local folded=false

    minB.MouseButton1Click:Connect(function()
        minimized=not minimized
        sc.Visible=not minimized
        mf.Size=minimized and UDim2.new(0,mf.Size.X.Offset,0,28*ms)
            or UDim2.new(0,215*ms,0,390*ms)
        minB.Text=minimized and "▲" or "–"
    end)

    foldB.MouseButton1Click:Connect(function()
        sc.Visible=not sc.Visible
        foldB.Text=sc.Visible and "▼" or "▶"
    end)

    clsB.MouseButton1Click:Connect(function()
        mf:Destroy()
    end)

    delB.MouseButton1Click:Connect(function()
        stopLock()
        if radarSG then pcall(function() radarSG:Destroy() end) end
        sg:Destroy()
    end)
end

-- ═════════════════════════════════
--  RADAR MENU
-- ═════════════════════════════════
function buildRadarMenu()
    if radarSG then pcall(function() radarSG:Destroy() end) end
    radarSG=Instance.new("ScreenGui",CoreGui)
    radarSG.Name="KuyRadar_v2"
    radarSG.ResetOnSpawn=false
    radarSG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

    local rs=CFG.radarSize/10
    local RW,RH=205*rs,340*rs

    local rf=Instance.new("Frame",radarSG)
    rf.Size=UDim2.new(0,RW,0,RH)
    rf.Position=UDim2.new(0.5,20,0.5,-RH/2)
    rf.BackgroundColor3=Color3.fromRGB(11,11,11)
    rf.BorderSizePixel=0 cr(rf,9) sk(rf,Color3.fromRGB(50,50,50))

    -- title
    local rtb=Instance.new("Frame",rf)
    rtb.Size=UDim2.new(1,0,0,26*rs)
    rtb.BackgroundColor3=Color3.fromRGB(19,19,19)
    rtb.BorderSizePixel=0 cr(rtb,9)
    makeDrag(rf,rtb)

    local rtl=lbl(rtb,"🔍 Radar",10*rs,Color3.fromRGB(255,255,255))
    rtl.Size=UDim2.new(1,-105*rs,1,0) rtl.Position=UDim2.new(0,7*rs,0,0)

    local rszBox=inp(rtb,"10",9*rs)
    rszBox.Size=UDim2.new(0,24*rs,0,18*rs)
    rszBox.Position=UDim2.new(1,-100*rs,0.5,-9*rs)

    local rMinB=btn(rtb,"–",12*rs,Color3.fromRGB(50,50,50))
    rMinB.Size=UDim2.new(0,20*rs,0,18*rs)
    rMinB.Position=UDim2.new(1,-73*rs,0.5,-9*rs)

    local rFoldB=btn(rtb,"▼",9*rs,Color3.fromRGB(40,40,40))
    rFoldB.Size=UDim2.new(0,20*rs,0,18*rs)
    rFoldB.Position=UDim2.new(1,-50*rs,0.5,-9*rs)

    local rClsB=btn(rtb,"✕",10*rs,Color3.fromRGB(190,45,45))
    rClsB.Size=UDim2.new(0,20*rs,0,18*rs)
    rClsB.Position=UDim2.new(1,-27*rs,0.5,-9*rs)

    local rDelB=btn(rtb,"🗑",10*rs,Color3.fromRGB(80,28,28))
    rDelB.Size=UDim2.new(0,20*rs,0,18*rs)
    rDelB.Position=UDim2.new(1,-4*rs,0.5,-9*rs)

    -- body
    local rbody=Instance.new("Frame",rf)
    rbody.Size=UDim2.new(1,-4*rs,1,-28*rs)
    rbody.Position=UDim2.new(0,2*rs,0,27*rs)
    rbody.BackgroundTransparency=1

    -- mode selector
    local modeSel=Instance.new("Frame",rbody)
    modeSel.Size=UDim2.new(1,-8*rs,0,24*rs)
    modeSel.Position=UDim2.new(0,4*rs,0,2*rs)
    modeSel.BackgroundTransparency=1

    local mPlayer=btn(modeSel,"👤 Player",9*rs,Color3.fromRGB(35,35,35))
    mPlayer.Size=UDim2.new(0.48,0,1,0) mPlayer.Position=UDim2.new(0,0,0,0)
    local mMonster=btn(modeSel,"🤖 Monster",9*rs,Color3.fromRGB(230,230,230),Color3.fromRGB(12,12,12))
    mMonster.Size=UDim2.new(0.48,0,1,0) mMonster.Position=UDim2.new(0.52,0,0,0)

    local function updateModeStyle()
        mPlayer.BackgroundColor3=CFG.mode=="Player" and Color3.fromRGB(230,230,230) or Color3.fromRGB(35,35,35)
        mPlayer.TextColor3=CFG.mode=="Player" and Color3.fromRGB(12,12,12) or Color3.fromRGB(175,175,175)
        mMonster.BackgroundColor3=CFG.mode=="Monster" and Color3.fromRGB(230,230,230) or Color3.fromRGB(35,35,35)
        mMonster.TextColor3=CFG.mode=="Monster" and Color3.fromRGB(12,12,12) or Color3.fromRGB(175,175,175)
    end
    updateModeStyle()
    mPlayer.MouseButton1Click:Connect(function() CFG.mode="Player" updateModeStyle() end)
    mMonster.MouseButton1Click:Connect(function() CFG.mode="Monster" updateModeStyle() end)

    -- scan btn
    local scanB=btn(rbody,"▶ SCAN NOW",10*rs,Color3.fromRGB(30,65,30))
    scanB.Size=UDim2.new(1,-8*rs,0,24*rs)
    scanB.Position=UDim2.new(0,4*rs,0,30*rs)

    -- found + filter row
    local infoF=Instance.new("Frame",rbody)
    infoF.Size=UDim2.new(1,-8*rs,0,18*rs)
    infoF.Position=UDim2.new(0,4*rs,0,58*rs)
    infoF.BackgroundTransparency=1

    local foundLbl=lbl(infoF,"0 found",8*rs,Color3.fromRGB(90,90,90))
    foundLbl.Size=UDim2.new(0.5,0,1,0)

    local clearFBtn=btn(infoF,"✕ All Colors",7*rs,Color3.fromRGB(35,35,35),Color3.fromRGB(160,160,160))
    clearFBtn.Size=UDim2.new(0.46,0,1,0)
    clearFBtn.Position=UDim2.new(0.52,0,0,0)

    -- color dots row
    local colorRow=Instance.new("Frame",rbody)
    colorRow.Size=UDim2.new(1,-8*rs,0,18*rs)
    colorRow.Position=UDim2.new(0,4*rs,0,80*rs)
    colorRow.BackgroundTransparency=1

    local colorLayout=Instance.new("UIListLayout",colorRow)
    colorLayout.FillDirection=Enum.FillDirection.Horizontal
    colorLayout.Padding=UDim.new(0,3*rs)

    -- scroll list
    local scroll=Instance.new("ScrollingFrame",rbody)
    scroll.Size=UDim2.new(1,-4*rs,1,-104*rs)
    scroll.Position=UDim2.new(0,2*rs,0,102*rs)
    scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=2
    scroll.ScrollBarImageColor3=Color3.fromRGB(65,65,65)
    scroll.CanvasSize=UDim2.new(0,0,0,0)

    local sll=Instance.new("UIListLayout",scroll)
    sll.Padding=UDim.new(0,3*rs)
    sll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize=UDim2.new(0,0,0,sll.AbsoluteContentSize.Y+8)
    end)

    local knownColors={}
    local colorDotBtns={}
    local selectedColors={} -- multi-color support

    local function refreshColorDots()
        for _,b in ipairs(colorDotBtns) do pcall(function() b:Destroy() end) end
        colorDotBtns={}
        for hex,col in pairs(knownColors) do
            local dotB=Instance.new("TextButton",colorRow)
            dotB.Size=UDim2.new(0,16*rs,1,0)
            dotB.BackgroundColor3=col dotB.BorderSizePixel=0
            dotB.Text="" dotB.AutoButtonColor=false cr(dotB,10)
            table.insert(colorDotBtns,dotB)
            -- toggle selection
            dotB.MouseButton1Click:Connect(function()
                if selectedColors[hex] then
                    selectedColors[hex]=nil
                    for _,ch in ipairs(dotB:GetChildren()) do
                        if ch:IsA("UIStroke") then ch:Destroy() end
                    end
                else
                    selectedColors[hex]=col
                    local s2=Instance.new("UIStroke",dotB)
                    s2.Color=Color3.fromRGB(255,255,255) s2.Thickness=1.5
                end
                -- apply filter: any selected color
                local count=0
                for _ in pairs(selectedColors) do count=count+1 end
                if count==0 then
                    CFG.colorFilter=nil
                else
                    -- use first selected for now (multi-filter via scan rebuild)
                    for _,c2 in pairs(selectedColors) do CFG.colorFilter=c2 break end
                end
            end)
        end
    end

    clearFBtn.MouseButton1Click:Connect(function()
        selectedColors={} CFG.colorFilter=nil
        for _,b in ipairs(colorDotBtns) do
            for _,ch in ipairs(b:GetChildren()) do
                if ch:IsA("UIStroke") then ch:Destroy() end
            end
        end
    end)

    local function doScan()
        for _,c in ipairs(scroll:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        knownColors={}
        local list=getTargets()
        foundLbl.Text=#list.." found"

        for _,e in ipairs(list) do
            local hex=toHex(e.color)
            if not knownColors[hex] then knownColors[hex]=e.color end

            -- row
            local row=Instance.new("TextButton",scroll)
            row.Size=UDim2.new(1,0,0,26*rs)
            row.BackgroundColor3=Color3.fromRGB(19,19,19)
            row.BorderSizePixel=0 row.Text=""
            row.AutoButtonColor=false cr(row,5)
            sk(row,Color3.fromRGB(40,40,40))

            local dot=Instance.new("Frame",row)
            dot.Size=UDim2.new(0,7*rs,0,7*rs)
            dot.Position=UDim2.new(0,5*rs,0.5,-3.5*rs)
            dot.BackgroundColor3=e.color dot.BorderSizePixel=0 cr(dot,10)

            local nl=lbl(row,e.name,9*rs,e.color)
            nl.Size=UDim2.new(0.58,0,1,0) nl.Position=UDim2.new(0,16*rs,0,0)

            local dl=lbl(row,math.floor(e.dist).."m",8*rs,Color3.fromRGB(100,100,100),Enum.TextXAlignment.Right)
            dl.Size=UDim2.new(0.35,0,1,0) dl.Position=UDim2.new(0.62,0,0,0)

            local cap=e
            row.MouseButton1Click:Connect(function()
                setTarget(cap.model)
            end)
        end
        refreshColorDots()
    end

    scanB.MouseButton1Click:Connect(doScan)

    -- title bar actions
    rszBox.FocusLost:Connect(function()
        local v=tonumber(rszBox.Text)
        if v then
            v=math.max(1,v) CFG.radarSize=v
            local ns=v/10
            rf.Size=UDim2.new(0,205*ns,0,340*ns)
        end
    end)

    local rMin=false
    rMinB.MouseButton1Click:Connect(function()
        rMin=not rMin rbody.Visible=not rMin
        rf.Size=rMin and UDim2.new(0,rf.Size.X.Offset,0,26*rs)
            or UDim2.new(0,205*rs,0,340*rs)
        rMinB.Text=rMin and "▲" or "–"
    end)

    rFoldB.MouseButton1Click:Connect(function()
        rbody.Visible=not rbody.Visible
        rFoldB.Text=rbody.Visible and "▼" or "▶"
    end)

    rClsB.MouseButton1Click:Connect(function()
        radarSG:Destroy() radarSG=nil
    end)

    rDelB.MouseButton1Click:Connect(function()
        radarSG:Destroy() radarSG=nil
    end)
end

-- ═════════════════════════════════
--  START
-- ═════════════════════════════════
buildMainMenu()
print("[KuyLock v2] Loaded ✓")
