local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

local RunService = game:GetService("RunService")

local lockEnabled = true
local lockedTarget = nil
local circleSize = 220
local lockStrength = 1
local scriptEnabled = true

--================ GUI =================

local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MobileLockSystem"

-- ปุ่มเปิด/ปิดล็อค
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0,120,0,45)
toggle.Position = UDim2.new(0,20,0,200)
toggle.Text = "LOCK : ON"
toggle.Parent = gui

-- ปุ่มปิดสคริปต์
local close = Instance.new("TextButton")
close.Size = UDim2.new(0,120,0,45)
close.Position = UDim2.new(0,20,0,150)
close.Text = "CLOSE SCRIPT"
close.Parent = gui

-- เส้นวงกลมจริง (ไม่ตัน)
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0,circleSize,0,circleSize)
circle.Position = UDim2.new(0.5,-circleSize/2,0.5,-circleSize/2)
circle.BackgroundTransparency = 1
circle.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1,0)
corner.Parent = circle

circle.BorderSizePixel = 2
circle.BorderColor3 = Color3.new(1,1,1)

--================ ปิดสคริปต์ =================

close.MouseButton1Click:Connect(function()
	scriptEnabled = false
	gui:Destroy()
end)

--================ เปิด/ปิดล็อค =================

toggle.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	
	if lockEnabled then
		toggle.Text = "LOCK : ON"
	else
		toggle.Text = "LOCK : OFF"
		lockedTarget = nil
	end
end)

--================ หาเป้าในวง =================

local function getTarget()
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

RunService.RenderStepped:Connect(function()
	if not scriptEnabled then return end
	if not lockEnabled then return end
	
	-- ถ้ายังไม่มีเป้า → หาใหม่
	if not lockedTarget then
		lockedTarget = getTarget()
	end
	
	-- ถ้ามอนหายหรือตาย → รีเซ็ต
	if lockedTarget then
		if not lockedTarget:FindFirstChild("Humanoid") or lockedTarget.Humanoid.Health <= 0 then
			lockedTarget = nil
			return
		end
		
		if not lockedTarget:FindFirstChild("HumanoidRootPart") then
			lockedTarget = nil
			return
		end
		
		local targetPos = lockedTarget.HumanoidRootPart.Position
		
		-- ล็อคตัวละคร
		local look = CFrame.lookAt(root.Position, targetPos)
		root.CFrame = root.CFrame:Lerp(look, lockStrength)
		
		-- ล็อคกล้องแบบไม่กระตุก
		local camLook = CFrame.lookAt(camera.CFrame.Position, targetPos)
		camera.CFrame = camera.CFrame:Lerp(camLook, lockStrength)
	end
end)
