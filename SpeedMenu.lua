-- ScatterUI_Mobile_Fixed.lua
-- รองรับมือถือเต็มรูปแบบ พร้อมระบบลาก UI และแตกกระจายจริง

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char, hum, hrp

local function setupCharacter(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")
	workspace:SetNetworkOwner(hrp, player)
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

local config = {
	Force = 60,
	Spread = 8,
	Spin = 2,
}

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "ScatterUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 200)
frame.Position = UDim2.new(0.35, 0, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
frame.Active = true
frame.Draggable = false -- เราจะใช้โค้ดลากเอง
frame.Parent = gui

local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)
frame.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
title.Text = "ตัวกระจาย"
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)

local function makeBox(labelText, defaultValue, y)
	local lbl = Instance.new("TextLabel", frame)
	lbl.Position = UDim2.new(0, 10, 0, y)
	lbl.Size = UDim2.new(0.4, 0, 0, 30)
	lbl.Text = labelText
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSans
	lbl.TextScaled = true

	local box = Instance.new("TextBox", frame)
	box.Position = UDim2.new(0.55, 0, 0, y)
	box.Size = UDim2.new(0.4, 0, 0, 30)
	box.Text = tostring(defaultValue)
	box.Font = Enum.Font.SourceSans
	box.TextScaled = true
	box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	box.TextColor3 = Color3.new(1, 1, 1)
	return box
end

local boxForce = makeBox("แรง", config.Force, 50)
local boxSpread = makeBox("กระจาย", config.Spread, 90)
local boxSpin = makeBox("หมุน", config.Spin, 130)

local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(0.9, 0, 0, 35)
toggle.Position = UDim2.new(0.05, 0, 0, 165)
toggle.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
toggle.Text = "▶ เปิดการทำงาน"
toggle.Font = Enum.Font.SourceSansBold
toggle.TextScaled = true
toggle.TextColor3 = Color3.new(1, 1, 1)

local active = false
toggle.MouseButton1Click:Connect(function()
	active = not active
	if active then
		toggle.Text = "⏹ ปิดการทำงาน"
		toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	else
		toggle.Text = "▶ เปิดการทำงาน"
		toggle.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	end
end)

boxForce.FocusLost:Connect(function() config.Force = tonumber(boxForce.Text) or config.Force end)
boxSpread.FocusLost:Connect(function() config.Spread = tonumber(boxSpread.Text) or config.Spread end)
boxSpin.FocusLost:Connect(function() config.Spin = tonumber(boxSpin.Text) or config.Spin end)

-- ระบบตัวแตก
local clones = {}
local moving = false

local function scatterParts()
	if not char or not hrp then return end
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local clone = part:Clone()
			clone.Anchored = false
			clone.CanCollide = true
			clone.CFrame = part.CFrame
			clone.Parent = workspace

			part.Transparency = 1
			part.CanCollide = false

			local force = Instance.new("BodyVelocity")
			force.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			force.Velocity = Vector3.new(
				math.random(-config.Spread, config.Spread),
				math.random(3, 8),
				math.random(-config.Spread, config.Spread)
			) * (config.Force / 10)
			force.Parent = clone

			local spin = Instance.new("BodyAngularVelocity")
			spin.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			spin.AngularVelocity = Vector3.new(
				math.random() * config.Spin,
				math.random() * config.Spin,
				math.random() * config.Spin
			)
			spin.Parent = clone

			table.insert(clones, clone)
			Debris:AddItem(clone, 8)
		end
	end
end

local function reassemble()
	for _, clone in ipairs(clones) do
		if clone and clone.Parent then
			local tween = TweenService:Create(clone, TweenInfo.new(0.6), {CFrame = hrp.CFrame})
			tween:Play()
			tween.Completed:Connect(function()
				clone:Destroy()
			end)
		end
	end
	clones = {}

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.Transparency = 0
			part.CanCollide = true
		end
	end
end

RunService.RenderStepped:Connect(function()
	if hum and active then
		local move = hum.MoveDirection.Magnitude > 0
		if move and not moving then
			moving = true
			scatterParts()
		elseif not move and moving then
			moving = false
			reassemble()
		end
	end
end)

print("[✅ ScatterUI Mobile Fixed Loaded]")
