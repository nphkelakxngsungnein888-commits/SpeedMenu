-- ScatterTrueDetach.lua
-- LocalScript (put in StarterGui OR run via loadstring)
-- 기능: UI (ตามภาพ) + ตัวละคร "แตกออกจริง" (detach Motor6D) + ApplyImpulse + ดูดกลับพร้อมกัน
-- โทร. : ใช้ในเกมของคุณเองเท่านั้น (อาจโดนเซิร์ฟเวอร์ตรวจจับในเกมอื่น)

-- ================== Services & player ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- ================== Character refs (respawn-safe) ==================
local character, humanoid, hrp
local function setupCharacter(c)
	character = c or player.Character or player.CharacterAdded:Wait()
	humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
	-- try to set network owner of HRP for better local physics control (may be ignored by some games)
	pcall(function() workspace:SetNetworkOwner(hrp, player) end)
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(function(c) task.wait(0.5); setupCharacter(c) end)

-- ================== Params (defaults) & persist in session attr ==================
local params = {
	Force = 60,       -- base impulse magnitude
	Spread = 8,       -- randomness / distance factor
	Spin = 2,         -- angular multiplier
	ReassembleTime = 0.6,
	CloneLifetime = 12,
}
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
	local ok, json = pcall(function() return HttpService:JSONEncode({Force=params.Force, Spread=params.Spread, Spin=params.Spin}) end)
	if ok then player:SetAttribute("ScatterTrue_Params", json) end
end
loadSaved()

-- ================== UI Build (centered, draggable, foldable) ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScatterTrueUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", screenGui)
main.Name = "Main"
main.Size = UDim2.new(0, 360, 0, 300)
main.Position = UDim2.new(0.5, -180, 0.5, -150)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.BackgroundColor3 = Color3.fromRGB(24,24,24)
main.BorderSizePixel = 0
main.Active = true
main.ZIndex = 5

local mainCorner = Instance.new("UICorner", main); mainCorner.CornerRadius = UDim.new(0,10)
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,48); header.Position = UDim2.new(0,0,0,0); header.BackgroundColor3 = Color3.fromRGB(0,150,220)
local headerCorner = Instance.new("UICorner", header); headerCorner.CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6,0,1,0); title.Position = UDim2.new(0.02,0,0,0)
title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSansBold; title.TextSize = 20; title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ ตัวกระจาย"

local foldBtn = Instance.new("TextButton", header)
foldBtn.Size = UDim2.new(0,36,0,36); foldBtn.Position = UDim2.new(0.98,-8,0,6); foldBtn.AnchorPoint = Vector2.new(1,0)
foldBtn.Text = "—"; foldBtn.Font = Enum.Font.SourceSansBold; foldBtn.TextSize = 18
foldBtn.BackgroundColor3 = Color3.fromRGB(18,18,18); foldBtn.TextColor3 = Color3.new(1,1,1)
local foldCorner = Instance.new("UICorner", foldBtn); foldCorner.CornerRadius = UDim.new(0,6)

local statusLabel = Instance.new("TextLabel", header)
statusLabel.Size = UDim2.new(0.35,-10,1,0); statusLabel.Position = UDim2.new(0.6,8,0,0); statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansBold; statusLabel.TextSize = 16; statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.TextXAlignment = Enum.TextXAlignment.Right; statusLabel.Text = "ปิด"

local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0,100,0,34); toggleBtn.Position = UDim2.new(1,-12,0,7); toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Text = "เปิดระบบ"; toggleBtn.Font = Enum.Font.SourceSans; toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30); toggleBtn.TextColor3 = Color3.new(1,1,1)
local toggleCorner = Instance.new("UICorner", toggleBtn); toggleCorner.CornerRadius = UDim.new(0,6)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,-16,1,-64); content.Position = UDim2.new(0,8,0,56); content.BackgroundTransparency = 1

local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1,0,0,30); modeLabel.Position = UDim2.new(0,0,0,0)
modeLabel.BackgroundTransparency = 1; modeLabel.Font = Enum.Font.SourceSansBold; modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.new(1,1,1); modeLabel.Text = "โหมด: ตัวกระจายจริง"

local subLabel = Instance.new("TextLabel", content)
subLabel.Size = UDim2.new(1,0,0,20); subLabel.Position = UDim2.new(0,0,0,34)
subLabel.BackgroundTransparency = 1; subLabel.Font = Enum.Font.SourceSans; subLabel.TextSize = 14; subLabel.TextColor3 = Color3.new(1,1,1)
subLabel.Text = "ปรับค่า (ค่าทั้งหมดเป็นตัวคูณ)"

local function makeField(parent, y, labelText, default)
	local cont = Instance.new("Frame", parent)
	cont.Size = UDim2.new(1,0,0,44); cont.Position = UDim2.new(0,0,0,y); cont.BackgroundTransparency = 1
	local lbl = Instance.new("TextLabel", cont)
	lbl.Size = UDim2.new(0.6, -8, 0, 30); lbl.Position = UDim2.new(0,6,0,7); lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 14; lbl.TextColor3 = Color3.new(1,1,1); lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = labelText
	local box = Instance.new("TextBox", cont)
	box.Size = UDim2.new(0.36, -12, 0, 30); box.Position = UDim2.new(0.64, 6, 0, 7)
	box.BackgroundColor3 = Color3.fromRGB(36,36,36); box.Font = Enum.Font.SourceSans; box.TextSize = 14
	box.TextColor3 = Color3.new(1,1,1); box.ClearTextOnFocus = false; box.Text = tostring(default)
	local corner = Instance.new("UICorner", box); corner.CornerRadius = UDim.new(0,6)
	return {frame = cont, label = lbl, box = box}
end

local fldForce = makeField(content, 60, "แรงกระจาย (Force)", params.Force)
local fldSpread = makeField(content, 110, "ความกว้างกระจาย (Spread)", params.Spread)
local fldSpin = makeField(content, 160, "ความเร็วหมุน (Spin)", params.Spin)

local info = Instance.new("TextLabel", content)
info.Size = UDim2.new(1,-8,0,40); info.Position = UDim2.new(0,8,1,-44); info.BackgroundTransparency = 1
info.Font = Enum.Font.SourceSans; info.TextSize = 13; info.TextColor3 = Color3.new(1,1,1); info.TextWrapped = true
info.Text = "เมื่อเปิดระบบและเริ่มเดิน ตัวจะ 'แตก' เป็นชิ้นจริง ๆ (ถอน Motor6D) แล้วเด้งออกทุกทิศ ทาง เมื่อหยุดจะดูดกลับพร้อมกัน"

-- fold / drag
local folded = false
local foldTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
foldBtn.MouseButton1Click:Connect(function()
	if folded then
		for _,v in pairs(main:GetChildren()) do if v~=header then v.Visible = true end end
		TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,360,0,300)}):Play()
		folded = false; foldBtn.Text = "—"
	else
		for _,v in pairs(main:GetChildren()) do if v~=header then v.Visible = false end end
		TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,160,0,48)}):Play()
		folded = true; foldBtn.Text = "เมนู"
	end
end)

-- drag (touch + mouse)
do
	local dragging=false; local dragStart=nil; local startPos=nil
	local function begin(input)
		if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true; dragStart=input.Position; startPos=main.Position
		end
	end
	local function update(input)
		if not dragging or not dragStart or not startPos then return end
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	local function ended(input) dragging=false end
	header.InputBegan:Connect(begin)
	header.InputChanged:Connect(update)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then update(input) end
	end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then ended(input) end end)
end

-- toggle enable
local enabled = false
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	statusLabel.Text = enabled and "เปิด" or "ปิด"
	toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
	if not enabled then
		-- ensure reassemble if disabling while detached
		-- reassemble handled by main loop
	end
end)

-- fields update (on focus lost)
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

-- ================== Detach / Reattach Logic (real Motor6D detach) ==================
-- savedMotors: list of tables storing motor info for recreate
local savedMotors = {}
local detachedParts = {} -- actual BaseParts that became detached

-- utility: collect all Motor6D in character
local function collectMotors()
	local result={}
	for _,inst in ipairs(character:GetDescendants()) do
		if inst:IsA("Motor6D") then table.insert(result, inst) end
	end
	return result
end

-- which Motor6D names to detach (pattern-based)
local detachPatterns = {"shoulder","hip","neck","waist","upper","lower","arm","leg","head","left","right"}
local function motorShouldDetach(m)
	if not m or not m.Name then return false end
	local n = string.lower(m.Name)
	if n:find("root") and (not n:find("rootjoint")) then return false end
	if m.Part1 == hrp or m.Part0 == hrp then return false end
	for _,p in ipairs(detachPatterns) do
		if n:find(p) then return true end
	end
	return false
end

local function saveAndRemoveMotors()
	savedMotors = {}
	detachedParts = {}
	if not character then return end
	for _,m in ipairs(collectMotors()) do
		if motorShouldDetach(m) and m.Part0 and m.Part1 then
			local entry = {
				Name = m.Name,
				Part0Name = m.Part0.Name,
				Part1Name = m.Part1.Name,
				C0 = m.C0,
				C1 = m.C1,
				ParentName = m.Parent and m.Parent.Name or nil
			}
			table.insert(savedMotors, entry)
			table.insert(detachedParts, m.Part1)
			pcall(function() m:Destroy() end)
		end
	end
end

local function recreateMotors()
	-- recreate Motor6D from savedMotors
	for _,d in ipairs(savedMotors) do
		local p0 = character:FindFirstChild(d.Part0Name, true) or character:FindFirstChild(d.Part0Name)
		local p1 = character:FindFirstChild(d.Part1Name, true) or character:FindFirstChild(d.Part1Name)
		if p0 and p1 then
			local m = Instance.new("Motor6D")
			m.Name = d.Name or ("Motor6D_"..math.random(1,9999))
			m.Part0 = p0
			m.Part1 = p1
			m.C0 = d.C0 or CFrame.new()
			m.C1 = d.C1 or CFrame.new()
			m.Parent = p0
		end
	end
	savedMotors = {}
	detachedParts = {}
end

-- apply impulse and spin to detached real parts
local function impulseDetached()
	if not hrp then return end
	for _,p in ipairs(detachedParts) do
		if p and p.Parent then
			p.Anchored = false
			p.CanCollide = true
			local dir = (p.Position - hrp.Position)
			if dir.Magnitude == 0 then dir = Vector3.new(0,1,0) end
			dir = dir.Unit
			local spreadFactor = math.max(0.1, params.Spread / 10)
			local rand = Vector3.new((math.random()-0.5)*2*spreadFactor, (math.random()*0.8 + 0.2)*spreadFactor, (math.random()-0.5)*2*spreadFactor)
			local forceVec = (dir + rand).Unit * (params.Force * (p:GetMass() or 1))
			p:ApplyImpulse(forceVec)
			local bav = Instance.new("BodyAngularVelocity")
			bav.MaxTorque = Vector3.new(1e6,1e6,1e6)
			bav.P = 1000
			bav.AngularVelocity = Vector3.new(rand.X, rand.Y, rand.Z) * (params.Spin or 1)
			bav.Parent = p
			Debris:AddItem(bav, 1.2)
		end
	end
end

-- reassemble: tween detached parts to HRP then recreate motors and restore properties
local function reassembleAll()
	-- Tween each detached part to hrp then recreate motors after tween
	for _,p in ipairs(detachedParts) do
		if p and p.Parent then
			-- remove any body forces to allow tween
			for _,child in ipairs(p:GetChildren()) do
				if child:IsA("BodyVelocity") or child:IsA("BodyAngularVelocity") or child:IsA("BodyForce") then
					pcall(function() child:Destroy() end)
				end
			end
			local target = hrp and hrp.CFrame or CFrame.new(0,5,0)
			local tw = TweenService:Create(p, TweenInfo.new(params.ReassembleTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = target})
			tw:Play()
		end
	end

	task.delay(params.ReassembleTime + 0.05, function()
		-- destroy lingering forces
		for _,p in ipairs(detachedParts) do
			if p and p.Parent then
				for _,child in ipairs(p:GetChildren()) do
					if child:IsA("BodyVelocity") or child:IsA("BodyAngularVelocity") or child:IsA("BodyForce") then
						pcall(function() child:Destroy() end)
					end
				end
			end
		end
		-- recreate motors
		recreateMotors()
		-- restore base part properties (transparency/canCollide)
		for _,part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function() part.Transparency = 0; part.CanCollide = false end)
			end
		end
	end)
end

-- fallback: if recreate fails, force reset
local function safeFallback()
	pcall(function() if humanoid then humanoid.Health = 0 end end)
end

-- ================== Movement detection & orchestration ==================
local wasMoving = false
local detachedNow = false

RunService.RenderStepped:Connect(function()
	-- live read fields (fast)
	local vf = tonumber(fldForce and fldForce.box and fldForce.box.Text)
	if vf and vf>0 then params.Force = vf end
	local vs = tonumber(fldSpread and fldSpread.box and fldSpread.box.Text)
	if vs and vs>0 then params.Spread = vs end
	local vs2 = tonumber(fldSpin and fldSpin.box and fldSpin.box.Text)
	if vs2 and vs2>=0 then params.Spin = vs2 end

	if not humanoid or not hrp then return end
	local moving = (humanoid.MoveDirection and humanoid.MoveDirection.Magnitude > 0.01) and enabled
	if moving and not wasMoving then
		-- start moving: detach and impulse
		wasMoving = true
		saveAndRemoveMotors()
		if #detachedParts > 0 then
			detachedNow = true
			-- make original parts visible as detached parts (we operate on real parts)
			impulseDetached()
		end
	elseif not moving and wasMoving then
		-- stopped: reassemble
		wasMoving = false
		if detachedNow then
			reassembleAll()
			detachedNow = false
		end
	end
end)

-- ================== UI hookups & safety ==================
fldForce.box.Text = tostring(params.Force)
fldSpread.box.Text = tostring(params.Spread)
fldSpin.box.Text = tostring(params.Spin)

-- toggle show/hide of content
local showing = true
foldBtn.MouseButton1Click:Connect(function()
	showing = not showing
	for _,v in ipairs(main:GetChildren()) do
		if v ~= header then v.Visible = showing end
	end
	if showing then main.Size = UDim2.new(0,360,0,300) else main.Size = UDim2.new(0,160,0,48) end
end)

-- enable/disable
enabled = false
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	statusLabel.Text = enabled and "เปิด" or "ปิด"
	toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
	if not enabled then
		-- if disabling while detached, attempt reassemble
		if #savedMotors > 0 or #detachedParts>0 then
			reassembleAll()
		end
	end
end)

-- cleanup on destroy
screenGui.Destroying:Connect(function()
	-- try to safely recreate if anything remains
	if #savedMotors>0 then recreateMotors() end
end)

print("[ScatterTrueDetach] loaded - mobile ready")
