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

-- หา Monster ใกล้สุด
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

-- 🔥 MOBILE + PC TAP / CLICK SYSTEM
local function getTappedTarget(screenPos)
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
	if result and result.Instance then
		local part = result.Instance
		local model = part:FindFirstAncestorOfClass("Model")
		if model and Players:GetPlayerFromCharacter(model) then
			if isAlive(model) and model ~= player.Character then
				return model
			end
		end
	end
	return nil
end

-- รองรับมือถือ (Tap)
UserInputService.TouchTap:Connect(function(touches)
	if not lockEnabled or targetMode ~= "Player" then return end
	local pos = touches[1]
	local target = getTappedTarget(pos)
	if target then
		currentTarget = target
	end
end)

-- รองรับ PC (Mouse)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if not lockEnabled or targetMode ~= "Player" then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = input.Position
		local target = getTappedTarget(pos)
		if target then
			currentTarget = target
		end
	end
end)

-- 🔥 LOCK SYSTEM
local function startLock()
	connection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		if targetMode == "Monster" then
			if not currentTarget or not isAlive(currentTarget) then
				currentTarget = getClosestMonster(root)
			end
		else
			if currentTarget and not isAlive(currentTarget) then
				currentTarget = nil
			end
		end

		if not currentTarget then return end

		local part = getTargetPart(currentTarget)
		if not part then return end

		local aimPos = part.Position

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

-- ================= GUI =================

local gui = Instance.new("ScreenGui")
gui.Name = "ProMobileLock"
gui.ResetOnSpawn = false

local success, playerGui = pcall(function() return player:WaitForChild("PlayerGui") end)
if success and playerGui then
	gui.Parent = playerGui
else
	gui.Parent = game:GetService("CoreGui")
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 260)
frame.Position = UDim2.new(0.5, -150, 0.5, -130)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Parent = gui
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Text = "📱 MOBILE LOCK"
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame
Instance.new("UICorner", title)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8,0,0,45)
toggleBtn.Position = UDim2.new(0.1,0,0.3,0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn)

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.8,0,0,45)
modeBtn.Position = UDim2.new(0.1,0,0.55,0)
modeBtn.Text = "Mode: Monster"
modeBtn.Parent = frame
Instance.new("UICorner", modeBtn)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.Parent = frame

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
	currentTarget = nil
	modeBtn.Text = "Mode: " .. targetMode
end)

closeBtn.MouseButton1Click:Connect(function()
	stopLock()
	gui:Destroy()
end)

-- DRAG
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function()
	dragging = false
end)
