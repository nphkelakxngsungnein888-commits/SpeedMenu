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

-- ================= STATE =================  
local lockEnabled = false  
local connection = nil  
local currentTarget = nil  
local targetMode = "Monster"  

local aimHeight = 0  
local scanEnabled = false  
local scanRange = 100  

local scanGui = nil  
local scanList = nil  
local lastScan = 0  
local SCAN_RATE = 0.5  

local CAMERA_OFFSET = Vector3.new(0,3,-8)  

-- ================= TARGET =================  

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
					if dist < shortest and dist <= scanRange then  
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
						if dist < shortest and dist <= scanRange then  
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

-- ================= LOCK =================  

local function startLock()  
	camera.CameraType = Enum.CameraType.Scriptable  

	connection = RunService.RenderStepped:Connect(function()  
		local char = getCharacter()  
		local root = char:FindFirstChild("HumanoidRootPart")  
		if not root then return end  

		if not currentTarget or not isAlive(currentTarget) then  
			currentTarget = getClosestTarget(root)  
		end  

		if not currentTarget then return end  

		local part = getTargetPart(currentTarget)  
		if not part then return end  

		local aimPos = part.Position + Vector3.new(0, aimHeight, 0)  

		root.CFrame = CFrame.new(root.Position, aimPos)  

		local camPos = root.Position + root.CFrame:VectorToWorldSpace(CAMERA_OFFSET)  
		camera.CFrame = CFrame.new(camPos, aimPos)  
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

-- ================= SCAN =================  

local function getTargetsInRange(root)  
	local list = {}  

	if targetMode == "Player" then  
		for _, plr in pairs(Players:GetPlayers()) do  
			if plr ~= player and plr.Character and isAlive(plr.Character) then  
				local part = getTargetPart(plr.Character)  
				if part then  
					local dist = (part.Position - root.Position).Magnitude  
					if dist <= scanRange then  
						table.insert(list, plr.Character)  
					end  
				end  
			end  
		end  
	else  
		for _, obj in pairs(workspace:GetDescendants()) do  
			if obj:IsA("Model") and isAlive(obj) then  
				if not Players:GetPlayerFromCharacter(obj) then  
					local part = getTargetPart(obj)  
					if part then  
						local dist = (part.Position - root.Position).Magnitude  
						if dist <= scanRange then  
							table.insert(list, obj)  
						end  
					end  
				end  
			end  
		end  
	end  

	return list  
end  

local function createScanUI()  
	if scanGui then scanGui:Destroy() end  

	scanGui = Instance.new("ScreenGui")  
	scanGui.Parent = player.PlayerGui  

	local frame = Instance.new("Frame")  
	frame.Size = UDim2.new(0,180,0,220)  
	frame.Position = UDim2.new(0.8,0,0.3,0)  
	frame.BackgroundColor3 = Color3.fromRGB(245,245,245)  
	frame.Parent = scanGui  
	Instance.new("UICorner", frame)  

	local scroll = Instance.new("ScrollingFrame")  
	scroll.Size = UDim2.new(1,0,1,0)  
	scroll.BackgroundTransparency = 1  
	scroll.Parent = frame  

	local layout = Instance.new("UIListLayout", scroll)  
	layout.Padding = UDim.new(0,4)  

	scanList = scroll  
end  

RunService.RenderStepped:Connect(function()  
	if not scanEnabled then return end  
	if tick() - lastScan < SCAN_RATE then return end  
	lastScan = tick()  

	local char = getCharacter()  
	local root = char:FindFirstChild("HumanoidRootPart")  
	if not root or not scanList then return end  

	scanList:ClearAllChildren()  

	local targets = getTargetsInRange(root)  

	for _, t in pairs(targets) do  
		local btn = Instance.new("TextButton")  
		btn.Size = UDim2.new(1,0,0,28)  
		btn.Text = t.Name  
		btn.Parent = scanList  

		btn.MouseButton1Click:Connect(function()  
			currentTarget = t  
			lockEnabled = true  
			startLock()  
		end)  
	end  

	scanList.CanvasSize = UDim2.new(0,0,0,#targets * 30)  
end)  

-- ================= UI =================  

local gui = Instance.new("ScreenGui")  
gui.Parent = player.PlayerGui  

local main = Instance.new("Frame")  
main.Size = UDim2.new(0, 220, 0, 340)  
main.Position = UDim2.new(0.5, -110, 0.5, -170)  
main.BackgroundColor3 = Color3.fromRGB(245,245,245)  
main.Parent = gui  
Instance.new("UICorner", main)  

local content = Instance.new("Frame")  
content.Size = UDim2.new(1,0,1,0)  
content.BackgroundTransparency = 1  
content.Parent = main  

local layout = Instance.new("UIListLayout", content)  
layout.Padding = UDim.new(0,6)  
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center  

local function btn(text)  
	local b = Instance.new("TextButton")  
	b.Size = UDim2.new(0.9,0,0,30)  
	b.Text = text  
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)  
	b.TextColor3 = Color3.new(1,1,1)  
	b.Parent = content  
	Instance.new("UICorner", b)  
	return b  
end  

local function box(placeholder, default, callback)
	local t = Instance.new("TextBox")
	t.Size = UDim2.new(0.9,0,0,30)
	t.PlaceholderText = placeholder
	t.Text = tostring(default)
	t.Parent = content
	Instance.new("UICorner", t)

	t.FocusLost:Connect(function()
		local num = tonumber(t.Text)
		if num then callback(num) end
	end)
end

local lockBtn = btn("Lock: OFF")  
local modeBtn = btn("Mode: Monster")  
local scanBtn = btn("Scan: OFF")  

-- 🔥 เพิ่มช่องปรับ
box("Aim Height (-1 / 0 / 1)", 0, function(v)
	aimHeight = v
end)

box("Range (e.g. 100)", 100, function(v)
	scanRange = v
end)

lockBtn.MouseButton1Click:Connect(function()  
	lockEnabled = not lockEnabled  
	lockBtn.Text = "Lock: "..(lockEnabled and "ON" or "OFF")  
	if lockEnabled then startLock() else stopLock() end  
end)  

modeBtn.MouseButton1Click:Connect(function()  
	targetMode = (targetMode=="Monster") and "Player" or "Monster"  
	modeBtn.Text = "Mode: "..targetMode  
	currentTarget = nil  
end)  

scanBtn.MouseButton1Click:Connect(function()  
	scanEnabled = not scanEnabled  
	scanBtn.Text = "Scan: "..(scanEnabled and "ON" or "OFF")  
	if scanEnabled then createScanUI()  
	elseif scanGui then scanGui:Destroy() end  
end)
