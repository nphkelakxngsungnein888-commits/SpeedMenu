local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--================ UI =================--

local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.ResetOnSpawn = false

-- ปุ่มเปิด/ปิด
local toggle = Instance.new("TextButton", gui)
toggle.Size = UDim2.new(0,120,0,40)
toggle.Position = UDim2.new(0,20,0,200)
toggle.Text = "Lock: OFF"
toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggle.TextColor3 = Color3.new(1,1,1)

-- ปุ่มลบ
local remove = Instance.new("TextButton", gui)
remove.Size = UDim2.new(0,120,0,40)
remove.Position = UDim2.new(0,20,0,250)
remove.Text = "Remove UI"
remove.BackgroundColor3 = Color3.fromRGB(30,30,30)
remove.TextColor3 = Color3.new(1,1,1)

-- วงกลางจอ
local circle = Instance.new("Frame", gui)
circle.Size = UDim2.new(0,150,0,150)
circle.AnchorPoint = Vector2.new(0.5,0.5)
circle.Position = UDim2.new(0.5,0,0.5,0)
circle.BackgroundTransparency = 1

local stroke = Instance.new("UIStroke", circle)
stroke.Thickness = 3
stroke.Color = Color3.new(1,1,1)

local corner = Instance.new("UICorner", circle)
corner.CornerRadius = UDim.new(1,0)

--================ ลาก UI ได้ =================--

local dragging = false
local dragStart
local startPos

toggle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = toggle.Position
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		toggle.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
									startPos.Y.Scale, startPos.Y.Offset + delta.Y)

		remove.Position = UDim2.new(toggle.Position.X.Scale, toggle.Position.X.Offset,
									toggle.Position.Y.Scale, toggle.Position.Y.Offset + 50)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--================ ระบบล็อค =================--

local lockEnabled = false
local target = nil
local radius = 80 -- ขนาดวงล็อค

toggle.MouseButton1Click:Connect(function()
	lockEnabled = not lockEnabled
	toggle.Text = lockEnabled and "Lock: ON" or "Lock: OFF"
end)

remove.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local function getTarget()
	local closest = nil
	local dist = math.huge

	for _, v in pairs(workspace:GetDescendants()) do
		if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v ~= character then
			
			local pos, visible = camera:WorldToViewportPoint(v.HumanoidRootPart.Position)
			
			if visible then
				local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
				local distance = (Vector2.new(pos.X,pos.Y) - center).Magnitude
				
				if distance < radius then
					if distance < dist then
						dist = distance
						closest = v
					end
				end
			end
		end
	end

	return closest
end

RunService.RenderStepped:Connect(function()
	if not lockEnabled then return end
	
	target = getTarget()
	
	if target and target:FindFirstChild("HumanoidRootPart") then
		root.CFrame = CFrame.lookAt(root.Position, target.HumanoidRootPart.Position)
	end
end)
