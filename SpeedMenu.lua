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

local function getTeamColor(model)
	local plr = Players:GetPlayerFromCharacter(model)
	if plr and plr.Team then
		return plr.TeamColor.Color
	end
	return Color3.fromRGB(255,255,255)
end

local function createScanUI()
	if scanGui then scanGui:Destroy() end

	scanGui = Instance.new("ScreenGui")
	scanGui.Parent = player.PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0,180,0,220)
	frame.Position = UDim2.new(0.8,0,0.3,0)
	frame.BackgroundColor3 = Color3.fromRGB(240,240,240)
	frame.Parent = scanGui
	Instance.new("UICorner", frame)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1,0,1,0)
	scroll.BackgroundTransparency = 1
	scroll.Parent = frame

	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0,4)

	scanList = scroll

	-- drag
	local dragging, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function()
		dragging = false
	end)
end

RunService.RenderStepped:Connect(function()
	if not scanEnabled then return end
	if tick() - lastScan < SCAN_RATE then return end
	lastScan = tick()

	local char = getCharacter()
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root or not scanList then return end

	scanList:ClearAllChildren()
	local layout = Instance.new("UIListLayout", scanList)
	layout.Padding = UDim.new(0,4)

	local targets = getTargetsInRange(root)

	for _, t in pairs(targets) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,0,0,30)
		btn.Text = t.Name
		btn.BackgroundColor3 = getTeamColor(t)
		btn.TextColor3 = Color3.new(0,0,0)
		btn.Parent = scanList

		btn.MouseButton1Click:Connect(function()
			currentTarget = t
			if not lockEnabled then
				lockEnabled = true
				startLock()
			end
		end)
	end

	scanList.CanvasSize = UDim2.new(0,0,0,#targets * 34)
end)

-- ================= UI =================

local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,200,0,260)
frame.Position = UDim2.new(0.5,-100,0.5,-130)
frame.BackgroundColor3 = Color3.fromRGB(240,240,240)
frame.Parent = gui
Instance.new("UICorner", frame)

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0,5)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function btn(text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.9,0,0,30)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(30,30,30)
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = frame
	Instance.new("UICorner", b)
	return b
end

local lockBtn = btn("Lock: OFF")
lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	lockBtn.Text = "Lock: " .. (lockEnabled and "ON" or "OFF")
	if lockEnabled then startLock() else stopLock() end
end)

local modeBtn = btn("Mode: Monster")
modeBtn.MouseButton1Click:Connect(function()
	targetMode = (targetMode=="Monster") and "Player" or "Monster"
	modeBtn.Text = "Mode: "..targetMode
	currentTarget = nil
end)

local scanBtn = btn("Scan: OFF")
scanBtn.MouseButton1Click:Connect(function()
	scanEnabled = not scanEnabled
	scanBtn.Text = "Scan: "..(scanEnabled and "ON" or "OFF")
	if scanEnabled then createScanUI()
	elseif scanGui then scanGui:Destroy() end
end)

local rangeBox = Instance.new("TextBox")
rangeBox.Size = UDim2.new(0.9,0,0,30)
rangeBox.PlaceholderText = "Range"
rangeBox.Parent = frame
Instance.new("UICorner", rangeBox)

rangeBox.FocusLost:Connect(function()
	local n = tonumber(rangeBox.Text)
	if n then scanRange = n end
end)

local aimBox = Instance.new("TextBox")
aimBox.Size = UDim2.new(0.9,0,0,30)
aimBox.PlaceholderText = "Aim Height"
aimBox.Parent = frame
Instance.new("UICorner", aimBox)

aimBox.FocusLost:Connect(function()
	local n = tonumber(aimBox.Text)
	if n then aimHeight = n end
end)

local closeBtn = btn("Close")
closeBtn.MouseButton1Click:Connect(function()
	stopLock()
	if scanGui then scanGui:Destroy() end
	gui:Destroy()
end)

-- drag main
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function()
	dragging = false
end)
