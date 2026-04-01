--// SERVICES
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")

local plr    = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================================
--  STATE
-- ============================================================
local lockOn      = false
local nearOn      = false
local lockMode    = "Player"
local locked      = nil
local lockConn    = nil
local lockStr     = 1
local detRange    = 500
local selColors   = {}

-- ============================================================
--  GAME UTILS
-- ============================================================
local function hrp(m)   return m and m:FindFirstChild("HumanoidRootPart") end
local function alive(m)
    if not m then return false end
    local h = m:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function dist(m)
    local c = plr.Character
    if not c then return math.huge end
    local a = c:FindFirstChild("HumanoidRootPart")
    local b = hrp(m)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

local function buildList()
    local out = {}
    if lockMode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= plr and p.Character and alive(p.Character)
                and dist(p.Character) <= detRange then
                table.insert(out, {
                    model = p.Character, name = p.Name,
                    team = p.Team, isPlayer = true })
            end
        end
    else
        local pc = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then pc[p.Character] = true end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not pc[obj]
                and obj:FindFirstChildOfClass("Humanoid")
                and obj:FindFirstChild("HumanoidRootPart")
                and alive(obj) and dist(obj) <= detRange then
                table.insert(out, {
                    model = obj, name = obj.Name,
                    team = nil, isPlayer = false })
            end
        end
    end
    return out
end

local function frontTarget(list)
    local best, bd = nil, -math.huge
    local cf = camera.CFrame
    for _, t in ipairs(list) do
        local r = hrp(t.model)
        if r then
            local dot = cf.LookVector:Dot((r.Position - cf.Position).Unit)
            if dot > bd then bd = dot; best = t end
        end
    end
    return best
end

local function nearTarget(list)
    local best, bd = nil, math.huge
    for _, t in ipairs(list) do
        local d = dist(t.model)
        if d < bd then bd = d; best = t end
    end
    return best
end

local function startLock()
    if lockConn then lockConn:Disconnect() end
    local list = buildList()
    locked = nearOn and nearTarget(list) or frontTarget(list)

    lockConn = RunService.RenderStepped:Connect(function()
        if not lockOn then return end
        local char = plr.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if not locked or not alive(locked.model) then
            locked = nearTarget(buildList())
            if not locked then return end
        end

        local tr = hrp(locked.model)
        if not tr then locked = nil; return end

        local flat = (tr.Position - root.Position) * Vector3.new(1,0,1)
        if flat.Magnitude > 0.1 then
            local a = math.clamp(lockStr * 0.1, 0.01, 1)
            root.CFrame = root.CFrame:Lerp(
                CFrame.lookAt(root.Position, root.Position + flat), a)
        end
    end)
end

local function stopLock()
    if lockConn then lockConn:Disconnect(); lockConn = nil end
    locked = nil
end

-- ============================================================
--  THEME
-- ============================================================
local FB = Enum.Font.GothamBold
local FL = Enum.Font.Gotham

local cBG     = Color3.fromRGB(11,11,11)
local cPanel  = Color3.fromRGB(19,19,19)
local cBorder = Color3.fromRGB(42,42,42)
local cWhite  = Color3.fromRGB(228,228,228)
local cGray   = Color3.fromRGB(115,115,115)
local cBtn    = Color3.fromRGB(26,26,26)
local cHov    = Color3.fromRGB(42,42,42)
local cOn     = Color3.fromRGB(198,198,198)
local cOff    = Color3.fromRGB(48,48,48)

-- ============================================================
--  UI HELPERS
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AimUI_v3"; gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true; gui.Parent = game.CoreGui

local function co(p,r)  local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 6) end
local function sk(p,c,t) local s=Instance.new("UIStroke",p);s.Color=c or cBorder;s.Thickness=t or 1 end

local function makeDrag(win, handle)
    local on,ds,sp = false,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            on=true; ds=i.Position; sp=win.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then on=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and (i.UserInputType==Enum.UserInputType.MouseMovement
                or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,
                                   sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

local function mkLabel(p,txt,sz,col,font,xa)
    local l=Instance.new("TextLabel",p)
    l.BackgroundTransparency=1; l.Text=txt; l.TextSize=sz or 12
    l.TextColor3=col or cWhite; l.Font=font or FL
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center
    return l
end

local function mkBtn(p,txt,cb)
    local b=Instance.new("TextButton",p)
    b.BackgroundColor3=cBtn; b.TextColor3=cWhite
    b.Text=txt; b.Font=FB; b.TextSize=12; b.AutoButtonColor=false
    co(b,5); sk(b,cBorder)
    b.MouseEnter:Connect(function() TS:Create(b,TweenInfo.new(0.12),{BackgroundColor3=cHov}):Play() end)
    b.MouseLeave:Connect(function() TS:Create(b,TweenInfo.new(0.12),{BackgroundColor3=cBtn}):Play() end)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function mkIcon(p,txt,cb)
    local b=Instance.new("TextButton",p)
    b.BackgroundTransparency=1; b.Text=txt
    b.TextColor3=cGray; b.Font=FB; b.TextSize=13; b.AutoButtonColor=false
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function mkInput(p,val)
    local b=Instance.new("TextBox",p)
    b.BackgroundColor3=Color3.fromRGB(7,7,7); b.TextColor3=cWhite
    b.Text=tostring(val); b.Font=FL; b.TextSize=12
    b.ClearTextOnFocus=false; b.TextXAlignment=Enum.TextXAlignment.Center
    co(b,4); sk(b,cBorder)
    return b
end

local function mkToggle(p,init,cb)
    local track=Instance.new("Frame",p)
    track.Size=UDim2.new(0,36,0,18)
    track.BackgroundColor3=init and cOn or cOff; co(track,9)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,12,0,12); knob.BackgroundColor3=cWhite; co(knob,6)
    knob.Position=init and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
    local state=init
    local hit=Instance.new("TextButton",track)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""
    hit.MouseButton1Click:Connect(function()
        state=not state
        TS:Create(track,TweenInfo.new(0.15),{BackgroundColor3=state and cOn or cOff}):Play()
        TS:Create(knob, TweenInfo.new(0.15),
            {Position=state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}):Play()
        cb(state)
    end)
    return track
end

local function mkSep(p,order)
    local f=Instance.new("Frame",p)
    f.BackgroundColor3=cBorder; f.BorderSizePixel=0
    f.Size=UDim2.new(1,-16,0,1); f.Position=UDim2.new(0,8,0,0)
    f.LayoutOrder=order or 0
    return f
end

-- ============================================================
--  WINDOW BUILDER
--  w, h = pixel size  |  returns (win, titleBar, bodyScroll)
-- ============================================================
local function newWindow(title, x, y, w, h)
    local win=Instance.new("Frame",gui)
    win.BackgroundColor3=cBG
    win.Position=UDim2.new(0,x,0,y)
    win.Size=UDim2.new(0,w,0,h)
    co(win,8); sk(win,cBorder)

    -- title bar
    local bar=Instance.new("Frame",win)
    bar.BackgroundColor3=cPanel
    bar.Size=UDim2.new(1,0,0,30)
    co(bar,8)
    -- patch bottom corners of bar
    local patch=Instance.new("Frame",win)
    patch.BackgroundColor3=cPanel; patch.BorderSizePixel=0
    patch.Size=UDim2.new(1,0,0,8); patch.Position=UDim2.new(0,0,0,22)

    mkLabel(bar,"  ◈  "..title,12,cWhite,FB).Size=UDim2.new(1,-110,1,0)
    makeDrag(win,bar)

    -- scrollable body
    local scroll=Instance.new("ScrollingFrame",win)
    scroll.BackgroundTransparency=1
    scroll.Position=UDim2.new(0,0,0,30)
    scroll.Size=UDim2.new(1,0,1,-30)
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.ScrollBarThickness=3
    scroll.ScrollBarImageColor3=cBorder
    scroll.BorderSizePixel=0
    scroll.ScrollingDirection=Enum.ScrollingDirection.Y

    local lyt=Instance.new("UIListLayout",scroll)
    lyt.SortOrder=Enum.SortOrder.LayoutOrder; lyt.Padding=UDim.new(0,0)

    local pad=Instance.new("UIPadding",scroll)
    pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
    pad.PaddingTop=UDim.new(0,8);   pad.PaddingBottom=UDim.new(0,8)

    return win, bar, scroll
end

-- simple row frame inside a scroll
local function mkRow(scroll,h,order)
    local f=Instance.new("Frame",scroll)
    f.BackgroundTransparency=1
    f.Size=UDim2.new(1,0,0,h or 32)
    f.LayoutOrder=order or 0
    return f
end

-- ============================================================
--  MAIN WINDOW
-- ============================================================
local mWin, mBar, mScroll = newWindow("LOCK", 20, 80, 192, 308)

-- titlebar: scale box + collapse + close
local mScaleBox = mkInput(mBar, "10")
mScaleBox.Size=UDim2.new(0,26,0,18); mScaleBox.Position=UDim2.new(1,-92,0.5,-9)
mScaleBox.FocusLost:Connect(function()
    local v=tonumber(mScaleBox.Text)
    if v then mWin.Size=UDim2.new(0,math.max(v*18,140),0,mWin.Size.Y.Offset) end
end)

local mColl=false
local mColIcon=mkIcon(mBar,"─")
mColIcon.Size=UDim2.new(0,20,0,20); mColIcon.Position=UDim2.new(1,-56,0.5,-10)
mColIcon.MouseButton1Click:Connect(function()
    mColl=not mColl; mScroll.Visible=not mColl
    mColIcon.Text=mColl and "□" or "─"
    mWin.Size=UDim2.new(0,mWin.Size.X.Offset,0,mColl and 30 or 308)
end)

local mXIcon=mkIcon(mBar,"✕",function() mWin:Destroy() end)
mXIcon.Size=UDim2.new(0,20,0,20); mXIcon.Position=UDim2.new(1,-30,0.5,-10)

-- ── MODE ──
local r1=mkRow(mScroll,32,1)
mkLabel(r1,"Mode",12,cGray).Size=UDim2.new(0.36,0,1,0)
local pBtn=mkBtn(r1,"Player"); pBtn.Size=UDim2.new(0.30,-2,0,22); pBtn.Position=UDim2.new(0.36,0,0.5,-11)
local nBtn=mkBtn(r1,"NPC");    nBtn.Size=UDim2.new(0.30,-2,0,22); nBtn.Position=UDim2.new(0.68,2,0.5,-11)
local function refreshMode()
    pBtn.BackgroundColor3=lockMode=="Player" and Color3.fromRGB(48,48,48) or cBtn
    nBtn.BackgroundColor3=lockMode=="NPC"    and Color3.fromRGB(48,48,48) or cBtn
end; refreshMode()
pBtn.MouseButton1Click:Connect(function() lockMode="Player"; refreshMode() end)
nBtn.MouseButton1Click:Connect(function() lockMode="NPC";    refreshMode() end)

mkSep(mScroll,2)

-- ── LOCK TARGET ──
local r2=mkRow(mScroll,32,3)
mkLabel(r2,"Lock Target",12,cGray).Size=UDim2.new(0.65,0,1,0)
local lkSw=mkToggle(r2,false,function(s)
    lockOn=s; if s then startLock() else stopLock() end
end); lkSw.Position=UDim2.new(1,-38,0.5,-9)

-- ── LOCK NEAREST ──
local r3=mkRow(mScroll,32,4)
mkLabel(r3,"Lock Nearest",12,cGray).Size=UDim2.new(0.65,0,1,0)
local nearSw=mkToggle(r3,false,function(s) nearOn=s end)
nearSw.Position=UDim2.new(1,-38,0.5,-9)

mkSep(mScroll,5)

-- ── LOCK STRENGTH ──
local r4=mkRow(mScroll,32,6)
mkLabel(r4,"Lock Strength",12,cGray).Size=UDim2.new(0.62,0,1,0)
local strBox=mkInput(r4,lockStr)
strBox.Size=UDim2.new(0,54,0,22); strBox.Position=UDim2.new(1,-56,0.5,-11)
strBox.FocusLost:Connect(function() local v=tonumber(strBox.Text); if v then lockStr=v end end)

-- ── DETECT RANGE ──
local r5=mkRow(mScroll,32,7)
mkLabel(r5,"Detect Range",12,cGray).Size=UDim2.new(0.62,0,1,0)
local rngBox=mkInput(r5,detRange)
rngBox.Size=UDim2.new(0,54,0,22); rngBox.Position=UDim2.new(1,-56,0.5,-11)
rngBox.FocusLost:Connect(function() local v=tonumber(rngBox.Text); if v then detRange=v end end)

mkSep(mScroll,8)

-- ── SCAN MENU TOGGLE ──
local r6=mkRow(mScroll,32,9)
mkLabel(r6,"Scan Menu",12,cGray).Size=UDim2.new(0.65,0,1,0)
local scanSw=mkToggle(r6,false,function(s)
    if scanWin then scanWin.Visible=s end
end); scanSw.Position=UDim2.new(1,-38,0.5,-9)

-- ============================================================
--  SCAN WINDOW
-- ============================================================
local scanWin, sBar, sScroll = newWindow("SCAN", 222, 80, 215, 328)
scanWin.Visible=false

-- titlebar controls
local sScaleBox=mkInput(sBar,"10")
sScaleBox.Size=UDim2.new(0,26,0,18); sScaleBox.Position=UDim2.new(1,-116,0.5,-9)
sScaleBox.FocusLost:Connect(function()
    local v=tonumber(sScaleBox.Text)
    if v then scanWin.Size=UDim2.new(0,math.max(v*20,160),0,scanWin.Size.Y.Offset) end
end)

local clrOpen=false
local clrIcon=mkIcon(sBar,"◐")
clrIcon.Size=UDim2.new(0,20,0,20); clrIcon.Position=UDim2.new(1,-86,0.5,-10)

local sColl=false
local sColIcon=mkIcon(sBar,"─")
sColIcon.Size=UDim2.new(0,20,0,20); sColIcon.Position=UDim2.new(1,-56,0.5,-10)
sColIcon.MouseButton1Click:Connect(function()
    sColl=not sColl; sScroll.Visible=not sColl
    sColIcon.Text=sColl and "□" or "─"
    scanWin.Size=UDim2.new(0,scanWin.Size.X.Offset,0,sColl and 30 or 328)
end)

local sXIcon=mkIcon(sBar,"✕",function() scanWin:Destroy() end)
sXIcon.Size=UDim2.new(0,20,0,20); sXIcon.Position=UDim2.new(1,-30,0.5,-10)

-- ── SCAN BUTTON ROW ──
local sr1=mkRow(sScroll,32,1)
local scanBtn=mkBtn(sr1,"▶  SCAN")
scanBtn.Size=UDim2.new(1,0,0,24); scanBtn.Position=UDim2.new(0,0,0.5,-12)

-- ── COLOR FILTER ROW ──
local sr2=mkRow(sScroll,28,2); sr2.Visible=false
local clrHolder=Instance.new("Frame",sr2)
clrHolder.BackgroundTransparency=1; clrHolder.Size=UDim2.new(1,0,1,0)
local clrLyt=Instance.new("UIListLayout",clrHolder)
clrLyt.FillDirection=Enum.FillDirection.Horizontal
clrLyt.Padding=UDim.new(0,4)
clrLyt.VerticalAlignment=Enum.VerticalAlignment.Center

clrIcon.MouseButton1Click:Connect(function()
    clrOpen=not clrOpen; sr2.Visible=clrOpen
end)

-- ── RESULT LIST ──
local sr3=mkRow(sScroll,238,3)
local rScroll=Instance.new("ScrollingFrame",sr3)
rScroll.BackgroundTransparency=1; rScroll.Size=UDim2.new(1,0,1,0)
rScroll.CanvasSize=UDim2.new(0,0,0,0)
rScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
rScroll.ScrollBarThickness=3; rScroll.ScrollBarImageColor3=cBorder
rScroll.BorderSizePixel=0; rScroll.ScrollingDirection=Enum.ScrollingDirection.Y
local rLyt=Instance.new("UIListLayout",rScroll)
rLyt.SortOrder=Enum.SortOrder.LayoutOrder; rLyt.Padding=UDim.new(0,2)

-- team color helper
local function tCol(e)
    if e.isPlayer and e.team then return e.team.TeamColor.Color
    elseif not e.isPlayer      then return Color3.fromRGB(210,50,50)
    else                            return Color3.fromRGB(145,145,145) end
end
local function ceq(a,b)
    return math.abs(a.R-b.R)<0.06 and math.abs(a.G-b.G)<0.06 and math.abs(a.B-b.B)<0.06
end

-- ── SCAN ACTION ──
local function doScan()
    for _,c in ipairs(rScroll:GetChildren())  do if not c:IsA("UIListLayout") then c:Destroy() end end
    for _,c in ipairs(clrHolder:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    selColors={}

    local list=buildList()
    local foundCols={}
    local groups={}

    for _,e in ipairs(list) do
        local key=e.isPlayer and (e.team and "Team: "..e.team.Name or "Neutral") or "NPC / Monster"
        if not groups[key] then groups[key]={entries={},color=tCol(e)} end
        table.insert(groups[key].entries,e)
        local c=tCol(e); local found=false
        for _,fc in ipairs(foundCols) do if ceq(fc,c) then found=true;break end end
        if not found then table.insert(foundCols,c) end
    end

    -- color picker dots
    for _,fc in ipairs(foundCols) do
        local cb=Instance.new("TextButton",clrHolder)
        cb.Size=UDim2.new(0,18,0,18); cb.BackgroundColor3=fc
        cb.Text=""; cb.AutoButtonColor=false; co(cb,4); sk(cb,cBorder)
        local sel=false
        cb.MouseButton1Click:Connect(function()
            sel=not sel
            for _,s in ipairs(cb:GetChildren()) do if s:IsA("UIStroke") then s:Destroy() end end
            sk(cb,sel and cWhite or cBorder,sel and 2 or 1)
            if sel then table.insert(selColors,fc)
            else
                for i,sc in ipairs(selColors) do if ceq(sc,fc) then table.remove(selColors,i);break end end
            end
        end)
    end

    -- result rows
    local ord=0
    for gname,gd in pairs(groups) do
        if #selColors>0 then
            local show=false
            for _,sc in ipairs(selColors) do if ceq(sc,gd.color) then show=true;break end end
            if not show then continue end
        end

        -- header
        local hf=Instance.new("Frame",rScroll)
        hf.BackgroundColor3=Color3.fromRGB(20,20,20)
        hf.Size=UDim2.new(1,0,0,20); hf.LayoutOrder=ord; ord=ord+1; co(hf,4)
        local dot=Instance.new("Frame",hf)
        dot.Size=UDim2.new(0,5,0,5); dot.Position=UDim2.new(0,5,0.5,-2.5)
        dot.BackgroundColor3=gd.color; co(dot,3)
        local hl=mkLabel(hf,"   "..gname,10,cGray,FB)
        hl.Size=UDim2.new(1,-12,1,0); hl.Position=UDim2.new(0,12,0,0)

        -- entries
        for _,e in ipairs(gd.entries) do
            local eb=Instance.new("TextButton",rScroll)
            eb.BackgroundColor3=Color3.fromRGB(16,16,16)
            eb.Size=UDim2.new(1,0,0,26); eb.LayoutOrder=ord; ord=ord+1
            eb.Text=""; eb.AutoButtonColor=false; co(eb,4)

            local bar2=Instance.new("Frame",eb)
            bar2.Size=UDim2.new(0,3,0.6,0); bar2.Position=UDim2.new(0,0,0.2,0)
            bar2.BackgroundColor3=gd.color; co(bar2,2)

            local nl=mkLabel(eb,"  "..e.name,12,Color3.fromRGB(222,222,222))
            nl.Size=UDim2.new(0.65,0,1,0); nl.Position=UDim2.new(0,5,0,0)

            local dl=mkLabel(eb,math.floor(dist(e.model)).."m",11,cGray,FL,Enum.TextXAlignment.Right)
            dl.Size=UDim2.new(0.32,0,1,0); dl.Position=UDim2.new(0.66,0,0,0)

            eb.MouseEnter:Connect(function()
                TS:Create(eb,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(26,26,26)}):Play()
            end)
            eb.MouseLeave:Connect(function()
                TS:Create(eb,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(16,16,16)}):Play()
            end)
            eb.MouseButton1Click:Connect(function()
                locked=e; lockOn=true; startLock()
            end)
        end
    end

    if ord==0 then
        local el=mkLabel(rScroll,"  No targets found",12,cGray)
        el.Size=UDim2.new(1,0,0,30)
    end
end

scanBtn.MouseButton1Click:Connect(doScan)
