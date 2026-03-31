--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

--// STATE
local lockEnabled = false
local lockMode = "Player"

local targetList = {}
local targetIndex = 1
local lockedTarget = nil
local lockConn

--// SAFE
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local head = char:WaitForChild("Head")
	return char, hrp, head
end

local function getRoot(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

--// TARGET LIST
local function buildTargetList()
	targetList = {}

	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				table.insert(targetList, p.Character)
			end
		end
	else
		local playerChars = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then playerChars[p.Character] = true end
		end

		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model")
			and not playerChars[obj]
			and obj:FindFirstChildOfClass("Humanoid")
			and obj:FindFirstChild("HumanoidRootPart") then
				table.insert(targetList, obj)
			end
		end
	end
end

--// FRONT TARGET
local function getFrontTarget()
	buildTargetList()

	local best, bestDot = nil, -math.huge
	local camCF = camera.CFrame

	for _, t in ipairs(targetList) do
		local root = getRoot(t)
		if root then
			local dir = (root.Position - camCF.Position).Unit
			local dot = camCF.LookVector:Dot(dir)
			if dot > bestDot then
				bestDot = dot
				best = t
			end
		end
	end

	return best
end

--// LOCK FIRST PERSON
local function startLock()
	if lockConn then lockConn:Disconnect() end

	lockedTarget = getFrontTarget()

	lockConn = RunService.RenderStepped:Connect(function()
		if not lockEnabled then return end

		local char, hrp, head = getChar()

		if not lockedTarget then
			lockedTarget = getFrontTarget()
			return
		end

		local root = getRoot(lockedTarget)
		if not root then
			lockedTarget = nil
			return
		end

		-- หมุนตัวละคร
		local flat = (root.Position - hrp.Position) * Vector3.new(1,0,1)
		if flat.Magnitude > 0.1 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
		end

		-- กล้อง First Person (ติดหัว)
		local headPos = head.Position
		camera.CFrame = CFrame.lookAt(headPos, root.Position)
	end)
end

local function stopLock()
	if lockConn then lockConn:Disconnect() end
	lockedTarget = nil
end

--// SWITCH TARGET
local function switchTarget()
	buildTargetList()
	if #targetList == 0 then return end

	targetIndex += 1
	if targetIndex > #targetList then
		targetIndex = 1
	end

	lockedTarget = targetList[targetIndex]
end

--// TOGGLE
local function toggleLock(btn)
	lockEnabled = not lockEnabled

	btn.Text = "Lock: " .. (lockEnabled and "ON" or "OFF")

	if lockEnabled then
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson -- 🔥 สำคัญ
		startLock()
	else
		player.CameraMode = Enum.CameraMode.Classic
		stopLock()
	end
end

--// UI
local function makeBtn(text, y)
	local b = Instance.new("TextButton", gui)
	b.Size = UDim2.new(0,130,0,40)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	return b
end

local lockBtn = makeBtn("Lock: OFF", 200)
local nextBtn = makeBtn("Next", 250)
local modeBtn = makeBtn("Mode: Player", 300)

--// EVENTS
lockBtn.MouseButton1Click:Connect(function()
	toggleLock(lockBtn)
end)

nextBtn.MouseButton1Click:Connect(function()
	switchTarget()
end)

modeBtn.MouseButton1Click:Connect(function()
	lockMode = (lockMode == "Player") and "NPC" or "Player"
	modeBtn.Text = "Mode: " .. lockMode
end)
