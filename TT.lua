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

-- 🔥 เช็คว่าเป็นศัตรู (ไม่ใช่ player)
local function isEnemy(model)
	if not model:FindFirstChild("Humanoid") then
		return false
	end

	-- ถ้าเป็น player → ไม่ใช่ศัตรู
	if Players:GetPlayerFromCharacter(model) then
		return false
	end

	return true
end

-- 🔥 หา part สำหรับเล็ง
local function getTargetPart(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Head")
		or model:FindFirstChild("Torso")
end

-- 🔥 หา target (กลางจอ + ทุกมอน)
local function getBestTarget(root)
	local closestPart = nil
	local shortest = math.huge

	local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= root.Parent and isEnemy(obj) then
			
			local part = getTargetPart(obj)
			if part then
				local screenPos, visible = camera:WorldToViewportPoint(part.Position)

				if visible then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					if dist < shortest then
						shortest = dist
						closestPart = part
					end
				end
			end
		end
	end

	return closestPart
end

-- Start
local function startLock()
	connection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local targetPart = getBestTarget(root)
		if not targetPart then return end

		-- หมุนตัว
		root.CFrame = CFrame.new(root.Position, targetPart.Position)

		-- หมุนกล้อง
		camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
	end)
end

-- Stop
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
