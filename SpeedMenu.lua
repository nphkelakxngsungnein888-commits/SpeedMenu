-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Player & Mouse
local player = Players.LocalPlayer
local mouse = player:GetMouse() -- เพิ่มเมาส์เพื่อใช้เช็คการคลิก
local camera = workspace.CurrentCamera

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

-- State
local lockEnabled = false
local connection = nil
local isLarge = true
local currentTarget = nil

-- MODE
local targetMode = "Monster" -- "Player" / "Monster"

-- ================= AIMBOT LOGIC =================

local function isAlive(model)
    local hum = model and model:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function getTargetPart(model)
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
end

-- ฟังก์ชันหาเป้าหมายอัตโนมัติ (ใช้เฉพาะมอนสเตอร์ หรือตอนเริ่ม)
local function getClosestMonster(root)
    local closest = nil
    local shortest = math.huge

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
    return closest
end

-- ✅ ฟังชั่นคลิกเพื่อเลือก Player
mouse.Button1Down:Connect(function()
    if not lockEnabled or targetMode ~= "Player" then return end
    
    local target = mouse.Target
    if target and target.Parent then
        -- ตรวจสอบว่าเป็นส่วนประกอบของตัวละครผู้เล่นหรือไม่
        local model = target.Parent:IsA("Model") and target.Parent or target.Parent.Parent
        if model:IsA("Model") and Players:GetPlayerFromCharacter(model) then
            if isAlive(model) and model ~= player.Character then
                currentTarget = model
                print("Locked on: " .. model.Name)
            end
        end
    end
end)

-- 🔥 MAIN LOCK SYSTEM
local function startLock()
    connection = RunService.RenderStepped:Connect(function()
        local character = getCharacter()
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if targetMode == "Monster" then
            -- โหมดมอนสเตอร์: หาตัวใกล้สุดอัตโนมัติ
            if not currentTarget or not isAlive(currentTarget) then
                currentTarget = getClosestMonster(root)
            end
        else
            -- โหมดผู้เล่น: รอการคลิก (ถ้าเป้าหมายตายให้ยกเลิก)
            if currentTarget and not isAlive(currentTarget) then
                currentTarget = nil
            end
        end

        if not currentTarget then return end

        local part = getTargetPart(currentTarget)
        if not part then return end

        local aimPos = part.Position
        
        -- หมุนตัวละครและกล้องไปหาเป้าหมาย
        root.CFrame = CFrame.new(root.Position, Vector3.new(aimPos.X, root.Position.Y, aimPos.Z))
        camera.CFrame = CFrame.new(camera.CFrame.Position, aimPos)
    end)
end

local function stopLock()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    currentTarget = nil
end

-- ================= MENU GUI =================

local gui = Instance.new("ScreenGui")
gui.Name = "ProLockGui"
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 280)
frame.Position = UDim2.new(0.5, -150, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Text = "⚡ PRO CLICK LOCK"
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame
Instance.new("UICorner", title)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8,0,0,45)
toggleBtn.Position = UDim2.new(0.1,0,0.25,0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn)

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.8,0,0,45)
modeBtn.Position = UDim2.new(0.1,0,0.45,0)
modeBtn.Text = "Mode: Monster (Auto)"
modeBtn.Parent = frame
Instance.new("UICorner", modeBtn)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.8,0,0,30)
infoLabel.Position = UDim2.new(0.1,0,0.65,0)
infoLabel.Text = "Status: Idle"
infoLabel.TextColor3 = Color3.new(0.8,0.8,0.8)
infoLabel.BackgroundTransparency = 1
infoLabel.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = frame

-- Events
toggleBtn.MouseButton1Click:Connect(function()
    lockEnabled = not lockEnabled
    if lockEnabled then
        toggleBtn.Text = "Lock: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
        startLock()
    else
        toggleBtn.Text = "Lock: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        stopLock()
    end
end)

modeBtn.MouseButton1Click:Connect(function()
    targetMode = (targetMode == "Monster") and "Player" or "Monster"
    currentTarget = nil -- รีเซ็ตเป้าหมายเมื่อเปลี่ยนโหมด
    
    if targetMode == "Player" then
        modeBtn.Text = "Mode: Player (Click Target)"
        infoLabel.Text = "Status: Click a player to lock"
    else
        modeBtn.Text = "Mode: Monster (Auto)"
        infoLabel.Text = "Status: Auto-seeking monsters"
    end
end)

-- อัปเดตสถานะเป้าหมายบน UI
RunService.Heartbeat:Connect(function()
    if lockEnabled then
        if currentTarget then
            infoLabel.Text = "Locked on: " .. currentTarget.Name
        else
            infoLabel.Text = (targetMode == "Player") and "Wait for Click..." or "Searching..."
        end
    else
        infoLabel.Text = "Status: Disabled"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    stopLock()
    gui:Destroy()
end)

-- DRAG SYSTEM (ทำให้เมนูลากได้)
local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
