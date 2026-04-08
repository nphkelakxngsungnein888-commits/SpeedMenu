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

--// CHARACTER SETUP
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

--// FLY SYSTEM
local function startFly()
    if not root then return end

    flying = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBG.CFrame = root.CFrame
    flyBG.Parent = root
end

local function stopFly()
    flying = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

--// MOVEMENT LOOP
RunService.RenderStepped:Connect(function()
    if humanoid then
        if state.enableSpeed then
            humanoid.WalkSpeed = state.walkSpeed
        end

        if state.enableJump then
            humanoid.JumpPower = state.jumpPower
        end
    end

    if state.enableFly and flying and root then
        local moveDir = humanoid.MoveDirection
        local camCF = camera.CFrame

        local direction = (camCF.LookVector * moveDir.Z + camCF.RightVector * moveDir.X)
        flyBV.Velocity = direction * state.flySpeed
        flyBG.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
    end
end)

--// UI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,260)
frame.Position = UDim2.new(0.02,0,0.2,0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0,8)

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

-- UI ELEMENT CREATOR
local function createToggle(name, posY, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.9,0,0,28)
    btn.Position = UDim2.new(0.05,0,0,posY)
    btn.Text = name.." : OFF"
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.white
    Instance.new("UICorner", btn)

    local stateLocal = false

    btn.MouseButton1Click:Connect(function()
        stateLocal = not stateLocal
        btn.Text = name.." : "..(stateLocal and "ON" or "OFF")
        callback(stateLocal)
    end)
end

local function createBox(name, posY, default, callback)
    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0.9,0,0,28)
    box.Position = UDim2.new(0.05,0,0,posY)
    box.Text = name..": "..default
    box.BackgroundColor3 = Color3.fromRGB(35,35,35)
    box.TextColor3 = Color3.white
    Instance.new("UICorner", box)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text:match("%d+"))
        if val then
            callback(val)
        end
    end)
end

--// UI BUILD

createToggle("Speed",10,function(v) state.enableSpeed = v end)
createBox("WalkSpeed",45,state.walkSpeed,function(v) state.walkSpeed = v end)

createToggle("Jump",80,function(v) state.enableJump = v end)
createBox("JumpPower",115,state.jumpPower,function(v) state.jumpPower = v end)

createToggle("MultiJump",150,function(v) state.enableMultiJump = v end)
createBox("JumpCount",185,state.multiJump,function(v) state.multiJump = v end)

createToggle("Fly",220,function(v)
    state.enableFly = v
    if v then startFly() else stopFly() end
end)

createBox("FlySpeed",255,state.flySpeed,function(v) state.flySpeed = v end)
