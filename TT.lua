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
local currentTarget = nil

-- ================= AIMBOT =================

local function isEnemy(model)
	if not model:FindFirstChild("Humanoid") then return false end
	if Players:GetPlayerFromCharacter(model) then return false end
	return true
end

-- 🔥 ล็อค "ตัว" เท่านั้น
local function getTargetPart(model)
	return model:FindFirstChild("HumanoidRootPart")
end

local function getBestTarget(root)
	local closest = nil
	local shortest = math.huge

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= root.Parent and isEnemy(obj) then
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

	return closest
end

local function isAlive(model)
	local hum = model and model:FindFirstChild("Humanoid")
	return hum and hum.Health > 0
end

local function startLock()
	connection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		-- 🔥 ถ้าตาย → เปลี่ยนเป้าทันที
		if not currentTarget or not isAlive(currentTarget) then
			currentTarget = getBestTarget(root)
		end

		if not currentTarget then return end

		local part = getTargetPart(currentTarget)
		if not part then return end

		local aimPos = part.Position

		-- 🎯 บังคับหัน + aim ตรงเป้า 100%
		root.CFrame = CFrame.new(root.Position, aimPos)
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

-- ================= MENU =================

local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Parent = gui
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Text = "⚡ PRO LOCK MENU"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame
title.Active = true

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8,0,0,40)
toggleBtn.Position = UDim2.new(0.1,0,0.3,0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
toggleBtn.Parent = frame

local resizeBtn = Instance.new("TextButton")
resizeBtn.Size = UDim2.new(0.8,0,0,40)
resizeBtn.Position = UDim2.new(0.1,0,0.55,0)
resizeBtn.Text = "Resize"
resizeBtn.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.Parent = frame

toggleBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	
	if lockEnabled then
		toggleBtn.Text = "Lock: ON"
		startLock()
	else
		toggleBtn.Text = "Lock: OFF"
		stopLock()
	end
end)

resizeBtn.MouseButton1Click:Connect(function()
	isLarge = not isLarge
	frame.Size = isLarge and UDim2.new(0,300,0,200) or UDim2.new(0,200,0,140)
end)

closeBtn.MouseButton1Click:Connect(function()
	stopLock()
	gui:Destroy()
end)

-- ================= DRAG =================

local dragging = false
local dragInput = nil
local dragStart
local startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		dragInput = input
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		
		dragInput = input
	end
end)

title.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		
		dragging = false
		dragInput = nil
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)d
