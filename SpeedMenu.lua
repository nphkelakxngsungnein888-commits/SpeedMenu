--// 🌀 UI หลักของระบบเมนูแบบโปร่งใส พับได้ ลากได้เฉพาะปุ่ม "เมนู"
--// เขียนให้ใช้งานได้จริงบนมือถือ Roblox (Touch Input)

-- ตรวจสอบว่ามี ScreenGui อยู่แล้วหรือยัง ถ้ามีให้ลบก่อน
if game.CoreGui:FindFirstChild("SpeedMenu_UI") then
	game.CoreGui:FindFirstChild("SpeedMenu_UI"):Destroy()
end

-- สร้าง UI หลัก
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedMenu_UI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- สร้างกรอบเมนู
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 300, 0, 220)
frame.Position = UDim2.new(0.5, -150, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 0
frame.Visible = true
frame.Parent = gui
frame.Active = true
frame.Draggable = false -- ปิดการลากตรงกรอบ ใช้ลากเฉพาะปุ่มเมนูแทน

-- ปุ่มเมนู
local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.Text = "เมนู"
menuButton.Size = UDim2.new(0, 100, 0, 35)
menuButton.Position = UDim2.new(0.5, -50, 0, -40)
menuButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
menuButton.Font = Enum.Font.SourceSansBold
menuButton.TextSize = 22
menuButton.AutoButtonColor = true
menuButton.Parent = frame

-- ค่าตัวอย่าง (ไว้สำหรับต่อยอด)
local label = Instance.new("TextLabel")
label.Name = "Title"
label.Text = "นี่คือเมนูหลัก"
label.Size = UDim2.new(1, -20, 0, 30)
label.Position = UDim2.new(0, 10, 0, 40)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.SourceSans
label.Parent = frame

-- ปุ่มทดสอบ (ตัวอย่าง)
local toggle = Instance.new("TextButton")
toggle.Name = "ToggleExample"
toggle.Text = "เปิดใช้งาน"
toggle.Size = UDim2.new(1, -20, 0, 30)
toggle.Position = UDim2.new(0, 10, 0, 80)
toggle.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.SourceSans
toggle.TextSize = 20
toggle.Parent = frame

-- ตัวแปรสถานะ
local isOpen = true
local isDragging = false
local dragStart, startPos

-- พับ/ขยายเมนู
local function toggleMenu()
	if isOpen then
		isOpen = false
		game:GetService("TweenService"):Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
			Size = UDim2.new(0, 120, 0, 50)
		}):Play()
		for _, v in ipairs(frame:GetChildren()) do
			if v ~= menuButton then
				v.Visible = false
			end
		end
	else
		isOpen = true
		game:GetService("TweenService"):Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
			Size = UDim2.new(0, 300, 0, 220)
		}):Play()
		task.wait(0.5)
		for _, v in ipairs(frame:GetChildren()) do
			if v ~= menuButton then
				v.Visible = true
			end
		end
	end
end
menuButton.MouseButton1Click:Connect(toggleMenu)

-- ระบบลากเฉพาะปุ่มเมนู
menuButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		isDragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

menuButton.InputChanged:Connect(function(input)
	if isDragging and input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

menuButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		isDragging = false
	end
end)

-- ทำให้เมนูอยู่ด้านบนเสมอ
frame.ZIndex = 10
menuButton.ZIndex = 11
label.ZIndex = 11
toggle.ZIndex = 11
