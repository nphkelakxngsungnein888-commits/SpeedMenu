--// ANYTHING FLY - FULL FINAL EXPERT VERSION
--// Character faces CAMERA (not joystick)
--// Vehicle stable | Mobile friendly | UI included

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------
-- SETTINGS
--------------------------------------------------
local HORIZONTAL_SPEED = 60
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
local linearVel
local alignOri
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

	-- Vehicle
	if seat then
		local model = seat:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

	-- Character
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

	attachment = Instance.new("Attachment", controlPart)

	-- 🧍 CHARACTER MODE
	if not seat then
		humanoid.AutoRotate = false

		linearVel = Instance.new("LinearVelocity")
		linearVel.Attachment0 = attachment
		linearVel.MaxForce = math.huge
		linearVel.Parent = controlPart
		return
	end

	-- 🚗 VEHICLE MODE
	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = attachment
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.RigidityEnabled = true
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 10
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
	if humanoid then humanoid.AutoRotate = true end

	for _,v in ipairs({linearVel, alignOri, angularVel, attachment}) do
		if v then v:Destroy() end
	end
end

--------------------------------------------------
-- UI
--------------------------------------------------
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "AnythingFlyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

-- Toggle UI
local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.12, 0.06)
toggle.Position = UDim2.fromScale(0.02, 0.6)
toggle.Text = "FLY"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.32, 0.24)
panel.Position = UDim2.fromScale(0.34, 0.38)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Title
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.fromScale(1, 0.25)
title.BackgroundTransparency = 1
title.Text = "✈ ANYTHING FLY"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1,1,1)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.85, 0.3)
flyBtn.Position = UDim2.fromScale(0.075, 0.28)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- Speed Box
local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.6, 0.22)
speedBox.Position = UDim2.fromScale(0.2, 0.62)
speedBox.Text = tostring(HORIZONTAL_SPEED)
speedBox.TextScaled = true
speedBox.Font = Enum.Font.Gotham
speedBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

--------------------------------------------------
-- UI LOGIC
--------------------------------------------------
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

speedBox.FocusLost:Connect(function()
	local v = tonumber(speedBox.Text)
	if v then
		HORIZONTAL_SPEED = math.clamp(v, 20, 300)
		VERTICAL_SPEED = HORIZONTAL_SPEED * 0.75
	end
	speedBox.Text = tostring(HORIZONTAL_SPEED)
end)

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart then return end

	local look = camera.CFrame.LookVector
	local horizontal = Vector3.zero
	local vertical = 0

	-- 🧍 Character faces camera (LOCK)
	if not seat then
		local yaw = math.atan2(look.X, look.Z)
		controlPart.CFrame =
			CFrame.new(controlPart.Position) *
			CFrame.Angles(0, yaw, 0)
	end

	-- Movement
	if seat then
		local yaw = math.atan2(look.X, look.Z)
		alignOri.CFrame = CFrame.Angles(0, yaw, 0)
		angularVel.AngularVelocity = Vector3.zero
		horizontal = camera.CFrame.LookVector * seat.Throttle * HORIZONTAL_SPEED
	else
		local moveDir = humanoid.MoveDirection
		horizontal = Vector3.new(
			moveDir.X * HORIZONTAL_SPEED,
			0,
			moveDir.Z * HORIZONTAL_SPEED
		)
	end

	-- Vertical
	if horizontal.Magnitude > 0.1 and math.abs(look.Y) > CAMERA_DEADZONE then
		vertical = look.Y * VERTICAL_SPEED
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

--------------------------------------------------
-- RESET
--------------------------------------------------
player.CharacterAdded:Connect(stopFly)
