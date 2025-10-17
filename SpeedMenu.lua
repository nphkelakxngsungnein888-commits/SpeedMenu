-- SpeedExplodeWalk.lua
-- UI + Explode-Walk mode (ตัวกระจายเมื่อเดิน)
-- ตามสเปกผู้ใช้: ทุกชิ้นส่วนแยกจริง ชนวัตถุได้ หมุนได้ กลับคืนเมื่อหยุดเดิน
-- UI อยู่ใน CoreGui และคงอยู่เมื่อ respawn

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- ----- Character refs (respawn safe) -----
local character, hrp, humanoid
local function setupCharacter(chr)
    character = chr or player.Character or player.CharacterAdded:Wait()
    hrp = character:WaitForChild("HumanoidRootPart")
    humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

-- ----- Default parameters (ปรับได้จาก UI) -----
local params = {
    Force = 50,           -- แรงกระเด้ง (Impulse magnitude base)
    Spread = 1.5,         -- ความกว้างการกระจาย (1 = แคบ, ยิ่งใหญ่ยิ่งกระจายกว้าง)
    Delay = 0.5,          -- หน่วงเวลา (วินาที) ระหว่างการแตกซ้ำ (ถ้ายังคงเดินอยู่)
    CloneLifetime = 6,    -- เวลาชิ้นส่วนคงอยู่ (วินาที) หากไม่ได้รวมคืนก่อน
    RespawnSafe = true,   -- ถ้าตั้ง true จะไม่ BreakJoints ตัวจริง (ตัวจริงซ่อนและคืน)
}

-- ----- UI Build (CoreGui) -----
local gui = Instance.new("ScreenGui")
gui.Name = "ExplodeWalkUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Name = "Main"
main.Size = UDim2.new(0, 300, 0, 260)
main.Position = UDim2.new(0.03,0,0.15,0)
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.Active = true
main.Draggable = true
main.BorderSizePixel = 0

-- header (blue)
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,46)
header.BackgroundColor3 = Color3.fromRGB(0,150,220)
header.Position = UDim2.new(0,0,0,0)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6,0,1,0)
title.Position = UDim2.new(0.02,0,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ ตัวกระจาย (Explode Walk)"

local foldBtn = Instance.new("TextButton", header)
foldBtn.Size = UDim2.new(0,40,0,34)
foldBtn.Position = UDim2.new(0.98,-8,0,6)
foldBtn.AnchorPoint = Vector2.new(1,0)
foldBtn.Text = "—"
foldBtn.Font = Enum.Font.GothamBold
foldBtn.TextSize = 18
foldBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
foldBtn.TextColor3 = Color3.new(1,1,1)

-- toggle button
local statusLabel = Instance.new("TextLabel", header)
statusLabel.Size = UDim2.new(0.28, -10, 1, 0)
statusLabel.Position = UDim2.new(0.7, 4, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
statusLabel.Text = "ปิด"

local toggleBtn = Instance.new("TextButton", header)
toggleBtn.Size = UDim2.new(0,84,0,30)
toggleBtn.Position = UDim2.new(1,-92,0,8)
toggleBtn.AnchorPoint = Vector2.new(1,0)
toggleBtn.Text = "เปิดระบบ"
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextSize = 14
toggleBtn.BackgroundColor3 = Color3.fromRGB(36,36,36)
toggleBtn.TextColor3 = Color3.new(1,1,1)

-- content area
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,0,1,-46)
content.Position = UDim2.new(0,0,0,46)
content.BackgroundTransparency = 1

-- mode label (only one mode)
local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1, -16, 0, 28)
modeLabel.Position = UDim2.new(0, 8, 0, 6)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "โหมด: ตัวกระจาย"

-- fields container (scroll)
local fieldsOuter = Instance.new("Frame", content)
fieldsOuter.Size = UDim2.new(1, -16, 0, 180)
fieldsOuter.Position = UDim2.new(0, 8, 0, 44)
fieldsOuter.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", fieldsOuter)
scroll.Size = UDim2.new(1,0,1,0)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1

local uiList = Instance.new("UIListLayout", scroll)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0,6)

local function field(labelText, default)
    local container = Instance.new("Frame", scroll)
    container.Size = UDim2.new(1,0,0,54)
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
    box.Size = UDim2.new(0.38, -8, 0, 28)
    box.Position = UDim2.new(0.62, 6, 0, 6)
    box.BackgroundColor3 = Color3.fromRGB(40,40,40)
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.TextColor3 = Color3.new(1,1,1)
    box.ClearTextOnFocus = false
    box.Text = tostring(default)

    uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,uiList.AbsoluteContentSize.Y + 6)
    end)

    return {container = container, label = lbl, box = box}
end

local fldForce = field("แรงกระจาย (Force)", params.Force)
local fldSpread = field("ความกว้างกระจาย (Spread)", params.Spread)
local fldDelay = field("หน่วงเวลา (Delay, วินาที)", params.Delay)

-- make visible (all fields visible for this single-mode UI)
fldForce.container.Visible = true
fldSpread.container.Visible = true
fldDelay.container.Visible = true

-- fold behavior
local folded = false
foldBtn.MouseButton1Click:Connect(function()
    folded = not folded
    if folded then
        -- collapse
        for _,v in ipairs(main:GetChildren()) do
            if v ~= header then v.Visible = false end
        end
        main.Size = UDim2.new(0,300,0,46)
        foldBtn.Text = "+"
    else
        for _,v in ipairs(main:GetChildren()) do
            if v ~= header then v.Visible = true end
        end
        main.Size = UDim2.new(0,300,0,260)
        foldBtn.Text = "—"
    end
end)

-- toggle system
local enabled = false
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    statusLabel.Text = enabled and "เปิด" or "ปิด"
    toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
    if not enabled then
        -- restore humanoid defaults
        if humanoid then pcall(function() humanoid.WalkSpeed = 16 end) end
    end
end)

-- update params on focus lost
fldForce.box.FocusLost:Connect(function()
    local n = tonumber(fldForce.box.Text)
    if n and n > 0 then params.Force = n else fldForce.box.Text = tostring(params.Force) end
end)
fldSpread.box.FocusLost:Connect(function()
    local n = tonumber(fldSpread.box.Text)
    if n and n > 0 then params.Spread = n else fldSpread.box.Text = tostring(params.Spread) end
end)
fldDelay.box.FocusLost:Connect(function()
    local n = tonumber(fldDelay.box.Text)
    if n and n >= 0 then params.Delay = n else fldDelay.box.Text = tostring(params.Delay) end
end)

-- ensure UI persists on respawn
player.CharacterAdded:Connect(function(c)
    task.delay(0.5, function()
        setupCharacter(c)
    end)
end)

-- ----- Explode logic -----
local isExploded = false
local lastExplodeTick = 0
local activeClones = {} -- store clones for cleanup

-- helper: get visible body parts to clone (exclude accessories, get parts with size)
local function getBodyParts(rootChar)
    local parts = {}
    for _,p in pairs(rootChar:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 1 and p.Size.Magnitude > 0.05 then
            -- exclude accessories' Handles? we'll include but ensure CanCollide true later
            table.insert(parts, p)
        end
    end
    return parts
end

-- helper: spawn clones with physics impulse
local function spawnClones()
    if not character or not hrp then return end
    local parts = getBodyParts(character)
    if #parts == 0 then return end

    -- hide original character (make invisible and non-collidable)
    for _,p in ipairs(parts) do
        p.Transparency = 1
        p.CanCollide = false
    end
    if hrp then hrp.Transparency = 1; hrp.CanCollide = false end
    if humanoid then pcall(function() humanoid.PlatformStand = true end) end

    local clones = {}
    for _,p in ipairs(parts) do
        local c = p:Clone()
        c.CFrame = p.CFrame
        c.Parent = workspace
        c.CanCollide = true
        -- ensure unanchored so physics apply
        c.Anchored = false

        -- set custom physical properties lightly influenced by size (optional)
        pcall(function()
            c.CustomPhysicalProperties = PhysicalProperties.new(1, c.CustomPhysicalProperties.Friction, c.CustomPhysicalProperties.Elasticity)
        end)

        -- randomize direction within spread
        local dir = (c.Position - hrp.Position)
        if dir.Magnitude == 0 then dir = Vector3.new(0,1,0) end
        dir = dir.Unit

        -- apply randomness based on spread
        local rand = Vector3.new((math.random()-0.5)*params.Spread, (math.random()*0.8 + 0.2)*params.Spread, (math.random()-0.5)*params.Spread)
        local forceVec = (dir + rand).Unit * (params.Force * (c:GetMass() or 1))

        -- apply impulse (scaled by part mass)
        pcall(function()
            c:ApplyImpulse(forceVec)
        end)

        -- apply angular velocity for spin
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(1e6,1e6,1e6)
        bav.AngularVelocity = Vector3.new(rand.X, rand.Y, rand.Z) * (params.Force/10)
        bav.P = 1000
        bav.Parent = c

        table.insert(clones, c)

        -- schedule automatic cleanup of clone after lifetime (in case reassemble not triggered)
        task.delay(params.CloneLifetime, function()
            if c and c.Parent then
                pcall(function()
                    if bav and bav.Parent then bav:Destroy() end
                    c:Destroy()
                end)
            end
        end)
    end

    -- store clones list
    table.insert(activeClones, clones)
    return clones
end

-- cleanup clones and restore character
local function restoreCharacter()
    -- destroy all clones
    for _,clist in ipairs(activeClones) do
        for _,c in ipairs(clist) do
            pcall(function()
                if c and c.Parent then c:Destroy() end
            end)
        end
    end
    activeClones = {}

    -- restore original parts (visibility and collisions)
    if character and character.Parent then
        for _,p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Transparency = 0
                p.CanCollide = false -- keep original not collidable to avoid physics issues
            end
        end
        if humanoid then pcall(function() humanoid.PlatformStand = false end) end
        -- move character root to hrp current position (if any clones remain, we don't try to set to clone pos)
        if hrp then
            pcall(function()
                -- keep HRP where it is (it was invisible). better to teleport to last HRP pos (no change)
                hrp.Transparency = 0
                hrp.CanCollide = false
            end)
        end
    end
    isExploded = false
end

-- main logic: trigger on walking
RunService.RenderStepped:Connect(function(dt)
    if not enabled then return end
    if not character or not humanoid or not hrp then return end

    -- read updated params from UI boxes (live update)
    local f = tonumber(fldForce.box.Text)
    if f and f > 0 then params.Force = f end
    local s = tonumber(fldSpread.box.Text)
    if s and s > 0 then params.Spread = s end
    local d = tonumber(fldDelay.box.Text)
    if d and d >= 0 then params.Delay = d end

    local move = humanoid.MoveDirection
    local moving = move.Magnitude > 0.01

    if moving then
        -- if not exploded yet or enough delay passed, explode
        local now = tick()
        if (not isExploded) or (now - lastExplodeTick >= params.Delay) then
            -- spawn clones and hide original
            spawnClones()
            isExploded = true
            lastExplodeTick = now
        end
    else
        -- not moving: restore if exploded
        if isExploded then
            restoreCharacter()
        end
    end
end)

-- ensure restore on GUI destroy or when disabling
gui.Destroying:Connect(function()
    restoreCharacter()
end)

-- ensure restore on script stop/unload (if available)
-- (no DataStore; UI persists on respawn)
-- initial state
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    statusLabel.Text = enabled and "เปิด" or "ปิด"
    toggleBtn.Text = enabled and "ปิดระบบ" or "เปิดระบบ"
    if not enabled then
        restoreCharacter()
    end
end)

-- expose quick restore on double-tap header (convenience)
header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        restoreCharacter()
    end
end)

-- Keep GUI even after respawn (ResetOnSpawn=false ensures UI persists)
-- Also reconnect touch events if needed when character respawn
player.CharacterAdded:Connect(function(c)
    task.delay(0.4, function()
        setupCharacter(c)
    end)
end)

-- End of script
