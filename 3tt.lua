--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// PLAYER
local player = Players.LocalPlayer
local character, humanoid, root, camera

--// STATE
local state = {
    walkSpeed = 16,
    jumpPower = 50,
    multiJump = 1,
    flySpeed = 60,

    enableSpeed = false,
    enableJump = false,
    enableMultiJump = false,
    enableFly = false
}

local jumpCount = 0
local flying = false
local flyBV, flyBG

--// CHARACTER
local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    camera = workspace.CurrentCamera
    jumpCount = 0

    humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Landed then
            jumpCount = 0
        end
    end)
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

--// MULTI JUMP
UIS.JumpRequest:Connect(function()
    if state.enableMultiJump and humanoid then
        if jumpCount < state.multiJump then
            jumpCount += 1
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--// FLY
local function startFly()
    if not root then return end
    flying = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBG.P = 1e4
    flyBG.Parent = root
end

local function stopFly()
    flying = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

--// LOOP
RunService.RenderStepped:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = state.enableSpeed and state.walkSpeed or 16
        humanoid.JumpPower = state.enableJump and state.jumpPower or 50
    end

    if state.enableFly and flying and root and humanoid then
        local camCF = camera.CFrame
        local moveDir = humanoid.MoveDirection
        local move = (camCF.LookVector * moveDir.Z + camCF.RightVector * moveDir.X)

        flyBV.Velocity = move * state.flySpeed
        flyBG.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
    end
end)

--// UI
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,240,0,320)
main.Position = UDim2.new(0.03,0,0.2,0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
Instance.new("UICorner", main)

-- HEADER
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,30)
header.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", header)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6,0,1,0)
title.Text = "Movement Panel"
title.TextColor3 = Color3.white
title.BackgroundTransparency = 1
title.TextScaled = true

-- BUTTONS
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,30,1,0)
closeBtn.Position = UDim2.new(1,-30,0,0)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(120,0,0)
closeBtn.TextColor3 = Color3.white
Instance.new("UICorner", closeBtn)

local miniBtn = Instance.new("TextButton", header)
miniBtn.Size = UDim2.new(0,30,1,0)
miniBtn.Position = UDim2.new(1,-60,0,0)
miniBtn.Text = "-"
miniBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
miniBtn.TextColor3 = Color3.white
Instance.new("UICorner", miniBtn)

-- SCROLL
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1,0,1,-30)
scroll.Position = UDim2.new(0,0,0,30)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 4
scroll.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,5)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)

-- DRAG
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- MINIMIZE
local minimized = false
miniBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    main.Size = minimized and UDim2.new(0,240,0,30) or UDim2.new(0,240,0,320)
end)

-- CLOSE
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- CREATE ROW
local function createRow(name, default, toggleFunc, valueFunc)
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1,-10,0,45)
    row.BackgroundColor3 = Color3.fromRGB(35,35,35)
    Instance.new("UICorner", row)

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.4,0,1,0)
    label.Text = name
    label.TextColor3 = Color3.white
    label.BackgroundTransparency = 1
    label.TextScaled = true

    local toggle = Instance.new("TextButton", row)
    toggle.Size = UDim2.new(0.25,0,0.7,0)
    toggle.Position = UDim2.new(0.4,0,0.15,0)
    toggle.Text = "OFF"
    toggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
    toggle.TextColor3 = Color3.white
    Instance.new("UICorner", toggle)

    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.25,0,0.7,0)
    box.Position = UDim2.new(0.7,0,0.15,0)
    box.Text = tostring(default)
    box.BackgroundColor3 = Color3.fromRGB(25,25,25)
    box.TextColor3 = Color3.white
    Instance.new("UICorner", box)

    local enabled = false

    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggle.Text = enabled and "ON" or "OFF"
        toggle.BackgroundColor3 = enabled and Color3.fromRGB(0,170,100) or Color3.fromRGB(60,60,60)
        toggleFunc(enabled)
    end)

    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then valueFunc(v) end
    end)
end

-- BUILD
createRow("WalkSpeed", state.walkSpeed,
    function(v) state.enableSpeed = v end,
    function(v) state.walkSpeed = v end
)

createRow("JumpPower", state.jumpPower,
    function(v) state.enableJump = v end,
    function(v) state.jumpPower = v end
)

createRow("MultiJump", state.multiJump,
    function(v) state.enableMultiJump = v end,
    function(v) state.multiJump = v end
)

createRow("Fly", state.flySpeed,
    function(v)
        state.enableFly = v
        if v then startFly() else stopFly() end
    end,
    function(v) state.flySpeed = v end
)
