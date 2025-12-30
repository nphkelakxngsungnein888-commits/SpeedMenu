--// ANYTHING FLY - FORWARD FACE LOCK (FULL EXPERT)
--// Character faces camera forward always
--// Vehicle stable | Mobile ready | Single LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------
-- SETTINGS
--------------------------------------------------
local SPEED = 60
local VERTICAL_SPEED = 45
local CAMERA_DEADZONE = 0.12

--------------------------------------------------
-- STATE
--------------------------------------------------
local flying = false
local controlPart
local humanoid
local seat

local attachment
local alignOri
local linearVel
local angularVel

--------------------------------------------------
-- GET CONTROL PART
--------------------------------------------------
local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	seat = humanoid.SeatPart
	if seat then
		local model = seat:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

	return char:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------
-- START FLY
--------------------------------------------------
local function startFly()
	if flying then return end

	controlPart = getControlPart()
	if not controlPart then return end
	flying = true

	if humanoid and not seat then
		humanoid.PlatformStand = true
	end

	attachment = Instance.new("Attachment")
	attachment.Parent = controlPart

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = attachment
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.RigidityEnabled = true
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 18
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = attachment
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart

	angularVel = Instance.new("AngularVelocity")
	angularVel.Attachment0 = attachment
	angularVel.MaxTorque = math.huge
	angularVel.AngularVelocity = Vector3.zero
	angularVel.Parent = controlPart
end

--------------------------------------------------
-- STOP FLY
--------------------------------------------------
local function stopFly()
	flying = false
	if humanoid then
		humanoid.PlatformStand = false
	end

	for _,v in ipairs({alignOri, linearVel, angularVel, attachment}) do
		if v then v:Destroy() end
	end
end

--------------------------------------------------
-- CORE LOOP (FORWARD FACE LOCK)
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	-- 🔒 Lock character/vehicle face to camera (Yaw only)
	local camLook = camera.CFrame.LookVector
	local yaw = math.atan2(camLook.X, camLook.Z)
	alignOri.CFrame = CFrame.Angles(0, yaw, 0)

	-- 🛑 Kill all rotation
	controlPart.AssemblyAngularVelocity = Vector3.zero
	angularVel.AngularVelocity = Vector3.zero

	-- Movement (joystick / WASD)
	local moveDir = humanoid.MoveDirection

	local horizontal = Vector3.new(
		moveDir.X * SPEED,
		0,
		moveDir.Z * SPEED
	)

	local vertical = 0
	if moveDir.Magnitude > 0.05 then
		local lookY = camLook.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

--------------------------------------------------
-- UI (SMALL & MOBILE)
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AnythingFlyUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.fromScale(0.12, 0.06)
toggleBtn.Position = UDim2.fromScale(0.02, 0.6)
toggleBtn.Text = "FLY"
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggleBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggleBtn)

toggleBtn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		toggleBtn.Text = "FLY"
	else
		startFly()
		toggleBtn.Text = "STOP"
	end
end)

--------------------------------------------------
-- RESET
--------------------------------------------------
player.CharacterAdded:Connect(stopFly)
