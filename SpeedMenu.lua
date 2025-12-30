--// ANYTHING FLY - PRO MAX FINAL
--// Character + Vehicle Fly | Anti-Flip | NoClip | Speed Control
--// LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------
-- SETTINGS (DEFAULT)
--------------------------------------------------
local H_SPEED = 70
local V_SPEED = 55
local CAMERA_DEADZONE = 0.12

--------------------------------------------------
-- STATES
--------------------------------------------------
local flying = false
local noclip = false
local controlPart, humanoid
local alignOri, linearVel
local storedCollisions = {}

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
-- NOCLIP
--------------------------------------------------
local function setNoClip(state)
	if not controlPart then return end
	local model = controlPart:FindFirstAncestorOfClass("Model") or controlPart.Parent

	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			if state then
				storedCollisions[v] = v.CanCollide
				v.CanCollide = false
			else
				if storedCollisions[v] ~= nil then
					v.CanCollide = storedCollisions[v]
				end
			end
		end
	end

	if not state then
		storedCollisions = {}
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
	humanoid.PlatformStand = true

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 25
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart

	if noclip then
		setNoClip(true)
	end
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if noclip then setNoClip(false) end

	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

--------------------------------------------------
-- UI
--------------------------------------------------
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "AnythingFlyUI"
gui.ResetOnSpawn = false

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.5, 0.45)
panel.Position = UDim2.fromScale(0.25, 0.25)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Active, panel.Draggable = true, true
Instance.new("UICorner", panel)

local function makeBtn(text, y)
	local b = Instance.new("TextButton", panel)
	b.Size = UDim2.fromScale(0.85, 0.13)
	b.Position = UDim2.fromScale(0.075, y)
	b.Text = text
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.BackgroundColor3 = Color3.fromRGB(70,70,70)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)
	return b
end

local flyBtn = makeBtn("FLY : OFF", 0.08)
local noclipBtn = makeBtn("NOCLIP : OFF", 0.25)

local function makeBox(placeholder, y)
	local box = Instance.new("TextBox", panel)
	box.Size = UDim2.fromScale(0.85, 0.12)
	box.Position = UDim2.fromScale(0.075, y)
	box.PlaceholderText = placeholder
	box.Text = ""
	box.TextScaled = true
	box.Font = Enum.Font.GothamBold
	box.BackgroundColor3 = Color3.fromRGB(40,40,40)
	box.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", box)
	return box
end

local hBox = makeBox("Horizontal Speed", 0.42)
local vBox = makeBox("Vertical Speed", 0.57)

--------------------------------------------------
-- UI LOGIC
--------------------------------------------------
flyBtn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyBtn.Text = "FLY : OFF"
	else
		startFly()
		if flying then flyBtn.Text = "FLY : ON" end
	end
end)

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.Text = noclip and "NOCLIP : ON" or "NOCLIP : OFF"
	if flying then setNoClip(noclip) end
end)

hBox.FocusLost:Connect(function()
	local n = tonumber(hBox.Text)
	if n then H_SPEED = math.clamp(n, 10, 300) end
end)

vBox.FocusLost:Connect(function()
	local n = tonumber(vBox.Text)
	if n then V_SPEED = math.clamp(n, 10, 300) end
end)

--------------------------------------------------
-- MAIN LOOP (ANTI-FLIP)
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart then return end

	-- Lock Roll / Pitch (Anti-Flip)
	local look = camera.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z).Unit
	alignOri.CFrame = CFrame.lookAt(controlPart.Position, controlPart.Position + flatLook)

	local moveDir = humanoid.MoveDirection
	local moving = moveDir.Magnitude > 0.05

	local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z) * H_SPEED
	local vertical = 0

	if moving then
		local y = camera.CFrame.LookVector.Y
		if math.abs(y) > CAMERA_DEADZONE then
			vertical = y * V_SPEED
		end
	end

	linearVel.VectorVelocity = horizontal + Vector3.new(0, vertical, 0)
end)

--------------------------------------------------
-- CLEANUP ON DEATH
--------------------------------------------------
player.CharacterAdded:Connect(function()
	stopFly()
	gui:Destroy()
end)
