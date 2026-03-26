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
local STEP = 1.0 -- 🔥 ความเร็วหนี (ปรับได้)

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

local toggle = Instance.new("TextButton", frame)  
toggle.Size = UDim2.new(1, -20, 0, 30)  
toggle.Position = UDim2.new(0,10,0,10)  
toggle.Text = "OFF"  

local modeBtn = Instance.new("TextButton", frame)  
modeBtn.Size = UDim2.new(1, -20, 0, 30)  
modeBtn.Position = UDim2.new(0,10,0,50)  
modeBtn.Text = "Mode: Player"  

local box = Instance.new("TextBox", frame)  
box.Size = UDim2.new(1, -20, 0, 30)  
box.Position = UDim2.new(0,10,0,90)  
box.Text = tostring(safeDistance)  

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

-- MONSTER CACHE  
local monsterCache = {}

task.spawn(function()
    while true do
        task.wait(0.5)
        local newCache = {}
        for _,v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
                local hum = v:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(v) then
                    table.insert(newCache, v)
                end
            end
        end
        monsterCache = newCache
    end
end)

-- GET THREATS  
local function getThreats()  
    local threats = {}  

    if mode == "Player" then  
        for _,p in pairs(Players:GetPlayers()) do  
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then  
                local hum = p.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local dist = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude  
                    if dist < safeDistance then  
                        table.insert(threats, p.Character)  
                    end  
                end
            end  
        end  
    else  
        for _,v in pairs(monsterCache) do
            local dist = (root.Position - v.HumanoidRootPart.Position).Magnitude  
            if dist < safeDistance then  
                table.insert(threats, v)  
            end  
        end  
    end  

    return threats  
end  

-- MAIN LOOP (CFrame evade)
RunService.Heartbeat:Connect(function()  
    if not enabled or not root then return end  

    local threats = getThreats()  
    if #threats == 0 then return end  

    local totalDirection = Vector3.zero  

    for _,target in pairs(threats) do  
        local tRoot = target:FindFirstChild("HumanoidRootPart")  
        local hum = target:FindFirstChild("Humanoid")

        if tRoot and hum and hum.Health > 0 then  
            local offset = root.Position - tRoot.Position  
            local dist = offset.Magnitude  

            if dist > 0.1 then  
                totalDirection += offset.Unit / dist  
            end  
        end  
    end  

    if totalDirection.Magnitude == 0 then return end  

    local moveDir = totalDirection.Unit  

    -- 🔥 เดินหนีด้วย CFrame (ใช้ได้ทุกแมพ)
    root.CFrame = root.CFrame + (moveDir * STEP)

    -- 🔥 หันหน้าหาศัตรูที่ใกล้สุด
    local closest, closestDist = nil, math.huge
    for _,t in pairs(threats) do
        local tr = t:FindFirstChild("HumanoidRootPart")
        if tr then
            local d = (root.Position - tr.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closest = tr
            end
        end
    end

    if closest then
        root.CFrame = CFrame.lookAt(root.Position, closest.Position)
    end  
end)
