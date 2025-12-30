--// Expert Fly LocalScript
--// By Professional Roblox Script Logic

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Character, Humanoid, RootPart
local Flying = false

-- ปรับค่าตรงนี้
local SPEED = 70
local CONTROL = {
	Forward = 0,
	Backward = 0,
	Left = 0,
	Right = 0,
	Up = 0,
	Down = 0
}

local BV, BG
local Connection

-- ======================= FUNCTIONS =======================

local function SetupCharacter()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character:WaitForChild("HumanoidRootPart")
end

local function StartFly()
	if Flying then return end
	Flying = true

	BV = Instance.new("BodyVelocity")
	BV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	BV.Velocity = Vector3.zero
	BV.Parent = RootPart

	BG = Instance.new("BodyGyro")
	BG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	BG.P = 9000
	BG.CFrame = RootPart.CFrame
	BG.Parent = RootPart

	Humanoid.PlatformStand = true

	Connection = RunService.RenderStepped:Connect(function()
		if not Flying then return end

		local CamCF = Camera.CFrame
		local MoveDir =
			(CamCF.LookVector * (CONTROL.Forward - CONTROL.Backward)) +
			(CamCF.RightVector * (CONTROL.Right - CONTROL.Left)) +
			(Vector3.new(0,1,0) * (CONTROL.Up - CONTROL.Down))

		if MoveDir.Magnitude > 0 then
			BV.Velocity = MoveDir.Unit * SPEED
		else
			BV.Velocity = Vector3.zero
		end

		BG.CFrame = CamCF
	end)
end

local function StopFly()
	Flying = false

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	if BV then BV:Destroy() BV = nil end
	if BG then BG:Destroy() BG = nil end

	if Humanoid then
		Humanoid.PlatformStand = false
	end
end

-- ======================= INPUT =======================

UserInputService.InputBegan:Connect(function(Input, GP)
	if GP then return end

	if Input.KeyCode == Enum.KeyCode.F then
		if Flying then
			StopFly()
		else
			StartFly()
		end
	end

	if Input.KeyCode == Enum.KeyCode.W then CONTROL.Forward = 1 end
	if Input.KeyCode == Enum.KeyCode.S then CONTROL.Backward = 1 end
	if Input.KeyCode == Enum.KeyCode.A then CONTROL.Left = 1 end
	if Input.KeyCode == Enum.KeyCode.D then CONTROL.Right = 1 end
	if Input.KeyCode == Enum.KeyCode.Space then CONTROL.Up = 1 end
	if Input.KeyCode == Enum.KeyCode.LeftControl then CONTROL.Down = 1 end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.W then CONTROL.Forward = 0 end
	if Input.KeyCode == Enum.KeyCode.S then CONTROL.Backward = 0 end
	if Input.KeyCode == Enum.KeyCode.A then CONTROL.Left = 0 end
	if Input.KeyCode == Enum.KeyCode.D then CONTROL.Right = 0 end
	if Input.KeyCode == Enum.KeyCode.Space then CONTROL.Up = 0 end
	if Input.KeyCode == Enum.KeyCode.LeftControl then CONTROL.Down = 0 end
end)

-- ======================= RESPAWN =======================

Player.CharacterAdded:Connect(function()
	task.wait(0.5)
	StopFly()
	SetupCharacter()
end)

SetupCharacter()

print("✅ Expert Fly Loaded | Press F to Fly")
