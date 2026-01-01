--// ANYTHING FLY - PRO MAX LEVEL 2 (ULTIMATE)
--// Fly + Vehicle | NoClip | Hover | Jet | Altitude Lock | Mobile UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------
-- SETTINGS
--------------------------------------------------
local BASE_SPEED = 60
local SPEED_MULT = 1
local DEADZONE = 0.12

local flying = false
local noclip = false

local MODE = "FREE" -- FREE / HOVER / JET
local altitudeLock = false
local lockedY = 0

local humanoid, controlPart, mode
local alignOri, linearVel

--------------------------------------------------
-- CONTROL PART
--------------------------------------------------
local function getModelCenter(model)
	local cf = model:GetBoundingBox()
	local p = Instance.new("Part")
	p.Size = Vector3.new(2,2,2)
	p.Transparency = 1
	p.CanCollide = false
	p.CFrame = cf
	p.Parent = model
	Instance.new("WeldConstraint", p).Part1 = model:FindFirstChildWhichIsA("BasePart")
	return p
end

local function getControl()
	local char = player.Character
	if not char then return end
	humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.SeatPart then
		local model = humanoid.SeatPart:FindFirstAncestorOfClass("Model")
		if model then
			mode = "VEH"
			return model.PrimaryPart or getModelCenter(model)
		end
	end
	mode = "CHAR"
	return char and char:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------
-- NOCLIP
--------------------------------------------------
local function applyNoClip(state)
	if player.Character then
		for _,v in pairs(player.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = not state
			end
		end
	end
end

--------------------------------------------------
-- START / STOP FLY
--------------------------------------------------
local function startFly()
	if flying then return end
	controlPart = getControl()
	if not controlPart then return end
	flying = true

	if mode == "CHAR" then
		humanoid.PlatformStand = true
	end

	pcall(function()
		controlPart:SetNetworkOwner(player)
	end)

	alignOri = Instance.new("AlignOrientation", controlPart)
	alignOri.Attachment0 = Instance.new("Attachment", controlPart)
	alignOri.MaxTorque = math.huge
	alignOri.Responsiveness = 25

	linearVel = Instance.new("LinearVelocity", controlPart)
	linearVel.Attachment0 = alignOri.Attachment0
	linearVel.MaxForce = math.huge

	if noclip then applyNoClip(true) end
end

local function stopFly()
	flying = false
	if humanoid then humanoid.PlatformStand = false end
	if alignOri then alignOri:Destroy() end
	if linearVel then linearVel:Destroy() end
end

--------------------------------------------------
-- UI
--------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local open = Instance.new("TextButton", gui)
open.Size = UDim2.fromScale(0.09,0.045)
open.Position = UDim2.fromScale(0.02,0.6)
open.Text = "FLY"
open.TextScaled = true
open.BackgroundColor3 = Color3.fromRGB(0,120,255)

local panel = Instance.new("Frame", gui)
panel.Size = UDim2.fromScale(0.3,0.38)
panel.Position = UDim2.fromScale(0.35,0.3)
panel.BackgroundColor3 = Color3.fromRGB(20,20,20)
panel.Visible = false
panel.Active = true
panel.Draggable = true

local function btn(txt,y)
	local b = Instance.new("TextButton", panel)
	b.Size = UDim2.fromScale(0.85,0.12)
	b.Position = UDim2.fromScale(0.075,y)
	b.Text = txt
	b.TextScaled = true
	return b
end

local flyBtn = btn("FLY : OFF",0.05)
local modeBtn = btn("MODE : FREE",0.2)
local altBtn = btn("ALT LOCK : OFF",0.35)
local noclipBtn = btn("NOCLIP : OFF",0.5)

local speedBox = Instance.new("TextBox", panel)
speedBox.Size = UDim2.fromScale(0.85,0.12)
speedBox.Position = UDim2.fromScale(0.075,0.68)
speedBox.Text = "1"
speedBox.PlaceholderText = "Speed Multiplier"

--------------------------------------------------
-- UI LOGIC
--------------------------------------------------
open.MouseButton1Click:Connect(function()
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

modeBtn.MouseButton1Click:Connect(function()
	if MODE == "FREE" then MODE="HOVER"
	elseif MODE=="HOVER" then MODE="JET"
	else MODE="FREE" end
	modeBtn.Text = "MODE : "..MODE
end)

altBtn.MouseButton1Click:Connect(function()
	altitudeLock = not altitudeLock
	if controlPart then lockedY = controlPart.Position.Y end
	altBtn.Text = altitudeLock and "ALT LOCK : ON" or "ALT LOCK : OFF"
end)

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	applyNoClip(noclip)
	noclipBtn.Text = noclip and "NOCLIP : ON" or "NOCLIP : OFF"
end)

speedBox.FocusLost:Connect(function()
	SPEED_MULT = tonumber(speedBox.Text) or SPEED_MULT
end)

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not controlPart then return end

	alignOri.CFrame = camera.CFrame
	local dir = humanoid.MoveDirection
	local speed = BASE_SPEED * SPEED_MULT
	local vel = Vector3.zero

	if MODE == "JET" then
		vel = camera.CFrame.LookVector * speed * 2
	else
		vel = Vector3.new(dir.X*speed,0,dir.Z*speed)
	end

	if MODE ~= "HOVER" then
		local y = camera.CFrame.LookVector.Y
		if math.abs(y) > DEADZONE then
			vel += Vector3.new(0,y*speed,0)
		end
	end

	if altitudeLock then
		vel = Vector3.new(vel.X,(lockedY-controlPart.Position.Y)*6,vel.Z)
	end

	linearVel.VectorVelocity = vel
end)
