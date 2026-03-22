local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

-- ================= GUI =================

local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local circle = Instance.new("Frame")
circle.Parent = gui
circle.Size = UDim2.new(0,220,0,220)
circle.Position = UDim2.new(0.5,-110,0.5,-110)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 3
circle.BorderColor3 = Color3.fromRGB(255,255,255)

local corner = Instance.new("UICorner")
corner.Parent = circle
corner.CornerRadius = UDim.new(1,0)

-- ปุ่มเปิด/ปิด
local toggle = Instance.new("TextButton")
toggle.Parent = gui
toggle.Size = UDim2.new(0,130,0,40)
toggle.Position = UDim2.new(0,30,0.7,0)
toggle.Text = "LOCK : OFF"
toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggle.TextColor3 = Color3.new(1,1,1)

-- ช่องปรับขนาด
local sizeBox = Instance.new("TextBox")
sizeBox.Parent = gui
sizeBox.Size = UDim2.new(0,130,0,40)
sizeBox.Position = UDim2.new(0,30,0.8,0)
sizeBox.Text = "220"
sizeBox.PlaceholderText = "Circle Size"

-- ลบ GUI
local delete = Instance.new("TextButton")
delete.Parent = gui
delete.Size = UDim2.new(0,130,0,40)
delete.Position = UDim2.new(0,30,0.9,0)
delete.Text = "DELETE"
delete.BackgroundColor3 = Color3.fromRGB(70,0,0)
delete.TextColor3 = Color3.new(1,1,1)

-- ================= SETTINGS =================

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

-- ================= หาเป้า =================

local function getTarget()
    local closest = nil
    local shortest = math.huge

    for _,v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= character then

            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then

                local pos, visible = camera:WorldToViewportPoint(hrp.Position)

                if visible then
                    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                    local dist = (Vector2.new(pos.X,pos.Y) - center).Magnitude

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

-- ================= ล็อคเป้า =================

game:GetService("RunService").RenderStepped:Connect(function()

    if not enabled then return end

    local target = getTarget()
    if not target then return end

    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- หันตัวละครไปทางเป้า
    root.CFrame = CFrame.lookAt(root.Position, hrp.Position)

    -- กล้องหมุนตามเป้า (ไม่หลุดเวลาเดิน)
    camera.CFrame = CFrame.lookAt(
        camera.CFrame.Position,
        hrp.Position
    )

end)
