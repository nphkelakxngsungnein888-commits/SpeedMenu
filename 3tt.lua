-- /client/auto_evade.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

local char, humanoid, root

local function setupCharacter(c)
    char = c
    humanoid = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
end

setupCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupCharacter)

-- CONFIG
local enabled = false
local mode = "Player"
local safeDistance = 20

-- UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "EvadeUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 160)
frame.Position = UDim2.new(0.5, -120, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Toggle
local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1, -20, 0, 30)
toggle.Position = UDim2.new(0,10,0,10)
toggle.Text = "OFF"

-- Mode switch
local modeBtn = Instance.new("TextButton", frame)
modeBtn.Size = UDim2.new(1, -20, 0, 30)
modeBtn.Position = UDim2.new(0,10,0,50)
modeBtn.Text = "Mode: Player"

-- Distance
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1, -20, 0, 30)
box.Position = UDim2.new(0,10,0,90)
box.Text = tostring(safeDistance)

-- UI logic
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

-- GET ALL THREATS
local function getThreats()
    local threats = {}

    if mode == "Player" then
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < safeDistance then
                    table.insert(threats, p.Character)
                end
            end
        end
    else
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v ~= char and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                local dist = (root.Position - v.HumanoidRootPart.Position).Magnitude
                if dist < safeDistance then
                    table.insert(threats, v)
                end
            end
        end
    end

    return threats
end

-- MAIN LOOP (MULTI EVADE)
RunService.Heartbeat:Connect(function()
    if not enabled or not root or not humanoid then return end

    local threats = getThreats()
    if #threats == 0 then return end

    local totalDirection = Vector3.zero
    local closestTarget = nil
    local closestDist = math.huge

    for _,target in pairs(threats) do
        local tRoot = target:FindFirstChild("HumanoidRootPart")
        if tRoot then
            local offset = root.Position - tRoot.Position
            local dist = offset.Magnitude

            if dist < closestDist then
                closestDist = dist
                closestTarget = tRoot
            end

            totalDirection += offset.Unit / dist -- weight ใกล้มากหนีแรง
        end
    end

    if totalDirection.Magnitude > 0 then
        local moveDir = totalDirection.Unit
        local moveToPos = root.Position + (moveDir * 12)

        humanoid:MoveTo(moveToPos)

        -- หันหน้าไปตัวที่ใกล้สุด
        if closestTarget then
            root.CFrame = CFrame.lookAt(root.Position, closestTarget.Position)
        end
    end
end)
