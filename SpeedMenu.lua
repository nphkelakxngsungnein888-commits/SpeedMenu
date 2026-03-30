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
local state = {
	bright = false,
	dark = false,
	speed = false,
	fly = false
}

local values = {
	brightness = 5,
	dark = 0,
	speed = 50,
	flySpeed = 50
}

local inputState = {
	forward = 0,
	right = 0,
	up = 0
}

--// CHARACTER
local humanoid, root

local function loadChar()
	local char = player.Character or player.CharacterAdded:Wait()
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end

loadChar()
player.CharacterAdded:Connect(loadChar)

--// UI
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,160,0,180)
frame.Position = UDim2.new(0.05,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local function createBlock(text, placeholder)
	local f = Instance.new("Frame", frame)
	f.Size = UDim2.new(1,0,0,42)

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1,0,0,19)
	btn.Text = text

	local box = Instance.new("TextBox", f)
	box.Size = UDim2.new(1,0,0,19)
	box.Position = UDim2.new(0,0,0,21)
	box.PlaceholderText = placeholder

	return btn, box
end

local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")
local darkBtn, darkBox = createBlock("Dark OFF","Dark")
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")
local flyBtn, flyBox = createBlock("Fly OFF","Fly Speed")

--// LIGHT
local function applyLighting()
	if state.bright then
		Lighting.Brightness = values.brightness
	elseif state.dark then
		Lighting.Brightness = values.dark
	else
		for k,v in pairs(default) do
			Lighting[k] = v
		end
	end
end

--// SPEED
local function applySpeed()
	if humanoid then
		humanoid.WalkSpeed = state.speed and values.speed or defaultWalkSpeed
	end
end

--// FLY
local flyConn
local bv, bg

local function startFly()
	if not root or not humanoid then return end

	humanoid.PlatformStand = true

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e5,1e5,1e5)
	bv.Parent = root

	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
	bg.Parent = root

	flyConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera

		local move =
			cam.CFrame.LookVector * inputState.forward +
			cam.CFrame.RightVector * inputState.right +
			Vector3.new(0, inputState.up, 0)

		if move.Magnitude > 0 then
			bv.Velocity = move.Unit * values.flySpeed
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

	if humanoid then
		humanoid.PlatformStand = false
	end
end

--// INPUT
UIS.InputBegan:Connect(function(i,g)
	if g then return end

	if i.KeyCode == Enum.KeyCode.W then inputState.forward = 1 end
	if i.KeyCode == Enum.KeyCode.S then inputState.forward = -1 end
	if i.KeyCode == Enum.KeyCode.A then inputState.right = -1 end
	if i.KeyCode == Enum.KeyCode.D then inputState.right = 1 end
	if i.KeyCode == Enum.KeyCode.Space then inputState.up = 1 end
	if i.KeyCode == Enum.KeyCode.LeftControl then inputState.up = -1 end
end)

UIS.InputEnded:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.W or i.KeyCode == Enum.KeyCode.S then inputState.forward = 0 end
	if i.KeyCode == Enum.KeyCode.A or i.KeyCode == Enum.KeyCode.D then inputState.right = 0 end
	if i.KeyCode == Enum.KeyCode.Space or i.KeyCode == Enum.KeyCode.LeftControl then inputState.up = 0 end
end)

--// BUTTONS
local function toggle(btn, key, label)
	state[key] = not state[key]
	btn.Text = label .. (state[key] and " ON" or " OFF")
end

brightBtn.MouseButton1Click:Connect(function()
	state.dark = false
	toggle(brightBtn, "bright", "FullBright")
	darkBtn.Text = "Dark OFF"
	applyLighting()
end)

darkBtn.MouseButton1Click:Connect(function()
	state.bright = false
	toggle(darkBtn, "dark", "Dark")
	brightBtn.Text = "FullBright OFF"
	applyLighting()
end)

speedBtn.MouseButton1Click:Connect(function()
	toggle(speedBtn, "speed", "Speed")
	applySpeed()
end)

flyBtn.MouseButton1Click:Connect(function()
	toggle(flyBtn, "fly", "Fly")
	if state.fly then startFly() else stopFly() end
end)

--// INPUT BOX
brightBox.FocusLost:Connect(function()
	local n = tonumber(brightBox.Text)
	if n then values.brightness = n applyLighting() end
end)

darkBox.FocusLost:Connect(function()
	local n = tonumber(darkBox.Text)
	if n then values.dark = n applyLighting() end
end)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n then values.speed = n applySpeed() end
end)

flyBox.FocusLost:Connect(function()
	local n = tonumber(flyBox.Text)
	if n then values.flySpeed = n end
end)

--// CLEANUP
gui.Destroying:Connect(stopFly)
