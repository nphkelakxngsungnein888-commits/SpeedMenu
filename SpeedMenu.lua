--// EXPERT FLY SCRIPT (MOBILE FRIENDLY)
--// LocalScript Only

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character, humanoid, root

local flying = false

-- ปรับค่าตรงนี้ได้
local HORIZONTAL_SPEED = 60
local VERTICAL_SPEED = 50
local CAMERA_DEADZONE = 0.08

local gyro, velocity

--// Load Character
local function loadCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
end
loadCharacter()

player.CharacterAdded:Connect(function()
	flying = false
	task.wait(0.3)
	loadCharacter()
end)

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ExpertFlyUI"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromScale(0.45, 0.3)
main.Position = UDim2.fromScale(0.28, 0.35)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.Active = true
main.Draggable = true
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,20)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.fromScale(1,0.25)
title.BackgroundTransparency = 1
title.Text = "✈️ EXPERT FLY"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local toggle = Instance.new("TextButton", main)
toggle.Position = UDim2.fromScale(0.1,0.35)
toggle.Size = UDim2.fromScale(0.8,0.25)
toggle.Text = "FLY : OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextScaled = true
toggle.BackgroundColor3 = Color3.fromRGB(180,50,50)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

local speedBox = Instance.new("TextBox", main)
speedBox.Position = UDim2.fromScale(0.2,0.68)
speedBox.Size = UDim2.fromScale(0.6,0.2)
speedBox.Text = tostring(HORIZONTAL_SPEED)
speedBox.PlaceholderText = "Speed"
speedBox.Font = Enum.Font.Gotham
speedBox.TextScaled = true
speedBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

--// Fly Functions
local function startFly()
	if flying then return end
	flying = true

	humanoid.PlatformStand = true

	gyro = Instance.new("BodyGyro")
	gyro.P = 100000
	gyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
	gyro.CFrame = root.CFrame
	gyro.Parent = root

	velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(1e9,1e9,1e9)
	velocity.Velocity = Vector3.zero
	velocity.Parent = root
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
		toggle.BackgroundColor3 = Color3.fromRGB(180,50,50)
	else
		startFly()
		toggle.Text = "FLY : ON"
		toggle.BackgroundColor3 = Color3.fromRGB(50,180,80)
	end
end)

speedBox.FocusLost:Connect(function()
	local v = tonumber(speedBox.Text)
	if v then
		HORIZONTAL_SPEED = math.clamp(v,20,300)
	end
	speedBox.Text = tostring(HORIZONTAL_SPEED)
end)

--// Expert Fly Loop
RunService.RenderStepped:Connect(function()
	if not flying or not root then return end

	local cam = workspace.CurrentCamera

	-- หันตัวตามกล้อง
	gyro.CFrame = cam.CFrame

	-- การเคลื่อนที่แนวราบ (จอยมือถือ)
	local moveDir = humanoid.MoveDirection
	local horizontal = Vector3.new(
		moveDir.X * HORIZONTAL_SPEED,
		0,
		moveDir.Z * HORIZONTAL_SPEED
	)

	-- ขึ้นลงตามมุมกล้อง (อัตโนมัติ)
	local lookY = cam.CFrame.LookVector.Y
	local vertical = 0

	if math.abs(lookY) > CAMERA_DEADZONE then
		vertical = lookY * VERTICAL_SPEED
	end

	velocity.Velocity = horizontal + Vector3.new(0, vertical, 0)
end)

--// UI Hide Button
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
