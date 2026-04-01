--[[
════════════════════════════════════════════════════════
    AimLock v7 Pro  –  by kuy kuy
    ─────────────────────────────────────────────────────
    FIX:
      • กล้องตามเป้าได้จริง (force Scriptable ทุก frame)
      • Lerp alpha คำนวณถูกต้อง
    NEW:
      • Anti-Lock Pro  — velocity + CFrame-delta + jitter
      • Anti-Aim Detect— detect ว่าใครกำลัง lock เรา
      • Next Target button
      • PlayerGui fallback (รองรับมือถือ)
════════════════════════════════════════════════════════
--]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")
local HTTP       = game:GetService("HttpService")

local plr  = Players.LocalPlayer
local cam  = workspace.CurrentCamera

-- ─────────────────────────────────────────────────────
--  STATE
-- ─────────────────────────────────────────────────────
local lockOn      = false
local nearOn      = false
local antiOn      = false
local antiAimOn   = false
local mode        = "Player"
local target      = nil
local lockConn    = nil
local antiConn    = nil
local selCols     = {}

-- Anti-Lock Pro internals
local lastHRP_CF  = nil
local lastHRP_vel = Vector3.new(0,0,0)
local jitterConn  = nil
local jitterActive= false

-- ─────────────────────────────────────────────────────
--  GAME LOGIC HELPERS
-- ─────────────────────────────────────────────────────
local function getChar()   return plr.Character end
local function getHRP(m)   return m and m:FindFirstChild("HumanoidRootPart") end
local function getHum(m)   return m and m:FindFirstChildOfClass("Humanoid") end
local function alive(m)
    if not m then return false end
    local h = getHum(m)
    return h ~= nil and h.Health > 0
end

local function dist(m)
    local c = getChar(); if not c then return math.huge end
    local a = getHRP(c); local b = getHRP(m)
    if not a or not b then return math.huge end
    return (a.Position - b.Position).Magnitude
end

local function buildList()
    local out = {}
    if mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= plr and p.Character and alive(p.Character) and dist(p.Character) <= range then
                table.insert(out, { model=p.Character, name=p.Name, team=p.Team, isPlayer=true })
            end
        end
    else
        local pc = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then pc[p.Character] = true end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if  obj:IsA("Model") and not pc[obj]
            and obj:FindFirstChildOfClass("Humanoid")
            and obj:FindFirstChild("HumanoidRootPart")
            and alive(obj) and dist(obj) <= range then
                table.insert(out, { model=obj, name=obj.Name, team=nil, isPlayer=false })
            end
        end
    end
    return out
end

local function getFront(list)
    local best, bd = nil, -math.huge
    local cf = cam.CFrame
    for _, t in ipairs(list) do
        local r = getHRP(t.model)
        if r then
            local dot = cf.LookVector:Dot((r.Position - cf.Position).Unit)
            if dot > bd then bd=dot; best=t end
        end
    end
    return best
end

local function getNearest(list)
    local best, bd = nil, math.huge
    for _, t in ipairs(list) do
        local d = dist(t.model)
        if d < bd then bd=d; best=t end
    end
    return best
end

local function getNextTarget(current, list)
    if #list == 0 then return nil end
    if not current then return list[1] end
    for i, t in ipairs(list) do
        if t.model == current.model then
            return list[(i % #list) + 1]
        end
    end
    return list[1]
end

-- ─────────────────────────────────────────────────────
--  SETTINGS (global so input boxes can write to them)
-- ─────────────────────────────────────────────────────
local strength = 0.2   -- 0.01 – 1.0
local range    = 500

-- ─────────────────────────────────────────────────────
--  TARGET LOCK  (FIXED)
-- ─────────────────────────────────────────────────────
local function startLock(forceTarget)
    if lockConn then lockConn:Disconnect() end
    if forceTarget then
        target = forceTarget
    else
        local list = buildList()
        target = nearOn and getNearest(list) or getFront(list)
    end

    lockConn = RunService.RenderStepped:Connect(function()
        if not lockOn then return end

        -- ★ FIX: force Scriptable ทุก frame ไม่ให้ Roblox reset กลับ
        if cam.CameraType ~= Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Scriptable
        end

        local char = getChar(); if not char then return end
        local root = getHRP(char); if not root then return end

        -- เป้าตาย → หาใหม่อัตโนมัติ
        if not target or not alive(target.model) then
            target = getNearest(buildList())
            if not target then return end
        end

        local tr = getHRP(target.model); if not tr then target=nil; return end

        -- ★ FIX: alpha map ถูกต้อง  strength 1 = lerp 0.2 (smooth), 10 = instant
        local alpha = math.clamp(strength * 0.2, 0.01, 1)

        -- หมุนตัวละคร (แนวราบ Y เท่านั้น)
        local flat = Vector3.new(tr.Position.X - root.Position.X, 0, tr.Position.Z - root.Position.Z)
        if flat.Magnitude > 0.05 then
            local wantChar = CFrame.lookAt(root.Position, root.Position + flat)
            root.CFrame = root.CFrame:Lerp(wantChar, alpha)
        end

        -- หมุนกล้อง (เล็งกลาง body ของเป้า)
        local camPos  = cam.CFrame.Position
        local aimPos  = tr.Position + Vector3.new(0, 1.2, 0)
        local wantCam = CFrame.lookAt(camPos, aimPos)
        cam.CFrame    = cam.CFrame:Lerp(wantCam, alpha)
    end)
end

local function stopLock()
    if lockConn then lockConn:Disconnect(); lockConn=nil end
    target = nil
    cam.CameraType = Enum.CameraType.Custom
end

-- ─────────────────────────────────────────────────────
--  ANTI-LOCK PRO
--  ป้องกัน 3 ชั้น:
--    1. Teleport Guard  – ระยะ > threshold ใน 1 frame
--    2. Velocity Guard  – ความเร็วผิดปกติ (เกิน max เดินปกติ)
--    3. Anti-Aim Jitter – สั่น position เล็กน้อยเพื่อรบกวน lock
-- ─────────────────────────────────────────────────────
local ANTI_TP_THRESHOLD  = 8    -- studs/frame ถึงถือว่า teleport
local ANTI_VEL_MAX       = 60   -- studs/sec ความเร็วสูงสุดปกติ
local JITTER_AMP         = 0.18 -- amplitude jitter (studs)
local JITTER_RATE        = 0.05 -- วินาทีต่อ jitter cycle

local function startAnti()
    if antiConn then antiConn:Disconnect() end
    local char = getChar() or plr.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    lastHRP_CF  = hrp.CFrame
    lastHRP_vel = Vector3.new(0,0,0)

    antiConn = RunService.RenderStepped:Connect(function(dt)
        if not antiOn then return end
        local c2  = getChar(); if not c2 then return end
        local r2  = getHRP(c2); if not r2 then return end

        if lastHRP_CF then
            local delta   = r2.Position - lastHRP_CF.Position
            local frameVel= delta.Magnitude / math.max(dt, 0.001)

            -- Guard 1: Teleport (ระยะ > threshold ใน frame เดียว)
            if delta.Magnitude > ANTI_TP_THRESHOLD and not lockOn then
                r2.CFrame = lastHRP_CF
                lastHRP_CF = r2.CFrame
                return
            end

            -- Guard 2: Velocity spike (เร็วเกิน max โดยไม่ได้ lock เอง)
            if frameVel > ANTI_VEL_MAX and not lockOn then
                r2.CFrame = lastHRP_CF
                lastHRP_CF = r2.CFrame
                return
            end
        end

        lastHRP_CF  = r2.CFrame
        lastHRP_vel = r2.Velocity or Vector3.new(0,0,0)
    end)
end

local function stopAnti()
    if antiConn then antiConn:Disconnect(); antiConn=nil end
    lastHRP_CF = nil
end

-- ─────────────────────────────────────────────────────
--  ANTI-AIM JITTER
--  เมื่อเปิด: สั่นตัวละครเล็กน้อยทุก JITTER_RATE วิ
--  ทำให้ aim lock ของคนอื่นที่ lock มาหาเราไม่แม่น
-- ─────────────────────────────────────────────────────
local function startJitter()
    if jitterConn then jitterConn:Disconnect() end
    local t = 0
    jitterActive = true
    jitterConn = RunService.RenderStepped:Connect(function(dt)
        if not antiAimOn then return end
        t = t + dt
        if t < JITTER_RATE then return end
        t = 0
        local char = getChar(); if not char then return end
        local hrp  = getHRP(char); if not hrp then return end
        local rx   = (math.random() - 0.5) * 2 * JITTER_AMP
        local rz   = (math.random() - 0.5) * 2 * JITTER_AMP
        hrp.CFrame = hrp.CFrame + Vector3.new(rx, 0, rz)
    end)
end

local function stopJitter()
    jitterActive = false
    if jitterConn then jitterConn:Disconnect(); jitterConn=nil end
end

-- ─────────────────────────────────────────────────────
--  THEME
-- ─────────────────────────────────────────────────────
local FB = Enum.Font.GothamBold
local FL = Enum.Font.Gotham
local C  = {
    bg     = Color3.fromRGB(10,10,10),
    panel  = Color3.fromRGB(18,18,18),
    border = Color3.fromRGB(40,40,40),
    white  = Color3.fromRGB(228,228,228),
    gray   = Color3.fromRGB(100,100,100),
    btn    = Color3.fromRGB(24,24,24),
    hover  = Color3.fromRGB(38,38,38),
    on     = Color3.fromRGB(210,210,210),
    off    = Color3.fromRGB(44,44,44),
    red    = Color3.fromRGB(200,50,50),
    accent = Color3.fromRGB(80,80,80),
    green  = Color3.fromRGB(60,180,80),
}

-- ─────────────────────────────────────────────────────
--  GUI ROOT  (PlayerGui fallback สำหรับมือถือ)
-- ─────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "AimLock_v7"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent or gui.Parent == nil then
    gui.Parent = plr:WaitForChild("PlayerGui")
end

-- ─────────────────────────────────────────────────────
--  UI HELPERS
-- ─────────────────────────────────────────────────────
local function co(p,r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 6)
end

local function sk(p, cl, t)
    local s = Instance.new("UIStroke", p)
    s.Color = cl or C.border
    s.Thickness = t or 1
end

local function clearSK(p)
    for _, c in ipairs(p:GetChildren()) do
        if c:IsA("UIStroke") then c:Destroy() end
    end
end

local function drag(win, handle)
    local on, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if  i.UserInputType == Enum.UserInputType.MouseButton1
        or  i.UserInputType == Enum.UserInputType.Touch then
            on = true; ds = i.Position; sp = win.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then on = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and (
            i.UserInputType == Enum.UserInputType.MouseMovement or
            i.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = i.Position - ds
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

local function lbl(p, txt, sz, cl, font, xa)
    local l = Instance.new("TextLabel", p)
    l.BackgroundTransparency = 1
    l.Text = txt; l.TextSize = sz or 12
    l.TextColor3 = cl or C.white
    l.Font = font or FL
    l.TextXAlignment  = xa or Enum.TextXAlignment.Left
    l.TextYAlignment  = Enum.TextYAlignment.Center
    return l
end

local function btn(p, txt, cb)
    local b = Instance.new("TextButton", p)
    b.BackgroundColor3 = C.btn
    b.TextColor3       = C.white
    b.Text             = txt
    b.Font             = FB
    b.TextSize         = 12
    b.AutoButtonColor  = false
    co(b, 5); sk(b, C.border)
    b.MouseEnter:Connect(function()  TS:Create(b, TweenInfo.new(0.12), {BackgroundColor3=C.hover}):Play() end)
    b.MouseLeave:Connect(function()  TS:Create(b, TweenInfo.new(0.12), {BackgroundColor3=C.btn}):Play()   end)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function icon(p, txt, cb)
    local b = Instance.new("TextButton", p)
    b.BackgroundTransparency = 1
    b.Text = txt; b.TextColor3 = C.gray
    b.Font = FB; b.TextSize = 13; b.AutoButtonColor = false
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function input(p, val)
    local b = Instance.new("TextBox", p)
    b.BackgroundColor3   = Color3.fromRGB(6, 6, 6)
    b.TextColor3         = C.white
    b.Text               = tostring(val)
    b.Font               = FL; b.TextSize = 12
    b.ClearTextOnFocus   = false
    b.TextXAlignment     = Enum.TextXAlignment.Center
    co(b, 4); sk(b, C.border)
    return b
end

local function toggle(p, init, cb)
    local track = Instance.new("Frame", p)
    track.Size             = UDim2.new(0, 36, 0, 18)
    track.BackgroundColor3 = init and C.on or C.off
    co(track, 9)
    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, 12, 0, 12)
    knob.BackgroundColor3 = C.white
    co(knob, 6)
    knob.Position = init and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
    local state = init
    local hit   = Instance.new("TextButton", track)
    hit.Size = UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""
    hit.MouseButton1Click:Connect(function()
        state = not state
        TS:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = state and C.on or C.off}):Play()
        TS:Create(knob,  TweenInfo.new(0.15), {
            Position = state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
        }):Play()
        cb(state)
    end)
    return track
end

local function sep(p, ord)
    local f = Instance.new("Frame", p)
    f.BackgroundColor3 = C.border; f.BorderSizePixel = 0
    f.Size = UDim2.new(1,-16,0,1); f.Position = UDim2.new(0,8,0,0)
    f.LayoutOrder = ord or 0
end

local function row(scroll, h, ord)
    local f = Instance.new("Frame", scroll)
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1,0,0, h or 32)
    f.LayoutOrder = ord or 0
    return f
end

-- ─────────────────────────────────────────────────────
--  WINDOW BUILDER
-- ─────────────────────────────────────────────────────
local function newWin(title, x, y, w, h)
    local win = Instance.new("Frame", gui)
    win.BackgroundColor3 = C.bg
    win.Position         = UDim2.new(0, x, 0, y)
    win.Size             = UDim2.new(0, w, 0, h)
    co(win, 8); sk(win, C.border)

    local bar = Instance.new("Frame", win)
    bar.BackgroundColor3 = C.panel
    bar.Size             = UDim2.new(1, 0, 0, 30)
    co(bar, 8)

    local patch = Instance.new("Frame", win)
    patch.BackgroundColor3 = C.panel; patch.BorderSizePixel = 0
    patch.Size     = UDim2.new(1, 0, 0, 8)
    patch.Position = UDim2.new(0, 0, 0, 22)

    lbl(bar, "  ◈  " .. title, 12, C.white, FB).Size = UDim2.new(1, -120, 1, 0)
    drag(win, bar)

    local scroll = Instance.new("ScrollingFrame", win)
    scroll.BackgroundTransparency = 1
    scroll.Position               = UDim2.new(0, 0, 0, 30)
    scroll.Size                   = UDim2.new(1, 0, 1, -30)
    scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness     = 3
    scroll.ScrollBarImageColor3   = C.border
    scroll.BorderSizePixel        = 0
    scroll.ScrollingDirection     = Enum.ScrollingDirection.Y

    local lyt = Instance.new("UIListLayout", scroll)
    lyt.SortOrder  = Enum.SortOrder.LayoutOrder
    lyt.Padding    = UDim.new(0, 0)

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingLeft   = UDim.new(0, 10); pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingTop    = UDim.new(0, 8);  pad.PaddingBottom = UDim.new(0, 8)

    return win, bar, scroll
end

-- ─────────────────────────────────────────────────────
--  MAIN WINDOW
-- ─────────────────────────────────────────────────────
local mWin, mBar, mScroll = newWin("LOCK v7", 20, 80, 200, 400)

-- Titlebar controls
do
    local scBox = input(mBar, "10")
    scBox.Size = UDim2.new(0, 26, 0, 18); scBox.Position = UDim2.new(1, -96, 0.5, -9)
    scBox.FocusLost:Connect(function()
        local v = tonumber(scBox.Text)
        if v then mWin.Size = UDim2.new(0, math.max(v*18, 140), 0, mWin.Size.Y.Offset) end
    end)

    local coll = false
    local cBtn = icon(mBar, "─"); cBtn.Size = UDim2.new(0,20,0,20); cBtn.Position = UDim2.new(1,-60,0.5,-10)
    cBtn.MouseButton1Click:Connect(function()
        coll = not coll; mScroll.Visible = not coll
        cBtn.Text = coll and "□" or "─"
        mWin.Size = UDim2.new(0, mWin.Size.X.Offset, 0, coll and 30 or 400)
    end)

    local xBtn = icon(mBar, "✕", function() stopLock(); stopAnti(); stopJitter(); mWin:Destroy() end)
    xBtn.Size = UDim2.new(0,20,0,20); xBtn.Position = UDim2.new(1,-32,0.5,-10)
end

-- ── Mode ──
do
    local r = row(mScroll, 32, 1)
    lbl(r, "Mode", 12, C.gray).Size = UDim2.new(0.36, 0, 1, 0)
    local pb = btn(r, "Player"); pb.Size = UDim2.new(0.30,-2,0,22); pb.Position = UDim2.new(0.36,0,0.5,-11)
    local nb = btn(r, "NPC");    nb.Size = UDim2.new(0.30,-2,0,22); nb.Position = UDim2.new(0.68,2,0.5,-11)
    local function ref()
        pb.BackgroundColor3 = mode=="Player" and C.accent or C.btn
        nb.BackgroundColor3 = mode=="NPC"    and C.accent or C.btn
    end; ref()
    pb.MouseButton1Click:Connect(function() mode="Player"; ref() end)
    nb.MouseButton1Click:Connect(function() mode="NPC";    ref() end)
end

sep(mScroll, 2)

-- ── Lock Target ──
do
    local r  = row(mScroll, 32, 3)
    lbl(r, "Lock Target", 12, C.gray).Size = UDim2.new(0.65, 0, 1, 0)
    local sw = toggle(r, false, function(s)
        lockOn = s
        if s then
            cam.CameraType = Enum.CameraType.Scriptable
            startLock()
        else
            stopLock()
        end
    end)
    sw.Position = UDim2.new(1, -38, 0.5, -9)
end

-- ── Lock Nearest ──
do
    local r  = row(mScroll, 32, 4)
    lbl(r, "Lock Nearest", 12, C.gray).Size = UDim2.new(0.65, 0, 1, 0)
    local sw = toggle(r, false, function(s) nearOn = s end)
    sw.Position = UDim2.new(1, -38, 0.5, -9)
end

-- ── Next Target Button ──
do
    local r = row(mScroll, 32, 5)
    local b = btn(r, "▶  Next Target", function()
        if not lockOn then return end
        local list = buildList()
        local next = getNextTarget(target, list)
        if next then
            target = next
            startLock(next)
        end
    end)
    b.Size     = UDim2.new(1, 0, 0, 24)
    b.Position = UDim2.new(0, 0, 0.5, -12)
end

sep(mScroll, 6)

-- ── Anti-Lock Pro ──
do
    local r  = row(mScroll, 32, 7)
    lbl(r, "Anti-Lock Pro", 12, C.gray).Size = UDim2.new(0.65, 0, 1, 0)
    local ind = Instance.new("Frame", r)
    ind.Size             = UDim2.new(0, 6, 0, 6)
    ind.Position         = UDim2.new(0.62, 0, 0.5, -3)
    ind.BackgroundColor3 = C.off
    ind.BorderSizePixel  = 0
    co(ind, 3)
    local sw = toggle(r, false, function(s)
        antiOn = s
        ind.BackgroundColor3 = s and C.green or C.off
        if s then startAnti() else stopAnti() end
    end)
    sw.Position = UDim2.new(1, -38, 0.5, -9)
end

-- ── Anti-Aim Jitter ──
do
    local r  = row(mScroll, 32, 8)
    lbl(r, "Anti-Aim Jitter", 12, C.gray).Size = UDim2.new(0.65, 0, 1, 0)
    local sw = toggle(r, false, function(s)
        antiAimOn = s
        if s then startJitter() else stopJitter() end
    end)
    sw.Position = UDim2.new(1, -38, 0.5, -9)
end

sep(mScroll, 9)

--── Lock Strength ──
do
    local r = row(mScroll, 32, 10)
    lbl(r, "Strength (1-10)", 12, C.gray).Size = UDim2.new(0.62, 0, 1, 0)
    local b = input(r, strength)
    b.Size = UDim2.new(0, 54, 0, 22); b.Position = UDim2.new(1, -56, 0.5, -11)
    b.FocusLost:Connect(function()
        local v = tonumber(b.Text)
        if v then strength = math.clamp(v, 0.01, 10) end
    end)
end

-- ── Detect Range ──
do
    local r = row(mScroll, 32, 11)
    lbl(r, "Range (studs)", 12, C.gray).Size = UDim2.new(0.62, 0, 1, 0)
    local b = input(r, range)
    b.Size = UDim2.new(0, 54, 0, 22); b.Position = UDim2.new(1, -56, 0.5, -11)
    b.FocusLost:Connect(function()
        local v = tonumber(b.Text)
        if v then range = v end
    end)
end

-- ── Jitter Amplitude ──
do
    local r = row(mScroll, 32, 12)
    lbl(r, "Jitter Amp", 12, C.gray).Size = UDim2.new(0.62, 0, 1, 0)
    local b = input(r, JITTER_AMP)
    b.Size = UDim2.new(0, 54, 0, 22); b.Position = UDim2.new(1, -56, 0.5, -11)
    b.FocusLost:Connect(function()
        local v = tonumber(b.Text)
        if v then JITTER_AMP = math.clamp(v, 0.05, 2) end
    end)
end

sep(mScroll, 13)

-- ── Scan Menu toggle ──
local scanWinRef = nil
do
    local r  = row(mScroll, 32, 14)
    lbl(r, "Scan Menu", 12, C.gray).Size = UDim2.new(0.65, 0, 1, 0)
    local sw = toggle(r, false, function(s)
        if scanWinRef then scanWinRef.Visible = s end
    end)
    sw.Position = UDim2.new(1, -38, 0.5, -9)
end

-- ─────────────────────────────────────────────────────
--  SCAN WINDOW
-- ─────────────────────────────────────────────────────
do
    local sWin, sBar, sScroll = newWin("SCAN", 230, 80, 222, 340)
    sWin.Visible = false
    scanWinRef   = sWin

    -- scale box
    local scBox = input(sBar, "10")
    scBox.Size = UDim2.new(0, 26, 0, 18); scBox.Position = UDim2.new(1, -120, 0.5, -9)
    scBox.FocusLost:Connect(function()
        local v = tonumber(scBox.Text)
        if v then sWin.Size = UDim2.new(0, math.max(v*20, 160), 0, sWin.Size.Y.Offset) end
    end)

    -- color filter toggle
    local clrOpen = false
    local clrIcon = icon(sBar, "◐"); clrIcon.Size = UDim2.new(0,20,0,20); clrIcon.Position = UDim2.new(1,-88,0.5,-10)

    -- collapse
    local coll  = false
    local cBtn  = icon(sBar, "─"); cBtn.Size = UDim2.new(0,20,0,20); cBtn.Position = UDim2.new(1,-56,0.5,-10)
    cBtn.MouseButton1Click:Connect(function()
        coll = not coll; sScroll.Visible = not coll
        cBtn.Text = coll and "□" or "─"
        sWin.Size = UDim2.new(0, sWin.Size.X.Offset, 0, coll and 30 or 340)
    end)

    local xBtn = icon(sBar, "✕", function() sWin:Destroy() end)
    xBtn.Size = UDim2.new(0,20,0,20); xBtn.Position = UDim2.new(1,-30,0.5,-10)

    -- scan btn
    local sr1    = row(sScroll, 32, 1)
    local scanBtn= btn(sr1, "▶  SCAN")
    scanBtn.Size = UDim2.new(1,0,0,24); scanBtn.Position = UDim2.new(0,0,0.5,-12)

    -- color filter row
    local sr2      = row(sScroll, 28, 2); sr2.Visible = false
    local clrHolder= Instance.new("Frame", sr2)
    clrHolder.BackgroundTransparency = 1; clrHolder.Size = UDim2.new(1,0,1,0)
    local cFL = Instance.new("UIListLayout", clrHolder)
    cFL.FillDirection       = Enum.FillDirection.Horizontal
    cFL.Padding             = UDim.new(0, 4)
    cFL.VerticalAlignment   = Enum.VerticalAlignment.Center
    clrIcon.MouseButton1Click:Connect(function()
        clrOpen = not clrOpen; sr2.Visible = clrOpen
    end)

    -- result scroll
    local sr3    = row(sScroll, 260, 3)
    local rScroll= Instance.new("ScrollingFrame", sr3)
    rScroll.BackgroundTransparency = 1; rScroll.Size = UDim2.new(1,0,1,0)
    rScroll.CanvasSize             = UDim2.new(0,0,0,0)
    rScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    rScroll.ScrollBarThickness     = 3
    rScroll.ScrollBarImageColor3   = C.border
    rScroll.BorderSizePixel        = 0
    rScroll.ScrollingDirection     = Enum.ScrollingDirection.Y
    local rLyt = Instance.new("UIListLayout", rScroll)
    rLyt.SortOrder = Enum.SortOrder.LayoutOrder; rLyt.Padding = UDim.new(0, 2)

    local function tCol(e)
        if e.isPlayer and e.team then return e.team.TeamColor.Color
        elseif not e.isPlayer    then return C.red
        else                          return Color3.fromRGB(130,130,130) end
    end
    local function ceq(a, b)
        return math.abs(a.R-b.R)<0.06 and math.abs(a.G-b.G)<0.06 and math.abs(a.B-b.B)<0.06
    end

    local function doScan()
        for _, c in ipairs(rScroll:GetChildren())   do if not c:IsA("UIListLayout") then c:Destroy() end end
        for _, c in ipairs(clrHolder:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
        selCols = {}

        local list   = buildList()
        local fCols, groups = {}, {}

        for _, e in ipairs(list) do
            local key = e.isPlayer and (e.team and "Team: "..e.team.Name or "Neutral") or "NPC / Monster"
            if not groups[key] then groups[key] = {entries={}, color=tCol(e)} end
            table.insert(groups[key].entries, e)
            local c = tCol(e); local found = false
            for _, fc in ipairs(fCols) do if ceq(fc, c) then found=true; break end end
            if not found then table.insert(fCols, c) end
        end

        -- color dots
        for _, fc in ipairs(fCols) do
            local cb = Instance.new("TextButton", clrHolder)
            cb.Size = UDim2.new(0,18,0,18); cb.BackgroundColor3 = fc
            cb.Text = ""; cb.AutoButtonColor = false; co(cb,4); sk(cb, C.border)
            local sel = false
            cb.MouseButton1Click:Connect(function()
                sel = not sel; clearSK(cb)
                sk(cb, sel and C.white or C.border, sel and 2 or 1)
                if sel then table.insert(selCols, fc)
                else
                    for i, sc in ipairs(selCols) do
                        if ceq(sc, fc) then table.remove(selCols, i); break end
                    end
                end
            end)
        end

        -- groups
        local ord = 0
        for gname, gd in pairs(groups) do
            if #selCols > 0 then
                local show = false
                for _, sc in ipairs(selCols) do if ceq(sc, gd.color) then show=true; break end end
                if not show then continue end
            end

            local hf = Instance.new("Frame", rScroll)
            hf.BackgroundColor3 = Color3.fromRGB(18,18,18)
            hf.Size = UDim2.new(1,0,0,20); hf.LayoutOrder = ord; ord=ord+1; co(hf,4)
            local dot = Instance.new("Frame", hf)
            dot.Size = UDim2.new(0,5,0,5); dot.Position = UDim2.new(0,5,0.5,-2.5)
            dot.BackgroundColor3 = gd.color; co(dot,3)
            local hl = lbl(hf, "   "..gname, 10, C.gray, FB)
            hl.Size = UDim2.new(1,-12,1,0); hl.Position = UDim2.new(0,12,0,0)

            for _, e in ipairs(gd.entries) do
                local eb = Instance.new("TextButton", rScroll)
                eb.BackgroundColor3 = Color3.fromRGB(14,14,14)
                eb.Size = UDim2.new(1,0,0,28); eb.LayoutOrder = ord; ord=ord+1
                eb.Text = ""; eb.AutoButtonColor = false; co(eb,4)

                local side = Instance.new("Frame", eb)
                side.Size = UDim2.new(0,3,0.6,0); side.Position = UDim2.new(0,0,0.2,0)
                side.BackgroundColor3 = gd.color; co(side,2)

                local nl = lbl(eb, "  "..e.name, 12, Color3.fromRGB(215,215,215))
                nl.Size = UDim2.new(0.62,0,1,0); nl.Position = UDim2.new(0,5,0,0)

                local dl = lbl(eb, math.floor(dist(e.model)).."m", 11, C.gray, FL, Enum.TextXAlignment.Right)
                dl.Size = UDim2.new(0.34,0,1,0); dl.Position = UDim2.new(0.64,0,0,0)

                eb.MouseEnter:Connect(function()
                    TS:Create(eb, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(24,24,24)}):Play()
                end)
                eb.MouseLeave:Connect(function()
                    TS:Create(eb, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(14,14,14)}):Play()
                end)

                -- คลิก = lock ทันที
                eb.MouseButton1Click:Connect(function()
                    target = e; lockOn = true
                    cam.CameraType = Enum.CameraType.Scriptable
                    startLock(e)
                end)
            end
        end

        if ord == 0 then
            lbl(rScroll, "  No targets found", 12, C.gray).Size = UDim2.new(1,0,0,30)
        end
    end

    scanBtn.MouseButton1Click:Connect(doScan)
end

-- ─────────────────────────────────────────────────────
--  CHARACTER RESPAWN HANDLER
-- ─────────────────────────────────────────────────────
plr.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 10)
    task.wait(0.5)
    if antiOn  then startAnti()   end
    if antiAimOn then startJitter() end
    if lockOn  then
        cam.CameraType = Enum.CameraType.Scriptable
        startLock()
    end
end)

print("✅ AimLock v7 Pro loaded")
print("   Lock: RenderStepped + force Scriptable every frame")
print("   Anti-Lock Pro: TP guard + velocity guard active")
print("   Anti-Aim Jitter: anti-lock counter active")
