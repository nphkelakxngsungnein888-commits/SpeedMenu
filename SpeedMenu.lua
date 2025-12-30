--// Expert Fly Script (Mobile Supported)
--// LocalScript Only

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character, humanoid, root

local flying = false
local speed = 50
local gyro, velocity
local moveVector = Vector3.zero

--// Character Loader
local function loadChar()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")
end
loadChar()

player.CharacterAdded:Connect(function()
	flying = false
	task.wait(0.5)
	loadChar()
end)

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "FlyUI"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromScale(0.45, 0.3)
main.Position = UDim2.fromScale(0.275, 0.35)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.Active = true
main.Draggable = true
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.fromScale(1,0.25)
title.BackgroundTransparency = 1
title.Text = "✈️ FLY CONTROL"
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold

local toggle = Instance.new("TextButton", main)
toggle.Position = UDim2.fromScale(0.1,0.35)
toggle.Size = UDim2.fromScale(0.8,0.25)
toggle.Text = "FLY : OFF"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(200,50,50)
toggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggle)

local speedBox = Instance.new("TextBox", main)
speedBox.Position = UDim2.fromScale(0.25,0.68)
speedBox.Size = UDim2.fromScale(0.5,0.2)
speedBox.PlaceholderText = "Speed (Default 50)"
speedBox.Text = tostring(speed)
speedBox.TextScaled = true
speedBox.Font = Enum.Font.Gotham
speedBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
speedBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedBox)

--// Fly Logic
local function startFly()
	if flying then return end
	flying = true
	humanoid.PlatformStand = true

	gyro = Instance.new("BodyGyro", root)
	gyro.P = 9e4
	gyro.MaxTorque = Vector3.new(9e9,9e9,9e9)

	velocity = Instance.new("BodyVelocity", root)
	velocity.MaxForce = Vector3.new(9e9,9e9,9e9)
end

local function stopFly()
	flying = false
	humanoid.PlatformStand = false
	if gyro then gyro:Destroy() end
	if velocity then velocity:Destroy() end
end

toggle.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		toggle.Text = "FLY : OFF"
		toggle.BackgroundColor3 = Color3.fromRGB(200,50,50)
	else
		startFly()
		toggle.Text = "FLY : ON"
		toggle.BackgroundColor3 = Color3.fromRGB(50,200,50)
	end
end)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n then speed = math.clamp(n,10,300) end
	speedBox.Text = tostring(speed)
end)

--// Movement
RunService.RenderStepped:Connect(function()
	if not flying or not root then return end

	local cam = workspace.CurrentCamera
	gyro.CFrame = cam.CFrame

	moveVector = humanoid.MoveDirection * speed

	if UIS:IsKeyDown(Enum.KeyCode.Space) then
		moveVector += Vector3.new(0,speed,0)
	end
	if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		moveVector -= Vector3.new(0,speed,0)
	end

	velocity.Velocity = moveVector
end)

--// Hide / Show Button
local hide = Instance.new("TextButton", gui)
hide.Size = UDim2.fromScale(0.12,0.06)
hide.Position = UDim2.fromScale(0.02,0.45)
hide.Text = "UI"
hide.TextScaled = true
hide.Font = Enum.Font.GothamBold
hide.BackgroundColor3 = Color3.fromRGB(0,120,255)
hide.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", hide)

hide.MouseButton1Click:Connect(function()
	main.Visible = not main.Visible
end)
