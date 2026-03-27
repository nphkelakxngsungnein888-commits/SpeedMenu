--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// STATE
local enabled = false
local freecam = false
local distance = 50

local camPos = Vector3.new()
local angleX, angleY = 0, 0
local speed = 5
local move = Vector3.new()

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "LockCamera_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 180, 0, 170)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -60, 0, 25)
title.Position = UDim2.new(0, 5, 0, 0)
title.Text = "Camera System"
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
toggle.Text = "Lock OFF"
toggle.BackgroundColor3 = Color3.fromRGB(200,50,50)

local freeBtn = Instance.new("TextButton", frame)
freeBtn.Size = UDim2.new(1,-10,0,30)
freeBtn.Position = UDim2.new(0,5,0,65)
freeBtn.Text = "FreeCam OFF"
freeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1,-10,0,30)
box.Position = UDim2.new(0,5,0,100)
box.PlaceholderText = "Distance"
box.BackgroundColor3 = Color3.fromRGB(50,50,50)
box.TextColor3 = Color3.new(1,1,1)

--// CONTROL UI (มือถือ)
local controlFrame = Instance.new("Frame", gui)
controlFrame.Size = UDim2.new(0,160,0,160)
controlFrame.Position = UDim2.new(0.75,0,0.6,0)
controlFrame.BackgroundTransparency = 1
controlFrame.Visible = false

local function makeBtn(name, pos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,45,0,45)
    b.Position = pos
    b.Text = name
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = controlFrame
    return b
end

local btnF = makeBtn("↑", UDim2.new(0.5,-22,0,0))
local btnB = makeBtn("↓", UDim2.new(0.5,-22,0,90))
local btnL = makeBtn("←", UDim2.new(0,0,0.5,-22))
local btnR = makeBtn("→", UDim2.new(0,90,0.5,-22))
local btnU = makeBtn("Up", UDim2.new(0,0,0,0))
local btnD = makeBtn("Dn", UDim2.new(0,90,0,0))

--// BIND BUTTON
local function bind(btn, vec)
    btn.MouseButton1Down:Connect(function()
        move = move + vec
    end)
    btn.MouseButton1Up:Connect(function()
        move = move - vec
    end)
end

bind(btnF, Vector3.new(0,0,-1))
bind(btnB, Vector3.new(0,0,1))
bind(btnL, Vector3.new(-1,0,0))
bind(btnR, Vector3.new(1,0,0))
bind(btnU, Vector3.new(0,1,0))
bind(btnD, Vector3.new(0,-1,0))

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

--// CLOSE / MINI
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    toggle.Visible = not minimized
    freeBtn.Visible = not minimized
    box.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,180,0,30) or UDim2.new(0,180,0,170)
end)

--// BUTTONS
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "Lock ON" or "Lock OFF"
    toggle.BackgroundColor3 = enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

freeBtn.MouseButton1Click:Connect(function()
    freecam = not freecam
    freeBtn.Text = freecam and "FreeCam ON" or "FreeCam OFF"
    freeBtn.BackgroundColor3 = freecam and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)

    controlFrame.Visible = freecam

    if freecam then
        camPos = camera.CFrame.Position
    end
end)

--// INPUT DISTANCE
box.FocusLost:Connect(function()
    local num = tonumber(box.Text)
    if num then
        distance = num
    end
end)

--// LOOK (หมุนกล้อง)
UIS.InputChanged:Connect(function(input)
    if freecam then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            angleX = angleX - input.Delta.X * 0.2
            angleY = math.clamp(angleY - input.Delta.Y * 0.2, -80, 80)
        end
    end
end)

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- LOCK MODE
    if enabled and not freecam then
        local look = camera.CFrame.LookVector
        camera.CFrame = CFrame.new(root.Position - look * distance, root.Position)
    end

    -- FREECAM
    if freecam then
        local rot = CFrame.Angles(0, math.rad(angleX), 0) * CFrame.Angles(math.rad(angleY), 0, 0)
        local dir = rot.LookVector

        camPos = camPos + dir * move.Z * speed
        camPos = camPos + rot.RightVector * move.X * speed
        camPos = camPos + Vector3.new(0, move.Y * speed, 0)

        camera.CFrame = CFrame.new(camPos, camPos + dir)
    end
end)
