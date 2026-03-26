-- /client/auto_escape.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ===== STATE =====
local Enabled = false
local Mode = "Players" -- "Players" or "Monsters"
local Distance = 20

-- ===== CHARACTER =====
local function getCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char, char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
end

-- ===== UI =====
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AutoEscapeUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0.3, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 10)

-- Resize
local resize = Instance.new("TextButton", frame)
resize.Size = UDim2.new(0, 20, 0, 20)
resize.Position = UDim2.new(1, -20, 1, -20)
resize.Text = "+"
resize.BackgroundColor3 = Color3.fromRGB(40,40,40)

resize.MouseButton1Click:Connect(function()
    frame.Size += UDim2.new(0, 20, 0, 20)
end)

-- Close
local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 20, 0, 20)
close.Position = UDim2.new(1, -20, 0, 0)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(80,30,30)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Toggle
local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1, -10, 0, 30)
toggle.Position = UDim2.new(0, 5, 0, 5)
toggle.Text = "OFF"
toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)

toggle.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    toggle.Text = Enabled and "ON" or "OFF"
end)

-- Mode
local modeBtn = Instance.new("TextButton", frame)
modeBtn.Size = UDim2.new(1, -10, 0, 30)
modeBtn.Position = UDim2.new(0, 5, 0, 40)
modeBtn.Text = "Mode: Players"
modeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)

modeBtn.MouseButton1Click:Connect(function()
    Mode = Mode == "Players" and "Monsters" or "Players"
    modeBtn.Text = "Mode: " .. Mode
end)

-- Distance input
local distBox = Instance.new("TextBox", frame)
distBox.Size = UDim2.new(1, -10, 0, 30)
distBox.Position = UDim2.new(0, 5, 0, 75)
distBox.Text = tostring(Distance)
distBox.BackgroundColor3 = Color3.fromRGB(50,50,50)

distBox.FocusLost:Connect(function()
    local val = tonumber(distBox.Text)
    if val then
        Distance = val
    else
        distBox.Text = tostring(Distance)
    end
end)

-- ===== ENEMY FIND =====
local function getEnemies()
    local enemies = {}

    if Mode == "Players" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(enemies, p.Character)
            end
        end
    else
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) then
                if v:FindFirstChild("HumanoidRootPart") then
                    table.insert(enemies, v)
                end
            end
        end
    end

    return enemies
end

-- ===== MAIN LOOP =====
RunService.Heartbeat:Connect(function()
    if not Enabled then return end

    local char, humanoid, root = getCharacter()

    local closest = nil
    local closestDist = math.huge

    for _, enemy in ipairs(getEnemies()) do
        local eroot = enemy:FindFirstChild("HumanoidRootPart")
        if eroot then
            local dist = (root.Position - eroot.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = eroot
            end
        end
    end

    if closest and closestDist < Distance then
        local dir = (root.Position - closest.Position).Unit
        humanoid:Move(dir)
    end
end)
