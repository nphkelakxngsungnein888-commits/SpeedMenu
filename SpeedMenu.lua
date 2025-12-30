--// ANYTHING FLY - EXPERT FULL VERSION
--// LocalScript | Mobile / PC | Pro Physics

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// SETTINGS (ปรับได้)
local HORIZONTAL_SPEED = 70
local VERTICAL_SPEED = 55
local CAMERA_DEADZONE = 0.12

local flying = false
local vehicleModel
local rootPart
local humanoid

local alignOri, linearVel

--// หา Model ที่ผู้เล่นกำลังใช้งาน (Seat / Weld)
local function getControlledModel()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.SeatPart then return end

	local seat = humanoid.SeatPart
	local model = seat:FindFirstAncestorOfClass("Model")

	if model and model.PrimaryPart then
		return model
	end
end

--// Start Fly
local function startFly()
	if flying then return end

	vehicleModel = getControlledModel()
	if not vehicleModel then
		warn("No controllable model found")
		return
	end

	rootPart = vehicleModel.PrimaryPart
	flying = true

	-- Orientation
	alignOri = Instance.new("AlignOrientation")
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = Instance.new("Attachment", rootPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 20
	alignOri.Parent = rootPart

	-- Velocity
	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.VectorVelocity = Vector3.zero
	linearVel.Parent = rootPart
end

--// Stop Fly
local function stopFly()
	flying = false
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

--// UI (เรียบ แต่ใช้งานจริง)
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false
gui.Name = "AnythingFlyUI"

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.22,0.08)
toggle.Position = UDim2.fromScale(0.39,0.85)
toggle.Text = "ANYTHING FLY : OFF"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

toggle.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		toggle.Text = "ANYTHING FLY : OFF"
		toggle.BackgroundColor3 = Color3.fromRGB(180,60,60)
	else
		startFly()
		if flying then
			toggle.Text = "ANYTHING FLY : ON"
			toggle.BackgroundColor3 = Color3.fromRGB(60,180,90)
		end
	end
end)

--// Main Fly Loop (EXPERT LOGIC)
RunService.RenderStepped:Connect(function()
	if not flying or not rootPart or not humanoid then return end

	-- หมุนตามกล้อง
	alignOri.CFrame = camera.CFrame

	local moveDir = humanoid.MoveDirection
	local isMoving = moveDir.Magnitude > 0.05

	-- แนวราบ
	local horizontal = Vector3.new(
		moveDir.X * HORIZONTAL_SPEED,
		0,
		moveDir.Z * HORIZONTAL_SPEED
	)

	-- แนวดิ่ง (ต้องขยับจอย)
	local vertical = 0
	if isMoving then
		local lookY = camera.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

--// Safety Reset
player.CharacterAdded:Connect(function()
	stopFly()
end)
