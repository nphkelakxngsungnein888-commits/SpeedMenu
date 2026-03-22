local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local target = nil

-- หามอนที่ใกล้ที่สุด
local function getClosestMonster()
    local closest = nil
    local distance = math.huge

    for _, v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= character then
            local dist = (root.Position - v.HumanoidRootPart.Position).Magnitude

            if dist < distance then
                distance = dist
                closest = v
            end
        end
    end

    return closest
end

-- กดปุ่ม E เพื่อล็อคมอน
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        target = getClosestMonster()
    end
end)

-- หันหน้าหามอนที่ล็อคไว้
game:GetService("RunService").RenderStepped:Connect(function()
    if target and target:FindFirstChild("HumanoidRootPart") then
        root.CFrame = CFrame.lookAt(root.Position, target.HumanoidRootPart.Position)
    end
end)
