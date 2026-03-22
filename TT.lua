local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = workspace.CurrentCamera
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local circle = Instance.new("Frame")
circle.Parent = gui
circle.Size = UDim2.new(0,200,0,200)
circle.Position = UDim2.new(0.5,-100,0.5,-100)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 2
circle.BorderColor3 = Color3.fromRGB(255,255,255)

local toggle = Instance.new("TextButton")
toggle.Parent = gui
toggle.Size = UDim2.new(0,120,0,40)
toggle.Position = UDim2.new(0,50,0.7,0)
toggle.Text = "LOCK : OFF"
toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggle.TextColor3 = Color3.fromRGB(255,255,255)

local sizeBox = Instance.new("TextBox")
sizeBox.Parent = gui
sizeBox.Size = UDim2.new(0,120,0,40)
sizeBox.Position = UDim2.new(0,50,0.8,0)
sizeBox.Text = "200"
sizeBox.PlaceholderText = "Circle Size"

local delete = Instance.new("TextButton")
delete.Parent = gui
delete.Size = UDim2.new(0,120,0,40)
delete.Position = UDim2.new(0,50,0.9,0)
delete.Text = "DELETE GUI"
delete.BackgroundColor3 = Color3.fromRGB(60,0,0)
delete.TextColor3 = Color3.fromRGB(255,255,255)

-- ตัวแปร
local enabled = false

toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "LOCK : ON" or "LOCK : OFF"
end)

delete.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

sizeBox.FocusLost:Connect(function()
    local n = tonumber(sizeBox.Text)
    if n then
        circle.Size = UDim2.new(0,n,0,n)
        circle.Position = UDim2.new(0.5,-n/2,0.5,-n/2)
    end
end)

-- หาเป้าในวง
local function getTarget()
    local closest = nil
    local shortest = math.huge

    for i,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= character then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    local cx = camera.ViewportSize.X/2
                    local cy = camera.ViewportSize.Y/2

                    local dist = (Vector2.new(pos.X,pos.Y) - Vector2.new(cx,cy)).Magnitude

                    if dist < circle.AbsoluteSize.X/2 then
                        if dist < shortest then
                            shortest = dist
                            closest = v
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- ล็อคเป้า
game:GetService("RunService").RenderStepped:Connect(function()
    if not enabled then return end

    local target = getTarget()

    if target then
        local hrp = target:FindFirstChild("HumanoidRootPart")

        if hrp then
            humanoidRootPart.CFrame = CFrame.lookAt(humanoidRootPart.Position, hrp.Position)
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, hrp.Position)
        end
    end
end)
