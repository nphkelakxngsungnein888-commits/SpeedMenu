--// ANYTHING FLY - EXPERT ANTI SPIN VERSION
--// Stable Vehicle / Character Fly
--// LocalScript | Mobile / PC

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// SETTINGS
local HORIZONTAL_SPEED = 60
local VERTICAL_SPEED = 45
local CAMERA_DEADZONE = 0.12

-- Stability (PRO)
local ORI_RESPONSIVENESS = 12     -- ยิ่งต่ำยิ่งนิ่ง
local ANGULAR_DAMPING = 0.92      -- กันหมุนเอง (0.9 - 0.97 ดีสุด)

--// STATES
local flying = false
local controlPart
local humanoid
local alignOri, linearVel, angularVel
local lastCFrame

----------------------------------------------------------------
--// GET CONTROL PART
----------------------------------------------------------------
local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Vehicle priority
	if humanoid.SeatPart then
		local model = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

	return char:FindFirstChild("HumanoidRootPart")
end

----------------------------------------------------------------
--// START FLY (ANTI ROTATE)
----------------------------------------------------------------
local function startFly()
	if flying then return end

	controlPart = getControlPart()
	if not controlPart then return end
	flying = true

	humanoid.PlatformStand = true

	-- Kill old angular force
	controlPart.AssemblyAngularVelocity = Vector3.zero

	-- Orientation lock
	alignOri = Instance.new("AlignOrientation")
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = ORI_RESPONSIVENESS
	alignOri.Parent = controlPart

	-- Velocity
	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart

	lastCFrame = controlPart.CFrame
end

----------------------------------------------------------------
--// STOP FLY
----------------------------------------------------------------
local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

----------------------------------------------------------------
--// UI (ย่อแล้ว)
----------------------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AnythingFlyUI"
gui.DisplayOrder = 999
gui.ResetOnSpawn = false

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.12,0.06)
toggle.Position = UDim2.fromScale(0.02,0.6)
toggle.Text = "FLY"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.34,0.24)
panel.Position = UDim2.fromScale(0.33,0.38)
panel.Visible = true
panel.Active = true
panel.Draggable = true
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", panel)

local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.85,0.35)
flyBtn.Position = UDim2.fromScale(0.075,0.32)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

toggle.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

flyBtn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyBtn.Text = "FLY : OFF"
		flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
	else
		startFly()
		if flying then
			flyBtn.Text = "FLY : ON"
			flyBtn.BackgroundColor3 = Color3.fromRGB(60,180,90)
		end
	end
end)

----------------------------------------------------------------
--// MAIN LOOP (ANTI SPIN CORE)
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	-- Lock orientation to camera (smooth)
	alignOri.CFrame = camera.CFrame

	-- Angular damping (หัวใจสำคัญ)
	controlPart.AssemblyAngularVelocity *= ANGULAR_DAMPING

	local moveDir = humanoid.MoveDirection
	local moving = moveDir.Magnitude > 0.05

	local horizontal = Vector3.new(
		moveDir.X * HORIZONTAL_SPEED,
		0,
		moveDir.Z * HORIZONTAL_SPEED
	)

	local vertical = 0
	if moving then
		local lookY = camera.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

----------------------------------------------------------------
--// RESET
----------------------------------------------------------------
player.CharacterAdded:Connect(function()
	stopFly()
end)
