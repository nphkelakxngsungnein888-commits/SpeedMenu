--// ANYTHING FLY - PRO EXPERT FULL VERSION
--// Character + Vehicle | Mobile | Fly + NoClip Toggle | Speed Multiplier | Mini UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-------------------------------------------------
-- SETTINGS
-------------------------------------------------
local BASE_SPEED = 60
local SPEED_MULT = 1
local flying = false
local noclip = false

local humanoid
local controlPart
local mode -- CHAR / VEH
local alignOri
local linearVel

-------------------------------------------------
-- GET CONTROL PART (CHAR / VEHICLE)
-------------------------------------------------
local function getVehicleControl(model)
	local cf = model:GetBoundingBox()
	local p = Instance.new("Part")
	p.Size = Vector3.new(2,2,2)
	p.Transparency = 1
	p.CanCollide = false
	p.Anchored = false
	p.CFrame = cf
	p.Parent = model
	local weld = Instance.new("WeldConstraint", p)
	weld.Part0 = p
	weld.Part1 = model:FindFirstChildWhichIsA("BasePart")
	return p
end

local function getControlPart()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoid.SeatPart then
		local model = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
		if model then
			mode = "VEH"
			return model.PrimaryPart or getVehicleControl(model)
		end
	end

	mode = "CHAR"
	return char:FindFirstChild("HumanoidRootPart")
end

-------------------------------------------------
-- NOCLIP
-------------------------------------------------
local function setNoClip(state)
	local char = player.Character
	if not char then return end

	for _,v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = not state
		end
	end

	if mode == "VEH" and controlPart then
		local model = controlPart:FindFirstAncestorOfClass("Model")
		if model then
			for _,v in ipairs(model:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = not state
				end
			end
		end
	end
end

-------------------------------------------------
-- START / STOP FLY
-------------------------------------------------
local function startFly()
	if flying then return end
	controlPart = getControlPart()
	if not controlPart then return end

	flying = true
	if mode == "CHAR" then
		humanoid.PlatformStand = true
	end

	pcall(function()
		controlPart:SetNetworkOwner(player)
	end)

	alignOri = Instance.new("AlignOrientation", controlPart)
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 25

	linearVel = Instance.new("LinearVelocity", controlPart)
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
end

local function stopFly()
	if not flying then return end
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

-------------------------------------------------
-- UI (MINI / MOBILE)
-------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

-- UI Toggle
local uiBtn = Instance.new("TextButton", gui)
uiBtn.Size = UDim2.fromScale(0.09,0.045)
uiBtn.Position = UDim2.fromScale(0.02,0.6)
uiBtn.Text = "MENU"
uiBtn.TextScaled = true
uiBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
uiBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", uiBtn)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.28,0.28)
panel.Position = UDim2.fromScale(0.35,0.33)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.85,0.18)
flyBtn.Position = UDim2.fromScale(0.075,0.05)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.BackgroundColor3 = Color3.fromRGB(170,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- NoClip Button
local noclipBtn = Instance.new("TextButton", panel)
noclipBtn.Size = UDim2.fromScale(0.85,0.18)
noclipBtn.Position = UDim2.fromScale(0.075,0.28)
noclipBtn.Text = "NOCLIP : OFF"
noclipBtn.TextScaled = true
noclipBtn.BackgroundColor3 = Color3.fromRGB(180,180,60)
noclipBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", noclipBtn)

-- Speed Box
local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.85,0.18)
speedBox.Position = UDim2.fromScale(0.075,0.55)
speedBox.PlaceholderText = "Speed Multiplier (ex: 2)"
speedBox.Text = "1"
speedBox.TextScaled = true
speedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

-------------------------------------------------
-- UI LOGIC
-------------------------------------------------
uiBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

flyBtn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyBtn.Text = "FLY : OFF"
		flyBtn.BackgroundColor3 = Color3.fromRGB(170,60,60)
	else
		startFly()
		flyBtn.Text = "FLY : ON"
		flyBtn.BackgroundColor3 = Color3.fromRGB(60,170,90)
	end
end)

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.Text = noclip and "NOCLIP : ON" or "NOCLIP : OFF"
	setNoClip(noclip)
end)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n and n > 0 then
		SPEED_MULT = n
	else
		speedBox.Text = tostring(SPEED_MULT)
	end
end)

-------------------------------------------------
-- FLY LOOP (JOYSTICK BASED UP/DOWN)
-------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	alignOri.CFrame = camera.CFrame

	local move = humanoid.MoveDirection
	local vel = Vector3.new(
		move.X * BASE_SPEED * SPEED_MULT,
		move.Y * BASE_SPEED * SPEED_MULT,
		move.Z * BASE_SPEED * SPEED_MULT
	)

	linearVel.VectorVelocity = vel
end)
