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

gui.Parent = success and playerGui or game.CoreGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 160, 0, 180)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,20)
title.Text = "Light System"
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 13

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,20,0,20)
close.Position = UDim2.new(1,-20,0,0)
close.Text = "X"
close.TextSize = 11
close.BackgroundColor3 = Color3.fromRGB(120,0,0)
close.TextColor3 = Color3.new(1,1,1)

local mini = Instance.new("TextButton", frame)
mini.Size = UDim2.new(0,20,0,20)
mini.Position = UDim2.new(1,-40,0,0)
mini.Text = "-"
mini.TextSize = 11
mini.BackgroundColor3 = Color3.fromRGB(60,60,60)
mini.TextColor3 = Color3.new(1,1,1)

--// SCROLL
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-6,1,-22)
scroll.Position = UDim2.new(0,3,0,22)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)
scroll.Active = true

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,4)

--// BLOCK
local function createBlock(text, placeholder)
	local f = Instance.new("Frame", scroll)
	f.Size = UDim2.new(1,-4,0,42)
	f.BackgroundTransparency = 1

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1,0,0,19)
	btn.Text = text
	btn.TextSize = 11
	btn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	btn.TextColor3 = Color3.new(1,1,1)

	local box = Instance.new("TextBox", f)
	box.Size = UDim2.new(1,0,0,19)
	box.Position = UDim2.new(0,0,0,21)
	box.PlaceholderText = placeholder
	box.TextSize = 11
	box.BackgroundColor3 = Color3.fromRGB(50,50,50)
	box.TextColor3 = Color3.new(1,1,1)

	return btn, box
end

--// UI CREATE
local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")
local darkBtn, darkBox = createBlock("Dark OFF","Dark")
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")
local flyBtn, flyBox = createBlock("Fly OFF","Fly Speed")

--// UP/DOWN
local udFrame = Instance.new("Frame", scroll)
udFrame.Size = UDim2.new(1,-4,0,20)
udFrame.BackgroundTransparency = 1

local upBtn = Instance.new("TextButton", udFrame)
upBtn.Size = UDim2.new(0.48,0,1,0)
upBtn.Text = "▲ Up"

local downBtn = Instance.new("TextButton", udFrame)
downBtn.Size = UDim2.new(0.48,0,1,0)
downBtn.Position = UDim2.new(0.52,0,0,0)
downBtn.Text = "▼ Down"

local resetBtn = Instance.new("TextButton", scroll)
resetBtn.Size = UDim2.new(1,-4,0,20)
resetBtn.Text = "RESET"

--// DRAG
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType.Name:find("Mouse") or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType.Name:find("Mouse") or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UIS.InputEnded:Connect(function() dragging = false end)

--// CLOSE
close.MouseButton1Click:Connect(function() gui:Destroy() end)

--// LIGHT
local function applyLighting()
	Lighting.Brightness = brightEnabled and brightnessValue or (darkEnabled and darkValue or default.Brightness)
end

--// SPEED
local function applySpeed()
	local char = Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = speedEnabled and speedValue or defaultWalkSpeed end
end

--// FLY FIXED
local function startFly()
	local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")

	hum.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity", hrp)
	bodyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6)

	bodyGyro = Instance.new("BodyGyro", hrp)
	bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)

	flyConnection = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local moveDir = hum.MoveDirection

		local dir = Vector3.zero

		if moveDir.Magnitude > 0 then
			local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
			local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
			dir = (look * moveDir.Z) + (right * moveDir.X)
		end

		local finalDir = dir + Vector3.new(0, verticalDir, 0)
		bodyVelocity.Velocity = finalDir.Magnitude > 0 and finalDir.Unit * flySpeed or Vector3.zero
		bodyGyro.CFrame = cam.CFrame
	end)
end

local function stopFly()
	if flyConnection then flyConnection:Disconnect() end
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

--// UP DOWN
upBtn.MouseButton1Down:Connect(function() verticalDir = 1 end)
upBtn.MouseButton1Up:Connect(function() verticalDir = 0 end)
downBtn.MouseButton1Down:Connect(function() verticalDir = -1 end)
downBtn.MouseButton1Up:Connect(function() verticalDir = 0 end)

--// BUTTONS
flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	if flyEnabled then startFly() else stopFly() end
end)

--// LOOP
RunService.RenderStepped:Connect(applySpeed)
