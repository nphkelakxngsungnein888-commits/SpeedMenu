-- Services  
local Players = game:GetService("Players")  
local RunService = game:GetService("RunService")  
local UserInputService = game:GetService("UserInputService")  

-- Player  
local player = Players.LocalPlayer  
local camera = workspace.CurrentCamera  

local function getCharacter()  
	return player.Character or player.CharacterAdded:Wait()  
end  

-- State  
local lockEnabled = false  
local connection = nil  
local isLarge = true  
local currentTarget = nil  

-- MODE
local targetMode = "Monster"

-- 🔧 SETTINGS
local aimHeight = 1.5 -- 🔥 ปรับได้ (0=ตัว / 1.5=อก / 2.5=หัว)

-- ================= AIMBOT =================  

local function isAlive(model)
	local hum = model and model:FindFirstChild("Humanoid")
	return hum and hum.Health > 0
end

local function getTargetPart(model)
	return model:FindFirstChild("HumanoidRootPart")
end

local function getClosestTarget(root)
	local closest = nil
	local shortest = math.huge

	if targetMode == "Player" then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and isAlive(plr.Character) then
				local part = getTargetPart(plr.Character)
				if part then
					local dist = (part.Position - root.Position).Magnitude
					if dist < shortest then
						shortest = dist
						closest = plr.Character
					end
				end
			end
		end
	else
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj ~= root.Parent and isAlive(obj) then
				if not Players:GetPlayerFromCharacter(obj) then
					local part = getTargetPart(obj)
					if part then
						local dist = (part.Position - root.Position).Magnitude
						if dist < shortest then
							shortest = dist
							closest = obj
						end
					end
				end
			end
		end
	end

	return closest
end

local function startLock()
	camera.CameraType = Enum.CameraType.Scriptable

	connection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		local root = character:FindFirstChild("HumanoidRootPart")
		local head = character:FindFirstChild("Head")
		if not root or not head then return end

		-- 🔥 ล็อคตัวเดิมจนตาย
		if not currentTarget or not isAlive(currentTarget) then
			currentTarget = getClosestTarget(root)
		end

		if not currentTarget then return end

		local part = getTargetPart(currentTarget)
		if not part then return end

		-- 🎯 จุดเล็ง
		local targetPos = part.Position + Vector3.new(0, aimHeight, 0)

		-- 🔄 หมุนตัวละคร
		root.CFrame = CFrame.new(root.Position, targetPos)

		-- 🎥 FIRST PERSON (ติดหัว)
		camera.CFrame = CFrame.new(head.Position, targetPos)
	end)
end

local function stopLock()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	camera.CameraType = Enum.CameraType.Custom
	currentTarget = nil
end

-- ================= MENU =================  

local gui = Instance.new("ScreenGui")  
gui.Parent = player:WaitForChild("PlayerGui")  

local frame = Instance.new("Frame")  
frame.Size = UDim2.new(0, 300, 0, 280)  
frame.Position = UDim2.new(0.5, -150, 0.5, -140)  
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)  
frame.Parent = gui  
Instance.new("UICorner", frame)  

local title = Instance.new("TextLabel")  
title.Size = UDim2.new(1,0,0,40)  
title.Text = "⚡ PRO LOCK MENU"  
title.BackgroundTransparency = 1  
title.TextColor3 = Color3.new(1,1,1)  
title.Parent = frame  
title.Active = true  

-- Lock
local toggleBtn = Instance.new("TextButton")  
toggleBtn.Size = UDim2.new(0.8,0,0,40)  
toggleBtn.Position = UDim2.new(0.1,0,0.2,0)  
toggleBtn.Text = "Lock: OFF"  
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)  
toggleBtn.Parent = frame  

-- Mode
local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0.8,0,0,40)
modeBtn.Position = UDim2.new(0.1,0,0.4,0)
modeBtn.Text = "Mode: Monster"
modeBtn.Parent = frame

-- Resize
local resizeBtn = Instance.new("TextButton")  
resizeBtn.Size = UDim2.new(0.8,0,0,40)  
resizeBtn.Position = UDim2.new(0.1,0,0.6,0)  
resizeBtn.Text = "Resize"  
resizeBtn.Parent = frame  

-- Close
local closeBtn = Instance.new("TextButton")  
closeBtn.Size = UDim2.new(0,30,0,30)  
closeBtn.Position = UDim2.new(1,-35,0,5)  
closeBtn.Text = "X"  
closeBtn.Parent = frame  

-- Toggle Lock  
toggleBtn.MouseButton1Click:Connect(function()  
	lockEnabled = not lockEnabled  
	if lockEnabled then  
		currentTarget = nil
		toggleBtn.Text = "Lock: ON"  
		startLock()  
	else  
		toggleBtn.Text = "Lock: OFF"  
		stopLock()  
	end  
end)  

-- Toggle Mode
modeBtn.MouseButton1Click:Connect(function()
	targetMode = (targetMode == "Monster") and "Player" or "Monster"
	modeBtn.Text = "Mode: " .. targetMode
	currentTarget = nil
end)

-- Resize  
resizeBtn.MouseButton1Click:Connect(function()  
	isLarge = not isLarge  
	frame.Size = isLarge and UDim2.new(0,300,0,280) or UDim2.new(0,200,0,180)  
end)  

-- Close  
closeBtn.MouseButton1Click:Connect(function()  
	stopLock()  
	gui:Destroy()  
end)  

-- DRAG  
local dragging = false  
local dragInput  
local dragStart  
local startPos  

title.InputBegan:Connect(function(input)  
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then  
		dragging = true  
		dragStart = input.Position  
		startPos = frame.Position  
		dragInput = input  
	end  
end)  

UserInputService.InputChanged:Connect(function(input)  
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

UserInputService.InputEnded:Connect(function(input)  
	if input == dragInput then  
		dragging = false  
	end  
end)
