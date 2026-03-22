-- StarterPlayerScripts/LockTarget.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local radius = 150
local running = true
local smoothness = 15 -- 🔥 แรงขึ้นให้ดึงเข้ากลางไว

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
circle.Size = UDim2.new(0, radius*2, 0, radius*2)
circle.BackgroundTransparency = 1

local corner = Instance.new("UICorner", circle)
corner.CornerRadius = UDim.new(1,0)

local stroke = Instance.new("UIStroke", circle)
stroke.Color = Color3.fromRGB(0,255,0)
stroke.Thickness = 2

toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "Toggle: ON" or "Toggle: OFF"
end)

slider.MouseButton1Click:Connect(function()
    radius += 25
    if radius > 400 then radius = 50 end
    slider.Text = "Radius: "..radius
    circle.Size = UDim2.new(0, radius*2, 0, radius*2)
end)

deleteBtn.MouseButton1Click:Connect(function()
    running = false
    gui:Destroy()
end)

-- target
local function getTarget()
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

RunService.RenderStepped:Connect(function(dt)
    if not running or not enabled then return end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local target = getTarget()
    if target then
        local targetPos = target.HumanoidRootPart.Position

        local screenPos, _ = camera:WorldToViewportPoint(targetPos)
        local center = camera.ViewportSize / 2

        local offset = Vector2.new(screenPos.X, screenPos.Y) - center

        -- 🔥 แปลง offset เป็นมุมหมุน
        local adjust = CFrame.Angles(
            math.rad(-offset.Y * 0.05),
            math.rad(-offset.X * 0.05),
            0
        )

        local desiredCF = CFrame.new(camera.CFrame.Position, targetPos) * adjust

        local alpha = math.clamp(dt * smoothness, 0.25, 1)

        camera.CFrame = camera.CFrame:Lerp(desiredCF, alpha)

        -- sync character
        char.HumanoidRootPart.CFrame = CFrame.new(
            char.HumanoidRootPart.Position,
            camera.CFrame.LookVector * 1000 + char.HumanoidRootPart.Position
        )
    end
end)                end
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function(dt)
    if not running or not enabled then return end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local target = getTarget()
    if target then
        local targetPos = target.HumanoidRootPart.Position

        -- 🔥 ใช้ CFrame เดียว
        local targetCF = CFrame.new(char.HumanoidRootPart.Position, targetPos)

        -- 🔥 clamp speed (กันช้า)
        local alpha = math.clamp(dt * smoothness, 0.2, 1)

        -- sync ทั้งคู่
        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame:Lerp(targetCF, alpha)
        camera.CFrame = camera.CFrame:Lerp(
            CFrame.new(camera.CFrame.Position, targetPos),
            alpha
        )
    end
end)
