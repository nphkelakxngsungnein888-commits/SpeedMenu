--// ANYTHING FLY - EXPERT FULL SCRIPT
--// Character + Vehicle | Stable | Mobile Friendly

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
local alignOri, linearVel

--------------------------------------------------
-- GET CONTROL PART (AUTO)
--------------------------------------------------
local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- ถ้านั่งรถ / ยาน
	if humanoid.SeatPart then
		local model = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

	-- บินตัวละคร
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
	humanoid.PlatformStand = true

	-- Align Orientation (Anti Roll / Anti Spin)
	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.RigidityEnabled = true
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 15
	alignOri.Parent = controlPart

	-- Linear Velocity
	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() alignOri = nil end
	if linearVel then linearVel:Destroy() linearVel = nil end
end

--------------------------------------------------
-- UI (SMALL & CLEAN)
--------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AnythingFlyUI"
gui.DisplayOrder = 999
gui.ResetOnSpawn = false

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
panel.Visible = true
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
-- MAIN LOOP (ANTI ROTATE CORE)
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	-- ล็อกการหมุน (Yaw เท่านั้น)
	local look = camera.CFrame.LookVector
	local yaw = math.atan2(look.X, look.Z)
	alignOri.CFrame = CFrame.new(controlPart.Position) * CFrame.Angles(0, yaw, 0)

	-- ตัดแรงหมุน (กันรถหมุนเอง)
	controlPart.AssemblyAngularVelocity = Vector3.zero

	-- Movement
	local moveDir = humanoid.MoveDirection
	local moving = moveDir.Magnitude > 0.05

	local horizontal = Vector3.new(
		moveDir.X * HORIZONTAL_SPEED,
		0,
		moveDir.Z * HORIZONTAL_SPEED
	)

	local vertical = 0
	if moving then
		if math.abs(look.Y) > CAMERA_DEADZONE then
			vertical = look.Y * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

--------------------------------------------------
-- RESET
--------------------------------------------------
player.CharacterAdded:Connect(stopFly)
