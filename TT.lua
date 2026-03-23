-- Services
local Players = game:GetService("Players")

-- Player
local player = Players.LocalPlayer

-- State
local lockEnabled = false
local isLarge = true

-- UI Root
local gui = Instance.new("ScreenGui")
gui.Name = "ProMenu"
gui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

-- UI Corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "⚡ PRO LOCK MENU"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
toggleBtn.Text = "Lock: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.Parent = frame

Instance.new("UICorner", toggleBtn)

-- Resize Button
local resizeBtn = Instance.new("TextButton")
resizeBtn.Size = UDim2.new(0.8, 0, 0, 40)
resizeBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
resizeBtn.Text = "Resize Menu"
resizeBtn.BackgroundColor3 = Color3.fromRGB(50,150,250)
resizeBtn.TextColor3 = Color3.new(1,1,1)
resizeBtn.Font = Enum.Font.GothamBold
resizeBtn.TextSize = 16
resizeBtn.Parent = frame

Instance.new("UICorner", resizeBtn)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(255,60,60)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = frame

Instance.new("UICorner", closeBtn)

-- Toggle Logic
toggleBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	
	if lockEnabled then
		toggleBtn.Text = "Lock: ON"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
	else
		toggleBtn.Text = "Lock: OFF"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	end
end)

-- Resize Logic
resizeBtn.MouseButton1Click:Connect(function()
	isLarge = not isLarge
	
	if isLarge then
		frame.Size = UDim2.new(0, 300, 0, 200)
	else
		frame.Size = UDim2.new(0, 200, 0, 140)
	end
end)

-- Close Logic
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)
-- Drag System
local UserInputService = game:GetService("UserInputService")

local dragging = false
local dragInput
local dragStart
local startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)
