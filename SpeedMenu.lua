--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// STATE
local lockEnabled = false
local nearestEnabled = true
local lockMode = "Player"
local lockedTarget = nil
local lockStrength = 1
local detectionRange = 500

local scanOpen = false
local selectedColors = {}

--// HELPERS
local function getChar()
	local c = player.Character or player.CharacterAdded:Wait()
	return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Head")
end

local function getRoot(m)
	return m and m:FindFirstChild("HumanoidRootPart")
end

local function isAlive(m)
	local h = m and m:FindFirstChildOfClass("Humanoid")
	return h and h.Health > 0
end

--// TARGET LIST
local function buildTargets()
	local list = {}
	local char, hrp = getChar()

	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and isAlive(p.Character) then
				local r = getRoot(p.Character)
				if r and (r.Position - hrp.Position).Magnitude <= detectionRange then
					table.insert(list,{
						model = p.Character,
						name = p.Name,
						color = p.Team and p.Team.TeamColor.Color or Color3.new(1,1,1)
					})
				end
			end
		end
	else
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
				local r = getRoot(obj)
				if r and isAlive(obj) and (r.Position - hrp.Position).Magnitude <= detectionRange then
					table.insert(list,{
						model = obj,
						name = obj.Name,
						color = Color3.fromRGB(255,80,80)
					})
				end
			end
		end
	end

	return list
end

--// LOCK SYSTEM (FINAL)
local lockConn
local function startLock()
	if lockConn then lockConn:Disconnect() end

	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.Classic

	lockConn = RunService.RenderStepped:Connect(function()
		if not lockEnabled then return end

		local char, hrp, head = getChar()

		if not lockedTarget then
			if nearestEnabled then
				local list = buildTargets()
				local best, dist = nil, math.huge
				for _, t in ipairs(list) do
					local r = getRoot(t.model)
					if r then
						local d = (r.Position - hrp.Position).Magnitude
						if d < dist then
							dist = d
							best = t.model
						end
					end
				end
				lockedTarget = best
			end
			return
		end

		local root = getRoot(lockedTarget)
		if not root or not isAlive(lockedTarget) then
			lockedTarget = nil
			return
		end

		local s = math.clamp(lockStrength, 0.05, 1)

		local flat = (root.Position - hrp.Position) * Vector3.new(1,0,1)
		if flat.Magnitude > 0.1 then
			local cf = CFrame.lookAt(hrp.Position, hrp.Position + flat)
			hrp.CFrame = hrp.CFrame:Lerp(cf, s)
		end

		local camPos = camera.CFrame.Position
		local camLook = CFrame.lookAt(camPos, root.Position)
		camera.CFrame = camera.CFrame:Lerp(camLook, s*0.7)
	end)
end

local function stopLock()
	if lockConn then lockConn:Disconnect() end
	lockConn = nil
	lockedTarget = nil
end

--// UI BUILDER
local function makeWindow(titleText, pos)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0,220,0,300)
	f.Position = pos
	f.BackgroundColor3 = Color3.fromRGB(20,20,20)
	f.Active = true
	f.Draggable = true
	f.Parent = game.CoreGui

	local title = Instance.new("TextLabel", f)
	title.Size = UDim2.new(1,0,0,25)
	title.Text = titleText
	title.BackgroundColor3 = Color3.fromRGB(30,30,30)
	title.TextColor3 = Color3.new(1,1,1)

	local close = Instance.new("TextButton", f)
	close.Size = UDim2.new(0,25,0,25)
	close.Position = UDim2.new(1,-25,0,0)
	close.Text = "X"
	close.MouseButton1Click:Connect(function()
		f:Destroy()
	end)

	local sizeBox = Instance.new("TextBox", f)
	sizeBox.Size = UDim2.new(0,40,0,20)
	sizeBox.Position = UDim2.new(1,-70,0,3)
	sizeBox.Text = "10"

	sizeBox.FocusLost:Connect(function()
		local v = tonumber(sizeBox.Text)
		if v then
			local scale = v/10
			f.Size = UDim2.new(0,220*scale,0,300*scale)
		end
	end)

	return f
end

-- MAIN UI
local main = makeWindow("AIMLOCK", UDim2.new(0,50,0,120))

local function makeBtn(p, text, y, fn)
	local b = Instance.new("TextButton", p)
	b.Size = UDim2.new(1,-10,0,32)
	b.Position = UDim2.new(0,5,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	b.MouseButton1Click:Connect(fn)
	return b
end

makeBtn(main,"LOCK",40,function()
	lockEnabled = not lockEnabled
	if lockEnabled then startLock() else stopLock() end
end)

makeBtn(main,"NEAREST",80,function()
	nearestEnabled = not nearestEnabled
end)

makeBtn(main,"MODE",120,function()
	lockMode = lockMode=="Player" and "NPC" or "Player"
end)

local rangeBox = Instance.new("TextBox", main)
rangeBox.Position = UDim2.new(0,5,0,160)
rangeBox.Size = UDim2.new(1,-10,0,25)
rangeBox.Text = "500"
rangeBox.FocusLost:Connect(function()
	local v = tonumber(rangeBox.Text)
	if v then detectionRange = v end
end)

local strengthBox = Instance.new("TextBox", main)
strengthBox.Position = UDim2.new(0,5,0,195)
strengthBox.Size = UDim2.new(1,-10,0,25)
strengthBox.Text = "1"
strengthBox.FocusLost:Connect(function()
	local v = tonumber(strengthBox.Text)
	if v then lockStrength = v end
end)

-- SCAN WINDOW
local scan = makeWindow("SCAN", UDim2.new(0,280,0,120))
scan.Visible = false

makeBtn(main,"SCAN MENU",230,function()
	scanOpen = not scanOpen
	scan.Visible = scanOpen
end)

local listFrame = Instance.new("ScrollingFrame", scan)
listFrame.Size = UDim2.new(1,-10,1,-40)
listFrame.Position = UDim2.new(0,5,0,35)
listFrame.CanvasSize = UDim2.new(0,0,0,0)

local layout = Instance.new("UIListLayout", listFrame)

local function runScan()
	for _,c in ipairs(listFrame:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	for _,t in ipairs(buildTargets()) do
		local btn = Instance.new("TextButton", listFrame)
		btn.Size = UDim2.new(1,0,0,28)
		btn.Text = t.name
		btn.BackgroundColor3 = t.color
		btn.TextColor3 = Color3.new(1,1,1)

		btn.MouseButton1Click:Connect(function()
			lockedTarget = t.model
			lockEnabled = true
			startLock()
		end)
	end
end

makeBtn(scan,"SCAN",5,runScan)

-- RESPAWN FIX
player.CharacterAdded:Connect(function()
	task.wait(1)
	if lockEnabled then startLock() end
end)
