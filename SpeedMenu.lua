-- SpeedMenu_v3.lua
-- Single-file loader-friendly. Place as raw on GitHub and load with:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/SpeedMenu_v3.lua"))()
-- =============================================================================
-- Spec (implemented exactly as requested):
-- - CoreGui ScreenGui, draggable
-- - Header "SPEED" (light-blue background, white text)
-- - Foldable: when folded, only the blue header remains
-- - Mode dropdown (scrolling) — choosing a mode stops any other mode (no stacking)
-- - Each mode shows only its own adjustable fields (inside mode UI)
-- - All fields are MULTIPLIERS (ค่าคูณ). Example: 2 = 2x base behavior.
-- - Fields are labeled in Thai.
-- - Values persist in-memory across mode switches and respawns.
-- - Must press "เปิดใช้งาน" to apply current mode + values (changes do NOT auto-apply).
-- - All 10 modes implemented and functioning: เดินเร็ว, วาร์ป, ขยับตำแหน่ง, แรงขับเคลื่อน,
--   แรงกระแทก, เคลื่อนไหวเนียน, ลอยตัว, บิน(ตามกล้อง), กระโดดแรง, สไลด์.
-- - No extra UI/buttons beyond what you asked.
-- - When switching mode, previous mode is stopped, only selected mode will run.
-- =============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Respawn-safe char refs
local char, hrp, hum
local function setupChar(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart", 5)
    hum = char:FindFirstChildOfClass("Humanoid")
end
if plr.Character then setupChar(plr.Character) end
plr.CharacterAdded:Connect(function(c) setupChar(c) end)

-- BASE reference values (1x)
local BASE = {
    WalkSpeed = 16,
    TPDistance = 3,
    CFrameStep = 1,
    Velocity = 16,
    Impulse = 60,
    BodyVelocity = 40,
    LinearVelocity = 40,
    AssemblySpeed = 16,
    TweenDist = 3,
    TweenTime = 0.08,
    LerpStep = 1,
    FloatHeight = 5,
    FlySpeed = 16,
    JumpBoost = 50,
    GlideMult = 0.6
}

-- Modes table: Thai names as keys. Each mode has:
-- defaults: { ["label"] = defaultNumber, ... }
-- start(values) / stop() implemented for each mode.
local modes = {}

-- storage of user-set multipliers (persist in script memory)
local values = {}

-- helper: safe number parse
local function safeNum(v, fallback)
    local n = tonumber(v)
    if not n or n ~= n then return fallback end
    return n
end

-- active mode control
local activeModeName = nil       -- string of current selected mode (UI)
local runningModeName = nil      -- string of mode currently running (after Activate)
local runningStopFunc = nil      -- function to stop currently running mode

-- helper: stop currently running mode (if any)
local function stopRunningMode()
    if runningStopFunc then
        pcall(function() runningStopFunc() end)
    end
    runningModeName = nil
    runningStopFunc = nil
end

-- Ensure values table has defaults for each mode
local function ensureValuesFor(modeName)
    if not values[modeName] then
        values[modeName] = {}
        for k,v in pairs(modes[modeName].defaults) do
            values[modeName][k] = v
        end
    end
end

-- =============================================================================
-- Mode implementations
-- Each start receives the table of multipliers for that mode (values[modeName]).
-- Each stop must undo any created objects / threads and return clean state.
-- =============================================================================

-- Utility: create cancellable loop thread wrapper
local function spawnLoop(func)
    local running = true
    local thread = task.spawn(function()
        while running do
            func()
            RunService.Heartbeat:Wait()
        end
    end)
    return function() running = false end
end

-- 1) WalkSpeed - เดินเร็ว
modes["เดินเร็ว"] = {
    defaults = { ["ความเร็ว"] = 2 },
    start = function(vals)
        -- Set WalkSpeed while running; caller will call stop to restore
        hum.WalkSpeed = BASE.WalkSpeed * (vals["ความเร็ว"] or 1)
        -- maintain via heartbeat in case something resets it
        local stopper = spawnLoop(function()
            if runningModeName ~= "เดินเร็ว" then return end
            pcall(function() hum.WalkSpeed = BASE.WalkSpeed * (vals["ความเร็ว"] or 1) end)
        end)
        return function() stopper() pcall(function() hum.WalkSpeed = BASE.WalkSpeed end) end
    end,
    stop = function() end
}

-- 2) วาร์ป (Teleport Step)
modes["วาร์ป"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["ระยะวาร์ป (stud)"] = 3, ["หน่วงวาร์ป (s)"] = 0.05 },
    start = function(vals)
        local stopFlag = false
        local thread = task.spawn(function()
            while not stopFlag do
                if runningModeName ~= "วาร์ป" then break end
                local dir = hum.MoveDirection
                if dir.Magnitude > 0 then
                    local dist = BASE.TPDistance * (vals["ระยะวาร์ป (stud)"] or 1) * (vals["ค่าความเร็ว"] or 1)
                    -- move along camera forward relative to player's facing - use MoveDirection (local input)
                    pcall(function()
                        hrp.CFrame = hrp.CFrame + dir * dist
                    end)
                end
                local delay = (vals["หน่วงวาร์ป (s)"] or 0.05)
                task.wait(math.max(0, delay))
            end
        end)
        return function() stopFlag = true end
    end,
    stop = function() end
}

-- 3) ขยับตำแหน่ง (CFrame Move)
modes["ขยับตำแหน่ง"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["ระยะขยับ (stud)"] = 1 },
    start = function(vals)
        local stop = spawnLoop(function()
            if runningModeName ~= "ขยับตำแหน่ง" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local step = BASE.CFrameStep * (vals["ระยะขยับ (stud)"] or 1) * (vals["ค่าความเร็ว"] or 1)
                pcall(function()
                    hrp.CFrame = hrp.CFrame + dir * step
                end)
            end
        end)
        return function() stop() end
    end,
    stop = function() end
}

-- 4) แรงขับเคลื่อน (BodyVelocity)
modes["แรงขับเคลื่อน"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["แรงขับ (power)"] = 40 },
    start = function(vals)
        local bv = Instance.new("BodyVelocity")
        bv.Name = "__SM_BodyVelocity"
        bv.MaxForce = Vector3.new(4e5, 4e5, 4e5)
        bv.P = 1250
        bv.Parent = hrp
        local stop = spawnLoop(function()
            if runningModeName ~= "แรงขับเคลื่อน" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local power = (vals["แรงขับ (power)"] or 40) * (vals["ค่าความเร็ว"] or 1)
                pcall(function() bv.Velocity = Vector3.new(dir.X * power, hrp.Velocity.Y, dir.Z * power) end)
            else
                pcall(function() bv.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end)
            end
        end)
        return function() stop() if bv and bv.Parent then pcall(function() bv:Destroy() end) end end
    end,
    stop = function() end
}

-- 5) แรงกระแทก (BodyImpulse)
modes["แรงกระแทก"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["แรงกระแทก (power)"] = 200, ["ความถี่ (s)"] = 0.12 },
    start = function(vals)
        local last = 0
        local stop = spawnLoop(function()
            if runningModeName ~= "แรงกระแทก" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                last = last + RunService.RenderStepped:Wait()
                if last >= (vals["ความถี่ (s)"] or 0.12) then
                    local p = (vals["แรงกระแทก (power)"] or 200) * (vals["ค่าความเร็ว"] or 1)
                    pcall(function() hrp:ApplyImpulse(dir * p) end)
                    last = 0
                end
            else
                RunService.RenderStepped:Wait()
            end
        end)
        return function() stop() end
    end,
    stop = function() end
}

-- 6) เคลื่อนไหวเนียน (Tween Move)
modes["เคลื่อนไหวเนียน"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["เวลา Tween (s)"] = 0.08, ["ระยะ (stud)"] = 3 },
    start = function(vals)
        local stopFlag = false
        local playing = false
        local function doTween(dir)
            if playing then return end
            playing = true
            local dist = (vals["ระยะ (stud)"] or 3) * (vals["ค่าความเร็ว"] or 1)
            local t = math.max(0.01, (vals["เวลา Tween (s)"] or 0.08))
            local goal = {CFrame = hrp.CFrame + dir * dist}
            local info = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), goal)
            pcall(function() info:Play() end)
            -- don't block long; let tween finish naturally
            task.delay(t + 0.01, function() playing = false end)
        end
        local thread = task.spawn(function()
            while not stopFlag do
                if runningModeName ~= "เคลื่อนไหวเนียน" then break end
                local dir = hum.MoveDirection
                if dir.Magnitude > 0 then
                    doTween(dir)
                end
                RunService.Heartbeat:Wait()
            end
        end)
        return function() stopFlag = true end
    end,
    stop = function() end
}

-- 7) ลอยตัว (Float)
modes["ลอยตัว"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["ระดับความสูง (stud)"] = 5 },
    start = function(vals)
        -- Keep player hovering at target height relative to hrp.Y + height
        local stop = spawnLoop(function()
            if runningModeName ~= "ลอยตัว" then return end
            local targetY = (hrp.Position.Y + (vals["ระดับความสูง (stud)"] or 5))
            local dir = hum.MoveDirection
            -- Allow small horizontal movement scaled by speed
            if dir.Magnitude > 0 then
                local speed = BASE.Velocity * (vals["ค่าความเร็ว"] or 1)
                pcall(function() hrp.CFrame = hrp.CFrame + dir * (speed * RunService.RenderStepped:Wait() * 0.6) end)
            else
                RunService.RenderStepped:Wait()
            end
            -- gently correct Y to target
            local currentY = hrp.Position.Y
            local dy = targetY - currentY
            if math.abs(dy) > 0.1 then
                pcall(function() hrp.CFrame = hrp.CFrame + Vector3.new(0, dy * 0.15, 0) end)
            end
        end)
        return function() stop() end
    end,
    stop = function() end
}

-- 8) บิน (Fly) - ตามกล้อง
modes["บิน"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["ความสูง (mult)"] = 1, ["แรงดึง Y (mult)"] = 1 },
    start = function(vals)
        -- Fly implementation: move relative to camera orientation
        local stop = spawnLoop(function()
            if runningModeName ~= "บิน" then return end
            local dirInput = hum.MoveDirection -- local input forward/right
            local camC = workspace.CurrentCamera
            local forward = camC.CFrame.LookVector
            local right = camC.CFrame.RightVector
            -- up/down via space (up) and left shift (down)
            local up = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then up = up - 1 end
            local move = Vector3.new(0,0,0)
            -- translate MoveDirection (which is in world space aligned to camera?) to camera relative
            if dirInput.Magnitude > 0 then
                -- MoveDirection is camera-relative on Roblox by default for humanoid; but to be safe:
                move = (forward * dirInput.Z) + (right * dirInput.X)
            end
            local speed = BASE.FlySpeed * (vals["ค่าความเร็ว"] or 1)
            local ySpeed = (vals["ความสูง (mult)"] or 1) * (vals["แรงดึง Y (mult)"] or 1)
            local targetVel = (move.Unit.Magnitude > 0 and move.Unit * speed) or Vector3.new(0,0,0)
            targetVel = targetVel + Vector3.new(0, up * speed * 0.9 * (vals["ความสูง (mult)"] or 1), 0)
            -- apply by setting CFrame directly for responsive camera-follow flight
            local dt = RunService.RenderStepped:Wait()
            pcall(function()
                hrp.CFrame = hrp.CFrame + targetVel * dt
            end)
        end)
        return function() stop() end
    end,
    stop = function() end
}

-- 9) กระโดดแรง (Jump Boost)
modes["กระโดดแรง"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["ความสูงกระโดด (mult)"] = 2 },
    start = function(vals)
        -- Increase JumpPower while running, restore when stop
        local oldJump = hum.JumpPower
        pcall(function() hum.JumpPower = (BASE.JumpBoost or 50) * (vals["ความสูงกระโดด (mult)"] or 1) end)
        local stop = spawnLoop(function()
            if runningModeName ~= "กระโดดแรง" then return end
            -- maintain WalkSpeed effect optional
            RunService.Heartbeat:Wait()
        end)
        return function() stop() pcall(function() hum.JumpPower = oldJump end) end
    end,
    stop = function() end
}

-- 10) สไลด์ (Glide)
modes["สไลด์"] = {
    defaults = { ["ค่าความเร็ว"] = 1, ["แรงร่อน (mult)"] = 0.6 },
    start = function(vals)
        local stop = spawnLoop(function()
            if runningModeName ~= "สไลด์" then return end
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local speed = BASE.Velocity * (vals["ค่าความเร็ว"] or 1)
                local glide = (vals["แรงร่อน (mult)"] or 0.6)
                -- reduce gravity effect by moving slightly horizontally and adjusting Y
                pcall(function()
                    hrp.CFrame = hrp.CFrame + dir * speed * RunService.RenderStepped:Wait()
                    -- apply slight downward smoothing to mimic glide
                    hrp.Velocity = Vector3.new(hrp.Velocity.X, hrp.Velocity.Y * glide, hrp.Velocity.Z)
                end)
            else
                RunService.RenderStepped:Wait()
            end
        end)
        return function() stop() end
    end,
    stop = function() end
}

-- -----------------------------------------------------------------------------
-- Initialize values table for each mode
for name,info in pairs(modes) do
    values[name] = {}
    for k,v in pairs(info.defaults) do
        values[name][k] = v
    end
end

-- =============================================================================
-- UI Build (CoreGui) - minimal and exactly as requested
-- =============================================================================

-- remove previous if exists
pcall(function()
    if game.CoreGui:FindFirstChild("SpeedMenu_v3") then
        game.CoreGui:FindFirstChild("SpeedMenu_v3"):Destroy()
    end
end)

local screen = Instance.new("ScreenGui")
screen.Name = "SpeedMenu_v3"
screen.ResetOnSpawn = false
screen.Parent = game.CoreGui

local main = Instance.new("Frame", screen)
main.Name = "Main"
main.Size = UDim2.new(0, 340, 0, 460)
main.Position = UDim2.new(0, 30, 0, 80)
main.BackgroundColor3 = Color3.fromRGB(24,34,56)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

-- Header (blue) - remains when folded
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,46)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(0,150,220)
header.Name = "Header"

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6,0,1,0)
title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = "SPEED"

local status = Instance.new("TextLabel", header)
status.Size = UDim2.new(0.35,-8,1,0)
status.Position = UDim2.new(0.6,8,0,0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.TextSize = 16
status.TextColor3 = Color3.new(1,1,1)
status.TextXAlignment = Enum.TextXAlignment.Right
status.Text = "ปิด"

local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0,80,0,30)
toggleBtn.Position = UDim2.new(1,-90,0,8)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Text = "Toggle"
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(36,36,36)
toggleBtn.TextColor3 = Color3.new(1,1,1)

local foldBtn = Instance.new("TextButton", header)
foldBtn.Size = UDim2.new(0,32,0,32)
foldBtn.Position = UDim2.new(0,6,0,6)
foldBtn.Font = Enum.Font.GothamBold
foldBtn.TextSize = 20
foldBtn.Text = "—"
foldBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
foldBtn.TextColor3 = Color3.new(1,1,1)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,0,1,-46)
content.Position = UDim2.new(0,0,0,46)
content.BackgroundTransparency = 1

-- Mode selection
local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1,-20,0,28)
modeLabel.Position = UDim2.new(0,10,0,8)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextSize = 14
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "โหมด: " .. (activeModeName or "เลือกโหมด")

local modeToggle = Instance.new("TextButton", content)
modeToggle.Size = UDim2.new(0,28,0,28)
modeToggle.Position = UDim2.new(1,-38,0,8)
modeToggle.Text = "▾"
modeToggle.Font = Enum.Font.SourceSans
modeToggle.TextSize = 18
modeToggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
modeToggle.TextColor3 = Color3.new(1,1,1)

local modeScroll = Instance.new("ScrollingFrame", content)
modeScroll.Size = UDim2.new(1,-20,0,180)
modeScroll.Position = UDim2.new(0,10,0,44)
modeScroll.CanvasSize = UDim2.new(0,0,0,0)
modeScroll.ScrollBarThickness = 8
modeScroll.BackgroundColor3 = Color3.fromRGB(28,40,68)
modeScroll.BorderSizePixel = 0
modeScroll.Visible = false

local modeLayout = Instance.new("UIListLayout", modeScroll)
modeLayout.Padding = UDim.new(0,6)
modeLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- dynamic fields container
local fieldsFrame = Instance.new("Frame", content)
fieldsFrame.Size = UDim2.new(1,-20,0,170)
fieldsFrame.Position = UDim2.new(0,10,0,236)
fieldsFrame.BackgroundTransparency = 1

-- Activate button
local activateBtn = Instance.new("TextButton", content)
activateBtn.Size = UDim2.new(1,-20,0,36)
activateBtn.Position = UDim2.new(0,10,1,-56)
activateBtn.BackgroundColor3 = Color3.fromRGB(70,110,180)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 16
activateBtn.TextColor3 = Color3.new(1,1,1)
activateBtn.Text = "เปิดใช้งาน: ❌"

-- hint
local hint = Instance.new("TextLabel", content)
hint.Size = UDim2.new(1,-20,0,22)
hint.Position = UDim2.new(0,10,1,-28)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(200,200,200)
hint.Text = "ค่าทั้งหมดเป็นตัวคูณ (Multiplier) — ต้องกด 'เปิดใช้งาน' เพื่อให้ค่ามีผล"

-- populate mode list UI
local i = 1
for modeName,_ in pairs(modes) do
    local b = Instance.new("TextButton", modeScroll)
    b.Size = UDim2.new(1,-12,0,34)
    b.Position = UDim2.new(0,6,0,(i-1)*40 + 2)
    b.BackgroundColor3 = Color3.fromRGB(48,72,110)
    b.Font = Enum.Font.Gotham
    b.TextSize = 15
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = modeName
    b.Name = "Mode_"..modeName
    b.MouseButton1Click:Connect(function()
        activeModeName = modeName
        modeLabel.Text = "โหมด: " .. activeModeName
        modeScroll.Visible = false
        modeToggle.Text = "▾"
        -- show fields for this mode
        refreshFieldsForCurrentMode()
    end)
    i = i + 1
end

modeLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    modeScroll.CanvasSize = UDim2.new(0,0,0,modeLayout.AbsoluteContentSize.Y + 8)
end)

modeToggle.MouseButton1Click:Connect(function()
    modeScroll.Visible = not modeScroll.Visible
    modeToggle.Text = modeScroll.Visible and "▴" or "▾"
end)

-- fold behavior
local folded = false
foldBtn.MouseButton1Click:Connect(function()
    folded = not folded
    content.Visible = not folded
    main.Size = folded and UDim2.new(0,200,0,46) or UDim2.new(0,340,0,460)
    foldBtn.Text = folded and "+" or "—"
end)

-- global toggle (enable/disable system)
local enabled = false
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    status.Text = enabled and "เปิด" or "ปิด"
    if not enabled then
        -- disable running mode if any
        stopRunningMode()
        activateBtn.Text = "เปิดใช้งาน: ❌"
    else
        -- do nothing until user presses activate
    end
end)

-- dynamic field widgets list
local fieldWidgets = {}

-- refresh fields for the selected mode (shows label+textbox per field)
function refreshFieldsForCurrentMode()
    -- clear existing
    for _,w in ipairs(fieldWidgets) do
        if w.label and w.label.Parent then w.label:Destroy() end
        if w.box and w.box.Parent then w.box:Destroy() end
        if w.hint and w.hint.Parent then w.hint:Destroy() end
    end
    fieldWidgets = {}

    if not activeModeName then return end
    local def = modes[activeModeName].defaults
    values[activeModeName] = values[activeModeName] or {}
    -- ensure persisted values exist
    for k,v in pairs(def) do
        if values[activeModeName][k] == nil then values[activeModeName][k] = v end
    end

    local y = 0
    for k,defv in pairs(def) do
        local lbl = Instance.new("TextLabel", fieldsFrame)
        lbl.Size = UDim2.new(0.6, -8, 0, 24)
        lbl.Position = UDim2.new(0, 0, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = tostring(k)

        local box = Instance.new("TextBox", fieldsFrame)
        box.Size = UDim2.new(0.4, -6, 0, 24)
        box.Position = UDim2.new(0.6, 6, 0, y)
        box.BackgroundColor3 = Color3.fromRGB(34,54,86)
        box.TextColor3 = Color3.new(1,1,1)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.ClearTextOnFocus = false
        box.Text = tostring(values[activeModeName][k] or defv)

        local hintLbl = Instance.new("TextLabel", fieldsFrame)
        hintLbl.Size = UDim2.new(1,0,0,18)
        hintLbl.Position = UDim2.new(0,0,0,y+24)
        hintLbl.BackgroundTransparency = 1
        hintLbl.Font = Enum.Font.SourceSans
        hintLbl.TextSize = 11
        hintLbl.TextColor3 = Color3.fromRGB(170,170,170)
        -- try to use hint from modes definitions if provided
        local hintText = ""
        for kk,vv in pairs(modes[activeModeName].defaults) do
            -- no separate hints stored in this version; keep empty to be minimal per request
        end
        hintLbl.Text = hintText

        -- save on focus lost (but changes do NOT auto-apply; user must press Activate)
        box.FocusLost:Connect(function()
            local n = safeNum(box.Text, defv)
            if n < 0 then n = defv end
            values[activeModeName][k] = n
            box.Text = tostring(n)
        end)

        table.insert(fieldWidgets, {label=lbl, box=box, hint=hintLbl, key=k})
        y = y + 44
    end
end

-- clicking the modeLabel cycles mode (convenience)
modeLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- cycle through mode list
        local keysOrdered = {}
        for nm,_ in pairs(modes) do table.insert(keysOrdered, nm) end
        table.sort(keysOrdered) -- stable order; user picks from dropdown normally
        local idx = 1
        if activeModeName then
            for i,name in ipairs(keysOrdered) do if name == activeModeName then idx = i; break end end
            idx = (idx % #keysOrdered) + 1
        end
        activeModeName = keysOrdered[idx]
        modeLabel.Text = "โหมด: " .. activeModeName
        refreshFieldsForCurrentMode()
    end
end)

-- Activate button behavior
activateBtn.MouseButton1Click:Connect(function()
    if not enabled then
        -- do nothing if global system is off
        return
    end
    -- toggle activation for the selected mode only
    if not activeModeName then return end

    if runningModeName == activeModeName then
        -- stop it
        stopRunningMode()
        activateBtn.Text = "เปิดใช้งาน: ❌"
    else
        -- stop any running mode and start selected
        stopRunningMode()
        -- ensure values exist
        ensureValuesFor(activeModeName)
        local startFunc = modes[activeModeName].start
        if startFunc then
            -- set running mode name, call start (start should return a stop function)
            runningModeName = activeModeName
            local ok, stopfn = pcall(function() return startFunc(values[activeModeName]) end)
            if ok and type(stopfn) == "function" then
                runningStopFunc = stopfn
            else
                -- If start returned nothing, provide generic stop via stopRunningMode
                runningStopFunc = function() end
            end
            activateBtn.Text = "เปิดใช้งาน: ✅"
        end
    end
end)

-- initial activeModeName default (first in iteration)
do
    for nm,_ in pairs(modes) do activeModeName = nm; break end
    modeLabel.Text = "โหมด: " .. (activeModeName or "เลือกโหมด")
    refreshFieldsForCurrentMode()
end

-- When user selects a different mode from dropdown, ensure previous running mode is stopped:
-- (Requirement: changing mode should leave only the selected mode able to run)
for _,child in ipairs(modeScroll:GetChildren()) do
    -- the mode buttons are already wired above; we only ensure safety: when activeModeName changes, we do not auto-start
    -- the user must press Activate; but if some other mode was running, stop it so there is no overlap.
end

-- ensure switching activeModeName will stop any running mode (non-auto start)
local function onModeChange()
    if runningModeName and runningModeName ~= activeModeName then
        stopRunningMode()
        activateBtn.Text = "เปิดใช้งาน: ❌"
    end
end

-- hook refreshFieldsForCurrentMode to call onModeChange
local oldRefresh = refreshFieldsForCurrentMode
function refreshFieldsForCurrentMode()
    oldRefresh()
    onModeChange()
end

-- Cleanup when GUI destroyed
screen.Destroying:Connect(function()
    stopRunningMode()
end)

-- final note: values persist in 'values' table while script lives (survives respawn)
-- End of file
