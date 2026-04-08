-- เอาโค้ดเดิมทั้งหมดของคุณไว้เหมือนเดิมด้านบน
-- ❗ แล้ว "แทนที่เฉพาะส่วน UI ทั้งหมด" ด้วยอันนี้

--// UI
local gui = Instance.new("ScreenGui")
gui.Name = "MovementPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.fromOffset(300, 320)
main.Position = UDim2.new(0, 20, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(70,70,70)
stroke.Transparency = 0.3

-- HEADER
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,36)
header.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", header).CornerRadius = UDim.new(0,10)

local fix = Instance.new("Frame", header)
fix.Size = UDim2.new(1,0,0.5,0)
fix.Position = UDim2.new(0,0,0.5,0)
fix.BackgroundColor3 = header.BackgroundColor3
fix.BorderSizePixel = 0

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-80,1,0)
title.Position = UDim2.fromOffset(12,0)
title.Text = "Movement"
title.Font = Enum.Font.GothamSemibold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(240,240,240)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local mini = Instance.new("TextButton", header)
mini.Size = UDim2.fromOffset(26,22)
mini.Position = UDim2.new(1,-60,0.5,-11)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(60,60,60)
Instance.new("UICorner", mini).CornerRadius = UDim.new(0,6)

local close = Instance.new("TextButton", header)
close.Size = UDim2.fromOffset(26,22)
close.Position = UDim2.new(1,-30,0.5,-11)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(120,50,50)
Instance.new("UICorner", close).CornerRadius = UDim.new(0,6)

-- SCROLL
local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = UDim2.fromOffset(0,36)
scroll.Size = UDim2.new(1,0,1,-36)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local pad = Instance.new("UIPadding", scroll)
pad.PaddingTop = UDim.new(0,10)
pad.PaddingBottom = UDim.new(0,10)
pad.PaddingLeft = UDim.new(0,10)
pad.PaddingRight = UDim.new(0,10)

local list = Instance.new("UIListLayout", scroll)
list.Padding = UDim.new(0,10)

-- ROW (สวย)
local function makeRow(name, def, tFunc, vFunc)
	local row = Instance.new("Frame", scroll)
	row.Size = UDim2.new(1,0,0,50)
	row.BackgroundColor3 = Color3.fromRGB(32,32,32)
	row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

	local s = Instance.new("UIStroke", row)
	s.Color = Color3.fromRGB(70,70,70)
	s.Transparency = 0.4

	local label = Instance.new("TextLabel", row)
	label.Position = UDim2.fromOffset(12,0)
	label.Size = UDim2.fromOffset(110,50)
	label.Text = name
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(240,240,240)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left

	local toggle = Instance.new("TextButton", row)
	toggle.Size = UDim2.fromOffset(60,28)
	toggle.Position = UDim2.new(0,130,0.5,-14)
	toggle.Text = "OFF"
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 12
	toggle.BackgroundColor3 = Color3.fromRGB(70,70,70)
	toggle.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,6)

	local box = Instance.new("TextBox", row)
	box.Size = UDim2.fromOffset(80,28)
	box.Position = UDim2.new(1,-90,0.5,-14)
	box.Text = tostring(def)
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.BackgroundColor3 = Color3.fromRGB(24,24,24)
	box.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

	local on=false
	toggle.MouseButton1Click:Connect(function()
		on = not on
		toggle.Text = on and "ON" or "OFF"
		toggle.BackgroundColor3 = on and Color3.fromRGB(0,170,110) or Color3.fromRGB(70,70,70)
		tFunc(on)
	end)

	box.FocusLost:Connect(function()
		local v=tonumber(box.Text)
		if v then vFunc(v) else box.Text=tostring(def) end
	end)
end

makeRow("WalkSpeed", state.walkSpeed,
	function(v) state.enableSpeed=v end,
	function(v) state.walkSpeed=v end)

makeRow("JumpPower", state.jumpPower,
	function(v) state.enableJump=v end,
	function(v) state.jumpPower=v end)

makeRow("MultiJump", state.multiJump,
	function(v) state.enableMultiJump=v end,
	function(v) state.multiJump=v end)

makeRow("FlySpeed", state.flySpeed,
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
	main.Size=minimized and UDim
