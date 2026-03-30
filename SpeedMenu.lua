--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

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

--// SAFE GUI (รองรับทุกแมพ)
local gui = Instance.new("ScreenGui")
gui.Name = "Light_UI"
gui.ResetOnSpawn = false

pcall(function()
	gui.Parent = player:WaitForChild("PlayerGui")
end)

if not gui.Parent then
	gui.Parent = game:GetService("CoreGui")
end

--// UI
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

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-30)
scroll.Position = UDim2.new(0,5,0,28)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

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

	local box = Instance.new("TextBox", f)
	box.Size = UDim2.new(1,0,0,23)
	box.Position = UDim2.new(0,0,0,25)
	box.PlaceholderText = placeholder

	return btn, box
end

-- UI CREATE
local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")
local darkBtn, darkBox = createBlock("Dark OFF","Dark")
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")
local flyBtn, flyBox = createBlock("Fly OFF","Fly Speed")

local resetBtn = Instance.new("TextButton", scroll)
resetBtn.Size = UDim2.new(1,-5,0,25)
resetBtn.Text = "RESET"

--// SAFE CHAR
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil end
	return char, hum, hrp
end

--// LIGHT
local function applyLighting()
	if brightEnabled then
		Lighting.Brightness = brightnessValue
	elseif darkEnabled then
		Lighting.Brightness = darkValue
	else
		for k,v in pairs(default) do
			Lighting[k] = v
		end
	end
end

--// SPEED
local function applySpeed()
	local char, hum = getChar()
	if not hum then return end
	hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed
end

--// FLY (กัน crash)
local flyConn
local bv, bg

local function startFly()
	local char, hum, hrp = getChar()
	if not hrp then return end

	hum.PlatformStand = true

	bv = Instance.new("BodyVelocity", hrp)
	bv.MaxForce = Vector3.new(1e5,1e5,1e5)

	bg = Instance.new("BodyGyro", hrp)
	bg.MaxTorque = Vector3.new(1e5,1e5,1e5)

	flyConn = RunService.RenderStepped:Connect(function()
		if not hrp or not hrp.Parent then return end

		local cam = workspace.CurrentCamera
		local dir = Vector3.zero

		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end

		if dir.Magnitude > 0 then
			bv.Velocity = dir.Unit * flySpeed
		else
			bv.Velocity = Vector3.zero
		end

		bg.CFrame = cam.CFrame
	end)
end

local function stopFly()
	if flyConn then flyConn:Disconnect() end
	if bv then bv:Destroy() end
	if bg then bg:Destroy() end

	local char, hum = getChar()
	if hum then hum.PlatformStand = false end
end

--// BUTTONS
brightBtn.MouseButton1Click:Connect(function()
	brightEnabled = not brightEnabled
	darkEnabled = false
	applyLighting()
end)

darkBtn.MouseButton1Click:Connect(function()
	darkEnabled = not darkEnabled
	brightEnabled = false
	applyLighting()
end)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	applySpeed()
end)

flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	if flyEnabled then startFly() else stopFly() end
end)

-- INPUT BOX
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
	if n then speedValue = n applySpeed() end
end)

flyBox.FocusLost:Connect(function()
	local n = tonumber(flyBox.Text)
	if n then flySpeed = n end
end)

-- RESET
resetBtn.MouseButton1Click:Connect(function()
	brightEnabled = false
	darkEnabled = false
	speedEnabled = false
	flyEnabled = false

	applyLighting()
	stopFly()
	applySpeed()
end)

-- CLOSE
close.MouseButton1Click:Connect(function()
	stopFly()
	gui:Destroy()
end)
