--// ANYTHING FLY - EXPERT FULL COMPLETE VERSION
--// Character Face Lock | Vehicle Stable | Camera Free | Mobile Ready

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
local alignOri
local linearVel
local angularVel

--------------------------------------------------
-- GET CONTROL PART (AUTO)
--------------------------------------------------
local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	seat = humanoid.SeatPart

	-- 🚗 Vehicle
	if seat then
		local model = seat:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

	-- 🧍 Character
	return char:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------
-- START / STOP FLY
--------------------------------------------------
local function startFly()
	if flying then return end

	controlPart = getControlPart()
	if not controlPart then return end
	flying = true

	-- Lock physics only when character
	if not seat then
		humanoid.PlatformStand = true
	end

	attachment = Instance.new("Attachment")
	attachment.Parent = controlPart

	-- AlignOrientation (manual control)
	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = attachment
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.RigidityEnabled = true
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 12
	alignOri.Parent = controlPart

	-- LinearVelocity
	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = attachment
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart

	-- AngularVelocity (anti spin)
	angularVel = Instance.new("AngularVelocity")
	angularVel.Attachment0 = attachment
	angularVel.MaxTorque = math.huge
	angularVel.AngularVelocity = Vector3.zero
	angularVel.Parent = controlPart
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end

	for _,v in ipairs({alignOri, linearVel, angularVel, attachment}) do
		if v then v:Destroy() end
	end
end

--------------------------------------------------
-- UI (SMALL & MOBILE)
--------------------------------------------------
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "AnythingFlyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

-- Toggle Button
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.fromScale(0.12, 0.06)
toggleBtn.Position = UDim2.fromScale(0.02, 0.6)
toggleBtn.Text = "FLY"
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggleBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggleBtn)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.36, 0.26)
panel.Position = UDim2.fromScale(0.32, 0.37)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Title
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.fromScale(1, 0.22)
title.BackgroundTransparency = 1
title.Text = "✈️ ANYTHING FLY"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.85, 0.28)
flyBtn.Position = UDim2.fromScale(0.075, 0.3)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- Speed Box
local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.6, 0.2)
speedBox.Position = UDim2.fromScale(0.2, 0.63)
speedBox.Text = tostring(HORIZONTAL_SPEED)
speedBox.PlaceholderText = "Speed"
speedBox.TextScaled = true
speedBox.Font = Enum.Font.Gotham
speedBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

--------------------------------------------------
-- UI LOGIC
--------------------------------------------------
toggleBtn.MouseButton1Click:Connect(function()
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
-- MAIN LOOP (EXPERT CORE)
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart then return end

	local horizontal = Vector3.zero
	local vertical = 0

	-- 🧍 CHARACTER MODE (FACE LOCK)
	if not seat then
		local moveDir = humanoid.MoveDirection
		if moveDir.Magnitude > 0.05 then
			local yaw = math.atan2(moveDir.X, moveDir.Z)
			alignOri.CFrame = CFrame.Angles(0, yaw, 0)

			horizontal = Vector3.new(
				moveDir.X * HORIZONTAL_SPEED,
				0,
				moveDir.Z * HORIZONTAL_SPEED
			)
		end
	else
		-- 🚗 VEHICLE MODE
		local look = camera.CFrame.LookVector
		local yaw = math.atan2(look.X, look.Z)
		alignOri.CFrame = CFrame.Angles(0, yaw, 0)
		horizontal = look * seat.Throttle * HORIZONTAL_SPEED
	end

	-- ⬆️⬇️ Vertical (only when moving)
	if horizontal.Magnitude > 0.1 then
		local lookY = camera.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
	angularVel.AngularVelocity = Vector3.zero
end)

--------------------------------------------------
-- RESET
--------------------------------------------------
player.CharacterAdded:Connect(stopFly)
