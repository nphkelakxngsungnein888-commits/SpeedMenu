-- ScatterTrueDetach.lua
-- LocalScript: ทำให้ตัวละคร "แตกออกจริง" (detach Motor6D) แล้วผลักส่วนด้วยฟิสิกส์
-- รวมกลับด้วยการสร้าง Motor6D ใหม่ (recreate) ให้สามารถขยับต่อได้
-- UI: อยู่กลางจอ, draggable, foldable, 3 ช่องค่าปรับ

-- == Services ==
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- == Character refs (respawn-safe) ==
local character, humanoid, hrp
local function setupChar(c)
	character = c or player.Character or player.CharacterAdded:Wait()
	humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
	-- try to own network to make local physics responsive (might be ignored in some games)
	pcall(function() workspace:SetNetworkOwner(hrp, player) end)
end
if player.Character then setupChar(player.Character) end
player.CharacterAdded:Connect(function(c) task.wait(0.5); setupChar(c) end)

-- == Params & storage ==
local params = {
	Force = 60,       -- base impulse
	Spread = 8,       -- direction randomness
	Spin = 2,         -- angular multiplier
	ReassembleTime = 0.6,
}
-- store saved per-session (attribute)
local function loadSaved()
	local s = player:GetAttribute("ScatterTrue_Params")
	if s then
		local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
		if ok and type(t)=="table" then
			params.Force = tonumber(t.Force) or params.Force
			params.Spread = tonumber(t.Spread) or params.Spread
			params.Spin = tonumber(t.Spin) or params.Spin
		end
	end
end
local function saveParams()
	local ok, v = pcall(function() return HttpService:JSONEncode({Force=params.Force, Spread=params.Spread, Spin=params.Spin}) end)
	if ok then player:SetAttribute("ScatterTrue_Params", v) end
end
loadSaved()

-- == UI build (centered, draggable, foldable) ==
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScatterTrueUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0, 360, 0, 300)
main.Position = UDim2.new(0.5, -180, 0.5, -150)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(24,24,24)
main.BorderSizePixel = 0
main.ZIndex = 5
main.Active = true

local mainCorner = Instance.new("UICorner", main); mainCorner.CornerRadius = UDim.new(0,10)

-- header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,48)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(0,150,220)
local headerCorner = Instance.new("UICorner", header); headerCorner.CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.02,0,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ ตัวกระจายจริง"

local foldBtn = Instance.new("TextButton", header)
foldBtn.Size = UDim2.new(0,36,0,36)
foldBtn.Position = UDim2.new(0.98,-8,0,6)
foldBtn.AnchorPoint = Vector2.new(1,0)
foldBtn.Text = "—"
foldBtn.Font = Enum.Font.SourceSansBold
foldBtn.TextSize = 18
foldBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
foldBtn.TextColor3 = Color3.new(1,1,1)
local foldCorner = Instance.new("UICorner", foldBtn); foldCorner.CornerRadius = UDim.new(0,6)

local statusLabel = Instance.new("TextLabel", header)
statusLabel.Size = UDim2.new(0.35, -10, 1, 0)
statusLabel.Position = UDim2.new(0.6, 8, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
statusLabel.Text = "ปิด"

local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0,100,0,34)
toggleBtn.Position = UDim2.new(1,-12,0,7)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Text = "เปิดระบบ"
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleBtn.TextColor3 = Color3.new(1,1,1)
local toggleCorner = Instance.new("UICorner", toggleBtn); toggleCorner.CornerRadius = UDim.new(0,6)

-- content
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -16, 1, -64)
content.Position = UDim2.new(0,8,0,56)
content.BackgroundTransparency = 1

local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1,0,0,30)
modeLabel.Position = UDim2.new(0,0,0,0)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.SourceSansBold
modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "โหมด: ตัวกระจายจริง"

local subLabel = Instance.new("TextLabel", content)
subLabel.Size = UDim2.new(1,0,0,20)
subLabel.Position = UDim2.new(0,0,0,34)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.SourceSans
subLabel.TextSize = 14
subLabel.TextColor3 = Color3.new(1,1,1)
subLabel.Text = "ปรับค่า"

-- field creator
local function makeField(parent, y, labelText, default)
	local cont = Instance.new("Frame", parent)
	cont.Size = UDim2.new(1,0,0,44)
	cont.Position = UDim2.new(0,0,0,y)
	cont.BackgroundTransparency = 1

	local lbl = Instance.new("TextLabel", cont)
	lbl.Size = UDim2.new(0.6, -8, 0, 30)
	lbl.Position = UDim2.new(0,6,0,7)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = labelText

	local box = Instance.new("TextBox", cont)
	box.Size = UDim2.new(0.36, -12, 0, 30)
	box.Position = UDim2.new(0.64, 6, 0, 7)
	box.BackgroundColor3 = Color3.fromRGB(36,36,36)
	box.Font = Enum.Font.SourceSans
	box.TextSize = 14
	box.TextColor3 = Color3.new(1,1,1)
	box.ClearTextOnFocus = false
	box.Text = tostring(default)
	local corner = Instance.new("UICorner", box); corner.CornerRadius = UDim.new(0,6)
	return {frame = cont, label = lbl, box = box}
end

local fldForce = makeField(content, 60, "แรงกระจาย (Force)", params.Force)
local fldSpread = makeField(content, 110, "ความกว้างกระจาย (Spread)", params.Spread)
local fldSpin = makeField(content, 160, "ความเร็วหมุน (Spin)", params.Spin)

local info = Instance.new("TextLabel", content)
info.Size = UDim2.new(1, -8, 0, 40)
info.Position = UDim2.new(0, 8, 1, -44)
info.BackgroundTransparency = 1
info.Font = Enum.Font.SourceSans
info.TextSize = 13
info.TextColor3 = Color3.new(1,1,1)
info.TextWrapped = true
info.Text = "เมื่อเปิดระบบ และเริ่มเดิน ตัวจะ 'แตก' เป็นชิ้นจริง ๆ (ถอน Motor6D) แล้วเด้งออกทุกทิศทาง ค่าในช่องเป็นตัวคูณ"

-- fold behavior
local folded = false
local foldTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
foldBtn.MouseButton1Click:Connect(function()
	if folded then
		-- expand
		for _,v in pairs(main:GetChildren()) do if v ~= header then v.Visible = true end end
		TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,360,0,300)}):Play()
		folded = false
		foldBtn.Text = "—"
	else
		for _,v in pairs(main:GetChildren()) do if v ~= header then v.Visible = false end end
		TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,160,0,48)}):Play()
		folded = true
		foldBtn.Text = "เมนู"
	end
end)

-- draggable (touch + mouse)
local dragging = false
local dragStart = nil
local startPos = nil
local function beginDrag(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end
local function updateDrag(input)
	if not dragging or not dragStart or not startPos then return end
	local delta = input.Position - dragStart
	main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
local function endDrag(input)
	dragging = false
end

header.InputBegan:Connect(beginDrag)
header.InputChanged:Connect(updateDrag)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		updateDrag(input)
	end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then endDrag(input) end)

-- toggle on/off
local enabled = false
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	statusLabel.Text = enabled and "เปิด" or "ปิด"
	toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
end)

-- handle fields
fldForce.box.FocusLost:Connect(function()
	local v = tonumber(fldForce.box.Text)
	if v and v>0 then params.Force = v; saveParams() else fldForce.box.Text = tostring(params.Force) end
end)
fldSpread.box.FocusLost:Connect(function()
	local v = tonumber(fldSpread.box.Text)
	if v and v>0 then params.Spread = v; saveParams() else fldSpread.box.Text = tostring(params.Spread) end
end)
fldSpin.box.FocusLost:Connect(function()
	local v = tonumber(fldSpin.box.Text)
	if v and v>=0 then params.Spin = v; saveParams() else fldSpin.box.Text = tostring(params.Spin) end
end)

-- == Detach / Reattach logic ==
-- store saved Motor6D data for recreation
local savedMotors = {} -- list of {Name, Part0, Part1Name, C0, C1}
local detachedParts = {} -- parts detached currently

local function listCandidateMotors(char)
	local motors = {}
	for _,inst in ipairs(char:GetDescendants()) do
		if inst:IsA("Motor6D") then
			-- keep rootjoint, waist, etc. but we will pick by name patterns
			table.insert(motors, inst)
		end
	end
	return motors
end

-- pattern to choose joints to detach (shoulder/hip/neck variants)
local detachPatterns = {"Shoulder","Hip","Neck","Waist","Root","UpperArm","LowerArm","UpperLeg","LowerLeg","Head","Left","Right"}

local function isDetachMotorName(mname)
	-- pick motors that likely connect limbs (exclude RootJoint to avoid total collapse)
	local lower = string.lower(mname or "")
	if mname == "RootJoint" or mname == "HumanoidRootPartRootJoint" then return false end
	-- if name contains any detachPatterns and not rootjoint
	for _,pat in ipairs(detachPatterns) do
		if string.find(lower, string.lower(pat)) then
			-- but exclude "Root" explicitly as rootjoint handled above
			if string.find(lower,"root") and not string.find(lower,"rootjoint") then
				-- continue, allow other root uses
			end
			return true
		end
	end
	return false
end

local function saveAndRemoveMotors()
	savedMotors = {}
	detachedParts = {}
	if not character then return end
	for _,m in ipairs(listCandidateMotors(character)) do
		if isDetachMotorName(m.Name) and m.Part0 and m.Part1 then
			-- don't remove motor that connects to HumanoidRootPart directly (avoid full collapse)
			if m.Part1 == hrp or m.Part0 == hrp then
				-- skip
			else
				table.insert(savedMotors, {
					Name = m.Name,
					Part0Name = m.Part0.Name,
					Part1Name = m.Part1.Name,
					C0 = m.C0,
					C1 = m.C1,
					ParentName = m.Parent and m.Parent.Name or nil
				})
				-- record detached part (the child part)
				table.insert(detachedParts, m.Part1)
				-- remove the Motor6D
				pcall(function() m:Destroy() end)
			end
		end
	end
end

local function recreateMotors()
	-- recreate motors by name lookup (we assume parts still present)
	for _,data in ipairs(savedMotors) do
		local part0 = character:FindFirstChild(data.Part0Name, true) or character:FindFirstChild(data.Part0Name)
		local part1 = character:FindFirstChild(data.Part1Name, true) or character:FindFirstChild(data.Part1Name)
		if part0 and part1 then
			local m = Instance.new("Motor6D")
			m.Name = data.Name or ("Motor6D_"..tostring(math.random(1,9999)))
			m.Part0 = part0
			m.Part1 = part1
			m.C0 = data.C0 or CFrame.new()
			m.C1 = data.C1 or CFrame.new()
			m.Parent = part0
		end
	end
	-- clear saved
	savedMotors = {}
	detachedParts = {}
end

-- apply impulses to detached parts (each actual BasePart)
local function impulseDetached()
	if not hrp then return end
	for _,p in ipairs(detachedParts) do
		if p and p.Parent then
			-- make sure unanchored and collidable
			p.Anchored = false
			p.CanCollide = true
			-- calculate dir and randomness
			local dir = (p.Position - hrp.Position)
			if dir.Magnitude == 0 then dir = Vector3.new(0,1,0) end
			dir = dir.Unit
			local spreadFactor = math.max(0.1, params.Spread/10)
			local rand = Vector3.new((math.random()-0.5)*2*spreadFactor, (math.random()*0.8 + 0.2)*spreadFactor, (math.random()-0.5)*2*spreadFactor)
			local forceVec = (dir + rand).Unit * (params.Force * (p:GetMass() or 1))
			p:ApplyImpulse(forceVec)
			-- add angular velocity via BodyAngularVelocity on part
			local bav = Instance.new("BodyAngularVelocity")
			bav.MaxTorque = Vector3.new(1e6,1e6,1e6)
			bav.P = 1000
			bav.AngularVelocity = Vector3.new(rand.X, rand.Y, rand.Z) * (params.Spin or 1)
			bav.Parent = p
			-- remove bav after some time so reattach can work smoothly
			Debris:AddItem(bav, 1.2)
		end
	end
end

-- reassemble (tween parts back to HRP and recreate Motor6D when finished)
local function reassembleToRoot()
	-- tween detachedParts to hrp.CFrame then recreate motors
	local toTween = {}
	for _,p in ipairs(detachedParts) do
		if p and p.Parent then
			-- remove dynamic forces to avoid jitter
			for _,child in ipairs(p:GetChildren()) do
				if child:IsA("BodyVelocity") or child:IsA("BodyForce") or child:IsA("BodyAngularVelocity") then
					pcall(function() child:Destroy() end)
				end
			end
			local target = (hrp and hrp.CFrame) or CFrame.new(0,5,0)
			local tw = TweenService:Create(p, TweenInfo.new(params.ReassembleTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = target})
			tw:Play()
			table.insert(toTween, p)
		end
	end

	-- after tween, recreate Motor6D and restore parts' properties
	task.delay(params.ReassembleTime + 0.05, function()
		-- destroy any lingering forces & then recreate motors
		for _,p in ipairs(toTween) do
			pcall(function()
				for _,child in ipairs(p:GetChildren()) do
					if child:IsA("BodyVelocity") or child:IsA("BodyForce") or child:IsA("BodyAngularVelocity") then
						child:Destroy()
					end
				end
			end)
		end
		recreateMotors()
		-- restore transparency / collisions as safe
		for _,part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function()
					part.Transparency = 0
					part.CanCollide = false -- keep non-collidable for the original to avoid physics conflicts
				end)
			end
		end
	end)
end

-- safety: if recreate fails, fallback: Force a Character reset (not preferred)
local function safeFallbackReset()
	pcall(function()
		humanoid.Health = 0
	end)
end

-- main movement detection and orchestration
local wasMoving = false
local currentlyDetached = false

RunService.RenderStepped:Connect(function()
	-- update params live
	local fv = tonumber(fldForce and fldForce.box and fldForce.box.Text)
	if fv and fv>0 then params.Force = fv end
	local sv = tonumber(fldSpread and fldSpread.box and fldSpread.box.Text)
	if sv and sv>0 then params.Spread = sv end
	local spv = tonumber(fldSpin and fldSpin.box and fldSpin.box.Text)
	if spv and spv>=0 then params.Spin = spv end

	if not humanoid or not hrp then return end
	local moving = (humanoid.MoveDirection and humanoid.MoveDirection.Magnitude > 0.01) and enabled
	if moving and not wasMoving then
		-- start moving: detach relevant motors, apply impulse
		wasMoving = true
		-- save and remove motors (detach)
		saveAndRemoveMotors()
		if #detachedParts > 0 then
			currentlyDetached = true
			-- make sure original parts invisible? we will keep them visible (they are same parts)
			-- apply impulse to detached real parts
			impulseDetached()
		end
	elseif not moving and wasMoving then
		-- stopped moving: reassemble
		wasMoving = false
		if currentlyDetached then
			reassembleToRoot()
			currentlyDetached = false
		end
	end
end)

-- UI show/hide
local visible = true
foldBtn.MouseButton1Click:Connect(function()
	visible = not visible
	for _,v in ipairs(main:GetChildren()) do
		if v ~= header then v.Visible = visible end
	end
	if visible then
		main.Size = UDim2.new(0,360,0,300)
	else
		main.Size = UDim2.new(0,160,0,48)
	end
end)

-- toggle enable
enabled = false
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	statusLabel.Text = enabled and "เปิด" or "ปิด"
	toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
end)

-- ensure fields defined for live update (connect earlier field makers)
-- we used fldForce/fldSpread/fldSpin variables created earlier
fldForce.box.Text = tostring(params.Force)
fldSpread.box.Text = tostring(params.Spread)
fldSpin.box.Text = tostring(params.Spin)

-- restore on GUI destroy
screenGui.Destroying:Connect(function()
	-- attempt to recreate motors if detached
	if #savedMotors > 0 then
		recreateMotors()
	end
end)

print("[ScatterTrueDetach] loaded")
