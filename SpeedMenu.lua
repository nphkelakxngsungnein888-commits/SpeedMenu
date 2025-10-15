-- SpeedMenu v3.0
-- Single-file loader: drop into GitHub raw and run with loadstring(game:HttpGet("<RAW>"))()
-- Features:
--  - GUI in CoreGui, draggable, foldable -> leaves only blue header when folded
--  - Mode switch stops all other modes automatically
--  - Each mode has its own Thai-labeled multiplier fields (values persist until changed)
--  - Must press "เปิดใช้งาน" to apply changed values
--  - Supports many movement modes (WalkSpeed, TP, CFrame, Impulse, BodyVelocity, LinearVelocity,
--    AssemblyLinearVelocity, Hover, Flight, Lerp, Instant TP (key), Tween)
-- Use in Studio / Private game only. Use responsibly.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local plr = Players.LocalPlayer

-- Character refs (respawn-safe)
local char, hrp, hum
local function setupChar(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
end
if plr.Character then setupChar(plr.Character) end
plr.CharacterAdded:Connect(function(c) setupChar(c) end)

-- BASE values (1x references)
local BASE = {
    WalkSpeed = 16,
    Velocity = 16,
    CFrameStep = 1,
    TPDistance = 3,
    ImpulsePower = 60,
    BodyVelocityPower = 40,
    LinearVelocityPower = 40,
    AssemblySpeed = 16,
    HoverHeight = 3,
    FlightSpeed = 20,
    TweenDistance = 3,
    TweenTime = 0.08,
    LerpStep = 1,
    InstantTPDistance = 6
}

-- Modes definition: fields = list { name, def, hint }
local MODES_DEF = {
    ["เดินเร็ว"] = { fields = { {name="ค่าความเร็ว", def=2, hint="คูณ WalkSpeed (เช่น 2 = 2x)"} } },
    ["วาร์ป"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณค่า TP ทั้งหมด"}, {name="ระยะวาร์ป", def=3, hint="ระยะวาร์ป (studs)"}, {name="หน่วงวาร์ป", def=0.05, hint="หน่วงเวลา (วินาที) ระหว่างขั้น)"} } },
    ["ขยับตำแหน่ง"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณ step"}, {name="ระยะขยับ", def=1, hint="ระยะต่อเฟรม (studs)"} } },
    ["แรงกระแทก"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณแรง"}, {name="ความถี่", def=1, hint="คูณ interval (เล็ก=ถี่ขึ้น)"} } },
    ["ดันตัวด้วยแรง"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณแรง BodyVelocity"}, {name="MaxForce Mult", def=1, hint="คูณ MaxForce"} } },
    ["ดันตัว (Linear)"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณ LinearVelocity"}, {name="MaxForce Mult", def=1, hint="คูณ MaxForce"} } },
    ["ความเร็วฟิสิกส์"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณ AssemblyLinearVelocity"}, {name="จำกัดแกน Y (1=จำกัด,0=ไม่จำกัด)", def=1, hint="จำกัดการเปลี่ยน Y เมื่อ 1"} } },
    ["ลอย"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณความเร็วแนวนอน"}, {name="ระดับลอย", def=3, hint="ระยะเหนือพื้น (studs)"} } },
    ["บิน"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณ Flight speed"}, {name="ความเร็วขึ้น/ลง", def=1, hint="คูณความเร็วแนวตั้ง"} } },
    ["เลื่อนนุ่มนวล"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณ step ของ Lerp"}, {name="ความนุ่ม (alphaScale)", def=1, hint="คูณ alpha (0-1 scaled)"} } },
    ["วาร์ปทันที"] = { fields = { {name="ระยะวาร์ป", def=6, hint="กดปุ่มคีย์เพื่อวาร์ป (studs)"} } },
    ["Tween เคลื่อนที่"] = { fields = { {name="ค่าความเร็ว", def=1, hint="คูณ distance"}, {name="เวลา Tween", def=1, hint="คูณเวลา (smaller = faster)"} } }
}

-- Persistent runtime values (keeps user inputs)
local values = {}
for name,def in pairs(MODES_DEF) do
    values[name] = {}
    for _,f in ipairs(def.fields) do
        values[name][f.name] = f.def
    end
end

-- active mode tracking
local currentMode = nil
local active = false

-- mover objects & connections for cleanup
local activeBV, activeLV, activeLVAtt, activeBP
local connections = {}

local function cleanupMovers()
    -- destroy BodyVelocity
    if activeBV and activeBV.Parent then pcall(function() activeBV:Destroy() end) end
    activeBV = nil
    -- destroy LinearVelocity + Attachment
    if activeLV and activeLV.Parent then pcall(function() activeLV:Destroy() end) end
    activeLV = nil
    if activeLVAtt and activeLVAtt.Parent then pcall(function() activeLVAtt:Destroy() end) end
    activeLVAtt = nil
    -- BodyPosition for hover
    if activeBP and activeBP.Parent then pcall(function() activeBP:Destroy() end) end
    activeBP = nil
    -- disconnect connections
    for _,c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
end

-- helper safe number parse
local function safeNum(v, fallback)
    local n = tonumber(v)
    if not n or n ~= n then return fallback end
    return n
end

-- UI builder (Instance.new style)
local GUI_NAME = "SpeedMenu_v3"
pcall(function() if game.CoreGui:FindFirstChild(GUI_NAME) then game.CoreGui[GUI_NAME]:Destroy() end end)

local screen = Instance.new("ScreenGui")
screen.Name = GUI_NAME
screen.ResetOnSpawn = false
screen.Parent = game.CoreGui

local main = Instance.new("Frame", screen)
main.Name = "Main"
main.Size = UDim2.new(0,380,0,520)
main.Position = UDim2.new(0,24,0,80)
main.BackgroundColor3 = Color3.fromRGB(18,30,48)
main.Active = true
main.Draggable = true
main.BorderSizePixel = 0

-- header (blue)
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,48)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(0,130,220)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6,0,1,0)
title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ SPEED"

-- fold button is clicking header
local folded = false
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,0,1,-48)
content.Position = UDim2.new(0,0,0,48)
content.BackgroundTransparency = 1

header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        folded = not folded
        content.Visible = not folded
        main.Size = folded and UDim2.new(0,200,0,48) or UDim2.new(0,380,0,520)
        -- keep header text only when folded
    end
end)

-- status label + global toggle
local status = Instance.new("TextLabel", header)
status.Size = UDim2.new(0.35,-8,1,0)
status.Position = UDim2.new(0.6,8,0,0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.TextSize = 16
status.TextColor3 = Color3.new(1,1,1)
status.TextXAlignment = Enum.TextXAlignment.Right
status.Text = "OFF"

local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0,72,0,30)
toggleBtn.Position = UDim2.new(1,-82,0,8)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Text = "Toggle"
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
toggleBtn.TextColor3 = Color3.new(1,1,1)

toggleBtn.MouseButton1Click:Connect(function()
    active = not active
    status.Text = active and "ON" or "OFF"
    if not active then
        -- stop all modes
        cleanupMovers()
        -- if humanoid exists restore walk speed
        pcall(function() if hum then hum.WalkSpeed = BASE.WalkSpeed end end)
    end
end)

-- Mode selector
local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1,-20,0,28)
modeLabel.Position = UDim2.new(0,10,0,8)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "โหมด: (เลือก)"

local modeToggle = Instance.new("TextButton", content)
modeToggle.Size = UDim2.new(0,28,0,28)
modeToggle.Position = UDim2.new(1,-38,0,8)
modeToggle.Text = "▾"
modeToggle.Font = Enum.Font.SourceSans
modeToggle.TextSize = 18
modeToggle.BackgroundColor3 = Color3.fromRGB(36,36,36)
modeToggle.TextColor3 = Color3.new(1,1,1)

local scroll = Instance.new("ScrollingFrame", content)
scroll.Size = UDim2.new(1,-20,0,200)
scroll.Position = UDim2.new(0,10,0,44)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 8
scroll.BackgroundColor3 = Color3.fromRGB(22,34,56)
scroll.BorderSizePixel = 0
scroll.Visible = false

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0,6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local modeListOrdered = {}
for name in pairs(MODES_DEF) do table.insert(modeListOrdered, name) end
table.sort(modeListOrdered) -- sort alphabetically for stable order; you can reorder if wanted

for i, mName in ipairs(modeListOrdered) do
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1,-12,0,36)
    b.Position = UDim2.new(0,6,0,(i-1)*44 + 2)
    b.BackgroundColor3 = Color3.fromRGB(44,64,96)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 15
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = mName
    b.MouseButton1Click:Connect(function()
        currentMode = mName
        modeLabel.Text = "โหมด: " .. mName
        scroll.Visible = false
        modeToggle.Text = "▾"
        refreshFieldsForCurrentMode()
    end)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y + 8)
end)

modeToggle.MouseButton1Click:Connect(function()
    scroll.Visible = not scroll.Visible
    modeToggle.Text = scroll.Visible and "▴" or "▾"
end)

-- fields container
local fieldsFrame = Instance.new("Frame", content)
fieldsFrame.Size = UDim2.new(1,-20,0,220)
fieldsFrame.Position = UDim2.new(0,10,0,256)
fieldsFrame.BackgroundTransparency = 1

-- activate button (per mode)
local activateBtn = Instance.new("TextButton", content)
activateBtn.Size = UDim2.new(1,-20,0,36)
activateBtn.Position = UDim2.new(0,10,1,-56)
activateBtn.BackgroundColor3 = Color3.fromRGB(68,104,160)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 16
activateBtn.TextColor3 = Color3.new(1,1,1)
activateBtn.Text = "เปิดใช้งาน: ❌"

local hint = Instance.new("TextLabel", content)
hint.Size = UDim2.new(1,-20,0,24)
hint.Position = UDim2.new(0,10,1,-28)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(200,200,200)
hint.Text = "ทุกช่องเป็นตัวคูณ (Multiplier). ตัวอย่าง ใส่ 2 = 2x"

-- dynamic field widgets
local fieldWidgets = {}

function refreshFieldsForCurrentMode()
    -- clear
    for _,w in ipairs(fieldWidgets) do
        if w.label and w.label.Parent then w.label:Destroy() end
        if w.box and w.box.Parent then w.box:Destroy() end
        if w.hint and w.hint.Parent then w.hint:Destroy() end
    end
    fieldWidgets = {}

    if not currentMode then return end
    local def = MODES_DEF[currentMode]
    if not def then return end
    local y = 0
    values[currentMode] = values[currentMode] or {}
    for i,field in ipairs(def.fields) do
        local lbl = Instance.new("TextLabel", fieldsFrame)
        lbl.Size = UDim2.new(0.58,-6,0,26)
        lbl.Position = UDim2.new(0,0,0,y)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = field.name

        local box = Instance.new("TextBox", fieldsFrame)
        box.Size = UDim2.new(0.42,-6,0,26)
        box.Position = UDim2.new(0.58,6,0,y)
        box.BackgroundColor3 = Color3.fromRGB(34,54,86)
        box.TextColor3 = Color3.new(1,1,1)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.ClearTextOnFocus = false
        box.Text = tostring(values[currentMode][field.name] or field.def)

        local hintLbl = Instance.new("TextLabel", fieldsFrame)
        hintLbl.Size = UDim2.new(1,0,0,18)
        hintLbl.Position = UDim2.new(0,0,0,y+26)
        hintLbl.BackgroundTransparency = 1
        hintLbl.Font = Enum.Font.SourceSans
        hintLbl.TextSize = 11
        hintLbl.TextColor3 = Color3.fromRGB(170,170,170)
        hintLbl.Text = field.hint or ""

        box.FocusLost:Connect(function()
            local n = safeNum(box.Text, values[currentMode][field.name] or field.def)
            if n < 0 then n = values[currentMode][field.name] or field.def end
            values[currentMode][field.name] = n
            box.Text = tostring(n)
        end)

        table.insert(fieldWidgets, {label=lbl, box=box, hint=hintLbl, name=field.name})
        y = y + 46
    end
end

-- cycling convenience
modeLabel.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        -- cycle through modes
        local idx = 1
        for i,name in ipairs(modeListOrdered) do
            if name == currentMode then idx = i; break end
        end
        idx = (idx % #modeListOrdered) + 1
        currentMode = modeListOrdered[idx]
        modeLabel.Text = "โหมด: " .. currentMode
        refreshFieldsForCurrentMode()
    end
end)

-- activate button behavior
activateBtn.MouseButton1Click:Connect(function()
    -- toggle active for current Mode
    if not currentMode then return end
    -- stop everything first
    cleanupMovers()
    for n,_ in pairs(MODES_DEF) do
        -- nothing extra to mark; we will manage single mode behavior by starting only current
    end

    if active and currentMode then
        -- start chosen mode
        -- set main active indicator already via global toggle
    end

    -- start or stop current mode only (user must have global toggle ON for movement to apply)
    if not active then
        activateBtn.Text = "เปิดใช้งาน: ❌"
        return
    end

    activateBtn.Text = "เปิดใช้งาน: ✅"

    -- call start implementation per mode
    startMode(currentMode, values[currentMode] or {})
end)

-- key bindings & instant-TP state
local instantTPKey = Enum.KeyCode.E
local instantTPConn = nil

-- helper: stop all mode threads / connections and restore default
local function stopAllModes()
    cleanupMovers()
    -- restore default walk speed
    pcall(function() if hum then hum.WalkSpeed = BASE.WalkSpeed end end)
end

-- Start Mode dispatcher: implements each mode logic (stop cleanup done via cleanupMovers and stored refs)
function startMode(modeName, val)
    -- ensure char/hum ready
    if not hrp or not hum then return end

    -- STOP previous movers
    cleanupMovers()

    -- implement per-mode
    if modeName == "เดินเร็ว" then
        local mult = val["ค่าความเร็ว"] or 1
        pcall(function() hum.WalkSpeed = BASE.WalkSpeed * mult end)

    elseif modeName == "วาร์ป" then
        -- spawn loop tp small steps; uses forward direction (Humanoid.MoveDirection)
        local mult = val["ค่าความเร็ว"] or 1
        local dist = (val["ระยะวาร์ป"] or 1) * mult
        local delay = (val["หน่วงวาร์ป"] or 0.05)
        local thr = task.spawn(function()
            while active and currentMode == "วาร์ป" do
                local dir = hum.MoveDirection
                if dir.Magnitude > 0 then
                    local newcf = hrp.CFrame + dir.Unit * dist
                    pcall(function() hrp.CFrame = newcf end)
                end
                task.wait(delay)
            end
        end)
        table.insert(connections, {Disconnect = function() task.cancel(thr) end})

    elseif modeName == "ขยับตำแหน่ง" then
        local mult = val["ค่าความเร็ว"] or 1
        local step = (val["ระยะขยับ"] or 1) * mult
        local thr = RunService.RenderStepped:Connect(function()
            if not active or currentMode ~= "ขยับตำแหน่ง" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                pcall(function() hrp.CFrame = hrp.CFrame + dir.Unit * step end)
            end
        end)
        table.insert(connections, thr)

    elseif modeName == "แรงกระแทก" then
        local mult = val["ค่าความเร็ว"] or 1
        local intervalMult = val["ความถี่"] or 1
        local cooldown = 0
        local conn = RunService.Heartbeat:Connect(function(dt)
            if not active or currentMode ~= "แรงกระแทก" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                cooldown = cooldown + dt
                local interval = 0.12 * intervalMult
                if cooldown >= interval then
                    local force = dir.Unit * (BASE.ImpulsePower * mult)
                    pcall(function() hrp:ApplyImpulse(force) end)
                    cooldown = 0
                end
            end
        end)
        table.insert(connections, conn)

    elseif modeName == "ดันตัวด้วยแรง" then
        -- BodyVelocity approach
        local mult = val["ค่าความเร็ว"] or 1
        local maxForceMult = val["MaxForce Mult"] or 1
        local bv = Instance.new("BodyVelocity")
        bv.Name = "__SM_BV"
        bv.MaxForce = Vector3.new(4e5 * maxForceMult, 4e5 * maxForceMult, 4e5 * maxForceMult)
        bv.P = 1250
        bv.Parent = hrp
        activeBV = bv
        local conn = RunService.Heartbeat:Connect(function()
            if not active or currentMode ~= "ดันตัวด้วยแรง" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                pcall(function() bv.Velocity = dir.Unit * (BASE.BodyVelocityPower * mult) end)
            else
                pcall(function() bv.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end)
            end
        end)
        table.insert(connections, conn)

    elseif modeName == "ดันตัว (Linear)" then
        -- LinearVelocity with Attachment
        local mult = val["ค่าความเร็ว"] or 1
        local maxForceMult = val["MaxForce Mult"] or 1
        local att = Instance.new("Attachment", hrp)
        att.Name = "__SM_LV_Att"
        local lv = Instance.new("LinearVelocity")
        lv.Name = "__SM_LV"
        lv.Attachment0 = att
        lv.MaxForce = Vector3.new(1e6 * maxForceMult, 1e6 * maxForceMult, 1e6 * maxForceMult)
        lv.Parent = hrp
        activeLVAtt = att
        activeLV = lv
        local conn = RunService.Heartbeat:Connect(function()
            if not active or currentMode ~= "ดันตัว (Linear)" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                pcall(function() lv.VectorVelocity = Vector3.new(dir.Unit.X * (BASE.LinearVelocityPower * mult), 0, dir.Unit.Z * (BASE.LinearVelocityPower * mult)) end)
            else
                pcall(function() lv.VectorVelocity = Vector3.new(0,0,0) end)
            end
        end)
        table.insert(connections, conn)

    elseif modeName == "ความเร็วฟิสิกส์" then
        local mult = val["ค่าความเร็ว"] or 1
        local limitY = val["จำกัดแกน Y (1=จำกัด,0=ไม่จำกัด)"] or 1
        local conn = RunService.Heartbeat:Connect(function()
            if not active or currentMode ~= "ความเร็วฟิสิกส์" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local v = hrp.AssemblyLinearVelocity
                local newv = Vector3.new(dir.Unit.X * (BASE.AssemblySpeed * mult), v.Y, dir.Unit.Z * (BASE.AssemblySpeed * mult))
                if limitY == 1 or tostring(limitY) == "1" then newv = Vector3.new(newv.X, 0, newv.Z) end
                pcall(function() hrp.AssemblyLinearVelocity = newv end)
            end
        end)
        table.insert(connections, conn)

    elseif modeName == "ลอย" then
        -- BodyPosition to hold height + optional horizontal move
        local horizMult = val["ค่าความเร็ว"] or 1
        local height = val["ระดับลอย"] or BASE.HoverHeight
        local bp = Instance.new("BodyPosition")
        bp.Name = "__SM_BP"
        bp.MaxForce = Vector3.new(4e4, 4e4, 4e4)
        bp.P = 1250
        bp.D = 100
        bp.Parent = hrp
        activeBP = bp
        local conn = RunService.Heartbeat:Connect(function()
            if not active or currentMode ~= "ลอย" then return end
            -- maintain target position hrp.CFrame + (0,height,0)
            local target = hrp.Position + Vector3.new(0, height, 0)
            pcall(function() bp.Position = target end)
            -- allow gentle horizontal move
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                pcall(function() hrp.CFrame = hrp.CFrame + dir.Unit * (BASE.LinearVelocityPower * 0.02 * horizMult) end)
            end
        end)
        table.insert(connections, conn)

    elseif modeName == "บิน" then
        -- Flight: uses AssemblyLinearVelocity, supports ascend/descend with Space / LeftControl
        local horizMult = val["ค่าความเร็ว"] or 1
        local vertMult = val["ความเร็วขึ้น/ลง"] or 1
        local ascend = false
        local descend = false

        -- input handlers for ascend/descend
        local function inputBegan(inp)
            if inp.KeyCode == Enum.KeyCode.Space then ascend = true end
            if inp.KeyCode == Enum.KeyCode.LeftControl or inp.KeyCode == Enum.KeyCode.C then descend = true end
        end
        local function inputEnded(inp)
            if inp.KeyCode == Enum.KeyCode.Space then ascend = false end
            if inp.KeyCode == Enum.KeyCode.LeftControl or inp.KeyCode == Enum.KeyCode.C then descend = false end
        end

        local conn1 = UserInputService.InputBegan:Connect(inputBegan)
        local conn2 = UserInputService.InputEnded:Connect(inputEnded)
        table.insert(connections, conn1)
        table.insert(connections, conn2)

        local conn = RunService.Heartbeat:Connect(function()
            if not active or currentMode ~= "บิน" then return end
            local dir = hum.MoveDirection
            local xz = Vector3.new(dir.X, 0, dir.Z).Unit
            if dir.Magnitude == 0 then xz = Vector3.new(0,0,0) else xz = Vector3.new(dir.Unit.X, 0, dir.Unit.Z) end
            local up = 0
            if ascend then up = 1 * vertMult elseif descend then up = -1 * vertMult else up = 0 end
            local vel = Vector3.new(xz.X * (BASE.FlightSpeed * horizMult), up * (BASE.FlightSpeed * vertMult), xz.Z * (BASE.FlightSpeed * horizMult))
            pcall(function() hrp.AssemblyLinearVelocity = vel end)
        end)
        table.insert(connections, conn)

    elseif modeName == "เลื่อนนุ่มนวล" then
        local mult = val["ค่าความเร็ว"] or 1
        local alphaScale = val["ความนุ่ม (alphaScale)"] or 1
        local conn = RunService.RenderStepped:Connect(function()
            if not active or currentMode ~= "เลื่อนนุ่มนวล" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local step = BASE.LerpStep * mult
                local alpha = math.clamp(0.01 * alphaScale, 0.01, 1)
                local target = hrp.CFrame + dir.Unit * step
                pcall(function() hrp.CFrame = hrp.CFrame:Lerp(target, alpha) end)
            end
        end)
        table.insert(connections, conn)

    elseif modeName == "วาร์ปทันที" then
        -- bind key E for instant TP once
        local dist = val["ระยะวาร์ป"] or BASE.InstantTPDistance
        if instantTPConn then pcall(function() instantTPConn:Disconnect() end) end
        instantTPConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.E then
                -- teleport forward by dist
                local dir = hrp.CFrame.LookVector
                local newcf = hrp.CFrame + dir * dist
                pcall(function() hrp.CFrame = newcf end)
            end
        end)
        table.insert(connections, instantTPConn)

    elseif modeName == "Tween เคลื่อนที่" then
        local distMult = val["ค่าความเร็ว"] or 1
        local timeMult = val["เวลา Tween"] or 1
        -- each frame, on input create a short tween toward next position
        local conn = UserInputService.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            -- we will not rely on key presses; instead do on RenderStepped if movement present
        end)
        table.insert(connections, conn)
        local conn2 = RunService.Heartbeat:Connect(function()
            if not active or currentMode ~= "Tween เคลื่อนที่" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local dist = BASE.TweenDistance * distMult
                local ttime = math.max(0.01, BASE.TweenTime * timeMult)
                local goal = {CFrame = hrp.CFrame + dir.Unit * dist}
                pcall(function()
                    local tw = TweenService:Create(hrp, TweenInfo.new(ttime, Enum.EasingStyle.Linear), goal)
                    tw:Play()
                end)
            end
        end)
        table.insert(connections, conn2)
    end
end

-- ensure switching modes stops previous: when currentMode changed, stopAllModes then start chosen only when user pressed Activate
-- We'll store a simple variable to track lastActivatedMode
local lastActivatedMode = nil

-- When user presses activate button we run startMode for the chosen mode only
activateBtn.MouseButton1Click:Connect(function()
    if not currentMode then return end
    -- Toggle activation state of the currently selected mode
    -- BUT per your request, require global "Toggle" to be ON to start effects
    if not active then
        activateBtn.Text = "เปิดใช้งาน: ❌"
        return
    end

    -- stop all before starting
    stopAllModes()

    -- start selected
    activateBtn.Text = "เปิดใช้งาน: ✅"
    startMode(currentMode, values[currentMode] or {})
    lastActivatedMode = currentMode
end)

-- When user changes mode via UI, we should stop previous active mode immediately
-- We'll hook into refresh (already called on selection)
local prevMode = nil
local function onModeSwitched()
    if prevMode and prevMode ~= currentMode then
        -- stop previous
        stopAllModes()
        activateBtn.Text = "เปิดใช้งาน: ❌"
    end
    prevMode = currentMode
end

-- call onModeSwitched when refresh
local origRefresh = refreshFieldsForCurrentMode
function refreshFieldsForCurrentMode()
    onModeSwitched()
    origRefresh()
end

-- initial refresh
refreshFieldsForCurrentMode()

-- Ensure when global toggle is turned OFF, everything stops
toggleBtn.MouseButton1Click:Connect(function()
    active = not active
    status.Text = active and "ON" or "OFF"
    if not active then
        stopAllModes()
        activateBtn.Text = "เปิดใช้งาน: ❌"
    else
        -- if user had previously activated a mode, they will need to press Activate again to apply
        activateBtn.Text = "เปิดใช้งาน: ❌"
    end
end)

-- cleanup when script GUI destroyed
screen.Destroying:Connect(function()
    stopAllModes()
end)

-- Finish: initial UI state
status.Text = "OFF"
activateBtn.Text = "เปิดใช้งาน: ❌"
modeLabel.Text = "โหมด: (เลือก)"
scroll.Visible = false

-- End of SpeedMenu v3.0
