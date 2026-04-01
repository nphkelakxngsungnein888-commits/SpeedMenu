--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// GUI ROOT
local gui = Instance.new("ScreenGui")
gui.Name = "LockGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = game.CoreGui

--// STATE
local lockEnabled = false
local lockNearest = false
local lockMode = "Player"
local lockedTarget = nil
local lockConn = nil
local scanEnabled = false

local lockStrength = 1
local detectionRange = 500
local mainScale = 10
local scanScale = 10

local selectedColors = {}
local teamColorMap = {}

--// UTILS
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	return char, char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Head")
end

local function getRoot(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

local function isAlive(model)
	local h = model and model:FindFirstChildOfClass("Humanoid")
	return h and h.Health > 0
end

local function getDistance(model)
	local char = player.Character
	if not char then return math.huge end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local root = getRoot(model)
	if not hrp or not root then return math.huge end
	return (hrp.Position - root.Position).Magnitude
end

--// BUILD TARGET LIST
local function buildTargetList()
	local list = {}
	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and isAlive(p.Character) then
				local d = getDistance(p.Character)
				if d <= detectionRange then
					table.insert(list, { model = p.Character, name = p.Name, team = p.Team, isPlayer = true })
				end
			end
		end
	else
		local playerChars = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then playerChars[p.Character] = true end
		end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model")
				and not playerChars[obj]
				and obj:FindFirstChildOfClass("Humanoid")
				and obj:FindFirstChild("HumanoidRootPart")
				and isAlive(obj)
			then
				local d = getDistance(obj)
				if d <= detectionRange then
					table.insert(list, { model = obj, name = obj.Name, team = nil, isPlayer = false })
				end
			end
		end
	end
	return list
end

--// GET FRONT TARGET
local function getFrontTarget(list)
	local best, bestDot = nil, -math.huge
	local camCF = camera.CFrame
	for _, t in ipairs(list) do
		local root = getRoot(t.model)
		if root then
			local dir = (root.Position - camCF.Position).Unit
			local dot = camCF.LookVector:Dot(dir)
			if dot > bestDot then
				bestDot = dot
				best = t
			end
		end
	end
	return best
end

local function getNearestTarget(list)
	local best, bestDist = nil, math.huge
	for _, t in ipairs(list) do
		local d = getDistance(t.model)
		if d < bestDist then
			bestDist = d
			best = t
		end
	end
	return best
end

--// LOCK LOGIC
local function startLock()
	if lockConn then lockConn:Disconnect() end

	local list = buildTargetList()
	if lockNearest then
		lockedTarget = getNearestTarget(list)
	else
		lockedTarget = getFrontTarget(list)
	end

	lockConn = RunService.RenderStepped:Connect(function()
		if not lockEnabled then return end
		local ok, char, hrp, head = pcall(getChar)
		if not ok or not hrp then return end

		if not lockedTarget or not isAlive(lockedTarget.model) then
			local newList = buildTargetList()
			lockedTarget = getNearestTarget(newList)
			if not lockedTarget then return end
		end

		local root = getRoot(lockedTarget.model)
		if not root then
			lockedTarget = nil
			return
		end

		local targetPos = root.Position
		local myPos = hrp.Position

		local flat = (targetPos - myPos) * Vector3.new(1, 0, 1)
		if flat.Magnitude > 0.1 then
			local alpha = math.clamp(lockStrength * 0.1, 0.01, 1)
			local newCF = CFrame.lookAt(myPos, myPos + flat)
			hrp.CFrame = hrp.CFrame:Lerp(newCF, alpha)
		end
	end)
end

local function stopLock()
	if lockConn then lockConn:Disconnect() lockConn = nil end
	lockedTarget = nil
end

--// ==================== UI BUILDER ====================

local FONT = Enum.Font.GothamBold
local FONT_LIGHT = Enum.Font.Gotham

local COLOR_BG = Color3.fromRGB(12, 12, 12)
local COLOR_PANEL = Color3.fromRGB(20, 20, 20)
local COLOR_BORDER = Color3.fromRGB(50, 50, 50)
local COLOR_WHITE = Color3.fromRGB(240, 240, 240)
local COLOR_GRAY = Color3.fromRGB(140, 140, 140)
local COLOR_ACCENT = Color3.fromRGB(220, 220, 220)
local COLOR_ON = Color3.fromRGB(200, 200, 200)
local COLOR_OFF = Color3.fromRGB(60, 60, 60)
local COLOR_BTN = Color3.fromRGB(30, 30, 30)
local COLOR_BTN_HOVER = Color3.fromRGB(45, 45, 45)

local function addCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 6)
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or COLOR_BORDER
	s.Thickness = thickness or 1
end

local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart, startPos

	local function input(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end

	handle.InputBegan:Connect(input)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local function makeLabel(parent, text, size, color, font)
	local l = Instance.new("TextLabel", parent)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 13
	l.TextColor3 = color or COLOR_WHITE
	l.Font = font or FONT_LIGHT
	l.TextXAlignment = Enum.TextXAlignment.Left
	return l
end

local function makeInput(parent, defaultVal, placeholder)
	local box = Instance.new("TextBox", parent)
	box.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	box.TextColor3 = COLOR_WHITE
	box.PlaceholderText = placeholder or ""
	box.Text = tostring(defaultVal)
	box.Font = FONT_LIGHT
	box.TextSize = 12
	box.ClearTextOnFocus = false
	addCorner(box, 4)
	addStroke(box, COLOR_BORDER)
	return box
end

local function makeButton(parent, text, onClick)
	local btn = Instance.new("TextButton", parent)
	btn.BackgroundColor3 = COLOR_BTN
	btn.TextColor3 = COLOR_WHITE
	btn.Text = text
	btn.Font = FONT
	btn.TextSize = 12
	btn.AutoButtonColor = false
	addCorner(btn, 5)
	addStroke(btn, COLOR_BORDER)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = COLOR_BTN_HOVER }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = COLOR_BTN }):Play()
	end)
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function makeToggleBtn(parent, label, initState, onChange)
	local row = Instance.new("Frame", parent)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 32)

	local lbl = makeLabel(row, label, 12, COLOR_GRAY)
	lbl.Size = UDim2.new(1, -50, 1, 0)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.TextYAlignment = Enum.TextYAlignment.Center

	local track = Instance.new("Frame", row)
	track.Size = UDim2.new(0, 40, 0, 20)
	track.Position = UDim2.new(1, -44, 0.5, -10)
	track.BackgroundColor3 = initState and COLOR_ON or COLOR_OFF
	addCorner(track, 10)

	local knob = Instance.new("Frame", track)
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = initState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = COLOR_WHITE
	addCorner(knob, 7)

	local state = initState
	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.MouseButton1Click:Connect(function()
		state = not state
		TweenService:Create(track, TweenInfo.new(0.2), { BackgroundColor3 = state and COLOR_ON or COLOR_OFF }):Play()
		TweenService:Create(knob, TweenInfo.new(0.2), {
			Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
		}):Play()
		onChange(state)
	end)

	return row, function() return state end
end

local function makeInputRow(parent, label, defaultVal, onChanged)
	local row = Instance.new("Frame", parent)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 32)

	local lbl = makeLabel(row, label, 12, COLOR_GRAY)
	lbl.Size = UDim2.new(1, -70, 1, 0)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.TextYAlignment = Enum.TextYAlignment.Center

	local box = makeInput(row, defaultVal, "")
	box.Size = UDim2.new(0, 60, 0, 22)
	box.Position = UDim2.new(1, -62, 0.5, -11)
	box.TextXAlignment = Enum.TextXAlignment.Center

	box.FocusLost:Connect(function()
		local v = tonumber(box.Text)
		if v then onChanged(v) end
	end)
	return row
end

local function makeSeparator(parent)
	local f = Instance.new("Frame", parent)
	f.BackgroundColor3 = COLOR_BORDER
	f.Size = UDim2.new(1, 0, 0, 1)
	f.BorderSizePixel = 0
	return f
end

--// ==================== MAIN WINDOW ====================

local function buildScaleSize(scale)
	local base = scale * 14
	return UDim2.new(0, math.max(base * 12, 150), 0, 0)
end

local mainWin = Instance.new("Frame", gui)
mainWin.BackgroundColor3 = COLOR_BG
mainWin.Position = UDim2.new(0, 20, 0, 80)
mainWin.Size = UDim2.new(0, 180, 0, 0)
mainWin.AutomaticSize = Enum.AutomaticSize.Y
mainWin.ClipsDescendants = true
addCorner(mainWin, 8)
addStroke(mainWin, COLOR_BORDER, 1)

-- Shadow
local shadow = Instance.new("Frame", mainWin)
shadow.Size = UDim2.new(1, 12, 1, 12)
shadow.Position = UDim2.new(0, -6, 0, -6)
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.6
shadow.ZIndex = mainWin.ZIndex - 1
addCorner(shadow, 10)
shadow.ZIndex = 0

local mainLayout = Instance.new("UIListLayout", mainWin)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0, 0)

local mainPad = Instance.new("UIPadding", mainWin)
mainPad.PaddingLeft = UDim.new(0, 0)
mainPad.PaddingRight = UDim.new(0, 0)

-- TITLE BAR
local titleBar = Instance.new("Frame", mainWin)
titleBar.BackgroundColor3 = COLOR_PANEL
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.LayoutOrder = 0

local titleLabel = makeLabel(titleBar, "  ◈  LOCK", 13, COLOR_WHITE, FONT)
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.TextYAlignment = Enum.TextYAlignment.Center

-- Scale input
local scaleBox = makeInput(titleBar, tostring(mainScale), "10")
scaleBox.Size = UDim2.new(0, 28, 0, 20)
scaleBox.Position = UDim2.new(1, -62, 0.5, -10)
scaleBox.TextXAlignment = Enum.TextXAlignment.Center
scaleBox.FocusLost:Connect(function()
	local v = tonumber(scaleBox.Text)
	if v then
		mainScale = v
		local w = math.max(v * 18, 150)
		mainWin.Size = UDim2.new(0, w, 0, 0)
	end
end)

local collapseBtn = Instance.new("TextButton", titleBar)
collapseBtn.Size = UDim2.new(0, 20, 0, 20)
collapseBtn.Position = UDim2.new(1, -32, 0.5, -10)
collapseBtn.BackgroundTransparency = 1
collapseBtn.Text = "─"
collapseBtn.TextColor3 = COLOR_GRAY
collapseBtn.Font = FONT
collapseBtn.TextSize = 14

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -10, 0.5, -10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = COLOR_GRAY
closeBtn.Font = FONT
closeBtn.TextSize = 13

makeDraggable(mainWin, titleBar)

-- BODY
local body = Instance.new("Frame", mainWin)
body.BackgroundTransparency = 1
body.Size = UDim2.new(1, 0, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.LayoutOrder = 1

local bodyLayout = Instance.new("UIListLayout", body)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Padding = UDim.new(0, 2)

local bodyPad = Instance.new("UIPadding", body)
bodyPad.PaddingLeft = UDim.new(0, 10)
bodyPad.PaddingRight = UDim.new(0, 10)
bodyPad.PaddingTop = UDim.new(0, 8)
bodyPad.PaddingBottom = UDim.new(0, 8)

-- COLLAPSE
local collapsed = false
collapseBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	body.Visible = not collapsed
	collapseBtn.Text = collapsed and "□" or "─"
end)
closeBtn.MouseButton1Click:Connect(function()
	mainWin:Destroy()
end)

-- MODE ROW
local modeRow = Instance.new("Frame", body)
modeRow.BackgroundTransparency = 1
modeRow.Size = UDim2.new(1, 0, 0, 30)
modeRow.LayoutOrder = 1

local modeLbl = makeLabel(modeRow, "Mode", 12, COLOR_GRAY)
modeLbl.Size = UDim2.new(0.5, -2, 1, 0)
modeLbl.TextYAlignment = Enum.TextYAlignment.Center

local playerModeBtn = makeButton(modeRow, "Player", function() end)
playerModeBtn.Size = UDim2.new(0.25, -2, 1, -4)
playerModeBtn.Position = UDim2.new(0.5, 0, 0, 2)

local npcModeBtn = makeButton(modeRow, "NPC", function() end)
npcModeBtn.Size = UDim2.new(0.25, -2, 1, -4)
npcModeBtn.Position = UDim2.new(0.75, 2, 0, 2)

local function updateModeButtons()
	playerModeBtn.BackgroundColor3 = lockMode == "Player" and Color3.fromRGB(50,50,50) or COLOR_BTN
	npcModeBtn.BackgroundColor3 = lockMode == "NPC" and Color3.fromRGB(50,50,50) or COLOR_BTN
end
updateModeButtons()

playerModeBtn.MouseButton1Click:Connect(function()
	lockMode = "Player"
	updateModeButtons()
end)
npcModeBtn.MouseButton1Click:Connect(function()
	lockMode = "NPC"
	updateModeButtons()
end)

makeSeparator(body).LayoutOrder = 2

-- LOCK TOGGLE
local lockRow, getLockState = makeToggleBtn(body, "Lock Target", false, function(s)
	lockEnabled = s
	if s then
		startLock()
	else
		stopLock()
	end
end)
lockRow.LayoutOrder = 3

-- NEAREST TOGGLE
local nearestRow, getNearestState = makeToggleBtn(body, "Lock Nearest", false, function(s)
	lockNearest = s
end)
nearestRow.LayoutOrder = 4

makeSeparator(body).LayoutOrder = 5

-- STRENGTH
local strengthRow = makeInputRow(body, "Lock Strength", lockStrength, function(v)
	lockStrength = v
end)
strengthRow.LayoutOrder = 6

-- RANGE
local rangeRow = makeInputRow(body, "Detect Range", detectionRange, function(v)
	detectionRange = v
end)
rangeRow.LayoutOrder = 7

makeSeparator(body).LayoutOrder = 8

-- SCAN TOGGLE
local scanRow, getScanState = makeToggleBtn(body, "Scan Menu", false, function(s)
	scanEnabled = s
	if scanWin then
		scanWin.Visible = s
	end
end)
scanRow.LayoutOrder = 9

--// ==================== SCAN WINDOW ====================

local scanWin = Instance.new("Frame", gui)
scanWin.BackgroundColor3 = COLOR_BG
scanWin.Position = UDim2.new(0, 210, 0, 80)
scanWin.Size = UDim2.new(0, 200, 0, 0)
scanWin.AutomaticSize = Enum.AutomaticSize.Y
scanWin.ClipsDescendants = true
scanWin.Visible = false
addCorner(scanWin, 8)
addStroke(scanWin, COLOR_BORDER, 1)

local scanLayout = Instance.new("UIListLayout", scanWin)
scanLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- SCAN TITLE
local scanTitle = Instance.new("Frame", scanWin)
scanTitle.BackgroundColor3 = COLOR_PANEL
scanTitle.Size = UDim2.new(1, 0, 0, 32)
scanTitle.LayoutOrder = 0

local scanTitleLbl = makeLabel(scanTitle, "  ◈  SCAN", 13, COLOR_WHITE, FONT)
scanTitleLbl.Size = UDim2.new(1, -90, 1, 0)
scanTitleLbl.TextYAlignment = Enum.TextYAlignment.Center

local scanScaleBox = makeInput(scanTitle, tostring(scanScale), "10")
scanScaleBox.Size = UDim2.new(0, 28, 0, 20)
scanScaleBox.Position = UDim2.new(1, -88, 0.5, -10)
scanScaleBox.TextXAlignment = Enum.TextXAlignment.Center
scanScaleBox.FocusLost:Connect(function()
	local v = tonumber(scanScaleBox.Text)
	if v then
		scanScale = v
		local w = math.max(v * 20, 160)
		scanWin.Size = UDim2.new(0, w, 0, 0)
	end
end)

-- Color filter btn
local colorBtn = Instance.new("TextButton", scanTitle)
colorBtn.Size = UDim2.new(0, 20, 0, 20)
colorBtn.Position = UDim2.new(1, -52, 0.5, -10)
colorBtn.BackgroundTransparency = 1
colorBtn.Text = "🎨"
colorBtn.TextColor3 = COLOR_GRAY
colorBtn.Font = FONT
colorBtn.TextSize = 13

local scanCollapseBtn = Instance.new("TextButton", scanTitle)
scanCollapseBtn.Size = UDim2.new(0, 20, 0, 20)
scanCollapseBtn.Position = UDim2.new(1, -32, 0.5, -10)
scanCollapseBtn.BackgroundTransparency = 1
scanCollapseBtn.Text = "─"
scanCollapseBtn.TextColor3 = COLOR_GRAY
scanCollapseBtn.Font = FONT
scanCollapseBtn.TextSize = 14

local scanCloseBtn = Instance.new("TextButton", scanTitle)
scanCloseBtn.Size = UDim2.new(0, 20, 0, 20)
scanCloseBtn.Position = UDim2.new(1, -10, 0.5, -10)
scanCloseBtn.BackgroundTransparency = 1
scanCloseBtn.Text = "✕"
scanCloseBtn.TextColor3 = COLOR_GRAY
scanCloseBtn.Font = FONT
scanCloseBtn.TextSize = 13

makeDraggable(scanWin, scanTitle)

local scanCollapsed = false
scanCollapseBtn.MouseButton1Click:Connect(function()
	scanCollapsed = not scanCollapsed
	scanCollapseBtn.Text = scanCollapsed and "□" or "─"
end)
scanCloseBtn.MouseButton1Click:Connect(function()
	scanWin:Destroy()
end)

-- SCAN BODY
local scanBody = Instance.new("Frame", scanWin)
scanBody.BackgroundTransparency = 1
scanBody.Size = UDim2.new(1, 0, 0, 0)
scanBody.AutomaticSize = Enum.AutomaticSize.Y
scanBody.LayoutOrder = 1

local scanBodyLayout = Instance.new("UIListLayout", scanBody)
scanBodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
scanBodyLayout.Padding = UDim.new(0, 2)

local scanBodyPad = Instance.new("UIPadding", scanBody)
scanBodyPad.PaddingLeft = UDim.new(0, 8)
scanBodyPad.PaddingRight = UDim.new(0, 8)
scanBodyPad.PaddingTop = UDim.new(0, 8)
scanBodyPad.PaddingBottom = UDim.new(0, 8)

scanCollapseBtn.MouseButton1Click:Connect(function()
	scanBody.Visible = not scanCollapsed
end)

-- SCAN BTN
local scanBtn = makeButton(scanBody, "▶  SCAN", function() end)
scanBtn.Size = UDim2.new(1, 0, 0, 28)
scanBtn.LayoutOrder = 0

-- RESULT LIST
local resultScroll = Instance.new("ScrollingFrame", scanBody)
resultScroll.BackgroundTransparency = 1
resultScroll.Size = UDim2.new(1, 0, 0, 180)
resultScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
resultScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
resultScroll.ScrollBarThickness = 3
resultScroll.ScrollBarImageColor3 = COLOR_BORDER
resultScroll.LayoutOrder = 1

local resultLayout = Instance.new("UIListLayout", resultScroll)
resultLayout.SortOrder = Enum.SortOrder.LayoutOrder
resultLayout.Padding = UDim.new(0, 2)

-- COLOR PICKER PANEL
local colorPanel = Instance.new("Frame", scanBody)
colorPanel.BackgroundColor3 = COLOR_PANEL
colorPanel.Size = UDim2.new(1, 0, 0, 0)
colorPanel.AutomaticSize = Enum.AutomaticSize.Y
colorPanel.Visible = false
colorPanel.LayoutOrder = 2
addCorner(colorPanel, 6)
addStroke(colorPanel, COLOR_BORDER)

local colorPanelPad = Instance.new("UIPadding", colorPanel)
colorPanelPad.PaddingAll = UDim.new(0, 6)

local colorPanelLayout = Instance.new("UIListLayout", colorPanel)
colorPanelLayout.FillDirection = Enum.FillDirection.Horizontal
colorPanelLayout.Padding = UDim.new(0, 4)
colorPanelLayout.Wraps = true

colorBtn.MouseButton1Click:Connect(function()
	colorPanel.Visible = not colorPanel.Visible
end)

-- TEAM COLOR UTILS
local function getTeamColor(entry)
	if entry.isPlayer and entry.team then
		return entry.team.TeamColor.Color
	elseif not entry.isPlayer then
		return Color3.fromRGB(255, 80, 80) -- NPC = red
	else
		return Color3.fromRGB(150, 150, 150)
	end
end

local function shouldShow(entry)
	if #selectedColors == 0 then return true end
	local c = getTeamColor(entry)
	for _, sc in ipairs(selectedColors) do
		if math.abs(c.R - sc.R) < 0.05
			and math.abs(c.G - sc.G) < 0.05
			and math.abs(c.B - sc.B) < 0.05 then
			return true
		end
	end
	return false
end

-- SCAN ACTION
local foundColors = {}

local function doScan()
	-- Clear
	for _, c in ipairs(resultScroll:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
	end

	local list = buildTargetList()
	foundColors = {}

	-- Group by team/type
	local groups = {}
	for _, entry in ipairs(list) do
		local key
		if entry.isPlayer and entry.team then
			key = "Team: " .. entry.team.Name
		elseif entry.isPlayer then
			key = "No Team"
		else
			key = "NPC / Monster"
		end
		if not groups[key] then groups[key] = { entries = {}, color = getTeamColor(entry) } end
		table.insert(groups[key].entries, entry)

		local c = getTeamColor(entry)
		local found = false
		for _, fc in ipairs(foundColors) do
			if math.abs(fc.R - c.R) < 0.05 and math.abs(fc.G - c.G) < 0.05 and math.abs(fc.B - c.B) < 0.05 then
				found = true break
			end
		end
		if not found then table.insert(foundColors, c) end
	end

	-- Rebuild color picker
	for _, c in ipairs(colorPanel:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, fc in ipairs(foundColors) do
		local cb = Instance.new("TextButton", colorPanel)
		cb.Size = UDim2.new(0, 18, 0, 18)
		cb.BackgroundColor3 = fc
		cb.Text = ""
		cb.AutoButtonColor = false
		addCorner(cb, 4)

		local isSelected = false
		cb.MouseButton1Click:Connect(function()
			isSelected = not isSelected
			addStroke(cb, isSelected and COLOR_WHITE or fc, isSelected and 2 or 1)
			if isSelected then
				table.insert(selectedColors, fc)
			else
				for i, sc in ipairs(selectedColors) do
					if math.abs(sc.R - fc.R) < 0.05 then
						table.remove(selectedColors, i) break
					end
				end
			end
		end)
	end

	-- Render groups
	local order = 0
	for groupName, groupData in pairs(groups) do
		if not shouldShow(groupData.entries[1]) then continue end

		local header = Instance.new("Frame", resultScroll)
		header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		header.Size = UDim2.new(1, 0, 0, 22)
		header.LayoutOrder = order
		order += 1
		addCorner(header, 4)

		local dot = Instance.new("Frame", header)
		dot.Size = UDim2.new(0, 6, 0, 6)
		dot.Position = UDim2.new(0, 6, 0.5, -3)
		dot.BackgroundColor3 = groupData.color
		addCorner(dot, 3)

		local hl = makeLabel(header, "  " .. groupName, 11, COLOR_GRAY, FONT)
		hl.Size = UDim2.new(1, -14, 1, 0)
		hl.Position = UDim2.new(0, 14, 0, 0)
		hl.TextYAlignment = Enum.TextYAlignment.Center

		for _, entry in ipairs(groupData.entries) do
			local eb = Instance.new("TextButton", resultScroll)
			eb.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			eb.Size = UDim2.new(1, 0, 0, 26)
			eb.LayoutOrder = order
			eb.Text = ""
			eb.AutoButtonColor = false
			order += 1
			addCorner(eb, 4)

			local colorDot = Instance.new("Frame", eb)
			colorDot.Size = UDim2.new(0, 4, 0.6, 0)
			colorDot.Position = UDim2.new(0, 0, 0.2, 0)
			colorDot.BackgroundColor3 = groupData.color
			addCorner(colorDot, 2)

			local nameLbl = makeLabel(eb, "  " .. entry.name, 12, COLOR_ACCENT)
			nameLbl.Size = UDim2.new(0.7, 0, 1, 0)
			nameLbl.Position = UDim2.new(0, 6, 0, 0)
			nameLbl.TextYAlignment = Enum.TextYAlignment.Center

			local dist = math.floor(getDistance(entry.model))
			local distLbl = makeLabel(eb, tostring(dist) .. "m", 11, COLOR_GRAY)
			distLbl.Size = UDim2.new(0.3, -6, 1, 0)
			distLbl.Position = UDim2.new(0.7, 0, 0, 0)
			distLbl.TextXAlignment = Enum.TextXAlignment.Right
			distLbl.TextYAlignment = Enum.TextYAlignment.Center

			eb.MouseEnter:Connect(function()
				TweenService:Create(eb, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(30,30,30) }):Play()
			end)
			eb.MouseLeave:Connect(function()
				TweenService:Create(eb, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(18,18,18) }):Play()
			end)
			eb.MouseButton1Click:Connect(function()
				lockedTarget = entry
				lockEnabled = true
				startLock()
			end)
		end
	end

	if order == 0 then
		local empty = makeLabel(resultScroll, "  No targets found", 12, COLOR_GRAY)
		empty.Size = UDim2.new(1, 0, 0, 30)
		empty.TextYAlignment = Enum.TextYAlignment.Center
	end
end

scanBtn.MouseButton1Click:Connect(doScan)
