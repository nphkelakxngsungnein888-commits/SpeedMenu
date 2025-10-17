-- ScatterUI.lua
-- LocalScript แบบเดียวจบ: UI + Explode-on-walk (ฟิสิกส์จริง) + Tween-reassemble
-- วางใน StarterGui (หรือ loadstring) -> ทำงานฝั่งผู้เล่น

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Respawn-safe character references
local character, hrp, humanoid
local function setupCharacter(chr)
    character = chr or player.Character or player.CharacterAdded:Wait()
    hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
    humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(function(c) setupCharacter(c) end)

-- PARAMETERS (defaults)
local params = {
    Force = 50,          -- แรงกระเด็น (ฐาน)
    Spread = 10,         -- ความกว้างกระจาย (ค่าที่ user ป้อน -> ยิ่งมากยิ่งกระจายกว้าง)
    Spin = 2,            -- ความเร็วหมุน base multiplier
    CloneLifetime = 10,  -- หากไม่รวมคืน อนุญาตให้ clone อยู่เท่าไหร่ (s) -> ปกติเราจะรวมคืน
    ReassembleTime = 0.6 -- เวลาที่ใช้ดูดกลับเข้ามารวม (Tween time)
}

-- load saved attributes if exist
local function loadSaved()
    local a = player:GetAttribute("Scatter_Params")
    if a then
        local ok, tab = pcall(function() return game:GetService("HttpService"):JSONDecode(a) end)
        if ok and type(tab)=="table" then
            params.Force = tonumber(tab.Force) or params.Force
            params.Spread = tonumber(tab.Spread) or params.Spread
            params.Spin = tonumber(tab.Spin) or params.Spin
        end
    end
end
local function saveParams()
    local ok, json = pcall(function()
        return game:GetService("HttpService"):JSONEncode({Force = params.Force, Spread = params.Spread, Spin = params.Spin})
    end)
    if ok then player:SetAttribute("Scatter_Params", json) end
end
loadSaved()

-- UI BUILD (center, draggable)
local screen = Instance.new("ScreenGui")
screen.Name = "ScatterUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", screen)
main.Name = "Main"
main.Size = UDim2.new(0, 380, 0, 300)
main.Position = UDim2.new(0.5, -190, 0.5, -150)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.AutomaticSize = Enum.AutomaticSize.None
main.ZIndex = 2
main.Visible = true

-- Rounded corners
local uiCorner = Instance.new("UICorner", main)
uiCorner.CornerRadius = UDim.new(0,8)

-- header blue bar
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,54)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(0,150,220)
header.BorderSizePixel = 0

local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0,8)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.02, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ ตัวกระจาย"

-- fold button (left)
local foldBtn = Instance.new("TextButton", header)
foldBtn.Size = UDim2.new(0,40,0,34)
foldBtn.Position = UDim2.new(0.01, 0, 0.05, 0)
foldBtn.AnchorPoint = Vector2.new(0,0)
foldBtn.Text = "เมนู"
foldBtn.Font = Enum.Font.SourceSansBold
foldBtn.TextSize = 14
foldBtn.BackgroundColor3 = Color3.fromRGB(15,15,15)
foldBtn.TextColor3 = Color3.new(1,1,1)
local foldCorner = Instance.new("UICorner", foldBtn); foldCorner.CornerRadius = UDim.new(0,6)

-- status label + toggle (right)
local statusLabel = Instance.new("TextLabel", header)
statusLabel.Size = UDim2.new(0.25, -10, 1, 0)
statusLabel.Position = UDim2.new(0.6, 8, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
statusLabel.Text = "ปิด"

local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0,90,0,30)
toggleBtn.Position = UDim2.new(0.985, 0, 0.07, 0)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Text = "เปิดระบบ"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleBtn.TextColor3 = Color3.new(1,1,1)
local toggleCorner = Instance.new("UICorner", toggleBtn); toggleCorner.CornerRadius = UDim.new(0,6)

-- content frame (below header)
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -12, 1, -64)
content.Position = UDim2.new(0,6,0,64)
content.BackgroundTransparency = 1

-- mode label (center)
local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1,0,0,30)
modeLabel.Position = UDim2.new(0,0,0,4)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.SourceSansBold
modeLabel.TextSize = 18
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "โหมด: ตัวกระจาย"

-- fields title
local subLabel = Instance.new("TextLabel", content)
subLabel.Size = UDim2.new(1,0,0,20)
subLabel.Position = UDim2.new(0,0,0,40)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.SourceSans
subLabel.TextSize = 14
subLabel.TextColor3 = Color3.new(1,1,1)
subLabel.Text = "ปรับค่า"

-- fields area with scrolling
local fieldsOuter = Instance.new("Frame", content)
fieldsOuter.Size = UDim2.new(1, 0, 0, 150)
fieldsOuter.Position = UDim2.new(0, 0, 0, 64)
fieldsOuter.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", fieldsOuter)
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1
local uiList = Instance.new("UIListLayout", scroll)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0,8)

local function createField(labelText, default)
    local container = Instance.new("Frame", scroll)
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(0.6, -8, 0, 28)
    lbl.Position = UDim2.new(0, 6, 0, 10)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText

    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(0.36, -12, 0, 28)
    box.Position = UDim2.new(0.64, 6, 0, 10)
    box.BackgroundColor3 = Color3.fromRGB(40,40,40)
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.TextColor3 = Color3.new(1,1,1)
    box.ClearTextOnFocus = true
    box.Text = tostring(default)
    return {container = container, label = lbl, box = box}
end

local fldForce = createField("แรงกระจาย (Force)", params.Force)
local fldSpread = createField("ความกว้างกระจาย (Spread)", params.Spread)
local fldSpin = createField("ความเร็วหมุน (Spin)", params.Spin)

-- update canvas size
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 6)
end)

-- info / help text bottom
local info = Instance.new("TextLabel", content)
info.Size = UDim2.new(1, -8, 0, 36)
info.Position = UDim2.new(0, 8, 1, -40)
info.BackgroundTransparency = 1
info.Font = Enum.Font.SourceSans
info.TextSize = 13
info.TextColor3 = Color3.new(1,1,1)
info.TextWrapped = true
info.Text = "เมื่อเปิดระบบและเริ่มเดิน ตัวจะระเบิดเป็นชิ้นส่วนทุกครั้งที่เริ่มเดิน และชิ้นส่วนจะดูดกลับเมื่อหยุดเดิน"

-- fold animation tweens
local folded = false
local foldTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function foldUI()
    if folded then
        -- expand
        for _,v in ipairs(main:GetChildren()) do if v ~= header then v.Visible = true end end
        TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,380,0,300)}):Play()
        folded = false
        foldBtn.Text = "เมนู"
    else
        -- collapse to header only (keep header visible)
        for _,v in ipairs(main:GetChildren()) do if v ~= header then v.Visible = false end end
        TweenService:Create(main, foldTweenInfo, {Size = UDim2.new(0,160,0,54)}):Play()
        folded = true
        foldBtn.Text = "เมนู"
    end
end
foldBtn.MouseButton1Click:Connect(foldUI)

-- toggle system
local enabled = false
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    statusLabel.Text = enabled and "เปิด" or "ปิด"
    toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
    if not enabled then
        -- restore if currently exploded
        -- restoreCharacter() will be called by main loop when detecting not moving
    end
end)

-- handle field updates on FocusLost or Enter
fldForce.box.FocusLost:Connect(function(enter)
    local v = tonumber(fldForce.box.Text)
    if v and v > 0 then params.Force = v; saveParams() else fldForce.box.Text = tostring(params.Force) end
end)
fldSpread.box.FocusLost:Connect(function(enter)
    local v = tonumber(fldSpread.box.Text)
    if v and v > 0 then params.Spread = v; saveParams() else fldSpread.box.Text = tostring(params.Spread) end
end)
fldSpin.box.FocusLost:Connect(function(enter)
    local v = tonumber(fldSpin.box.Text)
    if v and v >= 0 then params.Spin = v; saveParams() else fldSpin.box.Text = tostring(params.Spin) end
end)

-- also accept Enter press
local function textboxEnterHandler(box)
    box.FocusLost:Wait()
end

-- EXPLode logic
local exploded = false
local lastExplodeTick = 0
local activeClones = {} -- list of clones (tables of parts)
local originalState = {} -- store original part states to restore

local function getBodyPartsToClone(char)
    local parts = {}
    for _,v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and v.Transparency < 1 and v.Size.Magnitude > 0.05 then
            table.insert(parts, v)
        end
    end
    return parts
end

local function hideOriginalParts(parts)
    originalState = {}
    for _,p in ipairs(parts) do
        originalState[p] = {Transparency = p.Transparency, CanCollide = p.CanCollide}
        p.Transparency = 1
        p.CanCollide = false
    end
    if hrp then
        originalState[hrp] = {Transparency = hrp.Transparency, CanCollide = hrp.CanCollide}
        hrp.Transparency = 1
        hrp.CanCollide = false
    end
    if humanoid then pcall(function() humanoid.PlatformStand = true end) end
end

local function restoreOriginalParts()
    if not character then return end
    for p,st in pairs(originalState) do
        pcall(function()
            if p and p.Parent then
                p.Transparency = st.Transparency or 0
                p.CanCollide = st.CanCollide or false
            end
        end)
    end
    originalState = {}
    if humanoid then pcall(function() humanoid.PlatformStand = false end) end
end

local function spawnPieceClone(part)
    local c = part:Clone()
    c.CFrame = part.CFrame
    c.Parent = workspace
    c.Anchored = false
    c.CanCollide = true
    -- ensure physics properties are reasonable
    pcall(function() c.CustomPhysicalProperties = PhysicalProperties.new(1, c.CustomPhysicalProperties.Friction, c.CustomPhysicalProperties.Elasticity) end)
    return c
end

local function applyPhysicsToClone(c)
    -- direction away from hrp center with randomness based on Spread
    local dir = (c.Position - (hrp and hrp.Position or c.Position)).Unit
    if not dir or dir.Magnitude ~= dir.Magnitude then
        dir = Vector3.new(0,1,0)
    end
    local rand = Vector3.new((math.random()-0.5)*2, (math.random()*0.8 + 0.2), (math.random()-0.5)*2)
    rand = rand * (params.Spread / 10)
    local forceVec = (dir + rand)
    if forceVec.Magnitude == 0 then forceVec = Vector3.new(0,1,0) end
    forceVec = forceVec.Unit * (params.Force * (c:GetMass() or 1))

    -- Apply impulse (try method, fallback)
    pcall(function() c:ApplyImpulse(forceVec) end)
    -- Add angular velocity
    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(rand.X, rand.Y, rand.Z) * (params.Spin)
    bav.MaxTorque = Vector3.new(1e6,1e6,1e6)
    bav.P = 1000
    bav.Parent = c
    return bav
end

local function spawnExplode()
    if not character or not hrp then return end
    -- if previous clones exist, destroy them (we treat explode per "start moving" -> single explosion)
    for _,clist in ipairs(activeClones) do
        for _,p in ipairs(clist) do p:Destroy() end
    end
    activeClones = {}

    local parts = getBodyPartsToClone(character)
    if #parts == 0 then return end

    hideOriginalParts(parts)

    local clones = {}
    for _,p in ipairs(parts) do
        local c = spawnPieceClone(p)
        local bav = applyPhysicsToClone(c)
        table.insert(clones, {part = c, bav = bav})
        -- schedule lifetime destroy as safety
        task.delay(params.CloneLifetime, function()
            pcall(function()
                if c and c.Parent then
                    if bav and bav.Parent then bav:Destroy() end
                    c:Destroy()
                end
            end)
        end)
    end
    table.insert(activeClones, clones)
    exploded = true
    lastExplodeTick = tick()
end

-- reassemble: Tween all clones to hrp then destroy and restore original
local function reassemble()
    if not exploded then return end
    -- collect all clones (flatten)
    local toTween = {}
    for _,clist in ipairs(activeClones) do
        for _,entry in ipairs(clist) do
            if entry and entry.part and entry.part.Parent then
                table.insert(toTween, entry)
            end
        end
    end
    if #toTween == 0 then
        restoreOriginalParts()
        exploded = false
        activeClones = {}
        return
    end

    -- Tween each clone CFrame to HRP.CFrame (with small offset based on original part)
    local tweens = {}
    for _,entry in ipairs(toTween) do
        local c = entry.part
        local bav = entry.bav
        pcall(function() if bav and bav.Parent then bav:Destroy() end end)
        local targetC0 = hrp and hrp.CFrame or CFrame.new(0,0,0)
        local target = targetC0 * CFrame.new(0, 0.5, 0) -- go near root
        local ti = TweenInfo.new(params.ReassembleTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local success, t = pcall(function() return TweenService:Create(c, ti, {CFrame = target}) end)
        if success and t then
            t:Play()
            table.insert(tweens, t)
        else
            -- immediate set if tween can't be made
            pcall(function() c.CFrame = target end)
        end
    end

    -- wait for tween time then destroy clones and restore original parts
    task.delay(params.ReassembleTime + 0.05, function()
        for _,entry in ipairs(toTween) do
            pcall(function()
                if entry.part and entry.part.Parent then entry.part:Destroy() end
            end)
        end
        activeClones = {}
        restoreOriginalParts()
        exploded = false
    end)
end

-- movement detection: explode on move start (transition from not moving to moving)
local wasMoving = false
RunService.RenderStepped:Connect(function()
    if not humanoid or not hrp then return end
    -- read params live from UI textboxes (safe parse)
    local vf = tonumber(fldForce.box.Text); if vf and vf>0 then params.Force = vf end
    local vs = tonumber(fldSpread.box.Text); if vs and vs>0 then params.Spread = vs end
    local vs2 = tonumber(fldSpin.box.Text); if vs2 and vs2>=0 then params.Spin = vs2 end

    local moveDir = humanoid.MoveDirection
    local moving = (moveDir and moveDir.Magnitude > 0.01) and enabled

    if moving and not wasMoving then
        -- started moving: explode immediately
        spawnExplode()
        wasMoving = true
    elseif not moving and wasMoving then
        -- stopped moving: reassemble smoothly
        reassemble()
        wasMoving = false
    end
end)

-- Cleanup when GUI destroyed
screen.Destroying:Connect(function()
    -- destroy any clones
    for _,clist in ipairs(activeClones) do
        for _,e in ipairs(clist) do
            pcall(function() if e.part and e.part.Parent then e.part:Destroy() end end)
        end
    end
    restoreOriginalParts()
end)

-- persist UI visibility / center location: center by default, draggable allowed
-- ensure UI persists across respawn (ResetOnSpawn=false already)
-- initial textbox values reflect params
fldForce.box.Text = tostring(params.Force)
fldSpread.box.Text = tostring(params.Spread)
fldSpin.box.Text = tostring(params.Spin)

-- convenience: double-click header (right-click) to force reassemble
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        reassemble()
    end
end)

-- Done
