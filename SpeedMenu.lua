--// 🌊 Speed Menu System v1.1
--// Dropdown ∆ เลือกโหมด / พับได้ / ควบคุมด้วยจอย / ความเร็วคูณทุกโหมด

local plr = game.Players.LocalPlayer
local run = game:GetService("RunService")

--== Character Setup ==--
local char, hrp, hum
local function setupChar()
	char = plr.Character or plr.CharacterAdded:Wait()
	hrp = char:WaitForChild("HumanoidRootPart")
	hum = char:WaitForChild("Humanoid")
end
setupChar()
plr.CharacterAdded:Connect(setupChar)

--== GUI ==--
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SpeedMenu"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 220)
frame.Position = UDim2.new(0, 50, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

-- หัวข้อ (สีฟ้า)
local header = Instance.new("TextButton", frame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
header.Text = "🌊 เมนูสปีด"
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.GothamBold
header.TextSize = 18

-- ปุ่มพับเมนู
local menuVisible = true
header.MouseButton1Click:Connect(function()
	menuVisible = not menuVisible
	for _, v in pairs(frame:GetChildren()) do
		if v ~= header then v.Visible = menuVisible end
	end
	frame.Size = menuVisible and UDim2.new(0, 240, 0, 220) or UDim2.new(0, 240, 0, 40)
end)

--== โหมดต่าง ๆ ==--
local modes = {"Velocity", "TP", "CFrame", "WalkSpeed", "Impulse"}
local currentMode = "Velocity"

local modeLabel = Instance.new("TextLabel", frame)
modeLabel.Size = UDim2.new(1, -50, 0, 30)
modeLabel.Position = UDim2.new(0, 5, 0, 50)
modeLabel.BackgroundTransparency = 1
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 16
modeLabel.Text = "โหมด: " .. currentMode

local changeBtn = Instance.new("TextButton", frame)
changeBtn.Size = UDim2.new(0, 40, 0, 30)
changeBtn.Position = UDim2.new(1, -45, 0, 50)
changeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
changeBtn.Text = "∆"
changeBtn.TextColor3 = Color3.new(1,1,1)
changeBtn.Font = Enum.Font.GothamBold
changeBtn.TextSize = 18

--== เมนู Dropdown ==--
local dropdownFrame = Instance.new("Frame", frame)
dropdownFrame.Size = UDim2.new(0, 180, 0, 0)
dropdownFrame.Position = UDim2.new(0, 30, 0, 85)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.Visible = false
dropdownFrame.ClipsDescendants = true

local function openDropdown()
	dropdownFrame.Visible = true
	dropdownFrame:TweenSize(UDim2.new(0, 180, 0, #modes * 25), "Out", "Quad", 0.2, true)
end

local function closeDropdown()
	dropdownFrame:TweenSize(UDim2.new(0, 180, 0, 0), "Out", "Quad", 0.2, true)
	task.wait(0.2)
	dropdownFrame.Visible = false
end

for i, name in ipairs(modes) do
	local opt = Instance.new("TextButton", dropdownFrame)
	opt.Size = UDim2.new(1, 0, 0, 25)
	opt.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
	opt.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	opt.TextColor3 = Color3.new(1, 1, 1)
	opt.Text = name
	opt.Font = Enum.Font.Gotham
	opt.TextSize = 14

	opt.MouseButton1Click:Connect(function()
		currentMode = name
		modeLabel.Text = "โหมด: " .. currentMode
		closeDropdown()
	end)
end

changeBtn.MouseButton1Click:Connect(function()
	if dropdownFrame.Visible then
		closeDropdown()
	else
		openDropdown()
	end
end)

--== ช่องปรับค่า ==--
local function makeLabel(text, y)
	local t = Instance.new("TextLabel", frame)
	t.Size = UDim2.new(0, 100, 0, 30)
	t.Position = UDim2.new(0, 10, 0, y)
	t.BackgroundTransparency = 1
	t.TextColor3 = Color3.new(1,1,1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 14
	t.Text = text
	return t
end

local function makeBox(default, y)
	local b = Instance.new("TextBox", frame)
	b.Size = UDim2.new(0, 100, 0, 25)
	b.Position = UDim2.new(0, 130, 0, y)
	b.BackgroundColor3 = Color3.fromRGB(40,40,40)
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.Text = tostring(default)
	return b
end

local labels = {}
local boxes = {}

-- ความเร็วคูณ (ใช้ได้ทุกโหมด)
labels.speed = makeLabel("ความเร็วคูณ", 120)
boxes.speed = makeBox(1, 120)

-- เฉพาะ TP
labels.tpDist = makeLabel("ระยะวาร์ป", 160)
boxes.tpDist = makeBox(10, 160)
labels.tpDelay = makeLabel("หน่วงวาร์ป", 190)
boxes.tpDelay = makeBox(0.2, 190)

local function updateFields()
	for _, v in pairs(labels) do v.Visible = false end
	for _, v in pairs(boxes) do v.Visible = false end
	labels.speed.Visible = true
	boxes.speed.Visible = true
	if currentMode == "TP" then
		labels.tpDist.Visible = true
		boxes.tpDist.Visible = true
		labels.tpDelay.Visible = true
		boxes.tpDelay.Visible = true
	end
end
updateFields()

-- อัปเดตเมื่อเปลี่ยนโหมด
for _, opt in ipairs(dropdownFrame:GetChildren()) do
	if opt:IsA("TextButton") then
		opt.MouseButton1Click:Connect(updateFields)
	end
end

--== ระบบเคลื่อนที่ ==--
local active = true
run.RenderStepped:Connect(function()
	if not active or not hrp or not hum then return end
	local moveDir = hum.MoveDirection
	if moveDir.Magnitude > 0 then
		local spd = tonumber(boxes.speed.Text) or 1
		if currentMode == "Velocity" then
			hrp.Velocity = moveDir * 50 * spd
		elseif currentMode == "TP" then
			local dist = tonumber(boxes.tpDist.Text) or 10
			local delay = tonumber(boxes.tpDelay.Text) or 0.2
			hrp.CFrame = hrp.CFrame + moveDir * dist * spd
			task.wait(delay)
		elseif currentMode == "CFrame" then
			hrp.CFrame = hrp.CFrame + moveDir * 3 * spd
		elseif currentMode == "WalkSpeed" then
			hum.WalkSpeed = 16 * spd
		elseif currentMode == "Impulse" then
			hrp:ApplyImpulse(moveDir * 150 * spd)
		end
	end
end)
