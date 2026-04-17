-- ============================================================
--  ULTRA MENU v1.0 | by kuy kuy
--  SERVICES / VARIABLES / FUNCTIONS / UI / MAIN LOOP
-- ============================================================

-- ██ SERVICES
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")

-- ██ PLAYER REFS
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ██ CHARACTER HELPERS
local function getChar()
    return LocalPlayer.Character
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============================================================
-- ██ STATE
-- ============================================================
local State = {
    menuScale    = 5,          -- 1-10
    minimized    = false,
    -- F1 Speed
    speedOn      = false,
    speedMult    = 2,
    -- F2 Jump
    jumpOn       = false,
    jumpPower    = 100,
    jumpCount    = 3,
    _jumpLeft    = 0,
    _isGrounded  = true,
    -- F3 Noclip
    noclipOn     = false,
    -- F5 Fly
    flyOn        = false,
    flySpeed     = 2,
    -- F6 Float
    floatOn      = false,
    floatOffset  = 1,
}

-- ============================================================
-- ██ CLEANUP CONNECTION STORE
-- ============================================================
local Connections = {}
local function storeConn(key, conn)
    if Connections[key] then
        pcall(function() Connections[key]:Disconnect() end)
    end
    Connections[key] = conn
end
local function killConn(key)
    if Connections[key] then
        pcall(function() Connections[key]:Disconnect() end)
        Connections[key] = nil
    end
end

-- ============================================================
-- ██ F1 – SPEED
-- ============================================================
local function applySpeed()
    local hum = getHum()
    if not hum then return end
    local base = 16
    hum.WalkSpeed = State.speedOn and (base * State.speedMult) or base
end

local function startSpeed()
    applySpeed()
    -- override anything that tries to change walkspeed
    storeConn("speed_hb", RunService.Heartbeat:Connect(function()
        if not State.speedOn then return end
        local hum = getHum()
        if not hum then return end
        local target = 16 * State.speedMult
        if hum.WalkSpeed ~= target then
            hum.WalkSpeed = target
        end
        -- remove seat lock, unanchor HRP
        local hrp = getHRP()
        if hrp then hrp.Anchored = false end
        -- unsit
        if hum.Sit then
            hum.Sit = false
        end
    end))
end

local function stopSpeed()
    killConn("speed_hb")
    local hum = getHum()
    if hum then hum.WalkSpeed = 16 end
end

-- ============================================================
-- ██ F2 – JUMP (multi-jump, no spam)
-- ============================================================
local _lastJumpTick = 0
local _isFalling     = false

local function startJump()
    State._jumpLeft = State.jumpCount
    State._isGrounded = true

    storeConn("jump_hb", RunService.Heartbeat:Connect(function()
        if not State.jumpOn then return end
        local hum = getHum()
        if not hum then return end
        local hrp = getHRP()
        if not hrp then return end

        hum.JumpPower = State.jumpPower
        -- unsit / no lock
        if hum.Sit then hum.Sit = false end

        local vel = hrp.AssemblyLinearVelocity
        local rising  = vel.Y > 1
        local falling = vel.Y < -1

        if hum.FloorMaterial ~= Enum.Material.Air then
            -- on ground
            State._jumpLeft   = State.jumpCount
            State._isGrounded  = true
            _isFalling         = false
        else
            if _isFalling and falling == false and rising == false then
                -- peak → about to fall
                _isFalling = true
            end
            if falling and not _isFalling then
                _isFalling = true
            end
            if _isFalling and State._jumpLeft > 0 then
                local now = tick()
                if now - _lastJumpTick > 0.35 then
                    _lastJumpTick = now
                    State._jumpLeft = State._jumpLeft - 1
                    _isFalling = false
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end))
end

local function stopJump()
    killConn("jump_hb")
    local hum = getHum()
    if hum then hum.JumpPower = 50 end
end

-- ============================================================
-- ██ F3 – NOCLIP
-- ============================================================
local function startNoclip()
    storeConn("noclip_hb", RunService.Stepped:Connect(function()
        if not State.noclipOn then return end
        local char = getChar()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end))
end

local function stopNoclip()
    killConn("noclip_hb")
    local char = getChar()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ============================================================
-- ██ F5 – FLY (camera-direction based)
-- ============================================================
local _flyBodyVel   = nil
local _flyBodyGyro  = nil

local function startFly()
    local hrp = getHRP()
    if not hrp then return end
    local hum = getHum()
    if hum then hum.PlatformStand = true end

    -- Body velocity
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity  = Vector3.zero
    bv.Parent    = hrp
    _flyBodyVel  = bv

    -- Body gyro (face camera dir)
    local bg = Instance.new("BodyGyro")
    bg.Name      = "FlyBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D         = 50
    bg.P         = 1e4
    bg.CFrame    = hrp.CFrame
    bg.Parent    = hrp
    _flyBodyGyro = bg

    storeConn("fly_hb", RunService.Heartbeat:Connect(function()
        if not State.flyOn then return end
        hrp = getHRP()
        if not hrp then return end

        local cam    = workspace.CurrentCamera
        local cf     = cam.CFrame
        local fwd    = cf.LookVector
        local right  = cf.RightVector
        local baseSpd = 50 * State.flySpeed

        local moveVec = Vector3.zero
        -- joystick-like: W/S = forward/back, A/D = strafe
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVec = moveVec + fwd * baseSpd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVec = moveVec - fwd * baseSpd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVec = moveVec - right * baseSpd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVec = moveVec + right * baseSpd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVec = moveVec + Vector3.new(0, baseSpd, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVec = moveVec - Vector3.new(0, baseSpd, 0)
        end

        if _flyBodyVel and _flyBodyVel.Parent then
            _flyBodyVel.Velocity = moveVec
        end
        if _flyBodyGyro and _flyBodyGyro.Parent then
            _flyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + fwd)
        end
    end))
end

local function stopFly()
    killConn("fly_hb")
    if _flyBodyVel  and _flyBodyVel.Parent  then _flyBodyVel:Destroy()  end
    if _flyBodyGyro and _flyBodyGyro.Parent then _flyBodyGyro:Destroy() end
    _flyBodyVel  = nil
    _flyBodyGyro = nil
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ============================================================
-- ██ F6 – FLOAT (instant Y offset)
-- ============================================================
local function applyFloat()
    local hrp = getHRP()
    if not hrp then return end
    local offset = State.floatOffset
    local cur    = hrp.CFrame
    hrp.CFrame   = CFrame.new(cur.X, cur.Y + offset, cur.Z) * (cur - cur.Position)
end

-- ============================================================
-- ██ RESPAWN AUTO-RECONNECT
-- ============================================================
local function onCharAdded(char)
    char:WaitForChild("HumanoidRootPart", 10)
    task.wait(0.3)
    if State.speedOn  then startSpeed()  end
    if State.jumpOn   then startJump()   end
    if State.noclipOn then startNoclip() end
    if State.flyOn    then startFly()    end
end

LocalPlayer.CharacterAdded:Connect(onCharAdded)

-- ============================================================
-- ██ GUI BUILDER
-- ============================================================
-- Remove old GUI
pcall(function()
    if LocalPlayer.PlayerGui:FindFirstChild("UltraMenu") then
        LocalPlayer.PlayerGui.UltraMenu:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "UltraMenu"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = LocalPlayer.PlayerGui

-- ── Scale helper (1-10)
local function scaledSize(base)
    local s = math.clamp(State.menuScale, 1, 10) / 5
    return math.floor(base * s)
end

-- ── Colors
local C = {
    bg        = Color3.fromRGB(10,  10,  10),
    border    = Color3.fromRGB(40,  40,  40),
    btnOff    = Color3.fromRGB(30,  30,  30),
    btnOn     = Color3.fromRGB(255, 255, 255),
    textOff   = Color3.fromRGB(180, 180, 180),
    textOn    = Color3.fromRGB(10,  10,  10),
    title     = Color3.fromRGB(255, 255, 255),
    input     = Color3.fromRGB(20,  20,  20),
    inputBrd  = Color3.fromRGB(70,  70,  70),
    pill      = Color3.fromRGB(50,  50,  50),
    pillOn    = Color3.fromRGB(200, 200, 200),
    dot       = Color3.fromRGB(255, 255, 255),
}

-- ── Root frame (draggable)
local MenuFrame = Instance.new("Frame")
MenuFrame.Name            = "MenuFrame"
MenuFrame.Size            = UDim2.new(0, 180, 0, 380)
MenuFrame.Position        = UDim2.new(0.05, 0, 0.1, 0)
MenuFrame.BackgroundColor3 = C.bg
MenuFrame.BorderSizePixel = 0
MenuFrame.ClipsDescendants = false
MenuFrame.Parent          = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 10)
MenuCorner.Parent       = MenuFrame

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color     = C.border
MenuStroke.Thickness = 1
MenuStroke.Parent    = MenuFrame

-- ── Minimized circle
local MiniBall = Instance.new("Frame")
MiniBall.Name              = "MiniBall"
MiniBall.Size              = UDim2.new(0, 48, 0, 48)
MiniBall.Position          = MenuFrame.Position
MiniBall.BackgroundColor3  = C.bg
MiniBall.BorderSizePixel   = 0
MiniBall.Visible           = false
MiniBall.Parent            = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(1, 0)
MiniCorner.Parent       = MiniBall

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Color     = Color3.fromRGB(80, 80, 80)
MiniStroke.Thickness = 1.5
MiniStroke.Parent    = MiniBall

local MiniLabel = Instance.new("TextLabel")
MiniLabel.Size                = UDim2.new(1, 0, 1, 0)
MiniLabel.BackgroundTransparency = 1
MiniLabel.Text                = "☰"
MiniLabel.TextColor3          = C.title
MiniLabel.TextScaled          = true
MiniLabel.Font                = Enum.Font.GothamBold
MiniLabel.Parent              = MiniBall

-- ── Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name              = "TitleBar"
TitleBar.Size              = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3  = Color3.fromRGB(5, 5, 5)
TitleBar.BorderSizePixel   = 0
TitleBar.Parent            = MenuFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent       = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size                = UDim2.new(1, -70, 1, 0)
TitleLabel.Position            = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text                = "⚡ ULTRA"
TitleLabel.TextColor3          = C.title
TitleLabel.TextSize            = 13
TitleLabel.Font                = Enum.Font.GothamBold
TitleLabel.TextXAlignment      = Enum.TextXAlignment.Left
TitleLabel.Parent              = TitleBar

-- ── Scale input in title bar
local ScaleBox = Instance.new("TextBox")
ScaleBox.Size                = UDim2.new(0, 28, 0, 20)
ScaleBox.Position            = UDim2.new(1, -70, 0.5, -10)
ScaleBox.BackgroundColor3    = C.input
ScaleBox.TextColor3          = C.title
ScaleBox.Text                = tostring(State.menuScale)
ScaleBox.TextSize            = 11
ScaleBox.Font                = Enum.Font.GothamBold
ScaleBox.PlaceholderText     = "5"
ScaleBox.BorderSizePixel     = 0
ScaleBox.ClearTextOnFocus    = false
ScaleBox.Parent              = TitleBar

local ScaleCorner = Instance.new("UICorner")
ScaleCorner.CornerRadius = UDim.new(0, 4)
ScaleCorner.Parent       = ScaleBox

-- ── Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size                = UDim2.new(0, 22, 0, 22)
MinBtn.Position            = UDim2.new(1, -46, 0.5, -11)
MinBtn.BackgroundColor3    = Color3.fromRGB(60, 60, 60)
MinBtn.Text                = "—"
MinBtn.TextColor3          = C.title
MinBtn.TextSize            = 12
MinBtn.Font                = Enum.Font.GothamBold
MinBtn.BorderSizePixel     = 0
MinBtn.Parent              = TitleBar

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(1, 0)
MinBtnCorner.Parent       = MinBtn

-- ── Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size              = UDim2.new(0, 22, 0, 22)
CloseBtn.Position          = UDim2.new(1, -22, 0.5, -11)
CloseBtn.BackgroundColor3  = Color3.fromRGB(180, 40, 40)
CloseBtn.Text              = "✕"
CloseBtn.TextColor3        = C.title
CloseBtn.TextSize          = 11
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.BorderSizePixel   = 0
CloseBtn.Parent            = TitleBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(1, 0)
CloseBtnCorner.Parent       = CloseBtn

-- ── Scroll frame for functions
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name               = "ScrollFrame"
ScrollFrame.Size               = UDim2.new(1, -8, 1, -40)
ScrollFrame.Position           = UDim2.new(0, 4, 0, 36)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel    = 0
ScrollFrame.ScrollBarThickness = 2
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ScrollFrame.CanvasSize         = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent             = MenuFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder   = Enum.SortOrder.LayoutOrder
ListLayout.Padding     = UDim.new(0, 5)
ListLayout.Parent      = ScrollFrame

local ScrollPad = Instance.new("UIPadding")
ScrollPad.PaddingTop    = UDim.new(0, 4)
ScrollPad.PaddingBottom = UDim.new(0, 4)
ScrollPad.PaddingLeft   = UDim.new(0, 2)
ScrollPad.PaddingRight  = UDim.new(0, 2)
ScrollPad.Parent        = ScrollFrame

-- ============================================================
-- ██ FUNCTION CARD BUILDER
-- ============================================================
--[[
  buildCard(opts)
  opts = {
    order     = number,
    icon      = string,
    name      = string,
    inputs    = {{label, key, default, inline?}, ...},
    onToggle  = function(on)
  }
  Returns: card frame
]]

local function buildToggle(parent, state)
    -- pill toggle
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, 36, 0, 18)
    pill.BackgroundColor3 = state and C.pillOn or C.pill
    pill.BorderSizePixel  = 0
    pill.Parent           = parent

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent       = pill

    local dot = Instance.new("Frame")
    dot.Size              = UDim2.new(0, 12, 0, 12)
    dot.Position          = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3  = C.dot
    dot.BorderSizePixel   = 0
    dot.Parent            = pill

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent       = dot

    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.Parent              = pill

    local function refresh(on)
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.pillOn or C.pill
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)
        }):Play()
    end

    return pill, btn, refresh
end

local function buildInput(parent, label, defaultVal)
    local wrap = Instance.new("Frame")
    wrap.Size             = UDim2.new(1, 0, 0, 28)
    wrap.BackgroundTransparency = 1
    wrap.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(0, 50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = label
    lbl.TextColor3        = Color3.fromRGB(130, 130, 130)
    lbl.TextSize          = 10
    lbl.Font              = Enum.Font.Gotham
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = wrap

    local box = Instance.new("TextBox")
    box.Size              = UDim2.new(1, -55, 0, 22)
    box.Position          = UDim2.new(0, 52, 0.5, -11)
    box.BackgroundColor3  = C.input
    box.BorderSizePixel   = 0
    box.Text              = tostring(defaultVal)
    box.TextColor3        = Color3.fromRGB(220, 220, 220)
    box.TextSize          = 11
    box.Font              = Enum.Font.GothamBold
    box.PlaceholderText   = tostring(defaultVal)
    box.ClearTextOnFocus  = false
    box.Parent            = wrap

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent       = box

    local bStroke = Instance.new("UIStroke")
    bStroke.Color     = C.inputBrd
    bStroke.Thickness = 1
    bStroke.Parent    = box

    return wrap, box
end

local function buildCard(opts)
    local card = Instance.new("Frame")
    card.Name             = opts.name
    card.Size             = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    card.BorderSizePixel  = 0
    card.LayoutOrder      = opts.order
    card.Parent           = ScrollFrame

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent       = card

    local cPad = Instance.new("UIPadding")
    cPad.PaddingTop    = UDim.new(0, 7)
    cPad.PaddingBottom = UDim.new(0, 7)
    cPad.PaddingLeft   = UDim.new(0, 8)
    cPad.PaddingRight  = UDim.new(0, 8)
    cPad.Parent        = card

    local cList = Instance.new("UIListLayout")
    cList.SortOrder = Enum.SortOrder.LayoutOrder
    cList.Padding   = UDim.new(0, 5)
    cList.Parent    = card

    -- Header row
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 22)
    header.BackgroundTransparency = 1
    header.LayoutOrder      = 1
    header.Parent           = card

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size             = UDim2.new(0, 20, 1, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text             = opts.icon
    iconLbl.TextSize         = 14
    iconLbl.Font             = Enum.Font.GothamBold
    iconLbl.TextColor3       = C.title
    iconLbl.Parent           = header

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(1, -62, 1, 0)
    nameLbl.Position         = UDim2.new(0, 22, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = opts.name
    nameLbl.TextSize         = 11
    nameLbl.Font             = Enum.Font.GothamBold
    nameLbl.TextColor3       = C.title
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.Parent           = header

    local isOn = false
    local pill, pillBtn, pillRefresh = buildToggle(header, false)
    pill.Position = UDim2.new(1, -36, 0.5, -9)
    pill.AnchorPoint = Vector2.new(0, 0)

    -- Inputs
    local inputBoxes = {}
    for i, inp in ipairs(opts.inputs or {}) do
        local wrap, box = buildInput(card, inp.label, inp.default)
        wrap.LayoutOrder = 1 + i
        table.insert(inputBoxes, {box = box, key = inp.key})
    end

    -- Toggle logic
    pillBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        pillRefresh(isOn)
        -- read input values
        for _, ib in ipairs(inputBoxes) do
            local n = tonumber(ib.box.Text)
            if n ~= nil then
                State[ib.key] = n
            end
        end
        opts.onToggle(isOn)
    end)

    return card
end

-- ============================================================
-- ██ BUILD FUNCTION CARDS
-- ============================================================

-- F1 – SPEED
buildCard({
    order  = 1,
    icon   = "🏃",
    name   = "วิ่งไว",
    inputs = {
        {label = "Speed×", key = "speedMult", default = 2},
    },
    onToggle = function(on)
        State.speedOn = on
        if on then startSpeed() else stopSpeed() end
    end
})

-- F2 – JUMP
buildCard({
    order  = 2,
    icon   = "🤸",
    name   = "กระโดด",
    inputs = {
        {label = "Power", key = "jumpPower", default = 100},
        {label = "Count", key = "jumpCount", default = 3},
    },
    onToggle = function(on)
        State.jumpOn = on
        if on then startJump() else stopJump() end
    end
})

-- F3 – NOCLIP
buildCard({
    order  = 3,
    icon   = "🌚",
    name   = "ทะลุกำแพง",
    inputs = {},
    onToggle = function(on)
        State.noclipOn = on
        if on then startNoclip() else stopNoclip() end
    end
})

-- F5 – FLY
buildCard({
    order  = 5,
    icon   = "💨",
    name   = "บิน",
    inputs = {
        {label = "Speed×", key = "flySpeed", default = 2},
    },
    onToggle = function(on)
        State.flyOn = on
        if on then startFly() else stopFly() end
    end
})

-- F6 – FLOAT
buildCard({
    order  = 6,
    icon   = "☁️",
    name   = "ลอย",
    inputs = {
        {label = "Offset", key = "floatOffset", default = 1},
    },
    onToggle = function(on)
        State.floatOn = on
        if on then
            local n = tonumber(State.floatOffset)
            if n then applyFloat() end
        end
    end
})

-- ============================================================
-- ██ SCALE INPUT LOGIC
-- ============================================================
ScaleBox.FocusLost:Connect(function()
    local n = tonumber(ScaleBox.Text)
    if n then
        n = math.clamp(math.floor(n), 1, 10)
        State.menuScale = n
        ScaleBox.Text   = tostring(n)
        local s = n / 5
        local w = math.floor(180 * s)
        local h = math.floor(380 * s)
        MenuFrame.Size = UDim2.new(0, math.max(w, 120), 0, math.max(h, 160))
    end
end)

-- ============================================================
-- ██ DRAGGABLE (MenuFrame)
-- ============================================================
local function makeDraggable(frame)
    local dragging   = false
    local dragInput  = nil
    local dragStart  = nil
    local startPos   = nil

    local handle = TitleBar

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            -- sync mini ball
            MiniBall.Position = frame.Position
        end
    end)
end

makeDraggable(MenuFrame)

-- Draggable MiniBall
do
    local dragging  = false
    local dragStart = nil
    local startPos  = nil

    MiniBall.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = MiniBall.Position
        end
    end)
    MiniBall.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MiniBall.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
-- ██ MINIMIZE / RESTORE
-- ============================================================
MinBtn.MouseButton1Click:Connect(function()
    State.minimized = true
    MiniBall.Position = MenuFrame.Position
    MenuFrame.Visible = false
    MiniBall.Visible  = true
end)

MiniLabel.MouseButton1Click = nil
local miniBtn = Instance.new("TextButton")
miniBtn.Size              = UDim2.new(1, 0, 1, 0)
miniBtn.BackgroundTransparency = 1
miniBtn.Text              = ""
miniBtn.Parent            = MiniBall

miniBtn.MouseButton1Click:Connect(function()
    State.minimized   = false
    MenuFrame.Position = MiniBall.Position
    MenuFrame.Visible  = true
    MiniBall.Visible   = false
end)

-- ============================================================
-- ██ CLOSE
-- ============================================================
CloseBtn.MouseButton1Click:Connect(function()
    -- stop all systems
    stopSpeed()
    stopJump()
    stopNoclip()
    stopFly()
    ScreenGui:Destroy()
end)

-- ============================================================
-- ██ FLOAT INSTANT APPLY (real-time watch)
-- ============================================================
RunService.Heartbeat:Connect(function()
    -- nothing continuous for float; applied on toggle
end)

-- ============================================================
-- ██ DONE
-- ============================================================
print("✅ ULTRA MENU v1.0 loaded – kuy kuy")
