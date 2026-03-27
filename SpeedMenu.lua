--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

--// SAVE DEFAULT
local default = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

--// STATE
local brightEnabled = false
local darkEnabled = false
local brightnessValue = 5
local darkValue = 0

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "Light_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 190, 0, 210)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-60,0,25)
title.Position = UDim2.new(0,5,0,0)
title.Text = "Light System"
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

-- Bright
local brightBtn = Instance.new("TextButton", frame)
brightBtn.Size = UDim2.new(1,-10,0,25)
brightBtn.Position = UDim2.new(0,5,0,30)
brightBtn.Text = "FullBright OFF"
brightBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)

local brightBox = Instance.new("TextBox", frame)
brightBox.Size = UDim2.new(1,-10,0,25)
brightBox.Position = UDim2.new(0,5,0,60)
brightBox.PlaceholderText = "Brightness เช่น 5"
brightBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
brightBox.TextColor3 = Color3.new(1,1,1)

-- Dark
local darkBtn = Instance.new("TextButton", frame)
darkBtn.Size = UDim2.new(1,-10,0,25)
darkBtn.Position = UDim2.new(0,5,0,90)
darkBtn.Text = "Dark OFF"
darkBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)

local darkBox = Instance.new("TextBox", frame)
darkBox.Size = UDim2.new(1,-10,0,25)
darkBox.Position = UDim2.new(0,5,0,120)
darkBox.PlaceholderText = "Dark เช่น 0"
darkBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
darkBox.TextColor3 = Color3.new(1,1,1)

-- Reset
local resetBtn = Instance.new("TextButton", frame)
resetBtn.Size = UDim2.new(1,-10,0,30)
resetBtn.Position = UDim2.new(0,5,0,155)
resetBtn.Text = "RESET"
resetBtn.BackgroundColor3 = Color3.fromRGB(120,120,40)

--// DRAG (มือถือ + PC)
local dragging, dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
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

--// MINI / CLOSE
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    brightBtn.Visible = not minimized
    brightBox.Visible = not minimized
    darkBtn.Visible = not minimized
    darkBox.Visible = not minimized
    resetBtn.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,190,0,30) or UDim2.new(0,190,0,210)
end)

--// FUNCTIONS
local function applyBright()
    Lighting.Brightness = brightnessValue
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
end

local function applyDark()
    Lighting.Brightness = darkValue
    Lighting.ClockTime = 0
    Lighting.GlobalShadows = true
end

--// BUTTONS
brightBtn.MouseButton1Click:Connect(function()
    brightEnabled = not brightEnabled
    darkEnabled = false

    brightBtn.Text = brightEnabled and "FullBright ON" or "FullBright OFF"
    brightBtn.BackgroundColor3 = brightEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)

    if brightEnabled then
        applyBright()
    end
end)

darkBtn.MouseButton1Click:Connect(function()
    darkEnabled = not darkEnabled
    brightEnabled = false

    darkBtn.Text = darkEnabled and "Dark ON" or "Dark OFF"
    darkBtn.BackgroundColor3 = darkEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)

    if darkEnabled then
        applyDark()
    end
end)

-- INPUT
brightBox.FocusLost:Connect(function()
    local num = tonumber(brightBox.Text)
    if num then
        brightnessValue = num
        if brightEnabled then applyBright() end
    end
end)

darkBox.FocusLost:Connect(function()
    local num = tonumber(darkBox.Text)
    if num then
        darkValue = num
        if darkEnabled then applyDark() end
    end
end)

-- RESET
resetBtn.MouseButton1Click:Connect(function()
    brightEnabled = false
    darkEnabled = false

    Lighting.Brightness = default.Brightness
    Lighting.ClockTime = default.ClockTime
    Lighting.FogEnd = default.FogEnd
    Lighting.GlobalShadows = default.GlobalShadows
    Lighting.Ambient = default.Ambient
    Lighting.OutdoorAmbient = default.OutdoorAmbient

    brightBtn.Text = "FullBright OFF"
    darkBtn.Text = "Dark OFF"
    brightBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    darkBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
end)
