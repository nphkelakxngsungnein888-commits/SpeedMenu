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

-- CONFIG
local RAY_DISTANCE = 2000 -- 🔥 เพิ่มระยะคลิกไกล

-- State  
local lockEnabled = false  
local connection = nil  
local currentTarget = nil  

-- MODE  
local targetMode = "Monster"  

-- ================= AIMBOT LOGIC =================  

local function isAlive(model)  
	local hum = model and model:FindFirstChild("Humanoid")  
	return hum and hum.Health > 0  
end  

local function getTargetPart(model)  
	return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")  
end  

-- หา Monster ใกล้สุด  
local function getClosestMonster(root)  
	local closest = nil  
	local shortest = math.huge  

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
	return closest  
end  

-- 🔥 fallback หา player ใกล้ cursor
local function getClosestPlayerToScreen(screenPos)
	local closest = nil
	local shortest = math.huge

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and isAlive(plr.Character) then
			local part = getTargetPart(plr.Character)
			if part then
				local screenPoint, visible = camera:WorldToViewportPoint(part.Position)
				if visible then
					local dist = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
					if dist < shortest then
						shortest = dist
						closest = plr.Character
					end
				end
			end
		end
	end

	return closest
end

-- 🔥 MOBILE + PC TAP / CLICK SYSTEM (อัปเกรด)
local function getTappedTarget(screenPos)  
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)  

	local raycastParams = RaycastParams.new()  
	raycastParams.FilterDescendantsInstances = {player.Character}  
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist  

	local result = workspace:Raycast(ray.Origin, ray.Direction.Unit * RAY_DISTANCE, raycastParams)  

	-- 🎯 ถ้ายิงโดน
	if result and result.Instance then  
		local part = result.Instance  
		local model = part:FindFirstAncestorOfClass("Model")  
		if model and Players:GetPlayerFromCharacter(model) then  
			if isAlive(model) and model ~= player.Character then  
				return model  
			end  
		end  
	end  

	-- 🔥 ถ้าไม่โดน → หาใกล้ cursor แทน
	return getClosestPlayerToScreen(screenPos)
end  

-- Touch  
UserInputService.TouchTap:Connect(function(touches)  
	if not lockEnabled or targetMode ~= "Player" then return end  
	local pos = touches[1]  
	local target = getTappedTarget(pos)  
	if target then  
		currentTarget = target  
	end  
end)  

-- Mouse  
UserInputService.InputBegan:Connect(function(input, gpe)  
	if gpe then return end  
	if not lockEnabled or targetMode ~= "Player" then return end  

	if input.UserInputType == Enum.UserInputType.MouseButton1 then  
		local target = getTappedTarget(input.Position)  
		if target then  
			currentTarget = target  
		end  
	end  
end)  

-- 🔥 LOCK SYSTEM  
local function startLock()  
	connection = RunService.RenderStepped:Connect(function()  
		local character = getCharacter()  
		local root = character:FindFirstChild("HumanoidRootPart")  
		if not root then return end  

		if targetMode == "Monster" then  
			if not currentTarget or not isAlive(currentTarget) then  
				currentTarget = getClosestMonster(root)  
			end  
		else  
			if currentTarget and not isAlive(currentTarget) then  
				currentTarget = nil  
			end  
		end  

		if not currentTarget then return end  

		local part = getTargetPart(currentTarget)  
		if not part then return end  

		local aimPos = part.Position  

		root.CFrame = CFrame.new(root.Position, Vector3.new(aimPos.X, root.Position.Y, aimPos.Z))  
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

-- ================= GUI =================  

local gui = Instance.new("ScreenGui")  
gui.Name = "ProMobileLock"  
gui.ResetOnSpawn = false  

local success, playerGui = pcall(function() return player:WaitForChild("PlayerGui") end)  
if success and playerGui then  
	gui.Parent = playerGui  
else  
	gui.Parent = game:GetService("CoreGui")  
end  

local frame = Instance.new("Frame")  
frame.Size = UDim2.new(0, 300, 0, 260)  
frame.Position = UDim2.new(0.5, -150, 0.5, -130)  
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)  
frame.Parent = gui  
Instance.new("UICorner", frame)  

local title = Instance.new("TextLabel")  
title.Size = UDim2.new(1,0,0,40)  
title.Text = "📱 MOBILE LOCK"  
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)  
title.TextColor3 = Color3.new(1,1,1)  
title.Parent = frame  

local toggleBtn = Instance.new("TextButton")  
toggleBtn.Size = UDim2.new(0.8,0,0,45)  
toggleBtn.Position = UDim2.new(0.1,0,0.3,0)  
toggleBtn.Text = "Lock: OFF"  
toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)  
toggleBtn.Parent = frame  

local modeBtn = Instance.new("TextButton")  
modeBtn.Size = UDim2.new(0.8,0,0,45)  
modeBtn.Position = UDim2.new(0.1,0,0.55,0)  
modeBtn.Text = "Mode: Monster"  
modeBtn.Parent = frame  

local closeBtn = Instance.new("TextButton")  
closeBtn.Size = UDim2.new(0,30,0,30)  
closeBtn.Position = UDim2.new(1,-35,0,5)  
closeBtn.Text = "X"  
closeBtn.Parent = frame  

toggleBtn.MouseButton1Click:Connect(function()  
	lockEnabled = not lockEnabled  
	if lockEnabled then  
		toggleBtn.Text = "Lock: ON"  
		startLock()  
	else  
		toggleBtn.Text = "Lock: OFF"  
		stopLock()  
	end  
end)  

modeBtn.MouseButton1Click:Connect(function()  
	targetMode = (targetMode == "Monster") and "Player" or "Monster"  
	currentTarget = nil  
	modeBtn.Text = "Mode: " .. targetMode  
end)  

closeBtn.MouseButton1Click:Connect(function()  
	stopLock()  
	gui:Destroy()  
end)
