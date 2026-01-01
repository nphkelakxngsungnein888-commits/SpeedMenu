--[[ 
 ANYTHING FLY - MASTER VERSION
 Fly + NoClip + Record / Replay System
 Designed by PRO ENGINEER
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

------------------------------------------------
-- CONFIG
------------------------------------------------
local BASE_SPEED = 60
local SPEED_MULT = 1
local DEADZONE = 0.12

local flying = false
local noclip = false

local MODE = "MANUAL" -- MANUAL / RECORD / REPLAY

local humanoid
local controlPart
local modeType

local alignOri
local linearVel

------------------------------------------------
-- RECORD DATA
------------------------------------------------
local recordData = {}
local recordIndex = 1
local recording = false
local replaying = false

------------------------------------------------
-- CONTROL PART
------------------------------------------------
local function getModelCenter(model)
	local cf = model:GetBoundingBox()
	local part = Instance.new("Part")
	part.Size = Vector3.new(2,2,2)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = false
	part.CFrame = cf
	part.Name = "_FlyControl"
	part.Parent = model

	local weld = Instance.new("WeldConstraint", part)
	weld.Part0 = part
	weld.Part1 = model:FindFirstChildWhichIsA("BasePart")

	return part
end

local function getControl()
	local char = player.Character
	if not char then return end

	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if humanoid.SeatPart then
		local model = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
		if model then
			modeType = "VEH"
			return model.PrimaryPart or getModelCenter(model)
		end
	end

	modeType = "CHAR"
	return char:FindFirstChild("HumanoidRootPart")
end

------------------------------------------------
-- NOCLIP
------------------------------------------------
local function applyNoClip(state)
	if player.Character then
		for _,v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = not state
			end
		end
	end
end

------------------------------------------------
-- FLY CORE
------------------------------------------------
local function startFly()
	if flying then return end
	controlPart = getControl()
	if not controlPart then return end
	flying = true

	if modeType == "CHAR" then
		humanoid.PlatformStand = true
	end

	pcall(function()
		controlPart:SetNetworkOwner(player)
	end)

	local att = Instance.new("Attachment", controlPart)

	alignOri = Instance.new("AlignOrientation")
	alignOri.Attachment0 = att
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 25
	alignOri.Parent = controlPart

	linearVel = Instance.new("LinearVelocity")
	linearVel.Attachment0 = att
	linearVel.MaxForce = math.huge
	linearVel.Parent = controlPart
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

------------------------------------------------
-- UI
------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local menuBtn = Instance.new("TextButton", gui)
menuBtn.Size = UDim2.fromScale(0.1,0.045)
menuBtn.Position = UDim2.fromScale(0.02,0.6)
menuBtn.Text = "∆ MODE"
menuBtn.TextScaled = true
menuBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
menuBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", menuBtn)

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.3,0.28)
panel.Position = UDim2.fromScale(0.35,0.34)
panel.Visible = false
panel.Active = true
panel.Draggable = true
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
Instance.new("UICorner", panel)

local function createBtn(text,y)
	local b = Instance.new("TextButton", panel)
	b.Size = UDim2.fromScale(0.85,0.18)
	b.Position = UDim2.fromScale(0.075,y)
	b.Text = text
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)
	return b
end

local flyBtn = createBtn("FLY : OFF",0.05)
local manualBtn = createBtn("MODE : MANUAL",0.28)
local recordBtn = createBtn("● RECORD",0.51)
local replayBtn = createBtn("▶ REPLAY",0.74)

------------------------------------------------
-- UI LOGIC
------------------------------------------------
menuBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

flyBtn.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyBtn.Text = "FLY : OFF"
	else
		startFly()
		flyBtn.Text = "FLY : ON"
	end
end)

manualBtn.MouseButton1Click:Connect(function()
	MODE = "MANUAL"
	manualBtn.Text = "MODE : MANUAL"
end)

recordBtn.MouseButton1Click:Connect(function()
	MODE = "RECORD"
	recordData = {}
	recording = true
	replaying = false
	recordIndex = 1
end)

replayBtn.MouseButton1Click:Connect(function()
	if #recordData == 0 then return end
	MODE = "REPLAY"
	recording = false
	replaying = true
	recordIndex = 1
end)

------------------------------------------------
-- MAIN LOOP
------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	if not flying or not controlPart then return end

	if MODE == "REPLAY" and replaying then
		local frame = recordData[recordIndex]
		if frame then
			controlPart.CFrame = frame.cf
			recordIndex += 1
		else
			replaying = false
			MODE = "MANUAL"
		end
		return
	end

	alignOri.CFrame = camera.CFrame

	local dir = humanoid.MoveDirection
	local vel = Vector3.new(
		dir.X * BASE_SPEED * SPEED_MULT,
		0,
		dir.Z * BASE_SPEED * SPEED_MULT
	)

	if dir.Magnitude > 0.05 then
		local y = camera.CFrame.LookVector.Y
		if math.abs(y) > DEADZONE then
			vel += Vector3.new(0,y*BASE_SPEED*0.75*SPEED_MULT,0)
		end
	end

	linearVel.VectorVelocity = vel

	if MODE == "RECORD" and recording then
		table.insert(recordData,{
			cf = controlPart.CFrame
		})
	end
end)
