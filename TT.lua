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

-- State
local lockEnabled = false
local connection = nil
local isLarge = true

-- Settings
local predictionStrength = 0.15

-- ================= AIMBOT =================

local function isEnemy(model)
	if not model:FindFirstChild("Humanoid") then return false end
	if Players:GetPlayerFromCharacter(model) then return false end
	return true
end

local function getTargetPart(model)
	return model:FindFirstChild("Head")
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
end

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

local function startLock()
	connection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local targetPart = getBestTarget(root)
		if not targetPart then return end

		local velocity = targetPart.Velocity
		local predictedPos = targetPart.Position + (velocity * predictionStrength)
		local aimPos = predictedPos + Vector3.new(0, 0.5, 0)

		root.CFrame = CFrame.new(root.Position, aimPos)
		camera.CFrame = CFrame.new(camera.CFrame.Position, aimPos)
	end)
end

local function stopLock()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

-- ================= MENU =================

local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Text = "⚡ PRO LOCK MENU"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8,0,0,40)
toggleBtn.Position = UDim2.new(0.1,0,0.3,0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn)

-- Resize
local resizeBtn = Instance.new("TextButton")
resizeBtn.Size = UDim2.new(0.8,0,0,40)
resizeBtn.Position = UDim2.new(0.1,0,0.55,0)
resizeBtn.Text = "Resize"
resizeBtn.BackgroundColor3 = Color3.fromRGB(50,150,250)
resizeBtn.TextColor3 = Color3.new(1,1,1)
resizeBtn.Parent = frame
Instance.new("UICorner", resizeBtn)

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(255,60,60)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn)

-- Toggle Logic (เชื่อม AIMBOT)
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

-- Resize Logic
resizeBtn.MouseButton1Click:Connect(function()
	isLarge = not isLarge
	frame.Size = isLarge and UDim2.new(0,300,0,200) or UDim2.new(0,200,0,140)
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
	stopLock()
	gui:Destroy()
end)

-- Drag
local dragging, dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)
