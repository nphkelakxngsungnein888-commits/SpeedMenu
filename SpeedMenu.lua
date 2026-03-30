--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "Light_UI"
gui.ResetOnSpawn = false
pcall(function()
	if syn and syn.protect_gui then syn.protect_gui(gui) gui.Parent = game.CoreGui
	elseif gethui then gui.Parent = gethui()
	else gui.Parent = player:WaitForChild("PlayerGui") end
end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

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
	local c = Instance.new("UICorner", p) c.CornerRadius = UDim.new(0, r)
end
local function pad(p, t, b, l, r)
	local u = Instance.new("UIPadding", p)
	u.PaddingTop = UDim.new(0,t) u.PaddingBottom = UDim.new(0,b)
	u.PaddingLeft = UDim.new(0,l) u.PaddingRight = UDim.new(0,r)
end

--// DEFAULT
local default = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
	GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient
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

--// LOCK-ON STATE
local lockMode       = "Player" -- "Player" or "NPC"
local lockEnabled    = false
local lockTarget     = nil
local targetList     = {}
local targetIndex    = 1
local lockConn       = nil
local damageConn     = nil

--// SAFE CHAR
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum  = char:FindFirstChildOfClass("Humanoid")
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil end
	return char, hum, hrp
end

--// ============ MAIN FRAME ============
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 185, 0, 310)
frame.Position = UDim2.new(0.05, 0, 0.25, 0)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
corner(10, frame)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 80) stroke.Thickness = 1

--// TITLE BAR
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = PANEL
titleBar.BorderSizePixel = 0
corner(10, titleBar)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = PANEL titleFix.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -55, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "⚡ Light System"
title.BackgroundTransparency = 1
title.TextColor3 = ACCENT title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

-- Collapse button
local collapseBtn = Instance.new("TextButton", titleBar)
collapseBtn.Size = UDim2.new(0, 22, 0, 22)
collapseBtn.Position = UDim2.new(1, -50, 0, 3)
collapseBtn.Text = "▼"
collapseBtn.BackgroundColor3 = BTN
collapseBtn.TextColor3 = WHITE collapseBtn.TextSize = 11
collapseBtn.Font = Enum.Font.GothamBold collapseBtn.BorderSizePixel = 0
corner(6, collapseBtn)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -25, 0, 3)
closeBtn.Text = "✕"
closeBtn.BackgroundColor3 = OFF_COL
closeBtn.TextColor3 = WHITE closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold closeBtn.BorderSizePixel = 0
corner(6, closeBtn)

--// SCROLL BODY
local body = Instance.new("Frame", frame)
body.Size = UDim2.new(1, 0, 1, -28)
body.Position = UDim2.new(0, 0, 0, 28)
body.BackgroundTransparency = 1
body.ClipsDescendants = true

local scroll = Instance.new("ScrollingFrame", body)
scroll.Size = UDim2.new(1, -10, 1, 0)
scroll.Position = UDim2.new(0, 5, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = ACCENT

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
pad(scroll, 4, 4, 0, 0)

--// BLOCK BUILDER
local function createBlock(label, placeholder, order)
	local f = Instance.new("Frame", scroll)
	f.Size = UDim2.new(1, -4, 0, 52) f.BackgroundColor3 = PANEL
	f.BorderSizePixel = 0 f.LayoutOrder = order
	corner(8, f) pad(f, 5, 5, 6, 6)

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1, 0, 0, 20)
	btn.Text = label .. "  OFF"
	btn.BackgroundColor3 = OFF_COL btn.TextColor3 = WHITE
	btn.TextSize = 12 btn.Font = Enum.Font.GothamBold btn.BorderSizePixel = 0
	corner(6, btn)

	local box = Instance.new("TextBox", f)
	box.Size = UDim2.new(1, 0, 0, 18) box.Position = UDim2.new(0, 0, 0, 24)
	box.PlaceholderText = placeholder box.PlaceholderColor3 = DIM
	box.BackgroundColor3 = BTN box.TextColor3 = WHITE
	box.TextSize = 11 box.Font = Enum.Font.Gotham
	box.BorderSizePixel = 0 box.ClearTextOnFocus = false
	corner(5, box)
	return btn, box
end

local function setToggle(btn, label, state)
	btn.Text = label .. (state and "  ON" or "  OFF")
	btn.BackgroundColor3 = state and ON_COL or OFF_COL
end

local brightBtn, brightBox = createBlock("☀ FullBright", "Brightness (e.g. 5)", 1)
local darkBtn,   darkBox   = createBlock("🌑 Dark",       "Dark value (e.g. 0)", 2)
local speedBtn,  speedBox  = createBlock("⚡ Speed",      "WalkSpeed (e.g. 50)", 3)

--// FLY BLOCK
local flyFrame = Instance.new("Frame", scroll)
flyFrame.Size = UDim2.new(1, -4, 0, 75) flyFrame.BackgroundColor3 = PANEL
flyFrame.BorderSizePixel = 0 flyFrame.LayoutOrder = 4
corner(8, flyFrame) pad(flyFrame, 5, 5, 6, 6)

local flyBtn = Instance.new("TextButton", flyFrame)
flyBtn.Size = UDim2.new(1, 0, 0, 20) flyBtn.Text = "✈ Fly  OFF"
flyBtn.BackgroundColor3 = OFF_COL flyBtn.TextColor3 = WHITE
flyBtn.TextSize = 12 flyBtn.Font = Enum.Font.GothamBold flyBtn.BorderSizePixel = 0
corner(6, flyBtn)

local flyBox = Instance.new("TextBox", flyFrame)
flyBox.Size = UDim2.new(1, 0, 0, 18) flyBox.Position = UDim2.new(0, 0, 0, 24)
flyBox.PlaceholderText = "Fly Speed (e.g. 50)" flyBox.PlaceholderColor3 = DIM
flyBox.BackgroundColor3 = BTN flyBox.TextColor3 = WHITE
flyBox.TextSize = 11 flyBox.Font = Enum.Font.Gotham
flyBox.BorderSizePixel = 0 flyBox.ClearTextOnFocus = false
corner(5, flyBox)

local upBtn = Instance.new("TextButton", flyFrame)
upBtn.Size = UDim2.new(0.48, 0, 0, 18) upBtn.Position = UDim2.new(0, 0, 0, 46)
upBtn.Text = "▲ Up" upBtn.BackgroundColor3 = BTN upBtn.TextColor3 = ACCENT
upBtn.TextSize = 12 upBtn.Font = Enum.Font.GothamBold upBtn.BorderSizePixel = 0
corner(5, upBtn)

local downBtn = Instance.new("TextButton", flyFrame)
downBtn.Size = UDim2.new(0.48, 0, 0, 18) downBtn.Position = UDim2.new(0.52, 0, 0, 46)
downBtn.Text = "▼ Down" downBtn.BackgroundColor3 = BTN downBtn.TextColor3 = ACCENT
downBtn.TextSize = 12 downBtn.Font = Enum.Font.GothamBold downBtn.BorderSizePixel = 0
corner(5, downBtn)

--// ============ LOCK-ON BLOCK ============
local lockFrame = Instance.new("Frame", scroll)
lockFrame.Size = UDim2.new(1, -4, 0, 100)
lockFrame.BackgroundColor3 = PANEL
lockFrame.BorderSizePixel = 0 lockFrame.LayoutOrder = 5
corner(8, lockFrame) pad(lockFrame, 5, 5, 6, 6)

-- Mode selector (Player / NPC)
local modeRow = Instance.new("Frame", lockFrame)
modeRow.Size = UDim2.new(1, 0, 0, 20) modeRow.BackgroundTransparency = 1

local modePlayerBtn = Instance.new("TextButton", modeRow)
modePlayerBtn.Size = UDim2.new(0.48, 0, 1, 0)
modePlayerBtn.Text = "👤 Player"
modePlayerBtn.BackgroundColor3 = ACCENT
modePlayerBtn.TextColor3 = BG modePlayerBtn.TextSize = 11
modePlayerBtn.Font = Enum.Font.GothamBold modePlayerBtn.BorderSizePixel = 0
corner(6, modePlayerBtn)

local modeNpcBtn = Instance.new("TextButton", modeRow)
modeNpcBtn.Size = UDim2.new(0.48, 0, 1, 0)
modeNpcBtn.Position = UDim2.new(0.52, 0, 0, 0)
modeNpcBtn.Text = "👾 NPC"
modeNpcBtn.BackgroundColor3 = BTN
modeNpcBtn.TextColor3 = WHITE modeNpcBtn.TextSize = 11
modeNpcBtn.Font = Enum.Font.GothamBold modeNpcBtn.BorderSizePixel = 0
corner(6, modeNpcBtn)

-- Lock toggle
local lockBtn = Instance.new("TextButton", lockFrame)
lockBtn.Size = UDim2.new(1, 0, 0, 20)
lockBtn.Position = UDim2.new(0, 0, 0, 24)
lockBtn.Text = "🎯 Lock-On  OFF"
lockBtn.BackgroundColor3 = OFF_COL lockBtn.TextColor3 = WHITE
lockBtn.TextSize = 12 lockBtn.Font = Enum.Font.GothamBold lockBtn.BorderSizePixel = 0
corner(6, lockBtn)

-- Target name display
local targetLabel = Instance.new("TextLabel", lockFrame)
targetLabel.Size = UDim2.new(1, 0, 0, 16)
targetLabel.Position = UDim2.new(0, 0, 0, 48)
targetLabel.Text = "Target: —"
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = DIM targetLabel.TextSize = 11
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Prev / Next target buttons
local prevBtn = Instance.new("TextButton", lockFrame)
prevBtn.Size = UDim2.new(0.3, 0, 0, 20)
prevBtn.Position = UDim2.new(0, 0, 0, 68)
prevBtn.Text = "◀ Prev"
prevBtn.BackgroundColor3 = BTN prevBtn.TextColor3 = ACCENT
prevBtn.TextSize = 11 prevBtn.Font = Enum.Font.GothamBold prevBtn.BorderSizePixel = 0
corner(5, prevBtn)

local nextBtn = Instance.new("TextButton", lockFrame)
nextBtn.Size = UDim2.new(0.3, 0, 0, 20)
nextBtn.Position = UDim2.new(0.7, 0, 0, 68)
nextBtn.Text = "Next ▶"
nextBtn.BackgroundColor3 = BTN nextBtn.TextColor3 = ACCENT
nextBtn.TextSize = 11 nextBtn.Font = Enum.Font.GothamBold nextBtn.BorderSizePixel = 0
corner(5, nextBtn)

local lockIndexLabel = Instance.new("TextLabel", lockFrame)
lockIndexLabel.Size = UDim2.new(0.36, 0, 0, 20)
lockIndexLabel.Position = UDim2.new(0.32, 0, 0, 68)
lockIndexLabel.Text = "0 / 0"
lockIndexLabel.BackgroundTransparency = 1
lockIndexLabel.TextColor3 = WHITE lockIndexLabel.TextSize = 11
lockIndexLabel.Font = Enum.Font.Gotham
lockIndexLabel.TextXAlignment = Enum.TextXAlignment.Center

--// ============ LOCK-ON LOGIC ============

local function updateTargetUI()
	if lockTarget then
		targetLabel.Text = "Target: " .. (lockTarget.Name or "?")
		lockIndexLabel.Text = targetIndex .. " / " .. #targetList
	else
		targetLabel.Text = "Target: —"
		lockIndexLabel.Text = "0 / 0"
	end
end

local function getHRP(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

local function isAlive(model)
	if not model then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function buildTargetList()
	targetList = {}
	local char = player.Character
	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and getHRP(p.Character) and isAlive(p.Character) then
				table.insert(targetList, p.Character)
			end
		end
	else
		-- NPC: any model in workspace with Humanoid that isn't a player character
		local playerChars = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then playerChars[p.Character] = true end
		end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Humanoid") and obj.Health > 0 then
				local model = obj.Parent
				if model and not playerChars[model] and getHRP(model) then
					table.insert(targetList, model)
				end
			end
		end
	end
end

local function getNearestTarget()
	local _, _, myHRP = getChar()
	if not myHRP then return nil, 1 end
	local closest, closestDist, closestIdx = nil, math.huge, 1
	for i, t in ipairs(targetList) do
		local hrp = getHRP(t)
		if hrp then
			local d = (hrp.Position - myHRP.Position).Magnitude
			if d < closestDist then
				closestDist = d closest = t closestIdx = i
			end
		end
	end
	return closest, closestIdx
end

local function applyLockOn()
	if lockConn then lockConn:Disconnect() lockConn = nil end
	if not lockEnabled or not lockTarget then return end

	lockConn = RunService.RenderStepped:Connect(function()
		if not isAlive(lockTarget) then
			-- target died, try next
			buildTargetList()
			if #targetList > 0 then
				targetIndex = math.min(targetIndex, #targetList)
				lockTarget = targetList[targetIndex]
			else
				lockTarget = nil
			end
			updateTargetUI()
			if not lockTarget then return end
		end

		local hrp = getHRP(lockTarget)
		if not hrp then return end
		local _, _, myHRP = getChar()
		if not myHRP then return end

		local cam = workspace.CurrentCamera
		local targetPos = hrp.Position + Vector3.new(0, 1.5, 0)
		local camPos = cam.CFrame.Position

		-- Smoothly rotate camera toward target
		local lookCF = CFrame.lookAt(camPos, targetPos)
		cam.CFrame = cam.CFrame:Lerp(lookCF, 0.15)

		-- Rotate character HRP toward target (horizontal only)
		local dir = (hrp.Position - myHRP.Position) * Vector3.new(1, 0, 1)
		if dir.Magnitude > 0.5 then
			myHRP.CFrame = CFrame.lookAt(myHRP.Position, myHRP.Position + dir)
		end
	end)
end

local function setLockTarget(model)
	lockTarget = model
	updateTargetUI()
	applyLockOn()
end

local function stopLockOn()
	if lockConn then lockConn:Disconnect() lockConn = nil end
	lockTarget = nil
	updateTargetUI()
end

-- Auto-lock on damage
local function setupDamageDetect()
	if damageConn then damageConn:Disconnect() damageConn = nil end
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local lastHP = hum.Health
	damageConn = hum.HealthChanged:Connect(function(newHP)
		if newHP < lastHP and lockEnabled then
			-- find closest player or NPC that could be attacker
			buildTargetList()
			local nearest, idx = getNearestTarget()
			if nearest then
				targetIndex = idx
				setLockTarget(nearest)
			end
		end
		lastHP = newHP
	end)
end

player.CharacterAdded:Connect(function()
	task.wait(1)
	setupDamageDetect()
	if lockEnabled then
		buildTargetList()
		local nearest, idx = getNearestTarget()
		targetIndex = idx lockTarget = nearest
		updateTargetUI() applyLockOn()
	end
end)

--// MODE BUTTONS
local function updateModeUI()
	modePlayerBtn.BackgroundColor3 = lockMode == "Player" and ACCENT or BTN
	modePlayerBtn.TextColor3       = lockMode == "Player" and BG or WHITE
	modeNpcBtn.BackgroundColor3    = lockMode == "NPC"    and ACCENT or BTN
	modeNpcBtn.TextColor3          = lockMode == "NPC"    and BG or WHITE
end

modePlayerBtn.MouseButton1Click:Connect(function()
	lockMode = "Player" updateModeUI()
	if lockEnabled then buildTargetList() local n,i = getNearestTarget() targetIndex=i setLockTarget(n) end
end)

modeNpcBtn.MouseButton1Click:Connect(function()
	lockMode = "NPC" updateModeUI()
	if lockEnabled then buildTargetList() local n,i = getNearestTarget() targetIndex=i setLockTarget(n) end
end)

lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	setToggle(lockBtn, "🎯 Lock-On", lockEnabled)
	if lockEnabled then
		buildTargetList()
		local nearest, idx = getNearestTarget()
		targetIndex = idx
		setLockTarget(nearest)
		setupDamageDetect()
	else
		stopLockOn()
		if damageConn then damageConn:Disconnect() damageConn = nil end
	end
end)

prevBtn.MouseButton1Click:Connect(function()
	if #targetList == 0 then buildTargetList() end
	if #targetList == 0 then return end
	targetIndex = targetIndex - 1
	if targetIndex < 1 then targetIndex = #targetList end
	setLockTarget(targetList[targetIndex])
end)

nextBtn.MouseButton1Click:Connect(function()
	if #targetList == 0 then buildTargetList() end
	if #targetList == 0 then return end
	targetIndex = targetIndex + 1
	if targetIndex > #targetList then targetIndex = 1 end
	setLockTarget(targetList[targetIndex])
end)

updateModeUI()

--// ============ LIGHTING ============
local function applyLighting()
	if brightEnabled then
		Lighting.Brightness = brightnessValue Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(180,180,180)
		Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
	elseif darkEnabled then
		Lighting.Brightness = darkValue Lighting.ClockTime = 0
		Lighting.GlobalShadows = true
		Lighting.Ambient = Color3.fromRGB(0,0,0)
		Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
	else
		for k, v in pairs(default) do Lighting[k] = v end
	end
end

local function applySpeed()
	local _, hum = getChar()
	if hum then hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed end
end

--// FLY
local flyConn
local bv, bg

local function startFly()
	local _, hum, hrp = getChar() if not hrp then return end
	hum.PlatformStand = true
	bv = Instance.new("BodyVelocity", hrp) bv.MaxForce = Vector3.new(1e5,1e5,1e5)
	bg = Instance.new("BodyGyro", hrp) bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
	flyConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local dir = hum.MoveDirection + Vector3.new(0, verticalDir, 0)
		bv.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
		bg.CFrame = cam.CFrame
	end)
end

local function stopFly()
	if flyConn then flyConn:Disconnect() end
	if bv then bv:Destroy() end
	if bg then bg:Destroy() end
	local _, hum = getChar() if hum then hum.PlatformStand = false end
end

--// BUTTON LOGIC
brightBtn.MouseButton1Click:Connect(function()
	brightEnabled = not brightEnabled
	if brightEnabled then darkEnabled = false end
	setToggle(brightBtn, "☀ FullBright", brightEnabled)
	setToggle(darkBtn, "🌑 Dark", darkEnabled)
	applyLighting()
end)

darkBtn.MouseButton1Click:Connect(function()
	darkEnabled = not darkEnabled
	if darkEnabled then brightEnabled = false end
	setToggle(darkBtn, "🌑 Dark", darkEnabled)
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

upBtn.MouseButton1Down:Connect(function() verticalDir = 1 end)
upBtn.MouseButton1Up:Connect(function() verticalDir = 0 end)
downBtn.MouseButton1Down:Connect(function() verticalDir = -1 end)
downBtn.MouseButton1Up:Connect(function() verticalDir = 0 end)

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
	local n = tonumber(flyBox.Text) if n then flySpeed = n end
end)

--// COLLAPSE
collapseBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	body.Visible = not collapsed
	collapseBtn.Text = collapsed and "▶" or "▼"
	frame.Size = collapsed
		and UDim2.new(0, 185, 0, 28)
		or  UDim2.new(0, 185, 0, 310)
end)

--// CLOSE
closeBtn.MouseButton1Click:Connect(function()
	stopFly() stopLockOn()
	brightEnabled = false darkEnabled = false speedEnabled = fals
