--// SERVICES  
local Players = game:GetService("Players")  
local RunService = game:GetService("RunService")  
local TweenService = game:GetService("TweenService")  
local UserInputService = game:GetService("UserInputService")  

local player = Players.LocalPlayer  
local camera = workspace.CurrentCamera  

--// GUI ROOT  
local gui = Instance.new("ScreenGui")  
gui.Name = "AimLockGUI"  
gui.ResetOnSpawn = false  
gui.IgnoreGuiInset = true  
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  
gui.Parent = game.CoreGui  

--// STATE  
local lockEnabled = false  
local nearestEnabled = false  
local scanWindowOpen = false  
local lockMode = "Player"  
local lockedTarget = nil  
local lockConn = nil  
local lockStrength = 1  
local detectionRange = 500  

--// HELPERS  
local function getChar()  
	local char = player.Character or player.CharacterAdded:Wait()  
	return char, char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Head")  
end  

local function getRoot(model)  
	return model and model:FindFirstChild("HumanoidRootPart")  
end  

local function getHumanoid(model)  
	return model and model:FindFirstChildOfClass("Humanoid")  
end  

local function isAlive(model)  
	local h = getHumanoid(model)  
	return h and h.Health > 0  
end  

--// BUILD TARGET LIST  
local function buildTargetList()  
	local list = {}  
	local char = player.Character  
	local hrp = char and char:FindFirstChild("HumanoidRootPart")  
	if not hrp then return list end  

	if lockMode == "Player" then  
		for _, p in ipairs(Players:GetPlayers()) do  
			if p ~= player and p.Character and isAlive(p.Character) then  
				local root = getRoot(p.Character)  
				if root then  
					local dist = (root.Position - hrp.Position).Magnitude  
					if dist <= detectionRange then  
						table.insert(list, p.Character)  
					end  
				end  
			end  
		end  
	else  
		local playerChars = {}  
		for _, p in ipairs(Players:GetPlayers()) do  
			if p.Character then playerChars[p.Character] = true end  
		end  

		for _, obj in ipairs(workspace:GetDescendants()) do  
			if obj:IsA("Model") and not playerChars[obj]  
				and obj:FindFirstChildOfClass("Humanoid")  
				and obj:FindFirstChild("HumanoidRootPart")  
				and isAlive(obj) then  

				local root = getRoot(obj)  
				if root then  
					local dist = (root.Position - hrp.Position).Magnitude  
					if dist <= detectionRange then  
						table.insert(list, obj)  
					end  
				end  
			end  
		end  
	end  

	return list  
end  

--// GET NEAREST  
local function getNearestTarget(list)  
	local char = player.Character  
	local hrp = char and char:FindFirstChild("HumanoidRootPart")  
	if not hrp then return nil end  

	local best, bestDist = nil, math.huge  
	for _, t in ipairs(list) do  
		local root = getRoot(t)  
		if root then  
			local d = (root.Position - hrp.Position).Magnitude  
			if d < bestDist then  
				bestDist = d  
				best = t  
			end  
		end  
	end  
	return best  
end  

--// 🔥 FIXED LOCK SYSTEM
local function startLock()  
	if lockConn then lockConn:Disconnect() end  

	camera.CameraType = Enum.CameraType.Custom  
	player.CameraMode = Enum.CameraMode.Classic  

	lockConn = RunService.RenderStepped:Connect(function()  
		if not lockEnabled then return end  

		local ok, char, hrp, head = pcall(getChar)  
		if not ok then return end  

		-- auto target  
		if not lockedTarget and nearestEnabled then  
			local list = buildTargetList()  
			lockedTarget = getNearestTarget(list)  
			return  
		end  

		if not lockedTarget then return end  

		local root = getRoot(lockedTarget)  
		if not root or not isAlive(lockedTarget) then  
			lockedTarget = nil  
			return  
		end  

		-- 🔥 strength fix (แรงขึ้น)
		local s = math.clamp(lockStrength, 0.05, 1)  

		-- ตัวละครหัน
		local flat = (root.Position - hrp.Position) * Vector3.new(1,0,1)  
		if flat.Magnitude > 0.1 then  
			local targetCF = CFrame.lookAt(hrp.Position, hrp.Position + flat)  
			hrp.CFrame = hrp.CFrame:Lerp(targetCF, s)  
		end  

		-- กล้องหัน (แต่ยัง zoom ได้)
		local camPos = camera.CFrame.Position  
		local targetLook = CFrame.lookAt(camPos, root.Position)  

		camera.CFrame = camera.CFrame:Lerp(targetLook, s * 0.7)  
	end)  
end  

local function stopLock()  
	if lockConn then  
		lockConn:Disconnect()  
		lockConn = nil  
	end  

	lockedTarget = nil  

	camera.CameraType = Enum.CameraType.Custom  
	player.CameraMode = Enum.CameraMode.Classic  
end  

--// BUTTON SIMULATION (ใช้กับ UI เดิมคุณได้เลย)
local function toggleLock()  
	lockEnabled = not lockEnabled  

	if lockEnabled then  
		startLock()  
	else  
		stopLock()  
	end  
end  

--// RESPAWN FIX
player.CharacterAdded:Connect(function()  
	task.wait(1)  
	if lockEnabled then  
		startLock()  
	end  
end)
