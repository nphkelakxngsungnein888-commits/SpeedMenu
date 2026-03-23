-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

-- State
local lockEnabled = false
local connection = nil

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockHeadUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 20, 0, 20)
button.Text = "Lock Head: OFF"
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Parent = screenGui

-- Function: Find NPCs
local function getNPCs()
	local npcs = {}
	for _, model in pairs(workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("Humanoid") and model ~= character then
			table.insert(npcs, model)
		end
	end
	return npcs
end

-- Function: Start Lock
local function startLock()
	connection = RunService.RenderStepped:Connect(function()
		for _, npc in pairs(getNPCs()) do
			local head = npc:FindFirstChild("Head")
			if head then
				head.CFrame = CFrame.new(head.Position, root.Position)
			end
		end
	end)
end

-- Function: Stop Lock
local function stopLock()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Toggle Button
button.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	
	if lockEnabled then
		button.Text = "Lock Head: ON"
		button.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		startLock()
	else
		button.Text = "Lock Head: OFF"
		button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		stopLock()
	end
end)
