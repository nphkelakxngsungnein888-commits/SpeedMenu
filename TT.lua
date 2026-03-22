-- StarterPlayerScripts/LockTarget.lua  

local Players = game:GetService("Players")  
local RunService = game:GetService("RunService")  
local UIS = game:GetService("UserInputService")  
local GuiService = game:GetService("GuiService")

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

local circleDragEnabled = false  
local dragging = false  

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

local dragToggle = Instance.new("TextButton", frame)  
dragToggle.Position = UDim2.new(0,0,0,100)  
dragToggle.Size = UDim2.new(1,0,0,40)  
dragToggle.Text = "Drag: OFF"  

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
circle.Active = true  

local corner = Instance.new("UICorner", circle)  
corner.CornerRadius = UDim.new(1,0)  

local stroke = Instance.new("UIStroke", circle)  
stroke.Color = Color3.fromRGB(0,255,0)  
stroke.Thickness = 2  

-- toggle lock  
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

-- drag toggle  
dragToggle.MouseButton1Click:Connect(function()  
    circleDragEnabled = not circleDragEnabled  
    dragToggle.Text = circleDragEnabled and "Drag: ON" or "Drag: OFF"  
end)  

-- drag start  
circle.InputBegan:Connect(function(input)  
    if not circleDragEnabled then return end  
    if input.UserInputType == Enum.UserInputType.MouseButton1 then  
        dragging = true  
    end  
end)  

-- drag end  
circle.InputEnded:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.MouseButton1 then  
        dragging = false  
    end  
end)  

-- drag move (FIXED)
UIS.InputChanged:Connect(function(input)  
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then  
        local mousePos = UIS:GetMouseLocation()  
        local inset = GuiService:GetGuiInset()  

        local x = mousePos.X - inset.X  
        local y = mousePos.Y - inset.Y  

        circle.Position = UDim2.new(0, x, 0, y)  
    end  
end)  

deleteBtn.MouseButton1Click:Connect(function()  
    running = false  
    camera.CameraType = Enum.CameraType.Custom  
    UIS.MouseBehavior = Enum.MouseBehavior.Default  
    gui:Destroy()  
end)  

-- mouse input  
UIS.InputChanged:Connect(function(input)  
    if not enabled then return end  
    if input.UserInputType == Enum.UserInputType.MouseMovement then  
        yaw -= input.Delta.X * sensitivity  
        pitch -= input.Delta.Y * sensitivity  
        pitch = math.clamp(pitch, -80, 80)  
    end  
end)  

-- circle center  
local function getCircleCenter()  
    return Vector2.new(  
        circle.AbsolutePosition.X + circle.AbsoluteSize.X/2,  
        circle.AbsolutePosition.Y + circle.AbsoluteSize.Y/2  
    )  
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

    local circleCenter = getCircleCenter()  

    -- 🔥 reset ถ้าออกวง
    if currentTarget then  
        local pos, onScreen = camera:WorldToViewportPoint(currentTarget.HumanoidRootPart.Position)  
        if not onScreen or (Vector2.new(pos.X, pos.Y) - circleCenter).Magnitude > radius then  
            currentTarget = nil  
        end  
    end  

    if not currentTarget then  
        currentTarget = findTarget()  
    end  

    if currentTarget then  
        local root = char.HumanoidRootPart  
        local targetPos = currentTarget.HumanoidRootPart.Position  

        local camRot = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)  
        local camPos = root.Position + camRot:VectorToWorldSpace(cameraOffset)  

        local desiredCF = CFrame.new(camPos, targetPos)  

        camera.CFrame = camera.CFrame:Lerp(desiredCF, math.clamp(dt * smoothness, 0.3, 1))  
        root.CFrame = CFrame.new(root.Position, targetPos)  
    end  
end)
