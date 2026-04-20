--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

--// PLAYER
local player = Players.LocalPlayer
local character, humanoid, root

--// STATE
local speedEnabled = false
local speedMultiplier = 1

local infiniteJumpEnabled = false
local jumpPowerEnabled = false
local jumpPower = 50

local followTargetEnabled = false
local followDistance = 5
local followSpeedMultiplier = 1

--// FLY
local Flying = false
local FlySpeed = 60
local BV, BG, FlyLoop

--// LOCK HEIGHT
local lockHeightEnabled = false
local lockHeightOffset = 0
local lockTargetY = nil
local lockBodyPos = nil

--// NAME TAG
local nameTagEnabled = false
local nameTags = {}

local currentTarget = nil
local moveVector = Vector3.zero

local scanRange = 100
local nameFilter = ""
local hiddenTeamColors = {}
local lastFoundColors = {}
local pendingHide = {}

--// SETUP
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	-- รีเซ็ต fly
	if FlyLoop then FlyLoop:Disconnect() FlyLoop = nil end
	if BV then BV:Destroy() BV = nil end
	if BG then BG:Destroy() BG = nil end
	Flying = false
	-- รีเซ็ต lock
	lockTargetY = nil
	if lockBodyPos then lockBodyPos:Destroy() lockBodyPos = nil end
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(function(char)
	task.wait(1)
	setupCharacter(char)
end)
player.CharacterAdded:Connect(function()
	lockBodyPos = nil
	lockTargetY = nil
end)

local function getRoot()
	if character and character.Parent and root then return root end
	return nil
end

local function Alive()
	return character and humanoid and root and humanoid.Health > 0
end

--// TEAM COLOR
local function getTeamColor(p)
	if p and p.Team then
		local tc = p.Team.TeamColor
		return Color3.fromRGB(tc.r*255, tc.g*255, tc.b*255), p.Team.TeamColor.Name
	end
	return Color3.fromRGB(200,200,200), "NoTeam"
end

--// NAME TAG
local function clearNameTags()
	for _, tag in pairs(nameTags) do
		if tag and tag.Parent then tag:Destroy() end
	end
	nameTags = {}
end

local function updateNameTags()
	clearNameTags()
	if not nameTagEnabled then return end
	for _, p in pairs(Players:GetPlayers()) do
		if p == player then continue end
		local pChar = p.Character
		if not pChar then continue end
		local hrp2 = pChar:FindFirstChild("HumanoidRootPart")
		if not hrp2 then continue end

		local bb = Instance.new("BillboardGui")
		bb.Name = "KuyNameTag"
		bb.AlwaysOnTop = true
		bb.Size = UDim2.new(0, 100, 0, 22)
		bb.StudsOffset = Vector3.new(0, 3.5, 0)
		bb.Parent = hrp2

		local lbl = Instance.new("TextLabel", bb)
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = p.Name
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.Font = Enum.Font.SourceSansBold
		lbl.TextSize = 14
		lbl.TextStrokeTransparency = 0.3
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		table.insert(nameTags, bb)
	end
end

Players.PlayerAdded:Connect(function()
	task.wait(1)
	if nameTagEnabled then updateNameTags() end
end)
Players.PlayerRemoving:Connect(function()
	task.wait(0.1)
	if nameTagEnabled then updateNameTags() end
end)
task.spawn(function()
	while true do
		task.wait(5)
		if nameTagEnabled then updateNameTags() end
	end
end)

--// INFINITE JUMP
UIS.JumpRequest:Connect(function()
	if not infiniteJumpEnabled then return end
	if not humanoid then return end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.FallingDown
		or state == Enum.HumanoidStateType.Jumping then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

--// FLY (ใช้โค้ดใหม่ที่ส่งมา)
local function StartFly()
	if not Alive() or Flying then return end
	Flying = true

	BV = Instance.new("BodyVelocity")
	BV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	BV.Parent = root

	BG = Instance.new("BodyGyro")
	BG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	BG.P = 50000
	BG.D = 1000
	BG.Parent = root

	FlyLoop = RunService.RenderStepped:Connect(function()
		if not Flying or not Alive() then return end

		local camCF = Camera.CFrame
		local move = humanoid.MoveDirection

		local relative = camCF:VectorToObjectSpace(move)

		local forward = camCF.LookVector
		local right = camCF.RightVector

		local direction =
			(forward * -relative.Z) +
			(right * relative.X)

		BV.Velocity = direction * FlySpeed
		BG.CFrame = CFrame.lookAt(root.Position, root.Position + forward)

		humanoid.PlatformStand = true
	end)
end

local function StopFly()
	Flying = false
	if FlyLoop then FlyLoop:Disconnect() FlyLoop = nil end
	if BV then BV:Destroy() BV = nil end
	if BG then BG:Destroy() BG = nil end
	if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

--// LOCK HEIGHT
local function createLockForce(hrp)
	if not hrp then return end
	if not lockBodyPos then
		lockBodyPos = Instance.new("BodyPosition")
		lockBodyPos.MaxForce = Vector3.new(0, math.huge, 0)
		lockBodyPos.P = 100000
		lockBodyPos.D = 0
		lockBodyPos.Parent = hrp
	end
end

local function applyLockHeight(hrp)
	if not hrp then return end
	if not lockTargetY then
		lockTargetY = hrp.Position.Y + lockHeightOffset
		hrp.CFrame = CFrame.new(hrp.Position.X, lockTargetY, hrp.Position.Z)
	end
	createLockForce(hrp)
	local finalY = lockTargetY
	if lockHeightOffset < 0 then
		finalY = lockTargetY - 6
	elseif lockHeightOffset > 0 then
		finalY = lockTargetY + 0.2
	end
	lockBodyPos.Position = Vector3.new(hrp.Position.X, finalY, hrp.Position.Z)
end

local function removeLockHeight()
	if lockBodyPos then lockBodyPos:Destroy() lockBodyPos = nil end
	lockTargetY = nil
end

RunService.Heartbeat:Connect(function()
	if not lockHeightEnabled then
		if lockBodyPos then removeLockHeight() end
		return
	end
	local hrp = getRoot()
	if not hrp then
		if player.Character then setupCharacter(player.Character) end
		return
	end
	applyLockHeight(hrp)
end)

--// MAIN LOOP
RunService.RenderStepped:Connect(function(dt)
	local hrp = getRoot()
	if not hrp or not humanoid then return end

	if jumpPowerEnabled then
		humanoid.JumpPower = jumpPower
	end

	-- SPEED
	if speedEnabled and not Flying then
		local dir = humanoid.MoveDirection
		if dir.Magnitude > 0 then
			dir = dir.Unit
			local final = 16 * speedMultiplier
			hrp.CFrame = hrp.CFrame + Vector3.new(dir.X*final*0.05, 0, dir.Z*final*0.05)
		end
		humanoid.PlatformStand = false
		if not infiniteJumpEnabled then
			local state = humanoid:GetState()
			if state ~= Enum.HumanoidStateType.Jumping
				and state ~= Enum.HumanoidStateType.Freefall
				and state ~= Enum.HumanoidStateType.FallingDown then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end
	end

	-- FOLLOW
	if followTargetEnabled and not Flying then
		if currentTarget and not currentTarget.Parent then currentTarget = nil end
		if currentTarget then
			local tr = currentTarget:FindFirstChild("HumanoidRootPart")
			if tr then
				local dist = (tr.Position - hrp.Position).Magnitude
				if dist > followDistance then
					local dir = (tr.Position - hrp.Position).Unit
					hrp.CFrame = hrp.CFrame + dir * (0.6 * followSpeedMultiplier)
				end
				hrp.CFrame = CFrame.new(hrp.Position, tr.Position)
			end
		end
	end
end)

--// ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "KuyUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 240, 0, 420)
main.Position = UDim2.new(0.05, 0, 0.1, 0)
main.BackgroundColor3 = Color3.fromRGB(0,0,0)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local titleLabel = Instance.new("TextLabel", main)
titleLabel.Size = UDim2.new(1,0,0,24)
titleLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
titleLabel.Text = "Move Hub"
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 14
titleLabel.BorderSizePixel = 0

local closeMain = Instance.new("TextButton", main)
closeMain.Size = UDim2.new(0,24,0,24)
closeMain.Position = UDim2.new(1,-24,0,0)
closeMain.Text = "X"
closeMain.BackgroundColor3 = Color3.fromRGB(0,0,0)
closeMain.TextColor3 = Color3.fromRGB(255,80,80)
closeMain.Font = Enum.Font.SourceSansBold
closeMain.TextSize = 13
closeMain.BorderSizePixel = 0
closeMain.MouseButton1Click:Connect(function() gui:Destroy() end)

local minBtn = Instance.new("TextButton", main)
minBtn.Size = UDim2.new(0,24,0,24)
minBtn.Position = UDim2.new(1,-48,0,0)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
minBtn.TextColor3 = Color3.fromRGB(200,200,200)
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 14
minBtn.BorderSizePixel = 0

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,0,1,-24)
content.Position = UDim2.new(0,0,0,24)
content.BackgroundTransparency = 1

local open = true
minBtn.MouseButton1Click:Connect(function()
	open = not open
	content.Visible = open
	main.Size = open and UDim2.new(0,240,0,420) or UDim2.new(0,240,0,24)
end)

local scroll = Instance.new("ScrollingFrame", content)
scroll.Size = UDim2.new(1,-6,1,-4)
scroll.Position = UDim2.new(0,3,0,2)
scroll.CanvasSize = UDim2.new(0,0,0,900)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 3
scroll.BorderSizePixel = 0

local mainLayout = Instance.new("UIListLayout", scroll)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0,5)

--// UI HELPERS
local function makeHeader(parent, text)
	local h = Instance.new("TextLabel", parent)
	h.Size = UDim2.new(1,0,0,16)
	h.BackgroundColor3 = Color3.fromRGB(15,15,15)
	h.Text = text
	h.TextColor3 = Color3.fromRGB(160,160,160)
	h.Font = Enum.Font.SourceSansBold
	h.TextSize = 10
	h.BorderSizePixel = 0
	return h
end

local function makeSmallBtn(parent, text)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(0,72,0,26)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(15,15,15)
	b.TextColor3 = Color3.fromRGB(220,220,220)
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 10
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	return b
end

local function makeBox(parent, placeholder, defaultVal)
	local b = Instance.new("TextBox", parent)
	b.Size = UDim2.new(1,0,0,24)
	b.PlaceholderText = placeholder
	b.Text = defaultVal or ""
	b.BackgroundColor3 = Color3.fromRGB(18,18,18)
	b.TextColor3 = Color3.fromRGB(220,220,220)
	b.PlaceholderColor3 = Color3.fromRGB(80,80,80)
	b.Font = Enum.Font.SourceSans
	b.TextSize = 11
	b.BorderSizePixel = 0
	return b
end

local function makeFullBtn(parent, text)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(1,0,0,28)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(15,15,15)
	b.TextColor3 = Color3.fromRGB(220,220,220)
	b.Font = Enum.Font.SourceSans
	b.TextSize = 12
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	return b
end

local function makeRow(parent)
	local f = Instance.new("Frame", parent)
	f.Size = UDim2.new(1,0,0,26)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	local l = Instance.new("UIListLayout", f)
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0,3)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	return f
end

--// MOVEMENT
makeHeader(scroll, "── MOVEMENT ──")

local row1 = makeRow(scroll)
local speedBtn = makeSmallBtn(row1, "Speed\nOFF")
local jumpBtn  = makeSmallBtn(row1, "Inf Jump\nOFF")

local row1b = makeRow(scroll)
row1b.Size = UDim2.new(1,0,0,24)

local speedValBox = makeBox(nil, "Spd x1", "")
speedValBox.Size = UDim2.new(0,112,0,24)
speedValBox.Parent = row1b

local jumpValBox = makeBox(nil, "Jmp 50", "")
jumpValBox.Size = UDim2.new(0,112,0,24)
jumpValBox.Parent = row1b

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	speedBtn.Text = "Speed\n"..(speedEnabled and "ON" or "OFF")
	speedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(0,35,0) or Color3.fromRGB(15,15,15)
end)
speedValBox.FocusLost:Connect(function()
	local n = tonumber(speedValBox.Text)
	if n and n > 0 then speedMultiplier = n speedValBox.Text = tostring(n)
	else speedValBox.Text = tostring(speedMultiplier) end
end)

jumpBtn.MouseButton1Click:Connect(function()
	infiniteJumpEnabled = not infiniteJumpEnabled
	jumpBtn.Text = "Inf Jump\n"..(infiniteJumpEnabled and "ON" or "OFF")
	jumpBtn.BackgroundColor3 = infiniteJumpEnabled and Color3.fromRGB(0,35,0) or Color3.fromRGB(15,15,15)
end)
jumpValBox.FocusLost:Connect(function()
	local n = tonumber(jumpValBox.Text)
	if n and n > 0 then
		jumpPower = n
		jumpPowerEnabled = true
		jumpValBox.Text = tostring(n)
	else jumpValBox.Text = tostring(jumpPower) end
end)

--// SPECIAL
makeHeader(scroll, "── SPECIAL ──")

local row2 = makeRow(scroll)
local flyBtn  = makeSmallBtn(row2, "Fly\nOFF")
local lockBtn = makeSmallBtn(row2, "LockY\nOFF")

local row2b = makeRow(scroll)
row2b.Size = UDim2.new(1,0,0,24)

local flyValBox = makeBox(nil, "Fly spd 60", "")
flyValBox.Size = UDim2.new(0,112,0,24)
flyValBox.Parent = row2b

local lockValBox = makeBox(nil, "Y offset 0", "")
lockValBox.Size = UDim2.new(0,112,0,24)
lockValBox.Parent = row2b

flyBtn.MouseButton1Click:Connect(function()
	if Flying then
		StopFly()
		flyBtn.Text = "Fly\nOFF"
		flyBtn.BackgroundColor3 = Color3.fromRGB(15,15,15)
	else
		StartFly()
		flyBtn.Text = "Fly\nON"
		flyBtn.BackgroundColor3 = Color3.fromRGB(0,35,0)
	end
end)
flyValBox.FocusLost:Connect(function()
	local n = tonumber(flyValBox.Text)
	if n and n > 0 then FlySpeed = n flyValBox.Text = tostring(n)
	else flyValBox.Text = tostring(FlySpeed) end
end)

lockBtn.MouseButton1Click:Connect(function()
	lockHeightEnabled = not lockHeightEnabled
	lockBtn.Text = "LockY\n"..(lockHeightEnabled and "ON" or "OFF")
	lockBtn.BackgroundColor3 = lockHeightEnabled and Color3.fromRGB(0,35,0) or Color3.fromRGB(15,15,15)
	if lockHeightEnabled then
		local hrp = getRoot()
		if hrp then applyLockHeight(hrp) end
	else
		removeLockHeight()
		if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end
end)
lockValBox.FocusLost:Connect(function()
	local n = tonumber(lockValBox.Text)
	if n ~= nil then
		lockHeightOffset = n
		lockValBox.Text = tostring(n)
		if lockHeightEnabled then
			local hrp = getRoot()
			if hrp then
				lockTargetY = nil
				removeLockHeight()
				applyLockHeight(hrp)
			end
		end
	else lockValBox.Text = tostring(lockHeightOffset) end
end)

--// NAME TAG
makeHeader(scroll, "── NAME TAG ──")

local nameTagBtn = makeFullBtn(scroll, "Show Names OFF")
nameTagBtn.MouseButton1Click:Connect(function()
	nameTagEnabled = not nameTagEnabled
	nameTagBtn.Text = nameTagEnabled and "Show Names ON" or "Show Names OFF"
	nameTagBtn.BackgroundColor3 = nameTagEnabled and Color3.fromRGB(0,35,0) or Color3.fromRGB(15,15,15)
	updateNameTags()
end)

--// FOLLOW
makeHeader(scroll, "── FOLLOW ──")

local targetBtn = makeFullBtn(scroll, "Follow Target OFF")
targetBtn.MouseButton1Click:Connect(function()
	followTargetEnabled = not followTargetEnabled
	targetBtn.Text = followTargetEnabled and "Follow Target ON" or "Follow Target OFF"
	targetBtn.BackgroundColor3 = followTargetEnabled and Color3.fromRGB(0,35,0) or Color3.fromRGB(15,15,15)
end)

local targetLabel = Instance.new("TextLabel", scroll)
targetLabel.Size = UDim2.new(1,0,0,20)
targetLabel.Text = "Target: -"
targetLabel.BackgroundColor3 = Color3.fromRGB(10,10,10)
targetLabel.TextColor3 = Color3.fromRGB(180,255,180)
targetLabel.Font = Enum.Font.SourceSans
targetLabel.TextSize = 11
targetLabel.TextTruncate = Enum.TextTruncate.AtEnd
targetLabel.BorderSizePixel = 0

local row3 = makeRow(scroll)
row3.Size = UDim2.new(1,0,0,24)

local followSpdBox = makeBox(nil, "Follow spd 1", "")
followSpdBox.Size = UDim2.new(0,112,0,24)
followSpdBox.Parent = row3
followSpdBox.FocusLost:Connect(function()
	local n = tonumber(followSpdBox.Text)
	if n and n > 0 then followSpeedMultiplier = n followSpdBox.Text = tostring(n)
	else followSpdBox.Text = tostring(followSpeedMultiplier) end
end)

local distBox = makeBox(nil, "Stop dist 5", "")
distBox.Size = UDim2.new(0,112,0,24)
distBox.Parent = row3
distBox.FocusLost:Connect(function()
	local n = tonumber(distBox.Text)
	if n and n > 0 then followDistance = n distBox.Text = tostring(n)
	else distBox.Text = tostring(followDistance) end
end)

local clearBtn = makeFullBtn(scroll, "Clear Target")
clearBtn.BackgroundColor3 = Color3.fromRGB(50,8,8)
clearBtn.TextColor3 = Color3.fromRGB(255,160,160)
clearBtn.MouseButton1Click:Connect(function()
	currentTarget = nil
	targetLabel.Text = "Target: -"
end)

local scanToggleBtn = makeFullBtn(scroll, "Player Scanner")
scanToggleBtn.BackgroundColor3 = Color3.fromRGB(0,18,45)
scanToggleBtn.TextColor3 = Color3.fromRGB(130,200,255)
scanToggleBtn.Font = Enum.Font.SourceSansBold

--// ============ SCANNER MENU ============
local scanMenu = Instance.new("Frame", gui)
scanMenu.Size = UDim2.new(0,200,0,320)
scanMenu.Position = UDim2.new(0.05,250,0.1,0)
scanMenu.BackgroundColor3 = Color3.fromRGB(5,5,15)
scanMenu.BorderSizePixel = 0
scanMenu.Active = true
scanMenu.Draggable = true
scanMenu.Visible = false
scanMenu.ClipsDescendants = true

local scanHead = Instance.new("Frame", scanMenu)
scanHead.Size = UDim2.new(1,0,0,22)
scanHead.BackgroundColor3 = Color3.fromRGB(0,20,50)
scanHead.BorderSizePixel = 0

local scanTitle = Instance.new("TextLabel", scanHead)
scanTitle.Size = UDim2.new(0,90,1,0)
scanTitle.Position = UDim2.new(0,4,0,0)
scanTitle.BackgroundTransparency = 1
scanTitle.Text = "Player Scanner"
scanTitle.TextColor3 = Color3.fromRGB(150,210,255)
scanTitle.Font = Enum.Font.SourceSansBold
scanTitle.TextSize = 12
scanTitle.TextXAlignment = Enum.TextXAlignment.Left

local filterToggleBtn = Instance.new("TextButton", scanHead)
filterToggleBtn.Size = UDim2.new(0,40,0,18)
filterToggleBtn.Position = UDim2.new(1,-64,0,2)
filterToggleBtn.Text = "Filter"
filterToggleBtn.BackgroundColor3 = Color3.fromRGB(0,40,80)
filterToggleBtn.TextColor3 = Color3.fromRGB(150,210,255)
filterToggleBtn.Font = Enum.Font.SourceSansBold
filterToggleBtn.TextSize = 10
filterToggleBtn.BorderSizePixel = 0
filterToggleBtn.ZIndex = 4

local filterOkBtn = Instance.new("TextButton", scanHead)
filterOkBtn.Size = UDim2.new(0,20,0,18)
filterOkBtn.Position = UDim2.new(1,-22,0,2)
filterOkBtn.Text = "OK"
filterOkBtn.BackgroundColor3 = Color3.fromRGB(0,60,20)
filterOkBtn.TextColor3 = Color3.fromRGB(150,255,150)
filterOkBtn.Font = Enum.Font.SourceSansBold
filterOkBtn.TextSize = 10
filterOkBtn.BorderSizePixel = 0

local scanClose = Instance.new("TextButton", scanMenu)
scanClose.Size = UDim2.new(0,22,0,22)
scanClose.Position = UDim2.new(1,-22,0,0)
scanClose.Text = "X"
scanClose.BackgroundColor3 = Color3.fromRGB(0,20,50)
scanClose.TextColor3 = Color3.fromRGB(255,100,100)
scanClose.TextSize = 12
scanClose.BorderSizePixel = 0
scanClose.ZIndex = 5
scanClose.MouseButton1Click:Connect(function() scanMenu.Visible = false end)

local filterPopup = Instance.new("Frame", scanMenu)
filterPopup.Size = UDim2.new(1,-8,0,120)
filterPopup.Position = UDim2.new(0,4,0,22)
filterPopup.BackgroundColor3 = Color3.fromRGB(5,15,35)
filterPopup.BorderSizePixel = 1
filterPopup.BorderColor3 = Color3.fromRGB(0,60,120)
filterPopup.Visible = false
filterPopup.ZIndex = 10
filterPopup.ClipsDescendants = true

local filterScroll = Instance.new("ScrollingFrame", filterPopup)
filterScroll.Size = UDim2.new(1,0,1,0)
filterScroll.BackgroundTransparency = 1
filterScroll.ScrollBarThickness = 3
filterScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
filterScroll.CanvasSize = UDim2.new(0,0,0,0)
filterScroll.ZIndex = 10

local filterLayout2 = Instance.new("UIListLayout", filterScroll)
filterLayout2.SortOrder = Enum.SortOrder.LayoutOrder
filterLayout2.Padding = UDim.new(0,3)

filterToggleBtn.MouseButton1Click:Connect(function()
	filterPopup.Visible = not filterPopup.Visible
	if filterPopup.Visible then
		for _, c in pairs(filterScroll:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		pendingHide = {}
		for colorName, colorVal in pairs(lastFoundColors) do
			local row = Instance.new("TextButton", filterScroll)
			row.Size = UDim2.new(1,-6,0,24)
			row.BackgroundColor3 = hiddenTeamColors[colorName]
				and Color3.fromRGB(80,10,10) or Color3.fromRGB(10,30,60)
			row.TextColor3 = colorVal
			row.Font = Enum.Font.SourceSansBold
			row.TextSize = 12
			row.BorderSizePixel = 1
			row.BorderColor3 = colorVal
			row.AutoButtonColor = false
			row.ZIndex = 11
			row.Text = (hiddenTeamColors[colorName] and "✗ " or "✓ ") .. colorName
			row.MouseButton1Click:Connect(function()
				if pendingHide[colorName] then
					pendingHide[colorName] = nil
					row.BackgroundColor3 = hiddenTeamColors[colorName]
						and Color3.fromRGB(80,10,10) or Color3.fromRGB(10,30,60)
					row.Text = (hiddenTeamColors[colorName] and "✗ " or "✓ ") .. colorName
				else
					pendingHide[colorName] = true
					local willHide = not hiddenTeamColors[colorName]
					row.BackgroundColor3 = willHide
						and Color3.fromRGB(80,10,10) or Color3.fromRGB(10,30,60)
					row.Text = (willHide and "✗ " or "✓ ") .. colorName
				end
			end)
		end
	end
end)

local rangeBar = Instance.new("Frame", scanMenu)
rangeBar.Size = UDim2.new(1,0,0,26)
rangeBar.Position = UDim2.new(0,0,0,22)
rangeBar.BackgroundColor3 = Color3.fromRGB(10,10,25)
rangeBar.BorderSizePixel = 0

local rangeLabel2 = Instance.new("TextLabel", rangeBar)
rangeLabel2.Size = UDim2.new(0,50,1,0)
rangeLabel2.Position = UDim2.new(0,4,0,0)
rangeLabel2.BackgroundTransparency = 1
rangeLabel2.Text = "Range:"
rangeLabel2.TextColor3 = Color3.fromRGB(180,180,255)
rangeLabel2.Font = Enum.Font.SourceSans
rangeLabel2.TextSize = 12
rangeLabel2.TextXAlignment = Enum.TextXAlignment.Left

local rangeBox = Instance.new("TextBox", rangeBar)
rangeBox.Size = UDim2.new(0,65,0,20)
rangeBox.Position = UDim2.new(0,52,0,3)
rangeBox.Text = "100"
rangeBox.BackgroundColor3 = Color3.fromRGB(20,20,40)
rangeBox.TextColor3 = Color3.fromRGB(255,255,255)
rangeBox.Font = Enum.Font.SourceSans
rangeBox.TextSize = 12
rangeBox.BorderSizePixel = 0
rangeBox.FocusLost:Connect(function()
	local n = tonumber(rangeBox.Text)
	if n and n > 0 then scanRange = n
	else rangeBox.Text = tostring(scanRange) end
end)

local searchBar = Instance.new("Frame", scanMenu)
searchBar.Size = UDim2.new(1,0,0,26)
searchBar.Position = UDim2.new(0,0,0,48)
searchBar.BackgroundColor3 = Color3.fromRGB(10,10,25)
searchBar.BorderSizePixel = 0

local searchLbl = Instance.new("TextLabel", searchBar)
searchLbl.Size = UDim2.new(0,28,1,0)
searchLbl.Position = UDim2.new(0,2,0,0)
searchLbl.BackgroundTransparency = 1
searchLbl.Text = "🔍"
searchLbl.TextSize = 13
searchLbl.Font = Enum.Font.SourceSans

local searchBox = Instance.new("TextBox", searchBar)
searchBox.Size = UDim2.new(1,-32,0,20)
searchBox.Position = UDim2.new(0,28,0,3)
searchBox.PlaceholderText = "ค้นหาชื่อ..."
searchBox.Text = ""
searchBox.BackgroundColor3 = Color3.fromRGB(20,20,40)
searchBox.TextColor3 = Color3.fromRGB(255,255,255)
searchBox.PlaceholderColor3 = Color3.fromRGB(100,100,130)
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 12
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false

local listFrame = Instance.new("ScrollingFrame", scanMenu)
listFrame.Size = UDim2.new(1,-4,1,-76)
listFrame.Position = UDim2.new(0,2,0,76)
listFrame.BackgroundTransparency = 1
listFrame.ScrollBarThickness = 3
listFrame.BorderSizePixel = 0
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.CanvasSize = UDim2.new(0,0,0,0)

local listLayout = Instance.new("UIListLayout", listFrame)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0,3)

--// SEARCH TAGS (ชื่อในแมพ)
local searchTags = {}

local function clearSearchTags()
	for _, tag in pairs(searchTags) do
		if tag and tag.Parent then tag:Destroy() end
	end
	searchTags = {}
end

local function applySearchTags(filter)
	clearSearchTags()
	if filter == "" then return end
	for _, p in pairs(Players:GetPlayers()) do
		if p == player then continue end
		if not p.Name:lower():find(filter, 1, true) then continue end
		local pChar = p.Character
		if not pChar then continue end
		local hrp2 = pChar:FindFirstChild("HumanoidRootPart")
		if not hrp2 then continue end

		local bb = Instance.new("BillboardGui")
		bb.Name = "KuySearchTag"
		bb.AlwaysOnTop = true
		bb.Size = UDim2.new(0, 110, 0, 24)
		bb.StudsOffset = Vector3.new(0, 4.5, 0)
		bb.Parent = hrp2

		local lbl = Instance.new("TextLabel", bb)
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "▶ "..p.Name
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.Font = Enum.Font.SourceSansBold
		lbl.TextSize = 14
		lbl.TextStrokeTransparency = 0.2
		lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		table.insert(searchTags, bb)
	end
end

local function doScan()
	for _, c in pairs(listFrame:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
	local hrp = getRoot()
	if not hrp then return end

	local found = {}
	local foundColors = {}
	local filter = nameFilter

	for _, p in pairs(Players:GetPlayers()) do
		if p == player then continue end
		local pChar = p.Character
		if not pChar then continue end
		local r = pChar:FindFirstChild("HumanoidRootPart")
		local h = pChar:FindFirstChildOfClass("Humanoid")
		if not r or not h or h.Health <= 0 then continue end
		local dist = (r.Position - hrp.Position).Magnitude
		if dist <= scanRange then
			if filter ~= "" and not p.Name:lower():find(filter, 1, true) then continue end
			local col, colName = getTeamColor(p)
			foundColors[colName] = col
			if not hiddenTeamColors[colName] then
				table.insert(found, {p=p, dist=math.floor(dist), col=col, colName=colName})
			end
		end
	end

	lastFoundColors = foundColors
	table.sort(found, function(a,b) return a.dist < b.dist end)

	if #found == 0 then
		local empty = Instance.new("TextLabel", listFrame)
		empty.Size = UDim2.new(1,0,0,24)
		empty.Text = filter ~= "" and "ไม่พบ: "..nameFilter or "ไม่พบผู้เล่นในระยะ"
		empty.BackgroundTransparency = 1
		empty.TextColor3 = Color3.fromRGB(130,130,130)
		empty.Font = Enum.Font.SourceSans
		empty.TextSize = 12
		return
	end

	for _, data in ipairs(found) do
		local p = data.p
		local col = data.col

		local btn = Instance.new("TextButton", listFrame)
		btn.Size = UDim2.new(1,-4,0,26)
		btn.BackgroundColor3 = Color3.fromRGB(
			math.clamp(col.R*255*0.12,4,35),
			math.clamp(col.G*255*0.12,4,35),
			math.clamp(col.B*255*0.12,4,35)
		)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.ClipsDescendants = true

		local bar = Instance.new("Frame", btn)
		bar.Size = UDim2.new(0,3,1,0)
		bar.BackgroundColor3 = col
		bar.BorderSizePixel = 0

		local nameLbl = Instance.new("TextLabel", btn)
		nameLbl.Size = UDim2.new(1,-54,1,0)
		nameLbl.Position = UDim2.new(0,7,0,0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = p.Name
		nameLbl.TextColor3 = col
		nameLbl.Font = Enum.Font.SourceSansBold
		nameLbl.TextSize = 12
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local distLbl = Instance.new("TextLabel", btn)
		distLbl.Size = UDim2.new(0,48,1,0)
		distLbl.Position = UDim2.new(1,-50,0,0)
		distLbl.BackgroundTransparency = 1
		distLbl.Text = data.dist.."m"
		distLbl.TextColor3 = Color3.fromRGB(150,150,150)
		distLbl.Font = Enum.Font.SourceSans
		distLbl.TextSize = 11
		distLbl.TextXAlignment = Enum.TextXAlignment.Right

		btn.MouseButton1Click:Connect(function()
			local pChar = p.Character
			if not pChar then return end
			local h2 = pChar:FindFirstChildOfClass("Humanoid")
			local r2 = pChar:FindFirstChild("HumanoidRootPart")
			if h2 and r2 and h2.Health > 0 then
				currentTarget = pChar
				targetLabel.Text = "Target: "..p.Name
				followTargetEnabled = true
				targetBtn.Text = "Follow Target ON"
				targetBtn.BackgroundColor3 = Color3.fromRGB(0,35,0)
			end
		end)
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	nameFilter = searchBox.Text:lower()
	applySearchTags(nameFilter)
	if scanMenu.Visible then doScan() end
end)

filterOkBtn.MouseButton1Click:Connect(function()
	for colorName, _ in pairs(pendingHide) do
		if hiddenTeamColors[colorName] then
			hiddenTeamColors[colorName] = nil
		else
			hiddenTeamColors[colorName] = true
		end
	end
	pendingHide = {}
	filterPopup.Visible = false
	doScan()
end)

task.spawn(function()
	while true do
		task.wait(1.5)
		if scanMenu.Visible then doScan() end
	end
end)

scanToggleBtn.MouseButton1Click:Connect(function()
	scanMenu.Visible = not scanMenu.Visible
	if scanMenu.Visible then doScan() end
end)
