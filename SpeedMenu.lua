--// SERVICES  
local Players = game:GetService("Players")  
local UIS = game:GetService("UserInputService")  
local Lighting = game:GetService("Lighting")  
local RunService = game:GetService("RunService")  
  
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()  
  
--// GUI FIX  
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
  
--// COLORS (BLACK THEME)
local BLACK = Color3.fromRGB(10,10,10)
local DARK = Color3.fromRGB(20,20,20)
local MID = Color3.fromRGB(35,35,35)
local WHITE = Color3.fromRGB(255,255,255)

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
  
--// SAFE CHAR  
local function getChar()  
	local char = player.Character or player.CharacterAdded:Wait()  
	local hum = char:FindFirstChildOfClass("Humanoid")  
	local hrp = char:FindFirstChild("HumanoidRootPart")  
	if not hum or not hrp then return nil end  
	return char, hum, hrp  
end  
  
--// UI  
local frame = Instance.new("Frame", gui)  
frame.Size = UDim2.new(0,160,0,180)  
frame.Position = UDim2.new(0.05,0,0.3,0)  
frame.BackgroundColor3 = BLACK  
frame.BorderSizePixel = 0  
  
local title = Instance.new("TextLabel", frame)  
title.Size = UDim2.new(1,0,0,20)  
title.Text = "Light System"  
title.BackgroundColor3 = DARK  
title.TextColor3 = WHITE  
title.TextSize = 13  
title.BorderSizePixel = 0  
  
local close = Instance.new("TextButton", frame)  
close.Size = UDim2.new(0,20,0,20)  
close.Position = UDim2.new(1,-20,0,0)  
close.Text = "X"  
close.BackgroundColor3 = MID  
close.TextColor3 = WHITE  
close.BorderSizePixel = 0  
  
--// SCROLL  
local scroll = Instance.new("ScrollingFrame", frame)  
scroll.Size = UDim2.new(1,-6,1,-22)  
scroll.Position = UDim2.new(0,3,0,22)  
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y  
scroll.BackgroundColor3 = BLACK  
scroll.BorderSizePixel = 0  
  
local layout = Instance.new("UIListLayout", scroll)  
  
--// BLOCK  
local function createBlock(text, placeholder)  
	local f = Instance.new("Frame", scroll)  
	f.Size = UDim2.new(1,0,0,42)  
	f.BackgroundColor3 = BLACK  
	f.BorderSizePixel = 0  
  
	local btn = Instance.new("TextButton", f)  
	btn.Size = UDim2.new(1,0,0,19)  
	btn.Text = text  
	btn.BackgroundColor3 = MID  
	btn.TextColor3 = WHITE  
	btn.BorderSizePixel = 0  
  
	local box = Instance.new("TextBox", f)  
	box.Size = UDim2.new(1,0,0,19)  
	box.Position = UDim2.new(0,0,0,21)  
	box.PlaceholderText = placeholder  
	box.BackgroundColor3 = DARK  
	box.TextColor3 = WHITE  
	box.BorderSizePixel = 0  
  
	return btn, box  
end  
  
local brightBtn, brightBox = createBlock("FullBright OFF","Brightness")  
local darkBtn, darkBox = createBlock("Dark OFF","Dark")  
local speedBtn, speedBox = createBlock("Speed OFF","WalkSpeed")  
local flyBtn, flyBox = createBlock("Fly OFF","Fly Speed")  
  
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
	bv.MaxForce = Vector3.new(1e5,1e5,1e5)  
  
	bg = Instance.new("BodyGyro", hrp)  
	bg.MaxTorque = Vector3.new(1e5,1e5,1e5)  
  
	flyConn = RunService.RenderStepped:Connect(function()  
		local cam = workspace.CurrentCamera  
		local moveDir = hum.MoveDirection  
		local dir = moveDir + Vector3.new(0,verticalDir,0)  
  
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
  
	local _, hum = getChar()  
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
	if n then speedValue = n applySpeed() end  
end)  
  
flyBox.FocusLost:Connect(function()  
	local n = tonumber(flyBox.Text)  
	if n then flySpeed = n end  
end)  
  
--// CLOSE  
close.MouseButton1Click:Connect(function()  
	stopFly()  
	gui:Destroy()  
end)
