--// SpeedMenu v2.0 (Safe GUI Framework)
--// ตัวอย่างโครงสร้างระบบ Speed Menu พร้อม UI และระบบจำค่าคงที่

local plr = game.Players.LocalPlayer
local run = game:GetService("RunService")

--== GUI Setup ==--
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SpeedMenuGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 330)
frame.Position = UDim2.new(0, 50, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

-- หัวข้อ SPEED
local title = Instance.new("TextButton", frame)
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(0,150,255)
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 18
title.Text = "🚀 SPEED"
title.Name = "Title"

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1,0,1,-35)
content.Position = UDim2.new(0,0,0,35)
content.BackgroundTransparency = 1

local visible = true
title.MouseButton1Click:Connect(function()
	visible = not visible
	content.Visible = visible
end)

--== UI Elements ==--
local function createLabel(parent, text)
	local l = Instance.new("TextLabel", parent)
	l.Size = UDim2.new(1, -20, 0, 25)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.TextColor3 = Color3.fromRGB(255,255,255)
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	return l
end

local function createBox(parent, default)
	local b = Instance.new("TextBox", parent)
	b.Size = UDim2.new(0, 100, 0, 25)
	b.Position = UDim2.new(1, -110, 0, 0)
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.Font = Enum.Font.Gotham
	b.TextColor3 = Color3.new(1,1,1)
	b.TextSize = 14
	b.Text = tostring(default or 1)
	return b
end

--== Data ==--
local modes = {
	["เดินเร็ว"] = {"ค่าความเร็ว"},
	["แรงขับเคลื่อน"] = {"ค่าความเร็ว", "แรงขับเคลื่อน"},
	["ขยับตำแหน่ง"] = {"ค่าความเร็ว", "ระยะขยับ", "หน่วงเวลา"},
	["วาร์ป"] = {"ค่าความเร็ว", "ระยะวาร์ป", "หน่วงวาร์ป"},
	["แรงกระแทก"] = {"ค่าความเร็ว", "แรงกระแทก", "หน่วงเวลา"},
	["ดันตัวด้วยแรง"] = {"ค่าความเร็ว", "แรง", "แรงสูงสุด"},
	["ดันตัว (เส้นตรง)"] = {"ค่าความเร็ว", "แรง", "แรงสูงสุด"},
	["ความเร็วฟิสิกส์"] = {"ค่าความเร็ว", "คูณความเร็ว"},
	["เคลื่อนไหวเนียน"] = {"ค่าความเร็ว", "เวลาเคลื่อน", "ระยะ"},
	["เคลื่อนนุ่มนวล"] = {"ค่าความเร็ว", "ค่านุ่มนวล"}
}

local savedValues = {}  -- เก็บค่าที่ตั้งไว้

--== ส่วนเลือกโหมด ==--
local modeLabel = createLabel(content, "โหมด:")
modeLabel.Position = UDim2.new(0,10,0,10)
local modeDropdown = Instance.new("TextButton", content)
modeDropdown.Size = UDim2.new(1, -20, 0, 30)
modeDropdown.Position = UDim2.new(0,10,0,35)
modeDropdown.BackgroundColor3 = Color3.fromRGB(50,50,50)
modeDropdown.TextColor3 = Color3.new(1,1,1)
modeDropdown.Font = Enum.Font.GothamBold
modeDropdown.TextSize = 16
modeDropdown.Text = "เลือกโหมด ▼"

local dropdownFrame = Instance.new("Frame", content)
dropdownFrame.Size = UDim2.new(1, -20, 0, 0)
dropdownFrame.Position = UDim2.new(0,10,0,65)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
dropdownFrame.Visible = false
dropdownFrame.ClipsDescendants = true

--== สร้างตัวเลือกโหมด ==--
local btns = {}
for i, name in ipairs(table.getn and table.getn(modes) or (function()
	local t = {}
	for k,_ in pairs(modes) do table.insert(t,k) end
	return t
end)()) do end

local modeList = {}
for modeName, values in pairs(modes) do
	local b = Instance.new("TextButton", dropdownFrame)
	b.Size = UDim2.new(1,0,0,30)
	b.Position = UDim2.new(0,0,0,#modeList*30)
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.Font = Enum.Font.Gotham
	b.TextColor3 = Color3.new(1,1,1)
	b.Text = modeName
	table.insert(modeList, b)
end
dropdownFrame.Size = UDim2.new(1, -20, 0, #modeList*30)

local currentMode
local fields = {}

local function clearFields()
	for _,v in pairs(fields) do v:Destroy() end
	fields = {}
end

local function createFields(mode)
	clearFields()
	if not modes[mode] then return end
	local y = 100
	for _, labelText in ipairs(modes[mode]) do
		local l = createLabel(content, labelText..":")
		l.Position = UDim2.new(0,10,0,y)
		local defaultVal = savedValues[mode] and savedValues[mode][labelText] or 1
		local b = createBox(l, defaultVal)
		fields[#fields+1] = l
		b.FocusLost:Connect(function()
			local num = tonumber(b.Text) or 1
			savedValues[mode] = savedValues[mode] or {}
			savedValues[mode][labelText] = num
		end)
		y = y + 30
	end
end

modeDropdown.MouseButton1Click:Connect(function()
	dropdownFrame.Visible = not dropdownFrame.Visible
end)

for _,b in ipairs(modeList) do
	b.MouseButton1Click:Connect(function()
		modeDropdown.Text = b.Text.." ▼"
		currentMode = b.Text
		dropdownFrame.Visible = false
		createFields(currentMode)
	end)
end

--== ปุ่มเปิด/ปิด ==--
local toggleBtn = Instance.new("TextButton", content)
toggleBtn.Size = UDim2.new(1, -20, 0, 35)
toggleBtn.Position = UDim2.new(0,10,1,-45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
toggleBtn.Text = "เริ่มทำงาน ▶️"

local active = false
local activeMode

local function stopAllModes()
	activeMode = nil
end

toggleBtn.MouseButton1Click:Connect(function()
	active = not active
	if active then
		toggleBtn.Text = "หยุดทำงาน ⏹️"
		if currentMode then
			stopAllModes()
			activeMode = currentMode
			-- ตรงนี้คือจุดที่คุณสามารถใส่ฟังก์ชันการเคลื่อนไหวจริง ๆ ได้ภายหลัง
			print("เริ่มโหมด:", currentMode, savedValues[currentMode])
		end
	else
		toggleBtn.Text = "เริ่มทำงาน ▶️"
		stopAllModes()
	end
end)
