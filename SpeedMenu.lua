--// SpeedMenu v2.0 – All Modes + Saved Values + Mode Stop System
--// Author: You (based on TAS style)

local plr = game.Players.LocalPlayer
local run = game:GetService("RunService")
local tween = game:GetService("TweenService")

--==[ Main Gui ]==--
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedMenu"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 350)
frame.Position = UDim2.new(0, 50, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local header = Instance.new("TextButton", frame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
header.Text = "SPEED"
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.SourceSansBold
header.TextSize = 20

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -40)
content.Position = UDim2.new(0, 0, 0, 40)
content.BackgroundTransparency = 1

local fold = false
header.MouseButton1Click:Connect(function()
	fold = not fold
	content.Visible = not fold
	frame.Size = fold and UDim2.new(0, 250, 0, 40) or UDim2.new(0, 250, 0, 350)
end)

--==[ UI Elements ]==--
local function makeLabel(parent, text)
	local lbl = Instance.new("TextLabel", parent)
	lbl.Size = UDim2.new(1, -10, 0, 20)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.Text = text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local function makeBox(parent, default)
	local box = Instance.new("TextBox", parent)
	box.Size = UDim2.new(1, -10, 0, 25)
	box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.Text = tostring(default)
	box.ClearTextOnFocus = false
	return box
end

local function makeButton(parent, text)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.new(1, -10, 0, 30)
	b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = text
	return b
end

--==[ State ]==--
local currentMode = nil
local active = false
local values = {}

--==[ Character Refresher ]==--
local char, hrp, hum
local function setupChar()
	char = plr.Character or plr.CharacterAdded:Wait()
	hrp = char:WaitForChild("HumanoidRootPart")
	hum = char:WaitForChild("Humanoid")
end
setupChar()
plr.CharacterAdded:Connect(setupChar)

--==[ Mode Definitions ]==--
local modes = {
	["เดินเร็ว"] = {
		defaults = {["ค่าความเร็ว"] = 2},
		start = function(val)
			hum.WalkSpeed = 16 * val["ค่าความเร็ว"]
		end,
		stop = function()
			hum.WalkSpeed = 16
		end
	},
	["วาร์ป"] = {
		defaults = {["ค่าความเร็ว"] = 1, ["ระยะวาร์ป"] = 3, ["หน่วงวาร์ป"] = 0.05},
		thread = nil,
		start = function(val)
			modes["วาร์ป"].thread = task.spawn(function()
				while active and currentMode == "วาร์ป" do
					local cf = hrp.CFrame * CFrame.new(0, 0, -val["ระยะวาร์ป"] * val["ค่าความเร็ว"])
					hrp.CFrame = cf
					task.wait(val["หน่วงวาร์ป"])
				end
			end)
		end,
		stop = function()
			if modes["วาร์ป"].thread then
				task.cancel(modes["วาร์ป"].thread)
			end
		end
	},
	["ขยับตำแหน่ง"] = {
		defaults = {["ค่าความเร็ว"] = 1, ["ระยะขยับ"] = 2},
		thread = nil,
		start = function(val)
			modes["ขยับตำแหน่ง"].thread = task.spawn(function()
				while active and currentMode == "ขยับตำแหน่ง" do
					local dir = hum.MoveDirection
					if dir.Magnitude > 0 then
						hrp.CFrame = hrp.CFrame + dir * val["ระยะขยับ"] * val["ค่าความเร็ว"]
					end
					run.RenderStepped:Wait()
				end
			end)
		end,
		stop = function()
			if modes["ขยับตำแหน่ง"].thread then
				task.cancel(modes["ขยับตำแหน่ง"].thread)
			end
		end
	},
	["แรงขับเคลื่อน"] = {
		defaults = {["ค่าความเร็ว"] = 1, ["แรงขับ"] = 50},
		body = nil,
		start = function(val)
			local bv = Instance.new("BodyVelocity", hrp)
			bv.MaxForce = Vector3.new(1e5, 0, 1e5)
			modes["แรงขับเคลื่อน"].body = bv
			run.RenderStepped:Connect(function()
				if not active or currentMode ~= "แรงขับเคลื่อน" then return end
				bv.Velocity = hum.MoveDirection * val["แรงขับ"] * val["ค่าความเร็ว"]
			end)
		end,
		stop = function()
			if modes["แรงขับเคลื่อน"].body then
				modes["แรงขับเคลื่อน"].body:Destroy()
				modes["แรงขับเคลื่อน"].body = nil
			end
		end
	},
}

--==[ UI Build ]==--
local modeLabel = makeLabel(content, "โหมด:")
modeLabel.Position = UDim2.new(0, 5, 0, 5)
local modeDropdown = makeButton(content, "เลือกโหมด")
modeDropdown.Position = UDim2.new(0, 5, 0, 25)

local optionsFrame = Instance.new("Frame", content)
optionsFrame.Position = UDim2.new(0, 5, 0, 65)
optionsFrame.Size = UDim2.new(1, -10, 1, -115)
optionsFrame.BackgroundTransparency = 1

local runBtn = makeButton(content, "▶️ เปิดใช้งาน")
runBtn.Position = UDim2.new(0, 5, 1, -40)

local modeList = Instance.new("Frame", content)
modeList.Size = UDim2.new(1, -10, 0, 120)
modeList.Position = UDim2.new(0, 5, 0, 55)
modeList.BackgroundColor3 = Color3.fromRGB(40,40,40)
modeList.Visible = false

local layout = Instance.new("UIListLayout", modeList)
layout.Padding = UDim.new(0,2)

for modeName,_ in pairs(modes) do
	local btn = makeButton(modeList, modeName)
	btn.MouseButton1Click:Connect(function()
		modeDropdown.Text = "โหมด: "..modeName
		modeList.Visible = false
		currentMode = modeName

		for _, c in ipairs(optionsFrame:GetChildren()) do
			c:Destroy()
		end

		local defs = modes[modeName].defaults
		values[modeName] = values[modeName] or {}
		local y = 0
		for key, def in pairs(defs) do
			makeLabel(optionsFrame, key).Position = UDim2.new(0,0,0,y)
			local box = makeBox(optionsFrame, values[modeName][key] or def)
			box.Position = UDim2.new(0,0,0,y+20)
			box.FocusLost:Connect(function()
				local num = tonumber(box.Text) or def
				values[modeName][key] = num
			end)
			y = y + 50
		end
	end)
end

modeDropdown.MouseButton1Click:Connect(function()
	modeList.Visible = not modeList.Visible
end)

--==[ Activation ]==--
runBtn.MouseButton1Click:Connect(function()
	active = not active
	runBtn.Text = active and "⛔ หยุดการทำงาน" or "▶️ เปิดใช้งาน"

	for _, m in pairs(modes) do
		if m.stop then pcall(m.stop) end
	end

	if active and currentMode then
		local mode = modes[currentMode]
		if mode and mode.start then
			mode.start(values[currentMode] or mode.defaults)
		end
	end
end)
