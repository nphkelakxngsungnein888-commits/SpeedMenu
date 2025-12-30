--// ANYTHING FLY - EXPERT UI SPEED VERSION
--// Character + Vehicle Fly | Mobile Friendly | LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// SPEED SETTINGS (Dynamic)
local H_SPEED = 60
local V_SPEED = 45
local DEADZONE = 0.12

--// STATE
local flying = false
local humanoid, controlPart
local alignOri, linearVel

--------------------------------------------------
-- GET CONTROL PART
--------------------------------------------------
local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoid.SeatPart then
		local model = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
		if model and model.PrimaryPart then
			return model.PrimaryPart
		end
	end

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

	alignOri = Instance.new("AlignOrientation")
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 18
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

--------------------------------------------------
-- UI
--------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AnythingFlyExpertUI"
gui.ResetOnSpawn = false

-- Toggle Button
local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.12, 0.055)
toggle.Position = UDim2.fromScale(0.02, 0.6)
toggle.Text = "FLY"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.38, 0.24)
panel.Position = UDim2.fromScale(0.31, 0.36)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Title
local title = Instance.new("TextLabel", panel)
title.Size = UDim2.fromScale(1, 0.22)
title.BackgroundTransparency = 1
title.Text = "ANYTHING FLY"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1,1,1)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.8, 0.28)
flyBtn.Position = UDim2.fromScale(0.1, 0.28)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- Speed Label
local speedText = Instance.new("TextLabel", panel)
speedText.Size = UDim2.fromScale(1, 0.15)
speedText.Position = UDim2.fromScale(0, 0.6)
speedText.BackgroundTransparency = 1
speedText.Text = "Speed : 60"
speedText.TextScaled = true
speedText.Font = Enum.Font.Gotham
speedText.TextColor3 = Color3.new(1,1,1)

-- Slider Bar
local bar = Instance.new("Frame", panel)
bar.Size = UDim2.fromScale(0.8, 0.08)
bar.Position = UDim2.fromScale(0.1, 0.78)
bar.BackgroundColor3 = Color3.fromRGB(60,60,60)
Instance.new("UICorner", bar)

local fill = Instance.new("Frame", bar)
fill.Size = UDim2.fromScale(0.5, 1)
fill.BackgroundColor3 = Color3.fromRGB(0,170,255)
Instance.new("UICorner", fill)

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
		flyBtn.Text = "FLY : ON"
		flyBtn.BackgroundColor3 = Color3.fromRGB(60,180,90)
	end
end)

-- Slider Control
local dragging = false
bar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then dragging = true end
end)
bar.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

RunService.RenderStepped:Connect(function()
	if dragging then
		local x = math.clamp(
			(game:GetService("UserInputService"):GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
			0, 1
		)
		fill.Size = UDim2.fromScale(x,1)
		H_SPEED = math.floor(30 + (x * 120))
		V_SPEED = H_SPEED * 0.75
		speedText.Text = "Speed : "..H_SPEED
	end
end)

--------------------------------------------------
-- FLY LOOP
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not humanoid or not controlPart then return end

	alignOri.CFrame = camera.CFrame

	local dir = humanoid.MoveDirection
	local moving = dir.Magnitude > 0.05

	local vel = Vector3.new(dir.X * H_SPEED, 0, dir.Z * H_SPEED)

	if moving then
		local y = camera.CFrame.LookVector.Y
		if math.abs(y) > DEADZONE then
			vel += Vector3.new(0, y * V_SPEED, 0)
		end
	end

	linearVel.VectorVelocity = vel
end)

player.CharacterAdded:Connect(stopFly)
