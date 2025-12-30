--// ANYTHING FLY - MASTER FULL VERSION
--// PURE CFrame | NO PHYSICS | CHARACTER + VEHICLE
--// Mobile / PC | Expert Level

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

	-- ตัวละคร
	return char:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------
-- START / STOP
--------------------------------------------------
local function startFly()
	if flying then return end

	controlPart = getControlPart()
	if not controlPart then return end

	flying = true
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	-- ตัดแรงทั้งหมด
	controlPart.AssemblyLinearVelocity = Vector3.zero
	controlPart.AssemblyAngularVelocity = Vector3.zero
end

local function stopFly()
	flying = false
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
	end
end

--------------------------------------------------
-- UI (SMALL & CLEAN)
--------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
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
panel.Size = UDim2.fromScale(0.34, 0.24)
panel.Position = UDim2.fromScale(0.33, 0.38)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = true
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Title
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.fromScale(1, 0.25)
title.BackgroundTransparency = 1
title.Text = "✈️ ANYTHING FLY"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.85, 0.3)
flyBtn.Position = UDim2.fromScale(0.075, 0.32)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- Speed Box
local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.6, 0.2)
speedBox.Position = UDim2.fromScale(0.2, 0.67)
speedBox.Text = tostring(SPEED)
speedBox.PlaceholderText = "Speed"
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
		SPEED = math.clamp(v, 20, 300)
		VERTICAL_SPEED = SPEED * 0.75
	end
	speedBox.Text = tostring(SPEED)
end)

--------------------------------------------------
-- MAIN LOOP (PURE CFRAME CONTROL)
--------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	if not flying or not controlPart or not humanoid then return end

	-- หันตามกล้อง (Yaw เท่านั้น)
	local look = camera.CFrame.LookVector
	local yaw = math.atan2(look.X, look.Z)

	local baseCF = CFrame.new(controlPart.Position) * CFrame.Angles(0, yaw, 0)

	-- Input จากจอย
	local moveDir = humanoid.MoveDirection
	local moving = moveDir.Magnitude > 0.05

	local moveVec = Vector3.zero
	if moving then
		moveVec =
			(baseCF.RightVector * moveDir.X * SPEED) +
			(baseCF.LookVector * moveDir.Z * SPEED)

		-- ขึ้นลง (เฉพาะตอนดันจอย)
		if math.abs(look.Y) > CAMERA_DEADZONE then
			moveVec += Vector3.new(0, look.Y * VERTICAL_SPEED, 0)
		end
	end

	controlPart.CFrame = baseCF + moveVec * dt
end)

--------------------------------------------------
-- RESET
--------------------------------------------------
player.CharacterAdded:Connect(stopFly)
