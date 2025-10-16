--// 🌊 Simpl Speed Menu System – Mobile Ready + Ground Stick + Multi Mode (v1.0)
-- รองรับมือถือ, พับเก็บได้, ใช้งานจริงทุกโหมด

local plr = game.Players.LocalPlayer
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")

--==[ Character Setup ]==--
local char, hrp, hum
local function setupChar()
	char = plr.Character or plr.CharacterAdded:Wait()
	hrp = char:WaitForChild("HumanoidRootPart")
	hum = char:WaitForChild("Humanoid")
end
setupChar()
plr.CharacterAdded:Connect(setupChar)

--==[ Variables ]==--
local activeMode = "Velocity"
local baseSpeed = 1
local modes = {"Velocity", "TP", "CFrame", "WalkSpeed", "Impulse"}
local menuOpen = false
local moveInput = Vector3.zero
local tpCooldown = 0

--==[ UI Setup ]==--
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SpeedMenu"

-- ปุ่มเปิดเมนู (∆)
local openBtn = Instance.new("TextButton", gui)
openBtn.Size = UDim2.new(0, 40, 0, 40)
openBtn.Position = UDim2.new(0.5, -20, 1, -60)
openBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
openBtn.Text = "∆"
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 26

-- เฟรมเมนู
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 300)
frame.Position = UDim2.new(0.5, -130, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Visible = false
frame.Active = true
frame.Draggable = true

-- หัวข้อ
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
title.Text = "⚙️ เมนูสปีด"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20

-- ช่องเลือกโหมด
local modeLabel = Instance.new("TextLabel", frame)
modeLabel.Size = UDim2.new(1, -20, 0, 30)
modeLabel.Position = UDim2.new(0, 10, 0, 50)
modeLabel.Text = "โหมด: Velocity"
modeLabel.BackgroundTransparency = 1
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 18

-- ปุ่มเลื่อนโหมด
local nextBtn = Instance.new("TextButton", frame)
nextBtn.Size = UDim2.new(0, 60, 0, 30)
nextBtn.Position = UDim2.new(1, -70, 0, 50)
nextBtn.Text = "➡️"
nextBtn.Font = Enum.Font.GothamBold
nextBtn.TextSize = 16
nextBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
nextBtn.TextColor3 = Color3.new(1,1,1)

-- ค่าปรับหลัก (ความเร็วรวม)
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(1, -20, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 100)
speedLabel.Text = "ความเร็ว (คูณ):"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 16

local speedBox = Instance.new("TextBox", frame)
speedBox.Size = UDim2.new(0, 100, 0, 30)
speedBox.Position = UDim2.new(0, 140, 0, 100)
speedBox.Text = tostring(baseSpeed)
speedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 16

-- ค่าเฉพาะของแต่ละโหมด
local tpLabel = Instance.new("TextLabel", frame)
tpLabel.Size = UDim2.new(1, -20, 0, 30)
tpLabel.Position = UDim2.new(0, 10, 0, 140)
tpLabel.BackgroundTransparency = 1
tpLabel.TextColor3 = Color3.new(1,1,1)
tpLabel.Font = Enum.Font.Gotham
tpLabel.TextSize = 16
tpLabel.Text = "ระยะวาป (สตูด):"

local tpBox = Instance.new("TextBox", frame)
tpBox.Size = UDim2.new(0, 100, 0, 30)
tpBox.Position = UDim2.new(0, 140, 0, 140)
tpBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
tpBox.TextColor3 = Color3.new(1,1,1)
tpBox.Font = Enum.Font.GothamBold
tpBox.TextSize = 16
tpBox.Text = "10"

-- ปุ่มปิดเมนู
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(1, -20, 0, 40)
closeBtn.Position = UDim2.new(0, 10, 1, -50)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
closeBtn.Text = "ปิดเมนู"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.new(1,1,1)

--==[ UI Actions ]==--
openBtn.MouseButton1Click:Connect(function()
	menuOpen = not menuOpen
	frame.Visible = menuOpen
end)

closeBtn.MouseButton1Click:Connect(function()
	menuOpen = false
	frame.Visible = false
end)

-- เลือกโหมด
nextBtn.MouseButton1Click:Connect(function()
	local idx = table.find(modes, activeMode)
	activeMode = modes[(idx % #modes) + 1]
	modeLabel.Text = "โหมด: " .. activeMode
	-- แสดงค่าของโหมด TP เท่านั้น
	local isTP = (activeMode == "TP")
	tpLabel.Visible = isTP
	tpBox.Visible = isTP
end)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n and n > 0 then baseSpeed = n end
end)

tpBox.FocusLost:Connect(function()
	local n = tonumber(tpBox.Text)
	if n then tpRange = n end
end)

--==[ Movement Control ]==--
uis.InputChanged:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.Thumbstick1 then
		moveInput = Vector3.new(i.Position.X, 0, -i.Position.Y)
	end
end)

--==[ Mode Functions ]==--
run.RenderStepped:Connect(function(dt)
	if not char or not hrp or not hum then return end
	if moveInput.Magnitude < 0.1 then return end

	local dir = (workspace.CurrentCamera.CFrame:VectorToWorldSpace(moveInput)).Unit
	local speed = baseSpeed * 16

	if activeMode == "WalkSpeed" then
		hum.WalkSpeed = speed

	elseif activeMode == "Velocity" then
		local vel = dir * speed
		hrp.Velocity = Vector3.new(vel.X, hrp.Velocity.Y, vel.Z)

	elseif activeMode == "CFrame" then
		hrp.CFrame = hrp.CFrame + dir * dt * speed
		local ray = Ray.new(hrp.Position, Vector3.new(0, -5, 0))
		local hit, pos = workspace:FindPartOnRay(ray, char)
		if hit then hrp.Position = Vector3.new(hrp.Position.X, pos.Y + 2.8, hrp.Position.Z) end

	elseif activeMode == "Impulse" then
		hrp:ApplyImpulse(dir * 1000 * baseSpeed)

	elseif activeMode == "TP" then
		if tick() > tpCooldown then
			hrp.CFrame = hrp.CFrame + dir * tonumber(tpBox.Text)
			tpCooldown = tick() + 0.3
		end
	end
end)
