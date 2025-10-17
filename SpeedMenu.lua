-- ScatterUI.lua
if getgenv().ScatterUI then
	getgenv().ScatterUI:Destroy()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- สร้าง UI หลัก
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScatterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ปุ่มเปิด/ปิด ∆
local ToggleButton = Instance.new("TextButton")
ToggleButton.Text = "∆"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextScaled = true
ToggleButton.Parent = ScreenGui

-- กล่องเมนู
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 200)
Frame.Position = UDim2.new(0, 80, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Frame.Visible = false
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

-- หัวข้อ
local Title = Instance.new("TextLabel")
Title.Text = "⚡ ระบบแตกกระจาย"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextScaled = true
Title.Parent = Frame

-- ปุ่มเปิด/ปิดการทำงาน
local Toggle = Instance.new("TextButton")
Toggle.Text = "ปิดการทำงาน"
Toggle.Size = UDim2.new(0.9, 0, 0, 40)
Toggle.Position = UDim2.new(0.05, 0, 0, 50)
Toggle.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Font = Enum.Font.SourceSansBold
Toggle.TextScaled = true
Toggle.Parent = Frame

-- ช่องกรอกค่าแรงกระจาย
local PowerLabel = Instance.new("TextLabel")
PowerLabel.Text = "แรงกระจาย:"
PowerLabel.Size = UDim2.new(0.5, 0, 0, 30)
PowerLabel.Position = UDim2.new(0.05, 0, 0, 110)
PowerLabel.BackgroundTransparency = 1
PowerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PowerLabel.Font = Enum.Font.SourceSans
PowerLabel.TextScaled = true
PowerLabel.Parent = Frame

local PowerBox = Instance.new("TextBox")
PowerBox.Text = "5"
PowerBox.Size = UDim2.new(0.35, 0, 0, 30)
PowerBox.Position = UDim2.new(0.6, 0, 0, 110)
PowerBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PowerBox.TextColor3 = Color3.fromRGB(0, 0, 0)
PowerBox.Font = Enum.Font.SourceSans
PowerBox.TextScaled = true
PowerBox.Parent = Frame

-- สถานะ
local Active = false

-- เปิด/ปิดเมนู
ToggleButton.MouseButton1Click:Connect(function()
	Frame.Visible = not Frame.Visible
end)

-- เปิด/ปิดระบบ
Toggle.MouseButton1Click:Connect(function()
	Active = not Active
	Toggle.Text = Active and "เปิดการทำงาน" or "ปิดการทำงาน"
	Toggle.BackgroundColor3 = Active and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(100, 100, 255)
end)

-- ฟังก์ชันแตกกระจาย
local function Scatter()
	if not Active then return end
	local power = tonumber(PowerBox.Text) or 5

	for _, part in ipairs(Character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Anchored = false
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(math.random(-power, power), math.random(3, power*2), math.random(-power, power))
			bv.MaxForce = Vector3.new(4000, 4000, 4000)
			bv.Parent = part
			game:GetService("Debris"):AddItem(bv, 0.2)
		end
	end
end

-- ฟังก์ชันดูดกลับ
local function Reassemble()
	if not Active then return end
	for _, part in ipairs(Character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local tween = TweenService:Create(part, TweenInfo.new(0.5), {CFrame = Character.HumanoidRootPart.CFrame})
			tween:Play()
		end
	end
end

-- ตรวจจับการเดิน
local moving = false
Humanoid.Running:Connect(function(speed)
	if speed > 1 then
		if not moving then
			moving = true
			Scatter()
		end
	else
		if moving then
			moving = false
			Reassemble()
		end
	end
end)

getgenv().ScatterUI = ScreenGui
