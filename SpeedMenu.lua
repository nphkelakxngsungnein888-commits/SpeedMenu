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
local isCollapsed = false
local mainVisible = true

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
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and isAlive(plr.Character) then
				local part = getRoot(plr.Character)
				if part then
					local d = (part.Position - root.Position).Magnitude
					if d < dist then dist = d; best = plr.Character end
				end
			end
		end
	else
		for _, m in pairs(workspace:GetChildren()) do
			if m:IsA("Model") and isValid(m) then
				local part = getRoot(m)
				if part then
					local d = (part.Position - root.Position).Magnitude
					if d < dist then dist = d; best = m end
				end
			end
		end
	end
	return best
end


--// ===== OPTIMIZED CACHE =====
local cachedTargets = {}
local lastScan = 0
local SCAN_DELAY = 0.3

local function updateTargets()
	cachedTargets = {}
	local char = getChar()
	local root = getRoot(char)
	if not root then return end

	if targetMode == "Player" then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and isAlive(plr.Character) then
				local part = getRoot(plr.Character)
				if part then
					local dist = (part.Position - root.Position).Magnitude
					if dist <= scanDistance then
						table.insert(cachedTargets, plr.Character)
					end
				end
			end
		end
	else
		for _, m in pairs(workspace:GetChildren()) do
			if m:IsA("Model") and isValid(m) then
				local part = getRoot(m)
				if part then
					local dist = (part.Position - root.Position).Magnitude
					if dist <= scanDistance then
						table.insert(cachedTargets, m)
					end
				end
			end
		end
	end
end

local function getClosestCached(root)
	local best, dist = nil, math.huge
	for _, m in pairs(cachedTargets) do
		local part = getRoot(m)
		if part then
			local d = (part.Position - root.Position).Magnitude
			if d < dist then
				dist = d
				best = m
			end
		end
	end
	return best
end

--// ===== LOCK LOOP =====
RunService.RenderStepped:Connect(function()
	if not lockEnabled then return end
	local char = getChar()
	local root = getRoot(char)
	if not root then return end

	if selectedTarget and isAlive(selectedTarget) then
		currentTarget = selectedTarget
	else
		if tick() - lastScan > SCAN_DELAY then
	lastScan = tick()
	updateTargets()
end
currentTarget = getClosestCached(root)
	end

	if not currentTarget then return end
	local part = getRoot(currentTarget)
	if not part then return end

	local aim = part.Position + Vector3.new(offsets[1], offsets[2], offsets[3])
	local camPos = root.Position + Vector3.new(offsets[4], offsets[5], offsets[6])

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(camPos, aim)
end)

--// ===== GUI ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "AimUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui

--// ===== HELPER FUNCTIONS =====
local function makeCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 8)
end

local function makeStroke(parent, color, thickness)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or Color3.fromRGB(255,255,255)
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local function makePadding(parent, px)
	local p = Instance.new("UIPadding", parent)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
end

--// ===== COLOR THEME =====
local C = {
	bg        = Color3.fromRGB(10, 10, 10),
	panel     = Color3.fromRGB(20, 20, 20),
	border    = Color3.fromRGB(255, 255, 255),
	dimBorder = Color3.fromRGB(60, 60, 60),
	btnBg     = Color3.fromRGB(255, 255, 255),
	btnText   = Color3.fromRGB(0, 0, 0),
	activeBg  = Color3.fromRGB(230, 230, 230),
	onColor   = Color3.fromRGB(255, 255, 255),
	offColor  = Color3.fromRGB(120, 120, 120),
	text      = Color3.fromRGB(255, 255, 255),
	subText   = Color3.fromRGB(160, 160, 160),
	inputBg   = Color3.fromRGB(30, 30, 30),
	titleBg   = Color3.fromRGB(255, 255, 255),
	titleText = Color3.fromRGB(0, 0, 0),
}

--// ===== DRAG HELPER =====
local function makeDraggable(dragTarget, moveTarget)
	local dragging = false
	local dragStart, startPos

	local function inputBegan(i)
		local t = i.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = i.Position
			startPos = moveTarget.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end

	dragTarget.InputBegan:Connect(inputBegan)

	UIS.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch then
			local delta = i.Position - dragStart
			moveTarget.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	UIS.InputEnded:Connect(function(i)
		local t = i.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

--// ===== MAIN WINDOW =====
local MAIN_W = 230
local TITLE_H = 36
local BODY_H  = 320

local mainFrame = Instance.new("Frame", gui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, MAIN_W, 0, TITLE_H + BODY_H)
mainFrame.Position = UDim2.new(0, 20, 0.5, -(TITLE_H + BODY_H) / 2)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
makeCorner(mainFrame, 10)
makeStroke(mainFrame, C.border, 1)

-- Title Bar
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = C.titleBg
titleBar.BorderSizePixel = 0
makeCorner(titleBar, 10)

-- Fix corner: cover bottom corners of titlebar
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = C.titleBg
titleFix.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚔ AIM TOOL"
titleLabel.TextColor3 = C.titleText
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Collapse Button
local collapseBtn = Instance.new("TextButton", titleBar)
collapseBtn.Size = UDim2.new(0, 28, 0, 22)
collapseBtn.Position = UDim2.new(1, -62, 0.5, -11)
collapseBtn.BackgroundColor3 = C.bg
collapseBtn.Text = "▾"
collapseBtn.TextColor3 = C.titleBg
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 14
collapseBtn.BorderSizePixel = 0
makeCorner(collapseBtn, 5)

-- Close Button
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 22)
closeBtn.Position = UDim2.new(1, -30, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.BorderSizePixel = 0
makeCorner(closeBtn, 5)

-- Body Frame
local bodyFrame = Instance.new("Frame", mainFrame)
bodyFrame.Name = "Body"
bodyFrame.Size = UDim2.new(1, 0, 0, BODY_H)
bodyFrame.Position = UDim2.new(0, 0, 0, TITLE_H)
bodyFrame.BackgroundTransparency = 1
bodyFrame.ClipsDescendants = true

-- Scroll inside body
local scroll = Instance.new("ScrollingFrame", bodyFrame)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.Position = UDim2.new(0,0,0,0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 440)
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.dimBorder
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
makePadding(scroll, 10)

-- Helper: section label
local function sectionLabel(txt, order)
	local lbl = Instance.new("TextLabel", scroll)
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text = txt
	lbl.TextColor3 = C.subText
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order
	return lbl
end

-- Helper: styled toggle button
local function makeToggleBtn(txt, order)
	local btn = Instance.new("TextButton", scroll)
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = C.btnBg
	btn.Text = txt
	btn.TextColor3 = C.btnText
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.BorderSizePixel = 0
	btn.LayoutOrder = order
	makeCorner(btn, 7)
	return btn
end

-- Helper: styled textbox
local function makeInputBox(placeholder, order)
	local box = Instance.new("TextBox", scroll)
	box.Size = UDim2.new(1, 0, 0, 32)
	box.BackgroundColor3 = C.inputBg
	box.Text = placeholder
	box.TextColor3 = C.text
	box.PlaceholderColor3 = C.subText
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.LayoutOrder = order
	makeCorner(box, 7)
	makeStroke(box, C.dimBorder, 1)
	makePadding(box, 8)
	return box
end

--// ===== SECTION: LOCK =====
sectionLabel("TARGETING", 1)

local lockBtn = makeToggleBtn("🔴  LOCK OFF", 2)
lockBtn.BackgroundColor3 = C.btnBg

lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	if lockEnabled then
		lockBtn.Text = "🟢  LOCK ON"
		lockBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
	else
		lockBtn.Text = "🔴  LOCK OFF"
		lockBtn.BackgroundColor3 = C.btnBg
		camera.CameraType = Enum.CameraType.Custom
	end
end)

local modeBtn = makeToggleBtn("Mode: " .. targetMode, 3)
modeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
modeBtn.TextColor3 = C.text
makeStroke(modeBtn, C.dimBorder, 1)

modeBtn.MouseButton1Click:Connect(function()
	targetMode = targetMode == "Monster" and "Player" or "Monster"
	modeBtn.Text = "Mode: " .. targetMode
	_G.AIM_SETTINGS.mode = targetMode
end)

--// ===== SECTION: DISTANCE =====
sectionLabel("SCAN DISTANCE", 4)

local distBox = makeInputBox("Distance: " .. scanDistance, 5)
distBox.FocusLost:Connect(function()
	local v = tonumber(distBox.Text:match("%d+"))
	if v then
		scanDistance = v
		_G.AIM_SETTINGS.distance = v
		distBox.Text = "Distance: " .. v
	end
end)

--// ===== SECTION: OFFSETS =====
sectionLabel("AIM OFFSETS", 6)

local offsetNames = {"Aim X", "Aim Y", "Aim Z", "Cam X", "Cam Y", "Cam Z"}
for i = 1, 6 do
	local box = makeInputBox(offsetNames[i] .. ": " .. offsets[i], 6 + i)
	box.FocusLost:Connect(function()
		local v = tonumber(box.Text:match("-?%d+"))
		if v then
			offsets[i] = v
			_G.AIM_SETTINGS.offset = offsets
			box.Text = offsetNames[i] .. ": " .. v
		end
	end)
end

--// ===== SECTION: SCAN =====
sectionLabel("TARGET SCAN", 14)

local scanOpenBtn = makeToggleBtn("🔍  OPEN SCAN MENU", 15)
scanOpenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scanOpenBtn.TextColor3 = C.text
makeStroke(scanOpenBtn, C.dimBorder, 1)

--// ===== SCAN WINDOW =====
local scanFrame = Instance.new("Frame", gui)
scanFrame.Name = "ScanFrame"
scanFrame.Size = UDim2.new(0, 200, 0, 240)
scanFrame.Position = UDim2.new(0, 270, 0.5, -120)
scanFrame.BackgroundColor3 = C.bg
scanFrame.BorderSizePixel = 0
scanFrame.Visible = false
makeCorner(scanFrame, 10)
makeStroke(scanFrame, C.border, 1)

-- Scan Title
local scanTitle = Instance.new("Frame", scanFrame)
scanTitle.Size = UDim2.new(1, 0, 0, 36)
scanTitle.BackgroundColor3 = C.titleBg
scanTitle.BorderSizePixel = 0
makeCorner(scanTitle, 10)

local scanTitleFix = Instance.new("Frame", scanTitle)
scanTitleFix.Size = UDim2.new(1, 0, 0.5, 0)
scanTitleFix.Position = UDim2.new(0, 0, 0.5, 0)
scanTitleFix.BackgroundColor3 = C.titleBg
scanTitleFix.BorderSizePixel = 0

local scanTitleLbl = Instance.new("TextLabel", scanTitle)
scanTitleLbl.Size = UDim2.new(1, -36, 1, 0)
scanTitleLbl.Position = UDim2.new(0, 10, 0, 0)
scanTitleLbl.BackgroundTransparency = 1
scanTitleLbl.Text = "TARGET LIST"
scanTitleLbl.TextColor3 = C.titleText
scanTitleLbl.Font = Enum.Font.GothamBold
scanTitleLbl.TextSize = 12
scanTitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local scanCloseBtn = Instance.new("TextButton", scanTitle)
scanCloseBtn.Size = UDim2.new(0, 26, 0, 20)
scanCloseBtn.Position = UDim2.new(1, -30, 0.5, -10)
scanCloseBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
scanCloseBtn.Text = "✕"
scanCloseBtn.TextColor3 = C.text
scanCloseBtn.Font = Enum.Font.GothamBold
scanCloseBtn.TextSize = 12
scanCloseBtn.BorderSizePixel = 0
makeCorner(scanCloseBtn, 5)

-- Scan List
local scanList = Instance.new("ScrollingFrame", scanFrame)
scanList.Size = UDim2.new(1, -10, 1, -80)
scanList.Position = UDim2.new(0, 5, 0, 40)
scanList.CanvasSize = UDim2.new(0, 0, 0, 0)
scanList.ScrollBarThickness = 3
scanList.ScrollBarImageColor3 = C.dimBorder
scanList.BackgroundTransparency = 1
scanList.BorderSizePixel = 0

local scanListLayout = Instance.new("UIListLayout", scanList)
scanListLayout.Padding = UDim.new(0, 4)
scanListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Scan Now Button
local scanNowBtn = Instance.new("TextButton", scanFrame)
scanNowBtn.Size = UDim2.new(1, -10, 0, 30)
scanNowBtn.Position = UDim2.new(0, 5, 1, -36)
scanNowBtn.BackgroundColor3 = C.btnBg
scanNowBtn.Text = "SCAN"
scanNowBtn.TextColor3 = C.btnText
scanNowBtn.Font = Enum.Font.GothamBold
scanNowBtn.TextSize = 12
scanNowBtn.BorderSizePixel = 0
makeCorner(scanNowBtn, 7)

-- Selected label
local selectedLbl = Instance.new("TextLabel", scanFrame)
selectedLbl.Size = UDim2.new(1, -10, 0, 16)
selectedLbl.Position = UDim2.new(0, 5, 1, -68)
selectedLbl.BackgroundTransparency = 1
selectedLbl.Text = "Selected: none"
selectedLbl.TextColor3 = C.subText
selectedLbl.Font = Enum.Font.Gotham
selectedLbl.TextSize = 10
selectedLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Scan logic
scanNowBtn.MouseButton1Click:Connect(function()
	for _, c in pairs(scanList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	selectedTarget = nil
	selectedLbl.Text = "Selected: none"

	local char = getChar()
	local root = getRoot(char)
	if not root then return end

	local idx = 0
	for _, m in pairs(workspace:GetChildren()) do
		if m:IsA("Model") and isValid(m) then
			local part = getRoot(m)
			if part then
				local dist = (part.Position - root.Position).Magnitude
				if dist <= scanDistance then
					local b = Instance.new("TextButton", scanList)
					b.Size = UDim2.new(1, 0, 0, 28)
					b.BackgroundColor3 = C.inputBg
					b.Text = m.Name .. " (" .. math.floor(dist) .. ")"
					b.TextColor3 = C.text
					b.Font = Enum.Font.Gotham
					b.TextSize = 11
					b.BorderSizePixel = 0
					b.LayoutOrder = idx
					makeCorner(b, 6)

					b.MouseButton1Click:Connect(function()
						selectedTarget = m
						selectedLbl.Text = "Selected: " .. m.Name
						for _, child in pairs(scanList:GetChildren()) do
							if child:IsA("TextButton") then
								child.BackgroundColor3 = C.inputBg
								child.TextColor3 = C.text
							end
						end
						b.BackgroundColor3 = C.btnBg
						b.TextColor3 = C.btnText
					end)

					idx += 1
				end
			end
		end
	end
	scanList.CanvasSize = UDim2.new(0, 0, 0, idx * 32)
end)

--// ===== SCAN TOGGLE =====
scanOpenBtn.MouseButton1Click:Connect(function()
	scanFrame.Visible = not scanFrame.Visible
	if scanFrame.Visible then
		scanOpenBtn.Text = "🔍  CLOSE SCAN MENU"
	else
		scanOpenBtn.Text = "🔍  OPEN SCAN MENU"
	end
end)

scanCloseBtn.MouseButton1Click:Connect(function()
	scanFrame.Visible = false
	scanOpenBtn.Text = "🔍  OPEN SCAN MENU"
end)

--// ===== COLLAPSE =====
collapseBtn.MouseButton1Click:Connect(function()
	isCollapsed = not isCollapsed
	local targetH = isCollapsed and TITLE_H or (TITLE_H + BODY_H)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(mainFrame, tweenInfo, {
		Size = UDim2.new(0, MAIN_W, 0, targetH)
	})
	tween:Play()
	bodyFrame.Visible = not isCollapsed
	collapseBtn.Text = isCollapsed and "▸" or "▾"
end)

--// ===== CLOSE =====
closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	scanFrame.Visible = false
end)

--// ===== DRAGGABLE =====
makeDraggable(titleBar, mainFrame)
makeDraggable(scanTitle, scanFrame)

--// ===== REOPEN BUTTON (when closed) =====
local reopenBtn = Instance.new("TextButton", gui)
reopenBtn.Size = UDim2.new(0, 80, 0, 30)
reopenBtn.Position = UDim2.new(0, 20, 0, 20)
reopenBtn.BackgroundColor3 = C.titleBg
reopenBtn.Text = "⚔ AIM"
reopenBtn.TextColor3 = C.titleText
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 13
reopenBtn.BorderSizePixel = 0
reopenBtn.Visible = false
makeCorner(reopenBtn, 8)

closeBtn.MouseButton1Click:Connect(function()
	reopenBtn.Visible = true
end)

reopenBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	reopenBtn.Visible = false
end)
