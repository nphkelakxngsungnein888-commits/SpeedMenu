local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local runService = game:GetService("RunService")

local lockEnabled = true
local lockedTarget = nil
local circleSize = 220
local lockStrength = 0.12
local scriptEnabled = true

--================ GUI =================

local gui = Instance.new("ScreenGui", player.PlayerGui)

-- ปุ่มเปิด/ปิดล็อค
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0,130,0,45)
toggle.Position = UDim2.new(0,20,0,200)
toggle.Text = "LOCK : ON"
toggle.Parent = gui

-- ปุ่มปิดสคริปต์ทั้งหมด
local delete = Instance.new("TextButton")
delete.Size = UDim2.new(0,130,0,45)
delete.Position = UDim2.new(0,20,0,250)
delete.Text = "CLOSE SCRIPT"
delete.Parent = gui

-- ช่องปรับขนาดวง
local sizeBox = Instance.new("TextBox")
sizeBox.Size = UDim2.new(0,130,0,40)
sizeBox.Position = UDim2.new(0,20,0,300)
sizeBox.Text = "220"
sizeBox.Parent = gui

-- เส้นวงโปร่ง (ไม่มีพื้น)
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0,circleSize,0,circleSize)
circle.Position = UDim2.new(0.5,-circleSize/2,0.5,-circleSize/2)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 3
circle.BorderColor3 = Color3.fromRGB(255,255,255)
circle.Parent = gui

-- ทำให้เป็นวงจริง
local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(1,0)
uicorner.Parent = circle

--================ ปุ่มเปิดปิด =================

toggle.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	
	if lockEnabled then
		toggle.Text = "LOCK : ON"
	else
		toggle.Text = "LOCK : OFF"
		lockedTarget = nil
	end
end)

-- ปิดสคริปต์ทั้งหมด
delete.MouseButton1Click:Connect(function()
	scriptEnabled = false
	gui:Destroy()
end)

-- ปรับขนาดวง
sizeBox.FocusLost:Connect(function()
	local num = tonumber(sizeBox.Text)
	if num then
		circleSize = num
		circle.Size = UDim2.new(0,circleSize,0,circleSize)
		circle.Position = UDim2.new(0.5,-circleSize/2,0.5,-circleSize/2)
	end
end)

--================ หาเป้า =================

local function getTarget()
	local closest = nil
	local shortest = math.huge

	for _,v in pairs(workspace:GetChildren()) do
		if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= char then
			
			local pos, visible = camera:WorldToViewportPoint(v.HumanoidRootPart.Position)

			if visible then
				local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
				local targetPos = Vector2.new(pos.X,pos.Y)
				
				local dist = (center - targetPos).Magnitude
				
				if dist < circleSize/2 then
					if dist < shortest then
						shortest = dist
						closest = v
					end
				end
			end
		end
	end
	
	return closest
end

--================ ล็อคแบบไม่หลุด =================

runService.RenderStepped:Connect(function()
	if not scriptEnabled then return end
	if not lockEnabled then return end

	local newTarget = getTarget()
	if newTarget then
		lockedTarget = newTarget
	end

	if lockedTarget and lockedTarget:FindFirstChild("HumanoidRootPart") then
		
		local targetPos = lockedTarget.HumanoidRootPart.Position
		
		-- หมุนตัวแบบนุ่ม
		local look = CFrame.lookAt(root.Position, targetPos)
		root.CFrame = root.CFrame:Lerp(look, lockStrength)

		-- หมุนกล้องแบบไม่หลุด
		local camLook = CFrame.lookAt(camera.CFrame.Position, targetPos)
		camera.CFrame = camera.CFrame:Lerp(camLook, lockStrength)
	end
end)
