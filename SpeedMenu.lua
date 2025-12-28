-- SpeedMenu.lua
-- LocalScript สำหรับบินตามตัวละคร

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- UI เปิด/ปิดบิน
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0,100,0,50)
flyButton.Position = UDim2.new(0.5,-50,0.5,-25)
flyButton.Text = "Fly"
flyButton.BackgroundColor3 = Color3.fromRGB(0,170,255)
flyButton.TextColor3 = Color3.fromRGB(255,255,255)
flyButton.Parent = screenGui
flyButton.Active = true
flyButton.Draggable = true

local flying = false
local flySpeed = 50
local velocity

local function startFly()
    if velocity then velocity:Destroy() end
    velocity = Instance.new("BodyVelocity")
    velocity.MaxForce = Vector3.new(1e5,1e5,1e5)
    velocity.Velocity = Vector3.new(0,0,0)
    velocity.Parent = rootPart

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not flying or humanoid.Health <= 0 then
            velocity:Destroy()
            conn:Disconnect()
            flying = false
            return
        end

        -- ตัวละครหันตามกล้อง
        local lookAt = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
        if lookAt.Magnitude > 0 then
            rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
        end

        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            local forward = rootPart.CFrame.LookVector
            local right = rootPart.CFrame.RightVector
            local flyVelocity = (forward * moveDir.Z + right * moveDir.X + Vector3.new(0, moveDir.Y, 0)) * flySpeed
            velocity.Velocity = flyVelocity
        else
            velocity.Velocity = Vector3.new(0,0,0)
        end
    end)
end

flyButton.MouseButton1Click:Connect(function()
    flying = not flying
    if flying then
        flyButton.Text = "Stop"
        startFly()
    else
        flyButton.Text = "Fly"
        if velocity then velocity:Destroy() end
    end
end)

humanoid.Died:Connect(function()
    flying = false
    flyButton.Text = "Fly"
    if velocity then velocity:Destroy() end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.Died:Connect(function()
        flying = false
        flyButton.Text = "Fly"
        if velocity then velocity:Destroy() end
    end)
end)

