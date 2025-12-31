--// ANYTHING FLY - PRO MAX FULL VERSION
--// Character & Vehicle | Mobile | NoClip | PRO MAX

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- SETTINGS
local SPEED = 60
local DEADZONE = 0.12
local flying = false
local noclip = false
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
-- START / STOP
---------------------------------------------------
local function startFly()
	if flying then return end
	controlPart = getControl()
	if not controlPart then return end
	flying = true

	if mode == "CHAR" then
		humanoid.PlatformStand = true
	end

	-- Network Ownership (Multiplayer safe)
	pcall(function()
		controlPart:SetNetworkOwner(player)
	end)

	-- AlignOrientation
	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 22
	alignOri.Parent = controlPart

	-- LinearVelocity
	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart

	-- Apply NoClip if active
	if noclip then applyNoClip(true) end
end

local function stopFly()
	if not flying then return end
	flying = false

	if humanoid then humanoid.PlatformStand = false end

	-- Safe stop & reset
	task.delay(0.05,function()
		if alignOri then alignOri:Destroy() end
		if linearVel then linearVel:Destroy() end
		applyNoClip(false)
	end)
end

---------------------------------------------------
-- UI
---------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "AnythingFlyProMaxFullUI"
gui.ResetOnSpawn = false

-- Toggle Panel Button
local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.fromScale(0.11,0.05)
toggle.Position = UDim2.fromScale(0.02,0.6)
toggle.Text = "FLY"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

-- Panel
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.38,0.32)
panel.Position = UDim2.fromScale(0.31,0.33)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true
Instance.new("UICorner", panel)

-- Fly Button
local flyBtn = Instance.new("TextButton", panel)
flyBtn.Size = UDim2.fromScale(0.8,0.22)
flyBtn.Position = UDim2.fromScale(0.1,0.05)
flyBtn.Text = "FLY : OFF"
flyBtn.TextScaled = true
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
flyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", flyBtn)

-- Speed Label
local speedText = Instance.new("TextLabel", panel)
speedText.Size = UDim2.fromScale(1,0.15)
speedText.Position = UDim2.fromScale(0,0.3)
speedText.BackgroundTransparency = 1
speedText.Text = "Speed : 60"
speedText.TextScaled = true
speedText.Font = Enum.Font.Gotham
speedText.TextColor3 = Color3.new(1,1,1)

-- NoClip Button
local noclipBtn = Instance.new("TextButton", panel)
noclipBtn.Size = UDim2.fromScale(0.8,0.18)
noclipBtn.Position = UDim2.fromScale(0.1,0.55)
noclipBtn.Text = "NoClip : OFF"
noclipBtn.TextScaled = true
noclipBtn.Font = Enum.Font.GothamBold
noclipBtn.BackgroundColor3 = Color3.fromRGB(180,180,60)
noclipBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", noclipBtn)

---------------------------------------------------
-- UI LOGIC
---------------------------------------------------
toggle.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

flyBtn.MouseButton1Click:Connect(function()
	if flying then stopFly() 
		flyBtn.Text = "FLY : OFF" 
		flyBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
	else startFly() 
		flyBtn.Text = "FLY : ON" 
		flyBtn.BackgroundColor3 = Color3.fromRGB(60,180,90) 
	end
end)

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.Text = noclip and "NoClip : ON" or "NoClip : OFF"
	if flying then applyNoClip(noclip) end
end)

-- Slider for Speed (Touch)
local dragging = false
local bar = Instance.new("Frame", panel)
bar.Size = UDim2.fromScale(0.8,0.08)
bar.Position = UDim2.fromScale(0.1,0.8)
bar.BackgroundColor3 = Color3.fromRGB(60,60,60)
Instance.new("UICorner", bar)

local fill = Instance.new("Frame", bar)
fill.Size = UDim2.fromScale(SPEED/150,1)
fill.BackgroundColor3 = Color3.fromRGB(0,170,255)
Instance.new("UICorner", fill)

bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then dragging = true end
end)
bar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

RunService.RenderStepped:Connect(function()
	if dragging then
		local x = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
		fill.Size = UDim2.fromScale(x,1)
		SPEED = math.floor(30 + x*120)
		speedText.Text = "Speed : "..SPEED
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

	local vel = Vector3.new(dir.X*SPEED,0,dir.Z*SPEED)
	if moving then
		local y = camera.CFrame.LookVector.Y
		if math.abs(y) > DEADZONE then vel += Vector3.new(0,y*SPEED*0.75,0) end
	end

	linearVel.VectorVelocity = vel
end)

player.CharacterAdded:Connect(stopFly)
