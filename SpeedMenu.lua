--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--// CHARACTER
local function getChar()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")
    return char, hum, root
end

local char, hum, root = getChar()

player.CharacterAdded:Connect(function()
    char, hum, root = getChar()
end)

--// SAVE DEFAULT
local default = {
    WalkSpeed = hum.WalkSpeed,
    JumpPower = hum.JumpPower
}

--// STATE
local speedEnabled, jumpEnabled, airEnabled, floatEnabled, godEnabled =
    false, false, false, false, false

--// VALUES
local speedValue, jumpValue = 50, 100
local airJumpValue = 2
local floatValue = 10

--// AIR JUMP
local jumpCount = 0

--// FLOAT
local floatForce

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,450)
frame.Position = UDim2.new(0.05,0,0.3,0)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-10)
scroll.Position = UDim2.new(0,5,0,5)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

--// CREATE BLOCK
local function createBlock(text, placeholder)
    local f = Instance.new("Frame", scroll)
    f.Size = UDim2.new(1,-5,0,55)

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1,0,0,25)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(200,50,50)

    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(1,0,0,25)
    box.Position = UDim2.new(0,0,0,28)
    box.PlaceholderText = placeholder

    return btn, box
end

--// UI CREATE
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")
local jumpBtn, jumpBox = createBlock("Jump OFF","JumpPower")
local airBtn, airBox = createBlock("AirJump OFF","Count")
local floatBtn, floatBox = createBlock("Float OFF","Height")
local godBtn = Instance.new("TextButton", scroll)
godBtn.Size = UDim2.new(1,-5,0,30)
godBtn.Text = "GodWalk OFF"
godBtn.BackgroundColor3 = Color3.fromRGB(150,50,200)

--// FUNCTIONS
local function applySpeed()
    hum.WalkSpeed = speedValue
end

local function applyJump()
    hum.JumpPower = jumpValue
end

local function applyFloat()
    if not floatForce then
        floatForce = Instance.new("BodyPosition")
        floatForce.MaxForce = Vector3.new(0,math.huge,0)
        floatForce.Parent = root
    end
end

--// BUTTONS
speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedBtn.Text = speedEnabled and "Speed ON" or "Speed OFF"
end)

jumpBtn.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    jumpBtn.Text = jumpEnabled and "Jump ON" or "Jump OFF"
end)

airBtn.MouseButton1Click:Connect(function()
    airEnabled = not airEnabled
    airBtn.Text = airEnabled and "AirJump ON" or "AirJump OFF"
end)

floatBtn.MouseButton1Click:Connect(function()
    floatEnabled = not floatEnabled
    floatBtn.Text = floatEnabled and "Float ON" or "Float OFF"

    if floatEnabled then
        applyFloat()
    elseif floatForce then
        floatForce:Destroy()
        floatForce = nil
    end
end)

godBtn.MouseButton1Click:Connect(function()
    godEnabled = not godEnabled
    godBtn.Text = godEnabled and "GodWalk ON" or "GodWalk OFF"
end)

--// INPUT
speedBox.FocusLost:Connect(function()
    local n = tonumber(speedBox.Text)
    if n then speedValue = n end
end)

jumpBox.FocusLost:Connect(function()
    local n = tonumber(jumpBox.Text)
    if n then jumpValue = n end
end)

airBox.FocusLost:Connect(function()
    local n = tonumber(airBox.Text)
    if n then airJumpValue = n end
end)

floatBox.FocusLost:Connect(function()
    local n = tonumber(floatBox.Text)
    if n then floatValue = n end
end)

--// AIR JUMP
UIS.JumpRequest:Connect(function()
    if airEnabled and jumpCount < airJumpValue then
        jumpCount += 1
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

hum.StateChanged:Connect(function(_, new)
    if new == Enum.HumanoidStateType.Landed then
        jumpCount = 0
    end
end)

--// MAIN LOOP (GOD MODE CORE)
RunService.RenderStepped:Connect(function()

    if not hum or not root then return end

    -- SPEED LOCK
    if speedEnabled or godEnabled then
        hum.WalkSpeed = speedValue
    end

    -- JUMP LOCK
    if jumpEnabled or godEnabled then
        hum.JumpPower = jumpValue
    end

    -- FLOAT
    if floatEnabled and floatForce then
        floatForce.Position = root.Position + Vector3.new(0,floatValue,0)
    end

    -- GOD WALK CORE
    if godEnabled then

        -- กัน stun
        if hum.PlatformStand then
            hum.PlatformStand = false
        end

        -- กันนั่ง
        if hum.Sit then
            hum.Sit = false
        end

        -- กัน ragdoll / ล้ม
        if hum:GetState() ~= Enum.HumanoidStateType.Running then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end

        -- กันโดนผลัก
        root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)

    end

end)

--// AUTO SCROLL
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)
