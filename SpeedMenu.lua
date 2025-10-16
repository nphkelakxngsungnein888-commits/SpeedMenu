--// 🌊 Speed Menu System v1.0
--// รองรับหลายโหมด / พับเมนูได้ / ปรับค่าตามโหมด / ใช้งานผ่านจอย
--// เขียนให้ทำงานเหมือนต้นฉบับ (TAS Style)

local plr = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local run = game:GetService("RunService")

--== Character Handler ==--
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

-- ปุ่มพับ/เปิด
local menuVisible = true
header.MouseButton1Click:Connect(function()
	menuVisible = not menuVisible
	for _, v in pairs(frame:GetChildren()) do
		if v ~= header then v.Visible = menuVisible end
	end
	frame.Size = menuVisible and UDim2.new(0, 240, 0, 220) or UDim2.new(0, 240, 0, 40)
end)

--== ตัวเลือกโหมด ==--
local modes = {"Velocity", "TP", "CFrame", "WalkSpeed", "Impulse"}
local currentMode = 1

local modeLabel = Instance.new("TextLabel", frame)
modeLabel.Size = UDim2.new(1, 0, 0, 30)
modeLabel.Position = UDim2.new(0, 0, 0, 50)
modeLabel.BackgroundTransparency = 1
modeLabel.TextColor3 = Color3.fromRGB(255,255,255)
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 16
modeLabel.Text = "โหมด: " .. modes[currentMode]

-- ปุ่มเปลี่ยนโหมด (∆)
local changeBtn = Instance.new("TextButton", frame)
changeBtn.Size = UDim2.new(0, 40, 0, 30)
changeBtn.Position = UDim2.new(1, -45, 0, 50)
changeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
changeBtn.Text = "∆"
changeBtn.TextColor3 = Color3.new(1,1,1)
changeBtn.Font = Enum.Font.GothamBold
changeBtn.TextSize = 18

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

-- ช่อง “ความเร็วรวม”
labels.speed = makeLabel("ความเร็วคูณ", 90)
boxes.speed = makeBox(1, 90)

-- ช่องเฉพาะของแต่ละโหมด
labels.tpDist = makeLabel("ระยะวาร์ป", 130)
boxes.tpDist = makeBox(10, 130)
labels.tpDelay = makeLabel("หน่วงวาร์ป", 160)
boxes.tpDelay = makeBox(0.2, 160)

for k, v in pairs(labels) do v.Visible = false end
for k, v in pairs(boxes) do v.Visible = false end
labels.speed.Visible = true
boxes.speed.Visible = true

--== ฟังก์ชันอัปเดตโหมด ==--
local function updateMode()
	modeLabel.Text = "โหมด: " .. modes[currentMode]
	for k, v in pairs(labels) do v.Visible = false end
	for k, v in pairs(boxes) do v.Visible = false end
	labels.speed.Visible = true
	boxes.speed.Visible = true
	if modes[currentMode] == "TP" then
		labels.tpDist.Visible = true
		boxes.tpDist.Visible = true
		labels.tpDelay.Visible = true
		boxes.tpDelay.Visible = true
	end
end

changeBtn.MouseButton1Click:Connect(function()
	currentMode = currentMode + 1
	if currentMode > #modes then currentMode = 1 end
	updateMode()
end)
updateMode()

--== การทำงานของโหมด ==--
local active = true
local lastMove = Vector3.zero

run.RenderStepped:Connect(function()
	if not active or not hrp or not hum then return end
	local moveDir = hum.MoveDirection
	if moveDir.Magnitude > 0 then
		local spd = tonumber(boxes.speed.Text) or 1
		local mode = modes[currentMode]

		if mode == "Velocity" then
			hrp.Velocity = moveDir * 50 * spd
		elseif mode == "TP" then
			local dist = tonumber(boxes.tpDist.Text) or 10
			local delay = tonumber(boxes.tpDelay.Text) or 0.2
			hrp.CFrame = hrp.CFrame + moveDir * dist * spd
			task.wait(delay)
		elseif mode == "CFrame" then
			hrp.CFrame = hrp.CFrame + moveDir * 3 * spd
		elseif mode == "WalkSpeed" then
			hum.WalkSpeed = 16 * spd
		elseif mode == "Impulse" then
			hrp:ApplyImpulse(moveDir * 150 * spd)
		end
	end
end)
