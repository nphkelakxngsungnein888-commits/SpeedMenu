-- ScatterUI.lua (mobile fixed)
if getgenv().ScatterUI then
	getgenv().ScatterUI:Destroy()
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- สร้าง GUI หลัก
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScatterUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ปุ่มเปิด/ปิด
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ToggleButton.Text = "∆"
ToggleButton.TextScaled = true
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.ZIndex = 10
ToggleButton.Parent = ScreenGui

-- กรอบเมนูหลัก
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 260, 0, 220)
Frame.Position = UDim2.new(0, 80, 0.5, -110)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,35)
Frame.BorderSizePixel = 0
Frame.Visible = false
Frame.Active = true
Frame.Draggable = true
Frame.ZIndex = 10
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke", Frame)
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(0, 200, 255)

-- หัวข้อ
local Title = Instance.new("TextLabel")
Title.Text = "ตัวกระจาย"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(0,170,255)
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextScaled = true
Title.ZIndex = 11
Title.Parent = Frame

-- ปุ่มเปิดปิดระบบ
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(0.9, 0, 0, 40)
Toggle.Position = UDim2.new(0.05, 0, 0, 50)
Toggle.BackgroundColor3 = Color3.fromRGB(255,100,100)
Toggle.Text = "ปิดการทำงาน"
Toggle.TextColor3 = Color3.new(1,1,1)
Toggle.Font = Enum.Font.SourceSansBold
Toggle.TextScaled = true
Toggle.ZIndex = 11
Toggle.Parent = Frame

-- แรงกระจาย
local PowerLabel = Instance.new("TextLabel")
PowerLabel.Text = "แรงกระจาย"
PowerLabel.Size = UDim2.new(0.4, 0, 0, 30)
PowerLabel.Position = UDim2.new(0.05, 0, 0, 110)
PowerLabel.BackgroundTransparency = 1
PowerLabel.TextColor3 = Color3.new(1,1,1)
PowerLabel.Font = Enum.Font.SourceSansBold
PowerLabel.TextScaled = true
PowerLabel.ZIndex = 11
PowerLabel.Parent = Frame

local PowerBox = Instance.new("TextBox")
PowerBox.Text = "5"
PowerBox.Size = UDim2.new(0.4, 0, 0, 30)
PowerBox.Position = UDim2.new(0.55, 0, 0, 110)
PowerBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
PowerBox.TextColor3 = Color3.new(0,0,0)
PowerBox.Font = Enum.Font.SourceSans
PowerBox.TextScaled = true
PowerBox.ZIndex = 11
PowerBox.Parent = Frame

-- สถานะระบบ
local Active = false

ToggleButton.MouseButton1Click:Connect(function()
	Frame.Visible = not Frame.Visible
end)

Toggle.MouseButton1Click:Connect(function()
	Active = not Active
	Toggle.Text = Active and "เปิดการทำงาน" or "ปิดการทำงาน"
	Toggle.BackgroundColor3 = Active and Color3.fromRGB(0,255,120) or Color3.fromRGB(255,100,100)
end)

-- ฟังก์ชันกระจาย
local function Scatter()
	if not Active then return end
	local power = tonumber(PowerBox.Text) or 5
	for _, part in ipairs(Character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Anchored = false
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(math.random(-power,power), math.random(3,power*2), math.random(-power,power))
			bv.MaxForce = Vector3.new(4000,4000,4000)
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
			local tween = TweenService:Create(part, TweenInfo.new(0.4), {CFrame = Character.HumanoidRootPart.CFrame})
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
