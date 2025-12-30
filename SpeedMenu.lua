--// ANYTHING FLY - PRODUCTION GRADE VERSION
--// Character & Vehicle | Mobile | Multiplayer Safe

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// SPEED
local SPEED = 60
local DEADZONE = 0.12

--// STATE
local flying = false
local humanoid
local controlPart
local alignOri, linearVel
local mode -- "CHAR" | "VEH"

---------------------------------------------------
-- UTIL: FIND CENTER PART OF MODEL
---------------------------------------------------
local function getModelCenter(model)
	local cf, size = model:GetBoundingBox()
	local part = Instance.new("Part")
	part.Size = Vector3.new(2,2,2)
	part.Transparency = 1
	part.Anchored = false
	part.CanCollide = false
	part.CFrame = cf
	part.Name = "_FlyControl"
	part.Parent = model

	local weld = Instance.new("WeldConstraint", part)
	weld.Part0 = part
	weld.Part1 = model:FindFirstChildWhichIsA("BasePart")

	return part
end

---------------------------------------------------
-- GET CONTROL PART
---------------------------------------------------
local function getControl()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoid.SeatPart then
		local seat = humanoid.SeatPart
		local model = seat:FindFirstAncestorOfClass("Model")
		if model then
			mode = "VEH"
			return model.PrimaryPart or getModelCenter(model)
		end
	end

	mode = "CHAR"
	return char:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------
-- START / STOP
---------------------------------------------------
local function startFly()
	if flying then return end

	controlPart = getControl()
	if not controlPart then return end
	flying = true

	-- Character only
	if mode == "CHAR" then
		humanoid.PlatformStand = true
	end

	-- Network Ownership (Vehicle)
	pcall(function()
		controlPart:SetNetworkOwner(player)
	end)

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 20
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart
end

local function stopFly()
	if not flying then return end
	flying = false

	-- Safe stop
	if linearVel then
		linearVel.VectorVelocity *= 0.2
	end

	if humanoid then
		humanoid.PlatformStand = false
	end

	task.delay(0.1, function()
		if alignOri then alignOri:Destroy() end
		if linearVel then linearVel:Destroy() end
	end)
end

---------------------------------------------------
-- UI (Compact)
---------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AnythingFlyProUI"
gui.ResetOnSpawn = false

local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.11,0.05)
toggle.Position = UDim2.fromScale(0.02,0.6)
toggle.Text = "FLY"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.36,0.22)
panel.Position = UDim2.fromScale(0.32,0.38)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.8,0.35)
flyBtn.Position = UDim2.fromScale(0.1,0.1)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

local speedText = Instance.new("TextLabel", panel)
speedText.Size = UDim2.fromScale(1,0.2)
speedText.Position = UDim2.fromScale(0,0.55)
speedText.BackgroundTransparency = 1
speedText.Text = "Speed : 60"
speedText.TextScaled = true
speedText.Font = Enum.Font.Gotham
speedText.TextColor3 = Color3.new(1,1,1)

---------------------------------------------------
-- UI LOGIC
---------------------------------------------------
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

---------------------------------------------------
-- FLY LOOP
---------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not humanoid or not controlPart then return end

	alignOri.CFrame = camera.CFrame

	local dir = humanoid.MoveDirection
	local moving = dir.Magnitude > 0.05

	local vel = Vector3.new(dir.X * SPEED, 0, dir.Z * SPEED)

	if moving then
		local y = camera.CFrame.LookVector.Y
		if math.abs(y) > DEADZONE then
			vel += Vector3.new(0, y * SPEED * 0.75, 0)
		end
	end

	linearVel.VectorVelocity = vel
end)

player.CharacterAdded:Connect(stopFly)
