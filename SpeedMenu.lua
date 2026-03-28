--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--// CHARACTER
local function getChar()
    local char = player.Character or player.CharacterAdded:Wait()
    return char, char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
end

--// SAVE DEFAULT
local default = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    WalkSpeed = 16,
    JumpPower = 50
}

--// STATE
local brightEnabled, darkEnabled, fogEnabled = false, false, false
local speedEnabled, jumpEnabled, airJumpEnabled, floatEnabled = false, false, false, false

local brightnessValue, darkValue, fogValue = 5, 0, 100000
local speedValue, jumpValue = 16, 50
local airJumpCount, floatValue = 1, 0

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "Light_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 350)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-60,0,25)
title.Position = UDim2.new(0,5,0,0)
title.Text = "Pro Player Panel"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,25,0,25)
close.Position = UDim2.new(1,-25,0,0)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(120,0,0)

local mini = Instance.new("TextButton", frame)
mini.Size = UDim2.new(0,25,0,25)
mini.Position = UDim2.new(1,-50,0,0)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(60,60,60)

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-35)
scroll.Position = UDim2.new(0,5,0,30)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

--// BLOCK
local function createBlock(btnText, placeholder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1,-5,0,55)
    container.BackgroundTransparency = 1
    container.Parent = scroll

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1,0,0,25)
    btn.Text = btnText
    btn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    btn.TextColor3 = Color3.new(1,1,1)

    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(1,0,0,25)
    box.Position = UDim2.new(0,0,0,28)
    box.PlaceholderText = placeholder
    box.BackgroundColor3 = Color3.fromRGB(50,50,50)
    box.TextColor3 = Color3.new(1,1,1)

    return btn, box
end

--// ORIGINAL
local brightBtn, brightBox = createBlock("FullBright OFF", "Brightness")
local darkBtn, darkBox = createBlock("Dark OFF", "Dark")
local fogBtn, fogBox = createBlock("Fog OFF", "FogEnd")

--// NEW
local speedBtn, speedBox = createBlock("Speed OFF", "WalkSpeed")
local jumpBtn, jumpBox = createBlock("Jump OFF", "JumpPower")
local airBtn, airBox = createBlock("AirJump OFF", "Jump Count")
local floatBtn, floatBox = createBlock("Float OFF", "Height +/-")

local resetBtn = Instance.new("TextButton", scroll)
resetBtn.Size = UDim2.new(1,-5,0,30)
resetBtn.Text = "RESET"

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

--// CLOSE/MINI
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,200,0,30) or UDim2.new(0,200,0,350)
end)

--// FUNCTIONS
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

local function applySpeed()
    local _, hum = getChar()
    hum.WalkSpeed = speedValue
end

local function applyJump()
    local _, hum = getChar()
    hum.JumpPower = jumpValue
end

--// AIR JUMP
local jumpCounter = 0
UIS.JumpRequest:Connect(function()
    if airJumpEnabled then
        local _, hum = getChar()
        if jumpCounter < airJumpCount then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            jumpCounter += 1
        end
    end
end)

player.CharacterAdded:Connect(function()
    jumpCounter = 0
end)

--// FLOAT
local bodyPos
local function applyFloat()
    local _, _, root = getChar()

    if not bodyPos then
        bodyPos = Instance.new("BodyPosition")
        bodyPos.MaxForce = Vector3.new(0, math.huge, 0)
        bodyPos.P = 10000
        bodyPos.Parent = root
    end

    bodyPos.Position = root.Position + Vector3.new(0, floatValue, 0)
end

RunService.RenderStepped:Connect(function()
    if floatEnabled then applyFloat() end
end)

--// BUTTONS
brightBtn.MouseButton1Click:Connect(function()
    brightEnabled = not brightEnabled
    if brightEnabled then applyBright() end
end)

darkBtn.MouseButton1Click:Connect(function()
    darkEnabled = not darkEnabled
    if darkEnabled then applyDark() end
end)

fogBtn.MouseButton1Click:Connect(function()
    fogEnabled = not fogEnabled
    if fogEnabled then applyFog() end
end)

speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    if speedEnabled then applySpeed() end
end)

jumpBtn.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    if jumpEnabled then applyJump() end
end)

airBtn.MouseButton1Click:Connect(function()
    airJumpEnabled = not airJumpEnabled
end)

floatBtn.MouseButton1Click:Connect(function()
    floatEnabled = not floatEnabled
    if not floatEnabled and bodyPos then
        bodyPos:Destroy()
        bodyPos = nil
    end
end)

--// INPUT
brightBox.FocusLost:Connect(function()
    local n = tonumber(brightBox.Text)
    if n then brightnessValue = n end
end)

darkBox.FocusLost:Connect(function()
    local n = tonumber(darkBox.Text)
    if n then darkValue = n end
end)

fogBox.FocusLost:Connect(function()
    local n = tonumber(fogBox.Text)
    if n then fogValue = n end
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
    if n then airJumpCount = n end
end)

floatBox.FocusLost:Connect(function()
    local n = tonumber(floatBox.Text)
    if n then floatValue = n end
end)

--// RESET
resetBtn.MouseButton1Click:Connect(function()
    Lighting.Brightness = default.Brightness
    Lighting.ClockTime = default.ClockTime
    Lighting.FogEnd = default.FogEnd
    Lighting.GlobalShadows = default.GlobalShadows
    Lighting.Ambient = default.Ambient
    Lighting.OutdoorAmbient = default.OutdoorAmbient

    local _, hum = getChar()
    hum.WalkSpeed = default.WalkSpeed
    hum.JumpPower = default.JumpPower
end)

--// AUTO SCROLL
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)
