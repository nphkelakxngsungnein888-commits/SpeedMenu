--[[ 
 ANYTHING FLY - ULTIMATE PRO FULL VERSION
 Fly + NoClip + Speed + UI Toggle + Record / Replay (Delta Mode)
 Mobile Friendly | LocalScript
]]

---------------- SERVICES ----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

---------------- PLAYER ------------------
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

---------------- CONFIG ------------------
local BASE_SPEED = 60
local SPEED_MULT = 1
local DEADZONE = 0.12

---------------- STATES ------------------
local flying = false
local noclip = false
local flyMode = "FLY" -- FLY / RECORD / PLAY

local recordData = {}
local recordIndex = 1

local humanoid
local controlPart
local mode -- CHAR / VEH

local alignOri
local linearVel
local attachment

---------------- UTIL --------------------
local function getModelCenter(model)
	local cf = model:GetBoundingBox()
	local p = Instance.new("Part")
	p.Size = Vector3.new(2,2,2)
	p.Transparency = 1
	p.CanCollide = false
	p.Anchored = false
	p.CFrame = cf
	p.Name = "_FlyControl"
	p.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p
	weld.Part1 = model:FindFirstChildWhichIsA("BasePart")
	weld.Parent = p

	return p
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

---------------- NOCLIP ------------------
local function applyNoClip(state)
	if player.Character then
		for _,v in ipairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = not state
			end
		end
	end
	if mode == "VEH" and controlPart then
		local m = controlPart:FindFirstAncestorOfClass("Model")
		if m then
			for _,v in ipairs(m:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = not state
				end
			end
		end
	end
end

---------------- FLY ---------------------
local function startFly()
	if flying then return end
	controlPart = getControl()
	if not controlPart then return end

	flying = true
	if mode == "CHAR" then humanoid.PlatformStand = true end

	pcall(function()
		controlPart:SetNetworkOwner(player)
	end)

	attachment = Instance.new("Attachment", controlPart)

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = attachment
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 25
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = attachment
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
	if attachment then attachment:Destroy() end
end

---------------- UI ----------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "FlyUltimateUI"
gui.ResetOnSpawn = false

-- UI Toggle
local uiToggle = Instance.new("TextButton", gui)
uiToggle.Size = UDim2.fromScale(0.09,0.045)
uiToggle.Position = UDim2.fromScale(0.02,0.6)
uiToggle.Text = "MENU"
uiToggle.TextScaled = true
uiToggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
uiToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", uiToggle)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.28,0.3)
panel.Position = UDim2.fromScale(0.36,0.32)
panel.Visible = false
panel.Active = true
panel.Draggable = true
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", panel)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.8,0.18)
flyBtn.Position = UDim2.fromScale(0.1,0.05)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- Mode (∆)
local modeBtn = Instance.new("TextButton", panel)
modeBtn.Size = UDim2.fromScale(0.8,0.16)
modeBtn.Position = UDim2.fromScale(0.1,0.28)
modeBtn.Text = "MODE : FLY"
modeBtn.TextScaled = true
modeBtn.BackgroundColor3 = Color3.fromRGB(90,90,220)
modeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", modeBtn)

-- NoClip
local noclipBtn = Instance.new("TextButton", panel)
noclipBtn.Size = UDim2.fromScale(0.8,0.16)
noclipBtn.Position = UDim2.fromScale(0.1,0.48)
noclipBtn.Text = "NOCLIP : OFF"
noclipBtn.TextScaled = true
noclipBtn.BackgroundColor3 = Color3.fromRGB(180,180,60)
noclipBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", noclipBtn)

-- Speed
local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.8,0.16)
speedBox.Position = UDim2.fromScale(0.1,0.68)
speedBox.Text = tostring(SPEED_MULT)
speedBox.PlaceholderText = "Speed Multiplier"
speedBox.TextScaled = true
speedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

---------------- UI LOGIC ----------------
uiToggle.MouseButton1Click:Connect(function()
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

modeBtn.MouseButton1Click:Connect(function()
	if flyMode == "FLY" then
		flyMode = "RECORD"
		recordData = {}
	elseif flyMode == "RECORD" then
		flyMode = "PLAY"
		recordIndex = 1
	else
		flyMode = "FLY"
	end
	modeBtn.Text = "MODE : "..flyMode
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

---------------- MAIN LOOP ---------------
RunService.RenderStepped:Connect(function()
	if not controlPart then return end

	-- RECORD
	if flyMode == "RECORD" and flying then
		table.insert(recordData, {cf = controlPart.CFrame})
	end

	-- PLAY
	if flyMode == "PLAY" and #recordData > 0 then
		local f = recordData[recordIndex]
		if f then
			controlPart.CFrame = f.cf
			recordIndex += 1
		else
			recordIndex = 1
		end
		return
	end

	-- NORMAL FLY
	if flying then
		alignOri.CFrame = camera.CFrame

		local dir = humanoid.MoveDirection
		local vel = Vector3.new(
			dir.X * BASE_SPEED * SPEED_MULT,
			0,
			dir.Z * BASE_SPEED * SPEED_MULT
		)

		if dir.Magnitude > 0.05 then
			local y = camera.CFrame.LookVector.Y
			if math.abs(y) > DEADZONE then
				vel += Vector3.new(0, y * BASE_SPEED * 0.75 * SPEED_MULT, 0)
			end
		end

		linearVel.VectorVelocity = vel
	end
end)
