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
local function setToggle(btn, label, state)
	btn.Text = label .. (state and "  ON" or "  OFF")
	btn.BackgroundColor3 = state and ON_COL or OFF_COL
end

--// DEFAULT LIGHTING
local default = {
	Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
	GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient
}
local defaultWalkSpeed = 16

--// STATE
local brightEnabled, darkEnabled, speedEnabled, flyEnabled = false, false, false, false
local lockEnabled = false
local lockMode    = "Player" -- "Player" or "NPC"
local brightnessValue, darkValue, speedValue, flySpeed = 5, 0, 50, 50
local verticalDir = 0
local currentTarget = nil
local lockConn, flyConn
local bv, bg
local minimized = false

--// SAFE CHAR
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil end
	return char, hum, hrp
end

--// MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 180, 0, 340)
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
titleFix.BackgroundColor3 = PANEL
titleFix.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -55, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "⚡ Light System"
title.BackgroundTransparency = 1
title.TextColor3 = ACCENT
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -50, 0, 3)
minBtn.Text = "—"
minBtn.BackgroundColor3 = BTN
minBtn.TextColor3 = WHITE
minBtn.TextSize = 11
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
corner(6, minBtn)

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
scroll.Size = UDim2.new(1, -10, 1, -34)
scroll.Position = UDim2.new(0, 5, 0, 30)
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
	btn.Size = UDim2.new(1, 0, 0, 20) btn.Text = label .. "  OFF"
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

local brightBtn, brightBox = createBlock("☀ FullBright", "Brightness (e.g. 5)", 1)
local darkBtn,   darkBox   = createBlock("🌑 Dark",      "Dark value (e.g. 0)", 2)
local speedBtn,  speedBox  = createBlock("⚡ Speed",     "WalkSpeed (e.g. 50)", 3)

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

--// LOCK BLOCK
local lockFrame = Instance.new("Frame", scroll)
lockFrame.Size = UDim2.new(1, -4, 0, 100) lockFrame.BackgroundColor3 = PANEL
lockFrame.BorderSizePixel = 0 lockFrame.LayoutOrder = 5
corner(8, lockFrame) pad(lockFrame, 5, 5, 6, 6)

-- Mode toggle (Player / NPC)
local modeRow = Instance.new("Frame", lockFrame)
modeRow.Size = UDim2.new(1, 0, 0, 20) modeRow.BackgroundTransparency = 1

local modePlrBtn = Instance.new("TextButton", modeRow)
modePlrBtn.Size = UDim2.new(0.48, 0, 1, 0)
modePlrBtn.Text = "👤 Player" modePlrBtn.BackgroundColor3 = ACCENT
modePlrBtn.TextColor3 = BG modePlrBtn.TextSize = 11
modePlrBtn.Font = Enum.Font.GothamBold modePlrBtn.BorderSizePixel = 0
corner(6, modePlrBtn)

local modeNpcBtn = Instance.new("TextButton", modeRow)
modeNpcBtn.Size = UDim2.new(0.48, 0, 1, 0) modeNpcBtn.Position = UDim2.new(0.52, 0, 0, 0)
modeNpcBtn.Text = "🤖 NPC" modeNpcBtn.BackgroundColor3 = BTN
modeNpcBtn.TextColor3 = WHITE modeNpcBtn.TextSize = 11
modeNpcBtn.Font = Enum.Font.GothamBold modeNpcBtn.BorderSizePixel = 0
corner(6, modeNpcBtn)

-- Lock ON/OFF button
local lockBtn = Instance.new("TextButton", lockFrame)
lockBtn.Size = UDim2.new(1, 0, 0, 20) lockBtn.Position = UDim2.new(0, 0, 0, 24)
lockBtn.Text = "🎯 Lock  OFF" lockBtn.BackgroundColor3 = OFF_COL
lockBtn.TextColor3 = WHITE lockBtn.TextSize = 12
lockBtn.Font = Enum.Font.GothamBold lockBtn.BorderSizePixel = 0
corner(6, lockBtn)

-- Target label
local targetLabel = Instance.new("TextLabel", lockFrame)
targetLabel.Size = UDim2.new(1, 0, 0, 14) targetLabel.Position = UDim2.new(0, 0, 0, 48)
targetLabel.Text = "Target: —" targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = DIM targetLabel.TextSize = 10
targetLabel.Font = Enum.Font.Gotham targetLabel.TextXAlignment = Enum.TextXAlignment.Left

-- < > buttons
local prevBtn = Instance.new("TextButton", lockFrame)
prevBtn.Size = UDim2.new(0.3, 0, 0, 20) prevBtn.Position = UDim2.new(0, 0, 0, 66)
prevBtn.Text = "< Face" prevBtn.BackgroundColor3 = BTN
prevBtn.TextColor3 = ACCENT prevBtn.TextSize = 11
prevBtn.Font = Enum.Font.GothamBold prevBtn.BorderSizePixel = 0
corner(5, prevBtn)

local nextBtn = Instance.new("TextButton", lockFrame)
nextBtn.Size = UDim2.new(0.3, 0, 0, 20) nextBtn.Position = UDim2.new(0.7, 0, 0, 66)
nextBtn.Text = "Next >" nextBtn.BackgroundColor3 = BTN
nextBtn.TextColor3 = ACCENT nextBtn.TextSize = 11
nextBtn.Font = Enum.Font.GothamBold nextBtn.BorderSizePixel = 0
corner(5, nextBtn)

--// TARGET HELPERS
local function isAlive(model)
	if not model then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function getHRP(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

local function getTargetList()
	local _, _, myHRP = getChar()
	if not myHRP then return {} end
	local list = {}
	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and isAlive(p.Character) then
				local hrp = getHRP(p.Character)
				if hrp then
					table.insert(list, {model = p.Character, hrp = hrp,
						dist = (hrp.Position - myHRP.Position).Magnitude, name = p.Name})
				end
			end
		end
	else
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj ~= player.Character then
				local hum = obj:FindFirstChildOfClass("Humanoid")
				local hrp = getHRP(obj)
				if hum and hum.Health > 0 and hrp then
					table.insert(list, {model = obj, hrp = hrp,
						dist = (hrp.Position - myHRP.Position).Magnitude, name = obj.Name})
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.dist < b.dist end)
	return list
end

local function getNearestTarget()
	local list = getTargetList()
	return list[1] and list[1].model or nil
end

local function getFacingTarget()
	local cam = workspace.CurrentCamera
	local _, _, myHRP = getChar()
	if not myHRP then return nil end
	local list = getTargetList()
	local best, bestDot = nil, -math.huge
	for _, t in ipairs(list) do
		local dir = (t.hrp.Position - cam.CFrame.Position).Unit
		local dot = cam.CFrame.LookVector:Dot(dir)
		if dot > bestDot then bestDot = dot best = t.model end
	end
	return best
end

local function getNextTarget(current)
	local list = getTargetList()
	if #list == 0 then return nil end
	if not current then return list[1].model end
	for i, t in ipairs(list) do
		if t.model == current then
			return list[(i % #list) + 1].model
		end
	end
	return list[1].model
end

local function setTarget(model)
	currentTarget = model
	if model then
		local name = model.Name
		-- trim long names
		if #name > 16 then name = name:sub(1,16) .. "…" end
		targetLabel.Text = "🎯 " .. name
	else
		targetLabel.Text = "Target: —"
	end
end

--// LOCK LOOP
local function stopLock()
	if lockConn then lockConn:Disconnect() lockConn = nil end
end

local function startLock()
	stopLock()
	if not currentTarget then
		local t = getNearestTarget()
		if not t then return end
		setTarget(t)
	end
	lockConn = RunService.RenderStepped:Connect(function()
		-- swap if dead
		if not isAlive(currentTarget) then
			local next = getNearestTarget()
			setTarget(next)
			if not next then stopLock() lockEnabled = false setToggle(lockBtn,"🎯 Lock",false) return end
		end
		local hrp = getHRP(currentTarget)
		if not hrp then return end
		local _, _, myHRP = getChar()
		if not myHRP then return end
		-- rotate character toward target
		local dir = (hrp.Position - myHRP.Position) * Vector3.new(1,0,1)
		if dir.Magnitude > 0.1 then
			myHRP.CFrame = CFrame.lookAt(myHRP.Position, myHRP.Position + dir)
		end
		-- rotate camera toward target
		local cam = workspace.CurrentCamera
		local camPos = cam.CFrame.Position
		cam.CFrame = CFrame.lookAt(camPos, hrp.Position)
	end)
end

--// LIGHTING
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
		for k,v in pairs(default) do Lighting[k] = v end
	end
end

--// SPEED
local function applySpeed()
	local _, hum = getChar()
	if hum then hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed end
end

--// FLY
local function startFly()
	local _, hum, hrp = getChar()
	if not hrp then return end
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
	if bv then bv:Destroy() end if bg then bg:Destroy() end
	local _, hum = getChar()
	if hum then hum.PlatformStand = false end
end

--// MODE BUTTONS
local function updateModeUI()
	if lockMode == "Player" then
		modePlrBtn.BackgroundColor3 = ACCENT modePlrBtn.TextColor3 = BG
		modeNpcBtn.BackgroundColor3 = BTN modeNpcBtn.TextColor3 = WHITE
	else
		modeNpcBtn.BackgroundColor3 = ACCENT modeNpcBtn.TextColor3 = BG
		modePlrBtn.BackgroundColor3 = BTN modePlrBtn.TextColor3 = WHITE
	end
end

modePlrBtn.MouseButton1Click:Connect(function()
	lockMode = "Player" updateModeUI()
	if lockEnabled then setTarget(nil) startLock() end
end)
modeNpcBtn.MouseButton1Click:Connect(function()
	lockMode = "NPC" updateModeUI()
	if lockEnabled then setTarget(nil) startLock() end
end)

--// LOCK BUTTON
lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	setToggle(lockBtn, "🎯 Lock", lockEnabled)
	if lockEnabled then
		setTarget(getNearestTarget())
		startLock()
	else
		stopLock()
		setTarget(nil)
	end
end)

-- Next target (by distance)
nextBtn.MouseButton1Click:Connect(function()
	local next = getNextTarget(currentTarget)
	setTarget(next)
	if lockEnabled and next then startLock() end
end)

-- Face target (closest to crosshair)
prevBtn.MouseButton1Click:Connect(function()
	local t = getFacingTarget()
	setTarget(t)
	if lockEnabled and t then startLock() end
end)

--// OTHER BUTTONS
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

upBtn.MouseButton1Down:Connect(function()   verticalDir =  1 end)
upBtn.MouseButton1Up:Connect(function()     verticalDir =  0 end)
downBtn.MouseButton1Down:Connect(function() verticalDir = -1 end)
downBtn.MouseButton1Up:Connect(function()   verticalDir =  0 end)

--// BOXES
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

--// MINIMIZE
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	scroll.Visible = not minimized
	frame.Size = minimized and UDim2.new(0, 180, 0, 28) or UDim2.new(0, 180, 0, 340)
	minBtn.Text = minimized and "□" or "—"
end)

--// CLOSE
closeBtn.MouseButton1Click:Connect(function()
	stopFly() stopLock()
	brightEnabled = false darkEnabled = false speedEnabled = false
	applyLighting() applySpeed()
	gui:Destroy()
end)

--// DRAG
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true dragStart = input.Position startPos = frame.Position
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
