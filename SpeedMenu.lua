-- ScatterUI_Mobile.lua
-- LocalScript สำหรับมือถือ
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character, humanoid, hrp

local function setupCharacter(c)
	character = c
	humanoid = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

-- ค่าเริ่มต้น
local config = {
	Force = 60, -- แรงกระจาย
	Spread = 8, -- ความกระจาย
	Spin = 2, -- การหมุน
}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ScatterUI_Mobile"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 200)
frame.Position = UDim2.new(1, -270, 1, -240)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui
frame.Visible = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "⚙ Scatter Control"
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundColor3 = Color3.fromRGB(0, 150, 255)

local function makeBox(labelText, defaultValue, yPos)
	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(0.5, -10, 0, 30)
	lbl.Position = UDim2.new(0, 10, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = labelText
	lbl.Font = Enum.Font.SourceSans
	lbl.TextScaled = true

	local box = Instance.new("TextBox", frame)
	box.Size = UDim2.new(0.4, 0, 0, 30)
	box.Position = UDim2.new(0.55, 0, 0, yPos)
	box.Text = tostring(defaultValue)
	box.Font = Enum.Font.SourceSans
	box.TextScaled = true
	return box
end

local boxForce = makeBox("แรง", config.Force, 50)
local boxSpread = makeBox("กระจาย", config.Spread, 90)
local boxSpin = makeBox("หมุน", config.Spin, 130)

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 160)
toggleBtn.Text = "▶ เปิดระบบ"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextScaled = true
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)

local active = false
toggleBtn.MouseButton1Click:Connect(function()
	active = not active
	if active then
		toggleBtn.Text = "⏹ ปิดระบบ"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	else
		toggleBtn.Text = "▶ เปิดระบบ"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
	end
end)

local clones = {}

-- ฟังก์ชันกระจาย
local function scatterParts()
	if not character or not hrp then return end
	for _, old in ipairs(clones) do
		if old and old.Parent then old:Destroy() end
	end
	clones = {}

	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local clone = part:Clone()
			clone.Anchored = false
			clone.CanCollide = true
			clone.CFrame = part.CFrame
			clone.Parent = workspace

			part.Transparency = 1
			part.CanCollide = false

			local dir = Vector3.new(
				math.random(-config.Spread, config.Spread),
				math.random(3, 8),
				math.random(-config.Spread, config.Spread)
			).Unit

			local bv = Instance.new("BodyVelocity")
			bv.Velocity = dir * config.Force
			bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			bv.Parent = clone

			local bav = Instance.new("BodyAngularVelocity")
			bav.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			bav.AngularVelocity = Vector3.new(
				math.random() * config.Spin,
				math.random() * config.Spin,
				math.random() * config.Spin
			)
			bav.Parent = clone

			table.insert(clones, clone)
			Debris:AddItem(clone, 8)
		end
	end
end

-- ฟังก์ชันรวมกลับ
local function reassemble()
	if not character or not hrp then return end
	for _, clone in ipairs(clones) do
		if clone and clone.Parent then
			local tween = TweenService:Create(clone, TweenInfo.new(0.5), {CFrame = hrp.CFrame})
			tween:Play()
			tween.Completed:Connect(function()
				clone:Destroy()
			end)
		end
	end
	clones = {}

	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Transparency = 0
			part.CanCollide = true
		end
	end
end

-- ตรวจจับการเดินมือถือ (MoveDirection)
local moving = false
RunService.RenderStepped:Connect(function()
	if not humanoid then return end
	local move = humanoid.MoveDirection.Magnitude > 0
	if active then
		if move and not moving then
			moving = true
			scatterParts()
		elseif not move and moving then
			moving = false
			reassemble()
		end
	end
end)

-- อัปเดตค่าเมื่อเปลี่ยน textbox
boxForce.FocusLost:Connect(function() config.Force = tonumber(boxForce.Text) or config.Force end)
boxSpread.FocusLost:Connect(function() config.Spread = tonumber(boxSpread.Text) or config.Spread end)
boxSpin.FocusLost:Connect(function() config.Spin = tonumber(boxSpin.Text) or config.Spin end)

print("[ScatterUI_Mobile] Loaded successfully ✅")
