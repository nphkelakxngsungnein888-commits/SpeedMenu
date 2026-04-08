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
        if state.enableSpeed then
            humanoid.WalkSpeed = state.walkSpeed
        else
            humanoid.WalkSpeed = 16
        end

        if state.enableJump then
            humanoid.JumpPower = state.jumpPower
        else
            humanoid.JumpPower = 50
        end
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

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,230,0,300)
frame.Position = UDim2.new(0.03,0,0.2,0)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame)

-- DRAG
local dragging, dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
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

-- UI LAYOUT
local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0,5)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function createRow(title, default, toggleCallback, valueCallback)
    local row = Instance.new("Frame", frame)
    row.Size = UDim2.new(1,0,0,40)
    row.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.4,0,1,0)
    label.Text = title
    label.TextColor3 = Color3.white
    label.BackgroundTransparency = 1
    label.TextScaled = true

    local toggle = Instance.new("TextButton", row)
    toggle.Size = UDim2.new(0.25,0,0.8,0)
    toggle.Position = UDim2.new(0.4,0,0.1,0)
    toggle.Text = "OFF"
    toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    toggle.TextColor3 = Color3.white
    Instance.new("UICorner", toggle)

    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.3,0,0.8,0)
    box.Position = UDim2.new(0.7,0,0.1,0)
    box.Text = tostring(default)
    box.BackgroundColor3 = Color3.fromRGB(35,35,35)
    box.TextColor3 = Color3.white
    Instance.new("UICorner", box)

    local enabled = false

    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggle.Text = enabled and "ON" or "OFF"
        toggle.BackgroundColor3 = enabled and Color3.fromRGB(0,170,100) or Color3.fromRGB(50,50,50)
        toggleCallback(enabled)
    end)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            valueCallback(val)
        end
    end)
end

-- BUILD UI
createRow("Speed", state.walkSpeed,
    function(v) state.enableSpeed = v end,
    function(v) state.walkSpeed = v end
)

createRow("Jump", state.jumpPower,
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
