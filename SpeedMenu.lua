-- SpeedHub.lua
-- Single-file loader-friendly script (put on GitHub and load via loadstring(game:HttpGet(...))())
-- Features:
--  - Modular menu system (can add menus later via addMenu)
--  - Speed menu with 10 modes: WalkSpeed, Velocity, CFrame, TP, Impulse, BodyVelocity,
--    LinearVelocity, AssemblyLinearVelocity, Tween, Lerp
--  - Each mode shows only its configurable multiplier fields (labels + TextBox)
--  - GUI: draggable, foldable, persistent across respawn (values kept in script memory)
--  - All numeric inputs treated as MULTIPLIERS (e.g., 2 => 2x base)
--  - Use in Studio/Private games only

-- IMPORTANT: Use responsibly. This manipulates character physics/position.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer

-- =========================
-- Character refs (respawn-safe)
-- =========================
local char, hrp, hum
local function setupChar(c)
    char = c or plr.Character or plr.CharacterAdded:Wait()
    hrp = char:WaitForChild("HumanoidRootPart")
    hum = char:FindFirstChildOfClass("Humanoid")
end
if plr.Character then setupChar(plr.Character) end
plr.CharacterAdded:Connect(function(c) setupChar(c) end)

-- =========================
-- Base values (these are the "1x" references)
-- =========================
local BASE = {
    WalkSpeed = 16,
    Velocity = 16,
    CFrameStep = 1,
    TPDistance = 3,
    ImpulsePower = 60,
    BodyVelocityPower = 40,
    LinearVelocityPower = 40,
    AssemblySpeed = 16,
    TweenDistance = 3,
    TweenTime = 0.08,
    LerpStep = 1,
}

-- =========================
-- Modes definition: fields are multipliers (user input multiplies BASE)
-- fields = ordered list of {name = string, def = number, hint = string}
-- modes[name].active = bool
-- modes[name].fields values are stored in values[name][fieldName]
-- =========================
local modes = {
    WalkSpeed = { active = false, fields = { {name="speedMult", def=2, hint="Multiply WalkSpeed (e.g. 2 = 2x)"} } },
    Velocity = { active = false, fields = { {name="forceMult", def=1.5, hint="Multiply velocity base"}, {name="maxSpeedMult", def=6, hint="Max speed cap multiplier (applied to base)"} } },
    CFrame = { active = false, fields = { {name="stepMult", def=1, hint="Distance per frame (multiplier)"}, {name="delayMult", def=0, hint="Optional tiny delay multiplier"} } },
    TP = { active = false, fields = { {name="tpDistMult", def=1, hint="Teleport distance multiplier (studs)"} , {name="tpDelayMult", def=1, hint="Delay multiplier between tp steps (smaller = faster)"} } },
    Impulse = { active = false, fields = { {name="powerMult", def=2, hint="Impulse power multiplier"}, {name="intervalMult", def=1, hint="Interval multiplier (smaller = more frequent)"} } },
    BodyVelocity = { active = false, fields = { {name="bvPowerMult", def=1, hint="BodyVelocity power multiplier"}, {name="bvMaxForceMult", def=1, hint="MaxForce multiplier"} } },
    LinearVelocity = { active = false, fields = { {name="lvVelMult", def=1, hint="LinearVelocity speed multiplier"}, {name="lvMaxForceMult", def=1, hint="MaxForce multiplier"} } },
    AssemblyLinearVelocity = { active = false, fields = { {name="asmMult", def=1, hint="Assembly velocity multiplier"}, {name="limitY", def=1, hint="Limit Y axis? (1 = yes, 0 = no)"} } },
    Tween = { active = false, fields = { {name="tweenTimeMult", def=1, hint="Tween time multiplier (smaller = faster)"}, {name="tweenDistMult", def=1, hint="Tween distance multiplier"} } },
    Lerp = { active = false, fields = { {name="lerpAlphaMult", def=1, hint="Alpha multiplier (0-1 range scaled), higher = snappier"}, {name="lerpStepMult", def=1, hint="Step distance multiplier"} } },
}

-- Maintain an ordered mode list for UI consistency
local modeList = {"WalkSpeed","Velocity","CFrame","TP","Impulse","BodyVelocity","LinearVelocity","AssemblyLinearVelocity","Tween","Lerp"}
local currentModeIndex = 1

-- runtime storage for numeric values (multipliers)
local values = {}
for name,info in pairs(modes) do
    values[name] = {}
    for _,field in ipairs(info.fields) do
        values[name][field.name] = field.def
    end
end

-- helpers
local function safeNum(s, fallback)
    local n = tonumber(s)
    if not n or n ~= n then return fallback end
    return n
end

-- mover objects
local activeBV, activeLV, activeLVAtt
local function cleanupMovers()
    if activeBV and activeBV.Parent then pcall(function() activeBV:Destroy() end) end
    activeBV = nil
    if activeLV and activeLV.Parent then pcall(function() activeLV:Destroy() end) end
    activeLV = nil
    if activeLVAtt and activeLVAtt.Parent then pcall(function() activeLVAtt:Destroy() end) end
    activeLVAtt = nil
end

-- =========================
-- Modular menu system (allows addMenu in future)
-- =========================
local MENUS = {}
local function addMenu(id, buildFunc)
    -- store builder so future extension possible; builder returns a frame or table
    MENUS[id] = buildFunc
end

-- =========================
-- Build Speed Menu UI (ScreenGui in CoreGui)
-- =========================
local GUI_NAME = "SpeedHub_MAIN"
pcall(function() if game.CoreGui:FindFirstChild(GUI_NAME) then game.CoreGui[GUI_NAME]:Destroy() end end)

local screen = Instance.new("ScreenGui")
screen.Name = GUI_NAME
screen.ResetOnSpawn = false
screen.Parent = game.CoreGui

local main = Instance.new("Frame", screen)
main.Name = "MainFrame"
main.Size = UDim2.new(0, 380, 0, 460)
main.Position = UDim2.new(0, 30, 0, 80)
main.BackgroundColor3 = Color3.fromRGB(22,34,56)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

-- header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,46)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3 = Color3.fromRGB(0,125,215)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(0.6,0,1,0)
title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = "⚡ SpeedHub"

local status = Instance.new("TextLabel", header)
status.Size = UDim2.new(0.35,-8,1,0)
status.Position = UDim2.new(0.6,8,0,0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.TextSize = 18
status.TextColor3 = Color3.new(1,1,1)
status.TextXAlignment = Enum.TextXAlignment.Right
status.Text = "OFF"

local globalToggleBtn = Instance.new("TextButton", header)
globalToggleBtn.Size = UDim2.new(0,82,0,30)
globalToggleBtn.Position = UDim2.new(1,-92,0,8)
globalToggleBtn.AnchorPoint = Vector2.new(1,0)
globalToggleBtn.Text = "Toggle"
globalToggleBtn.Font = Enum.Font.Gotham
globalToggleBtn.TextSize = 14
globalToggleBtn.BackgroundColor3 = Color3.fromRGB(36,36,36)
globalToggleBtn.TextColor3 = Color3.new(1,1,1)

local collapseBtn = Instance.new("TextButton", header)
collapseBtn.Size = UDim2.new(0,32,0,32)
collapseBtn.Position = UDim2.new(0,6,0,6)
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 20
collapseBtn.Text = "—"
collapseBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
collapseBtn.TextColor3 = Color3.new(1,1,1)

-- content
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,0,1,-46)
content.Position = UDim2.new(0,0,0,46)
content.BackgroundTransparency = 1

-- Mode label and dropdown
local modeLabel = Instance.new("TextLabel", content)
modeLabel.Size = UDim2.new(1,-20,0,28)
modeLabel.Position = UDim2.new(0,10,0,8)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.new(1,1,1)
modeLabel.Text = "Mode: " .. modeList[currentModeIndex]

local modeToggle = Instance.new("TextButton", content)
modeToggle.Size = UDim2.new(0,28,0,28)
modeToggle.Position = UDim2.new(1,-38,0,8)
modeToggle.Text = "▾"
modeToggle.Font = Enum.Font.SourceSans
modeToggle.TextSize = 18
modeToggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
modeToggle.TextColor3 = Color3.new(1,1,1)

-- scroll for modes
local scroll = Instance.new("ScrollingFrame", content)
scroll.Size = UDim2.new(1,-20,0,176)
scroll.Position = UDim2.new(0,10,0,44)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 8
scroll.BackgroundColor3 = Color3.fromRGB(28,40,68)
scroll.BorderSizePixel = 0
scroll.Visible = false

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)
layout.SortOrder = Enum.SortOrder.LayoutOrder

for i,m in ipairs(modeList) do
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1,-12,0,34)
    b.Position = UDim2.new(0,6,0,(i-1)*40 + 2)
    b.BackgroundColor3 = Color3.fromRGB(48,72,110)
    b.Font = Enum.Font.Gotham
    b.TextSize = 15
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = m
    b.Name = "Mode_"..m
    b.MouseButton1Click:Connect(function()
        currentModeIndex = i
        modeLabel.Text = "Mode: " .. modeList[currentModeIndex]
        scroll.Visible = false
        modeToggle.Text = "▾"
        refreshFieldsForCurrentMode()
    end)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 8)
end)

modeToggle.MouseButton1Click:Connect(function()
    scroll.Visible = not scroll.Visible
    modeToggle.Text = scroll.Visible and "▴" or "▾"
end)

-- dynamic field container
local fieldsFrame = Instance.new("Frame", content)
fieldsFrame.Size = UDim2.new(1,-20,0,190)
fieldsFrame.Position = UDim2.new(0,10,0,232)
fieldsFrame.BackgroundTransparency = 1

-- Activate button (per current mode)
local activateBtn = Instance.new("TextButton", content)
activateBtn.Size = UDim2.new(1,-20,0,36)
activateBtn.Position = UDim2.new(0,10,1,-56)
activateBtn.BackgroundColor3 = Color3.fromRGB(70,110,180)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 16
activateBtn.TextColor3 = Color3.new(1,1,1)
activateBtn.Text = "Activate: ❌"

-- hint text
local hint = Instance.new("TextLabel", content)
hint.Size = UDim2.new(1,-20,0,24)
hint.Position = UDim2.new(0,10,1,-28)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(200,200,200)
hint.Text = "ทุกค่าเป็นตัวคูณ (Multiplier). เช่น 2 = 2x"

-- fold behavior
local folded = false
collapseBtn.MouseButton1Click:Connect(function()
    folded = not folded
    content.Visible = not folded
    main.Size = folded and UDim2.new(0,200,0,46) or UDim2.new(0,380,0,460)
    collapseBtn.Text = folded and "+" or "—"
end)

-- global enable toggle
local enabled = false
globalToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    status.Text = enabled and "ON" or "OFF"
    if not enabled then
        -- disable all modes gracefully
        for _,nm in ipairs(modeList) do modes[nm].active = false end
        activateBtn.Text = "Activate: ❌"
        cleanupMovers()
    else
        local cm = modeList[currentModeIndex]
        activateBtn.Text = modes[cm].active and "Activate: ✅" or "Activate: ❌"
    end
end)

-- =========================
-- Dynamic fields builder / refresher
-- =========================
local fieldWidgets = {} -- { {label=Label, box=TextBox, hint=Label, name=fieldName}, ... }

function refreshFieldsForCurrentMode()
    -- clear existing
    for _,w in ipairs(fieldWidgets) do
        if w.label and w.label.Parent then w.label:Destroy() end
        if w.box and w.box.Parent then w.box:Destroy() end
        if w.hint and w.hint.Parent then w.hint:Destroy() end
    end
    fieldWidgets = {}

    local modeName = modeList[currentModeIndex]
    local defFields = modes[modeName].fields
    local y = 0
    for i,f in ipairs(defFields) do
        local lbl = Instance.new("TextLabel", fieldsFrame)
        lbl.Size = UDim2.new(0.58, -8, 0, 28)
        lbl.Position = UDim2.new(0, 0, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = f.name:gsub("Mult"," (mult)")

        local box = Instance.new("TextBox", fieldsFrame)
        box.Size = UDim2.new(0.42, -6, 0, 28)
        box.Position = UDim2.new(0.58, 6, 0, y)
        box.BackgroundColor3 = Color3.fromRGB(34,54,86)
        box.TextColor3 = Color3.new(1,1,1)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.ClearTextOnFocus = false
        box.Text = tostring(values[modeName][f.name] or f.def)

        local hintLbl = Instance.new("TextLabel", fieldsFrame)
        hintLbl.Size = UDim2.new(1,0,0,18)
        hintLbl.Position = UDim2.new(0,0,0,y+28)
        hintLbl.BackgroundTransparency = 1
        hintLbl.Font = Enum.Font.SourceSans
        hintLbl.TextSize = 11
        hintLbl.TextColor3 = Color3.fromRGB(170,170,170)
        hintLbl.Text = f.hint or ""

        -- input handler
        box.FocusLost:Connect(function()
            local n = safeNum(box.Text, values[modeName][f.name])
            if n < 0 then n = values[modeName][f.name] end
            values[modeName][f.name] = n
            box.Text = tostring(n)
        end)

        table.insert(fieldWidgets, {label=lbl, box=box, hint=hintLbl, name=f.name})
        y = y + 46
    end
end

-- initialize
refreshFieldsForCurrentMode()

-- clicking label cycles modes (convenience)
modeLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        currentModeIndex = currentModeIndex % #modeList + 1
        modeLabel.Text = "Mode: " .. modeList[currentModeIndex]
        refreshFieldsForCurrentMode()
    end
end)

-- mode activate toggle
activateBtn.MouseButton1Click:Connect(function()
    local nm = modeList[currentModeIndex]
    modes[nm].active = not modes[nm].active
    activateBtn.Text = modes[nm].active and "Activate: ✅" or "Activate: ❌"
    if not modes[nm].active then
        cleanupMovers()
    end
end)

-- =========================
-- Core behavior: apply effects per active mode
-- =========================
-- Impulse cooldown
local impulseCooldown = 0

RunService.RenderStepped:Connect(function(dt)
    if not enabled then return end
    if not hrp or not hum then setupChar() end
    if not hrp or not hum then return end

    local moveDir = hum.MoveDirection
    local mag = moveDir.Magnitude

    -- Apply each active mode (you typically will have one active; but loop supports multiple if you toggle them)
    for _, name in ipairs(modeList) do
        if modes[name].active and values[name] then
            if name == "WalkSpeed" then
                local mult = values[name].speedMult or 1
                pcall(function() hum.WalkSpeed = BASE.WalkSpeed * mult end)

            elseif name == "Velocity" then
                if mag > 0 then
                    local m = values[name].forceMult or 1
                    local capMult = values[name].maxSpeedMult or 6
                    local targ = Vector3.new(moveDir.X * BASE.Velocity * m, hrp.Velocity.Y, moveDir.Z * BASE.Velocity * m)
                    -- apply cap
                    if targ.Magnitude > BASE.Velocity * capMult then
                        targ = targ.Unit * (BASE.Velocity * capMult)
                    end
                    pcall(function() hrp.Velocity = targ end)
                end

            elseif name == "CFrame" then
                if mag > 0 then
                    local stepM = values[name].stepMult or 1
                    local delayM = values[name].delayMult or 0
                    local step = BASE.CFrameStep * stepM
                    pcall(function() hrp.CFrame = hrp.CFrame + moveDir * step end)
                    if delayM and delayM > 0 then
                        task.wait(0.001 * delayM) -- scaled small wait
                    end
                end

            elseif name == "TP" then
                if mag > 0 then
                    local distM = values[name].tpDistMult or 1
                    local delayM = values[name].tpDelayMult or 1
                    local dist = BASE.TPDistance * distM
                    pcall(function() hrp.CFrame = hrp.CFrame + moveDir * dist end)
                    if delayM and delayM > 0 then
                        task.wait((BASE.TPDistance * 0.01) * delayM) -- scaled small wait so not huge
                    end
                end

            elseif name == "Impulse" then
                if mag > 0 then
                    local powerM = values[name].powerMult or 1
                    local intervalM = values[name].intervalMult or 1
                    impulseCooldown = impulseCooldown + dt
                    local interval = 0.12 * intervalM
                    if impulseCooldown >= interval then
                        local force = moveDir * (BASE.ImpulsePower * powerM)
                        pcall(function() hrp:ApplyImpulse(force) end)
                        impulseCooldown = 0
                    end
                end

            elseif name == "BodyVelocity" then
                if not activeBV or not activeBV.Parent then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "__SH_BodyVelocity"
                    bv.MaxForce = Vector3.new(4e5, 0, 4e5)
                    bv.P = 1250
                    bv.Parent = hrp
                    activeBV = bv
                end
                local m = values[name].bvPowerMult or 1
                if mag > 0 then
                    pcall(function() activeBV.Velocity = Vector3.new(moveDir.X * BASE.BodyVelocityPower * m, hrp.Velocity.Y, moveDir.Z * BASE.BodyVelocityPower * m) end)
                else
                    pcall(function() activeBV.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end)
                end

            elseif name == "LinearVelocity" then
                if not activeLV or not activeLV.Parent then
                    local att = Instance.new("Attachment")
                    att.Name = "__SH_LV_Att"
                    att.Parent = hrp
                    local lv = Instance.new("LinearVelocity")
                    lv.Name = "__SH_LinearVelocity"
                    lv.Attachment0 = att
                    lv.MaxForce = math.huge
                    lv.Parent = hrp
                    activeLVAtt = att
                    activeLV = lv
                end
                local m = values[name].lvVelMult or 1
                if mag > 0 then
                    pcall(function() activeLV.VectorVelocity = Vector3.new(moveDir.X * BASE.LinearVelocityPower * m, 0, moveDir.Z * BASE.LinearVelocityPower * m) end)
                else
                    pcall(function() activeLV.VectorVelocity = Vector3.new(0,0,0) end)
                end

            elseif name == "AssemblyLinearVelocity" then
                if mag > 0 then
                    local m = values[name].asmMult or 1
                    local v = hrp.AssemblyLinearVelocity
                    local newv = Vector3.new(moveDir.X * BASE.AssemblySpeed * m, v.Y, moveDir.Z * BASE.AssemblySpeed * m)
                    if values[name].limitY and (values[name].limitY == 1 or values[name].limitY == "1") then
                        newv = Vector3.new(newv.X, 0, newv.Z)
                    end
                    pcall(function() hrp.AssemblyLinearVelocity = newv end)
                end

            elseif name == "Tween" then
                if mag > 0 then
                    local ttimeM = values[name].tweenTimeMult or 1
                    local distM = values[name].tweenDistMult or 1
                    local tTime = math.max(0.01, BASE.TweenTime * ttimeM)
                    local dist = BASE.TweenDistance * distM
                    local info = TweenInfo.new(tTime, Enum.EasingStyle.Linear)
                    pcall(function()
                        local tw = TweenService:Create(hrp, info, {CFrame = hrp.CFrame + moveDir * dist})
                        tw:Play()
                    end)
                end

            elseif name == "Lerp" then
                if mag > 0 then
                    local alphaM = values[name].lerpAlphaMult or 1
                    local stepM = values[name].lerpStepMult or 1
                    local step = BASE.LerpStep * stepM
                    local alpha = math.clamp(0.01 * alphaM, 0, 1)
                    pcall(function() hrp.CFrame = hrp.CFrame:Lerp(hrp.CFrame + moveDir * step, alpha) end)
                end
            end
        end
    end
end)

-- cleanup on destroy
screen.Destroying:Connect(function() cleanupMovers() end)

-- =========================
-- Expose addMenu for future expansion (example stub)
-- =========================
-- addMenu("Speed", function(parent) ... end)
-- For now, Speed menu is built-in; other menus can be added by implementing addMenu callbacks and hooking them into UI.

-- =========================
-- End
-- Save this file as SpeedHub.lua on your GitHub and load with loadstring(game:HttpGet('<RAW URL>'))()
