-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Player
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

-- ================= STATE =================
local lockEnabled = false
local connection = nil
local currentTarget = nil
local targetMode = "Monster"

local aimHeight = 0
local scanEnabled = false
local scanRange = 100

local scanGui = nil
local scanList = nil
local lastScan = 0
local SCAN_RATE = 0.5

local CAMERA_OFFSET = Vector3.new(0,3,-8)

-- ================= TARGET =================
local function isAlive(model)
    local hum = model and model:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function getTargetPart(model)
    return model:FindFirstChild("HumanoidRootPart")
end

local function getClosestTarget(root)
    local closest = nil
    local shortest = math.huge

    if targetMode == "Player" then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and isAlive(plr.Character) then
                local part = getTargetPart(plr.Character)
                if part then
                    local dist = (part.Position - root.Position).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = plr.Character
                    end
                end
            end
        end
    else
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= root.Parent and isAlive(obj) then
                if not Players:GetPlayerFromCharacter(obj) then
                    local part = getTargetPart(obj)
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = obj
                        end
                    end
                end
            end
        end
    end

    return closest
end

-- ================= LOCK =================
local function startLock()
    camera.CameraType = Enum.CameraType.Scriptable

    connection = RunService.RenderStepped:Connect(function()
        local char = getCharacter()
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if not currentTarget or not isAlive(currentTarget) then
            currentTarget = getClosestTarget(root)
        end

        if not currentTarget then return end

        local part = getTargetPart(currentTarget)
        if not part then return end

        local aimPos = part.Position + Vector3.new(0, aimHeight, 0)

        root.CFrame = CFrame.new(root.Position, aimPos)
        local camPos = root.Position + root.CFrame:VectorToWorldSpace(CAMERA_OFFSET)
        camera.CFrame = CFrame.new(camPos, aimPos)
    end)
end

local function stopLock()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    camera.CameraType = Enum.CameraType.Custom
    currentTarget = nil
end

-- ================= SCAN =================
local function getTargetsInRange(root)
    local list = {}

    if targetMode == "Player" then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and isAlive(plr.Character) then
                local part = getTargetPart(plr.Character)
                if part then
                    local dist = (part.Position - root.Position).Magnitude
                    if dist <= scanRange then
                        table.insert(list, plr.Character)
                    end
                end
            end
        end
    else
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and isAlive(obj) then
                if not Players:GetPlayerFromCharacter(obj) then
                    local part = getTargetPart(obj)
                    if part then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist <= scanRange then
                            table.insert(list, obj)
                        end
                    end
                end
            end
        end
    end

    return list
end

local function getTeamColor(model)
    local plr = Players:GetPlayerFromCharacter(model)
    if plr and plr.Team then
        return plr.TeamColor.Color
    end
    return Color3.fromRGB(255,255,255)
end

local function createScanUI()
    if scanGui then scanGui:Destroy() end

    scanGui = Instance.new("ScreenGui")
    scanGui.Parent = player.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,180,0,220)
    frame.Position = UDim2.new(0.8,0,0.3,0)
    frame.BackgroundColor3 = Color3.fromRGB(245,245,245)
    frame.Parent = scanGui
    Instance.new("UICorner", frame)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0,4)

    scanList = scroll

    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function()
        dragging = false
    end)
end

RunService.RenderStepped:Connect(function()
    if not scanEnabled then return end
    if tick() - lastScan < SCAN_RATE then return end
    lastScan = tick()

    local char = getCharacter()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or not scanList then return end

    scanList:ClearAllChildren()
    local layout = Instance.new("UIListLayout", scanList)
    layout.Padding = UDim.new(0,4)

    local targets = getTargetsInRange(root)

    for _, t in pairs(targets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,28)
        btn.Text = t.Name
        btn.BackgroundColor3 = getTeamColor(t)
        btn.TextColor3 = Color3.new(0,0,0)
        btn.Parent = scanList

        btn.MouseButton1Click:Connect(function()
            currentTarget = t
            if not lockEnabled then
                lockEnabled = true
                startLock()
            end
        end)
    end

    scanList.CanvasSize = UDim2.new(0,0,0,#targets * 30)
end)

-- ================= MODERN UI =================
local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 320)
main.Position = UDim2.new(0.5, -130, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(245,245,245)
main.Parent = gui
Instance.new("UICorner", main)

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,35)
header.BackgroundColor3 = Color3.fromRGB(230,230,230)
header.Parent = main
Instance.new("UICorner", header)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-60,1,0)
title.Position = UDim2.new(0,10,0,0)
title.Text = "PRO LOCK"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(30,30,30)
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,20,0,20)
closeBtn.Position = UDim2.new(1,-25,0.5,-10)
closeBtn.Text = "✕"
closeBtn.Parent = header

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0,20,0,20)
collapseBtn.Position = UDim2.new(1,-50,0.5,-10)
collapseBtn.Text = "-"
collapseBtn.Parent = header

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-40)
content.Position = UDim2.new(0,0,0,40)
content.BackgroundTransparency = 1
content.Parent = main

local layout = Instance.new("UIListLayout", content)
layout.Padding = UDim.new(0,6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- ปุ่มสร้าง
local function btn(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.9,0,0,32)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(40,40,40)
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = content
    Instance.new("UICorner", b)
    return b
end

local lockBtn = btn("Lock: OFF")
local modeBtn = btn("Mode: Monster")
local scanBtn = btn("Scan: OFF")

-- =================== เพิ่ม Input สำหรับ aimHeight ===================
local function createNumberInput(labelText, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9,0,0,32)
    frame.BackgroundTransparency = 0.8
    frame.BackgroundColor3 = Color3.fromRGB(220,220,220)
    frame.Parent = content
    Instance.new("UICorner", frame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5,0,1,0)
    label.Position = UDim2.new(0,0,0,0)
    label.Text = labelText
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(0,0,0)
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5,0,1,0)
    box.Position = UDim2.new(0.5,0,0,0)
    box.Text = tostring(defaultValue)
    box.ClearTextOnFocus = false
    box.TextColor3 = Color3.new(0,0,0)
    box.BackgroundColor3 = Color3.fromRGB(245,245,245)
    box.Parent = frame
    Instance.new("UICorner", box)

    box.FocusLost:Connect(function()
        local value = tonumber(box.Text)
        if value then
            callback(value)
        else
            box.Text = tostring(defaultValue)
        end
    end)
end

-- ปรับ aimHeight
createNumberInput("Aim Height:", aimHeight, function(v) aimHeight = v end)
-- ปรับ scanRange
createNumberInput("Scan Range:", scanRange, function(v) scanRange = v end)

-- ================= ปุ่มหลัก =================
lockBtn.MouseButton1Click:Connect(function()
    lockEnabled = not lockEnabled
    lockBtn.Text = "Lock: "..(lockEnabled and "ON" or "OFF")
    if lockEnabled then startLock() else stopLock() end
end)

modeBtn.MouseButton1Click:Connect(function()
    targetMode = (targetMode=="Monster") and "Player" or "Monster"
    modeBtn.Text = "Mode: "..targetMode
    currentTarget = nil
end)

scanBtn.MouseButton1Click:Connect(function()
    scanEnabled = not scanEnabled
    scanBtn.Text = "Scan: "..(scanEnabled and "ON" or "OFF")
    if scanEnabled then createScanUI()
    elseif scanGui then scanGui:Destroy() end
end)

closeBtn.MouseButton1Click:Connect(function()
    stopLock()
    if scanGui then scanGui:Destroy() end
    gui:Destroy()
end)

local collapsed = false
collapseBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    content.Visible = not collapsed
    main.Size = collapsed and UDim2.new(0,260,0,40) or UDim2.new(0,260,0,320)
end)

-- DRAG
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function()
    dragging = false
end)
