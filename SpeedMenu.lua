--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local camera = workspace.CurrentCamera

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "Light_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local ok = pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
		gui.Parent = game.CoreGui
	elseif gethui then
		gui.Parent = gethui()
	end
end)
if not ok or not gui.Parent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

--// COLORS
local BG      = Color3.fromRGB(15, 15, 20)
local PANEL   = Color3.fromRGB(25, 25, 32)
local BTN     = Color3.fromRGB(35, 35, 45)
local ACCENT  = Color3.fromRGB(100, 180, 255)
local ON_COL  = Color3.fromRGB(60, 200, 120)
local OFF_COL = Color3.fromRGB(200, 70, 70)
local WHITE   = Color3.fromRGB(230, 230, 255)
local DIM     = Color3.fromRGB(120, 120, 150)

local function corner(r, p)
	local c = Instance.new("UICorner", p)
	c.CornerRadius = UDim.new(0, r)
end
local function pad(p, t, b, l, r)
	local u = Instance.new("UIPadding", p)
	u.PaddingTop    = UDim.new(0, t)
	u.PaddingBottom = UDim.new(0, b)
	u.PaddingLeft   = UDim.new(0, l)
	u.PaddingRight  = UDim.new(0, r)
end
local function setToggle(btn, label, state)
	btn.Text = label .. (state and "  ON" or "  OFF")
	btn.BackgroundColor3 = state and ON_COL or OFF_COL
end

--// DEFAULT
local default = {
	Brightness     = Lighting.Brightness,
	ClockTime      = Lighting.ClockTime,
	GlobalShadows  = Lighting.GlobalShadows,
	Ambient        = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
}
local defaultWalkSpeed = 16

--// STATE
local brightEnabled = false
local darkEnabled   = false
local speedEnabled  = false
local flyEnabled    = false
local collapsed     = false

local brightnessValue = 5
local darkValue       = 0
local speedValue      = 50
local flySpeed        = 50
local verticalDir     = 0

local lockEnabled  = false
local lockMode     = "Player"
local lockedTarget = nil
local targetList   = {}
local targetIndex  = 1

--// SAFE CHAR
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum  = char:FindFirstChildOfClass("Humanoid")
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil, nil, nil end
	return char, hum, hrp
end

--// FRAME
local FRAME_W   = 185
local TITLE_H   = 28
local CONTENT_H = 380

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, FRAME_W, 0, TITLE_H + CONTENT_H)
frame.Position = UDim2.new(0, 20, 0, 150)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
corner(10, frame)

Instance.new("UIStroke", frame).Color = Color3.fromRGB(60,60,80)

--// TITLE BAR
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = PANEL
titleBar.BorderSizePixel = 0
corner(10, titleBar)

-- fix bottom corners
local fix = Instance.new("Frame", titleBar)
fix.Size = UDim2.new(1, 0, 0.5, 0)
fix.Position = UDim2.new(0, 0, 0.5, 0)
fix.BackgroundColor3 = PANEL
fix.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1, -55, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.Text = "⚡ Light System"
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3 = ACCENT
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local collapseBtn = Instance.new("TextButton", titleBar)
collapseBtn.Size = UDim2.new(0, 22, 0, 22)
collapseBtn.Position = UDim2.new(1, -50, 0, 3)
collapseBtn.Text = "▼"
collapseBtn.BackgroundColor3 = BTN
collapseBtn.TextColor3 = ACCENT
collapseBtn.TextSize = 11
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.BorderSizePixel = 0
corner(6, collapseBtn)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -25, 0, 3)
closeBtn.Text = "✕"
closeBtn.BackgroundColor3 = OFF_COL
closeBtn.TextColor3 = WHITE
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
corner(6, closeBtn)

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -10, 1, -(TITLE_H + 4))
scroll.Position = UDim2.new(0, 5, 0, TITLE_H + 2)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = ACCENT
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
pad(scroll, 4, 4, 0, 0)

--// BLOCK BUILDER
local function createBlock(label, placeholder, order)
	local f = Instance.new("Frame", scroll)
	f.Size = UDim2.new(1, -4, 0, 52)
	f.BackgroundColor3 = PANEL
	f.BorderSizePixel = 0
	f.LayoutOrder = order
	corner(8, f)
	pad(f, 5, 5, 6, 6)

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1, 0, 0, 20)
	btn.Text = label .. "  OFF"
	btn.BackgroundColor3 = OFF_COL
	btn.TextColor3 = WHITE
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	corner(6, btn)

	local box = Instance.new("TextBox", f)
	box.Size = UDim2.new(1, 0, 0, 18)
	box.Position = UDim2.new(0, 0, 0, 24)
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = DIM
	box.BackgroundColor3 = BTN
	box.TextColor3 = WHITE
	box.TextSize = 11
	box.Font = Enum.Font.Gotham
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	corner(5, box)

	return btn, box
end

local brightBtn, brightBox = createBlock("☀ FullBright", "Brightness (e.g. 5)", 1)
local darkBtn,   darkBox   = createBlock("🌑 Dark",       "Dark value (e.g. 0)", 2)
local speedBtn,  speedBox  = createBlock("⚡ Speed",      "WalkSpeed (e.g. 50)", 3)

--// FLY BLOCK
local flyFrame = Instance.new("Frame", scroll)
flyFrame.Size = UDim2.new(1, -4, 0, 75)
flyFrame.BackgroundColor3 = PANEL
flyFrame.BorderSizePixel = 0
flyFrame.LayoutOrder = 4
corner(8, flyFrame)
pad(flyFrame, 5, 5, 6, 6)

local flyBtn = Instance.new("TextButton", flyFrame)
flyBtn.Size = UDim2.new(1, 0, 0, 20)
flyBtn.Text = "✈ Fly  OFF"
flyBtn.BackgroundColor3 = OFF_COL
flyBtn.TextColor3 = WHITE
flyBtn.TextSize = 12
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BorderSizePixel = 0
corner(6, flyBtn)

local flyBox = Instance.new("TextBox", flyFrame)
flyBox.Size = UDim2.new(1, 0, 0, 18)
flyBox.Position = UDim2.new(0, 0, 0, 24)
flyBox.PlaceholderText = "Fly Speed (e.g. 50)"
flyBox.PlaceholderColor3 = DIM
flyBox.BackgroundColor3 = BTN
flyBox.TextColor3 = WHITE
flyBox.TextSize = 11
flyBox.Font = Enum.Font.Gotham
flyBox.BorderSizePixel = 0
flyBox.ClearTextOnFocus = false
corner(5, flyBox)

local upBtn = Instance.new("TextButton", flyFrame)
upBtn.Size = UDim2.new(0.48, 0, 0, 18)
upBtn.Position = UDim2.new(0, 0, 0, 46)
upBtn.Text = "▲ Up"
upBtn.BackgroundColor3 = BTN
upBtn.TextColor3 = ACCENT
upBtn.TextSize = 12
upBtn.Font = Enum.Font.GothamBold
upBtn.BorderSizePixel = 0
corner(5, upBtn)

local downBtn = Instance.new("TextButton", flyFrame)
downBtn.Size = UDim2.new(0.48, 0, 0, 18)
downBtn.Position = UDim2.new(0.52, 0, 0, 46)
downBtn.Text = "▼ Down"
downBtn.BackgroundColor3 = BTN
downBtn.TextColor3 = ACCENT
downBtn.TextSize = 12
downBtn.Font = Enum.Font.GothamBold
downBtn.BorderSizePixel = 0
corner(5, downBtn)

--// LOCK BLOCK
local lockFrame = Instance.new("Frame", scroll)
lockFrame.Size = UDim2.new(1, -4, 0, 108)
lockFrame.BackgroundColor3 = PANEL
lockFrame.BorderSizePixel = 0
lockFrame.LayoutOrder = 5
corner(8, lockFrame)
pad(lockFrame, 5, 5, 6, 6)

local modeRow = Instance.new("Frame", lockFrame)
modeRow.Size = UDim2.new(1, 0, 0, 20)
modeRow.BackgroundTransparency = 1
modeRow.BorderSizePixel = 0

local modePlayerBtn = Instance.new("TextButton", modeRow)
modePlayerBtn.Size = UDim2.new(0.48, 0, 1, 0)
modePlayerBtn.Text = "Player"
modePlayerBtn.BackgroundColor3 = ACCENT
modePlayerBtn.TextColor3 = BG
modePlayerBtn.TextSize = 11
modePlayerBtn.Font = Enum.Font.GothamBold
modePlayerBtn.BorderSizePixel = 0
corner(5, modePlayerBtn)

local modeNPCBtn = Instance.new("TextButton", modeRow)
modeNPCBtn.Size = UDim2.new(0.48, 0, 1, 0)
modeNPCBtn.Position = UDim2.new(0.52, 0, 0, 0)
modeNPCBtn.Text = "NPC/Monster"
modeNPCBtn.BackgroundColor3 = BTN
modeNPCBtn.TextColor3 = WHITE
modeNPCBtn.TextSize = 11
modeNPCBtn.Font = Enum.Font.GothamBold
modeNPCBtn.BorderSizePixel = 0
corner(5, modeNPCBtn)

local lockBtn = Instance.new("TextButton", lockFrame)
lockBtn.Size = UDim2.new(1, 0, 0, 20)
lockBtn.Position = UDim2.new(0, 0, 0, 24)
lockBtn.Text = "🎯 Lock Target  OFF"
lockBtn.BackgroundColor3 = OFF_COL
lockBtn.TextColor3 = WHITE
lockBtn.TextSize = 12
lockBtn.Font = Enum.Font.GothamBold
lockBtn.BorderSizePixel = 0
corner(6, lockBtn)

local targetLabel = Instance.new("TextLabel", lockFrame)
targetLabel.Size = UDim2.new(1, 0, 0, 16)
targetLabel.Position = UDim2.new(0, 0, 0, 48)
targetLabel.Text = "Target: --"
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = DIM
targetLabel.TextSize = 10
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextXAlignment = Enum.TextXAlignment.Center

local prevBtn = Instance.new("TextButton", lockFrame)
prevBtn.Size = UDim2.new(0.48, 0, 0, 18)
prevBtn.Position = UDim2.new(0, 0, 0, 68)
prevBtn.Text = "◀ Prev"
prevBtn.BackgroundColor3 = BTN
prevBtn.TextColor3 = ACCENT
prevBtn.TextSize = 12
prevBtn.Font = Enum.Font.GothamBold
prevBtn.BorderSizePixel = 0
corner(5, prevBtn)

local nextBtn = Instance.new("TextButton", lockFrame)
nextBtn.Size = UDim2.new(0.48, 0, 0, 18)
nextBtn.Position = UDim2.new(0.52, 0, 0, 68)
nextBtn.Text = "Next ▶"
nextBtn.BackgroundColor3 = BTN
nextBtn.TextColor3 = ACCENT
nextBtn.TextSize = 12
nextBtn.Font = Enum.Font.GothamBold
nextBtn.BorderSizePixel = 0
corner(5, nextBtn)

--// LIGHTING
local function applyLighting()
	if brightEnabled then
		Lighting.Brightness = brightnessValue
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(180,180,180)
		Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
	elseif darkEnabled then
		Lighting.Brightness = darkValue
		Lighting.ClockTime = 0
		Lighting.GlobalShadows = true
		Lighting.Ambient = Color3.fromRGB(0,0,0)
		Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
	else
		for k, v in pairs(default) do Lighting[k] = v end
	end
end

--// SPEED
local function applySpeed()
	local _, hum = getChar()
	if hum then
		hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed
	end
end

--// FLY
local flyConn
local bv, bg

local function startFly()
	local _, hum, hrp = getChar()
	if not hrp then return end
	hum.PlatformStand = true
	bv = Instance.new("BodyVelocity", hrp)
	bv.MaxForce = Vector3.new(1e5,1e5,1e5)
	bg = Instance.new("BodyGyro", hrp)
	bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
	flyConn = RunService.RenderStepped:Connect(function()
		local moveDir = hum.MoveDirection
		local dir = moveDir + Vector3.new(0, verticalDir, 0)
		bv.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
		bg.CFrame = camera.CFrame
	end)
end

local function stopFly()
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if bv then bv:Destroy() bv = nil end
	if bg then bg:Destroy() bg = nil end
	local _, hum = getChar()
	if hum then hum.PlatformStand = false end
end

--// LOCK SYSTEM
local lockConn
local dmgConn

local function getTargetRoot(t)
	if not t or not t.Parent then return nil end
	return t:FindFirstChild("HumanoidRootPart") or t:FindFirstChildOfClass("Part")
end

local function buildTargetList()
	targetList = {}
	local playerChars = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then playerChars[p.Character] = true end
	end
	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				table.insert(targetList, p.Character)
			end
		end
	else
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and not playerChars[obj] and obj:FindFirstChildOfClass("Humanoid") then
				table.insert(targetList, obj)
			end
		end
	end
	local myChar = player.Character
	local origin = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if origin then
		table.sort(targetList, function(a, b)
			local ra = getTargetRoot(a)
			local rb = getTargetRoot(b)
			if not ra then return false end
			if not rb then return true end
			return (ra.Position - origin.Position).Magnitude < (rb.Position - origin.Position).Magnitude
		end)
	end
end

local function getFrontTarget()
	buildTargetList()
	if #targetList == 0 then return nil, 1 end
	local bestIdx = 1
	local bestDot = -math.huge
	local camCF = camera.CFrame
	for i, t in ipairs(targetList) do
		local root = getTargetRoot(t)
		if root then
			local dir = (root.Position - camCF.Position).Unit
			local dot = camCF.LookVector:Dot(dir)
			if dot > bestDot then
				bestDot = dot
				bestIdx = i
			end
		end
	end
	return targetList[bestIdx], bestIdx
end

local function startLock()
	if lockConn then lockConn:Disconnect() lockConn = nil end
	buildTargetList()
	if #targetList == 0 then
		targetLabel.Text = "Target: (none)"
		return
	end
	lockedTarget, targetIndex = getFrontTarget()
	targetLabel.Text = "Target: " .. (lockedTarget and lockedTarget.Name or "--")

	lockConn = RunService.RenderStepped:Connect(function()
		if not lockEnabled then return end
		local root = getTargetRoot(lockedTarget)
		if not root then
			buildTargetList()
			if #targetList == 0 then
				lockedTarget = nil
				targetLabel.Text = "Target: (none)"
				return
			end
			targetIndex = math.clamp(targetIndex, 1, #targetList)
			lockedTarget = targetList[targetIndex]
			targetLabel.Text = "Target: " .. lockedTarget.Name
			root = getTargetRoot(lockedTarget)
			if not root then return end
		end
		local myChar = player.Character
		local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local toTarget = (root.Position - hrp.Position) * Vector3.new(1,0,1)
		if toTarget.Magnitude > 0.1 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + toTarget)
		end
		local camPos = camera.CFrame.Position
		camera.CFrame = CFrame.lookAt(camPos, root.Position + Vector3.new(0,2,0))
	end)
end

local function stopLock()
	if lockConn then lockConn:Disconnect() lockConn = nil end
	lockedTarget = nil
	targetLabel.Text = "Target: --"
end

local function switchTarget(dir)
	buildTargetList()
	if #targetList == 0 then targetLabel.Text = "Target: (none)" return end
	targetIndex = ((targetIndex - 1 + dir) % #targetList) + 1
	lockedTarget = targetList[targetIndex]
	targetLabel.Text = "Target: " .. lockedTarget.Name
end

local function setupDamageWatch()
	if dmgConn then dmgConn:Disconnect() dmgConn = nil end
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	dmgConn = hum.HealthChanged:Connect(function()
		if not lockEnabled then return end
		local myHRP = char:FindFirstChild("HumanoidRootPart")
		if not myHRP then return end
		local playerChars = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then playerChars[p.Character] = true end
		end
		local allTargets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then table.insert(allTargets, p.Character) end
		end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and not playerChars[obj] and obj:FindFirstChildOfClass("Humanoid") then
				table.insert(allTargets, obj)
			end
		end
		local best, bestDist = nil, math.huge
		for _, t in ipairs(allTargets) do
			local root = getTargetRoot(t)
			if root then
				local d = (root.Position - myHRP.Position).Magnitude
				if d < bestDist and d < 60 then
					bestDist = d
					best = t
				end
			end
		end
		if best then
			lockedTarget = best
			targetLabel.Text = "⚠ " .. best.Name
		end
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(1)
	setupDamageWatch()
	if lockEnabled then startLock() end
	if speedEnabled then applySpeed() end
end)
task.spawn(setupDamageWatch)

--// BUTTONS
brightBtn.MouseButton1Click:Connect(function()
	brightEnabled = not brightEnabled
	if brightEnabled then darkEnabled = false end
	setToggle(brightBtn, "☀ FullBright", brightEnabled)
	setToggle(darkBtn,   "🌑 Dark",       darkEnabled)
	applyLighting()
end)

darkBtn.MouseButton1Click:Connect(function()
	darkEnabled = not darkEnabled
	if darkEnabled then brightEnabled = false end
	setToggle(darkBtn,   "🌑 Dark",       darkEnabled)
	setToggle(brightBtn, "☀ FullBright", brightEnabled)
	applyLighting()
end)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	setToggle(speedBtn, "⚡ Speed", speedEnabled)
	applySpeed()
end)

flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	setToggle(flyBtn, "✈ Fly", flyEnabled)
	if flyEnabled then startFly() else stopFly() end
end)

upBtn.MouseButton1Down:Connect(function()   verticalDir =  1 end)
upBtn.MouseButton1Up:Connect(function()     verticalDir =  0 end)
downBtn.MouseButton1Down:Connect(function() verticalDir = -1 end)
downBtn.MouseButton1Up:Connect(function()   verticalDir =  0 end)

local function updateModeUI()
	if lockMode == "Player" then
		modePlayerBtn.BackgroundColor3 = ACCENT modePlayerBtn.TextColor3 = BG
		modeNPCBtn.BackgroundColor3 = BTN       modeNPCBtn.TextColor3 = WHITE
	else
		modeNPCBtn.BackgroundColor3 = ACCENT    modeNPCBtn.TextColor3 = BG
		modePlayerBtn.BackgroundColor3 = BTN    modePlayerBtn.TextColor3 = WHITE
	end
end

modePlayerBtn.MouseButton1Click:Connect(function()
	lockMode = "Player" updateModeUI()
	if lockEnabled then startLock() end
end)
modeNPCBtn.MouseButton1Click:Connect(function()
	lockMode = "NPC" updateModeUI()
	if lockEnabled then startLock() end
end)

lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	setToggle(lockBtn, "🎯 Lock Target", lockEnabled)
	if lockEnabled then
		camera.CameraType = Enum.CameraType.Scriptable
		startLock()
	else
		camera.CameraType = Enum.CameraType.Custom
		stopLock()
	end
end)

prevBtn.MouseButton1Click:Connect(function() switchTarget(-1) end)
nextBtn.MouseButton1Click:Connect(function() switchTarget(1)  end)

brightBox.FocusLost:Connect(function()
	local n = tonumber(brightBox.Text)
	if n then brightnessValue = n if brightEnabled then applyLighting() end end
end)
darkBox.FocusLost:Connect(function()
	local n = tonumber(darkBox.Text)
	if n then darkValue = n if darkEnabled then applyLighting() end end
end)
speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n then speedValue = n if speedEnabled then applySpeed() end end
end)
flyBox.FocusLost:Connect(function()
	local n = tonumber(flyBox.Text)
	if n then flySpeed = n end
end)

--// CLOSE
closeBtn.MouseButton1Click:Connect(function()
	stopFly()
	stopLock()
	camera.CameraType = Enum.CameraType.Custom
	brightEnabled = false darkEnabled = false speedEnabled = false
	applyLighting()
	applySpeed()
	gui:Destroy()
end)

--// COLLAPSE
collapseBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	if collapsed then
		frame:TweenSize(UDim2.new(0, FRAME_W, 0, TITLE_H), "Out", "Quad", 0.2, true)
		collapseBtn.Text = "▶"
	else
		frame:TweenSize(UDim2.new(0, FRAME_W, 0, TITLE_H + CONTENT_H), "Out", "Quad", 0.2, true)
		collapseBtn.Text = "▼"
	end
end)

--// DRAG
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and 
