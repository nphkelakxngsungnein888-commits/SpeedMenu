--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// STATE
local enabled = false
local distance = 50

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "LockCamera_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 180, 0, 140)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -60, 0, 25)
title.Position = UDim2.new(0, 5, 0, 0)
title.Text = "Lock Camera"
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
box.PlaceholderText = "ใส่ระยะ เช่น 1000"
box.BackgroundColor3 = Color3.fromRGB(50,50,50)
box.TextColor3 = Color3.new(1,1,1)

--// DRAG (มือถือได้)
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

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    frame.Size = minimized and UDim2.new(0,180,0,30) or UDim2.new(0,180,0,140)
end)

--// TOGGLE
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

--// INPUT (ไม่จำกัด)
box.FocusLost:Connect(function()
    local num = tonumber(box.Text)
    if num then
        distance = num
        box.Text = tostring(num)
    else
        box.Text = ""
    end
end)

--// MAIN LOOP (ล็อคกล้องจริง)
RunService.RenderStepped:Connect(function()
    if not enabled then return end

    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local look = camera.CFrame.LookVector

    -- 🔥 ล็อคระยะกล้อง
    camera.CFrame = CFrame.new(
        root.Position - look * distance,
        root.Position
    )
end)
