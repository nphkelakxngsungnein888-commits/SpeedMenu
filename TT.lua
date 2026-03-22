local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local lockEnabled = true
local circleSize = 150
local target = nil

-- UI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MonsterLockUI"

-- วงกลมกลางจอ
local circle = Instance.new("Frame", gui)
circle.Size = UDim2.new(0, circleSize, 0, circleSize)
circle.Position = UDim2.new(0.5, -circleSize/2, 0.5, -circleSize/2)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 2
circle.BorderColor3 = Color3.fromRGB(255, 0, 0)

local uicorner = Instance.new("UICorner", circle)
uicorner.CornerRadius = UDim.new(1,0)

-- กล่อง UI เล็ก ๆ
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 140, 0, 80)
panel.Position = UDim2.new(0, 20, 0.5, -40)
panel.BackgroundColor3 = Color3.fromRGB(30,30,30)
panel.Active = true
panel.Draggable = true

local close = Instance.new("TextButton", panel)
close.Size = UDim2.new(0, 20, 0, 20)
close.Position = UDim2.new(1,-22,0,2)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(255,50,50)

local toggle = Instance.new("TextButton", panel)
toggle.Size = UDim2.new(1,-10,0,25)
toggle.Position = UDim2.new(0,5,0,5)
toggle.Text = "LOCK : ON"
toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)

local sizeBox = Instance.new("TextBox", panel)
sizeBox.Size = UDim2.new(1,-10,0,25)
sizeBox.Position = UDim2.new(0,5,0,40)
sizeBox.PlaceholderText = "Circle Size"
sizeBox.Text = ""

-- ปิด UI
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- เปิด/ปิดระบบล็อค
toggle.MouseButton1Click:Connect(function()
    lockEnabled = not lockEnabled
    toggle.Text = lockEnabled and "LOCK : ON" or "LOCK : OFF"
end)

-- เปลี่ยนขนาดวงกลม
sizeBox.FocusLost:Connect(function()
    local n = tonumber(sizeBox.Text)
    if n then
        circleSize = n
        circle.Size = UDim2.new(0, circleSize, 0, circleSize)
        circle.Position = UDim2.new(0.5, -circleSize/2, 0.5, -circleSize/2)
    end
end)

-- หามอนในวงกลม
local function getTarget()
    local closest = nil
    local distance = math.huge

    for _,v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= char then
            
            local pos, visible = camera:WorldToViewportPoint(v.HumanoidRootPart.Position)
            
            if visible then
                local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                local monsterPos = Vector2.new(pos.X, pos.Y)
                local dist = (screenCenter - monsterPos).Magnitude

                if dist < circleSize/2 and dist < distance then
                    distance = dist
                    closest = v
                end
            end
        end
    end

    return closest
end

-- ล็อคมอน + หันกล้อง
RS.RenderStepped:Connect(function()
    if not lockEnabled then return end

    target = getTarget()

    if target and target:FindFirstChild("HumanoidRootPart") then
        root.CFrame = CFrame.lookAt(root.Position, target.HumanoidRootPart.Position)

        camera.CFrame = CFrame.new(camera.CFrame.Position, target.HumanoidRootPart.Position)
    end
end)
