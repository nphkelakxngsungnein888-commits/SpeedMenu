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

--// DEFAULT
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

--// AIR
local jumpCount = 0

--// FLOAT
local floatForce

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "Pro_Menu"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,350)
frame.Position = UDim2.new(0.05,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.ClipsDescendants = true

--// DRAG
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function()
    dragging = false
end)

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-10)
scroll.Position = UDim2.new(0,5,0,5)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)
scroll.ClipsDescendants = true
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

local padding = Instance.new("UIPadding", scroll)
padding.PaddingTop = UDim.new(0,5)
padding.PaddingBottom = UDim.new(0,5)

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
local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")
local darkBtn, darkBox = createBlock("Dark OFF","Dark")
local fogBtn, fogBox = createBlock("Fog OFF","FogEnd")

local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")
local jumpBtn, jumpBox = createBlock("Jump OFF","JumpPower")
local airBtn, airBox = createBlock("AirJump OFF","Count")
local floatBtn, floatBox = createBlock("Float OFF","Height")

local resetBtn = Instance.new("TextButton", scroll)
resetBtn.Size = UDim2.new(1,-5,0,30)
resetBtn.Text = "RESET"

--// LIGHT FUNCTIONS
local function applyBright()
    Lighting.Brightness = brightnessValue
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
end

local function applyDark()
    Lighting.Brightness = darkValue
    Lighting.ClockTime = 0
    Lighting.GlobalShadows = true
end

local function applyFog()
    Lighting.FogEnd = fogValue
end

--// MOVEMENT FUNCTIONS
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
brightBtn.MouseButton1Click:Connect(function()
    brightEnabled = not brightEnabled
    brightBtn.Text = brightEnabled and "FullBright ON" or "FullBright OFF"
    if brightEnabled then applyBright() end
end)

darkBtn.MouseButton1Click:Connect(function()
    darkEnabled = not darkEnabled
    darkBtn.Text = darkEnabled and "Dark ON" or "Dark OFF"
    if darkEnabled then applyDark() end
end)

fogBtn.MouseButton1Click:Connect(function()
    fogEnabled = not fogEnabled
    fogBtn.Text = fogEnabled and "Fog ON" or "Fog OFF"
    if fogEnabled then applyFog() end
end)

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

    if floatEnabled then
        applyFloat()
    elseif floatForce then
        floatForce:Destroy()
        floatForce = nil
    end
end)

--// INPUT
brightBox.FocusLost:Connect(function()
    local n = tonumber(brightBox.Text)
    if n then brightnessValue = n if brightEnabled then applyBright() end end
end)

darkBox.FocusLost:Connect(function()
    local n = tonumber(darkBox.Text)
    if n then darkValue = n if darkEnabled then applyDark() end end
end)

fogBox.FocusLost:Connect(function()
    local n = tonumber(fogBox.Text)
    if n then fogValue = n if fogEnabled then applyFog() end end
end)

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

--// AIR JUMP
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
RunService.RenderStepped:Connect(function()
    if floatEnabled and floatForce then
        floatForce.Position = root.Position + Vector3.new(0,floatValue,0)
    end
end)

--// RESET
resetBtn.MouseButton1Click:Connect(function()
    Lighting.Brightness = default.Brightness
    Lighting.ClockTime = default.ClockTime
    Lighting.FogEnd = default.FogEnd
    Lighting.GlobalShadows = default.GlobalShadows
    Lighting.Ambient = default.Ambient
    Lighting.OutdoorAmbient = default.OutdoorAmbient

    hum.WalkSpeed = default.WalkSpeed
    hum.JumpPower = default.JumpPower
end)
