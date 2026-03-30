--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--// PLAYER
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

--// SAFE GUI (แก้หลัก)
local gui = Instance.new("ScreenGui")
gui.Name = "Light_UI"
gui.ResetOnSpawn = false

local success, pg = pcall(function()
	return player:WaitForChild("PlayerGui")
end)

if success and pg then
	gui.Parent = pg
else
	gui.Parent = game:GetService("CoreGui")
end

--// UI
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

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-30)
scroll.Position = UDim2.new(0,5,0,28)
scroll.CanvasSize = UDim2.new(0,0,0,300)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

--// BLOCK
local function createBlock(text)
	local f = Instance.new("Frame", scroll)
	f.Size = UDim2.new(1,0,0,30)

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1,0,1,0)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(200,50,50)

	return btn
end

local speedBtn = createBlock("Speed OFF")
local flyBtn = createBlock("Fly OFF")

--// SPEED
speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	speedBtn.Text = speedEnabled and "Speed ON" or "Speed OFF"

	local char = getChar()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed
	end
end)

--// SAFE NORMALIZE (แก้ bug บินค้าง)
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

		local flatLook = Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
		local flatRight = Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)

		local moveDir = (flatLook * thumbstickDir.Y) + (flatRight * thumbstickDir.X)
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
end

--// BUTTON
flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	flyBtn.Text = flyEnabled and "Fly ON" or "Fly OFF"
	if flyEnabled then startFly() else stopFly() end
end)

--// INPUT มือถือ/จอย
UIS.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		thumbstickDir = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

--// LOOP
RunService.RenderStepped:Connect(function()
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and not flyEnabled then
			hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed
		end
	end
end)

--// CLOSE
close.MouseButton1Click:Connect(function()
	stopFly()
	gui:Destroy()
end)
