--// ANYTHING FLY - PRO MAX FULL VERSION
--// Character + Vehicle | Mobile | NoClip Always | Speed Input | Mini UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- SETTINGS
local BASE_SPEED = 60
local SPEED_MULT = 1
local DEADZONE = 0.12
local flying = false
local noclip = false -- start off
local humanoid, controlPart, mode
local alignOri, linearVel

---------------------------------------------------
-- UTIL: GET CONTROL PART
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

local function getControl()
	local char = player.Character
	if not char then return end
	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if humanoid.SeatPart then
		local model = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
		if model then
			mode = "VEH"
			return model.PrimaryPart or getModelCenter(model)
		end
	end
	mode = "CHAR"
	return char:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------
-- NOCLIP
---------------------------------------------------
local function applyNoClip(state)
	if not player.Character then return end
	for _, part in pairs(player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not state
		end
	end
	if mode == "VEH" and controlPart then
		local model = controlPart:FindFirstAncestorOfClass("Model")
		if model then
			for _, p in pairs(model:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CanCollide = not not state
				end
			end
		end
	end
end

---------------------------------------------------
-- START / STOP FLY
---------------------------------------------------
local function startFly()
	if flying then return end
	controlPart = getControl()
	if not controlPart then return end
	flying = true

	if mode == "CHAR" then
		humanoid.PlatformStand = true
	end

	pcall(function()
		controlPart:SetNetworkOwner(player)
	end)

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 22
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart

	if noclip then applyNoClip(true) end
end

local function stopFly()
	if not flying then return end
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

---------------------------------------------------
-- UI MINI
---------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "FlyProMaxFullUI"
gui.ResetOnSpawn = false

-- Toggle Panel Button
local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.09,0.045)
toggle.Position = UDim2.fromScale(0.02,0.62)
toggle.Text = "UI"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.28,0.26)
panel.Position = UDim2.fromScale(0.35,0.34)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.8,0.2)
flyBtn.Position = UDim2.fromScale(0.1,0.05)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- NoClip Button
local noclipBtn = Instance.new("TextButton", panel)
noclipBtn.Size = UDim2.fromScale(0.8,0.18)
noclipBtn.Position = UDim2.fromScale(0.1,0.35)
noclipBtn.Text = "NoClip : OFF"
noclipBtn.TextScaled = true
noclipBtn.Font = Enum.Font.GothamBold
noclipBtn.BackgroundColor3 = Color3.fromRGB(180,180,60)
noclipBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", noclipBtn)

-- Speed Input
local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.8,0.18)
speedBox.Position = UDim2.fromScale(0.1,0.63)
speedBox.PlaceholderText = "Speed Multiplier (e.g., 2)"
speedBox.Text = tostring(SPEED_MULT)
speedBox.TextScaled = true
speedBox.Font = Enum.Font.Gotham
speedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

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

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.Text = noclip and "NoClip : ON" or "NoClip : OFF"
	applyNoClip(noclip)
end)

speedBox.FocusLost:Connect(function()
	local val = tonumber(speedBox.Text)
	if val and val > 0 then
		SPEED_MULT = val
		speedBox.Text = tostring(val)
	else
		speedBox.Text = tostring(SPEED_MULT)
	end
end)

---------------------------------------------------
-- FLY LOOP
---------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not controlPart or not humanoid then return end
	if flying then
		alignOri.CFrame = camera.CFrame
		local dir = humanoid.MoveDirection
		local moving = dir.Magnitude > 0.05
		local vel = Vector3.new(dir.X*BASE_SPEED*SPEED_MULT,0,dir.Z*BASE_SPEED*SPEED_MULT)
		if moving then
			local y = camera.CFrame.LookVector.Y
			if math.abs(y) > DEADZONE then
				vel += Vector3.new(0,y*BASE_SPEED*0.75*SPEED_MULT,0)
			end
		end
		if linearVel then
			linearVel.VectorVelocity = vel
		end
	end
end)
