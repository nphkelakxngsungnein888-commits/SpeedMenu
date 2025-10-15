--// Speed Menu System v1.0 🇹🇭
--// เขียนโดยคุณ (และผู้ช่วย GPT 😸)
--// ใช้โหลดผ่านลิงก์: loadstring(game:HttpGet("..."))()

-- ตั้งค่าพื้นฐาน
local plr = game.Players.LocalPlayer
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- GUI หลัก
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "SpeedMenu"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 300)
frame.Position = UDim2.new(0, 50, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextButton", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "💨 Speed Menu (คลิกเพื่อพับ/กาง)"
title.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 15

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1

-- สถานะเมนู
local menuOpen = true
title.MouseButton1Click:Connect(function()
	menuOpen = not menuOpen
	content.Visible = menuOpen
end)

-- สร้างหัวข้อโหมด
local modeLabel = Instance.new("TextLabel", content)
modeLabel.Text = "โหมดการเคลื่อนที่:"
modeLabel.TextColor3 = Color3.fromRGB(255,255,255)
modeLabel.BackgroundTransparency = 1
modeLabel.Size = UDim2.new(1, -20, 0, 25)
modeLabel.Position = UDim2.new(0, 10, 0, 10)
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextSize = 14
modeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ปุ่มเลือกโหมด
local modeBtn = Instance.new("TextButton", content)
modeBtn.Size = UDim2.new(1, -20, 0, 30)
modeBtn.Position = UDim2.new(0, 10, 0, 35)
modeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
modeBtn.TextColor3 = Color3.new(1, 1, 1)
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 14
modeBtn.Text = "Velocity"

-- รายชื่อโหมดทั้งหมด
local modes = {"Velocity","TP","Pulse","CFrame","WalkSpeed","Impulse","Tween","BodyVelocity","AlignPosition","LinearVelocity"}
local currentMode = 1

modeBtn.MouseButton1Click:Connect(function()
	currentMode = currentMode + 1
	if currentMode > #modes then currentMode = 1 end
	modeBtn.Text = modes[currentMode]
end)

-- สไลเดอร์ความเร็ว (ค่า *2, *3, ...)
local speedValue = 1
local speedLabel = Instance.new("TextLabel", content)
speedLabel.Size = UDim2.new(1, -20, 0, 25)
speedLabel.Position = UDim2.new(0, 10, 0, 75)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Text = "ค่าความเร็ว: x" .. speedValue
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedBox = Instance.new("TextBox", content)
speedBox.Size = UDim2.new(1, -20, 0, 30)
speedBox.Position = UDim2.new(0, 10, 0, 100)
speedBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
speedBox.Text = tostring(speedValue)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 14

speedBox.FocusLost:Connect(function()
	local num = tonumber(speedBox.Text)
	if num then
		speedValue = num
		speedLabel.Text = "ค่าความเร็ว: x" .. speedValue
	end
end)

-- ฟังก์ชันทำงานของโหมด
run.RenderStepped:Connect(function()
	if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
	local hrp = plr.Character.HumanoidRootPart
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local moveDir = hum.MoveDirection

	if modes[currentMode] == "WalkSpeed" then
		hum.WalkSpeed = 16 * speedValue
	elseif modes[currentMode] == "Velocity" then
		hrp.Velocity = moveDir * 50 * speedValue
	elseif modes[currentMode] == "TP" then
		if moveDir.Magnitude > 0 then
			hrp.CFrame = hrp.CFrame + moveDir * (speedValue * 2)
		end
	elseif modes[currentMode] == "CFrame" then
		if moveDir.Magnitude > 0 then
			hrp.CFrame = hrp.CFrame + moveDir * (speedValue / 2)
		end
	elseif modes[currentMode] == "Impulse" then
		hrp:ApplyImpulse(moveDir * 100 * speedValue)
	elseif modes[currentMode] == "Tween" then
		local goal = hrp.Position + moveDir * (speedValue * 5)
		game:GetService("TweenService"):Create(hrp, TweenInfo.new(0.1), {CFrame = CFrame.new(goal)}):Play()
	elseif modes[currentMode] == "BodyVelocity" then
		local bv = hrp:FindFirstChildOfClass("BodyVelocity") or Instance.new("BodyVelocity", hrp)
		bv.Velocity = moveDir * 80 * speedValue
	elseif modes[currentMode] == "AlignPosition" then
		local ap = hrp:FindFirstChildOfClass("AlignPosition") or Instance.new("AlignPosition", hrp)
		ap.Position = hrp.Position + moveDir * (speedValue * 5)
	elseif modes[currentMode] == "LinearVelocity" then
		local lv = hrp:FindFirstChildOfClass("LinearVelocity") or Instance.new("LinearVelocity", hrp)
		lv.VectorVelocity = moveDir * 80 * speedValue
	end
end)
