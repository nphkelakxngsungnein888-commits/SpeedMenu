-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Player
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

-- State
local lockEnabled = false
local connection = nil

-- UI
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 20, 0, 20)
button.Text = "Lock Target: OFF"
button.BackgroundColor3 = Color3.fromRGB(200,50,50)
button.Parent = gui

-- หา NPC ใกล้สุด
local function getClosestNPC(root)
	local closest = nil
	local shortest = math.huge

	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= root.Parent then
			local hrp = obj:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - root.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closest = obj
				end
			end
		end
	end

	return closest
end

-- เริ่มล็อค
local function startLock()
	connection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local target = getClosestNPC(root)
		if not target then return end

		local targetHRP = target:FindFirstChild("HumanoidRootPart")
		if not targetHRP then return end

		-- หมุนตัวละคร
		root.CFrame = CFrame.new(root.Position, targetHRP.Position)

		-- หมุนกล้อง
		camera.CFrame = CFrame.new(camera.CFrame.Position, targetHRP.Position)
	end)
end

-- หยุดล็อค
local function stopLock()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Toggle
button.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	
	if lockEnabled then
		button.Text = "Lock Target: ON"
		button.BackgroundColor3 = Color3.fromRGB(50,200,50)
		startLock()
	else
		button.Text = "Lock Target: OFF"
		button.BackgroundColor3 = Color3.fromRGB(200,50,50)
		stopLock()
	end
end)
