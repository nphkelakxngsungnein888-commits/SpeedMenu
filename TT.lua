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
local isFirstLock = true  

-- ESP  
local espEnabled = false  
local espObjects = {}  

-- ESP SETTINGS  
local ESP_UPDATE_RATE = 0.2  
local MAX_ESP = 20  
local MAX_DISTANCE = 200  
local lastUpdate = 0  

-- ================= AIMBOT =================  

local function isEnemy(model)  
	if not model:FindFirstChild("Humanoid") then return false end  
	if Players:GetPlayerFromCharacter(model) then return false end  
	return true  
end  

local function getTargetPart(model)  
	return model:FindFirstChild("HumanoidRootPart")  
end  

local function isAlive(model)  
	local hum = model and model:FindFirstChild("Humanoid")  
	return hum and hum.Health > 0  
end  

local function getFrontTarget(root)  
	local best = nil  
	local bestDot = -1  

	for _, obj in pairs(workspace:GetDescendants()) do  
		if obj:IsA("Model") and obj ~= root.Parent and isEnemy(obj) and isAlive(obj) then  
			local part = getTargetPart(obj)  
			if part then  
				local direction = (part.Position - camera.CFrame.Position).Unit  
				local dot = camera.CFrame.LookVector:Dot(direction)  
				if dot > bestDot then  
					bestDot = dot  
					best = obj  
				end  
			end  
		end  
	end  
	return best  
end  

local function getBestTarget(root)  
	local closest = nil  
	local shortest = math.huge  

	for _, obj in pairs(workspace:GetDescendants()) do  
		if obj:IsA("Model") and obj ~= root.Parent and isEnemy(obj) and isAlive(obj) then  
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
	return closest  
end  

local function startLock()  
	connection = RunService.RenderStepped:Connect(function()  
		local character = getCharacter()  
		local root = character:FindFirstChild("HumanoidRootPart")  
		if not root then return end  

		if isFirstLock then  
			currentTarget = getFrontTarget(root)  
			isFirstLock = false  
		end  

		if not currentTarget or not isAlive(currentTarget) then  
			currentTarget = getBestTarget(root)  
		end  

		if not currentTarget then return end  

		local part = getTargetPart(currentTarget)  
		if not part then return end  

		local aimPos = part.Position  

		root.CFrame = CFrame.new(root.Position, aimPos)  
		camera.CFrame = CFrame.new(camera.CFrame.Position, aimPos)  
	end)  
end  

local function stopLock()  
	if connection then  
		connection:Disconnect()  
		connection = nil  
	end  
	currentTarget = nil  
end  

-- ================= ESP (OPTIMIZED) =================  

local function createESP(part)  
	if espObjects[part] then return end  

	local billboard = Instance.new("BillboardGui")  
	billboard.Size = UDim2.new(0, 8, 0, 8)  
	billboard.AlwaysOnTop = true  
	billboard.Adornee = part  
	billboard.Parent = part  

	local dot = Instance.new("Frame")  
	dot.Size = UDim2.new(1,0,1,0)  
	dot.BackgroundColor3 = Color3.fromRGB(255,0,0)  
	dot.BorderSizePixel = 0  
	dot.Parent = billboard  

	Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)  

	espObjects[part] = billboard  
end  

local function clearFarESP(root)  
	for part, gui in pairs(espObjects) do  
		if not part or not part.Parent then  
			gui:Destroy()  
			espObjects[part] = nil  
		else  
			local dist = (part.Position - root.Position).Magnitude  
			if dist > MAX_DISTANCE then  
				gui:Destroy()  
				espObjects[part] = nil  
			end  
		end  
	end  
end  

RunService.RenderStepped:Connect(function()  
	if not espEnabled then return end  

	if tick() - lastUpdate < ESP_UPDATE_RATE then return end  
	lastUpdate = tick()  

	local character = getCharacter()  
	local root = character:FindFirstChild("HumanoidRootPart")  
	if not root then return end  

	clearFarESP(root)  

	local count = 0  

	for _, obj in pairs(workspace:GetDescendants()) do  
		if count >= MAX_ESP then break end  

		if obj:IsA("Model") and isEnemy(obj) and isAlive(obj) then  
			local part = getTargetPart(obj)  
			if part then  
				local dist = (part.Position - root.Position).Magnitude  
				if dist <= MAX_DISTANCE then  
					createESP(part)  
					count += 1  
				end  
			end  
		end  
	end  
end)  

-- ================= MENU =================  

local gui = Instance.new("ScreenGui")  
gui.Parent = player:WaitForChild("PlayerGui")  

local frame = Instance.new("Frame")  
frame.Size = UDim2.new(0, 300, 0, 240)  
frame.Position = UDim2.new(0.5, -150, 0.5, -120)  
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

local toggleBtn = Instance.new("TextButton")  
toggleBtn.Size = UDim2.new(0.8,0,0,40)  
toggleBtn.Position = UDim2.new(0.1,0,0.25,0)  
toggleBtn.Text = "Lock: OFF"  
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)  
toggleBtn.Parent = frame  

local espBtn = Instance.new("TextButton")  
espBtn.Size = UDim2.new(0.8,0,0,40)  
espBtn.Position = UDim2.new(0.1,0,0.45,0)  
espBtn.Text = "ESP: OFF"  
espBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)  
espBtn.Parent = frame  

local resizeBtn = Instance.new("TextButton")  
resizeBtn.Size = UDim2.new(0.8,0,0,40)  
resizeBtn.Position = UDim2.new(0.1,0,0.65,0)  
resizeBtn.Text = "Resize"  
resizeBtn.Parent = frame  

local closeBtn = Instance.new("TextButton")  
closeBtn.Size = UDim2.new(0,30,0,30)  
closeBtn.Position = UDim2.new(1,-35,0,5)  
closeBtn.Text = "X"  
closeBtn.Parent = frame  

toggleBtn.MouseButton1Click:Connect(function()  
	lockEnabled = not lockEnabled  
	if lockEnabled then  
		currentTarget = nil  
		isFirstLock = true  
		toggleBtn.Text = "Lock: ON"  
		startLock()  
	else  
		toggleBtn.Text = "Lock: OFF"  
		stopLock()  
	end  
end)  

espBtn.MouseButton1Click:Connect(function()  
	espEnabled = not espEnabled  
	if espEnabled then  
		espBtn.Text = "ESP: ON"  
		espBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)  
	else  
		espBtn.Text = "ESP: OFF"  
		espBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)  
		for _, v in pairs(espObjects) do v:Destroy() end  
		espObjects = {}  
	end  
end)  

resizeBtn.MouseButton1Click:Connect(function()  
	isLarge = not isLarge  
	frame.Size = isLarge and UDim2.new(0,300,0,240) or UDim2.new(0,200,0,160)  
end)  

closeBtn.MouseButton1Click:Connect(function()  
	stopLock()  
	for _, v in pairs(espObjects) do v:Destroy() end  
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
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)  
	end  
end)  

UserInputService.InputEnded:Connect(function(input)  
	if input == dragInput then  
		dragging = false  
	end  
end)
