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

-- RAYCAST PARAM  
local rayParams = RaycastParams.new()  
rayParams.FilterType = Enum.RaycastFilterType.Blacklist  
rayParams.FilterDescendantsInstances = {char}  

-- GET THREATS (FIXED)  
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
        for _,v in pairs(workspace:GetDescendants()) do  
            if v:IsA("Model")  
            and v ~= char  
            and v:FindFirstChild("Humanoid")  
            and v:FindFirstChild("HumanoidRootPart")  
            and not Players:GetPlayerFromCharacter(v)  
            then  
                local hum = v:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local dist = (root.Position - v.HumanoidRootPart.Position).Magnitude  
                    if dist < safeDistance then  
                        table.insert(threats, v)  
                    end  
                end
            end  
        end  
    end  

    return threats  
end  

-- SAFE CHECK  
local function isSafeDirection(dir)  
    local origin = root.Position  

    local forwardRay = workspace:Raycast(origin, dir * 6, rayParams)  
    if forwardRay then return false end  

    local downRay = workspace:Raycast(origin + dir * 4, Vector3.new(0,-10,0), rayParams)  
    if not downRay then return false end  

    return true  
end  

-- MAIN LOOP (UPDATED)
RunService.Heartbeat:Connect(function()  
    if not enabled or not root or not humanoid then return end  

    local threats = getThreats()  
    if #threats == 0 then return end  

    local totalDirection = Vector3.zero  
    local closestTarget = nil  
    local closestDist = math.huge  

    for _,target in pairs(threats) do  
        local tRoot = target:FindFirstChild("HumanoidRootPart")  
        local hum = target:FindFirstChild("Humanoid")

        if tRoot and hum and hum.Health > 0 then  
            local offset = root.Position - tRoot.Position  
            local dist = offset.Magnitude  

            if dist < closestDist then  
                closestDist = dist  
                closestTarget = tRoot  
            end  

            totalDirection += offset.Unit / dist  
        end  
    end  

    if totalDirection.Magnitude > 0 then  
        local baseDir = totalDirection.Unit  
        local moveDir = baseDir  

        if not isSafeDirection(moveDir) then  
            local angles = {30, -30, 60, -60, 90, -90}  
            for _,angle in ipairs(angles) do  
                local rotated = (CFrame.Angles(0, math.rad(angle), 0):VectorToWorldSpace(baseDir))  
                if isSafeDirection(rotated) then  
                    moveDir = rotated  
                    break  
                end  
            end  
        end  

        -- 🔥 ใช้ Velocity แทน MoveTo (แก้แมพรถไฟ)
        local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)

        if flatDir.Magnitude > 0 then  
            root.AssemblyLinearVelocity = flatDir.Unit * 25  
        end  

        -- fallback
        if root.AssemblyLinearVelocity.Magnitude < 1 then  
            humanoid:Move(moveDir, false)  
        end  

        if closestTarget then  
            root.CFrame = CFrame.lookAt(root.Position, closestTarget.Position)  
        end  
    end  
end)
