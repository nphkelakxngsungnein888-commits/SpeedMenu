--// ANYTHING FLY - EXPERT PRO VERSION
--// Fly Character & Any Vehicle | Mobile Friendly

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// SETTINGS (DEFAULT)
local speed = 70
local VERTICAL_SPEED = 55
local CAMERA_DEADZONE = 0.12

--// STATES
local flying = false
local noclip = false
local controlPart
local humanoid
local alignOri, linearVel

--------------------------------------------------
-- GET CONTROL PART (VEHICLE OR CHARACTER)
--------------------------------------------------
local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoid.SeatPart then
		local seat = humanoid.SeatPart
		local model = seat:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

	return char:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------
-- NOCLIP
--------------------------------------------------
local function setNoClip(state)
	noclip = state
	local char = player.Character
	if not char then return end

	for _,v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = not state
		end
	end
end

--------------------------------------------------
-- START / STOP FLY
--------------------------------------------------
local function startFly()
	if flying then return end

	controlPart = getControlPart()
	if not controlPart then return end

	flying = true
	if humanoid then humanoid.PlatformStand = true end

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 20
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	setNoClip(false)

	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

--------------------------------------------------
-- UI (SMALL & CLEAN)
--------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false
gui.DisplayOrder = 999

-- Toggle UI Button
local uiBtn = Instance.new("TextButton", gui)
uiBtn.Size = UDim2.fromScale(0.12,0.06)
uiBtn.Position = UDim2.fromScale(0.02,0.55)
uiBtn.Text = "FLY"
uiBtn.TextScaled = true
uiBtn.Font = Enum.Font.GothamBold
uiBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
uiBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", uiBtn)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.38,0.32)
panel.Position = UDim2.fromScale(0.31,0.35)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.85,0.25)
flyBtn.Position = UDim2.fromScale(0.075,0.1)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- NoClip Button
local noclipBtn = Instance.new("TextButton", panel)
noclipBtn.Size = UDim2.fromScale(0.85,0.2)
noclipBtn.Position = UDim2.fromScale(0.075,0.4)
noclipBtn.Text = "NOCLIP : OFF"
noclipBtn.TextScaled = true
noclipBtn.Font = Enum.Font.Gotham
noclipBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
noclipBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", noclipBtn)

-- Speed Box
local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.85,0.2)
speedBox.Position = UDim2.fromScale(0.075,0.65)
speedBox.Text = tostring(speed)
speedBox.PlaceholderText = "Speed"
speedBox.TextScaled = true
speedBox.Font = Enum.Font.Gotham
speedBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

--------------------------------------------------
-- UI LOGIC
--------------------------------------------------
uiBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

flyBtn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyBtn.Text = "FLY : OFF"
		flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
	else
		startFly()
		flyBtn.Text = "FLY : ON"
		flyBtn.BackgroundColor3 = Color3.fromRGB(60,180,90)
	end
end)

noclipBtn.MouseButton1Click:Connect(function()
	setNoClip(not noclip)
	noclipBtn.Text = noclip and "NOCLIP : ON" or "NOCLIP : OFF"
	noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(60,180,90) or Color3.fromRGB(70,70,70)
end)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n then speed = math.clamp(n,20,300) end
	speedBox.Text = tostring(speed)
end)

--------------------------------------------------
-- MAIN FLY LOOP (EXPERT CONTROL)
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	alignOri.CFrame = camera.CFrame

	local moveDir = humanoid.MoveDirection
	local isMoving = moveDir.Magnitude > 0.05

	local horizontal = Vector3.new(
		moveDir.X * speed,
		0,
		moveDir.Z * speed
	)

	local vertical = 0
	if isMoving then
		local lookY = camera.CFrame.LookVector.Y
		if math.abs(lookY) > CAMERA_DEADZONE then
			vertical = lookY * VERTICAL_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

--------------------------------------------------
-- RESET
--------------------------------------------------
player.CharacterAdded:Connect(function()
	stopFly()
end)
