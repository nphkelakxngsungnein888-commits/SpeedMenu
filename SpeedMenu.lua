--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// GUI ROOT
local gui = Instance.new("ScreenGui")
gui.Name = "AimLockGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game.CoreGui

--// STATE
local lockEnabled = false
local nearestEnabled = false
local scanWindowOpen = false
local lockMode = "Player"
local lockedTarget = nil
local lockConn = nil
local scanConn = nil
local lockStrength = 1
local detectionRange = 500
local selectedTeamColors = {}
local mainScale = 10
local scanScale = 10

--// COLORS
local C = {
	BG        = Color3.fromRGB(15, 15, 15),
	BG2       = Color3.fromRGB(22, 22, 22),
	BG3       = Color3.fromRGB(30, 30, 30),
	BORDER    = Color3.fromRGB(50, 50, 50),
	TEXT      = Color3.fromRGB(230, 230, 230),
	TEXTDIM   = Color3.fromRGB(130, 130, 130),
	ACCENT    = Color3.fromRGB(210, 210, 210),
	ON        = Color3.fromRGB(200, 200, 200),
	OFF       = Color3.fromRGB(70, 70, 70),
	HOVER     = Color3.fromRGB(40, 40, 40),
	RED       = Color3.fromRGB(220, 80, 80),
}

--// HELPERS
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	return char, char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Head")
end

local function getRoot(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function isAlive(model)
	local h = getHumanoid(model)
	return h and h.Health > 0
end

local function getTeamColor(p)
	if p and p.Team then
		return p.Team.TeamColor.Color
	end
	return Color3.fromRGB(180, 180, 180)
end

--// CORNER
local function addCorner(inst, rad)
	local c = Instance.new("UICorner", inst)
	c.CornerRadius = UDim.new(0, rad or 6)
end

local function addStroke(inst, color, thickness)
	local s = Instance.new("UIStroke", inst)
	s.Color = color or C.BORDER
	s.Thickness = thickness or 1
end

--// BASE FRAME BUILDER
local function makeFrame(parent, size, pos, bg, zindex)
	local f = Instance.new("Frame", parent)
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = bg or C.BG
	f.BorderSizePixel = 0
	if zindex then f.ZIndex = zindex end
	return f
end

local function makeLabel(parent, text, size, pos, color, fontSize, zindex)
	local l = Instance.new("TextLabel", parent)
	l.Size = size
	l.Position = pos
	l.Text = text
	l.TextColor3 = color or C.TEXT
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = fontSize or 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	if zindex then l.ZIndex = zindex end
	return l
end

local function makeBtn(parent, text, size, pos, zindex)
	local b = Instance.new("TextButton", parent)
	b.Size = size
	b.Position = pos
	b.Text = text
	b.TextColor3 = C.TEXT
	b.BackgroundColor3 = C.BG3
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.AutoButtonColor = false
	if zindex then b.ZIndex = zindex end
	addCorner(b, 5)
	addStroke(b, C.BORDER, 1)
	b.MouseEnter:Connect(function() b.BackgroundColor3 = C.HOVER end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = C.BG3 end)
	return b
end

local function makeInput(parent, default, size, pos, zindex)
	local box = Instance.new("TextBox", parent)
	box.Size = size
	box.Position = pos
	box.Text = tostring(default)
	box.TextColor3 = C.TEXT
	box.BackgroundColor3 = C.BG3
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Gotham
	box.TextSize = 11
	box.ClearTextOnFocus = false
	if zindex then box.ZIndex = zindex end
	addCorner(box, 5)
	addStroke(box, C.BORDER, 1)
	return box
end

local function makeDivider(parent, y, zindex)
	local d = makeFrame(parent, UDim2.new(1, -16, 0, 1), UDim2.new(0, 8, 0, y), C.BORDER)
	if zindex then d.ZIndex = zindex end
	return d
end

--// DRAG FUNCTION
local function makeDraggable(frame, handle)
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				frame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

--// SCALE APPLY
local function applyScale(frame, scale, baseW, baseH)
	local factor = scale / 10
	frame.Size = UDim2.new(0, math.floor(baseW * factor), 0, math.floor(baseH * factor))
end

--// ─────────────────────────────────────────────
--//  MAIN WINDOW
--// ─────────────────────────────────────────────
local MAIN_BASE_W = 200
local MAIN_BASE_H = 330

local mainWin = makeFrame(gui,
	UDim2.new(0, MAIN_BASE_W, 0, MAIN_BASE_H),
	UDim2.new(0, 20, 0, 100),
	C.BG, 10)
addCorner(mainWin, 10)
addStroke(mainWin, C.BORDER, 1)
mainWin.ClipsDescendants = true

-- Shadow
local shadow = makeFrame(gui,
	UDim2.new(0, MAIN_BASE_W + 10, 0, MAIN_BASE_H + 10),
	UDim2.new(0, 15, 0, 95),
	Color3.fromRGB(0,0,0), 9)
addCorner(shadow, 12)
shadow.BackgroundTransparency = 0.7

-- Title bar
local titleBar = makeFrame(mainWin,
	UDim2.new(1, 0, 0, 34),
	UDim2.new(0, 0, 0, 0),
	C.BG2, 11)
addCorner(titleBar, 10)

-- fix bottom corners of titlebar
local titleFix = makeFrame(mainWin,
	UDim2.new(1, 0, 0, 10),
	UDim2.new(0, 0, 0, 24),
	C.BG2, 11)

local titleLabel = makeLabel(titleBar, "◈  AIMLOCK", UDim2.new(1, -70, 1, 0), UDim2.new(0, 12, 0, 0), C.TEXT, 12, 12)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local minBtn = makeBtn(titleBar, "—", UDim2.new(0, 24, 0, 20), UDim2.new(1, -54, 0, 7), 12)
minBtn.TextSize = 13

-- Close button
local closeBtn = makeBtn(titleBar, "✕", UDim2.new(0, 24, 0, 20), UDim2.new(1, -26, 0, 7), 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)

-- Scale label + input (top right of titlebar)
local scaleLabel = makeLabel(titleBar, "SIZE", UDim2.new(0, 28, 0, 14), UDim2.new(1, -130, 0, 10), C.TEXTDIM, 9, 12)
local scaleInput = makeInput(titleBar, "10", UDim2.new(0, 28, 0, 20), UDim2.new(1, -102, 0, 7), 12)
scaleInput.TextXAlignment = Enum.TextXAlignment.Center

makeDraggable(mainWin, titleBar)
makeDraggable(shadow, titleBar)

-- Content frame (scrollable area)
local contentFrame = makeFrame(mainWin,
	UDim2.new(1, 0, 1, -34),
	UDim2.new(0, 0, 0, 34),
	C.BG, 11)

local scroll = Instance.new("ScrollingFrame", contentFrame)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.Position = UDim2.new(0, 0, 0, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = C.BORDER
scroll.CanvasSize = UDim2.new(0, 0, 0, 280)
scroll.ZIndex = 11

local function row(y)
	return UDim2.new(0, 8, 0, y)
end

-- Section: LOCK
local s1 = makeLabel(scroll, "LOCK", UDim2.new(1, -16, 0, 14), row(8), C.TEXTDIM, 9, 12)
s1.TextXAlignment = Enum.TextXAlignment.Left

local lockBtn = makeBtn(scroll, "LOCK  OFF", UDim2.new(1, -16, 0, 30), row(24), 12)
lockBtn.TextXAlignment = Enum.TextXAlignment.Center

local nearBtn = makeBtn(scroll, "NEAREST  OFF", UDim2.new(1, -16, 0, 30), row(60), 12)
nearBtn.TextXAlignment = Enum.TextXAlignment.Center

makeDivider(scroll, 98, 12)

-- Section: MODE
local s2 = makeLabel(scroll, "MODE", UDim2.new(1, -16, 0, 14), row(106), C.TEXTDIM, 9, 12)

local modeBtn = makeBtn(scroll, "MODE  PLAYER", UDim2.new(1, -16, 0, 30), row(122), 12)
modeBtn.TextXAlignment = Enum.TextXAlignment.Center

local scanToggleBtn = makeBtn(scroll, "SCAN  OFF", UDim2.new(1, -16, 0, 30), row(158), 12)
scanToggleBtn.TextXAlignment = Enum.TextXAlignment.Center

makeDivider(scroll, 196, 12)

-- Section: SETTINGS
local s3 = makeLabel(scroll, "SETTINGS", UDim2.new(1, -16, 0, 14), row(204), C.TEXTDIM, 9, 12)

local rangeLabel = makeLabel(scroll, "Detection Range", UDim2.new(0, 110, 0, 14), row(220), C.TEXT, 10, 12)
local rangeInput = makeInput(scroll, "500", UDim2.new(0, 60, 0, 22), UDim2.new(0, 124, 0, 220), 12)
rangeInput.TextXAlignment = Enum.TextXAlignment.Center

local strengthLabel = makeLabel(scroll, "Lock Strength", UDim2.new(0, 110, 0, 14), row(248), C.TEXT, 10, 12)
local strengthInput = makeInput(scroll, "1", UDim2.new(0, 60, 0, 22), UDim2.new(0, 124, 0, 248), 12)
strengthInput.TextXAlignment = Enum.TextXAlignment.Center

-- minimized state
local minimized = false
local function toggleMinimize()
	minimized = not minimized
	local targetH = minimized and 34 or MAIN_BASE_H
	local factor = mainScale / 10
	TweenService:Create(mainWin, TweenInfo.new(0.2), {
		Size = UDim2.new(0, math.floor(MAIN_BASE_W * factor), 0, math.floor(targetH * factor))
	}):Play()
	TweenService:Create(shadow, TweenInfo.new(0.2), {
		Size = UDim2.new(0, math.floor((MAIN_BASE_W+10) * factor), 0, math.floor((targetH+10) * factor))
	}):Play()
	contentFrame.Visible = not minimized
	minBtn.Text = minimized and "▢" or "—"
end

minBtn.MouseButton1Click:Connect(toggleMinimize)

closeBtn.MouseButton1Click:Connect(function()
	TweenService:Create(mainWin, TweenInfo.new(0.15), {Size = UDim2.new(0,0,0,0)}):Play()
	TweenService:Create(shadow, TweenInfo.new(0.15), {Size = UDim2.new(0,0,0,0)}):Play()
	wait(0.15)
	gui:Destroy()
end)

scaleInput.FocusLost:Connect(function()
	local v = tonumber(scaleInput.Text)
	if v then
		mainScale = v
		local factor = v / 10
		local targetH = minimized and 34 or MAIN_BASE_H
		mainWin.Size = UDim2.new(0, math.floor(MAIN_BASE_W * factor), 0, math.floor(targetH * factor))
		shadow.Size = UDim2.new(0, math.floor((MAIN_BASE_W+10) * factor), 0, math.floor((targetH+10) * factor))
	end
end)

rangeInput.FocusLost:Connect(function()
	local v = tonumber(rangeInput.Text)
	if v then detectionRange = v end
end)

strengthInput.FocusLost:Connect(function()
	local v = tonumber(strengthInput.Text)
	if v then lockStrength = v end
end)

--// ─────────────────────────────────────────────
--//  SCAN WINDOW
--// ─────────────────────────────────────────────
local SCAN_BASE_W = 220
local SCAN_BASE_H = 300

local scanWin = makeFrame(gui,
	UDim2.new(0, SCAN_BASE_W, 0, SCAN_BASE_H),
	UDim2.new(0, 240, 0, 100),
	C.BG, 10)
addCorner(scanWin, 10)
addStroke(scanWin, C.BORDER, 1)
scanWin.Visible = false
scanWin.ClipsDescendants = true

local scanShadow = makeFrame(gui,
	UDim2.new(0, SCAN_BASE_W+10, 0, SCAN_BASE_H+10),
	UDim2.new(0, 235, 0, 95),
	Color3.fromRGB(0,0,0), 9)
addCorner(scanShadow, 12)
scanShadow.BackgroundTransparency = 0.7
scanShadow.Visible = false

-- Scan title bar
local scanTitleBar = makeFrame(scanWin, UDim2.new(1,0,0,34), UDim2.new(0,0,0,0), C.BG2, 11)
addCorner(scanTitleBar, 10)
local scanTitleFix = makeFrame(scanWin, UDim2.new(1,0,0,10), UDim2.new(0,0,0,24), C.BG2, 11)

local scanTitleLabel = makeLabel(scanTitleBar, "◈  SCAN", UDim2.new(1,-100,1,0), UDim2.new(0,12,0,0), C.TEXT, 12, 12)

-- Color filter button
local colorFilterBtn = makeBtn(scanTitleBar, "🎨", UDim2.new(0,24,0,20), UDim2.new(1,-84,0,7), 12)
colorFilterBtn.TextSize = 14

-- Minimize scan
local scanMinBtn = makeBtn(scanTitleBar, "—", UDim2.new(0,24,0,20), UDim2.new(1,-54,0,7), 12)

-- Close scan
local scanCloseBtn = makeBtn(scanTitleBar, "✕", UDim2.new(0,24,0,20), UDim2.new(1,-26,0,7), 12)
scanCloseBtn.BackgroundColor3 = Color3.fromRGB(50,20,20)

-- Scan size
local scanScaleLabel = makeLabel(scanTitleBar, "SIZE", UDim2.new(0,28,0,14), UDim2.new(1,-160,0,10), C.TEXTDIM, 9, 12)
local scanScaleInput = makeInput(scanTitleBar, "10", UDim2.new(0,28,0,20), UDim2.new(1,-132,0,7), 12)
scanScaleInput.TextXAlignment = Enum.TextXAlignment.Center

makeDraggable(scanWin, scanTitleBar)
makeDraggable(scanShadow, scanTitleBar)

-- Scan body
local scanBody = makeFrame(scanWin, UDim2.new(1,0,1,-34), UDim2.new(0,0,0,34), C.BG, 11)

-- Scan button
local scanBtn = makeBtn(scanBody, "▶  SCAN NOW", UDim2.new(1,-16,0,28), UDim2.new(0,8,0,8), 12)
scanBtn.TextXAlignment = Enum.TextXAlignment.Center
scanBtn.BackgroundColor3 = C.BG3

-- Results area
local scanScroll = Instance.new("ScrollingFrame", scanBody)
scanScroll.Size = UDim2.new(1,-8, 1, -48)
scanScroll.Position = UDim2.new(0, 4, 0, 44)
scanScroll.BackgroundTransparency = 1
scanScroll.BorderSizePixel = 0
scanScroll.ScrollBarThickness = 2
scanScroll.ScrollBarImageColor3 = C.BORDER
scanScroll.CanvasSize = UDim2.new(0,0,0,0)
scanScroll.ZIndex = 12

local scanList = Instance.new("UIListLayout", scanScroll)
scanList.Padding = UDim.new(0, 3)
scanList.SortOrder = Enum.SortOrder.LayoutOrder

-- Color filter popup
local colorPopup = makeFrame(scanWin, UDim2.new(0,150,0,120), UDim2.new(1,-158,0,34), C.BG2, 15)
addCorner(colorPopup, 8)
addStroke(colorPopup, C.BORDER, 1)
colorPopup.Visible = false
local colorPopupLabel = makeLabel(colorPopup, "SHOW COLORS", UDim2.new(1,0,0,16), UDim2.new(0,8,0,4), C.TEXTDIM, 9, 16)
colorPopupLabel.TextXAlignment = Enum.TextXAlignment.Left
local colorList = Instance.new("ScrollingFrame", colorPopup)
colorList.Size = UDim2.new(1,-8,1,-24)
colorList.Position = UDim2.new(0,4,0,22)
colorList.BackgroundTransparency = 1
colorList.BorderSizePixel = 0
colorList.ScrollBarThickness = 2
colorList.ScrollBarImageColor3 = C.BORDER
colorList.CanvasSize = UDim2.new(0,0,0,0)
colorList.ZIndex = 16
local colorUIList = Instance.new("UIListLayout", colorList)
colorUIList.Padding = UDim.new(0,3)

-- scan minimized
local scanMinimized = false
local function toggleScanMinimize()
	scanMinimized = not scanMinimized
	local targetH = scanMinimized and 34 or SCAN_BASE_H
	local factor = scanScale / 10
	TweenService:Create(scanWin, TweenInfo.new(0.2), {
		Size = UDim2.new(0, math.floor(SCAN_BASE_W*factor), 0, math.floor(targetH*factor))
	}):Play()
	TweenService:Create(scanShadow, TweenInfo.new(0.2), {
		Size = UDim2.new(0, math.floor((SCAN_BASE_W+10)*factor), 0, math.floor((targetH+10)*factor))
	}):Play()
	scanBody.Visible = not scanMinimized
	scanMinBtn.Text = scanMinimized and "▢" or "—"
end

scanMinBtn.MouseButton1Click:Connect(toggleScanMinimize)

scanCloseBtn.MouseButton1Click:Connect(function()
	scanWin.Visible = false
	scanShadow.Visible = false
	scanWindowOpen = false
	scanToggleBtn.Text = "SCAN  OFF"
	colorPopup.Visible = false
end)

scanScaleInput.FocusLost:Connect(function()
	local v = tonumber(scanScaleInput.Text)
	if v then
		scanScale = v
		local factor = v / 10
		local targetH = scanMinimized and 34 or SCAN_BASE_H
		scanWin.Size = UDim2.new(0, math.floor(SCAN_BASE_W*factor), 0, math.floor(targetH*factor))
		scanShadow.Size = UDim2.new(0, math.floor((SCAN_BASE_W+10)*factor), 0, math.floor((targetH+10)*factor))
	end
end)

colorFilterBtn.MouseButton1Click:Connect(function()
	colorPopup.Visible = not colorPopup.Visible
end)

--// BUILD TARGET LIST
local function buildTargetList()
	local list = {}
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return list end

	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and isAlive(p.Character) then
				local root = getRoot(p.Character)
				if root then
					local dist = (root.Position - hrp.Position).Magnitude
					if dist <= detectionRange then
						table.insert(list, {model = p.Character, name = p.Name, isPlayer = true, playerObj = p})
					end
				end
			end
		end
	else
		local playerChars = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then playerChars[p.Character] = true end
		end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and not playerChars[obj]
				and obj:FindFirstChildOfClass("Humanoid")
				and obj:FindFirstChild("HumanoidRootPart") and isAlive(obj) then
				local root = getRoot(obj)
				if root then
					local dist = (root.Position - hrp.Position).Magnitude
					if dist <= detectionRange then
						table.insert(list, {model = obj, name = obj.Name, isPlayer = false, playerObj = nil})
					end
				end
			end
		end
	end
	return list
end

--// GET NEAREST
local function getNearestTarget(list)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local best, bestDist = nil, math.huge
	for _, t in ipairs(list) do
		local root = getRoot(t.model)
		if root then
			local d = (root.Position - hrp.Position).Magnitude
			if d < bestDist then
				bestDist = d
				best = t
			end
		end
	end
	return best
end

--// LOCK LOGIC
local function startLock()
	if lockConn then lockConn:Disconnect() end
	lockConn = RunService.RenderStepped:Connect(function()
		if not lockEnabled then return end
		local ok, char, hrp, head = pcall(getChar)
		if not ok then return end

		if lockedTarget == nil then
			if nearestEnabled then
				local list = buildTargetList()
				local t = getNearestTarget(list)
				if t then lockedTarget = t.model end
			end
			return
		end

		local root = getRoot(lockedTarget)
		if not root or not isAlive(lockedTarget) then
			lockedTarget = nil
			return
		end

		local s = math.clamp(lockStrength * 0.1, 0.01, 1)
		local flat = (root.Position - hrp.Position) * Vector3.new(1,0,1)
		if flat.Magnitude > 0.1 then
			local targetCF = CFrame.lookAt(hrp.Position, hrp.Position + flat)
			hrp.CFrame = hrp.CFrame:Lerp(targetCF, s)
		end
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(head.Position, root.Position), s)
	end)
end

local function stopLock()
	if lockConn then lockConn:Disconnect() lockConn = nil end
	lockedTarget = nil
end

--// SCAN DISPLAY
local foundColors = {}

local function runScan()
	-- clear old entries
	for _, c in ipairs(scanScroll:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
	end
	foundColors = {}

	local list = buildTargetList()

	-- collect unique team colors for color popup
	for _, c in ipairs(colorList:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end

	local colorSet = {}
	for _, t in ipairs(list) do
		local col
		if t.isPlayer then
			col = getTeamColor(t.playerObj)
		else
			col = Color3.fromRGB(220, 80, 80)
		end
		local key = math.floor(col.R*255).."_"..math.floor(col.G*255).."_"..math.floor(col.B*255)
		if not colorSet[key] then
			colorSet[key] = col
			foundColors[key] = {color = col, show = true}

			-- color toggle button
			local cb = Instance.new("TextButton", colorList)
			cb.Size = UDim2.new(1,-4,0,22)
			cb.BackgroundColor3 = col
			cb.TextColor3 = Color3.fromRGB(255,255,255)
			cb.Font = Enum.Font.GothamBold
			cb.TextSize = 10
			cb.Text = "● " .. key:gsub("_",",")
			cb.BorderSizePixel = 0
			addCorner(cb, 4)
			local showing = true
			cb.MouseButton1Click:Connect(function()
				showing = not showing
				foundColors[key].show = showing
				cb.BackgroundTransparency = showing and 0 or 0.6
				cb.Text = (showing and "●" or "○") .. " " .. key:gsub("_",",")
			end)
		end
	end

	local colorListH = #colorSet * 25
	colorList.CanvasSize = UDim2.new(0,0,0,colorListH)

	-- now display filtered entries
	local totalH = 0
	for _, t in ipairs(list) do
		local col
		if t.isPlayer then
			col = getTeamColor(t.playerObj)
		else
			col = Color3.fromRGB(220, 80, 80)
		end
		local key = math.floor(col.R*255).."_"..math.floor(col.G*255).."_"..math.floor(col.B*255)
		if foundColors[key] and foundColors[key].show then
			local btn = Instance.new("TextButton", scanScroll)
			btn.Size = UDim2.new(1,-4,0,26)
			btn.BackgroundColor3 = C.BG3
			btn.TextColor3 = col
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 11
			btn.Text = "  ◆ " .. t.name
	btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = false
			addCorner(btn, 5)
			addStroke(btn, col, 1)

			local tRef = t
			btn.MouseButton1Click:Connect(function()
				lockedTarget = tRef.model
				if not lockEnabled then
					lockEnabled = true
					lockBtn.Text = "LOCK  ON"
					lockBtn.BackgroundColor3 = C.BG
					addStroke(lockBtn, C.ON, 1.5)
					camera.CameraType = Enum.CameraType.Custom
					player.CameraMode = Enum.CameraMode.LockFirstPerson
					startLock()
				end
			end)

			btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.HOVER end)
			btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.BG3 end)

			totalH = totalH + 29
		end
	end

	scanScroll.CanvasSize = UDim2.new(0,0,0,totalH)
end

scanBtn.MouseButton1Click:Connect(runScan)

--// TOGGLE SCAN WINDOW
local function toggleScanWindow()
	scanWindowOpen = not scanWindowOpen
	scanWin.Visible = scanWindowOpen
	scanShadow.Visible = scanWindowOpen
	scanToggleBtn.Text = "SCAN  " .. (scanWindowOpen and "ON" or "OFF")
	scanToggleBtn.BackgroundColor3 = scanWindowOpen and C.BG or C.BG3
end

scanToggleBtn.MouseButton1Click:Connect(toggleScanWindow)

--// LOCK BUTTON
lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	if lockEnabled then
		lockBtn.Text = "LOCK  ON"
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		startLock()
	else
		lockBtn.Text = "LOCK  OFF"
		player.CameraMode = Enum.CameraMode.Classic
		stopLock()
	end
end)

--// NEAREST BUTTON
nearBtn.MouseButton1Click:Connect(function()
	nearestEnabled = not nearestEnabled
	nearBtn.Text = "NEAREST  " .. (nearestEnabled and "ON" or "OFF")
end)

--// MODE BUTTON
modeBtn.MouseButton1Click:Connect(function()
	lockMode = (lockMode == "Player") and "NPC" or "Player"
	modeBtn.Text = "MODE  " .. lockMode
	lockedTarget = nil
end)

--// RESPAWN HANDLER
player.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	if lockEnabled then
		startLock()
	end
end)
