-- ╔══════════════════════════════════════╗
-- ║   KUY LOCK MENU v1 - CLEAN SIMPLE   ║
-- ║   Lock + Radar | Mobile + PC        ║
-- ╚══════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ══════════════════════
-- STATE
-- ══════════════════════
local S = {
    Size       = 10,
    Mode       = "Monster", -- "Player" | "Monster"
    AimPart    = "Body",    -- "Head" | "Body"
    Strength   = 0.2,
    Range      = 150,
    Enabled    = false,
    Nearest    = false,
    RadarOpen  = false,
    RadarSize  = 10,
    ColorFilter = nil,      -- nil = all colors
}

local currentTarget = nil
local lockConn = nil
local radarGui = nil

-- ══════════════════════
-- CHAR HELPERS
-- ══════════════════════
local Char, HRP, Hum

local function refreshChar(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart", 5)
    Hum  = c:FindFirstChildOfClass("Humanoid")
end

if LP.Character then refreshChar(LP.Character) end
LP.CharacterAdded:Connect(refreshChar)

local function getRoot(m)
    return m and m:FindFirstChild("HumanoidRootPart")
end
local function getHum(m)
    return m and m:FindFirstChildOfClass("Humanoid")
end
local function isAlive(m)
    local h = getHum(m)
    return h and h.Health > 0
end
local function getAimPos(m)
    if S.AimPart == "Head" then
        local head = m:FindFirstChild("Head")
        if head then return head.Position end
    end
    local r = getRoot(m)
    return r and r.Position
end

-- ══════════════════════
-- TARGET LIST
-- ══════════════════════
local function getTeamColor(model)
    local p = Players:GetPlayerFromCharacter(model)
    if p then
        local myT = LP.Team
        if myT and p.Team == myT then return Color3.fromRGB(60,200,100) end
        if p.Team then return Color3.fromRGB(220,60,60) end
        return Color3.fromRGB(150,150,255)
    end
    return Color3.fromRGB(220,140,50)
end

local function getTargets()
    if not HRP then return {} end
    local list = {}
    if S.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and isAlive(p.Character) then
                local r = getRoot(p.Character)
                if r then
                    local d = (r.Position - HRP.Position).Magnitude
                    if d <= S.Range then
                        table.insert(list, {
                            model = p.Character,
                            name  = p.Name,
                            dist  = d,
                            color = getTeamColor(p.Character)
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
                if h and h.Health > 0 and r and not Players:GetPlayerFromCharacter(obj) then
                    local d = (r.Position - HRP.Position).Magnitude
                    if d <= S.Range then
                        table.insert(list, {
                            model = obj,
                            name  = obj.Name,
                            dist  = d,
                            color = getTeamColor(obj)
                        })
                    end
                end
            end
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    -- filter color
    if S.ColorFilter then
        local cf = S.ColorFilter
        local filtered = {}
        for _, e in ipairs(list) do
            if math.abs(e.color.R-cf.R)<0.05 and math.abs(e.color.G-cf.G)<0.05 and math.abs(e.color.B-cf.B)<0.05 then
                table.insert(filtered, e)
            end
        end
        return filtered
    end
    return list
end

local function getNearestTarget()
    local list = getTargets()
    return list[1] and list[1].model or nil
end

local function getLookedTarget()
    if not HRP then return nil end
    local list = getTargets()
    local best, bestDot = nil, -1
    local camLook = Camera.CFrame.LookVector
    local camPos  = Camera.CFrame.Position
    for _, e in ipairs(list) do
        local r = getRoot(e.model)
        if r then
            local dir = (r.Position - camPos).Unit
            local dot = camLook:Dot(dir)
            if dot > bestDot then best = e.model bestDot = dot end
        end
    end
    return best
end

-- ══════════════════════
-- LOCK LOGIC
-- ══════════════════════
local function setTarget(m)
    currentTarget = m
end

local function startLock()
    if lockConn then lockConn:Disconnect() end
    local origType = Camera.CameraType
    Camera.CameraType = Enum.CameraType.Scriptable
    local scanTimer = 0

    lockConn = RunService.RenderStepped:Connect(function(dt)
        if not HRP then return end
        Camera.CameraType = Enum.CameraType.Scriptable

        -- auto pick target
        if not currentTarget or not isAlive(currentTarget) then
            if S.Nearest then
                setTarget(getNearestTarget())
            else
                setTarget(getLookedTarget())
            end
        end

        if currentTarget then
            if not isAlive(currentTarget) then
                setTarget(getNearestTarget())
                return
            end
            local aimPos = getAimPos(currentTarget)
            if not aimPos then return end
            -- rotate character
            HRP.CFrame = CFrame.new(HRP.Position,
                Vector3.new(aimPos.X, HRP.Position.Y, aimPos.Z))
            -- lerp camera
            local targetCF = CFrame.new(Camera.CFrame.Position, aimPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, S.Strength)
        end
    end)
end

local function stopLock()
    if lockConn then lockConn:Disconnect() lockConn = nil end
    pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
    setTarget(nil)
end

-- ══════════════════════════════════════
-- DRAGGABLE HELPER
-- ══════════════════════════════════════
local function makeDraggable(frame, handle)
    local drag, dStart, fStart = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true dStart = i.Position fStart = frame.Position
        end
    end)
    local function move(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dStart
            frame.Position = UDim2.new(fStart.X.Scale, fStart.X.Offset+d.X,
                fStart.Y.Scale, fStart.Y.Offset+d.Y)
        end
    end
    handle.InputChanged:Connect(move)
    UserInputService.InputChanged:Connect(move)
    local function stop(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end
    handle.InputEnded:Connect(stop)
    UserInputService.InputEnded:Connect(stop)
end

-- ══════════════════════════════════════
-- UI FACTORY
-- ══════════════════════════════════════
local function corner(p, r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 6) end
local function stroke(p, c, t)
    local s=Instance.new("UIStroke",p) s.Color=c or Color3.fromRGB(60,60,60) s.Thickness=t or 1
end

local function makeLabel(parent, text, size, color, xalign)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(200,200,200)
    l.TextSize = size or 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = xalign or Enum.TextXAlignment.Left
    l.TextScaled = false
    return l
end

local function makeBtn(parent, text, size, bg, tc)
    local b = Instance.new("TextButton", parent)
    b.BackgroundColor3 = bg or Color3.fromRGB(35,35,35)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = tc or Color3.fromRGB(220,220,220)
    b.TextSize = size or 11
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    corner(b, 6)
    return b
end

local function makeInput(parent, default, tsize)
    local b = Instance.new("TextBox", parent)
    b.BackgroundColor3 = Color3.fromRGB(28,28,28)
    b.BorderSizePixel = 0
    b.Text = tostring(default)
    b.TextColor3 = Color3.fromRGB(220,220,220)
    b.TextSize = tsize or 11
    b.Font = Enum.Font.Gotham
    b.ClearTextOnFocus = false
    corner(b, 5)
    stroke(b, Color3.fromRGB(55,55,55))
    return b
end

-- ══════════════════════════════════════
-- BUILD MAIN GUI
-- ══════════════════════════════════════
pcall(function() CoreGui:FindFirstChild("KuyLock_v1"):Destroy() end)

local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "KuyLock_v1"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local sc = S.Size / 10  -- scale
local W, H = 210*sc, 370*sc

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
main.BackgroundColor3 = Color3.fromRGB(13,13,13)
main.BorderSizePixel = 0
corner(main, 9)
stroke(main, Color3.fromRGB(55,55,55))

-- title bar
local tbar = Instance.new("Frame", main)
tbar.Size = UDim2.new(1,0,0,28*sc)
tbar.BackgroundColor3 = Color3.fromRGB(22,22,22)
tbar.BorderSizePixel = 0
corner(tbar, 9)
makeDraggable(main, tbar)

local titleLbl = makeLabel(tbar, "⚔  KuyLock", 11*sc, Color3.fromRGB(255,255,255))
titleLbl.Size = UDim2.new(1,-100*sc,1,0)
titleLbl.Position = UDim2.new(0,8*sc,0,0)

-- size input
local sizeInput = makeInput(tbar, "10", 10*sc)
sizeInput.Size = UDim2.new(0,26*sc,0,20*sc)
sizeInput.Position = UDim2.new(1,-96*sc,0.5,-10*sc)

-- minimize btn
local minBtn = makeBtn(tbar, "–", 13*sc, Color3.fromRGB(50,50,50))
minBtn.Size = UDim2.new(0,22*sc,0,20*sc)
minBtn.Position = UDim2.new(1,-68*sc,0.5,-10*sc)

-- close btn
local closeBtn = makeBtn(tbar, "✕", 11*sc, Color3.fromRGB(190,45,45), Color3.fromRGB(255,255,255))
closeBtn.Size = UDim2.new(0,22*sc,0,20*sc)
closeBtn.Position = UDim2.new(1,-42*sc,0.5,-10*sc)

-- delete btn
local delBtn = makeBtn(tbar, "🗑", 11*sc, Color3.fromRGB(80,30,30), Color3.fromRGB(255,150,150))
delBtn.Size = UDim2.new(0,22*sc,0,20*sc)
delBtn.Position = UDim2.new(1,-16*sc,0.5,-10*sc)

-- content scroll
local content = Instance.new("ScrollingFrame", main)
content.Size = UDim2.new(1,-4*sc,1,-30*sc)
content.Position = UDim2.new(0,2*sc,0,29*sc)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 2
content.ScrollBarImageColor3 = Color3.fromRGB(70,70,70)
content.CanvasSize = UDim2.new(0,0,0,0)

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0,4*sc)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local pad = Instance.new("UIPadding", content)
pad.PaddingLeft = UDim.new(0,6*sc)
pad.PaddingRight = UDim.new(0,6*sc)
pad.PaddingTop = UDim.new(0,5*sc)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+10*sc)
end)

-- ──────────────────────────────
-- ROW BUILDER HELPERS
-- ──────────────────────────────
local function secLabel(text)
    local f = Instance.new("Frame", content)
    f.Size = UDim2.new(1,0,0,14*sc)
    f.BackgroundTransparency = 1
    local l = makeLabel(f, text, 9*sc, Color3.fromRGB(120,120,120))
    l.Size = UDim2.new(1,0,1,0)
    return f
end

local function divider()
    local f = Instance.new("Frame", content)
    f.Size = UDim2.new(1,0,0,1)
    f.BackgroundColor3 = Color3.fromRGB(40,40,40)
    f.BorderSizePixel = 0
end

local function toggleRow(label, onToggle)
    local f = Instance.new("Frame", content)
    f.Size = UDim2.new(1,0,0,26*sc)
    f.BackgroundColor3 = Color3.fromRGB(20,20,20)
    f.BorderSizePixel = 0
    corner(f,6)

    local l = makeLabel(f, label, 10*sc)
    l.Size = UDim2.new(1,-50*sc,1,0)
    l.Position = UDim2.new(0,8*sc,0,0)

    local state = false
    local btn = makeBtn(f, "OFF", 9*sc, Color3.fromRGB(45,45,45), Color3.fromRGB(130,130,130))
    btn.Size = UDim2.new(0,40*sc,0,18*sc)
    btn.Position = UDim2.new(1,-46*sc,0.5,-9*sc)

    local function refresh()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
            btn.TextColor3 = Color3.fromRGB(0,0,0)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
            btn.TextColor3 = Color3.fromRGB(130,130,130)
            btn.Text = "OFF"
        end
    end

    btn.MouseButton1Click:Connect(function()
        state = not state refresh() onToggle(state)
    end)
    return f, function(v) state=v refresh() end
end

local function inputRow(label, default, onChange)
    local f = Instance.new("Frame", content)
    f.Size = UDim2.new(1,0,0,26*sc)
    f.BackgroundColor3 = Color3.fromRGB(20,20,20)
    f.BorderSizePixel = 0
    corner(f,6)

    local l = makeLabel(f, label, 10*sc)
    l.Size = UDim2.new(0.55,0,1,0)
    l.Position = UDim2.new(0,8*sc,0,0)

    local box = makeInput(f, default, 10*sc)
    box.Size = UDim2.new(0.38,0,0,18*sc)
    box.Position = UDim2.new(0.58,0,0.5,-9*sc)
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then onChange(v) else box.Text=tostring(default) end
    end)
    return f
end

local function modeRow(opts, default, onChange)
    local f = Instance.new("Frame", content)
    f.Size = UDim2.new(1,0,0,26*sc)
    f.BackgroundTransparency = 1

    local cur = default
    local btns = {}
    local w = (1/#opts)
    for i, opt in ipairs(opts) do
        local b = makeBtn(f, opt, 9*sc)
        b.Size = UDim2.new(w,-3*sc,1,0)
        b.Position = UDim2.new((i-1)*w,2*sc,0,0)
        table.insert(btns, {b=b, v=opt})
        b.MouseButton1Click:Connect(function()
            cur = opt
            for _, d in ipairs(btns) do
                d.b.BackgroundColor3 = d.v==cur
                    and Color3.fromRGB(230,230,230) or Color3.fromRGB(35,35,35)
                d.b.TextColor3 = d.v==cur
                    and Color3.fromRGB(15,15,15) or Color3.fromRGB(180,180,180)
            end
            onChange(opt)
        end)
    end
    -- init style
    for _, d in ipairs(btns) do
        d.b.BackgroundColor3 = d.v==cur
            and Color3.fromRGB(230,230,230) or Color3.fromRGB(35,35,35)
        d.b.TextColor3 = d.v==cur
            and Color3.fromRGB(15,15,15) or Color3.fromRGB(180,180,180)
    end
    return f
end

-- ──────────────────────────────
-- TARGET DISPLAY LABEL
-- ──────────────────────────────
local statusRow = Instance.new("Frame", content)
statusRow.Size = UDim2.new(1,0,0,22*sc)
statusRow.BackgroundColor3 = Color3.fromRGB(18,18,18)
statusRow.BorderSizePixel = 0
corner(statusRow,6)

local statusLbl = makeLabel(statusRow, "● No Target", 9*sc, Color3.fromRGB(100,100,100))
statusLbl.Size = UDim2.new(1,-10*sc,1,0)
statusLbl.Position = UDim2.new(0,8*sc,0,0)

local function updateStatus()
    if currentTarget then
        statusLbl.Text = "🔒 " .. currentTarget.Name
        statusLbl.TextColor3 = Color3.fromRGB(120,255,120)
    else
        statusLbl.Text = "● No Target"
        statusLbl.TextColor3 = Color3.fromRGB(100,100,100)
    end
end

-- ══════════════════════
-- BUILD MENU ITEMS
-- ══════════════════════

secLabel("▸ TARGET MODE")
modeRow({"Player","Monster"}, S.Mode, function(v)
    S.Mode = v currentTarget = nil
end)

divider()
secLabel("▸ AIM PART")
modeRow({"Body","Head"}, S.AimPart, function(v)
    S.AimPart = v
end)

divider()
secLabel("▸ TARGET LOCK")

local lockRow, setLockUI = toggleRow("🔒 Lock Enable", function(v)
    S.Enabled = v
    if v then startLock() else stopLock() end
end)

local nearRow, setNearUI = toggleRow("📍 Auto Nearest", function(v)
    S.Nearest = v
    if v then setTarget(getNearestTarget()) end
end)

inputRow("⚡ Strength (0.01-1)", S.Strength, function(v)
    S.Strength = math.clamp(v, 0.01, 1)
end)

inputRow("📏 Range (studs)", S.Range, function(v)
    S.Range = math.max(1, v)
end)

divider()
secLabel("▸ NAVIGATE TARGET")

local navRow = Instance.new("Frame", content)
navRow.Size = UDim2.new(1,0,0,26*sc)
navRow.BackgroundTransparency = 1

local prevBtn = makeBtn(navRow, "◀ Prev", 9*sc, Color3.fromRGB(35,35,35))
prevBtn.Size = UDim2.new(0.48,0,1,0)
prevBtn.Position = UDim2.new(0,0,0,0)

local nextBtn = makeBtn(navRow, "Next ▶", 9*sc, Color3.fromRGB(35,35,35))
nextBtn.Size = UDim2.new(0.48,0,1,0)
nextBtn.Position = UDim2.new(0.52,0,0,0)

prevBtn.MouseButton1Click:Connect(function()
    local list = getTargets()
    if #list == 0 then return end
    local idx = 1
    for i, e in ipairs(list) do
        if e.model == currentTarget then idx = i break end
    end
    idx = idx - 1
    if idx < 1 then idx = #list end
    setTarget(list[idx].model)
    updateStatus()
end)

nextBtn.MouseButton1Click:Connect(function()
    local list = getTargets()
    if #list == 0 then return end
    local idx = 1
    for i, e in ipairs(list) do
        if e.model == currentTarget then idx = i break end
    end
    idx = idx + 1
    if idx > #list then idx = 1 end
    setTarget(list[idx].model)
    updateStatus()
end)

divider()
statusRow.Parent = nil -- re-add at bottom
statusRow.Parent = content

divider()
secLabel("▸ RADAR")

local radarToggleRow, setRadarUI = toggleRow("🔍 Open Radar", function(v)
    S.RadarOpen = v
    if v then
        if radarGui then pcall(function() radarGui:Destroy() end) end
        -- BUILD RADAR GUI
        local rs = S.RadarSize / 10
        local RW, RH = 200*rs, 320*rs

        radarGui = Instance.new("ScreenGui", CoreGui)
        radarGui.Name = "KuyRadar_v1"
        radarGui.ResetOnSpawn = false
        radarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local rf = Instance.new("Frame", radarGui)
        rf.Size = UDim2.new(0,RW,0,RH)
        rf.Position = UDim2.new(0.5,20,0.5,-RH/2)
        rf.BackgroundColor3 = Color3.fromRGB(11,11,11)
        rf.BorderSizePixel = 0
        corner(rf,9)
        stroke(rf, Color3.fromRGB(55,55,55))

        local rtbar = Instance.new("Frame", rf)
        rtbar.Size = UDim2.new(1,0,0,26*rs)
        rtbar.BackgroundColor3 = Color3.fromRGB(20,20,20)
        rtbar.BorderSizePixel = 0
        corner(rtbar,9)
        makeDraggable(rf, rtbar)

        local rtitle = makeLabel(rtbar, "🔍 Radar", 10*rs, Color3.fromRGB(255,255,255))
        rtitle.Size = UDim2.new(1,-80*rs,1,0)
        rtitle.Position = UDim2.new(0,7*rs,0,0)

        local rSizeInput = makeInput(rtbar, "10", 9*rs)
        rSizeInput.Size = UDim2.new(0,24*rs,0,18*rs)
        rSizeInput.Position = UDim2.new(1,-76*rs,0.5,-9*rs)

        local rMinBtn = makeBtn(rtbar, "–", 11*rs, Color3.fromRGB(50,50,50))
        rMinBtn.Size = UDim2.new(0,20*rs,0,18*rs)
        rMinBtn.Position = UDim2.new(1,-50*rs,0.5,-9*rs)

        local rCloseBtn = makeBtn(rtbar, "✕", 10*rs, Color3.fromRGB(190,45,45))
        rCloseBtn.Size = UDim2.new(0,20*rs,0,18*rs)
        rCloseBtn.Position = UDim2.new(1,-27*rs,0.5,-9*rs)

        local rDelBtn = makeBtn(rtbar, "🗑", 10*rs, Color3.fromRGB(80,30,30))
        rDelBtn.Size = UDim2.new(0,20*rs,0,18*rs)
        rDelBtn.Position = UDim2.new(1,-5*rs,0.5,-9*rs)

        -- radar body
        local rbody = Instance.new("Frame", rf)
        rbody.Size = UDim2.new(1,-4*rs,1,-28*rs)
        rbody.Position = UDim2.new(0,2*rs,0,27*rs)
        rbody.BackgroundTransparency = 1

        -- scan btn
        local scanBtn = makeBtn(rbody, "▶ SCAN", 10*rs, Color3.fromRGB(35,70,35))
        scanBtn.Size = UDim2.new(1,-8*rs,0,24*rs)
        scanBtn.Position = UDim2.new(0,4*rs,0,2*rs)

        -- found label
        local foundLbl = makeLabel(rbody, "0 found", 8*rs, Color3.fromRGB(90,90,90))
        foundLbl.Size = UDim2.new(1,0,0,12*rs)
        foundLbl.Position = UDim2.new(0,4*rs,0,28*rs)

        -- color filter btns area
        local colorBar = Instance.new("Frame", rbody)
        colorBar.Size = UDim2.new(1,-8*rs,0,20*rs)
        colorBar.Position = UDim2.new(0,4*rs,0,42*rs)
        colorBar.BackgroundTransparency = 1

        local colorLayout = Instance.new("UIListLayout", colorBar)
        colorLayout.FillDirection = Enum.FillDirection.Horizontal
        colorLayout.Padding = UDim.new(0,3*rs)

        -- all btn
        local allColorBtn = makeBtn(colorBar, "ALL", 8*rs, Color3.fromRGB(230,230,230), Color3.fromRGB(15,15,15))
        allColorBtn.Size = UDim2.new(0,30*rs,1,0)

        -- scroll list
        local scroll = Instance.new("ScrollingFrame", rbody)
        scroll.Size = UDim2.new(1,-4*rs,1,-68*rs)
        scroll.Position = UDim2.new(0,2*rs,0,66*rs)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = Color3.fromRGB(70,70,70)
        scroll.CanvasSize = UDim2.new(0,0,0,0)

        local sLayout = Instance.new("UIListLayout", scroll)
        sLayout.Padding = UDim.new(0,3*rs)
        sLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0,0,0,sLayout.AbsoluteContentSize.Y+6)
        end)

        local knownColors = {}
        local colorBtns = {}

        local function buildColorBtns()
            for _, b in ipairs(colorBtns) do pcall(function() b:Destroy() end) end
            colorBtns = {}
            for hex, col in pairs(knownColors) do
                local b = makeBtn(colorBar, "", 8*rs, col)
                b.Size = UDim2.new(0,18*rs,1,0)
                -- tooltip via text
                b.Text = ""
                table.insert(colorBtns, b)
                b.MouseButton1Click:Connect(function()
                    S.ColorFilter = col
                    allColorBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
                    allColorBtn.TextColor3 = Color3.fromRGB(180,180,180)
                    for _, cb in ipairs(colorBtns) do
                        if cb == b then
                            local s2 = Instance.new("UIStroke",cb)
                            s2.Color = Color3.fromRGB(255,255,255) s2.Thickness=1.5
                        else
                            for _, ch in ipairs(cb:GetChildren()) do
                                if ch:IsA("UIStroke") then ch:Destroy() end
                            end
                        end
                    end
                end)
            end
        end

        allColorBtn.MouseButton1Click:Connect(function()
            S.ColorFilter = nil
            allColorBtn.BackgroundColor3 = Color3.fromRGB(230,230,230)
            allColorBtn.TextColor3 = Color3.fromRGB(15,15,15)
            for _, cb in ipairs(colorBtns) do
                for _, ch in ipairs(cb:GetChildren()) do
                    if ch:IsA("UIStroke") then ch:Destroy() end
                end
            end
        end)

        local function doScan()
            for _, c in ipairs(scroll:GetChildren()) do
                if not c:IsA("UIListLayout") then c:Destroy() end
            end
            knownColors = {}
            local list = getTargets()
            foundLbl.Text = #list .. " found"
            for _, e in ipairs(list) do
                -- collect colors
                local hex = string.format("%02X%02X%02X",
                    math.floor(e.color.R*255),
                    math.floor(e.color.G*255),
                    math.floor(e.color.B*255))
                if not knownColors[hex] then knownColors[hex] = e.color end

                local row = Instance.new("TextButton", scroll)
                row.Size = UDim2.new(1,0,0,24*rs)
                row.BackgroundColor3 = Color3.fromRGB(20,20,20)
                row.BorderSizePixel = 0
                row.Text = ""
                row.AutoButtonColor = false
                corner(row, 5)

                local dot = Instance.new("Frame", row)
                dot.Size = UDim2.new(0,7*rs,0,7*rs)
                dot.Position = UDim2.new(0,5*rs,0.5,-3.5*rs)
                dot.BackgroundColor3 = e.color
                dot.BorderSizePixel = 0
                corner(dot, 10)

                local nameLbl = makeLabel(row, e.name, 9*rs, e.color)
                nameLbl.Size = UDim2.new(0.6,0,1,0)
                nameLbl.Position = UDim2.new(0,16*rs,0,0)

                local distLbl = makeLabel(row, math.floor(e.dist).."m", 8*rs,
                    Color3.fromRGB(110,110,110), Enum.TextXAlignment.Right)
                distLbl.Size = UDim2.new(0.35,0,1,0)
                distLbl.Position = UDim2.new(0.62,0,0,0)

                local cap = e
                row.MouseButton1Click:Connect(function()
                    setTarget(cap.model)
                    updateStatus()
                end)
            end
            buildColorBtns()
        end

        scanBtn.MouseButton1Click:Connect(doScan)

        -- minimize
        local rMinimized = false
        rMinBtn.MouseButton1Click:Connect(function()
            rMinimized = not rMinimized
            rbody.Visible = not rMinimized
            rf.Size = rMinimized
                and UDim2.new(0,RW,0,26*rs)
                or UDim2.new(0,RW,0,RH)
        end)

        rCloseBtn.MouseButton1Click:Connect(function()
            S.RadarOpen = false
            setRadarUI(false)
            radarGui:Destroy()
            radarGui = nil
        end)

        rDelBtn.MouseButton1Click:Connect(function()
            S.RadarOpen = false
            setRadarUI(false)
            radarGui:Destroy()
            radarGui = nil
        end)

        rSizeInput.FocusLost:Connect(function()
            local v = tonumber(rSizeInput.Text)
            if v then
                v = math.max(1, v)
                S.RadarSize = v
                local ns = v/10
                rf.Size = UDim2.new(0,200*ns,0,320*ns)
            end
        end)

    else
        if radarGui then
            pcall(function() radarGui:Destroy() end)
            radarGui = nil
        end
    end
end)

-- ══════════════════════
-- TITLE BAR BUTTONS
-- ══════════════════════
sizeInput.FocusLost:Connect(function()
    local v = tonumber(sizeInput.Text)
    if v then
        v = math.max(1, v)
        S.Size = v
        local ns = v/10
        main.Size = UDim2.new(0,210*ns,0,370*ns)
    end
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    main.Size = minimized
        and UDim2.new(0,main.Size.X.Offset,0,28*sc)
        or UDim2.new(0,210*sc,0,370*sc)
    minBtn.Text = minimized and "▲" or "–"
end)

closeBtn.MouseButton1Click:Connect(function()
    content.Visible = not content.Visible
    closeBtn.Text = content.Visible and "–" or "▲"
end)

delBtn.MouseButton1Click:Connect(function()
    stopLock()
    if radarGui then pcall(function() radarGui:Destroy() end) end
    sg:Destroy()
end)

-- ══════════════════════
-- HEARTBEAT STATUS UPDATE
-- ══════════════════════
RunService.Heartbeat:Connect(function()
    if S.Enabled then updateStatus() end
end)

print("[KuyLock v1] Loaded ✓")
