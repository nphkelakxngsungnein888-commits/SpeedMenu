--[[ 
 HOVER FLY PRO FULL VERSION
 Character + Vehicle + Boat
 Stable Hover | NoClip Toggle | Mobile UI
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

------------------------------------------------
-- CONFIG
------------------------------------------------
local BASE_SPEED = 60
local SPEED_MULT = 1
local DEADZONE = 0.12

local flying = false
local noclip = false
local hoverHeight = nil

local humanoid
local controlPart
local mode

local alignOri
local linearVel

------------------------------------------------
-- GET CONTROL PART
------------------------------------------------
local function getModelCenter(model)
	local cf = model:GetBoundingBox()
	local part = Instance.new("Part")
	part.Size = Vector3.new(2,2,2)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = false
	part.CFrame = cf
	part.Name = "_FlyControl"
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = model:FindFirstChildWhichIsA("BasePart")
	weld.Parent = part

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
			mode = "VEHICLE"
			return model.PrimaryPart or getModelCenter(model)
		end
	end

	mode = "CHAR"
	return char:FindFirstChild("HumanoidRootPart")
end

------------------------------------------------
-- NOCLIP
------------------------------------------------
local function applyNoClip(state)
	if player.Character then
		for _,v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = not state
			end
		end
	end

	if mode == "VEHICLE" and controlPart then
		local model = controlPart:FindFirstAncestorOfClass("Model")
		if model then
			for _,v in pairs(model:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = not state
				end
			end
		end
	end
end

------------------------------------------------
-- START / STOP FLY
------------------------------------------------
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

	hoverHeight = controlPart.Position.Y

	-- ลดผลกระทบน้ำ + ทำให้ลอยนิ่ง
	local model = controlPart:FindFirstAncestorOfClass("Model")
	if model then
		for _,v in pairs(model:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.CustomPhysicalProperties = PhysicalProperties.new(
					0.05, -- density ต่ำ = น้ำไม่ดัน
					0,
					0
				)
			end
		end
	end

	local att = Instance.new("Attachment", controlPart)

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = att
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 25
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = att
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart
end

local function stopFly()
	if not flying then return end
	flying = false

	if humanoid then
		humanoid.PlatformStand = false
	end

	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

------------------------------------------------
-- UI (MINI - MOBILE)
------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local menuBtn = Instance.new("TextButton", gui)
menuBtn.Size = UDim2.fromScale(0.09,0.045)
menuBtn.Position = UDim2.fromScale(0.02,0.6)
menuBtn.Text = "MENU"
menuBtn.TextScaled = true
menuBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
menuBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", menuBtn)

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.28,0.25)
panel.Position = UDim2.fromScale(0.36,0.35)
panel.Visible = false
panel.Active = true
panel.Draggable = true
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", panel)

local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.8,0.2)
flyBtn.Position = UDim2.fromScale(0.1,0.05)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

local noclipBtn = Instance.new("TextButton", panel)
noclipBtn.Size = UDim2.fromScale(0.8,0.18)
noclipBtn.Position = UDim2.fromScale(0.1,0.32)
noclipBtn.Text = "NOCLIP : OFF"
noclipBtn.TextScaled = true
noclipBtn.BackgroundColor3 = Color3.fromRGB(180,180,60)
noclipBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", noclipBtn)

local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.8,0.18)
speedBox.Position = UDim2.fromScale(0.1,0.6)
speedBox.Text = tostring(SPEED_MULT)
speedBox.PlaceholderText = "Speed x"
speedBox.TextScaled = true
speedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

------------------------------------------------
-- UI LOGIC
------------------------------------------------
menuBtn.MouseButton1Click:Connect(function()
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
	noclipBtn.Text = noclip and "NOCLIP : ON" or "NOCLIP : OFF"
	applyNoClip(noclip)
end)

speedBox.FocusLost:Connect(function()
	local v = tonumber(speedBox.Text)
	if v and v > 0 then SPEED_MULT = v end
	speedBox.Text = tostring(SPEED_MULT)
end)

------------------------------------------------
-- HOVER FLY LOOP (KEY PART)
------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart or not humanoid then return end

	alignOri.CFrame = camera.CFrame

	local dir = humanoid.MoveDirection
	local vel = Vector3.zero

	-- Horizontal movement
	if dir.Magnitude > 0.05 then
		vel += Vector3.new(
			dir.X * BASE_SPEED * SPEED_MULT,
			0,
			dir.Z * BASE_SPEED * SPEED_MULT
		)
	end

	-- Control height by camera
	local lookY = camera.CFrame.LookVector.Y
	if math.abs(lookY) > DEADZONE then
		hoverHeight += lookY * BASE_SPEED * 0.6
	end

	-- Altitude lock (ทำให้นิ่ง)
	local currentY = controlPart.Position.Y
	local yForce = (hoverHeight - currentY) * 10

	vel += Vector3.new(0, yForce, 0)
	linearVel.VectorVelocity = vel
end)
