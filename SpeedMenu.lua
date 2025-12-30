--====================================================
-- ANYTHING FLY - SMART SYSTEM FULL VERSION (MASTER)
-- Mobile / PC | LocalScript
--====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

----------------------------------------------------
-- STATE
----------------------------------------------------
local flying = false
local humanoid
local targetModel
local controlPart
local centerPart
local alignOri
local linearVel

----------------------------------------------------
-- SMART SETTINGS
----------------------------------------------------
local BASE_SPEED = 60
local speedMultiplier = 1

----------------------------------------------------
-- 1) SMART TARGET DETECTION
----------------------------------------------------
local function getTarget()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoid.SeatPart then
		return humanoid.SeatPart:FindFirstAncestorOfClass("Model")
	end

	return char
end

----------------------------------------------------
-- 2) DYNAMIC MASS CALCULATION
----------------------------------------------------
local function calculateMass(model)
	local mass = 0
	for _,v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			mass += v:GetMass()
		end
	end
	return math.max(mass, 1)
end

----------------------------------------------------
-- 4) SMART CENTER OF MASS
----------------------------------------------------
local function createCenter(model)
	local cf = model:GetBoundingBox()

	centerPart = Instance.new("Part")
	centerPart.Size = Vector3.new(1,1,1)
	centerPart.Transparency = 1
	centerPart.CanCollide = false
	centerPart.Massless = true
	centerPart.CFrame = cf
	centerPart.Parent = model

	for _,v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") and v ~= centerPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = centerPart
			weld.Part1 = v
			weld.Parent = centerPart
		end
	end

	model.PrimaryPart = centerPart
	return centerPart
end

----------------------------------------------------
-- START / STOP FLY
----------------------------------------------------
local function startFly()
	if flying then return end

	targetModel = getTarget()
	if not targetModel then return end

	if targetModel:IsA("Model") then
		controlPart = createCenter(targetModel)
	else
		controlPart = targetModel:FindFirstChild("HumanoidRootPart")
	end
	if not controlPart then return end

	flying = true
	humanoid.PlatformStand = true

	-- 3) ADAPTIVE RESPONSIVENESS
	local mass = calculateMass(targetModel)
	local responsiveness = math.clamp(20 - math.log(mass), 6, 20)

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Responsiveness = responsiveness
	alignOri.MaxTorque = math.huge
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	linearVel.MaxForce = mass * 130
	linearVel.Parent = controlPart
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
	if centerPart then centerPart:Destroy() centerPart = nil end
end

----------------------------------------------------
-- 6) SMART DEADZONE
----------------------------------------------------
local function getDeadzone(speed)
	return math.clamp(0.16 - (speed / 500), 0.05, 0.16)
end

----------------------------------------------------
-- MAIN LOOP (SMART CONTROL)
----------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	alignOri.CFrame = camera.CFrame

	local moveDir = humanoid.MoveDirection
	local moving = moveDir.Magnitude > 0.05
	local speed = BASE_SPEED * speedMultiplier

	-- Horizontal
	local horizontal = Vector3.new(
		moveDir.X * speed,
		0,
		moveDir.Z * speed
	)

	-- 5) VELOCITY DAMPENING
	local damping = controlPart.AssemblyLinearVelocity * 0.15

	-- Vertical
	local vertical = 0
	if moving then
		local dz = getDeadzone(speed)
		local lookY = camera.CFrame.LookVector.Y
		if math.abs(lookY) > dz then
			vertical = lookY * speed * 0.75
		end
	end

	-- 7) AUTO STABILIZER
	if not moving then
		linearVel.VectorVelocity = damping
	else
		linearVel.VectorVelocity =
			horizontal + Vector3.new(0, vertical, 0) - damping
	end
end)

----------------------------------------------------
-- UI (SMALL / MOBILE)
----------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.12,0.06)
toggle.Position = UDim2.fromScale(0.02,0.6)
toggle.Text = "FLY"
toggle.TextScaled = true
toggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.32,0.22)
panel.Position = UDim2.fromScale(0.34,0.38)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.9,0.35)
flyBtn.Position = UDim2.fromScale(0.05,0.15)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.7,0.25)
speedBox.Position = UDim2.fromScale(0.15,0.6)
speedBox.Text = tostring(BASE_SPEED)
speedBox.TextScaled = true
speedBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

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
		BASE_SPEED = math.clamp(v,20,300)
	end
	speedBox.Text = tostring(BASE_SPEED)
end)

----------------------------------------------------
-- RESET
----------------------------------------------------
player.CharacterAdded:Connect(stopFly)----------------------------------------------------------------
--// RESET
----------------------------------------------------------------
player.CharacterAdded:Connect(function()
	stopFly()
end)
