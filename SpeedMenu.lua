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
local fogEnabled = false
local sharpEnabled = false

local brightnessValue = 5
local darkValue = 0
local fogValue = 100000
local sharpValue = 0.5

local sharpenEffect = nil

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "Light_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 280)
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

-- 🔥 SCROLL MENU
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-35)
scroll.Position = UDim2.new(0,5,0,30)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,5)

local function addButton(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-5,0,25)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = scroll
    return b
end

local function addBox(placeholder)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1,-5,0,25)
    t.PlaceholderText = placeholder
    t.BackgroundColor3 = Color3.fromRGB(50,50,50)
    t.TextColor3 = Color3.new(1,1,1)
    t.Parent = scroll
    return t
end

-- UI Elements
local brightBtn = addButton("FullBright OFF")
local brightBox = addBox("Brightness")

local darkBtn = addButton("Dark OFF")
local darkBox = addBox("Dark")

local fogBtn = addButton("Fog OFF")
local fogBox = addBox("FogEnd")

local sharpBtn = addButton("Sharpen OFF")
local sharpBox = addBox("Sharpness 0-1")

local resetBtn = addButton("RESET")

--// DRAG
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

--// CLOSE / MINI
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,200,0,30) or UDim2.new(0,200,0,280)
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

local function applySharp()
    if not sharpenEffect then
        sharpenEffect = Instance.new("SharpenEffect")
        sharpenEffect.Parent = Lighting
    end
    sharpenEffect.Sharpness = sharpValue
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

sharpBtn.MouseButton1Click:Connect(function()
    sharpEnabled = not sharpEnabled
    sharpBtn.Text = sharpEnabled and "Sharpen ON" or "Sharpen OFF"

    if sharpEnabled then
        applySharp()
    elseif sharpenEffect then
        sharpenEffect:Destroy()
        sharpenEffect = nil
    end
end)

-- INPUT
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

sharpBox.FocusLost:Connect(function()
    local n = tonumber(sharpBox.Text)
    if n then sharpValue = n if sharpEnabled then applySharp() end end
end)

-- RESET
resetBtn.MouseButton1Click:Connect(function()
    brightEnabled = false
    darkEnabled = false
    fogEnabled = false
    sharpEnabled = false

    Lighting.Brightness = default.Brightness
    Lighting.ClockTime = default.ClockTime
    Lighting.FogEnd = default.FogEnd
    Lighting.GlobalShadows = default.GlobalShadows
    Lighting.Ambient = default.Ambient
    Lighting.OutdoorAmbient = default.OutdoorAmbient

    if sharpenEffect then
        sharpenEffect:Destroy()
        sharpenEffect = nil
    end

    brightBtn.Text = "FullBright OFF"
    darkBtn.Text = "Dark OFF"
    fogBtn.Text = "Fog OFF"
    sharpBtn.Text = "Sharpen OFF"
end)

-- AUTO CANVAS SIZE
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)
