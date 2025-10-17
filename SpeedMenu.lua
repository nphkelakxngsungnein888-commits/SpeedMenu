--// ตัวกระจายระบบพร้อม UI (เวอร์ชันมือถือ)
-- สร้าง UI อัตโนมัติเมื่อรันเกม

-- สร้างหน้าจอ UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScatterUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- กล่องหลัก
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.35, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- ปุ่มเมนู
local menuBtn = Instance.new("TextButton")
menuBtn.Size = UDim2.new(0, 50, 0, 25)
menuBtn.Position = UDim2.new(0, 5, 0, 5)
menuBtn.Text = "เมนู"
menuBtn.Parent = frame

-- ปุ่มเปิด/ปิดใช้งาน
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 80, 0, 25)
toggleBtn.Position = UDim2.new(1, -85, 0, 5)
toggleBtn.Text = "ปิดใช้งาน"
toggleBtn.Parent = frame

-- ชื่อระบบ
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "ตัวกระจาย"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Parent = frame

-- ช่องปรับค่า 3 ช่อง
local valueNames = {"แรงกระเด็น", "ความกว้าง", "ความเร็ว"}
local textBoxes = {}

for i = 1, 3 do
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 80, 0, 30)
	box.Position = UDim2.new(0, 20 + (i - 1) * 90, 0, 120)
	box.PlaceholderText = valueNames[i]
	box.Text = ""
	box.Parent = frame
	textBoxes[i] = box
end

-- ค่าพารามิเตอร์เริ่มต้น
local enabled = false
local scatterForce = 50
local scatterSpread = 5
local scatterSpeed = 20
local player = game.Players.LocalPlayer

-- ฟังก์ชันปรับค่า
for i, box in ipairs(textBoxes) do
	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val then
			if i == 1 then scatterForce = val end
			if i == 2 then scatterSpread = val end
			if i == 3 then scatterSpeed = val end
		end
	end)
end

-- ปุ่มเปิด/ปิด
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	toggleBtn.Text = enabled and "เปิดใช้งาน" or "ปิดใช้งาน"
end)

-- ฟังก์ชันกระจายและรวม
local function scatterCharacter(char)
	for _, part in pairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Anchored = false
			part.Velocity = Vector3.new(
				math.random(-scatterSpread, scatterSpread) * scatterForce,
				math.random(5, 10) * scatterForce,
				math.random(-scatterSpread, scatterSpread) * scatterForce
			)
		end
	end
end

local function restoreCharacter(char)
	for _, part in pairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.Velocity = Vector3.new(0,0,0)
			part.CFrame = char.HumanoidRootPart.CFrame
		end
	end
end

-- ตรวจจับการเดิน/หยุด
player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")

	humanoid.Running:Connect(function(speed)
		if enabled then
			if speed > 0 then
				scatterCharacter(char)
			else
				restoreCharacter(char)
			end
		end
	end)
end)
