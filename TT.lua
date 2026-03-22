local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local lockEnabled = true
local lockedTarget = nil
local circleSize = 220
local lockStrength = 0.12

humanoid.AutoRotate = false

--================ GUI =================

local gui = Instance.new("ScreenGui", player.PlayerGui)

-- ปุ่มเปิด/ปิดล็อค
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0,120,0,45)
toggle.Position = UDim2.new(0,20,0,200)
toggle.Text = "LOCK : ON"
toggle.Parent = gui

-- ปุ่มปิดสคริปต์
local deleteBtn = Instance.new("TextButton")
deleteBtn.Size = UDim2.new(0,120,0,45)
deleteBtn.Position = UDim2.new(0,20,0,250)
deleteBtn.Text = "DELETE SCRIPT"
deleteBtn.Parent = gui

-- ช่องปรับขนาดวง
local sizeBox = Instance.new("TextBox")
sizeBox.Size = UDim2.new(0,120,0,40)
sizeBox.Position = UDim2.new(0,20,0,300)
sizeBox.Text = "220"
sizeBox.Parent = gui

-- วงกลมเส้นรอบวง
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0,circleSize,0,circleSize)
circle.Position = UDim2.new(0.5,-circleSize/2,0.5,-circleSize/2)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 2
circle.BorderColor3 = Color3.new(1,1,1)
circle.Parent = gui

--================ ปุ่มเปิด/ปิด =================

toggle.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	
	if lockEnabled then
		toggle.Text = "LOCK : ON"
	else
		toggle.Text = "LOCK : OFF"
		lockedTarget = nil
	end
end)

--================ ปุ่มลบสคริปต์ =================

deleteBtn.MouseButton1Click:Connect(function()
	lockEnabled = false
	humanoid.AutoRotate = true
	gui:Destroy()
	script:Destroy()
end)

--================ ปรับขนาดวง =================

sizeBox.FocusLost:Connect(function()
	local num = tonumber(sizeBox.Text)
	if num then
		circleSize = num
		circle.Size = UDim2.new(0,circleSize,0,circleSize)
		circle.Position = UDim2.new(0.5,-circleSize/2,0.5,-circleSize/2)
	end
end)

--================ หาเป้าในวง =================

local function getTargetInCircle()
	local closest = nil
	local shortest = math.huge

	for _,v in pairs(workspace:GetDescendants()) do
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

--================ ระบบล็อคแบบไม่หลุด =================

game:GetService("RunService").RenderStepped:Connect(function()

	if lockEnabled then
		
		lockedTarget = getTargetInCircle()

		if lockedTarget and lockedTarget:FindFirstChild("HumanoidRootPart") then
			
			local targetPos = lockedTarget.HumanoidRootPart.Position

			local look = CFrame.lookAt(root.Position, targetPos)
			root.CFrame = root.CFrame:Lerp(look, lockStrength)

			local camLook = CFrame.lookAt(camera.CFrame.Position, targetPos)
			camera.CFrame = camera.CFrame:Lerp(camLook, lockStrength)
			
		end
	end
end)
