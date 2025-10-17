--// 💥 ตัวแตกกระจาย R15 พร้อมเมนูพับได้ (Mobile Ready)
--// เขียนให้เหมือนสไตล์สคริปต์แรก ใช้งานได้จริง

local plr = game.Players.LocalPlayer
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")

--== GUI Setup ==--
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ExplodeMenu"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 300)
frame.Position = UDim2.new(0, 50, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

-- Title
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Text = "💥 ตัวแตกกระจาย"

-- ปุ่มพับเมนู
local menuBtn = Instance.new("TextButton", frame)
menuBtn.Size = UDim2.new(0, 80, 0, 30)
menuBtn.Position = UDim2.new(0, 10, 0, 260)
menuBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
menuBtn.TextColor3 = Color3.new(1, 1, 1)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 14
menuBtn.Text = "📂 เมนู"

-- ปุ่มเปิดใช้งาน
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0, 200, 0, 40)
toggleBtn.Position = UDim2.new(0, 20, 0, 60)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
toggleBtn.Text = "🔘 เปิดใช้งาน: ปิด"

-- ป้ายชื่อค่าปรับ
local strengthLabel = Instance.new("TextLabel", frame)
strengthLabel.Size = UDim2.new(0, 200, 0, 25)
strengthLabel.Position = UDim2.new(0, 20, 0, 120)
strengthLabel.BackgroundTransparency = 1
strengthLabel.TextColor3 = Color3.new(1, 1, 1)
strengthLabel.Font = Enum.Font.Gotham
strengthLabel.TextSize = 16
strengthLabel.Text = "แรงกระจาย (เท่า):"

-- ช่องกรอกแรง
local strengthBox = Instance.new("TextBox", frame)
strengthBox.Size = UDim2.new(0, 200, 0, 30)
strengthBox.Position = UDim2.new(0, 20, 0, 150)
strengthBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
strengthBox.TextColor3 = Color3.new(1, 1, 1)
strengthBox.Font = Enum.Font.GothamBold
strengthBox.TextSize = 16
strengthBox.Text = "5"

--== พับเมนู ==--
local menuCollapsed = false
menuBtn.MouseButton1Click:Connect(function()
	menuCollapsed = not menuCollapsed
	for _, v in ipairs(frame:GetChildren()) do
		if v ~= title and v ~= menuBtn then
			v.Visible = not menuCollapsed
		end
	end
	frame.Size = menuCollapsed and UDim2.new(0, 240, 0, 50) or UDim2.new(0, 240, 0, 300)
end)

--== ฟังก์ชันหลัก ==--
local active = false
local exploded = false
local connections = {}

local function getCharacter()
	local char = plr.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		char = plr.CharacterAdded:Wait()
	end
	return char
end

local function explodeCharacter(char, force)
	if exploded then return end
	exploded = true

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true
			local bv = Instance.new("BodyVelocity", part)
			bv.Velocity = Vector3.new(math.random(-1, 1), 1, math.random(-1, 1)).Unit * force
			bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
			game.Debris:AddItem(bv, 0.3)
		end
	end
end

local function regroupCharacter(char)
	if not exploded then return end
	exploded = false
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Velocity = Vector3.zero
			part.CFrame = hrp.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
		end
	end
end

local function startListener()
	local char = getCharacter()
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")

	local conn
	conn = run.Heartbeat:Connect(function()
		if not active or not hum or not root then return end
		local moveDir = hum.MoveDirection
		local speed = moveDir.Magnitude
		local force = tonumber(strengthBox.Text) or 5

		if speed > 0 then
			explodeCharacter(char, force * 30)
		else
			regroupCharacter(char)
		end
	end)
	table.insert(connections, conn)
end

toggleBtn.MouseButton1Click:Connect(function()
	active = not active
	toggleBtn.Text = active and "🔘 เปิดใช้งาน: เปิด" or "🔘 เปิดใช้งาน: ปิด"

	if active then
		startListener()
	else
		for _, c in ipairs(connections) do
			c:Disconnect()
		end
		connections = {}
	end
end)

-- ระบบรีเซ็ตเมื่อเกิดใหม่
plr.CharacterAdded:Connect(function()
	if active then
		task.wait(1)
		startListener()
	end
end)
