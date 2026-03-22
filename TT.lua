-- StarterPlayerScripts/LockTarget.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local radius = 150
local running = true

-- UI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "LockUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 150)
frame.Position = UDim2.new(0.5, -100, 0.5, -75)
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
circle.BackgroundTransparency = 0.7
circle.BackgroundColor3 = Color3.fromRGB(0,255,0)

local corner = Instance.new("UICorner", circle)
corner.CornerRadius = UDim.new(1,0)

-- toggle
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "Toggle: ON" or "Toggle: OFF"
end)

-- slider (click to increase)
slider.MouseButton1Click:Connect(function()
    radius += 25
    if radius > 400 then radius = 50 end
    slider.Text = "Radius: "..radius
    circle.Size = UDim2.new(0, radius*2, 0, radius*2)
end)

-- delete
deleteBtn.MouseButton1Click:Connect(function()
    running = false
    gui:Destroy()
end)

-- find target
local function getTarget()
    local closest = nil
    local shortest = radius

    for _, v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and v ~= player.Character then
                local pos, onScreen = camera:WorldToViewportPoint(v.HumanoidRootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = v
                    end
                end
            end
        end
    end

    return closest
end

-- main loop
RunService.RenderStepped:Connect(function()
    if not running then return end
    if not enabled then return end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local target = getTarget()
    if target then
        local targetPos = target.HumanoidRootPart.Position

        -- rotate camera
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)

        -- rotate character
        char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position, targetPos)
    end
end)
