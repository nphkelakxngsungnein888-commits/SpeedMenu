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
local targets = {}
local targetIndex = 1

-- MODE
local targetMode = "Monster"

-- ================= CORE =================

local function isAlive(model)
	local hum = model and model:FindFirstChild("Humanoid")
	return hum and hum.Health > 0
end

local function getTargetPart(model)
	return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
end

-- 🔥 หา target ใกล้กลางจอ
local function getTargetsOnScreen()
	local list = {}
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X/2, viewport.Y/2)

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and isAlive(obj) and obj ~= player.Character then
			local isPlayer = Players:GetPlayerFromCharacter(obj)

			if (targetMode == "Player" and isPlayer) or (targetMode == "Monster" and not isPlayer) then
				local part = getTargetPart(obj)
				if part then
					local pos, visible = camera:WorldToViewportPoint(part.Position)
					if visible then
						local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
						table.insert(list, {model = obj, dist = dist})
					end
				end
			end
		end
	end

	table.sort(list, function(a,b)
		return a.dist < b.dist
	end)

	local result = {}
	for _,v in ipairs(list) do
		table.insert(result, v.model)
	end

	return result
end

-- 🔥 swipe เปลี่ยนเป้า
local lastTouch = nil
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		lastTouch = input.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and lastTouch then
		local delta = input.Position - lastTouch

		if math.abs(delta.X) > 50 then
			if delta.X > 0 then
				targetIndex = math.max(1, targetIndex - 1)
			else
				targetIndex = math.min(#targets, targetIndex + 1)
			end
			lastTouch = input.Position
		end
	end
end)

-- PC click เปลี่ยนเป้า
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		targetIndex = targetIndex + 1
		if targetIndex > #targets then targetIndex = 1 end
	end
end)

-- 🔥 LOCK SYSTEM (แก้สั่นแล้ว)
local function startLock()
	connection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		targets = getTargetsOnScreen()
		if #targets == 0 then return end

		targetIndex = math.clamp(targetIndex, 1, #targets)
		currentTarget = targets[targetIndex]
		if not currentTarget then return end

		local part = getTargetPart(currentTarget)
		if not part then return end

		local aimPos = part.Position

		-- ✅ SMOOTH (แก้สั่น)
		local smooth = 0.15
		local targetCF = CFrame.new(root.Position, Vector3.new(aimPos.X, root.Position.Y, aimPos.Z))
		root.CFrame = root.CFrame:Lerp(targetCF, smooth)

		-- กล้องลื่น ไม่สั่น
		local camTarget = CFrame.new(camera.CFrame.Position, aimPos)
		camera.CFrame = camera.CFrame:Lerp(camTarget, 0.1)
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
gui.Name = "CenterLock"
gui.ResetOnSpawn = false

local success, playerGui = pcall(function() return player:WaitForChild("PlayerGui") end)
gui.Parent = success and playerGui or game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 220)
frame.Position = UDim2.new(0.5, -150, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Parent = gui
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.Text = "🎯 CENTER LOCK"
title.BackgroundColor3 = Color3.fromRGB(35,35,35)
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8,0,0,45)
toggleBtn.Position = UDim2.new(0.1,0,0.3,0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.Parent = frame

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.8,0,0,45)
modeBtn.Position = UDim2.new(0.1,0,0.6,0)
modeBtn.Text = "Mode: Monster"
modeBtn.Parent = frame

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

modeBtn.MouseButton1Click:Connect(function()
	targetMode = (targetMode == "Monster") and "Player" or "Monster"
	targetIndex = 1
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
	if dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function()
	dragging = false
end)
