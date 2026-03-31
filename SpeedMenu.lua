--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MobileLockUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

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
	return char, hrp
end

local function getRoot(model)
	return model and model:FindFirstChild("HumanoidRootPart")
end

--// BUILD LIST (FIX NPC)
local function buildTargetList()
	targetList = {}

	if lockMode == "Player" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				local root = getRoot(p.Character)
				if root then
					table.insert(targetList, p.Character)
				end
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

--// LOCK (FIX CAMERA FOLLOW)
local function startLock()
	if lockConn then lockConn:Disconnect() end

	lockedTarget = getFrontTarget()

	lockConn = RunService.RenderStepped:Connect(function()
		if not lockEnabled then return end

		local char, hrp = getChar()

		if not lockedTarget then
			lockedTarget = getFrontTarget()
			return
		end

		local root = getRoot(lockedTarget)
		if not root then
			lockedTarget = nil
			return
		end

		-- rotate character
		local flat = (root.Position - hrp.Position) * Vector3.new(1,0,1)
		if flat.Magnitude > 0.1 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
		end

		-- CAMERA FOLLOW PLAYER + LOOK TARGET
		local camOffset = CFrame.new(0, 5, 10) -- ระยะกล้องหลังตัว
		local camPos = hrp.CFrame * camOffset
		camera.CFrame = CFrame.lookAt(camPos.Position, root.Position)
	end)
end

local function stopLock()
	if lockConn then lockConn:Disconnect() end
	lockedTarget = nil
end

--// SWITCH
local function switchTarget()
	buildTargetList()
	if #targetList == 0 then return end

	targetIndex = targetIndex + 1
	if targetIndex > #targetList then
		targetIndex = 1
	end

	lockedTarget = targetList[targetIndex]
end

--// TOGGLE
local function toggleLock(btn)
	lockEnabled = not lockEnabled

	btn.Text = "Lock: " .. (lockEnabled and "ON" or "OFF")
	btn.BackgroundColor3 = lockEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)

	if lockEnabled then
		camera.CameraType = Enum.CameraType.Scriptable
		startLock()
	else
		camera.CameraType = Enum.CameraType.Custom
		stopLock()
	end
end

--// UI
local function makeBtn(text, y)
	local b = Instance.new("TextButton", gui)
	b.Size = UDim2.new(0,120,0,40)
	b.Position = UDim2.new(0,10,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.TextColor3 = Color3.new(1,1,1)
	return b
end

local lockBtn = makeBtn("Lock: OFF", 200)
local nextBtn = makeBtn("Next Target", 250)
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
