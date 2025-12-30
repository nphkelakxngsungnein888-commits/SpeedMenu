--// EXPERT FLY SCRIPT (JOYSTICK REQUIRED FOR UP/DOWN)
--// LocalScript | Mobile / PC Friendly

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character, humanoid, root

--// SETTINGS (ปรับได้)
local HORIZONTAL_SPEED = 65
local VERTICAL_SPEED = 55
local CAMERA_DEADZONE = 0.1

local flying = false
local gyro, velocity

--// Character Load
local function loadCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
end
loadCharacter()

player.CharacterAdded:Connect(function()
	flying = false
	task.wait(0.4)
	loadCharacter()
end)

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ExpertFlyUI"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromScale(0.45, 0.3)
main.Position = UDim2.fromScale(0.28, 0.35)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.Active = true
main.Draggable = true
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,20)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.fromScale(1,0.25)
title.BackgroundTransparency = 1
title.Text = "✈️ EXPERT FLY PRO"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local toggle = Instance.new("TextButton", main)
toggle.Position = UDim2.fromScale(0.1,0.35)
toggle.Size = UDim2.fromScale(0.8,0.25)
toggle.Text = "FLY : OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextScaled = true
toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

--// Fly Core
local function startFly()
	if flying then return end
	flying = true
	humanoid.PlatformStand = true

	gyro = Instance.new("BodyGyro", root)
	gyro.P = 120000
	gyro.MaxTorque = Vector3.new(1e9,1e9,1e9)

	velocity = Instance.new("BodyVelocity", root)
	velocity.MaxForce = Vector3.new(1e9,1e9,1e9)
	velocity.Velocity = Vector3.zero
end

local function stopFly()
	flying = false
	humanoid.PlatformStand = false
	if gyro then gyro:Destroy() end
	if velocity then velocity:Destroy() end
end

toggle.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		toggle.Text = "FLY : OFF"
		toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
	else
		startFly()
		toggle.Text = "FLY : ON"
		toggle.BackgroundColor3 = Color3.fromRGB(60,180,90)
	end
end)

--// Expert Fly Loop
RunService.RenderStepped:Connect(function()
	if not flying or not root then return end

	local cam = workspace.CurrentCamera
	gyro.CFrame = cam.CFrame

	local moveDir = humanoid.MoveDirection
	local isMoving = moveDir.Magnitude > 0.05

	-- แนวราบ
	local horizontal = Vector3.new(
		moveDir.X * HORIZONTAL_SPEED,
		0,
		moveDir.Z * HORIZONTAL_SPEED
	)

	-- แนวดิ่ง (ต้องขยับจอยเท่านั้น)
	local vertical = 0
	if isMoving then
		local lookY = cam.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	velocity.Velocity = horizontal + Vector3.new(0, vertical, 0)
end)

--// Hide UI
local hide = Instance.new("TextButton", gui)
hide.Size = UDim2.fromScale(0.12,0.06)
hide.Position = UDim2.fromScale(0.02,0.45)
hide.Text = "FLY"
hide.Font = Enum.Font.GothamBold
hide.TextScaled = true
hide.BackgroundColor3 = Color3.fromRGB(0,120,255)
hide.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", hide)

hide.MouseButton1Click:Connect(function()
	main.Visible = not main.Visible
end)
