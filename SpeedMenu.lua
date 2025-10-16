--// SpeedMenu_v6.lua
--// เวอร์ชันใช้งานจริง พร้อมเพิ่มโหมดในอนาคต
--// ทำโดยคำสั่งของ kuy kuy

--== [บริการหลัก] ==--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local hum = character:WaitForChild("Humanoid")

--== [ค่าหลัก] ==--
local currentMode = "WalkSpeed"
local active = false
local speedMultiplier = 1
local tpDistance = 10
local tpDelay = 0.2

--== [สร้าง UI หลัก] ==--
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "SpeedMenu_v6"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 300)
frame.Position = UDim2.new(0.5, -110, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

-- หัวข้อ SPEED
local header = Instance.new("TextButton", frame)
header.Size = UDim2.new(1, 0, 0, 35)
header.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
header.TextColor3 = Color3.new(1, 1, 1)
header.Text = "⚡ SPEED MENU"
header.TextScaled = true
header.Font = Enum.Font.GothamBold

--== [พับเมนู] ==--
local isFolded = false
header.MouseButton1Click:Connect(function()
	isFolded = not isFolded
	for _, v in pairs(frame:GetChildren()) do
		if v ~= header then v.Visible = not isFolded end
	end
	frame.Size = isFolded and UDim2.new(0, 220, 0, 35) or UDim2.new(0, 220, 0, 300)
end)

--== [ปุ่มเปิด/ปิดระบบ] ==--
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(1, -10, 0, 35)
toggleBtn.Position = UDim2.new(0, 5, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Text = "🔘 ปิดการทำงาน"
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextScaled = true

toggleBtn.MouseButton1Click:Connect(function()
	active = not active
	toggleBtn.Text = active and "🟢 เปิดใช้งาน" or "🔘 ปิดการทำงาน"
end)

--== [ช่องความเร็ว] ==--
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(1, -10, 0, 25)
speedLabel.Position = UDim2.new(0, 5, 0, 90)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "ความเร็ว (x)"
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextScaled = true

local speedBox = Instance.new("TextBox", frame)
speedBox.Size = UDim2.new(1, -10, 0, 30)
speedBox.Position = UDim2.new(0, 5, 0, 115)
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.Text = tostring(speedMultiplier)
speedBox.ClearTextOnFocus = false
speedBox.TextScaled = true

speedBox.FocusLost:Connect(function()
	local val = tonumber(speedBox.Text)
	if val and val > 0 then
		speedMultiplier = val
	else
		speedBox.Text = tostring(speedMultiplier)
	end
end)

--== [ช่องเฉพาะ TP Mode] ==--
local tpDistLabel = Instance.new("TextLabel", frame)
tpDistLabel.Size = UDim2.new(1, -10, 0, 25)
tpDistLabel.Position = UDim2.new(0, 5, 0, 155)
tpDistLabel.BackgroundTransparency = 1
tpDistLabel.Text = "ระยะวาร์ป"
tpDistLabel.TextColor3 = Color3.new(1, 1, 1)
tpDistLabel.Font = Enum.Font.GothamBold
tpDistLabel.TextScaled = true

local tpDistBox = Instance.new("TextBox", frame)
tpDistBox.Size = UDim2.new(1, -10, 0, 30)
tpDistBox.Position = UDim2.new(0, 5, 0, 180)
tpDistBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tpDistBox.TextColor3 = Color3.new(1, 1, 1)
tpDistBox.Text = tostring(tpDistance)
tpDistBox.ClearTextOnFocus = false
tpDistBox.TextScaled = true

tpDistBox.FocusLost:Connect(function()
	local val = tonumber(tpDistBox.Text)
	if val and val > 0 then
		tpDistance = val
	else
		tpDistBox.Text = tostring(tpDistance)
	end
end)

local tpDelayLabel = Instance.new("TextLabel", frame)
tpDelayLabel.Size = UDim2.new(1, -10, 0, 25)
tpDelayLabel.Position = UDim2.new(0, 5, 0, 215)
tpDelayLabel.BackgroundTransparency = 1
tpDelayLabel.Text = "หน่วงวาร์ป (วินาที)"
tpDelayLabel.TextColor3 = Color3.new(1, 1, 1)
tpDelayLabel.Font = Enum.Font.GothamBold
tpDelayLabel.TextScaled = true

local tpDelayBox = Instance.new("TextBox", frame)
tpDelayBox.Size = UDim2.new(1, -10, 0, 30)
tpDelayBox.Position = UDim2.new(0, 5, 0, 240)
tpDelayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tpDelayBox.TextColor3 = Color3.new(1, 1, 1)
tpDelayBox.Text = tostring(tpDelay)
tpDelayBox.ClearTextOnFocus = false
tpDelayBox.TextScaled = true

tpDelayBox.FocusLost:Connect(function()
	local val = tonumber(tpDelayBox.Text)
	if val and val >= 0 then
		tpDelay = val
	else
		tpDelayBox.Text = tostring(tpDelay)
	end
end)

-- ซ่อนไว้ก่อน (แสดงเฉพาะตอนเลือก TP)
tpDistLabel.Visible = false
tpDistBox.Visible = false
tpDelayLabel.Visible = false
tpDelayBox.Visible = false

--== [ปุ่มเลือกโหมด] ==--
local modes = {"WalkSpeed", "Velocity", "TP", "CFrame", "Impulse"}
local modeIndex = 1

local modeBtn = Instance.new("TextButton", frame)
modeBtn.Size = UDim2.new(1, -10, 0, 35)
modeBtn.Position = UDim2.new(0, 5, 0, 275)
modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
modeBtn.TextColor3 = Color3.new(1, 1, 1)
modeBtn.TextScaled = true
modeBtn.Font = Enum.Font.GothamBold
modeBtn.Text = "โหมด: " .. modes[modeIndex]

local function updateVisibleInputs()
	-- ซ่อนทั้งหมดก่อน
	tpDistLabel.Visible = false
	tpDistBox.Visible = false
	tpDelayLabel.Visible = false
	tpDelayBox.Visible = false

	-- แสดงเฉพาะโหมด TP
	if currentMode == "TP" then
		tpDistLabel.Visible = true
		tpDistBox.Visible = true
		tpDelayLabel.Visible = true
		tpDelayBox.Visible = true
	end
end

modeBtn.MouseButton1Click:Connect(function()
	modeIndex += 1
	if modeIndex > #modes then modeIndex = 1 end
	currentMode = modes[modeIndex]
	modeBtn.Text = "โหมด: " .. currentMode
	updateVisibleInputs()
end)

--== [ระบบการทำงานจริง] ==--
RunService.Heartbeat:Connect(function()
	if not active then return end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	character = player.Character
	hrp = character:FindFirstChild("HumanoidRootPart")
	hum = character:FindFirstChildOfClass("Humanoid")

	if currentMode == "WalkSpeed" then
		hum.WalkSpeed = 16 * speedMultiplier

	elseif currentMode == "Velocity" then
		local bv = hrp:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity", hrp)
		bv.MaxForce = Vector3.new(4000, 4000, 4000)
		bv.Velocity = hrp.CFrame.LookVector * (50 * speedMultiplier)

	elseif currentMode == "TP" then
		task.wait(tpDelay)
		hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * (tpDistance * speedMultiplier)

	elseif currentMode == "CFrame" then
		hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * (speedMultiplier / 2)

	elseif currentMode == "Impulse" then
		hrp:ApplyImpulse(hrp.CFrame.LookVector * 50 * speedMultiplier)
	end
end)
