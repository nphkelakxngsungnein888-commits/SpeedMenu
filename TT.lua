-- StarterPlayerScripts/LockTarget.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local enabled = false
local radius = 150
local running = true
local lockStrength = 1 -- 1 = slow, 3 = fast

-- UI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "LockUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 200)
frame.Position = UDim2.new(0.1, 0, 0.5, -100)
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

local strengthBtn = Instance.new("TextButton", frame)
strengthBtn.Position = UDim2.new(0,0,0,100)
strengthBtn.Size = UDim2.new(1,0,0,40)
strengthBtn.Text = "Strength: 1"

local deleteBtn = Instance.new("TextButton", frame)
deleteBtn.Position = UDim2.new(0,0,0,150)
deleteBtn.Size = UDim2.new(1,0,0,40)
deleteBtn.Text = "DELETE"

-- circle (outline only)
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

-- toggle
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "Toggle: ON" or "Toggle: OFF"
end)

-- radius
slider.MouseButton1Click:Connect(function()
    radius += 25
    if radius > 400 then radius = 50 end
    slider.Text = "Radius: "..radius
    circle.Size = UDim2.new(0, radius*2, 0, radius*2)
end)

-- strength
strengthBtn.MouseButton1Click:Connect(function()
    lockStrength += 1
    if lockStrength > 3 then lockStrength = 1 end
    strengthBtn.Text = "Strength: "..lockStrength
end)

-- delete
deleteBtn.MouseButton1Click:Connect(function()
    running = false
    gui:Destroy()
end)

-- get closest target (3D distance)
local function getTarget()
    local closest = nil
    local shortest = math.huge

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myPos = char.HumanoidRootPart.Position

    for _, v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and v ~= char then
                local dist3D = (v.HumanoidRootPart.Position - myPos).Magnitude
                if dist3D < shortest then
                    -- check if inside circle (screen)
                    local pos, onScreen = camera:WorldToViewportPoint(v.HumanoidRootPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(pos.X, pos.Y) - camera.ViewportSize/2).Magnitude
                        if screenDist <= radius then
                            shortest = dist3D
                            closest = v
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- strength mapping
local function getLerpAlpha()
    if lockStrength == 1 then return 0.1 end
    if lockStrength == 2 then return 0.2 end
    if lockStrength == 3 then return 0.35 end
end

-- main loop
RunService.RenderStepped:Connect(function()
    if not running or not enabled then return end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local target = getTarget()
    if target then
        local targetPos = target.HumanoidRootPart.Position
        local alpha = getLerpAlpha()

        -- smooth camera
        local newCam = CFrame.new(camera.CFrame.Position, targetPos)
        camera.CFrame = camera.CFrame:Lerp(newCam, alpha)

        -- smooth character
        local root = char.HumanoidRootPart
        local newChar = CFrame.new(root.Position, targetPos)
        root.CFrame = root.CFrame:Lerp(newChar, alpha)
    end
end)
