-- /client/auto_avoid.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ================= STATE =================
local state = {
    enabled = false,
    mode = "Players", -- "Players" / "Monsters"
    distance = 20
}

-- ================= UI =================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AutoAvoidUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0.05, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Auto Avoid"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

-- Toggle
local toggle = Instance.new("TextButton", frame)
toggle.Position = UDim2.new(0,10,0,40)
toggle.Size = UDim2.new(0,90,0,30)
toggle.Text = "OFF"

-- Mode
local modeBtn = Instance.new("TextButton", frame)
modeBtn.Position = UDim2.new(0,110,0,40)
modeBtn.Size = UDim2.new(0,100,0,30)
modeBtn.Text = "Players"

-- Distance box
local box = Instance.new("TextBox", frame)
box.Position = UDim2.new(0,10,0,80)
box.Size = UDim2.new(0,200,0,30)
box.PlaceholderText = "Distance"
box.Text = tostring(state.distance)

-- Resize handle
local resize = Instance.new("Frame", frame)
resize.Size = UDim2.new(0,10,0,10)
resize.Position = UDim2.new(1,-10,1,-10)
resize.BackgroundColor3 = Color3.fromRGB(200,200,200)

-- resize logic
local resizing = false
resize.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
    end
end)
resize.InputEnded:Connect(function()
    resizing = false
end)

game:GetService("UserInputService").InputChanged:Connect(function(i)
    if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
        frame.Size = UDim2.new(0, i.Position.X - frame.AbsolutePosition.X, 0, i.Position.Y - frame.AbsolutePosition.Y)
    end
end)

-- UI actions
toggle.MouseButton1Click:Connect(function()
    state.enabled = not state.enabled
    toggle.Text = state.enabled and "ON" or "OFF"
end)

modeBtn.MouseButton1Click:Connect(function()
    state.mode = (state.mode == "Players") and "Monsters" or "Players"
    modeBtn.Text = state.mode
end)

box.FocusLost:Connect(function()
    local val = tonumber(box.Text)
    if val then
        state.distance = val
    end
end)

-- ================= LOGIC =================
local function getCharacter()
    return player.Character
end

local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function isMonster(model)
    return model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model)
end

local function getClosestTarget()
    local char = getCharacter()
    local hrp = getHRP(char)
    if not hrp then return nil end

    local closest, dist = nil, math.huge

    if state.mode == "Players" then
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local tHRP = getHRP(plr.Character)
                if tHRP then
                    local d = (hrp.Position - tHRP.Position).Magnitude
                    if d < dist then
                        dist = d
                        closest = tHRP
                    end
                end
            end
        end
    else
        for _,v in pairs(workspace:GetDescendants()) do
            if isMonster(v) then
                local tHRP = v:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local d = (hrp.Position - tHRP.Position).Magnitude
                    if d < dist then
                        dist = d
                        closest = tHRP
                    end
                end
            end
        end
    end

    return closest, dist
end

-- ================= LOOP =================
RunService.Heartbeat:Connect(function()
    if not state.enabled then return end

    local char = getCharacter()
    local hrp = getHRP(char)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and humanoid) then return end

    local target, dist = getClosestTarget()
    if target and dist < state.distance then
        local direction = (hrp.Position - target.Position).Unit
        local moveTo = hrp.Position + direction * 10

        humanoid:MoveTo(moveTo)

        -- face target while running away
        hrp.CFrame = CFrame.lookAt(hrp.Position, target.Position)
    end
end)
