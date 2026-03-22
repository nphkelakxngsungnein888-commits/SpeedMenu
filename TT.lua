-- StarterPlayerScripts/LockTarget.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local radius = 150
local running = true
local smoothness = 50

local currentTarget = nil
local cameraOffset = Vector3.new(0, 5, -10)

local yaw = 0
local pitch = 0
local sensitivity = 0.2

local moveCircleEnabled = false

-- UI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "LockUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 200)
frame.Position = UDim2.new(0, 20, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1,0,0,40)
toggle.Text = "Toggle: OFF"

local slider = Instance.new("TextButton", frame)
slider.Position = UDim2.new(0,0,0,50)
slider.Size = UDim2.new(1,0,0,40)
slider.Text = "Radius: 150"

local moveBtn = Instance.new("TextButton", frame)
moveBtn.Position = UDim2.new(0,0,0,100)
moveBtn.Size = UDim2.new(1,0,0,40)
moveBtn.Text = "Move Circle: OFF"

local deleteBtn = Instance.new("TextButton", frame)
deleteBtn.Position = UDim2.new(0,0,0,150)
deleteBtn.Size = UDim2.new(1,0,0,40)
deleteBtn.Text = "DELETE"

-- circle
local circle = Instance.new("Frame", gui)
circle.AnchorPoint = Vector2.new(0.5,0.5)
circle.Position = UDim2.new(0.5,0,0.5,0)
circle.Size = UDim2.new(0, radius*2, 0, radius*2)
circle.BackgroundTransparency = 1
circle.Active = false
circle.Draggable = false

local corner = Instance.new("UICorner", circle)
corner.CornerRadius = UDim.new(1,0)

local stroke = Instance.new("UIStroke", circle)
stroke.Color = Color3.fromRGB(0,255,0)
stroke.Thickness = 2

-- toggle aim
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "Toggle: ON" or "Toggle: OFF"

    if enabled then
        camera.CameraType = Enum.CameraType.Scriptable
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
    else
        camera.CameraType = Enum.CameraType.Custom
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        currentTarget = nil
    end
end)

-- radius
slider.MouseButton1Click:Connect(function()
    radius += 25
    if radius > 400 then radius = 50 end
    slider.Text = "Radius: "..radius
    circle.Size = UDim2.new(0, radius*2, 0, radius*2)
end)

-- move circle toggle
moveBtn.MouseButton1Click:Connect(function()
    moveCircleEnabled = not moveCircleEnabled
    moveBtn.Text = moveCircleEnabled and "Move Circle: ON" or "Move Circle: OFF"

    circle.Active = moveCircleEnabled
    circle.Draggable = moveCircleEnabled
end)

-- delete
deleteBtn.MouseButton1Click:Connect(function()
    running = false
    camera.CameraType = Enum.CameraType.Custom
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    gui:Destroy()
end)

-- mouse look
UIS.InputChanged:Connect(function(input)
    if not enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        yaw -= input.Delta.X * sensitivity
        pitch -= input.Delta.Y * sensitivity
        pitch = math.clamp(pitch, -80, 80)
    end
end)

-- get circle center (สำคัญ)
local function getCircleCenter()
    local absPos = circle.AbsolutePosition
    local absSize = circle.AbsoluteSize
    return Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2)
end

-- find target
local function findTarget()
    local closest = nil
    local shortest = math.huge

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local myPos = char.HumanoidRootPart.Position
    local circleCenter = getCircleCenter()

    for _, v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and v ~= char then
                local targetPos = v.HumanoidRootPart.Position
                local dist3D = (myPos - targetPos).Magnitude

                local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
                if onScreen then
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - circleCenter).Magnitude
                    if dist2D <= radius and dist3D < shortest then
                        shortest = dist3D
                        closest = v
                    end
                end
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function(dt)
    if not running or not enabled then return end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    if not currentTarget or currentTarget.Humanoid.Health <= 0 then
        currentTarget = findTarget()
    end

    local target = currentTarget
    if target then
        local root = char.HumanoidRootPart
        local targetPos = target.HumanoidRootPart.Position

        local camRot = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
        local camPos = root.Position + camRot:VectorToWorldSpace(cameraOffset)

        local desiredCF = CFrame.new(camPos, targetPos)
        camera.CFrame = camera.CFrame:Lerp(desiredCF, math.clamp(dt * smoothness, 0.3, 1))

        root.CFrame = CFrame.new(root.Position, targetPos)
    end
end)
