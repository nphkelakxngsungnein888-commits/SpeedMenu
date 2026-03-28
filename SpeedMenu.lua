--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

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
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    WalkSpeed = hum.WalkSpeed,
    JumpPower = hum.JumpPower
}

--// STATE
local brightEnabled, darkEnabled, fogEnabled = false, false, false
local speedEnabled, jumpEnabled, airEnabled, floatEnabled = false, false, false, false

--// VALUES
local brightnessValue, darkValue, fogValue = 5, 0, 100000
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
frame.Size = UDim2.new(0,200,0,400)
frame.Position = UDim2.new(0.05,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

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
    floatForce.Position = root.Position + Vector3.new(0,floatValue,0)
end

--// BUTTONS
speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    speedBtn.Text = speedEnabled and "Speed ON" or "Speed OFF"
    if speedEnabled then applySpeed() else hum.WalkSpeed = default.WalkSpeed end
end)

jumpBtn.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    jumpBtn.Text = jumpEnabled and "Jump ON" or "Jump OFF"
    if jumpEnabled then applyJump() else hum.JumpPower = default.JumpPower end
end)

airBtn.MouseButton1Click:Connect(function()
    airEnabled = not airEnabled
    airBtn.Text = airEnabled and "AirJump ON" or "AirJump OFF"
end)

floatBtn.MouseButton1Click:Connect(function()
    floatEnabled = not floatEnabled
    floatBtn.Text = floatEnabled and "Float ON" or "Float OFF"

    if not floatEnabled and floatForce then
        floatForce:Destroy()
        floatForce = nil
    end
end)

--// INPUT BOX
speedBox.FocusLost:Connect(function()
    local n = tonumber(speedBox.Text)
    if n then speedValue = n if speedEnabled then applySpeed() end end
end)

jumpBox.FocusLost:Connect(function()
    local n = tonumber(jumpBox.Text)
    if n then jumpValue = n if jumpEnabled then applyJump() end end
end)

airBox.FocusLost:Connect(function()
    local n = tonumber(airBox.Text)
    if n then airJumpValue = n end
end)

floatBox.FocusLost:Connect(function()
    local n = tonumber(floatBox.Text)
    if n then floatValue = n end
end)

--// AIR JUMP LOGIC
UIS.JumpRequest:Connect(function()
    if airEnabled then
        if jumpCount < airJumpValue then
            jumpCount += 1
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

hum.StateChanged:Connect(function(_, new)
    if new == Enum.HumanoidStateType.Landed then
        jumpCount = 0
    end
end)

--// FLOAT LOOP
game:GetService("RunService").RenderStepped:Connect(function()
    if floatEnabled and floatForce then
        floatForce.Position = root.Position + Vector3.new(0,floatValue,0)
    end
end)

--// AUTO SCROLL
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)
