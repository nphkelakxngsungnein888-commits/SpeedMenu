--// SERVICES
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")

--// STATE
local enabled = false
local brightness = 5

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "FullBright_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 170, 0, 140)
frame.Position = UDim2.new(0.03, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-60,0,25)
title.Position = UDim2.new(0,5,0,0)
title.Text = "FullBright"
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

local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1,-10,0,30)
toggle.Position = UDim2.new(0,5,0,30)
toggle.Text = "OFF"
toggle.BackgroundColor3 = Color3.fromRGB(200,50,50)
toggle.TextColor3 = Color3.new(1,1,1)

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1,-10,0,30)
box.Position = UDim2.new(0,5,0,70)
box.PlaceholderText = "Brightness (เช่น 5, 10, 50)"
box.BackgroundColor3 = Color3.fromRGB(50,50,50)
box.TextColor3 = Color3.new(1,1,1)

--// DRAG (มือถือ + PC)
local dragging = false
local dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement 
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--// CLOSE / MINI
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggle.Visible = not minimized
    box.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,170,0,30) or UDim2.new(0,170,0,140)
end)

--// APPLY FULLBRIGHT
local function apply()
    Lighting.Brightness = brightness
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
end

--// TOGGLE
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)

    if enabled then
        apply()
    end
end)

--// INPUT BRIGHTNESS
box.FocusLost:Connect(function()
    local num = tonumber(box.Text)
    if num then
        brightness = num
        if enabled then
            apply()
        end
    else
        box.Text = ""
    end
end)

--// กันเกมรีเซ็ตค่า
Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
    if enabled then Lighting.Brightness = brightness end
end)

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
    if enabled then Lighting.ClockTime = 14 end
end)

Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if enabled then Lighting.FogEnd = 100000 end
end)

Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
    if enabled then Lighting.GlobalShadows = false end
end)
