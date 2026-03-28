--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--// DEFAULT
local default = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient
}

local defaultWalkSpeed = 16

--// STATE
local brightEnabled = false
local darkEnabled = false
local fogEnabled = false
local speedEnabled = false

local brightnessValue = 5
local darkValue = 0
local fogValue = 100000
local speedValue = 50

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "Light_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 330)
frame.Position = UDim2.new(0.05, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-60,0,25)
title.Position = UDim2.new(0,5,0,0)
title.Text = "Light System"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

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
scroll.Size = UDim2.new(1,-10,1,-35)
scroll.Position = UDim2.new(0,5,0,30)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)
scroll.Active = true

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

--// BLOCK
local function createBlock(text, placeholder)
	local f = Instance.new("Frame", scroll)
	f.Size = UDim2.new(1,-5,0,55)
	f.BackgroundTransparency = 1

	local btn = Instance.new("TextButton", f)
	btn.Size = UDim2.new(1,0,0,25)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	btn.TextColor3 = Color3.new(1,1,1)

	local box = Instance.new("TextBox", f)
	box.Size = UDim2.new(1,0,0,25)
	box.Position = UDim2.new(0,0,0,28)
	box.PlaceholderText = placeholder
	box.BackgroundColor3 = Color3.fromRGB(50,50,50)
	box.TextColor3 = Color3.new(1,1,1)

	return btn, box
end

--// UI CREATE
local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")
local darkBtn, darkBox = createBlock("Dark OFF","Dark")
local fogBtn, fogBox = createBlock("Fog OFF","FogEnd")
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")

local resetBtn = Instance.new("TextButton", scroll)
resetBtn.Size = UDim2.new(1,-5,0,30)
resetBtn.Text = "RESET"
resetBtn.BackgroundColor3 = Color3.fromRGB(120,120,40)

--// DRAG FIX
local dragging, dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		dragInput = input
		scroll.ScrollingEnabled = false
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input == dragInput then
		dragging = false
		scroll.ScrollingEnabled = true
	end
end)

--// MINI / CLOSE
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local minimized = false
mini.MouseButton1Click:Connect(function()
	minimized = not minimized
	scroll.Visible = not minimized
	frame.Size = minimized and UDim2.new(0,200,0,30) or UDim2.new(0,200,0,330)
end)

--// APPLY LIGHT
local function applyLighting()
	Lighting.Brightness = default.Brightness
	Lighting.ClockTime = default.ClockTime
	Lighting.FogEnd = default.FogEnd
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
	end

	if fogEnabled then
		Lighting.FogEnd = fogValue
	end
end

--// SPEED
local function applySpeed()
	local char = Players.LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	defaultWalkSpeed = hum.WalkSpeed
	hum.WalkSpeed = speedValue
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

fogBtn.MouseButton1Click:Connect(function()
	fogEnabled = not fogEnabled
	fogBtn.Text = fogEnabled and "Fog ON" or "Fog OFF"
	applyLighting()
end)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	speedBtn.Text = speedEnabled and "Speed ON" or "Speed OFF"

	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			if speedEnabled then
				applySpeed()
			else
				hum.WalkSpeed = defaultWalkSpeed
			end
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

fogBox.FocusLost:Connect(function()
	local n = tonumber(fogBox.Text)
	if n then fogValue = n applyLighting() end
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
	if speedEnabled then
		local char = Players.LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = speedValue
			end
		end
	end
end)

--// RESET
resetBtn.MouseButton1Click:Connect(function()
	brightEnabled = false
	darkEnabled = false
	fogEnabled = false
	speedEnabled = false

	applyLighting()

	local char = Players.LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = defaultWalkSpeed
		end
	end

	brightBtn.Text = "FullBright OFF"
	darkBtn.Text = "Dark OFF"
	fogBtn.Text = "Fog OFF"
	speedBtn.Text = "Speed OFF"
end)

--// AUTO SCROLL
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)
