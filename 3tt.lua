--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// PLAYER
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// CONTROLS
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

--// CHARACTER
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	camera = workspace.CurrentCamera

	if stateConn then stateConn:Disconnect() end
	jumpCount = 0

	humanoid.WalkSpeed = state.walkSpeed
	humanoid.JumpPower = state.jumpPower
	humanoid.UseJumpPower = true
	humanoid.AutoRotate = true

	stateConn = humanoid.StateChanged:Connect(function(_, s)
		if s == Enum.HumanoidStateType.Landed then
			jumpCount = 0
		end
	end)
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

--// MULTI JUMP
UIS.JumpRequest:Connect(function()
	if state.enableMultiJump and humanoid then
		if jumpCount < math.floor(state.multiJump) then
			jumpCount += 1
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

--// FLY
local function startFly()
	if not root then return end
	cleanupFly()
	flying = true

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
	flyBV.P = 1e4
	flyBV.Parent = root

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
	flyBG.P = 1e4
	flyBG.Parent = root

	if humanoid then humanoid.AutoRotate = false end
end

local function stopFly()
	if humanoid then humanoid.AutoRotate = true end
	cleanupFly()
end

--// LOOP (⭐ แกน 3D เต็ม)
RunService.RenderStepped:Connect(function()
	if humanoid then
		humanoid.WalkSpeed = state.enableSpeed and state.walkSpeed or 16
		humanoid.JumpPower = state.enableJump and state.jumpPower or 50
	end

	if state.enableFly and flying and root and flyBV and flyBG then
		local camCF = camera.CFrame
		local move = controls:GetMoveVector()

		-- ⭐ คำนวณ 3 แกนตามกล้อง
		local dir =
			(camCF.LookVector * -move.Z) +
			(camCF.RightVector * move.X) +
			(camCF.UpVector * -move.Y)

		flyBV.Velocity = dir * state.flySpeed

		-- หันตามกล้อง
		flyBG.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
	end
end)

--// UI
local gui = Instance.new("ScreenGui")
gui.Name = "MovementPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(290,280)
main.Position = UDim2.new(0,20,0.25,0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.ClipsDescendants = true
Instance.new("UICorner", main)

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,34)
header.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-80,1,0)
title.Position = UDim2.fromOffset(10,0)
title.Text = "Movement Panel"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local mini = Instance.new("TextButton", header)
mini.Size = UDim2.fromOffset(30,22)
mini.Position = UDim2.new(1,-60,0.5,-11)
mini.Text = "-"

local close = Instance.new("TextButton", header)
close.Size = UDim2.fromOffset(30,22)
close.Position = UDim2.new(1,-30,0.5,-11)
close.Text = "X"

local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = UDim2.fromOffset(0,34)
scroll.Size = UDim2.new(1,0,1,-34)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local list = Instance.new("UIListLayout", scroll)
list.Padding = UDim.new(0,6)

local function row(name, def, tFunc, vFunc)
	local r = Instance.new("Frame", scroll)
	r.Size = UDim2.new(1,0,0,40)
	r.BackgroundColor3 = Color3.fromRGB(40,40,40)

	local l = Instance.new("TextLabel", r)
	l.Size = UDim2.fromOffset(100,40)
	l.Text = name
	l.TextColor3 = Color3.new(1,1,1)
	l.BackgroundTransparency = 1

	local t = Instance.new("TextButton", r)
	t.Position = UDim2.fromOffset(105,5)
	t.Size = UDim2.fromOffset(60,30)
	t.Text = "OFF"

	local b = Instance.new("TextBox", r)
	b.Position = UDim2.new(1,-80,0.5,-15)
	b.Size = UDim2.fromOffset(70,30)
	b.Text = tostring(def)

	local on=false
	t.MouseButton1Click:Connect(function()
		on=not on
		t.Text=on and "ON" or "OFF"
		tFunc(on)
	end)

	b.FocusLost:Connect(function()
		local v=tonumber(b.Text)
		if v then vFunc(v) end
	end)
end

row("WalkSpeed", state.walkSpeed,
	function(v) state.enableSpeed=v end,
	function(v) state.walkSpeed=v end)

row("JumpPower", state.jumpPower,
	function(v) state.enableJump=v end,
	function(v) state.jumpPower=v end)

row("MultiJump", state.multiJump,
	function(v) state.enableMultiJump=v end,
	function(v) state.multiJump=v end)

row("FlySpeed", state.flySpeed,
	function(v)
		state.enableFly=v
		if v then startFly() else stopFly() end
	end,
	function(v) state.flySpeed=v end)

-- DRAG
local dragging,dragStart,startPos
header.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then
		dragging=true
		dragStart=i.Position
		startPos=main.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and i.UserInputType==Enum.UserInputType.Touch then
		local d=i.Position-dragStart
		main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then
		dragging=false
	end
end)

-- MINIMIZE / CLOSE
local minimized=false
mini.MouseButton1Click:Connect(function()
	minimized=not minimized
	scroll.Visible=not minimized
	main.Size=minimized and UDim2.fromOffset(290,34) or UDim2.fromOffset(290,280)
end)

close.MouseButton1Click:Connect(function()
	stopFly()
	gui:Destroy()
end)
