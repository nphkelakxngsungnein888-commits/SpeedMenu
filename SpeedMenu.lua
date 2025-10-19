--// UI ตัวกระจาย (ไม่มีฟังก์ชันอื่น)
--// รองรับมือถือ / ลากได้ / พับเก็บได้

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BreakUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 300)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- หัวข้อเมนู (สีฟ้า)
local Header = Instance.new("TextButton")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Header.Text = "เมนู"
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.Font = Enum.Font.SourceSansBold
Header.TextSize = 24
Header.Parent = MainFrame

-- ปุ่มเปิดใช้งาน
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 100, 0, 30)
ToggleButton.Position = UDim2.new(0.5, -50, 0, 50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
ToggleButton.Text = "เปิดใช้งาน"
ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 20
ToggleButton.Parent = MainFrame

-- ป้ายชื่อหลัก
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 90)
Title.BackgroundTransparency = 1
Title.Text = "ตัวกระจาย"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 24
Title.Parent = MainFrame

-- ฟังก์ชันสร้างช่องกรอกค่า
local function CreateSetting(name, yPos)
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.5, -10, 0, 25)
	Label.Position = UDim2.new(0, 10, 0, yPos)
	Label.BackgroundTransparency = 1
	Label.Text = name
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.Font = Enum.Font.SourceSans
	Label.TextSize = 20
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = MainFrame

	local Box = Instance.new("TextBox")
	Box.Size = UDim2.new(0.4, 0, 0, 25)
	Box.Position = UDim2.new(0.55, 0, 0, yPos)
	Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Box.Text = "1"
	Box.TextColor3 = Color3.fromRGB(255, 255, 255)
	Box.Font = Enum.Font.SourceSans
	Box.TextSize = 18
	Box.Parent = MainFrame
end

CreateSetting("แรงกระเด้ง", 140)
CreateSetting("ความกว้าง", 180)
CreateSetting("ความเร็ว", 220)

-- ฟังก์ชันพับเมนู
local folded = false
Header.MouseButton1Click:Connect(function()
	folded = not folded
	for _, obj in ipairs(MainFrame:GetChildren()) do
		if obj ~= Header then
			obj.Visible = not folded
		end
	end
end)
