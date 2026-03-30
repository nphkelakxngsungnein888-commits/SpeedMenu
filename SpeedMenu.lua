--นี่เลยครับ แก้ทั้ง 2 จุดแล้ว:
-- Mobile-Friendly GUI Menu | Black & White Theme
-- Target Lock System (Player / NPC) | Codex Fixed

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Settings = {
    MenuSize = 10,
    LockStrength = 0.3,
    LockRange = 100,
    Mode = "NPC",
    Enabled = false,
}

local currentTarget = nil
local targetList = {}
local targetIndex = 1
local lockConnection = nil
local damageCheckConnection = nil
local lastHealth = Humanoid.Health

-- ลบ GUI เก่าถ้ามี
pcall(function()
    if CoreGui:FindFirstChild("LockMenu") then
        CoreGui:FindFirstChild("LockMenu"):Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui  -- แก้จาก PlayerGui เป็น CoreGui

local function S(n) return n * (Settings.MenuSize / 10) end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, S(220), 0, S(300))
MainFrame.Position = UDim2.new(0.5, -S(110), 0.5, -S(150))
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, S(30))
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -S(70), 1, 0)
TitleLabel.Position = UDim2.new(0, S(8), 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ Lock Menu"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = S(13)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local SizeBox = Instance.new("TextBox")
SizeBox.Size = UDim2.new(0, S(28), 0, S(20))
SizeBox.Position = UDim2.new(1, -S(68), 0.5, -S(10))
SizeBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
SizeBox.BorderSizePixel = 0
SizeBox.Text = tostring(Settings.MenuSize)
SizeBox.TextColor3 = Color3.fromRGB(255,255,255)
SizeBox.TextSize = S(11)
SizeBox.Font = Enum.Font.Gotham
SizeBox.PlaceholderText = "10"
SizeBox.Parent = TitleBar
Instance.new("UICorner", SizeBox).CornerRadius = UDim.new(0,4)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, S(22), 0, S(22))
MinBtn.Position = UDim2.new(1, -S(46), 0.5, -S(11))
MinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.TextSize = S(14)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, S(22), 0, S(22))
CloseBtn.Position = UDim2.new(1, -S(22), 0.5, -S(11))
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = S(12)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,4)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -S(30))
Content.Position = UDim2.new(0, 0, 0, S(30))
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local function Divider(parent, yPos)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -S(16), 0, 1)
    d.Position = UDim2.new(0, S(8), 0, yPos)
    d.BackgroundColor3 = Color3.fromRGB(50,50,50)
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function Label(parent, text, y, size)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -S(16), 0, S(18))
    l.Position = UDim2.new(0, S(8), 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(180,180,180)
    l.TextSize = size or S(11)
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function InputBox(parent, placeholder, default, y, w, x)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, S(w or 80), 0, S(24))
    box.Position = UDim2.new(0, S(x or 8), 0, y)
    box.BackgroundColor3 = Color3.fromRGB(30,30,30)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.PlaceholderColor3 = Color3.fromRGB(100,100,100)
    box.TextSize = S(11)
    box.Font = Enum.Font.Gotham
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)
    return box
end

-- MODE
Label(Content, "🎯 MODE", S(6), S(11))

local ModePlayer = Instance.new("TextButton")
ModePlayer.Size = UDim2.new(0, S(96), 0, S(26))
ModePlayer.Position = UDim2.new(0, S(8), 0, S(26))
ModePlayer.BackgroundColor3 = Color3.fromRGB(40,40,40)
ModePlayer.BorderSizePixel = 0
ModePlayer.Text = "👤 Player"
ModePlayer.TextColor3 = Color3.fromRGB(180,180,180)
ModePlayer.TextSize = S(11)
ModePlayer.Font = Enum.Font.GothamBold
ModePlayer.Parent = Content
Instance.new("UICorner", ModePlayer).CornerRadius = UDim.new(0,6)

local ModeNPC = Instance.new("TextButton")
ModeNPC.Size = UDim2.new(0, S(96), 0, S(26))
ModeNPC.Position = UDim2.new(0, S(112), 0, S(26))
ModeNPC.BackgroundColor3 = Color3.fromRGB(200,200,200)
ModeNPC.BorderSizePixel = 0
ModeNPC.Text = "🤖 NPC"
ModeNPC.TextColor3 = Color3.fromRGB(20,20,20)
ModeNPC.TextSize = S(11)
ModeNPC.Font = Enum.Font.GothamBold
ModeNPC.Parent = Content
Instance.new("UICorner", ModeNPC).CornerRadius = UDim.new(0,6)

local function UpdateModeUI()
    if Settings.Mode == "Player" then
        ModePlayer.BackgroundColor3 = Color3.fromRGB(200,200,200)
        ModePlayer.TextColor3 = Color3.fromRGB(20,20,20)
        ModeNPC.BackgroundColor3 = Color3.fromRGB(40,40,40)
        ModeNPC.TextColor3 = Color3.fromRGB(180,180,180)
    else
        ModeNPC.BackgroundColor3 = Color3.fromRGB(200,200,200)
        ModeNPC.TextColor3 = Color3.fromRGB(20,20,20)
        ModePlayer.BackgroundColor3 = Color3.fromRGB(40,40,40)
        ModePlayer.TextColor3 = Color3.fromRGB(180,180,180)
    end
end
UpdateModeUI()

ModePlayer.MouseButton1Click:Connect(function()
    Settings.Mode = "Player"
    currentTarget = nil
    UpdateModeUI()
end)
ModeNPC.MouseButton1Click:Connect(function()
    Settings.Mode = "NPC"
    currentTarget = nil
    UpdateModeUI()
end)

Divider(Content, S(58))

Label(Content, "⚡ Strength", S(64), S(11))
Label(Content, "📏 Range", S(64), S(11))

local StrBox = InputBox(Content, "Strength", Settings.LockStrength, S(82), 90, 8)
local RangeBox = InputBox(Content, "Range", Settings.LockRange, S(82), 90, 112)

Divider(Content, S(112))

local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.new(1, -S(16), 0, S(28))
LockBtn.Position = UDim2.new(0, S(8), 0, S(118))
LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
LockBtn.BorderSizePixel = 0
LockBtn.Text = "🔓 Lock : OFF"
LockBtn.TextColor3 = Color3.fromRGB(220,220,220)
LockBtn.TextSize = S(12)
LockBtn.Font = Enum.Font.GothamBold
LockBtn.Parent = Content
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0,6)

local function UpdateLockBtn()
    if Settings.Enabled then
        LockBtn.Text = "🔒 Lock : ON"
        LockBtn.BackgroundColor3 = Color3.fromRGB(220,220,220)
        LockBtn.TextColor3 = Color3.fromRGB(20,20,20)
    else
        LockBtn.Text = "🔓 Lock : OFF"
        LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        LockBtn.TextColor3 = Color3.fromRGB(220,220,220)
    end
end

local PrevBtn = Instance.new("TextButton")
PrevBtn.Size = UDim2.new(0, S(44), 0, S(26))
PrevBtn.Position = UDim2.new(0, S(8), 0, S(154))
PrevBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
PrevBtn.BorderSizePixel = 0
PrevBtn.Text = "◀"
PrevBtn.TextColor3 = Color3.fromRGB(220,220,220)
PrevBtn.TextSize = S(14)
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.Parent = Content
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0,6)

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(0, S(100), 0, S(26))
TargetLabel.Position = UDim2.new(0, S(58), 0, S(154))
TargetLabel.BackgroundColor3 = Color3.fromRGB(25,25,25)
TargetLabel.BorderSizePixel = 0
TargetLabel.Text = "No Target"
TargetLabel.TextColor3 = Color3.fromRGB(200,200,200)
TargetLabel.TextSize = S(10)
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
TargetLabel.Parent = Content
Instance.new("UICorner", TargetLabel).CornerRadius = UDim.new(0,5)

local NextBtn = Instance.new("TextButton")
NextBtn.Size = UDim2.new(0, S(44), 0, S(26))
NextBtn.Position = UDim2.new(0, S(164), 0, S(154))
NextBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NextBtn.BorderSizePixel = 0
NextBtn.Text = "▶"
NextBtn.TextColor3 = Color3.fromRGB(220,220,220)
NextBtn.TextSize = S(14)
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = Content
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(188))

local StatusLabel = Label(Content, "● Idle", S(194), S(11))
StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)

-- ══════════════════════════════════
--        CORE FUNCTIONS
-- ══════════════════════════════════
local function GetTargetList()
    local list = {}
    local range = tonumber(RangeBox.Text) or Settings.LockRange
    if Settings.Mode == "Player" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                    if dist <= range then
                        table.insert(list, {model = p.Character, name = p.Name, dist = dist})
                    end
                end
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= Character then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                    local dist = (hrp.Position - HumanoidRootPart.Position).Magnitude
                    if dist <= range then
                        table.insert(list, {model = obj, name = obj.Name, dist = dist})
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function GetNearestTarget()
    local list = GetTargetList()
    if #list > 0 then return list[1].model, list end
    return nil, {}
end

local function SetTarget(model)
    currentTarget = model
    if model then
        TargetLabel.Text = model.Name
        StatusLabel.Text = "🔒 " .. model.Name
        StatusLabel.TextColor3 = Color3.fromRGB(220,220,220)
    else
        TargetLabel.Text = "No Target"
        StatusLabel.Text = "● Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
    end
end

local function StartLock()
    if lockConnection then lockConnection:Disconnect() end
    lockConnection = RunService.Heartbeat:Connect(function()  -- แก้จาก RenderStepped เป็น Heartbeat
        Settings.LockStrength = tonumber(StrBox.Text) or 0.3
        if not currentTarget then
            local nearest = GetNearestTarget()
            SetTarget(nearest)
        end
        if currentTarget then
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local hum = currentTarget:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                SetTarget(nil)
                return
            end
            local targetPos = hrp.Position
            local currentCF = Camera.CFrame
            local lookAt = CFrame.lookAt(currentCF.Position, targetPos)
            Camera.CFrame = currentCF:Lerp(lookAt, Settings.LockStrength)
        end
    end)
end

local function StopLock()
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    SetTarget(nil)
end

local function StartDamageCheck()
    if damageCheckConnection then damageCheckConnection:Disconnect() end
    damageCheckConnection = RunService.Heartbeat:Connect(function()
        local h = Humanoid.Health
        if h < lastHealth then
            local nearest = GetNearestTarget()
            if nearest then SetTarget(nearest) end
        end
        lastHealth = h
    end)
end

-- ══════════════════════════════════
--         BUTTONS
-- ══════════════════════════════════
LockBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    UpdateLockBtn()
    if Settings.Enabled then
        local nearest, list = GetNearestTarget()
        targetList = list
        targetIndex = 1
        SetTarget(nearest)
        StartLock()
        StartDamageCheck()
    else
        StopLock()
        if damageCheckConnection then damageCheckConnection:Disconnect() end
    end
end)

NextBtn.MouseButton1Click:Connect(function()
    if not Settings.Enabled then return end
    targetList = GetTargetList()
    if #targetList == 0 then return end
    targetIndex = targetIndex % #targetList + 1
    SetTarget(targetList[targetIndex].model)
end)

PrevBtn.MouseButton1Click:Connect(function()
    if not Settings.Enabled then return end
    targetList = GetTargetList()
    if #targetList == 0 then return end
    targetIndex = ((targetIndex - 2) % #targetList) + 1
    SetTarget(targetList[targetIndex].model)
end)

CloseBtn.MouseButton1Click:Connect(function()
    StopLock()
    ScreenGui:Destroy()
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, S(220), 0, S(30))
        MinBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, S(220), 0, S(300))
        MinBtn.Text = "–"
    end
end)

SizeBox.FocusLost:Connect(function()
    local v = tonumber(SizeBox.Text)
    if v and v >= 1 then
        Settings.MenuSize = v
        MainFrame.Size = UDim2.new(0, S(220), 0, minimized and S(30) or S(300))
    else
        SizeBox.Text = tostring(Settings.MenuSize)
    end
end)

-- ══════════════════════════════════
--           DRAG
-- ══════════════════════════════════
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseMove) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

task.defer(function()
    task.wait(1)
    local nearest = GetNearestTarget()
    if nearest then
        SetTarget(nearest)
        StatusLabel.Text = "⚠ Ready (Lock OFF)"
    end
end)
