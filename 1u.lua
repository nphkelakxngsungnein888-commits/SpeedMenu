แก้ให้เลยครับ สรุปที่จะทำ:
แก้ปุ่ม toggle ให้แสดง ON/OFF ถูกต้อง
เพิ่มปุ่ม ↑ ↓ สำหรับบิน
ปรับ UI ให้สวยขึ้น (rounded corners, accent color, spacing)
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
	if syn and syn.protect_gui then  
		syn.protect_gui(gui)  
		gui.Parent = game.CoreGui  
	elseif gethui then  
		gui.Parent = gethui()  
	else  
		gui.Parent = player:WaitForChild("PlayerGui")  
	end  
end)  
if not gui.Parent then  
	gui.Parent = player:WaitForChild("PlayerGui")  
end  
  
--// COLORS  
local BG     = Color3.fromRGB(15, 15, 20)
local PANEL  = Color3.fromRGB(25, 25, 32)
local BTN    = Color3.fromRGB(35, 35, 45)
local ACCENT = Color3.fromRGB(100, 180, 255)
local ON_COL = Color3.fromRGB(60, 200, 120)
local OFF_COL= Color3.fromRGB(200, 70, 70)
local WHITE  = Color3.fromRGB(230, 230, 255)
local DIM    = Color3.fromRGB(120, 120, 150)

--// CORNER HELPER
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

--// DEFAULT  
local default = {  
	Brightness    = Lighting.Brightness,  
	ClockTime     = Lighting.ClockTime,  
	GlobalShadows = Lighting.GlobalShadows,  
	Ambient       = Lighting.Ambient,  
	OutdoorAmbient= Lighting.OutdoorAmbient  
}  
local defaultWalkSpeed = 16  
  
--// STATE  
local brightEnabled = false  
local darkEnabled   = false  
local speedEnabled  = false  
local flyEnabled    = false  
  
local brightnessValue = 5  
local darkValue       = 0  
local speedValue      = 50  
local flySpeed        = 50  
local verticalDir     = 0  
  
--// SAFE CHAR  
local function getChar()  
	local char = player.Character or player.CharacterAdded:Wait()  
	local hum  = char:FindFirstChildOfClass("Humanoid")  
	local hrp  = char:FindFirstChild("HumanoidRootPart")  
	if not hum or not hrp then return nil end  
	return char, hum, hrp  
end  

--// MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 175, 0, 285)
frame.Position = UDim2.new(0.05, 0, 0.28, 0)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
corner(10, frame)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 1

--// TITLE BAR
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = PANEL
titleBar.BorderSizePixel = 0
corner(10, titleBar)

-- fix bottom corners of titlebar
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = PANEL
titleFix.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "⚡ Light System"
title.BackgroundTransparency = 1
title.TextColor3 = ACCENT
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", titleBar)
close.Size = UDim2.new(0, 22, 0, 22)
close.Position = UDim2.new(1, -25, 0, 3)
close.Text = "✕"
close.BackgroundColor3 = OFF_COL
close.TextColor3 = WHITE
close.TextSize = 11
close.Font = Enum.Font.GothamBold
close.BorderSizePixel = 0
corner(6, close)

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

--// TOGGLE LABEL HELPER
local function setToggle(btn, label, state)
	btn.Text = label .. (state and "  ON" or "  OFF")
	btn.BackgroundColor3 = state and ON_COL or OFF_COL
end

local brightBtn, brightBox = createBlock("☀ FullBright", "Brightness (e.g. 5)", 1)
local darkBtn,   darkBox   = createBlock("🌑 Dark",       "Dark value (e.g. 0)", 2)
local speedBtn,  speedBox  = createBlock("⚡ Speed",      "WalkSpeed (e.g. 50)", 3)

--// FLY BLOCK (custom with ↑↓ buttons)
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

-- ↑ ↓ buttons
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
		for k, v in pairs(default) do  
			Lighting[k] = v  
		end  
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
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)  
	bg = Instance.new("BodyGyro", hrp)  
	bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)  
	flyConn = RunService.RenderStepped:Connect(function()  
		local cam = workspace.CurrentCamera  
		local moveDir = hum.MoveDirection  
		local dir = moveDir + Vector3.new(0, verticalDir, 0)  
		bv.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
		bg.CFrame = cam.CFrame  
	end)  
end  
  
local function stopFly()  
	if flyConn then flyConn:Disconnect() end  
	if bv then bv:Destroy() end  
	if bg then bg:Destroy() end  
	local _, hum = getChar()  
	if hum then hum.PlatformStand = false end  
end  
  
--// BUTTON LOGIC

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

-- hold ↑ ↓
upBtn.MouseButton1Down:Connect(function()   verticalDir =  1 end)
upBtn.MouseButton1Up:Connect(function()     verticalDir =  0 end)
downBtn.MouseButton1Down:Connect(function() verticalDir = -1 end)
downBtn.MouseButton1Up:Connect(function()   verticalDir =  0 end)

--// INPUT BOXES
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
close.MouseButton1Click:Connect(function()
	stopFly()
	-- reset everything on close
	brightEnabled = false darkEnabled = false speedEnabled = false
	applyLighting()
	applySpeed()
	gui:Destroy()
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
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)
