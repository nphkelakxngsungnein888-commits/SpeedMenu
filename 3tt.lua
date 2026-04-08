--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// PLAYER
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// OPTIONAL MOBILE/DEFAULT CONTROLS
local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local controls = PlayerModule:GetControls()

--// STATE
local state = {
	walkSpeed = 16,
	jumpPower = 50,
	multiJump = 1,
	flySpeed = 60,

	enableSpeed = false,
	enableJump = false,
	enableMultiJump = false,
	enableFly = false,
}

local character, humanoid, root
local stateConn
local jumpCount = 0
local flying = false
local flyBV, flyBG

--// CLEANUP
local function cleanupFly()
	flying = false
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
end

--// CHARACTER SETUP
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	camera = workspace.CurrentCamera

	if stateConn then
		stateConn:Disconnect()
		stateConn = nil
	end

	jumpCount = 0
	humanoid.UseJumpPower = true
	humanoid.WalkSpeed = state.walkSpeed
	humanoid.JumpPower = state.jumpPower
	humanoid.AutoRotate = true

	stateConn = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			jumpCount = 0
		end
	end)

	if state.enableFly then
		task.defer(function()
			if root and state.enableFly then
				cleanupFly()
				flying = true

				flyBV = Instance.new("BodyVelocity")
				flyBV.Name = "FlyVelocity"
				flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				flyBV.P = 1e4
				flyBV.Velocity = Vector3.zero
				flyBV.Parent = root

				flyBG = Instance.new("BodyGyro")
				flyBG.Name = "FlyGyro"
				flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
				flyBG.P = 1e4
				flyBG.CFrame = root.CFrame
				flyBG.Parent = root
			end
		end)
	end
end

if player.Character then
	setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

--// MULTI JUMP
UIS.JumpRequest:Connect(function()
	if state.enableMultiJump and humanoid then
		if jumpCount < math.max(0, math.floor(state.multiJump)) then
			jumpCount += 1
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

--// FLY START/STOP
local function startFly()
	if not root then return end
	cleanupFly()
	flying = true

	flyBV = Instance.new("BodyVelocity")
	flyBV.Name = "FlyVelocity"
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.P = 1e4
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = root

	flyBG = Instance.new("BodyGyro")
	flyBG.Name = "FlyGyro"
	flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBG.P = 1e4
	flyBG.CFrame = root.CFrame
	flyBG.Parent = root

	if humanoid then
		humanoid.AutoRotate = false
	end
end

local function stopFly()
	if humanoid then
		humanoid.AutoRotate = true
	end
	cleanupFly()
end

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
	if humanoid then
		humanoid.WalkSpeed = state.enableSpeed and state.walkSpeed or 16
		humanoid.JumpPower = state.enableJump and state.jumpPower or 50
	end

	if state.enableFly and flying and root and humanoid and flyBV and flyBG then
		local camCF = camera.CFrame
		local moveVector = controls:GetMoveVector()

		local worldMove = camCF:VectorToWorldSpace(moveVector)
		local flatMove = Vector3.new(worldMove.X, 0, worldMove.Z)

		flyBV.Velocity = flatMove * state.flySpeed
		flyBG.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
	end
end)

--// UI
local gui = Instance.new("ScreenGui")
gui.Name = "MovementPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Parent = gui
main.Size = UDim2.fromOffset(290, 280)
main.Position = UDim2.new(0, 18, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main)

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1
mainStroke.Color = Color3.fromRGB(65, 65, 65)
mainStroke.Transparency = 0.25
mainStroke.Parent = main

local header = Instance.new("Frame")
header.Name = "Header"
header.Parent = main
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
header.BorderSizePixel = 0

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local headerCover = Instance.new("Frame")
headerCover.Parent = header
headerCover.BackgroundColor3 = header.BackgroundColor3
headerCover.BorderSizePixel = 0
headerCover.Position = UDim2.new(0, 0, 0.5, 0)
headerCover.Size = UDim2.new(1, 0, 0.5, 0)

local title = Instance.new("TextLabel")
title.Parent = header
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(10, 0)
title.Size = UDim2.new(1, -90, 1, 0)
title.Font = Enum.Font.GothamSemibold
title.Text = "Movement Panel"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local miniBtn = Instance.new("TextButton")
miniBtn.Parent = header
miniBtn.Size = UDim2.fromOffset(28, 22)
miniBtn.Position = UDim2.new(1, -60, 0.5, -11)
miniBtn.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
miniBtn.BorderSizePixel = 0
miniBtn.Font = Enum.Font.GothamBold
miniBtn.Text = "-"
miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniBtn.TextSize = 16
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = header
closeBtn.Size = UDim2.fromOffset(28, 22)
closeBtn.Position = UDim2.new(1, -30, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Parent = main
scroll.Position = UDim2.fromOffset(0, 34)
scroll.Size = UDim2.new(1, 0, 1, -34)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ClipsDescendants = true

local padding = Instance.new("UIPadding")
padding.Parent = scroll
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)

local list = Instance.new("UIListLayout")
list.Parent = scroll
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 8)

local function makeRow(parent, name, defaultValue, onToggle, onValue)
	local row = Instance.new("Frame")
	row.Parent = parent
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	row.BorderSizePixel = 0
	row.ClipsDescendants = true
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(55, 55, 55)
	stroke.Transparency = 0.35
	stroke.Parent = row

	local label = Instance.new("TextLabel")
	label.Parent = row
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.fromOffset(108, 44)
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left

	local toggle = Instance.new("TextButton")
	toggle.Parent = row
	toggle.Size = UDim2.fromOffset(58, 26)
	toggle.Position = UDim2.new(0, 122, 0.5, -13)
	toggle.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
	toggle.BorderSizePixel = 0
	toggle.Font = Enum.Font.GothamBold
	toggle.Text = "OFF"
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.TextSize = 12
	Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

	local box = Instance.new("TextBox")
	box.Parent = row
	box.Size = UDim2.fromOffset(78, 26)
	box.Position = UDim2.new(1, -88, 0.5, -13)
	box.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Gotham
	box.Text = tostring(defaultValue)
	box.PlaceholderText = "Value"
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	box.TextSize = 12
	box.ClearTextOnFocus = false
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	local enabled = false

	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled
		toggle.Text = enabled and "ON" or "OFF"
		toggle.BackgroundColor3 = enabled and Color3.fromRGB(0, 150, 90) or Color3.fromRGB(62, 62, 62)
		onToggle(enabled)
	end)

	box.FocusLost:Connect(function()
		local value = tonumber(box.Text)
		if value then
			onValue(value)
			box.Text = tostring(value)
		else
			box.Text = tostring(defaultValue)
		end
	end)
end

makeRow(scroll, "WalkSpeed", state.walkSpeed,
	function(on)
		state.enableSpeed = on
	end,
	function(v)
		state.walkSpeed = math.max(0, v)
	end
)

makeRow(scroll, "JumpPower", state.jumpPower,
	function(on)
		state.enableJump = on
	end,
	function(v)
		state.jumpPower = math.max(0, v)
	end
)

makeRow(scroll, "MultiJump", state.multiJump,
	function(on)
		state.enableMultiJump = on
		jumpCount = 0
	end,
	function(v)
		state.multiJump = math.max(1, math.floor(v))
	end
)

makeRow(scroll, "FlySpeed", state.flySpeed,
	function(on)
		state.enableFly = on
		if on then
			startFly()
		else
			stopFly()
		end
	end,
	function(v)
		state.flySpeed = math.max(0, v)
	end
)

--// DRAG
local dragging = false
local dragInput
local dragStart
local startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		dragInput = input
	end
end)

header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		updateDrag(input)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input == dragInput then
		dragging = false
		dragInput = nil
	end
end)

--// MINIMIZE / CLOSE
local minimized = false
miniBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	scroll.Visible = not minimized
	main.Size = minimized and UDim2.fromOffset(290, 34) or UDim2.fromOffset(290, 280)
end)

closeBtn.MouseButton1Click:Connect(function()
	stopFly()
	if stateConn then
		stateConn:Disconnect()
		stateConn = nil
	end
	gui:Destroy()
end)
