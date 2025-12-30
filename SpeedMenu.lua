--// ANYTHING FLY - EXPERT FULL VERSION (ALL-IN-ONE)
--// LocalScript | Mobile / PC | Stable UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--======================
-- SETTINGS
--======================
local HORIZONTAL_SPEED = 70
local VERTICAL_SPEED = 55
local CAMERA_DEADZONE = 0.12

--======================
-- VARIABLES
--======================
local flying = false
local vehicleModel
local rootPart
local humanoid
local alignOri, linearVel

--======================
-- FIND CONTROLLED MODEL
--======================
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

--======================
-- FLY FUNCTIONS
--======================
local function startFly()
	if flying then return end

	vehicleModel = getControlledModel()
	if not vehicleModel then
		warn("AnythingFly: No model with PrimaryPart found")
		return
	end

	rootPart = vehicleModel.PrimaryPart
	flying = true

	alignOri = Instance.new("AlignOrientation")
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = Instance.new("Attachment", rootPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 20
	alignOri.Parent = rootPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.VectorVelocity = Vector3.zero
	linearVel.Parent = rootPart
end

local function stopFly()
	flying = false
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

--======================
-- UI (FIXED & MOBILE SAFE)
--======================
local gui = Instance.new("ScreenGui")
gui.Name = "AnythingFlyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = game:GetService("CoreGui")

-- Floating toggle button
local uiToggle = Instance.new("TextButton")
uiToggle.Parent = gui
uiToggle.Size = UDim2.fromScale(0.14, 0.07)
uiToggle.Position = UDim2.fromScale(0.02, 0.6)
uiToggle.Text = "FLY UI"
uiToggle.TextScaled = true
uiToggle.Font = Enum.Font.GothamBold
uiToggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
uiToggle.TextColor3 = Color3.new(1,1,1)
uiToggle.ZIndex = 10
Instance.new("UICorner", uiToggle)

-- Main panel
local panel = Instance.new("Frame")
panel.Parent = gui
panel.Size = UDim2.fromScale(0.45, 0.28)
panel.Position = UDim2.fromScale(0.28, 0.35)
panel.BackgroundColor3 = Color3.fromRGB(18,18,18)
panel.Visible = true
panel.Active = true
panel.Draggable = true
panel.ZIndex = 9
Instance.new("UICorner", panel)

local title = Instance.new("TextLabel")
title.Parent = panel
title.Size = UDim2.fromScale(1, 0.3)
title.BackgroundTransparency = 1
title.Text = "✈️ ANYTHING FLY (EXPERT)"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1,1,1)
title.ZIndex = 10

local flyBtn = Instance.new("TextButton")
flyBtn.Parent = panel
flyBtn.Size = UDim2.fromScale(0.8, 0.35)
flyBtn.Position = UDim2.fromScale(0.1, 0.45)
flyBtn.Text = "ANYTHING FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
flyBtn.ZIndex = 10
Instance.new("UICorner", flyBtn)

-- UI Toggle Logic
uiToggle.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

flyBtn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyBtn.Text = "ANYTHING FLY : OFF"
		flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
	else
		startFly()
		if flying then
			flyBtn.Text = "ANYTHING FLY : ON"
			flyBtn.BackgroundColor3 = Color3.fromRGB(60,180,90)
		end
	end
end)

--======================
-- MAIN FLY LOOP (EXPERT)
--======================
RunService.RenderStepped:Connect(function()
	if not flying or not rootPart or not humanoid then return end

	alignOri.CFrame = camera.CFrame

	local moveDir = humanoid.MoveDirection
	local isMoving = moveDir.Magnitude > 0.05

	-- Horizontal movement
	local horizontal = Vector3.new(
		moveDir.X * HORIZONTAL_SPEED,
		0,
		moveDir.Z * HORIZONTAL_SPEED
	)

	-- Vertical movement (joystick required)
	local vertical = 0
	if isMoving then
		local lookY = camera.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

--======================
-- SAFETY RESET
--======================
player.CharacterAdded:Connect(function()
	stopFly()
end)
