--// ANYTHING FLY - EXPERT FULL AUTO VERSION
--// Fly Character OR Any Vehicle Automatically
--// LocalScript | Mobile / PC

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// SETTINGS
local HORIZONTAL_SPEED = 70
local VERTICAL_SPEED = 55
local CAMERA_DEADZONE = 0.12

--// STATES
local flying = false
local controlPart
local humanoid
local alignOri, linearVel

----------------------------------------------------------------
--// GET PART TO CONTROL (VEHICLE OR CHARACTER)
----------------------------------------------------------------
local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Priority 1: Vehicle / Seat
	if humanoid.SeatPart then
		local seat = humanoid.SeatPart
		local model = seat:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

	-- Priority 2: Character
	return char:FindFirstChild("HumanoidRootPart")
end

----------------------------------------------------------------
--// START / STOP FLY
----------------------------------------------------------------
local function startFly()
	if flying then return end

	controlPart = getControlPart()
	if not controlPart then
		warn("AnythingFly: No control part found")
		return
	end

	flying = true

	-- Character safety
	if humanoid then
		humanoid.PlatformStand = true
	end

	-- Orientation
	alignOri = Instance.new("AlignOrientation")
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 20
	alignOri.Parent = controlPart

	-- Velocity
	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.VectorVelocity = Vector3.zero
	linearVel.Parent = controlPart
end

local function stopFly()
	flying = false

	if humanoid then
		humanoid.PlatformStand = false
	end

	if alignOri then alignOri:Destroy() alignOri = nil end
	if linearVel then linearVel:Destroy() linearVel = nil end
end

----------------------------------------------------------------
--// UI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AnythingFlyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = game:GetService("CoreGui")

-- Floating Button
local uiToggle = Instance.new("TextButton", gui)
uiToggle.Size = UDim2.fromScale(0.14, 0.07)
uiToggle.Position = UDim2.fromScale(0.02, 0.6)
uiToggle.Text = "FLY UI"
uiToggle.TextScaled = true
uiToggle.Font = Enum.Font.GothamBold
uiToggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
uiToggle.TextColor3 = Color3.new(1,1,1)
uiToggle.ZIndex = 20
Instance.new("UICorner", uiToggle)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.45, 0.28)
panel.Position = UDim2.fromScale(0.28, 0.35)
panel.BackgroundColor3 = Color3.fromRGB(18,18,18)
panel.Visible = true
panel.Active = true
panel.Draggable = true
panel.ZIndex = 15
Instance.new("UICorner", panel)

-- Title
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.fromScale(1, 0.25)
title.BackgroundTransparency = 1
title.Text = "✈️ ANYTHING FLY"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.ZIndex = 16

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.8, 0.35)
flyBtn.Position = UDim2.fromScale(0.1, 0.45)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
flyBtn.ZIndex = 16
Instance.new("UICorner", flyBtn)

----------------------------------------------------------------
--// UI LOGIC
----------------------------------------------------------------
uiToggle.MouseButton1Click:Connect(function()
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
--// MAIN FLY LOOP (PRO CONTROL)
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	-- Rotate toward camera
	alignOri.CFrame = camera.CFrame

	local moveDir = humanoid.MoveDirection
	local isMoving = moveDir.Magnitude > 0.05

	-- Horizontal
	local horizontal = Vector3.new(
		moveDir.X * HORIZONTAL_SPEED,
		0,
		moveDir.Z * HORIZONTAL_SPEED
	)

	-- Vertical (only when moving)
	local vertical = 0
	if isMoving then
		local lookY = camera.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

----------------------------------------------------------------
--// RESET SAFETY
----------------------------------------------------------------
player.CharacterAdded:Connect(function()
	stopFly()
end)
