--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

--// Player
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getChar()
	return player.Character or player.CharacterAdded:Wait()
end

--// State
local lockEnabled = false
local currentTarget = nil
local targetMode = "Monster"

local offsetY = 0 -- 🔥 ปรับสูงต่ำ
local scanRange = 200

--// Utils
local function isAlive(model)
	local hum = model and model:FindFirstChild("Humanoid")
	return hum and hum.Health > 0
end

local function getPart(model)
	return model:FindFirstChild("HumanoidRootPart")
end

local function isValid(model)
	if not isAlive(model) then return false end
	local plr = Players:GetPlayerFromCharacter(model)

	if targetMode == "Monster" then
		return plr == nil
	else
		return plr and plr ~= player
	end
end

local function getClosest(root)
	local closest, dist = nil, math.huge

	if targetMode == "Player" then
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player and p.Character and isValid(p.Character) then
				local part = getPart(p.Character)
				if part then
					local d = (part.Position - root.Position).Magnitude
					if d < dist and d <= scanRange then
						dist = d
						closest = p.Character
					end
				end
			end
		end
	else
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj ~= root.Parent and isValid(obj) then
				local part = getPart(obj)
				if part then
					local d = (part.Position - root.Position).Magnitude
					if d < dist and d <= scanRange then
						dist = d
						closest = obj
					end
				end
			end
		end
	end

	return closest
end

--// LOCK SYSTEM
RunService.RenderStepped:Connect(function()
	if not lockEnabled then return end

	local char = getChar()
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if not currentTarget or not isAlive(currentTarget) then
		currentTarget = getClosest(root)
	end

	if not currentTarget then return end

	local part = getPart(currentTarget)
	if not part then return end

	local aimPos = part.Position + Vector3.new(0, offsetY, 0)

	-- 🎯 หมุนตัว
	root.CFrame = CFrame.new(root.Position, aimPos)

	-- 🎥 กล้อง 3rd person
	local camOffset = root.CFrame.LookVector * -8 + Vector3.new(0, 3, 0)
	camera.CFrame = CFrame.new(root.Position + camOffset, aimPos)
end)

--// ================= UI =================

local gui = Instance.new("ScreenGui", player.PlayerGui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 260)
frame.Position = UDim2.new(0.5, -120, 0.5, -130)
frame.BackgroundColor3 = Color3.fromRGB(240,240,240)
Instance.new("UICorner", frame)

local function makeBtn(text, y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0.85,0,0,30)
	b.Position = UDim2.new(0.075,0,y,0)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(30,30,30)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)
	return b
end

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "PRO LOCK"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(0,0,0)
title.Active = true

-- Buttons
local lockBtn = makeBtn("Lock: OFF",0.15)
local modeBtn = makeBtn("Mode: Monster",0.3)
local scanBtn = makeBtn("Scan Menu",0.45)

-- Offset Input
local offsetBox = Instance.new("TextBox", frame)
offsetBox.Size = UDim2.new(0.85,0,0,30)
offsetBox.Position = UDim2.new(0.075,0,0.6,0)
offsetBox.PlaceholderText = "Y Offset (-1 / 0 / 1)"
offsetBox.Text = "0"
Instance.new("UICorner", offsetBox)

-- Range Input
local rangeBox = Instance.new("TextBox", frame)
rangeBox.Size = UDim2.new(0.85,0,0,30)
rangeBox.Position = UDim2.new(0.075,0,0.75,0)
rangeBox.PlaceholderText = "Range (e.g. 200)"
rangeBox.Text = "200"
Instance.new("UICorner", rangeBox)

-- Close
local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,20,0,20)
close.Position = UDim2.new(1,-25,0,5)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(200,50,50)

--// BUTTON LOGIC

lockBtn.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	lockBtn.Text = "Lock: "..(lockEnabled and "ON" or "OFF")
end)

modeBtn.MouseButton1Click:Connect(function()
	targetMode = (targetMode=="Monster") and "Player" or "Monster"
	modeBtn.Text = "Mode: "..targetMode
end)

offsetBox.FocusLost:Connect(function()
	local val = tonumber(offsetBox.Text)
	if val then offsetY = val end
end)

rangeBox.FocusLost:Connect(function()
	local val = tonumber(rangeBox.Text)
	if val then scanRange = val end
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

--// DRAG (มือถือ)
local drag=false
local dragStart, startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
		drag=true
		dragStart=input.Position
		startPos=frame.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if drag then
		local delta=input.Position-dragStart
		frame.Position=UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset+delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset+delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function()
	drag=false
end)
