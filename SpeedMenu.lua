--// SpeedMenu_Core5.lua
--// สคริปต์เมนู SPEED (เวอร์ชันนิ่งสุด)
--// เหลือเฉพาะโหมด: WalkSpeed, Velocity, TP, CFrame, Impulse

-- [บริการหลัก]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

-- [ค่าหลัก]
local currentMode = nil
local active = false
local speedMultiplier = 1
local tpDistance = 10
local tpDelay = 0.2

-- [UI หลัก]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "SpeedMenu"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0.5, -100, 0.5, -125)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true
Frame.Visible = true

-- หัวข้อ SPEED
local Header = Instance.new("TextButton", Frame)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Header.Text = "⚡ SPEED MENU"
Header.TextColor3 = Color3.new(1, 1, 1)
Header.TextScaled = true

-- ปุ่มพับเมนู
local isFolded = false
Header.MouseButton1Click:Connect(function()
	isFolded = not isFolded
	for _, child in pairs(Frame:GetChildren()) do
		if child ~= Header then
			child.Visible = not isFolded
		end
	end
	Frame.Size = isFolded and UDim2.new(0, 200, 0, 30) or UDim2.new(0, 200, 0, 250)
end)

-- ปุ่มเปิด/ปิดการทำงาน
local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Size = UDim2.new(1, -10, 0, 30)
ToggleBtn.Position = UDim2.new(0, 5, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Text = "🔘 ปิดการทำงาน"

ToggleBtn.MouseButton1Click:Connect(function()
	active = not active
	ToggleBtn.Text = active and "🟢 เปิดใช้งาน" or "🔘 ปิดการทำงาน"
end)

-- ช่องค่าความเร็ว
local SpeedLabel = Instance.new("TextLabel", Frame)
SpeedLabel.Size = UDim2.new(1, -10, 0, 20)
SpeedLabel.Position = UDim2.new(0, 5, 0, 80)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "ค่าความเร็ว (x)"
SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedLabel.TextScaled = true

local SpeedBox = Instance.new("TextBox", Frame)
SpeedBox.Size = UDim2.new(1, -10, 0, 25)
SpeedBox.Position = UDim2.new(0, 5, 0, 105)
SpeedBox.Text = tostring(speedMultiplier)
SpeedBox.TextColor3 = Color3.new(1, 1, 1)
SpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedBox.ClearTextOnFocus = false
SpeedBox.TextScaled = true

SpeedBox.FocusLost:Connect(function()
	local val = tonumber(SpeedBox.Text)
	if val and val > 0 then
		speedMultiplier = val
	end
end)

-- ช่องเฉพาะ TP
local TpDistLabel = Instance.new("TextLabel", Frame)
TpDistLabel.Size = UDim2.new(1, -10, 0, 20)
TpDistLabel.Position = UDim2.new(0, 5, 0, 140)
TpDistLabel.BackgroundTransparency = 1
TpDistLabel.Text = "ระยะวาร์ป"
TpDistLabel.TextColor3 = Color3.new(1, 1, 1)
TpDistLabel.TextScaled = true

local TpDistBox = Instance.new("TextBox", Frame)
TpDistBox.Size = UDim2.new(1, -10, 0, 25)
TpDistBox.Position = UDim2.new(0, 5, 0, 165)
TpDistBox.Text = tostring(tpDistance)
TpDistBox.TextColor3 = Color3.new(1, 1, 1)
TpDistBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TpDistBox.ClearTextOnFocus = false
TpDistBox.TextScaled = true

TpDistBox.FocusLost:Connect(function()
	local val = tonumber(TpDistBox.Text)
	if val then tpDistance = val end
end)

local TpDelayLabel = Instance.new("TextLabel", Frame)
TpDelayLabel.Size = UDim2.new(1, -10, 0, 20)
TpDelayLabel.Position = UDim2.new(0, 5, 0, 195)
TpDelayLabel.BackgroundTransparency = 1
TpDelayLabel.Text = "หน่วงวาร์ป (วินาที)"
TpDelayLabel.TextColor3 = Color3.new(1, 1, 1)
TpDelayLabel.TextScaled = true

local TpDelayBox = Instance.new("TextBox", Frame)
TpDelayBox.Size = UDim2.new(1, -10, 0, 25)
TpDelayBox.Position = UDim2.new(0, 5, 0, 220)
TpDelayBox.Text = tostring(tpDelay)
TpDelayBox.TextColor3 = Color3.new(1, 1, 1)
TpDelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TpDelayBox.ClearTextOnFocus = false
TpDelayBox.TextScaled = true

TpDelayBox.FocusLost:Connect(function()
	local val = tonumber(TpDelayBox.Text)
	if val then tpDelay = val end
end)

-- [ระบบเลือกโหมด]
local modes = {"WalkSpeed", "Velocity", "TP", "CFrame", "Impulse"}
local ModeIndex = 1

local ModeBtn = Instance.new("TextButton", Frame)
ModeBtn.Size = UDim2.new(1, -10, 0, 30)
ModeBtn.Position = UDim2.new(0, 5, 0, 255)
ModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ModeBtn.TextColor3 = Color3.new(1, 1, 1)
ModeBtn.Text = "โหมด: WalkSpeed"

ModeBtn.MouseButton1Click:Connect(function()
	ModeIndex = ModeIndex + 1
	if ModeIndex > #modes then ModeIndex = 1 end
	currentMode = modes[ModeIndex]
	ModeBtn.Text = "โหมด: " .. currentMode
end)

-- [ระบบการทำงานหลัก]
RunService.Heartbeat:Connect(function()
	if not active or not currentMode then return end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	hrp = player.Character:FindFirstChild("HumanoidRootPart")
	hum = player.Character:FindFirstChildOfClass("Humanoid")

	if currentMode == "WalkSpeed" then
		hum.WalkSpeed = 16 * speedMultiplier

	elseif currentMode == "Velocity" then
		local bv = hrp:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity", hrp)
		bv.MaxForce = Vector3.new(4000, 4000, 4000)
		bv.Velocity = hrp.CFrame.LookVector * (50 * speedMultiplier)

	elseif currentMode == "TP" then
		wait(tpDelay)
		hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * tpDistance * speedMultiplier

	elseif currentMode == "CFrame" then
		hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * (speedMultiplier / 2)

	elseif currentMode == "Impulse" then
		hrp:ApplyImpulse(hrp.CFrame.LookVector * 50 * speedMultiplier)
	end
end)
