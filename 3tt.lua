-- /client/auto_evade.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- CONFIG
local state = {
    enabled = false,
    distance = 20,
    mode = "Players" -- "Players" | "Monsters"
}

-- UI SETUP
local gui = Instance.new("ScreenGui")
gui.Name = "EvadeUI"
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 140)
frame.Position = UDim2.new(0.1, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Parent = gui
frame.Active = true
frame.Draggable = true

-- toggle
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 30)
toggle.Position = UDim2.new(0, 10, 0, 10)
toggle.Text = "OFF"
toggle.Parent = frame

-- distance input
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 25)
box.Position = UDim2.new(0, 10, 0, 50)
box.PlaceholderText = "Distance"
box.Text = tostring(state.distance)
box.Parent = frame

-- mode switch
local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(1, -20, 0, 25)
modeBtn.Position = UDim2.new(0, 10, 0, 80)
modeBtn.Text = "Mode: Players"
modeBtn.Parent = frame

-- close
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 25, 0, 25)
close.Position = UDim2.new(1, -30, 0, 5)
close.Text = "X"
close.Parent = frame

-- resize handle
local resize = Instance.new("Frame")
resize.Size = UDim2.new(0, 15, 0, 15)
resize.Position = UDim2.new(1, -15, 1, -15)
resize.BackgroundColor3 = Color3.fromRGB(80,80,80)
resize.Parent = frame

-- UI EVENTS
toggle.MouseButton1Click:Connect(function()
    state.enabled = not state.enabled
    toggle.Text = state.enabled and "ON" or "OFF"
end)

modeBtn.MouseButton1Click:Connect(function()
    state.mode = (state.mode == "Players") and "Monsters" or "Players"
    modeBtn.Text = "Mode: " .. state.mode
end)

box.FocusLost:Connect(function()
    local num = tonumber(box.Text)
    if num then
        state.distance = num
    end
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- resize logic
local resizing = false
resize.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
    end
end)

UIS.InputChanged:Connect(function(i)
    if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
        frame.Size = UDim2.new(0, i.Position.X - frame.AbsolutePosition.X, 0, i.Position.Y - frame.AbsolutePosition.Y)
    end
end)

-- CORE LOGIC
local function getCharacter()
    return player.Character
end

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getTargets()
    local targets = {}

    if state.mode == "Players" then
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                table.insert(targets, p.Character)
            end
        end
    else
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Humanoid") then
                table.insert(targets, v)
            end
        end
    end

    return targets
end

RunService.Heartbeat:Connect(function()
    if not state.enabled then return end

    local char = getCharacter()
    local root = getRoot(char)
    if not root then return end

    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    for _,target in pairs(getTargets()) do
        local tRoot = getRoot(target)
        if tRoot then
            local dist = (root.Position - tRoot.Position).Magnitude

            if dist < state.distance then
                local dir = (root.Position - tRoot.Position).Unit
                local movePos = root.Position + dir * state.distance

                humanoid:MoveTo(movePos)
                break
            end
        end
    end
end)
