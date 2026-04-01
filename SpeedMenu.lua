--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// GUI FIX (สำคัญมาก)
local gui = Instance.new("ScreenGui")
gui.Name = "AimLockGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- รองรับ executor + มือถือ
pcall(function()
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game.CoreGui
    else
        gui.Parent = player:WaitForChild("PlayerGui")
    end
end)

if not gui.Parent then
    gui.Parent = player:WaitForChild("PlayerGui")
end

--// STATE
local lockEnabled = false
local nearestEnabled = true
local lockMode = "Player"
local lockedTarget = nil
local lockConn

local lockStrength = 1
local detectionRange = 500

--// HELPERS
local function getChar()
    local char = player.Character or player.CharacterAdded:Wait()
    return char,
        char:WaitForChild("HumanoidRootPart"),
        char:WaitForChild("Head")
end

local function getRoot(m)
    return m and m:FindFirstChild("HumanoidRootPart")
end

local function isAlive(m)
    local h = m and m:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

--// UI SIMPLE (debug ให้ขึ้นก่อน)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,120)
frame.Position = UDim2.new(0.05,0,0.2,0)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)

local lockBtn = Instance.new("TextButton", frame)
lockBtn.Size = UDim2.new(1,-10,0,30)
lockBtn.Position = UDim2.new(0,5,0,5)
lockBtn.Text = "LOCK OFF"

local modeBtn = Instance.new("TextButton", frame)
modeBtn.Size = UDim2.new(1,-10,0,30)
modeBtn.Position = UDim2.new(0,5,0,40)
modeBtn.Text = "MODE PLAYER"

local nearestBtn = Instance.new("TextButton", frame)
nearestBtn.Size = UDim2.new(1,-10,0,30)
nearestBtn.Position = UDim2.new(0,5,0,75)
nearestBtn.Text = "NEAREST ON"

--// TARGET LIST
local function buildTargets()
    local list = {}
    local char, hrp = getChar()

    if lockMode == "Player" then
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and isAlive(p.Character) then
                local r = getRoot(p.Character)
                if r and (r.Position-hrp.Position).Magnitude <= detectionRange then
                    table.insert(list, p.Character)
                end
            end
        end
    else
        for _,obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model")
            and obj:FindFirstChildOfClass("Humanoid")
            and not Players:GetPlayerFromCharacter(obj)
            and isAlive(obj) then

                local r = getRoot(obj)
                if r and (r.Position-hrp.Position).Magnitude <= detectionRange then
                    table.insert(list, obj)
                end
            end
        end
    end

    return list
end

local function getNearest(list)
    local _, hrp = getChar()
    local best, dist = nil, math.huge

    for _,m in pairs(list) do
        local r = getRoot(m)
        if r then
            local d = (r.Position-hrp.Position).Magnitude
            if d < dist then
                dist = d
                best = m
            end
        end
    end

    return best
end

--// LOCK SYSTEM (แก้กล้อง + ตัวละคร)
local function startLock()
    if lockConn then lockConn:Disconnect() end

    lockConn = RunService.RenderStepped:Connect(function()
        if not lockEnabled then return end

        local char, hrp, head = getChar()

        if not lockedTarget and nearestEnabled then
            lockedTarget = getNearest(buildTargets())
        end

        local root = getRoot(lockedTarget)
        if not root then return end

        -- หมุนตัวละคร
        local flat = (root.Position - hrp.Position) * Vector3.new(1,0,1)
        if flat.Magnitude > 0.1 then
            hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
        end

        -- กล้องธรรมชาติ (ซูมได้)
        camera.CameraType = Enum.CameraType.Custom
        camera.CFrame = CFrame.new(camera.CFrame.Position, root.Position)
    end)
end

local function stopLock()
    if lockConn then lockConn:Disconnect() end
    lockedTarget = nil
end

--// BUTTONS
lockBtn.MouseButton1Click:Connect(function()
    lockEnabled = not lockEnabled
    lockBtn.Text = "LOCK "..(lockEnabled and "ON" or "OFF")

    if lockEnabled then
        startLock()
    else
        stopLock()
    end
end)

modeBtn.MouseButton1Click:Connect(function()
    lockMode = (lockMode=="Player") and "NPC" or "Player"
    modeBtn.Text = "MODE "..lockMode
    lockedTarget = nil
end)

nearestBtn.MouseButton1Click:Connect(function()
    nearestEnabled = not nearestEnabled
    nearestBtn.Text = "NEAREST "..(nearestEnabled and "ON" or "OFF")
end)

--// RESPAWN FIX
player.CharacterAdded:Connect(function()
    task.wait(1)
    if lockEnabled then startLock() end
end)
