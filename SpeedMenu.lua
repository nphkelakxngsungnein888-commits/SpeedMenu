-- ScatterR15_UI.lua
-- LocalScript for StarterGui
-- ฟีเจอร์: UI ตามภาพ + R15 true detach (Motor6D remove) + ApplyImpulse + reattach immediately on stop
-- ใช้เฉพาะในเกมของคุณเอง (server-side anti-cheat อาจขัดข้อง)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- ====== parameters (default) ======
local params = {
    Force = 60,       -- แรงคูณ (ค่าที่ผู้ใช้กรอก)
    Spread = 8,       -- ความกว้างการกระจาย (คูณ)
    Spin = 2,         -- ความเร็วหมุน (คูณ)
    ReassembleTime = 0.25, -- เวลา tween ตอนรวม (ใช้สั้นเพราะรวมทันที)
}
-- load saved session attr if exist
local function loadSaved()
    local s = player:GetAttribute("ScatterR15_Params")
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
    pcall(function()
        player:SetAttribute("ScatterR15_Params", HttpService:JSONEncode({Force=params.Force, Spread=params.Spread, Spin=params.Spin}))
    end)
end
loadSaved()

-- ====== Character refs (respawn-safe) ======
local character, humanoid, hrp
local function setupCharacter(c)
    character = c or player.Character or player.CharacterAdded:Wait()
    humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
    hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
    -- try set network owner for better local physics (may be ignored)
    pcall(function() workspace:SetNetworkOwner(hrp, player) end)
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(function(c) task.wait(0.5); setupCharacter(c) end)

-- ====== UI Build (match image) ======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScatterR15UI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 360, 0, 300)
main.Position = UDim2.new(0.5, -180, 0.5, -150)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(24,24,24)
main.BackgroundTransparency = 0.15 -- โปร่งใสนิด ๆ ตามที่ต้องการ
main.BorderSizePixel = 0
main.ZIndex = 5
main.Active = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner", main); mainCorner.CornerRadius = UDim.new(0,10)

-- header (blue)
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,52)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(0,150,220)
local headerCorner = Instance.new("UICorner", header); headerCorner.CornerRadius = UDim.new(0,10)

-- title label (center-left)
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.03, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ ตัวกระจาย"

-- fold/menu button (top-left word "เมนู") - this is the only draggable hit area
local menuBtn = Instance.new("TextButton", header)
menuBtn.Name = "MenuBtn"
menuBtn.Size = UDim2.new(0, 72, 0, 36)
menuBtn.Position = UDim2.new(0.01, 0, 0.08, 0)
menuBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
menuBtn.TextColor3 = Color3.new(1,1,1)
menuBtn.Font = Enum.Font.SourceSansBold
menuBtn.TextSize = 14
menuBtn.Text = "เมนู"
local menuCorner = Instance.new("UICorner", menuBtn); menuCorner.CornerRadius = UDim.new(0,6)

-- status label (top-right)
local statusLabel = Instance.new("TextLabel", header)
statusLabel.Size = UDim2.new(0.28, -12, 1, 0)
statusLabel.Position = UDim2.new(0.6, 8, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
statusLabel.Text = "ปิด"

-- toggle enable button (top-right)
local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0, 100, 0, 36)
toggleBtn.Position = UDim2.new(1, -12, 0.08, 0)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.TextSize = 14
toggleBtn.Text = "เปิดระบบ"
local togCorner = Instance.new("UICorner", toggleBtn); togCorner.CornerRadius = UDim.new(0,6)

-- content frame (holds fields)
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -16, 1, -72)
content.Position = UDim2.new(0,8,0,64)
content.BackgroundTransparency = 1

local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1,0,0,28)
modeLabel.Position = UDim2.new(0,0,0,0)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.SourceSansBold
modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "โหมด: ตัวกระจายจริง"

local subText = Instance.new("TextLabel", content)
subText.Size = UDim2.new(1,0,0,18)
subText.Position = UDim2.new(0,0,0,30)
subText.BackgroundTransparency = 1
subText.Font = Enum.Font.SourceSans
subText.TextSize = 13
subText.TextColor3 = Color3.new(1,1,1)
subText.Text = "ปรับค่า (ค่าทั้งหมดเป็นตัวคูณ)"

-- field maker (positioned like image)
local function makeField(parent, y, labelText, default)
    local cont = Instance.new("Frame", parent)
    cont.Size = UDim2.new(1,0,0,44)
    cont.Position = UDim2.new(0,0,0,y)
    cont.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", cont)
    lbl.Size = UDim2.new(0.62, -8, 0, 28)
    lbl.Position = UDim2.new(0, 6, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = labelText
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", cont)
    box.Size = UDim2.new(0.34, -12, 0, 28)
    box.Position = UDim2.new(0.64, 6, 0, 8)
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
local fldSpread = makeField(content, 110, "ความกว้าง (Spread)", params.Spread)
local fldSpin = makeField(content, 160, "ความเร็วหมุน (Spin)", params.Spin)

local info = Instance.new("TextLabel", content)
info.Size = UDim2.new(1,-8,0,36)
info.Position = UDim2.new(0,8,1,-44)
info.BackgroundTransparency = 1
info.Font = Enum.Font.SourceSans
info.TextSize = 13
info.TextColor3 = Color3.new(1,1,1)
info.TextWrapped = true
info.Text = "กดเปิดระบบแล้วเริ่มเดิน → ตัวจะแตกเป็นชิ้นจริง (R15) เมื่อหยุดจะรวมกลับทันที"

-- initial textbox values
fldForce.box.Text = tostring(params.Force)
fldSpread.box.Text = tostring(params.Spread)
fldSpin.box.Text = tostring(params.Spin)

-- ====== Fold behavior (smooth expand/collapse) ======
local folded = false
local foldTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
menuBtn.MouseButton1Click:Connect(function()
    folded = not folded
    if folded then
        -- collapse: hide content, shrink
        for _,v in ipairs(main:GetChildren()) do
            if v ~= header then v.Visible = false end
        end
        TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,360,0,52)}):Play()
    else
        -- expand: show and restore size
        for _,v in ipairs(main:GetChildren()) do
            v.Visible = true
        end
        TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,360,0,300)}):Play()
    end
end)

-- ====== Drag only on menuBtn (hitbox = menuBtn text) ======
do
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function begin(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end
    local function update(input)
        if not dragging or not dragStart or not startPos then return end
        local delta = input.Position - dragStart
        local newX = startPos.X.Scale
        local newY = startPos.Y.Scale
        local newXoff = startPos.X.Offset + delta.X
        local newYoff = startPos.Y.Offset + delta.Y

        -- constrain to screen bounds (do not go off-screen)
        local screenW = workspace.CurrentCamera.ViewportSize.X
        local screenH = workspace.CurrentCamera.ViewportSize.Y
        local clampedX = math.clamp(newXoff, -screenW/2 + 30, screenW/2 - 30)
        local clampedY = math.clamp(newYoff, -screenH/2 + 30, screenH/2 - 30)

        main.Position = UDim2.new(newX, clampedX, newY, clampedY)
    end
    local function ended(input)
        dragging = false
        -- when released, per your choice: "เด้งกลับ" => we return to previous startPos when user requested bounce
        -- you requested "เด้งกลับตำแหน่งเดิม" so animate back to startPos
        if startPos then
            TweenService:Create(main, TweenInfo.new(0.18), {Position = startPos}):Play()
        end
    end

    menuBtn.InputBegan:Connect(begin)
    menuBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            ended(input)
        end
    end)
end

-- ====== Toggle enable/disable ======
local enabled = false
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    statusLabel.Text = enabled and "เปิด" or "ปิด"
    toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
end)

-- ====== Fields update ======
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

-- ====== Detach / Reattach logic (R15 true detach) ======
local savedMotors = {}      -- stores data to recreate motors later
local detachedParts = {}    -- list of BaseParts detached right now
local isDetached = false

local function collectMotor6Ds(char)
    local t = {}
    for _,v in ipairs(char:GetDescendants()) do
        if v:IsA("Motor6D") then table.insert(t,v) end
    end
    return t
end

-- pattern list to choose which motors to remove for R15 limbs
local detachPatterns = {"shoulder","hip","neck","waist","upper","lower","arm","leg","head","left","right"}
local function shouldDetachMotor(m)
    if not m or not m.Name then return false end
    local n = string.lower(m.Name)
    if n:find("root") and not n:find("rootjoint") then return false end
    if not m.Part0 or not m.Part1 then return false end
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
    for _,m in ipairs(collectMotor6Ds(character)) do
        if shouldDetachMotor(m) then
            table.insert(savedMotors, {
                Name = m.Name,
                Part0Name = m.Part0.Name,
                Part1Name = m.Part1.Name,
                C0 = m.C0,
                C1 = m.C1,
            })
            table.insert(detachedParts, m.Part1)
            pcall(function() m:Destroy() end)
        end
    end
end

local function recreateMotors()
    for _,d in ipairs(savedMotors) do
        local p0 = character:FindFirstChild(d.Part0Name, true) or character:FindFirstChild(d.Part0Name)
        local p1 = character:FindFirstChild(d.Part1Name, true) or character:FindFirstChild(d.Part1Name)
        if p0 and p1 then
            local m = Instance.new("Motor6D")
            m.Name = d.Name or ("Motor6D_"..tostring(math.random(1,9999)))
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

-- apply impulse + angular to detached real parts
local function impulseDetachedParts()
    if not hrp then return end
    for _,p in ipairs(detachedParts) do
        if p and p.Parent then
            p.Anchored = false
            p.CanCollide = true
            -- direction outward relative to hrp + random spread
            local dir = (p.Position - hrp.Position)
            if dir.Magnitude == 0 then dir = Vector3.new(0,1,0) end
            dir = dir.Unit
            local spreadFactor = math.max(0.1, params.Spread / 10)
            local rand = Vector3.new((math.random()-0.5)*2*spreadFactor, (math.random()*0.8 + 0.2)*spreadFactor, (math.random()-0.5)*2*spreadFactor)
            local forceVec = (dir + rand).Unit * (params.Force * (p:GetMass() or 1))
            -- Apply impulse (works client-side if network owner set)
            p:ApplyImpulse(forceVec)
            -- add angular
            local bav = Instance.new("BodyAngularVelocity")
            bav.MaxTorque = Vector3.new(1e6,1e6,1e6)
            bav.P = 1000
            bav.AngularVelocity = Vector3.new(rand.X, rand.Y, rand.Z) * (params.Spin or 1)
            bav.Parent = p
            Debris:AddItem(bav, 2)
        end
    end
end

-- reattach immediately: tween parts to hrp then recreate motors
local function reattachImmediate()
    if #detachedParts == 0 then
        isDetached = false
        return
    end
    -- stop forces and instantly move parts to HRP (you requested immediate)
    for _,p in ipairs(detachedParts) do
        if p and p.Parent then
            -- destroy forces
            for _,ch in ipairs(p:GetChildren()) do
                if ch:IsA("BodyAngularVelocity") or ch:IsA("BodyVelocity") or ch:IsA("BodyForce") then
                    pcall(function() ch:Destroy() end)
                end
            end
            -- set CFrame to HRP immediately (instant)
            if hrp then
                p.CFrame = hrp.CFrame * CFrame.new(0,0,0)
            end
        end
    end
    -- recreate motors
    recreateMotors()
    -- restore base parts properties (non-collidable original parts)
    for _,pt in ipairs(character:GetDescendants()) do
        if pt:IsA("BasePart") then
            pcall(function() pt.Transparency = 0; pt.CanCollide = false end)
        end
    end
    isDetached = false
end

-- safe fallback (in case recreation fails)
local function safeFallbackReset()
    if humanoid then
        pcall(function() humanoid.Health = 0 end)
    end
end

-- ====== Movement detection & orchestration ======
local wasMoving = false
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
        -- start moving: detach + impulse
        wasMoving = true
        saveAndRemoveMotors()
        if #detachedParts > 0 then
            isDetached = true
            impulseDetachedParts()
        end
    elseif not moving and wasMoving then
        -- stopped: reattach immediate
        wasMoving = false
        if isDetached then
            reattachImmediate()
        end
    end
end)

-- ====== UI behavior extras ======
-- ensure UI persists on respawn
screenGui.Parent = player:WaitForChild("PlayerGui")

-- if user dies, UI remains and logic continues for new character
player.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    setupCharacter(c)
end)

-- cleanup on destroy
screenGui.Destroying:Connect(function()
    if #savedMotors > 0 then recreateMotors() end
end)

print("[ScatterR15_UI] loaded - mobile ready")
