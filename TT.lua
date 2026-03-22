local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

local lockedTarget = nil
local lockEnabled = true
local circleSize = 200

--================ GUI =================

local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "LockSystem"

-- ปุ่มเปิดปิด
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0,120,0,45)
toggle.Position = UDim2.new(0,20,0,200)
toggle.Text = "LOCK : ON"
toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Parent = gui

-- ช่องปรับขนาดวง
local sizeBox = Instance.new("TextBox")
sizeBox.Size = UDim2.new(0,120,0,40)
sizeBox.Position = UDim2.new(0,20,0,260)
sizeBox.Text = "200"
sizeBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
sizeBox.TextColor3 = Color3.new(1,1,1)
sizeBox.Parent = gui

-- วงกลางจอ
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

--================ ปรับขนาดวง =================

sizeBox.FocusLost:Connect(function()
	local num = tonumber(sizeBox.Text)
	if num then
		circleSize = num
		circle.Size = UDim2.new(0,circleSize,0,circleSize)
		circle.Position = UDim2.new(0.5,-circleSize/2,0.5,-circleSize/2)
	end
end)

--================ หาเป้าหมายในวง =================

local function getTargetInCircle()
	local closest = nil
	local shortest = math.huge
	
	for _,v in pairs(workspace:GetDescendants()) do
		if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= char then
			
			local pos, visible = camera:WorldToViewportPoint(v.HumanoidRootPart.Position)
			
			if visible then
				local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
				local targetPos = Vector2.new(pos.X,pos.Y)
				
				local dist = (screenCenter - targetPos).Magnitude
				
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

--================ ล็อคเป้า + หันกล้อง =================

game:GetService("RunService").RenderStepped:Connect(function()
	if lockEnabled then
		lockedTarget = getTargetInCircle()
		
		if lockedTarget and lockedTarget:FindFirstChild("HumanoidRootPart") then
			local targetPos = lockedTarget.HumanoidRootPart.Position
			
			root.CFrame = CFrame.lookAt(root.Position, targetPos)
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
		end
	end
end)
