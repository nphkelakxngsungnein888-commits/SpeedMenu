--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--// DEFAULT
local default = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient
}

local defaultWalkSpeed = 16

--// STATE
local brightEnabled = false
local darkEnabled = false
local speedEnabled = false
local floatEnabled = false

local brightnessValue = 5
local darkValue = 0
local speedValue = 50

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "Light_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 260)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,25)
title.Text = "Light System"
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.TextColor3 = Color3.new(1,1,1)

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,25,0,25)
close.Position = UDim2.new(1,-25,0,0)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(120,0,0)

local mini = Instance.new("TextButton", frame)
mini.Size = UDim2.new(0,25,0,25)
mini.Position = UDim2.new(1,-50,0,0)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(60,60,60)

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-30)
scroll.Position = UDim2.new(0,5,0,28)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)
scroll.Active = true

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

--// BLOCK
local function createBlock(text, placeholder)
	local f = Instance.new("Frame", scroll)
	f.Size = UDim2.new(1,-5,0,50)
	f.BackgroundTransparency = 1

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1,0,0,23)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	btn.TextColor3 = Color3.new(1,1,1)

	local box = Instance.new("TextBox", f)
	box.Size = UDim2.new(1,0,0,23)
	box.Position = UDim2.new(0,0,0,25)
	box.PlaceholderText = placeholder
	box.BackgroundColor3 = Color3.fromRGB(50,50,50)
	box.TextColor3 = Color3.new(1,1,1)

	return btn, box
end

--// UI CREATE
local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")
local darkBtn, darkBox = createBlock("Dark OFF","Dark")
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")
local floatBtn, floatBox = createBlock("Float OFF","Float Speed")

local resetBtn = Instance.new("TextButton", scroll)
resetBtn.Size = UDim2.new(1,-5,0,25)
resetBtn.Text = "RESET"
resetBtn.BackgroundColor3 = Color3.fromRGB(120,120,40)
resetBtn.TextColor3 = Color3.new(1,1,1)

--// DRAG
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
	or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function()
	dragging = false
end)

--// CLOSE / MINI
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local minimized = false
mini.MouseButton1Click:Connect(function()
	minimized = not minimized
	scroll.Visible = not minimized
	frame.Size = minimized and UDim2.new(0,200,0,25) or UDim2.new(0,200,0,260)
end)

--// LIGHT
local function applyLighting()
	Lighting.Brightness = default.Brightness
	Lighting.ClockTime = default.ClockTime
	Lighting.GlobalShadows = default.GlobalShadows
	Lighting.Ambient = default.Ambient
	Lighting.OutdoorAmbient = default.OutdoorAmbient

	if brightEnabled then
		Lighting.Brightness = brightnessValue
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.new(1,1,1)
		Lighting.OutdoorAmbient = Color3.new(1,1,1)
	elseif darkEnabled then
		Lighting.Brightness = darkValue
		Lighting.ClockTime = 0
		Lighting.GlobalShadows = true
		Lighting.Ambient = Color3.new(0,0,0)
		Lighting.OutdoorAmbient = Color3.new(0,0,0)
	end
end

--// SPEED
local function applySpeed()
	local char = Players.LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.WalkSpeed = speedValue or defaultWalkSpeed
end

--// FLOAT UP/DOWN
local floatBP = nil
local floatSpeed = 1
local floatDirection = 0 -- 1=ขึ้น -1=ลง

-- ปุ่มขึ้นลง
local upBtn = Instance.new("TextButton", frame)
upBtn.Size = UDim2.new(0,25,0,25)
upBtn.Position = UDim2.new(1,-75,0,0)
upBtn.Text = "↑"
upBtn.BackgroundColor3 = Color3.fromRGB(50,50,200)
upBtn.Visible = false

local downBtn = Instance.new("TextButton", frame)
downBtn.Size = UDim2.new(0,25,0,25)
downBtn.Position = UDim2.new(1,-100,0,0)
downBtn.Text = "↓"
downBtn.BackgroundColor3 = Color3.fromRGB(50,50,200)
downBtn.Visible = false

-- ปรับความเร็ว float จาก box เดียว
floatBox.FocusLost:Connect(function()
	local n = tonumber(floatBox.Text)
	if n then
		floatSpeed = n
	end
end)

-- กดปุ่ม float
upBtn.MouseButton1Down:Connect(function()
	floatDirection = 1
end)
upBtn.MouseButton1Up:Connect(function()
	floatDirection = 0
end)

downBtn.MouseButton1Down:Connect(function()
	floatDirection = -1
end)
downBtn.MouseButton1Up:Connect(function()
	floatDirection = 0
end)

-- ฟังก์ชัน float
local function applyFloat()
	local char = Players.LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if floatEnabled then
		if not floatBP then
			floatBP = Instance.new("BodyPosition")
			floatBP.MaxForce = Vector3.new(0, math.huge, 0)
			floatBP.P = 1250
			floatBP.D = 25
			floatBP.Position = hrp.Position
			floatBP.Parent = hrp
		end
		floatBP.Position = floatBP.Position + Vector3.new(0, floatSpeed * floatDirection, 0)
	else
		if floatBP then
			floatBP:Destroy()
			floatBP = nil
		end
	end
end

--// BUTTONS
brightBtn.MouseButton1Click:Connect(function()
	brightEnabled = not brightEnabled
	darkEnabled = false
	brightBtn.Text = brightEnabled and "FullBright ON" or "FullBright OFF"
	brightBtn.BackgroundColor3 = brightEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
	darkBtn.Text = "Dark OFF"
	darkBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	applyLighting()
end)

darkBtn.MouseButton1Click:Connect(function()
	darkEnabled = not darkEnabled
	brightEnabled = false
	darkBtn.Text = darkEnabled and "Dark ON" or "Dark OFF"
	darkBtn.BackgroundColor3 = darkEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
	brightBtn.Text = "FullBright OFF"
	brightBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	applyLighting()
end)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	speedBtn.Text = speedEnabled and "Speed ON" or "Speed OFF"
	speedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
	applySpeed()
end)

floatBtn.MouseButton1Click:Connect(function()
	floatEnabled = not floatEnabled
	floatBtn.Text = floatEnabled and "Float ON" or "Float OFF"
	floatBtn.BackgroundColor3 = floatEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
	upBtn.Visible = floatEnabled
	downBtn.Visible = floatEnabled
	if not floatEnabled then
		floatDirection = 0
		if floatBP then
			floatBP:Destroy()
			floatBP = nil
		end
	end
end)

--// INPUT
brightBox.FocusLost:Connect(function()
	local n = tonumber(brightBox.Text)
	if n then brightnessValue = n applyLighting() end
end)

darkBox.FocusLost:Connect(function()
	local n = tonumber(darkBox.Text)
	if n then darkValue = n applyLighting() end
end)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n then
		speedValue = math.clamp(n,0,500)
		if speedEnabled then applySpeed() end
	end
end)

--// LOOP
RunService.RenderStepped:Connect(function()
	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = speedEnabled and (speedValue or defaultWalkSpeed) or defaultWalkSpeed
		end
		if floatEnabled then
			applyFloat()
		end
	end
end)

--// RESET
resetBtn.MouseButton1Click:Connect(function()
	brightEnabled = false
	darkEnabled = false
	speedEnabled = false
	floatEnabled = false

	applyLighting()

	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hum then hum.WalkSpeed = defaultWalkSpeed end
		if hrp then
			if floatBP then floatBP:Destroy() floatBP = nil end
			hrp.Position = Vector3.new(hrp.Position.X, math.floor(hrp.Position.Y), hrp.Position.Z)
		end
	end

	brightBtn.Text = "FullBright OFF"
	brightBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	darkBtn.Text = "Dark OFF"
	darkBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	speedBtn.Text = "Speed OFF"
	speedBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	floatBtn.Text = "Float OFF"
	floatBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	upBtn.Visible = false
	downBtn.Visible = false
end)

--// AUTO SCROLL
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)
