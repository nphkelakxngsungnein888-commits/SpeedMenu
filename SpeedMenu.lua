โค้ดพร้อมคัดลอกครับ:

```lua
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
local flyEnabled = false

local brightnessValue = 5
local darkValue = 0
local speedValue = 50
local flySpeed = 50
local verticalDir = 0
local thumbstickDir = Vector2.zero

--// FLY VARS
local flyConnection
local bodyVelocity
local bodyGyro

--// UI
local gui = Instance.new("ScreenGui")
gui.Name = "Light_UI"
gui.ResetOnSpawn = false

local success, playerGui = pcall(function()
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end)

if success and playerGui then
	gui.Parent = playerGui
else
	gui.Parent = game.CoreGui
end

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 220)
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
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(100,100,100)
scroll.ElasticBehavior = Enum.ElasticBehavior.Never

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

local function createUpDown()
	local f = Instance.new("Frame", scroll)
	f.Size = UDim2.new(1,-5,0,25)
	f.BackgroundTransparency = 1

	local upBtn = Instance.new("TextButton", f)
	upBtn.Size = UDim2.new(0.48,0,1,0)
	upBtn.Text = "▲ Up"
	upBtn.BackgroundColor3 = Color3.fromRGB(60,60,150)
	upBtn.TextColor3 = Color3.new(1,1,1)

	local downBtn = Instance.new("TextButton", f)
	downBtn.Size = UDim2.new(0.48,0,1,0)
	downBtn.Position = UDim2.new(0.52,0,0,0)
	downBtn.Text = "▼ Down"
	downBtn.BackgroundColor3 = Color3.fromRGB(60,60,150)
	downBtn.TextColor3 = Color3.new(1,1,1)

	return upBtn, downBtn
end

--// UI CREATE
local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")
local darkBtn, darkBox = createBlock("Dark OFF","Dark")
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")
local flyBtn, flyBox = createBlock("Fly OFF","Fly Speed")
local upBtn, downBtn = createUpDown()

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

UIS.InputEnded:Connect(function() dragging = false end)

--// CLOSE / MINI
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local minimized = false
mini.MouseButton1Click:Connect(function()
	minimized = not minimized
	scroll.Visible = not minimized
	frame.Size = minimized and UDim2.new(0,200,0,25) or UDim2.new(0,200,0,220)
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

--// FLY
local function startFly()
	local char = Players.LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	hum.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity", hrp)
	bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
	bodyVelocity.Velocity = Vector3.zero

	bodyGyro = Instance.new("BodyGyro", hrp)
	bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
	bodyGyro.P = 1e4

	flyConnection = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local moveDir = Vector3.zero
		local sX = thumbstickDir.X
		local sY = thumbstickDir.Y

		if math.abs(sX) > 0.1 or math.abs(sY) > 0.1 then
			local flat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
			if flat.Magnitude > 0 then flat = flat.Unit end
			local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
			if right.Magnitude > 0 then right = right.Unit end
			moveDir = flat * sY + right * sX
		end

		local dir = moveDir + Vector3.new(0, verticalDir, 0)

		if dir.Magnitude > 0 then
			bodyVelocity.Velocity = dir.Unit * flySpeed
		else
			bodyVelocity.Velocity = Vector3.zero
		end

		bodyGyro.CFrame = cam.CFrame
	end)
end

local function stopFly()
	local char = Players.LocalPlayer.Character
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
	end
	verticalDir = 0
end

--// THUMBSTICK
UIS.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		thumbstickDir = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

--// UP/DOWN
upBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		verticalDir = 1
	end
end)
upBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		verticalDir = 0
	end
end)

downBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		verticalDir = -1
	end
end)
downBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		verticalDir = 0
	end
end)

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
	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = speedEnabled and (speedValue or defaultWalkSpeed) or defaultWalkSpeed
		end
	end
end)

flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	flyBtn.Text = flyEnabled and "Fly ON" or "Fly OFF"
	flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
	if flyEnabled then startFly() else stopFly() end
end)

--// INPUT BOX
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

flyBox.FocusLost:Connect(function()
	local n = tonumber(flyBox.Text)
	if n then flySpeed = math.clamp(n,1,500) end
end)

--// LOOP
RunService.RenderStepped:Connect(function()
	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and not flyEnabled then
			hum.WalkSpeed = speedEnabled and (speedValue or defaultWalkSpeed) or defaultWalkSpeed
		end
	end
end)

--// RESET
resetBtn.MouseButton1Click:Connect(function()
	brightEnabled = false
	darkEnabled = false
	speedEnabled = false
	flyEnabled = false

	applyLighting()
	stopFly()

	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = defaultWalkSpeed end
	end

	brightBtn.Text = "FullBright OFF"
	brightBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	darkBtn.Text = "Dark OFF"
	darkBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	speedBtn.Text = "Speed OFF"
	speedBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	flyBtn.Text = "Fly OFF"
	flyBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
end)

--// AUTO SCROLL
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)
```
