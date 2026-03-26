-- /client/auto_evade.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

-- CONFIG
local enabled = false
local mode = "Player" -- "Player" / "Monster"
local safeDistance = 20

-- UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "EvadeUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0.5, -110, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 10)

-- Toggle Button
local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1, -20, 0, 30)
toggle.Position = UDim2.new(0,10,0,10)
toggle.Text = "OFF"
toggle.BackgroundColor3 = Color3.fromRGB(60,60,60)

-- Mode Button
local modeBtn = Instance.new("TextButton", frame)
modeBtn.Size = UDim2.new(1, -20, 0, 30)
modeBtn.Position = UDim2.new(0,10,0,50)
modeBtn.Text = "Mode: Player"
modeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)

-- Distance Box
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -20, 0, 30)
box.Position = UDim2.new(0,10,0,90)
box.Text = tostring(safeDistance)
box.PlaceholderText = "Distance"

-- Resize
local resizing = false
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        resizing = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        resizing = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
        frame.Size += UDim2.new(0, input.Delta.X, 0, input.Delta.Y)
    end
end)

-- UI Logic
toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggle.Text = enabled and "ON" or "OFF"
end)

modeBtn.MouseButton1Click:Connect(function()
    mode = (mode == "Player") and "Monster" or "Player"
    modeBtn.Text = "Mode: "..mode
end)

box.FocusLost:Connect(function()
    local num = tonumber(box.Text)
    if num then safeDistance = num end
end)

-- TARGET FINDER
local function getNearestTarget()
    local nearest = nil
    local shortest = math.huge

    if mode == "Player" then
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = p.Character
                end
            end
        end
    else
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v ~= char and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                local dist = (root.Position - v.HumanoidRootPart.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = v
                end
            end
        end
    end

    return nearest, shortest
end

-- MAIN LOOP
RunService.Heartbeat:Connect(function()
    if not enabled then return end
    if not char or not root then return end

    local target, dist = getNearestTarget()

    if target and dist < safeDistance then
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        local direction = (root.Position - targetRoot.Position).Unit

        -- move backward
        humanoid:Move(direction, true)

        -- face target
        root.CFrame = CFrame.lookAt(root.Position, targetRoot.Position)
    end
end)
