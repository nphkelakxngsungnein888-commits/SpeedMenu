-- StarterPlayerScripts/LockTarget.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local radius = 150
local running = true

local currentTarget = nil

-- UI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "LockUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 150)
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

local deleteBtn = Instance.new("TextButton", frame)
deleteBtn.Position = UDim2.new(0,0,0,100)
deleteBtn.Size = UDim2.new(1,0,0,40)
deleteBtn.Text = "DELETE"

-- circle
local circle = Instance.new("Frame", gui)
circle.AnchorPoint = Vector2.new(0.5,0.5)
circle.Position = UDim2.new(0.5,0,0.5,0)
circle.Size = UDim2.new(0, radius, 0, radius)
circle.BackgroundTransparency = 1

local corner = Instance.new("UICorner", circle)
corner.CornerRadius = UDim.new(1,0)

local stroke = Instance.new("UIStroke", circle)
stroke.Color = Color3.fromRGB(0,255,0)
stroke.Thickness = 2

toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "Toggle: ON" or "Toggle: OFF"

    camera.CameraType = Enum.CameraType.Custom

    if enabled then    
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter    
    else    
        UIS.MouseBehavior = Enum.MouseBehavior.Default    
        currentTarget = nil    
    end
end)

slider.MouseButton1Click:Connect(function()
    radius += 25
    if radius > 400 then radius = 50 end
    slider.Text = "Radius: "..radius
    circle.Size = UDim2.new(0, radius, 0, radius)
end)

deleteBtn.MouseButton1Click:Connect(function()
    running = false
    camera.CameraType = Enum.CameraType.Custom
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    gui:Destroy()
end)

local function getEyePosition(character)
    local head = character:FindFirstChild("Head")
    if head then
        return head.Position + Vector3.new(0, 1.2, 0)
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        return hrp.Position + Vector3.new(0, 2, 0)
    end
    
    return nil
end

local function findTarget()
    local closest = nil
    local shortest = math.huge

    local char = player.Character    
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end    

    local myPos = char.HumanoidRootPart.Position    

    for _, v in pairs(workspace:GetDescendants()) do    
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then    
            if v.Humanoid.Health > 0 and v ~= char then    
                local targetPos = v.HumanoidRootPart.Position    
                local dist3D = (myPos - targetPos).Magnitude    

                local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)    
                if onScreen then    
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - camera.ViewportSize/2).Magnitude    
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

RunService.RenderStepped:Connect(function()
    if not running or not enabled then return end

    local char = player.Character    
    if not char then return end    

    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid then return end

    -- 🔥 shoulder cam (ไม่ใช้ Scriptable)
    humanoid.CameraOffset = Vector3.new(2, 1, 0)

    if not currentTarget or currentTarget.Humanoid.Health <= 0 then    
        currentTarget = findTarget()    
    end    

    local target = currentTarget    
    if target then    
        local eyeTargetPos = getEyePosition(target)
        if not eyeTargetPos then return end

        -- 🔥 หมุนตัวละครหาเป้า
        root.CFrame = CFrame.new(root.Position, eyeTargetPos)

        -- 🔥 วงตามเป้า
        local screenPos, onScreen = camera:WorldToViewportPoint(eyeTargetPos)
        if onScreen then
            circle.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
        end
    else
        circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
end)
