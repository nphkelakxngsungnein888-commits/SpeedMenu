-- SpeedMenu_Ragdoll.lua
-- Speed menu + Ragdoll Dash (ตามสเปกของผู้ใช้)
-- UI ไทย, พับได้, dropdown ∆, 5 โหมด + โหมดตัวแตกกระเด้ง
-- เหมาะสำหรับ Mobile (ตรวจ MoveDirection) และ Desktop

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer

-- ======= Character handler (respawn-safe) =======
local char, hrp, hum
local function setupChar(c)
	char = c or plr.Character or plr.CharacterAdded:Wait()
	hrp = char:WaitForChild("HumanoidRootPart")
	hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
end
if plr.Character then setupChar(plr.Character) end
plr.CharacterAdded:Connect(setupChar)

-- ======= Default values =======
local globalActive = false
local modes = { "ความเร็วแรงดัน", "วาร์ป", "ขยับเฟรม", "ความเร็วเดิน", "แรงกระแทก", "โหมดตัวแตกกระเด้ง (Ragdoll Dash)" }
local currentMode = modes[1]

-- Global speed multiplier (applies to all modes)
local speedMultiplier = 2 -- default per your earlier request
-- TP specific defaults
local tpDistance = 10
local tpDelay = 0
-- Ragdoll defaults (multipliers / values)
local rag = {
	BouncePower = 50,
	BounceFrequency = 0.5,
	MassEffect = 1,
	SpinStrength = 10,
	MaxBounceRange = 30,
}
-- store values persistently per session
local values = {
	speed = speedMultiplier,
	TP = { dist = tpDistance, delay = tpDelay },
	Ragdoll = {
		BouncePower = rag.BouncePower,
		BounceFrequency = rag.BounceFrequency,
		MassEffect = rag.MassEffect,
		SpinStrength = rag.SpinStrength,
		MaxBounceRange = rag.MaxBounceRange,
	}
}

-- ======= GUI build (CoreGui) =======
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedMenu_Ragdoll"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 320, 0, 420)
main.Position = UDim2.new(0.02, 0, 0.15, 0)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.Active = true
main.Draggable = true
main.BorderSizePixel = 0

-- header (blue)
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,48)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(0,150,220)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.02,0,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ SPEED MENU"

local foldBtn = Instance.new("TextButton", header)
foldBtn.Size = UDim2.new(0,36,0,36)
foldBtn.Position = UDim2.new(0.95,-40,0,6)
foldBtn.AnchorPoint = Vector2.new(1,0)
foldBtn.Text = "—"
foldBtn.Font = Enum.Font.GothamBold
foldBtn.TextSize = 20
foldBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
foldBtn.TextColor3 = Color3.new(1,1,1)

local statusLbl = Instance.new("TextLabel", header)
statusLbl.Size = UDim2.new(0.35, -10, 1, 0)
statusLbl.Position = UDim2.new(0.6, 8, 0, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 16
statusLbl.TextColor3 = Color3.new(1,1,1)
statusLbl.TextXAlignment = Enum.TextXAlignment.Right
statusLbl.Text = "ปิด"

local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0,84,0,30)
toggleBtn.Position = UDim2.new(1,-92,0,9)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Text = "เปิดระบบ"
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(36,36,36)
toggleBtn.TextColor3 = Color3.new(1,1,1)

-- content
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,0,1,-48)
content.Position = UDim2.new(0,0,0,48)
content.BackgroundTransparency = 1

-- Mode label + ∆ button
local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(0.78, -10, 0, 30)
modeLabel.Position = UDim2.new(0.02, 0, 0, 8)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "โหมด: " .. currentMode

local deltaBtn = Instance.new("TextButton", content)
deltaBtn.Size = UDim2.new(0, 40, 0, 30)
deltaBtn.Position = UDim2.new(0.82, 0, 0, 8)
deltaBtn.Text = "∆"
deltaBtn.Font = Enum.Font.GothamBold
deltaBtn.TextSize = 18
deltaBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
deltaBtn.TextColor3 = Color3.new(1,1,1)

-- dropdown (appears below)
local dropdown = Instance.new("Frame", content)
dropdown.Size = UDim2.new(0, 260, 0, 0)
dropdown.Position = UDim2.new(0.02, 0, 0, 46)
dropdown.BackgroundColor3 = Color3.fromRGB(35,35,35)
dropdown.BorderSizePixel = 0
dropdown.ClipsDescendants = true
dropdown.Visible = false

local function openDropdown()
	if dropdown.Visible then return end
	dropdown.Visible = true
	dropdown:TweenSize(UDim2.new(0,260,0,#modes * 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.18, true)
end
local function closeDropdown()
	if not dropdown.Visible then return end
	dropdown:TweenSize(UDim2.new(0,260,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.16, true)
	task.delay(0.16, function() dropdown.Visible = false end)
end

local dropdownButtons = {}
for i, name in ipairs(modes) do
	local b = Instance.new("TextButton", dropdown)
	b.Size = UDim2.new(1, 0, 0, 30)
	b.Position = UDim2.new(0, 0, 0, (i-1)*30)
	b.BackgroundColor3 = Color3.fromRGB(48,48,48)
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.Text = name
	dropdownButtons[i] = b
	b.MouseButton1Click:Connect(function()
		currentMode = name
		modeLabel.Text = "โหมด: " .. currentMode
		closeDropdown()
		-- when switching, ensure other mode behaviors stop
		-- any per-mode cleanup will be handled in the main loop or via flags
		updateFields()
	end)
end

deltaBtn.MouseButton1Click:Connect(function()
	if dropdown.Visible then closeDropdown() else openDropdown() end
end)

-- Fields container with scrolling
local fieldsOuter = Instance.new("Frame", content)
fieldsOuter.Size = UDim2.new(1, -20, 0, 300)
fieldsOuter.Position = UDim2.new(0, 10, 0, 90)
fieldsOuter.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", fieldsOuter)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 8
scroll.BackgroundTransparency = 1

local uiList = Instance.new("UIListLayout", scroll)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0,6)

-- utility to create field
local function createField(labelText, default)
	local container = Instance.new("Frame", scroll)
	container.Size = UDim2.new(1,0,0,56)
	container.BackgroundTransparency = 1

	local lbl = Instance.new("TextLabel", container)
	lbl.Size = UDim2.new(0.6, -8, 0, 24)
	lbl.Position = UDim2.new(0, 6, 0, 6)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = labelText

	local box = Instance.new("TextBox", container)
	box.Size = UDim2.new(0.4, -12, 0, 28)
	box.Position = UDim2.new(0.6, 6, 0, 6)
	box.BackgroundColor3 = Color3.fromRGB(40,40,40)
	box.Font = Enum.Font.SourceSans
	box.TextSize = 14
	box.TextColor3 = Color3.new(1,1,1)
	box.ClearTextOnFocus = false
	box.Text = tostring(default)

	-- adjust canvas size
	uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y + 6)
	end)

	return {frame = container, label = lbl, box = box}
end

-- create fields but keep them dynamic: show only relevant
local field_map = {}

-- global speed
field_map.speed = createField("ความเร็วคูณ (x)", values.speed)

-- TP fields
field_map.tpDist = createField("ระยะวาร์ป", values.TP.dist)
field_map.tpDelay = createField("หน่วงวาร์ป (วินาที)", values.TP.delay)

-- Ragdoll fields
field_map.r_bounce = createField("Bounce Power (แรงกระเด้ง)", values.Ragdoll.BouncePower)
field_map.r_freq = createField("Bounce Frequency (วินาที)", values.Ragdoll.BounceFrequency)
field_map.r_mass = createField("Mass Effect", values.Ragdoll.MassEffect)
field_map.r_spin = createField("Spin Strength", values.Ragdoll.SpinStrength)
field_map.r_range = createField("Max Bounce Range", values.Ragdoll.MaxBounceRange)

-- hide all then show necessary
local function updateFields()
	-- hide all
	for k,v in pairs(field_map) do
		v.frame.Visible = false
	end
	-- always show speed
	field_map.speed.frame.Visible = true

	-- Show TP extras
	if currentMode == "วาร์ป" or currentMode == "TP" or currentMode == "วาร์ป" then
		-- If your mode label uses Thai 'วาร์ป' or 'TP', handle both; our modes list uses Thai "วาร์ป".
	end
	-- map names used earlier: "วาร์ป" is "วาร์ป", but we used "วาร์ป" in modes? We have "วาร์ป" string? 
	-- To be robust, compare english-ish words too:
	local cm = currentMode
	if cm == "วาร์ป" or cm == "TP" or cm == "วาร์ป" then
		field_map.tpDist.frame.Visible = true
		field_map.tpDelay.frame.Visible = true
	elseif cm == "โหมดตัวแตกกระเด้ง (Ragdoll Dash)" then
		field_map.r_bounce.frame.Visible = true
		field_map.r_freq.frame.Visible = true
		field_map.r_mass.frame.Visible = true
		field_map.r_spin.frame.Visible = true
		field_map.r_range.frame.Visible = true
	end
end

-- Because our modes array used names in Thai earlier, ensure lookup mapping:
-- But our modes were defined in Thai. To be safe, convert modes table entries to intended Thai:
-- We'll use the following standardized names (displayed in dropdown): 
-- "ความเร็วแรงดัน", "วาร์ป", "ขยับเฟรม", "ความเร็วเดิน", "แรงกระแทก", "โหมดตัวแตกกระเด้ง (Ragdoll Dash)"
-- updateFields will check these.
-- For robustness, define a helper:
local function isTPmode(name)
	return name == "วาร์ป" or name == "TP" or name == "วาร์ป"
end

-- override updateFields to use standardized names
function updateFields()
	for k,v in pairs(field_map) do v.frame.Visible = false end
	field_map.speed.frame.Visible = true
	if currentMode == "วาร์ป" or currentMode == "TP" or currentMode == "วาร์ป" then
		field_map.tpDist.frame.Visible = true
		field_map.tpDelay.frame.Visible = true
	elseif currentMode == "โหมดตัวแตกกระเด้ง (Ragdoll Dash)" then
		field_map.r_bounce.frame.Visible = true
		field_map.r_freq.frame.Visible = true
		field_map.r_mass.frame.Visible = true
		field_map.r_spin.frame.Visible = true
		field_map.r_range.frame.Visible = true
	end
end

-- initialize fields to match defaults (fill values)
field_map.speed.box.Text = tostring(values.speed or speedMultiplier)
field_map.tpDist.box.Text = tostring(values.TP.dist or tpDistance)
field_map.tpDelay.box.Text = tostring(values.TP.delay or tpDelay)
field_map.r_bounce.box.Text = tostring(values.Ragdoll.BouncePower)
field_map.r_freq.box.Text = tostring(values.Ragdoll.BounceFrequency)
field_map.r_mass.box.Text = tostring(values.Ragdoll.MassEffect)
field_map.r_spin.box.Text = tostring(values.Ragdoll.SpinStrength)
field_map.r_range.box.Text = tostring(values.Ragdoll.MaxBounceRange)

updateFields()

-- input handling: update values on focus lost
field_map.speed.box.FocusLost:Connect(function()
	local n = tonumber(field_map.speed.box.Text)
	if n and n > 0 then values.speed = n else field_map.speed.box.Text = tostring(values.speed) end
end)
field_map.tpDist.box.FocusLost:Connect(function()
	local n = tonumber(field_map.tpDist.box.Text)
	if n and n > 0 then values.TP.dist = n else field_map.tpDist.box.Text = tostring(values.TP.dist) end
end)
field_map.tpDelay.box.FocusLost:Connect(function()
	local n = tonumber(field_map.tpDelay.box.Text)
	if n and n >= 0 then values.TP.delay = n else field_map.tpDelay.box.Text = tostring(values.TP.delay) end
end)
field_map.r_bounce.box.FocusLost:Connect(function()
	local n = tonumber(field_map.r_bounce.box.Text)
	if n and n > 0 then values.Ragdoll.BouncePower = n else field_map.r_bounce.box.Text = tostring(values.Ragdoll.BouncePower) end
end)
field_map.r_freq.box.FocusLost:Connect(function()
	local n = tonumber(field_map.r_freq.box.Text)
	if n and n >= 0 then values.Ragdoll.BounceFrequency = n else field_map.r_freq.box.Text = tostring(values.Ragdoll.BounceFrequency) end
end)
field_map.r_mass.box.FocusLost:Connect(function()
	local n = tonumber(field_map.r_mass.box.Text)
	if n and n > 0 then values.Ragdoll.MassEffect = n else field_map.r_mass.box.Text = tostring(values.Ragdoll.MassEffect) end
end)
field_map.r_spin.box.FocusLost:Connect(function()
	local n = tonumber(field_map.r_spin.box.Text)
	if n and n >= 0 then values.Ragdoll.SpinStrength = n else field_map.r_spin.box.Text = tostring(values.Ragdoll.SpinStrength) end
end)
field_map.r_range.box.FocusLost:Connect(function()
	local n = tonumber(field_map.r_range.box.Text)
	if n and n > 0 then values.Ragdoll.MaxBounceRange = n else field_map.r_range.box.Text = tostring(values.Ragdoll.MaxBounceRange) end
end)

-- toggle system on/off
toggleBtn.MouseButton1Click:Connect(function()
	globalActive = not globalActive
	statusLbl.Text = globalActive and "เปิด" or "ปิด"
	toggleBtn.Text = globalActive and "ปิดระบบ" or "เปิดระบบ"
	-- reset humanoid defaults when turning off
	if not globalActive and hum then
		pcall(function() hum.WalkSpeed = 16 end)
	end
end)

foldBtn.MouseButton1Click:Connect(function()
	local folded = (main.Size.Y.Offset == 48)
	if folded then
		-- expand
		for _,v in pairs(main:GetChildren()) do
			if v ~= header then v.Visible = true end
		end
		main.Size = UDim2.new(0,320,0,420)
		foldBtn.Text = "—"
	else
		-- collapse (only header remains)
		for _,v in pairs(main:GetChildren()) do
			if v ~= header then v.Visible = false end
		end
		main.Size = UDim2.new(0,320,0,48)
		foldBtn.Text = "+"
	end
end)

-- cleanup helper for per-mode movers
local activeBV = nil
local function cleanupMode()
	if activeBV and activeBV.Parent then pcall(function() activeBV:Destroy() end) end
	activeBV = nil
	-- restore walk speed default if needed
	if hum then pcall(function() hum.WalkSpeed = 16 end) end
end

-- helper: spawn temporary clone pieces for ragdoll visual
local function spawnRagdollPieces(originChar, powerMult, spinMult, massMult, maxRange)
	local clones = {}
	local lifetime = 6
	for _, part in ipairs(originChar:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 and part.Size.Magnitude > 0.01 then
			-- clone visible body parts (head, torso, limbs)
			local c = part:Clone()
			c.CFrame = part.CFrame
			c.CanCollide = true
			c.Parent = workspace
			-- adjust mass via CustomPhysicalProperties if available
			pcall(function()
				local density = 1 * massMult
				c.CustomPhysicalProperties = PhysicalProperties.new(density, c.CustomPhysicalProperties.Friction, c.CustomPhysicalProperties.Elasticity)
			end)
			-- apply impulse outward with slight randomness
			local dir = (part.CFrame.Position - originChar.HumanoidRootPart.Position).Unit
			if not dir or dir.Magnitude ~= dir.Magnitude then dir = Vector3.new(math.random()-0.5, 0.2, math.random()-0.5).Unit end
			local rand = Vector3.new((math.random()-0.5), (math.random()*0.8)+0.2, (math.random()-0.5))
			local forceVec = (dir + rand).Unit * (powerMult * (math.random()*0.8 + 0.6))
			pcall(function() c:ApplyImpulse(forceVec * c:GetMass()) end)
			-- add angular velocity via BodyAngularVelocity for spin
			local bav = Instance.new("BodyAngularVelocity")
			bav.MaxTorque = Vector3.new(1e6,1e6,1e6)
			bav.AngularVelocity = Vector3.new(rand.X, rand.Y, rand.Z) * spinMult
			bav.P = 1000
			bav.Parent = c
			-- schedule cleanup
			table.insert(clones, c)
			task.delay(lifetime, function()
				pcall(function()
					if bav and bav.Parent then bav:Destroy() end
					if c and c.Parent then c:Destroy() end
				end)
			end)
		end
	end
	return clones
end

-- Detect collisions for ragdoll trigger: touched event on RootPart
local ragdollCooldown = 0.25
local lastRagdollTime = 0
local function onTouchedRagdoll(hit)
	if not globalActive then return end
	if currentMode ~= "โหมดตัวแตกกระเด้ง (Ragdoll Dash)" then return end
	if not hum or not hrp then return end
	local now = tick()
	if now - lastRagdollTime < ragdollCooldown then return end
	-- ignore self
	local par = hit and hit.Parent
	if not par or par == char then return end
	-- triggered only when player is moving (per spec)
	local moveDir = hum.MoveDirection
	if not moveDir or moveDir.Magnitude <= 0 then return end
	-- trigger ragdoll visual pieces
	lastRagdollTime = now
	local power = (values.Ragdoll.BouncePower or rag.BouncePower) * (values.speed or speedMultiplier)
	local spin = (values.Ragdoll.SpinStrength or rag.SpinStrength) * (values.speed or speedMultiplier)
	local massMult = (values.Ragdoll.MassEffect or rag.MassEffect)
	local maxRange = (values.Ragdoll.MaxBounceRange or rag.MaxBounceRange)
	-- spawn clones that fly out
	spawnRagdollPieces(char, power, spin, massMult, maxRange)
	-- optional: little knockback to character root (so it feels like hit)
	pcall(function() hrp:ApplyImpulse(-hit.CFrame.LookVector * (power * 0.3)) end)
end

-- connect touched (attach once and keep)
local touchedConn = nil
task.delay(0.5, function()
	if hrp then
		touchedConn = hrp.Touched:Connect(onTouchedRagdoll)
	end
end)
-- reconnect on respawn
plr.CharacterAdded:Connect(function(c)
	setupChar(c)
	-- reattach touched
	task.delay(0.6, function()
		if touchedConn then pcall(function() touchedConn:Disconnect() end) end
		if hrp and hrp.Parent then touchedConn = hrp.Touched:Connect(onTouchedRagdoll) end
	end)
end)

-- Per-frame main loop: only apply selected mode when MoveDirection > 0
RunService.RenderStepped:Connect(function(dt)
	if not globalActive or not hrp or not hum then return end
	-- update stored global speed value
	local sp = tonumber(field_map and field_map.speed and field_map.speed.box and field_map.speed.box.Text) or values.speed
	values.speed = sp
	local move = hum.MoveDirection
	if move.Magnitude <= 0 then
		-- not moving: reset passive things if needed
		cleanupMode()
		return
	end

	-- ensure only one mode active: apply behavior for currentMode only
	if currentMode == "ความเร็วแรงดัน" then
		-- apply BodyVelocity per-frame
		if not activeBV or not activeBV.Parent then
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1e5,1e5,1e5)
			bv.P = 1250
			bv.Parent = hrp
			activeBV = bv
		end
		local pow = 50 * (values.speed or 1)
		pcall(function() activeBV.Velocity = hrp.CFrame:VectorToWorldSpace(Vector3.new(move.X, move.Y, move.Z)) * pow end)

	elseif currentMode == "วาร์ป" or currentMode == "TP" then
		-- step-teleport: move HRP forward by tpDist * multiplier, then delay tpDelay
		local dist = tonumber(field_map.tpDist.box.Text) or values.TP.dist or tpDistance
		local delay = tonumber(field_map.tpDelay.box.Text) or values.TP.delay or tpDelay
		local step = (dist) * (values.speed or 1)
		-- move along look vector (world space)
		pcall(function() hrp.CFrame = hrp.CFrame + hrp.CFrame.LookVector * step end)
		if delay and delay > 0 then task.wait(delay) end

	elseif currentMode == "ขยับเฟรม" or currentMode == "CFrame" then
		local step = 3 * (values.speed or 1)
		pcall(function() hrp.CFrame = hrp.CFrame + move * step end)

	elseif currentMode == "ความเร็วเดิน" or currentMode == "WalkSpeed" then
		pcall(function() hum.WalkSpeed = 16 * (values.speed or 1) end)

	elseif currentMode == "แรงกระแทก" or currentMode == "Impulse" then
		pcall(function() hrp:ApplyImpulse(move * (150 * (values.speed or 1))) end)

	elseif currentMode == "โหมดตัวแตกกระเด้ง (Ragdoll Dash)" then
		-- main mode: no automatic break; ragdoll triggers on touch collisions handled by onTouchedRagdoll
		-- optionally add slight body velocity to assist collisions
		if not activeBV or not activeBV.Parent then
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1e4,1e4,1e4)
			bv.P = 500
			bv.Parent = hrp
			activeBV = bv
		end
		local assist = 24 * (values.speed or 1)
		pcall(function() activeBV.Velocity = hrp.CFrame:VectorToWorldSpace(Vector3.new(move.X, move.Y, move.Z)) * assist end)
	end
end)

-- cleanup on GUI destroy/unload
gui.Destroying:Connect(function()
	cleanupMode()
	if touchedConn then pcall(function() touchedConn:Disconnect() end) end
end)

-- finalize: ensure fields UI initially correct
updateFields()

-- End of file
