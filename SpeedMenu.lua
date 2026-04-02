--// ===== SETTINGS SAVE =====
_G.AIM_SETTINGS = _G.AIM_SETTINGS or {
	offset = {0,0,0,0,0,0},
	distance = 200,
	mode = "Monster"
}

--// ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

--// ===== STATE =====
local lockEnabled = false
local currentTarget = nil
local selectedTarget = nil

local targetMode = _G.AIM_SETTINGS.mode
local offsets = _G.AIM_SETTINGS.offset
local scanDistance = _G.AIM_SETTINGS.distance

--// ===== TARGET =====
local function isAlive(m)
	local h = m and m:FindFirstChild("Humanoid")
	return h and h.Health > 0
end

local function getRoot(m)
	return m:FindFirstChild("HumanoidRootPart")
end

local function isValid(m)
	local plr = Players:GetPlayerFromCharacter(m)
	if targetMode == "Player" then
		return plr and plr ~= player and isAlive(m)
	else
		return not plr and isAlive(m)
	end
end

local function getClosest(root)
	local best, dist = nil, math.huge

	if targetMode == "Player" then
		for _,plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and isAlive(plr.Character) then
				local part = getRoot(plr.Character)
				if part then
					local d = (part.Position-root.Position).Magnitude
					if d < dist then
						dist = d
						best = plr.Character
					end
				end
			end
		end
	else
		for _,m in pairs(workspace:GetDescendants()) do
			if m:IsA("Model") and isValid(m) then
				local part = getRoot(m)
				if part then
					local d = (part.Position-root.Position).Magnitude
					if d < dist then
						dist = d
						best = m
					end
				end
			end
		end
	end

	return best
end

--// ===== LOCK =====
RunService.RenderStepped:Connect(function()
	if not lockEnabled then return end

	local char = getChar()
	local root = getRoot(char)
	if not root then return end

	if selectedTarget and isAlive(selectedTarget) then
		currentTarget = selectedTarget
	else
		currentTarget = getClosest(root)
	end

	if not currentTarget then return end

	local part = getRoot(currentTarget)
	if not part then return end

	local aim = part.Position + Vector3.new(offsets[1], offsets[2], offsets[3])
	local camPos = root.Position + Vector3.new(offsets[4], offsets[5], offsets[6])

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(camPos, aim)
end)

--// ===== UI =====
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ===== COLORS =====
local C = {
	BLACK      = Color3.fromRGB(8, 8, 8),
	DARK       = Color3.fromRGB(18, 18, 18),
	PANEL      = Color3.fromRGB(24, 24, 24),
	BORDER     = Color3.fromRGB(55, 55, 55),
	WHITE      = Color3.fromRGB(255, 255, 255),
	LIGHTGRAY  = Color3.fromRGB(180, 180, 180),
	MIDGRAY    = Color3.fromRGB(100, 100, 100),
	ACCENT     = Color3.fromRGB(220, 220, 220),
	ON         = Color3.fromRGB(255, 255, 255),
	OFF        = Color3.fromRGB(50, 50, 50),
}

-- ===== HELPERS =====
local function corner(r, p)
	local c = Instance.new("UICorner", p)
	c.CornerRadius = UDim.new(0, r)
	return c
end

local function stroke(p, thick, col, trans)
	local s = Instance.new("UIStroke", p)
	s.Thickness = thick or 1
	s.Color = col or C.BORDER
	s.Transparency = trans or 0
	return s
end

local function tween(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function hoverEffect(btn, normalCol, hoverCol)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.15, {BackgroundColor3 = hoverCol})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, {BackgroundColor3 = normalCol})
	end)
end

-- ===== MAIN FRAME =====
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 250, 0, 320)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
mainFrame.BackgroundColor3 = C.DARK
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
corner(10, mainFrame)
stroke(mainFrame, 1, C.BORDER)

-- ===== TITLE BAR =====
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = C.BLACK
titleBar.BorderSizePixel = 0
corner(10, titleBar)

-- Fix bottom corners of titleBar
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = C.BLACK
titleFix.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "◈  AIM CONTROL"
titleLabel.TextColor3 = C.WHITE
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
closeBtn.Text = "✕"
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.TextColor3 = C.LIGHTGRAY
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
corner(6, closeBtn)

closeBtn.MouseButton1Click:Connect(function()
	tween(mainFrame, 0.2, {Size = UDim2.new(0, 250, 0, 0)})
	task.delay(0.25, function() mainFrame.Visible = false end)
end)
hoverEffect(closeBtn, Color3.fromRGB(40,40,40), Color3.fromRGB(200,50,50))

-- Collapse Button
local collapseBtn = Instance.new("TextButton", titleBar)
collapseBtn.Size = UDim2.new(0, 26, 0, 26)
collapseBtn.Position = UDim2.new(1, -64, 0.5, -13)
collapseBtn.Text = "—"
collapseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
collapseBtn.TextColor3 = C.LIGHTGRAY
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 11
corner(6, collapseBtn)

local collapsed = false
local fullHeight = 320

collapseBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	if collapsed then
		tween(mainFrame, 0.25, {Size = UDim2.new(0, 250, 0, 38)})
		collapseBtn.Text = "+"
	else
		tween(mainFrame, 0.25, {Size = UDim2.new(0, 250, 0, fullHeight)})
		collapseBtn.Text = "—"
	end
end)
hoverEffect(collapseBtn, Color3.fromRGB(40,40,40), Color3.fromRGB(60,60,60))

-- ===== SCROLL CONTENT =====
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, 0, 1, -38)
scroll.Position = UDim2.new(0, 0, 0, 38)
scroll.CanvasSize = UDim2.new(0, 0, 0, 500)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.BORDER
scroll.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local padding = Instance.new("UIPadding", scroll)
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)

-- Auto resize canvas
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
end)

-- ===== SECTION LABEL =====
local function sectionLabel(text)
	local lbl = Instance.new("TextLabel", scroll)
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = C.MIDGRAY
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = 0
	return lbl
end

-- ===== TOGGLE BUTTON =====
local function toggleBtn(text, order)
	local container = Instance.new("Frame", scroll)
	container.Size = UDim2.new(1, 0, 0, 38)
	container.BackgroundColor3 = C.PANEL
	container.BorderSizePixel = 0
	container.LayoutOrder = order
	corner(8, container)
	stroke(container, 1, C.BORDER)

	local btn = Instance.new("TextButton", container)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.BorderSizePixel = 0

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = C.ACCENT
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	-- Toggle pill
	local pill = Instance.new("Frame", container)
	pill.Size = UDim2.new(0, 36, 0, 20)
	pill.Position = UDim2.new(1, -48, 0.5, -10)
	pill.BackgroundColor3 = C.OFF
	pill.BorderSizePixel = 0
	corner(10, pill)
	stroke(pill, 1, C.BORDER)

	local knob = Instance.new("Frame", pill)
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = C.MIDGRAY
	knob.BorderSizePixel = 0
	corner(7, knob)

	local isOn = false

	local function setState(v)
		isOn = v
		if isOn then
			tween(pill, 0.2, {BackgroundColor3 = C.WHITE})
			tween(knob, 0.2, {Position = UDim2.new(0, 19, 0.5, -7), BackgroundColor3 = C.BLACK})
			tween(lbl, 0.15, {TextColor3 = C.WHITE})
		else
			tween(pill, 0.2, {BackgroundColor3 = C.OFF})
			tween(knob, 0.2, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = C.MIDGRAY})
			tween(lbl, 0.15, {TextColor3 = C.ACCENT})
		end
	end

	btn.MouseButton1Click:Connect(function()
		setState(not isOn)
	end)

	hoverEffect(container, C.PANEL, Color3.fromRGB(32,32,32))

	return btn, setState, isOn
end

-- ===== ACTION BUTTON =====
local function actionBtn(text, order)
	local btn = Instance.new("TextButton", scroll)
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = C.PANEL
	btn.Text = text
	btn.TextColor3 = C.ACCENT
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.LayoutOrder = order
	corner(8, btn)
	stroke(btn, 1, C.BORDER)
	hoverEffect(btn, C.PANEL, Color3.fromRGB(38,38,38))
	return btn
end

-- ===== INPUT BOX =====
local function inputBox(labelText, defaultVal, order)
	local container = Instance.new("Frame", scroll)
	container.Size = UDim2.new(1, 0, 0, 48)
	container.BackgroundColor3 = C.PANEL
	container.BorderSizePixel = 0
	container.LayoutOrder = order
	corner(8, container)
	stroke(container, 1, C.BORDER)

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(1, -12, 0, 18)
	lbl.Position = UDim2.new(0, 12, 0, 4)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = C.MIDGRAY
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local box = Instance.new("TextBox", container)
	box.Size = UDim2.new(1, -24, 0, 22)
	box.Position = UDim2.new(0, 12, 0, 22)
	box.BackgroundTransparency = 1
	box.Text = tostring(defaultVal)
	box.TextColor3 = C.WHITE
	box.PlaceholderText = "Enter value..."
	box.PlaceholderColor3 = C.BORDER
	box.Font = Enum.Font.GothamBold
	box.TextSize = 13
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0

	box.Focused:Connect(function()
		tween(container, 0.15, {BackgroundColor3 = Color3.fromRGB(30,30,30)})
		stroke(container, 1, C.WHITE)
	end)
	box.FocusLost:Connect(function()
		tween(container, 0.15, {BackgroundColor3 = C.PANEL})
		stroke(container, 1, C.BORDER)
	end)

	return box
end

-- ===== DIVIDER =====
local function divider(order)
	local d = Instance.new("Frame", scroll)
	d.Size = UDim2.new(1, 0, 0, 1)
	d.BackgroundColor3 = C.BORDER
	d.BorderSizePixel = 0
	d.LayoutOrder = order
	return d
end

-- ===== BUILD UI =====

-- Lock Toggle
sectionLabel("LOCK"):LayoutOrder = 1
local lockClickBtn, setLockState = toggleBtn("Lock-On", 2)
lockClickBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	setLockState(lockEnabled)
end)

divider(3)

-- Mode
sectionLabel("TARGET MODE"):LayoutOrder = 4
local modeBtn = actionBtn("◎  Mode: " .. targetMode, 5)
modeBtn.MouseButton1Click:Connect(function()
	targetMode = targetMode == "Monster" and "Player" or "Monster"
	modeBtn.Text = "◎  Mode: " .. targetMode
	_G.AIM_SETTINGS.mode = targetMode
end)

divider(6)

-- Distance
sectionLabel("SCAN DISTANCE"):LayoutOrder = 7
local distBox = inputBox("Distance", scanDistance, 8)
distBox.FocusLost:Connect(function()
	local v = tonumber(distBox.Text:match("-?%d+%.?%d*"))
	if v then
		scanDistance = v
		_G.AIM_SETTINGS.distance = v
	end
end)

divider(9)

-- Offsets
sectionLabel("AIM OFFSETS"):LayoutOrder = 10
local names = {"Aim X", "Aim Y", "Aim Z", "Cam X", "Cam Y", "Cam Z"}
for i = 1, 6 do
	local box = inputBox(names[i], offsets[i], 10 + i)
	box.FocusLost:Connect(function()
		local v = tonumber(box.Text:match("-?%d+%.?%d*"))
		if v then
			offsets[i] = v
			_G.AIM_SETTINGS.offset = offsets
		end
	end)
end

divider(17)

-- Open Scan
sectionLabel("SCANNER"):LayoutOrder = 18
local scanToggleBtn = actionBtn("◈  Open Scanner", 19)

-- ===== SCAN GUI =====
local scanGui = Instance.new("Frame", gui)
scanGui.Size = UDim2.new(0, 220, 0, 280)
scanGui.Position = UDim2.new(0, 280, 0.5, -140)
scanGui.BackgroundColor3 = C.DARK
scanGui.BorderSizePixel = 0
scanGui.Visible = false
corner(10, scanGui)
stroke(scanGui, 1, C.BORDER)

-- Scan Title Bar
local scanTitle = Instance.new("Frame", scanGui)
scanTitle.Size = UDim2.new(1, 0, 0, 38)
scanTitle.BackgroundColor3 = C.BLACK
scanTitle.BorderSizePixel = 0
corner(10, scanTitle)

local scanTitleFix = Instance.new("Frame", scanTitle)
scanTitleFix.Size = UDim2.new(1, 0, 0.5, 0)
scanTitleFix.Position = UDim2.new(0, 0, 0.5, 0)
scanTitleFix.BackgroundColor3 = C.BLACK
scanTitleFix.BorderSizePixel = 0

local scanTitleLbl = Instance.new("TextLabel", scanTitle)
scanTitleLbl.Size = UDim2.new(1, -50, 1, 0)
scanTitleLbl.Position = UDim2.new(0, 14, 0, 0)
scanTitleLbl.BackgroundTransparency = 1
scanTitleLbl.Text = "◈  SCANNER"
scanTitleLbl.TextColor3 = C.WHITE
scanTitleLbl.Font = Enum.Font.GothamBold
scanTitleLbl.TextSize = 12
scanTitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local scanCloseBtn = Instance.new("TextButton", scanTitle)
scanCloseBtn.Size = UDim2.new(0, 26, 0, 26)
scanCloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
scanCloseBtn.Text = "✕"
scanCloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scanCloseBtn.TextColor3 = C.LIGHTGRAY
scanCloseBtn.Font = Enum.Font.GothamBold
scanCloseBtn.TextSize = 11
corner(6, scanCloseBtn)
scanCloseBtn.MouseButton1Click:Connect(function()
	scanGui.Visible = false
end)
hoverEffect(scanCloseBtn, Color3.fromRGB(40,40,40), Color3.fromRGB(200,50,50))

-- Scan Button
local scanNow = Instance.new("TextButton", scanGui)
scanNow.Size = UDim2.new(1, -24, 0, 34)
scanNow.Position = UDim2.new(0, 12, 1, -46)
scanNow.Text = "⟳  SCAN NOW"
scanNow.BackgroundColor3 = C.WHITE
scanNow.TextColor3 = C.BLACK
scanNow.Font = Enum.Font.GothamBold
scanNow.TextSize = 12
scanNow.BorderSizePixel = 0
corner(8, scanNow)
hoverEffect(scanNow, C.WHITE, C.ACCENT)

-- List
local list = Instance.new("ScrollingFrame", scanGui)
list.Size = UDim2.new(1, -24, 1, -96)
list.Position = UDim2.new(0, 12, 0, 48)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = C.BORDER
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new(0, 0, 0, 0)

local listLayout = Instance.new("UIListLayout", list)
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

scanToggleBtn.MouseButton1Click:Connect(function()
	scanGui.Visible = not scanGui.Visible
end)

scanNow.MouseButton1Click:Connect(function()
	-- Animate button
	tween(scanNow, 0.1, {BackgroundColor3 = C.MIDGRAY})
	task.delay(0.15, function()
		tween(scanNow, 0.1, {BackgroundColor3 = C.WHITE})
	end)

	list:ClearAllChildren()
	listLayout = Instance.new("UIListLayout", list)
	listLayout.Padding = UDim.new(0, 4)

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	local char = getChar()
	local root = getRoot(char)
	if not root then return end

	local count = 0
	for _, m in pairs(workspace:GetDescendants()) do
		if m:IsA("Model") and isValid(m) then
			local part = getRoot(m)
			if part then
				local dist = (part.Position - root.Position).Magnitude
				if dist <= scanDistance then
					count += 1
					local item = Instance.new("TextButton", list)
					item.Size = UDim2.new(1, 0, 0, 32)
					item.BackgroundColor3 = C.PANEL
					item.Text = ""
					item.BorderSizePixel = 0
					item.LayoutOrder = count
					corner(6, item)
					stroke(item, 1, C.BORDER)

					local nameLbl = Instance.new("TextLabel", item)
					nameLbl.Size = UDim2.new(1, -60, 1, 0)
					nameLbl.Position = UDim2.new(0, 10, 0, 0)
					nameLbl.BackgroundTransparency = 1
					nameLbl.Text = m.Name
					nameLbl.TextColor3 = C.ACCENT
					nameLbl.Font = Enum.Font.Gotham
					nameLbl.TextSize = 11
					nameLbl.TextXAlignment = Enum.TextXAlignment.Left
					nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

					local distLbl = Instance.new("TextLabel", item)
					distLbl.Size = UDim2.new(0, 50, 1, 0)
					distLbl.Position = UDim2.new(1, -55, 0, 0)
					distLbl.BackgroundTransparency = 1
					distLbl.Text = math.floor(dist) .. "m"
					distLbl.TextColor3 = C.MIDGRAY
					distLbl.Font = Enum.Font.GothamBold
					distLbl.TextSize = 10
					distLbl.TextXAlignment = Enum.TextXAlignment.Right

					hoverEffect(item, C.PANEL, Color3.fromRGB(35,35,35))

					item.MouseButton1Click:Connect(function()
						selectedTarget = m
						-- Flash selected
						tween(item, 0.1, {BackgroundColor3 = C.WHITE})
						tween(nameLbl, 0.1, {TextColor3 = C.BLACK})
						task.delay(0.2, function()
							tween(item, 0.15, {BackgroundColor3 = C.PANEL})
							tween(nameLbl, 0.15, {TextColor3 = C.ACCENT})
						end)
					end)
				end
			end
		end
	end

	if count == 0 then
		local empty = Instance.new("TextLabel", list)
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Text = "No targets found"
		empty.TextColor3 = C.MIDGRAY
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 12
	end
end)

-- ===== DRAG: MAIN FRAME =====
local dragging, dragStart, startPos

titleBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = mainFrame.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local delta = i.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ===== DRAG: SCAN GUI =====
local sDragging, sDragStart, sSPos

scanTitle.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sDragging = true
		sDragStart = i.Position
		sSPos = scanGui.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if sDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local delta = i.Position - sDragStart
		scanGui.Position = UDim2.new(
			sSPos.X.Scale, sSPos.X.Offset + delta.X,
			sSPos.Y.Scale, sSPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sDragging = false
	end
end)

-- ===== REOPEN BUTTON (when closed) =====
local reopenBtn = Instance.new("TextButton", gui)
reopenBtn.Size = UDim2.new(0, 38, 0, 38)
reopenBtn.Position = UDim2.new(0, 12, 0.5, -19)
reopenBtn.Text = "◈"
reopenBtn.BackgroundColor3 = C.BLACK
reopenBtn.TextColor3 = C.WHITE
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 18
reopenBtn.BorderSizePixel = 0
reopenBtn.Visible = false
corner(8, reopenBtn)
stroke(reopenBtn, 1, C.BORDER)

reopenBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	reopenBtn.Visible = false
	tween(mainFrame, 0.25, {Size = UDim2.new(0, 250, 0, 320)})
end)

closeBtn.MouseButton1Click:Connect(function()
	task.delay(0.3, function() reopenBtn.Visible = true end)
end)

print("✓ AIM CONTROL UI Loaded")
