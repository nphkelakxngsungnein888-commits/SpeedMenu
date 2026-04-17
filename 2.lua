--// =========================
--// SERVICES
--// =========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// =========================
--// VARIABLES
--// =========================
local char, humanoid, root

local toggles = {
	speed = false,
	jump = false,
	noclip = false,
	fly = false,
	float = false,
}

local values = {
	speed = 1,
	jumpPower = 50,
	jumpCount = 2,
	flySpeed = 1,
	floatOffset = 0,
	menuSize = 10,
}

local jumpUsed = 0
local floatOrigin = nil
local floatTargetPos = nil
local flyBV, flyBG = nil, nil
local miniButton = nil
local minimized = false
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local uiRefs = {}

--// =========================
--// THEME
--// =========================
local THEME = {
	bg         = Color3.fromRGB(8, 8, 10),
	surface    = Color3.fromRGB(15, 15, 18),
	card       = Color3.fromRGB(20, 20, 25),
	cardHover  = Color3.fromRGB(28, 28, 35),
	border     = Color3.fromRGB(50, 50, 65),
	accent     = Color3.fromRGB(120, 100, 255),
	accentDim  = Color3.fromRGB(70, 55, 180),
	accentGlow = Color3.fromRGB(160, 140, 255),
	text       = Color3.fromRGB(235, 235, 240),
	textDim    = Color3.fromRGB(140, 140, 155),
	textMuted  = Color3.fromRGB(85, 85, 100),
	green      = Color3.fromRGB(80, 220, 130),
	red        = Color3.fromRGB(255, 80, 80),
	topbar     = Color3.fromRGB(12, 12, 16),
}

--// =========================
--// FUNCTIONS
--// =========================
local function safeNum(text, fallback)
	local n = tonumber(text)
	if n == nil then return fallback end
	return n
end

local function clampMenuScale(v)
	v = math.floor(tonumber(v) or 10)
	if v < 1 then v = 1 end
	if v > 10 then v = 10 end
	return v
end

local function menuFactor()
	return 0.55 + ((values.menuSize - 1) * (0.45 / 9))
end

local function safeHRP()
	if not player.Character then return nil end
	return player.Character:FindFirstChild("HumanoidRootPart")
end

local function stopFly()
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
end

local function applyNoclip(state)
	if not player.Character then return end
	for _, v in ipairs(player.Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = not state
		end
	end
end

local function refreshSpeed()
	if humanoid then
		humanoid.WalkSpeed = 16 * math.max(values.speed, 1)
	end
end

local function refreshJump()
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = values.jumpPower
	end
end

local function refreshFloat()
	local hrp = safeHRP()
	if not hrp then return end
	if toggles.float then
		if floatOrigin == nil then floatOrigin = hrp.Position end
		floatTargetPos = floatOrigin + Vector3.new(0, values.floatOffset, 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(floatTargetPos, floatTargetPos + hrp.CFrame.LookVector)
	else
		hrp.Anchored = false
	end
end

local function applyFlyObjects()
	local hrp = safeHRP()
	if not hrp then return end
	stopFly()
	flyBV = Instance.new("BodyVelocity")
	flyBV.Name = "SmartFlyVelocity"
	flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	flyBV.P = 1e5
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = hrp
	flyBG = Instance.new("BodyGyro")
	flyBG.Name = "SmartFlyGyro"
	flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	flyBG.P = 1e5
	flyBG.D = 1000
	flyBG.CFrame = hrp.CFrame
	flyBG.Parent = hrp
end

local function setCharacter(c)
	char = c
	if not char then humanoid = nil; root = nil; return end
	humanoid = char:WaitForChild("Humanoid", 10)
	root = char:WaitForChild("HumanoidRootPart", 10)
	jumpUsed = 0
	floatOrigin = nil
	floatTargetPos = nil
	if humanoid then refreshSpeed(); refreshJump() end
	if toggles.float then task.wait(); refreshFloat() end
	if toggles.fly then task.wait(); applyFlyObjects() end
end

local function setToggleState(key, state)
	toggles[key] = state
	if key == "speed" then refreshSpeed()
	elseif key == "jump" then refreshJump(); jumpUsed = 0
	elseif key == "noclip" then applyNoclip(state)
	elseif key == "fly" then
		if state then applyFlyObjects()
		else stopFly(); if humanoid then humanoid.AutoRotate = true end end
	elseif key == "float" then
		if state then floatOrigin = nil; refreshFloat()
		else
			local hrp = safeHRP()
			if hrp then hrp.Anchored = false end
			floatOrigin = nil; floatTargetPos = nil
		end
	end
end

local function updateMenuScale(n)
	values.menuSize = clampMenuScale(n)
	local f = menuFactor()
	local w = math.floor(210 * f)
	local h = math.floor(310 * f)
	uiRefs.main.Size = UDim2.fromOffset(w, h)
	local fs = math.max(8, math.floor(11 * f))
	local fsSmall = math.max(7, math.floor(9 * f))
	if uiRefs.title then uiRefs.title.TextSize = math.max(10, math.floor(13 * f)) end
	if uiRefs.sizeLabel then uiRefs.sizeLabel.TextSize = fsSmall end
	if uiRefs.sizeBox then uiRefs.sizeBox.TextSize = fsSmall end
	if uiRefs.closeBtn then uiRefs.closeBtn.TextSize = fs end
	if uiRefs.minBtn then uiRefs.minBtn.TextSize = fs end
end

--// DRAG: MAIN
local function createDrag(target)
	target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = uiRefs.main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	target.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging and startPos then
			local delta = input.Position - dragStart
			uiRefs.main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// DRAG: MINI
local function createMiniDrag(btn)
	local mDragging, mDragInput, mDragStart, mStartPos = false, nil, nil, nil
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			mDragging = true
			mDragStart = input.Position
			mStartPos = btn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then mDragging = false end
			end)
		end
	end)
	btn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			mDragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == mDragInput and mDragging and mStartPos then
			local delta = input.Position - mDragStart
			btn.Position = UDim2.new(
				mStartPos.X.Scale, mStartPos.X.Offset + delta.X,
				mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// MINIMIZE
local function toggleMinimize()
	minimized = not minimized
	if minimized then
		uiRefs.main.Visible = false
		if not miniButton then
			miniButton = Instance.new("TextButton")
			miniButton.Name = "MiniMenu"
			miniButton.Parent = uiRefs.gui
			miniButton.Size = UDim2.fromOffset(50, 50)
			miniButton.Position = uiRefs.main.Position
			miniButton.BackgroundColor3 = THEME.accent
			miniButton.BorderSizePixel = 0
			miniButton.Text = "⚡"
			miniButton.TextColor3 = THEME.text
			miniButton.TextScaled = true
			miniButton.AutoButtonColor = false

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent = miniButton

			local grd = Instance.new("UIGradient")
			grd.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, THEME.accentGlow),
				ColorSequenceKeypoint.new(1, THEME.accentDim),
			})
			grd.Rotation = 135
			grd.Parent = miniButton

			local stroke = Instance.new("UIStroke")
			stroke.Color = THEME.accentGlow
			stroke.Thickness = 1.5
			stroke.Transparency = 0.3
			stroke.Parent = miniButton

			createMiniDrag(miniButton)

			miniButton.MouseButton1Click:Connect(function()
				minimized = false
				uiRefs.main.Visible = true
				if miniButton then miniButton:Destroy(); miniButton = nil end
			end)
		end
	else
		uiRefs.main.Visible = true
		if miniButton then miniButton:Destroy(); miniButton = nil end
	end
end

--// =========================
--// UI HELPERS
--// =========================
local function makeShadow(parent, offset, transparency)
	local sh = Instance.new("Frame")
	sh.Name = "Shadow"
	sh.Parent = parent
	sh.BackgroundColor3 = Color3.fromRGB(0,0,0)
	sh.BackgroundTransparency = transparency or 0.55
	sh.BorderSizePixel = 0
	sh.Size = UDim2.new(1, offset or 6, 1, offset or 6)
	sh.Position = UDim2.new(0, -(offset or 6)/2 + 2, 0, (offset or 6)/2)
	sh.ZIndex = parent.ZIndex - 1
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = sh
end

local function createToggleCard(parent, title, emoji, onChanged)
	local card = Instance.new("Frame")
	card.Parent = parent
	card.BackgroundColor3 = THEME.card
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, -10, 0, 56)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.border
	stroke.Thickness = 1
	stroke.Transparency = 0.3
	stroke.Parent = card

	-- left accent bar
	local accent = Instance.new("Frame")
	accent.Parent = card
	accent.BackgroundColor3 = THEME.accent
	accent.BorderSizePixel = 0
	accent.Size = UDim2.new(0, 3, 0.7, 0)
	accent.Position = UDim2.new(0, 0, 0.15, 0)
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 4)
	accentCorner.Parent = accent

	local header = Instance.new("Frame")
	header.Parent = card
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, -12, 0, 22)
	header.Position = UDim2.new(0, 10, 0, 5)

	-- emoji badge
	local badge = Instance.new("TextLabel")
	badge.Parent = header
	badge.BackgroundColor3 = THEME.surface
	badge.BorderSizePixel = 0
	badge.Size = UDim2.fromOffset(22, 22)
	badge.Position = UDim2.new(0, 0, 0, 0)
	badge.Font = Enum.Font.GothamBold
	badge.Text = emoji
	badge.TextColor3 = THEME.text
	badge.TextSize = 12
	badge.TextXAlignment = Enum.TextXAlignment.Center
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = badge

	local label = Instance.new("TextLabel")
	label.Parent = header
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -72, 1, 0)
	label.Position = UDim2.new(0, 28, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = title
	label.TextColor3 = THEME.text
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left

	-- TOGGLE SWITCH
	local toggle = Instance.new("TextButton")
	toggle.Parent = header
	toggle.Size = UDim2.fromOffset(40, 20)
	toggle.Position = UDim2.new(1, -40, 0, 1)
	toggle.BackgroundColor3 = THEME.surface
	toggle.BorderSizePixel = 0
	toggle.Text = ""
	toggle.AutoButtonColor = false

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(1, 0)
	tCorner.Parent = toggle

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = THEME.border
	tStroke.Thickness = 1
	tStroke.Transparency = 0.2
	tStroke.Parent = toggle

	local knob = Instance.new("Frame")
	knob.Parent = toggle
	knob.Size = UDim2.fromOffset(15, 15)
	knob.Position = UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = THEME.textDim
	knob.BorderSizePixel = 0
	local kCorner = Instance.new("UICorner")
	kCorner.CornerRadius = UDim.new(1, 0)
	kCorner.Parent = knob

	local state = false

	local function paint(s)
		if s then
			TweenService:Create(toggle, TweenInfo.new(0.18), {BackgroundColor3 = THEME.accent}):Play()
			TweenService:Create(knob, TweenInfo.new(0.18), {
				Position = UDim2.new(1, -18, 0.5, -7),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			}):Play()
			tStroke.Color = THEME.accent
			accent.BackgroundColor3 = THEME.green
			stroke.Color = THEME.accent
		else
			TweenService:Create(toggle, TweenInfo.new(0.18), {BackgroundColor3 = THEME.surface}):Play()
			TweenService:Create(knob, TweenInfo.new(0.18), {
				Position = UDim2.new(0, 3, 0.5, -7),
				BackgroundColor3 = THEME.textDim,
			}):Play()
			tStroke.Color = THEME.border
			accent.BackgroundColor3 = THEME.accent
			stroke.Color = THEME.border
		end
	end

	paint(state)

	toggle.MouseButton1Click:Connect(function()
		state = not state
		paint(state)
		onChanged(state)
	end)

	return card, function() return state end
end

local function createInput(parent, placeholder, widthScale, callback)
	local box = Instance.new("TextBox")
	box.Parent = parent
	box.BackgroundColor3 = THEME.surface
	box.BorderSizePixel = 0
	box.Size = widthScale and UDim2.new(widthScale, -3, 0, 20) or UDim2.new(1, 0, 0, 20)
	box.Font = Enum.Font.GothamBold
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = THEME.textMuted
	box.Text = ""
	box.TextColor3 = THEME.text
	box.TextSize = 9
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Center
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = box
	local s = Instance.new("UIStroke")
	s.Color = THEME.border
	s.Thickness = 1
	s.Transparency = 0.2
	s.Parent = box
	box.Focused:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), {Color = THEME.accent, Transparency = 0}):Play()
	end)
	box.FocusLost:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), {Color = THEME.border, Transparency = 0.2}):Play()
		callback(safeNum(box.Text, nil), box)
	end)
	return box
end

local function createTwoInputRow(parent, p1, p2, cb1, cb2)
	local row = Instance.new("Frame")
	row.Parent = parent
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -10, 0, 20)
	local layout = Instance.new("UIListLayout")
	layout.Parent = row
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	createInput(row, p1, 0.5, cb1)
	createInput(row, p2, 0.5, cb2)
	return row
end

local function createOneInputRow(parent, placeholder, cb)
	local row = Instance.new("Frame")
	row.Parent = parent
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -10, 0, 20)
	createInput(row, placeholder, nil, cb)
	return row
end

local function updateFlyStep()
	if not toggles.fly or not humanoid or not root or not flyBV or not flyBG then return end
	local move = humanoid.MoveDirection
	local speed = 45 * math.max(values.flySpeed, 1)
	local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z) end
	if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) end
	flatLook = flatLook.Unit
	flyBG.CFrame = CFrame.new(root.Position, root.Position + flatLook)
	flyBV.Velocity = (move.Magnitude > 0) and (move.Unit * speed) or Vector3.zero
end

local function ensureJumpReset()
	if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
		jumpUsed = 0
	end
end

--// =========================
--// BUILD UI
--// =========================
local gui = Instance.new("ScreenGui")
gui.Name = "SmartMenuV2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player:WaitForChild("PlayerGui")

-- SHADOW layer
local shadowFrame = Instance.new("Frame")
shadowFrame.Name = "Shadow"
shadowFrame.Parent = gui
shadowFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadowFrame.BackgroundTransparency = 0.5
shadowFrame.BorderSizePixel = 0
shadowFrame.Size = UDim2.fromOffset(220, 330)
shadowFrame.Position = UDim2.new(0.08, -6, 0.2, 6)
shadowFrame.ZIndex = 1
local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 14)
shadowCorner.Parent = shadowFrame

-- MAIN FRAME
local main = Instance.new("Frame")
main.Name = "Main"
main.Parent = gui
main.BackgroundColor3 = THEME.bg
main.BorderSizePixel = 0
main.Position = UDim2.new(0.08, 0, 0.2, 0)
main.Size = UDim2.fromOffset(210, 310)
main.Active = true
main.ZIndex = 2

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = THEME.border
mainStroke.Thickness = 1
mainStroke.Transparency = 0.1
mainStroke.Parent = main

-- Sync shadow to main position
main:GetPropertyChangedSignal("Position"):Connect(function()
	shadowFrame.Position = UDim2.new(
		main.Position.X.Scale,
		main.Position.X.Offset - 6,
		main.Position.Y.Scale,
		main.Position.Y.Offset + 6
	)
	shadowFrame.Size = UDim2.new(
		main.Size.X.Scale, main.Size.X.Offset + 12,
		main.Size.Y.Scale, main.Size.Y.Offset + 12
	)
end)
main:GetPropertyChangedSignal("Size"):Connect(function()
	shadowFrame.Size = UDim2.new(
		main.Size.X.Scale, main.Size.X.Offset + 12,
		main.Size.Y.Scale, main.Size.Y.Offset + 12
	)
end)

-- TOP GRADIENT HEADER
local topGrad = Instance.new("Frame")
topGrad.Name = "TopGrad"
topGrad.Parent = main
topGrad.BackgroundColor3 = THEME.topbar
topGrad.BorderSizePixel = 0
topGrad.Size = UDim2.new(1, 0, 0, 38)
topGrad.ZIndex = 3

local topGradCorner = Instance.new("UICorner")
topGradCorner.CornerRadius = UDim.new(0, 12)
topGradCorner.Parent = topGrad

local gradFix = Instance.new("Frame")
gradFix.BackgroundColor3 = THEME.topbar
gradFix.BorderSizePixel = 0
gradFix.Size = UDim2.new(1, 0, 0.5, 0)
gradFix.Position = UDim2.new(0, 0, 0.5, 0)
gradFix.Parent = topGrad
gradFix.ZIndex = 3

local topGradient = Instance.new("UIGradient")
topGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, THEME.accent),
	ColorSequenceKeypoint.new(0.5, THEME.accentDim),
	ColorSequenceKeypoint.new(1, THEME.bg),
})
topGradient.Rotation = 90
topGradient.Parent = topGrad

local topSepLine = Instance.new("Frame")
topSepLine.Parent = main
topSepLine.BackgroundColor3 = THEME.accent
topSepLine.BackgroundTransparency = 0.6
topSepLine.BorderSizePixel = 0
topSepLine.Size = UDim2.new(1, 0, 0, 1)
topSepLine.Position = UDim2.new(0, 0, 0, 38)
topSepLine.ZIndex = 4

-- TITLE ICON
local titleIcon = Instance.new("TextLabel")
titleIcon.Parent = topGrad
titleIcon.BackgroundTransparency = 1
titleIcon.Position = UDim2.new(0, 10, 0, 0)
titleIcon.Size = UDim2.new(0, 20, 1, 0)
titleIcon.Font = Enum.Font.GothamBold
titleIcon.Text = "⚡"
titleIcon.TextColor3 = THEME.text
titleIcon.TextSize = 13
titleIcon.TextXAlignment = Enum.TextXAlignment.Left
titleIcon.ZIndex = 5

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = topGrad
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 32, 0, 0)
title.Size = UDim2.new(1, -90, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "SMART MENU"
title.TextColor3 = THEME.text
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 5

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Parent = topGrad
closeBtn.Size = UDim2.fromOffset(18, 18)
closeBtn.Position = UDim2.new(1, -24, 0.5, -9)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 65, 65)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = true
closeBtn.ZIndex = 6
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

-- MIN BUTTON
local minBtn = Instance.new("TextButton")
minBtn.Name = "Minimize"
minBtn.Parent = topGrad
minBtn.Size = UDim2.fromOffset(18, 18)
minBtn.Position = UDim2.new(1, -46, 0.5, -9)
minBtn.BackgroundColor3 = Color3.fromRGB(230, 175, 40)
minBtn.BorderSizePixel = 0
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 11
minBtn.Font = Enum.Font.GothamBold
minBtn.AutoButtonColor = true
minBtn.ZIndex = 6
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(1, 0)
minCorner.Parent = minBtn

-- SIZE ROW
local sizeRow = Instance.new("Frame")
sizeRow.Name = "SizeRow"
sizeRow.Parent = main
sizeRow.BackgroundColor3 = THEME.surface
sizeRow.BorderSizePixel = 0
sizeRow.Position = UDim2.new(0, 6, 0, 44)
sizeRow.Size = UDim2.new(1, -12, 0, 26)
sizeRow.ZIndex = 3
local sizeRowCorner = Instance.new("UICorner")
sizeRowCorner.CornerRadius = UDim.new(0, 8)
sizeRowCorner.Parent = sizeRow
local sizeRowStroke = Instance.new("UIStroke")
sizeRowStroke.Color = THEME.border
sizeRowStroke.Thickness = 1
sizeRowStroke.Transparency = 0.3
sizeRowStroke.Parent = sizeRow

local sizeIcon = Instance.new("TextLabel")
sizeIcon.Parent = sizeRow
sizeIcon.BackgroundTransparency = 1
sizeIcon.Position = UDim2.new(0, 8, 0, 0)
sizeIcon.Size = UDim2.new(0, 14, 1, 0)
sizeIcon.Font = Enum.Font.GothamBold
sizeIcon.Text = "⊞"
sizeIcon.TextColor3 = THEME.accent
sizeIcon.TextSize = 10
sizeIcon.ZIndex = 4

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Parent = sizeRow
sizeLabel.BackgroundTransparency = 1
sizeLabel.Position = UDim2.new(0, 24, 0, 0)
sizeLabel.Size = UDim2.new(0.55, 0, 1, 0)
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.Text = "Menu Size"
sizeLabel.TextColor3 = THEME.textDim
sizeLabel.TextSize = 9
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.ZIndex = 4

local sizeBox = Instance.new("TextBox")
sizeBox.Name = "SizeBox"
sizeBox.Parent = sizeRow
sizeBox.BackgroundColor3 = THEME.card
sizeBox.BorderSizePixel = 0
sizeBox.Position = UDim2.new(1, -52, 0.5, -9)
sizeBox.Size = UDim2.fromOffset(46, 18)
sizeBox.Font = Enum.Font.GothamBold
sizeBox.PlaceholderText = "1–10"
sizeBox.Text = "10"
sizeBox.TextColor3 = THEME.accent
sizeBox.TextSize = 10
sizeBox.ClearTextOnFocus = false
sizeBox.TextXAlignment = Enum.TextXAlignment.Center
sizeBox.ZIndex = 4
local sizeBoxCorner = Instance.new("UICorner")
sizeBoxCorner.CornerRadius = UDim.new(0, 6)
sizeBoxCorner.Parent = sizeBox
local sizeBoxStroke = Instance.new("UIStroke")
sizeBoxStroke.Color = THEME.accent
sizeBoxStroke.Thickness = 1
sizeBoxStroke.Transparency = 0.4
sizeBoxStroke.Parent = sizeBox

-- DIVIDER
local divider = Instance.new("Frame")
divider.Parent = main
divider.BackgroundColor3 = THEME.border
divider.BackgroundTransparency = 0.6
divider.BorderSizePixel = 0
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 74)
divider.ZIndex = 3

-- SCROLL
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Parent = main
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Position = UDim2.new(0, 0, 0, 78)
scroll.Size = UDim2.new(1, 0, 1, -78)
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = THEME.accent
scroll.ScrollBarImageTransparency = 0.3
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ZIndex = 3

local list = Instance.new("UIListLayout")
list.Parent = scroll
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 6)

local pad = Instance.new("UIPadding")
pad.Parent = scroll
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingLeft = UDim.new(0, 5)
pad.PaddingRight = UDim.new(0, 5)
pad.PaddingBottom = UDim.new(0, 6)

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12)
end)

uiRefs = {
	gui       = gui,
	main      = main,
	top       = topGrad,
	sizeRow   = sizeRow,
	scroll    = scroll,
	title     = title,
	sizeLabel = sizeLabel,
	sizeBox   = sizeBox,
	closeBtn  = closeBtn,
	minBtn    = minBtn,
}

createDrag(topGrad)

--// =========================
--// CARDS
--// =========================
do
	local card = createToggleCard(scroll, "วิ่งไว", "🏃🏻", function(state)
		setToggleState("speed", state)
	end)
	createOneInputRow(card, "× speed  (default 1)", function(n)
		if n then
			values.speed = math.max(0, n)
			refreshSpeed()
		end
	end)
	card.Size = UDim2.new(1, -10, 0, 80)
end

do
	local card = createToggleCard(scroll, "กระโดด", "🤸🏻", function(state)
		setToggleState("jump", state)
		jumpUsed = 0
	end)
	createTwoInputRow(
		card,
		"jump power",
		"count",
		function(n) if n then values.jumpPower = math.max(0, n); refreshJump() end end,
		function(n) if n then values.jumpCount = math.max(1, math.floor(n)) end end
	)
	card.Size = UDim2.new(1, -10, 0, 80)
end

do
	local card = createToggleCard(scroll, "ทะลุกำแพง", "🌚", function(state)
		setToggleState("noclip", state)
	end)
	card.Size = UDim2.new(1, -10, 0, 56)
end

do
	local card = createToggleCard(scroll, "บิน", "💨", function(state)
		setToggleState("fly", state)
	end)
	createOneInputRow(card, "fly speed  (default 1)", function(n)
		if n then values.flySpeed = math.max(0, n) end
	end)
	card.Size = UDim2.new(1, -10, 0, 80)
end

do
	local card = createToggleCard(scroll, "ลอย", "☁️", function(state)
		setToggleState("float", state)
	end)
	createOneInputRow(card, "offset height", function(n)
		if n then
			values.floatOffset = n
			if toggles.float then refreshFloat() end
		end
	end)
	card.Size = UDim2.new(1, -10, 0, 80)
end

--// =========================
--// BUTTON LOGIC
--// =========================
closeBtn.MouseButton1Click:Connect(function()
	stopFly()
	gui:Destroy()
	shadowFrame:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
	toggleMinimize()
end)

sizeBox.FocusLost:Connect(function()
	local n = clampMenuScale(sizeBox.Text)
	values.menuSize = n
	sizeBox.Text = tostring(n)
	updateMenuScale(n)
end)

updateMenuScale(10)
sizeBox.Text = "10"

--// =========================
--// CHARACTER HOOKS
--// =========================
player.CharacterAdded:Connect(function(c)
	setCharacter(c)
	task.wait(0.2)
	if toggles.noclip then applyNoclip(true) end
	if toggles.float then refreshFloat() end
	if toggles.fly then applyFlyObjects() end
end)

if player.Character then
	setCharacter(player.Character)
end

UIS.JumpRequest:Connect(function()
	if not toggles.jump then return end
	if not humanoid or not root then return end
	refreshJump()
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		jumpUsed = 1
		humanoid.Jump = true
		return
	end
	if jumpUsed < math.max(1, math.floor(values.jumpCount)) then
		jumpUsed += 1
		root.AssemblyLinearVelocity = Vector3.new(
			root.AssemblyLinearVelocity.X,
			values.jumpPower,
			root.AssemblyLinearVelocity.Z
		)
	end
end)

--// =========================
--// MAIN LOOP
--// =========================
RunService.RenderStepped:Connect(function()
	if not player.Character then return end
	if not humanoid or not root then return end
	camera = workspace.CurrentCamera or camera

	if toggles.speed then refreshSpeed() end
	if toggles.jump then refreshJump(); ensureJumpReset() end
	if toggles.noclip then applyNoclip(true) end

	if toggles.float then
		if floatOrigin == nil then
			floatOrigin = root.Position
			floatTargetPos = floatOrigin + Vector3.new(0, values.floatOffset, 0)
		end
		if not root.Anchored then root.Anchored = true end
		if floatTargetPos == nil then
			floatTargetPos = root.Position + Vector3.new(0, values.floatOffset, 0)
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.new(floatTargetPos, floatTargetPos + root.CFrame.LookVector)
	else
		if root.Anchored then root.Anchored = false end
	end

	if toggles.fly and not toggles.float then
		if not flyBV or not flyBG then applyFlyObjects() end
		updateFlyStep()
	else
		if toggles.fly == false then stopFly() end
	end
end)
