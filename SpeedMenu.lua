--// ANYTHING FLY - EXPERT VERSION
--// LocalScript | Mobile Friendly | Pro Control

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

--// SETTINGS
local MOVE_SPEED = 70
local VERTICAL_SPEED = 55
local CAMERA_DEADZONE = 0.1

local flying = false
local targetModel
local rootPart

local gyro, velocity

--// Utility
local function getPrimary(model)
	if model:IsA("BasePart") then
		return model
	end
	if model:IsA("Model") then
		if not model.PrimaryPart then
			model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
		end
		return model.PrimaryPart
	end
end

--// Start Fly
local function startFly(model)
	if flying then return end

	targetModel = model
	rootPart = getPrimary(model)
	if not rootPart then return end

	flying = true

	gyro = Instance.new("BodyGyro")
	gyro.P = 120000
	gyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
	gyro.CFrame = rootPart.CFrame
	gyro.Parent = rootPart

	velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(1e9,1e9,1e9)
	velocity.Velocity = Vector3.zero
	velocity.Parent = rootPart
end

--// Stop Fly
local function stopFly()
	flying = false
	if gyro then gyro:Destroy() end
	if velocity then velocity:Destroy() end
	targetModel = nil
	rootPart = nil
end

--// Auto Detect (นั่ง / จับ / เลือก)
local function detectTarget()
	local char = player.Character
	if not char then return end

	-- Priority 1: Seat
	for _,v in pairs(workspace:GetDescendants()) do
		if v:IsA("Seat") and v.Occupant == char:FindFirstChild("Humanoid") then
			return v.Parent
		end
	end

	-- Priority 2: Model touching
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _,p in pairs(hrp:GetTouchingParts()) do
			if p:IsA("BasePart") and p.Parent ~= char then
				return p.Parent
			end
		end
	end
end

--// UI (Minimal Expert)
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.fromScale(0.18,0.07)
btn.Position = UDim2.fromScale(0.02,0.45)
btn.Text = "ANY FLY"
btn.Font = Enum.Font.GothamBold
btn.TextScaled = true
btn.BackgroundColor3 = Color3.fromRGB(0,140,255)
btn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", btn)

btn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
	else
		local target = detectTarget()
		if target then
			startFly(target)
		end
	end
end)

--// Expert Fly Loop
RunService.RenderStepped:Connect(function()
	if not flying or not rootPart then return end

	gyro.CFrame = cam.CFrame

	-- ใช้ MoveDirection ของตัวละคร (รองรับมือถือ)
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local moveDir = humanoid.MoveDirection
	local isMoving = moveDir.Magnitude > 0.05

	local horizontal = Vector3.new(
		moveDir.X * MOVE_SPEED,
		0,
		moveDir.Z * MOVE_SPEED
	)

	local vertical = 0
	if isMoving then
		local lookY = cam.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	velocity.Velocity = horizontal + Vector3.new(0, vertical, 0)
end)
