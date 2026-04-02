--// ===== SETTINGS SAVE =====
_G.AIM_SETTINGS = _G.AIM_SETTINGS or {
	offset = {0,0,0,0,0,0},
	distance = 200,
	mode = "Monster"
}

--// ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

--// ===== STATE =====
local lockEnabled = false
local currentTarget = nil
local selectedTarget = nil

local targetMode = _G.AIM_SETTINGS.mode
local offsets = _G.AIM_SETTINGS.offset
local scanDistance = _G.AIM_SETTINGS.distance

--// ===== TARGET =====
local function isAlive(m)
	local h = m and m:FindFirstChild("Humanoid")
	return h and h.Health > 0
end

local function getRoot(m)
	return m:FindFirstChild("HumanoidRootPart")
end

local function isValid(m)
	local plr = Players:GetPlayerFromCharacter(m)
	if targetMode == "Player" then
		return plr and plr ~= player and isAlive(m)
	else
		return not plr and isAlive(m)
	end
end

local function getClosest(root)
	local best, dist = nil, math.huge

	if targetMode == "Player" then
		for _,plr in pairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and isAlive(plr.Character) then
				local part = getRoot(plr.Character)
				if part then
					local d = (part.Position-root.Position).Magnitude
					if d < dist then
						dist = d
						best = plr.Character
					end
				end
			end
		end
	else
		for _,m in pairs(workspace:GetDescendants()) do
			if m:IsA("Model") and isValid(m) then
				local part = getRoot(m)
				if part then
					local d = (part.Position-root.Position).Magnitude
					if d < dist then
						dist = d
						best = m
					end
				end
			end
		end
	end

	return best
end

--// ===== LOCK =====
RunService.RenderStepped:Connect(function()
	if not lockEnabled then return end

	local char = getChar()
	local root = getRoot(char)
	if not root then return end

	if selectedTarget and isAlive(selectedTarget) then
		currentTarget = selectedTarget
	else
		currentTarget = getClosest(root)
	end

	if not currentTarget then return end

	local part = getRoot(currentTarget)
	if not part then return end

	local aim = part.Position + Vector3.new(offsets[1], offsets[2], offsets[3])
	local camPos = root.Position + Vector3.new(offsets[4], offsets[5], offsets[6])

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(camPos, aim)
end)

--// ===== UI =====
local gui = Instance.new("ScreenGui", player.PlayerGui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,260)
frame.Position = UDim2.new(0.5,-110,0.5,-130)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
Instance.new("UICorner",frame)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,0,1,0)
scroll.CanvasSize = UDim2.new(0,0,0,600)
scroll.BackgroundTransparency = 1

local function btn(text,y)
	local b = Instance.new("TextButton", scroll)
	b.Size = UDim2.new(0.9,0,0,30)
	b.Position = UDim2.new(0.05,0,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(255,255,255)
	return b
end

-- Lock
local lockBtn = btn("LOCK OFF",10)
lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	lockBtn.Text = lockEnabled and "LOCK ON" or "LOCK OFF"
end)

-- Mode
local modeBtn = btn("Mode: "..targetMode,50)
modeBtn.MouseButton1Click:Connect(function()
	targetMode = targetMode=="Monster" and "Player" or "Monster"
	modeBtn.Text = "Mode: "..targetMode
	_G.AIM_SETTINGS.mode = targetMode
end)

-- Distance
local distBox = Instance.new("TextBox", scroll)
distBox.Size = UDim2.new(0.9,0,0,30)
distBox.Position = UDim2.new(0.05,0,0,90)
distBox.Text = "Distance: "..scanDistance

distBox.FocusLost:Connect(function()
	local v = tonumber(distBox.Text:match("%d+"))
	if v then
		scanDistance = v
		_G.AIM_SETTINGS.distance = v
	end
end)

-- Offsets 6 ช่อง
local names = {"Aim X","Aim Y","Aim Z","Cam X","Cam Y","Cam Z"}

for i=1,6 do
	local box = Instance.new("TextBox", scroll)
	box.Size = UDim2.new(0.9,0,0,30)
	box.Position = UDim2.new(0.05,0,0,120+(i*35))
	box.Text = names[i]..": "..offsets[i]

	box.FocusLost:Connect(function()
		local v = tonumber(box.Text:match("-?%d+"))
		if v then
			offsets[i] = v
			_G.AIM_SETTINGS.offset = offsets
		end
	end)
end

--// ===== SCAN MENU =====
local scanGui = Instance.new("Frame", gui)
scanGui.Size = UDim2.new(0,200,0,200)
scanGui.Position = UDim2.new(0.7,0,0.5,-100)
scanGui.BackgroundColor3 = Color3.fromRGB(0,0,0)
scanGui.Visible = false
Instance.new("UICorner",scanGui)

local scanBtn = btn("OPEN SCAN",350)
scanBtn.MouseButton1Click:Connect(function()
	scanGui.Visible = not scanGui.Visible
end)

local list = Instance.new("ScrollingFrame", scanGui)
list.Size = UDim2.new(1,0,1,-40)
list.CanvasSize = UDim2.new(0,0,0,500)

local scanNow = Instance.new("TextButton", scanGui)
scanNow.Size = UDim2.new(1,0,0,40)
scanNow.Position = UDim2.new(0,0,1,-40)
scanNow.Text = "SCAN"

scanNow.MouseButton1Click:Connect(function()
	list:ClearAllChildren()
	local char = getChar()
	local root = getRoot(char)

	local y = 0
	for _,m in pairs(workspace:GetDescendants()) do
		if m:IsA("Model") and isValid(m) then
			local part = getRoot(m)
			if part then
				local dist = (part.Position-root.Position).Magnitude
				if dist <= scanDistance then
					local b = Instance.new("TextButton", list)
					b.Size = UDim2.new(1,0,0,30)
					b.Position = UDim2.new(0,0,0,y)
					b.Text = m.Name
					b.BackgroundColor3 = Color3.fromRGB(255,255,255)

					b.MouseButton1Click:Connect(function()
						selectedTarget = m
					end)

					y += 35
				end
			end
		end
	end
end)

--// ===== DRAG =====
local dragging,dragStart,startPos

frame.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging then
		local delta = i.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
	end
end)

UIS.InputEnded:Connect(function()
	dragging = false
end)
