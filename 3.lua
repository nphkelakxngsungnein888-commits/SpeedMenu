-- Kuy Hub Full Script (Speed + Lock + Chase)

--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// PLAYER
local player = Players.LocalPlayer
local character, humanoid, root
local camera = workspace.CurrentCamera

--// STATE
local speedEnabled = false
local speedMultiplier = 1
local noclip = false

local moveVector = Vector3.zero

-- TARGET
local lockEnabled = false
local lockDistance = 50
local currentTarget = nil
local targets = {}
local targetIndex = 1

-- CHASE
local chaseEnabled = false
local chaseDistance = 5

-- PERFORMANCE
local lastScan = 0
local scanDelay = 0.3

--// SETUP
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	setupCharacter(char)
end)

local function getRoot()
	if character and character.Parent and root then
		return root
	end
	return nil
end

--// NOCLIP
RunService.Stepped:Connect(function()
	if noclip and character then
		for _, v in ipairs(character:GetChildren()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end
end)

-- INPUT
RunService.RenderStepped:Connect(function()
	if humanoid then
		moveVector = humanoid.MoveDirection
	end
end)

-- TARGET SCAN
local function refreshTargets()
	local now = tick()
	if now - lastScan < scanDelay then return end
	lastScan = now

	targets = {}
	local hrp = getRoot()
	if not hrp then return end

	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("Model") and v ~= character then
			local h = v:FindFirstChildOfClass("Humanoid")
			local r = v:FindFirstChild("HumanoidRootPart")
			if h and r and h.Health > 0 then
				local dist = (r.Position - hrp.Position).Magnitude
				if dist <= lockDistance then
					table.insert(targets, r)
				end
			end
		end
	end

	table.sort(targets, function(a,b)
		return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
	end)

	if #targets > 0 then
		targetIndex = math.clamp(targetIndex,1,#targets)
		currentTarget = targets[targetIndex]
	else
		currentTarget = nil
	end
end

-- SWITCH TARGET
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if lockEnabled then
		if input.KeyCode == Enum.KeyCode.Left then
			targetIndex -= 1
			if targetIndex < 1 then targetIndex = #targets end
		elseif input.KeyCode == Enum.KeyCode.Right then
			targetIndex += 1
			if targetIndex > #targets then targetIndex = 1 end
		end
	end
end)

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
	local hrp = getRoot()
	if not hrp or not humanoid then return end

	-- SPEED
	if speedEnabled then
		noclip = true

		local dir = moveVector
		if dir.Magnitude > 0 then
			local baseSpeed = 16
			local finalSpeed = baseSpeed * speedMultiplier

			hrp.CFrame = hrp.CFrame + Vector3.new(
				dir.X * finalSpeed * 0.04,
				0,
				dir.Z * finalSpeed * 0.04
			)
		end

		humanoid.PlatformStand = false
		humanoid.Sit = false
	else
		noclip = false
	end

	-- LOCK + CHASE
	if lockEnabled then
		refreshTargets()

		if currentTarget then
			local targetPos = currentTarget.Position
			local dist = (targetPos - hrp.Position).Magnitude

			hrp.CFrame = CFrame.new(hrp.Position, targetPos)

			camera.CFrame = camera.CFrame:Lerp(
				CFrame.new(camera.CFrame.Position, targetPos),
				0.2
			)

			if chaseEnabled and dist > chaseDistance then
				local dir = (targetPos - hrp.Position).Unit
				hrp.CFrame = hrp.CFrame + Vector3.new(
					dir.X * 1.2,
					0,
					dir.Z * 1.2
				)
			end
		end
	end
end)

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "KuyUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 260)
main.Position = UDim2.new(0.1, 0, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(0,0,0)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(20,20,20)
title.Text = "Kuy Hub"
title.TextColor3 = Color3.fromRGB(255,255,255)

local close = Instance.new("TextButton", main)
close.Size = UDim2.new(0, 25, 0, 25)
close.Position = UDim2.new(1, -25, 0, 0)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255,255,255)
close.BackgroundColor3 = Color3.fromRGB(0,0,0)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local minimize = Instance.new("TextButton", main)
minimize.Size = UDim2.new(0, 25, 0, 25)
minimize.Position = UDim2.new(1, -50, 0, 0)
minimize.Text = "-"
minimize.TextColor3 = Color3.fromRGB(255,255,255)
minimize.BackgroundColor3 = Color3.fromRGB(0,0,0)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, 0, 1, -25)
content.Position = UDim2.new(0,0,0,25)
content.BackgroundTransparency = 1

local visible = true
minimize.MouseButton1Click:Connect(function()
	visible = not visible
	content.Visible = visible
	main.Size = visible and UDim2.new(0,220,0,260) or UDim2.new(0,220,0,25)
end)

-- SPEED UI
local speedBtn = Instance.new("TextButton", content)
speedBtn.Size = UDim2.new(0.6,0,0,30)
speedBtn.Position = UDim2.new(0,5,0,10)
speedBtn.Text = "Speed OFF"
speedBtn.TextColor3 = Color3.new(1,1,1)
speedBtn.BackgroundColor3 = Color3.new(0,0,0)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	speedBtn.Text = speedEnabled and "Speed ON" or "Speed OFF"
end)

local speedBox = Instance.new("TextBox", content)
speedBox.Size = UDim2.new(0.4,0,0,30)
speedBox.Position = UDim2.new(0.6,5,0,10)
speedBox.Text = "1"

speedBox.FocusLost:Connect(function()
	local v = tonumber(speedBox.Text)
	if v and v > 0 then speedMultiplier = v end
end)

-- LOCK UI
local lockBtn = Instance.new("TextButton", content)
lockBtn.Size = UDim2.new(0.6,0,0,30)
lockBtn.Position = UDim2.new(0,5,0,50)
lockBtn.Text = "Lock OFF"
lockBtn.TextColor3 = Color3.new(1,1,1)
lockBtn.BackgroundColor3 = Color3.new(0,0,0)

lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	lockBtn.Text = lockEnabled and "Lock ON" or "Lock OFF"
end)

local distBox = Instance.new("TextBox", content)
distBox.Size = UDim2.new(0.4,0,0,30)
distBox.Position = UDim2.new(0.6,5,0,50)
distBox.Text = "50"

distBox.FocusLost:Connect(function()
	local v = tonumber(distBox.Text)
	if v and v > 0 then lockDistance = v end
end)

-- CHASE UI
local chaseBtn = Instance.new("TextButton", content)
chaseBtn.Size = UDim2.new(0.6,0,0,30)
chaseBtn.Position = UDim2.new(0,5,0,90)
chaseBtn.Text = "Chase OFF"
chaseBtn.TextColor3 = Color3.new(1,1,1)
chaseBtn.BackgroundColor3 = Color3.new(0,0,0)

chaseBtn.MouseButton1Click:Connect(function()
	chaseEnabled = not chaseEnabled
	chaseBtn.Text = chaseEnabled and "Chase ON" or "Chase OFF"
end)

local chaseBox = Instance.new("TextBox", content)
chaseBox.Size = UDim2.new(0.4,0,0,30)
chaseBox.Position = UDim2.new(0.6,5,0,90)
chaseBox.Text = "5"

chaseBox.FocusLost:Connect(function()
	local v = tonumber(chaseBox.Text)
	if v and v > 0 then chaseDistance = v end
end)
