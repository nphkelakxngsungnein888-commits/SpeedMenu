--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

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
local brightEnabled, darkEnabled, speedEnabled, flyEnabled = false,false,false,false
local brightnessValue, darkValue, speedValue, flySpeed = 5,0,50,50

--// FLY VARS
local flyConnection, bodyVelocity, bodyGyro
local thumbstickDir = Vector2.zero
local verticalDir = 0

--// GUI (FIX ALL MAP)
local gui = Instance.new("ScreenGui")
gui.Name = "Light_UI"
gui.ResetOnSpawn = false

local ok, pg = pcall(function()
	return player:WaitForChild("PlayerGui")
end)

gui.Parent = ok and pg or game:GetService("CoreGui")

--// UI
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 260)
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

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-30)
scroll.Position = UDim2.new(0,5,0,28)
scroll.CanvasSize = UDim2.new(0,0,0,400)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

--// CREATE BUTTON
local function createBtn(text)
	local btn = Instance.new("TextButton", scroll)
	btn.Size = UDim2.new(1,0,0,35)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	btn.TextColor3 = Color3.new(1,1,1)
	return btn
end

local brightBtn = createBtn("FullBright OFF")
local darkBtn = createBtn("Dark OFF")
local speedBtn = createBtn("Speed OFF")
local flyBtn = createBtn("Fly OFF")

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
	local hum = getChar():FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed
	end
end

--// SAFE UNIT
local function safeUnit(v)
	if v.Magnitude == 0 then return Vector3.zero end
	return v.Unit
end

--// FLY
local function startFly()
	local char = getChar()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	hum.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity", hrp)
	bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)

	bodyGyro = Instance.new("BodyGyro", hrp)
	bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)

	flyConnection = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera

		local look = Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
		local right = Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)

		local moveDir = (look * thumbstickDir.Y) + (right * thumbstickDir.X)
		local dir = moveDir + Vector3.new(0, verticalDir, 0)

		bodyVelocity.Velocity = safeUnit(dir) * flySpeed
		bodyGyro.CFrame = cam.CFrame
	end)
end

local function stopFly()
	if flyConnection then flyConnection:Disconnect() end
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end

	local hum = getChar():FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
	verticalDir = 0
end

--// BUTTONS
brightBtn.MouseButton1Click:Connect(function()
	brightEnabled = not brightEnabled
	darkEnabled = false
	brightBtn.Text = brightEnabled and "FullBright ON" or "FullBright OFF"
	darkBtn.Text = "Dark OFF"
	applyLighting()
end)

darkBtn.MouseButton1Click:Connect(function()
	darkEnabled = not darkEnabled
	brightEnabled = false
	darkBtn.Text = darkEnabled and "Dark ON" or "Dark OFF"
	brightBtn.Text = "FullBright OFF"
	applyLighting()
end)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	speedBtn.Text = speedEnabled and "Speed ON" or "Speed OFF"
	applySpeed()
end)

flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	flyBtn.Text = flyEnabled and "Fly ON" or "Fly OFF"
	if flyEnabled then startFly() else stopFly() end
end)

--// INPUT มือถือ
UIS.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		thumbstickDir = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

--// LOOP
RunService.RenderStepped:Connect(function()
	if not flyEnabled then
		applySpeed()
	end
end)

--// CLOSE
close.MouseButton1Click:Connect(function()
	stopFly()
	gui:Destroy()
end)
