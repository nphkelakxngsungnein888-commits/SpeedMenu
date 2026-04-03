-- Lock Menu | NPC/Player | Nearest + Scan | Team Color
-- Fixed: mobile drag, nil errors, incomplete code, RunService cleanup

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
    Humanoid = c:WaitForChild("Humanoid")
end)

local Settings = {
    MenuSize = 10,
    ScanMenuSize = 10,
    LockStrength = 0.3,
    LockRange = 100,
    Mode = "NPC",
    Enabled = false,
    NearestMode = false,
}

local currentTarget = nil
local targetList = {}
local targetIndex = 1
local lockConnection = nil
local SCAN_INTERVAL = 0.5

pcall(function()
    local old = CoreGui:FindFirstChild("LockMenu")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LockMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local function S(n) return n * (Settings.MenuSize / 10) end
local function SS(n) return n * (Settings.ScanMenuSize / 10) end

-- ══════════════════════════════
--   DRAG HELPER (Mobile Safe)
-- ══════════════════════════════
local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos

    local function onInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    local function onInputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end

    handle.InputBegan:Connect(onInput)
    handle.InputEnded:Connect(onInputEnded)
    handle.InputChanged:Connect(onInputChanged)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end

-- ══════════════════════════════
--         MAIN FRAME
-- ══════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, S(220), 0, S(310))
MainFrame.Position = UDim2.new(0.5, -S(110), 0.5, -S(155))
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,8)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, S(30))
TitleBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -S(70), 1, 0)
TitleLabel.Position = UDim2.new(0, S(8), 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚔ Lock Menu"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.TextSize = S(13)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

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

MakeDraggable(MainFrame, TitleBar)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -S(30))
Content.Position = UDim2.new(0, 0, 0, S(30))
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ══════════════════════════════
--         HELPERS
-- ══════════════════════════════
local function Divider(parent, yPos)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -S(16), 0, 1)
    d.Position = UDim2.new(0, S(8), 0, yPos)
    d.BackgroundColor3 = Color3.fromRGB(50,50,50)
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function SmallLabel(parent, text, y, xPos)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, S(100), 0, S(14))
    l.Position = UDim2.new(0, S(xPos), 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(160,160,160)
    l.TextSize = S(10)
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function InputBox(parent, default, y, w, xPos)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, S(w), 0, S(24))
    box.Position = UDim2.new(0, S(xPos), 0, y)
    box.BackgroundColor3 = Color3.fromRGB(30,30,30)
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.PlaceholderColor3 = Color3.fromRGB(100,100,100)
    box.TextSize = S(11)
    box.Font = Enum.Font.Gotham
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)
    return box
end

-- ══════════════════════════════
--          MODE BUTTONS
-- ══════════════════════════════
SmallLabel(Content, "🎯 MODE", S(6), 8)

local ModePlayer = Instance.new("TextButton")
ModePlayer.Size = UDim2.new(0, S(96), 0, S(26))
ModePlayer.Position = UDim2.new(0, S(8), 0, S(22))
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
ModeNPC.Position = UDim2.new(0, S(112), 0, S(22))
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

Divider(Content, S(54))

-- ══════════════════════════════
--        STRENGTH / RANGE
-- ══════════════════════════════
SmallLabel(Content, "⚡ Strength", S(58), 8)
SmallLabel(Content, "📏 Range", S(58), 112)

local StrBox = InputBox(Content, Settings.LockStrength, S(72), 90, 8)
local RangeBox = InputBox(Content, Settings.LockRange, S(72), 90, 112)

Divider(Content, S(102))

-- ══════════════════════════════
--         LOCK BUTTON
-- ══════════════════════════════
local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.new(1, -S(16), 0, S(28))
LockBtn.Position = UDim2.new(0, S(8), 0, S(108))
LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
LockBtn.BorderSizePixel = 0
LockBtn.Text = "🔓 Lock : OFF"
LockBtn.TextColor3 = Color3.fromRGB(220,220,220)
LockBtn.TextSize = S(12)
LockBtn.Font = Enum.Font.GothamBold
LockBtn.Parent = Content
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0,6)

-- ══════════════════════════════
--        NEAREST BUTTON
-- ══════════════════════════════
local NearBtn = Instance.new("TextButton")
NearBtn.Size = UDim2.new(1, -S(16), 0, S(26))
NearBtn.Position = UDim2.new(0, S(8), 0, S(142))
NearBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NearBtn.BorderSizePixel = 0
NearBtn.Text = "📍 Nearest : OFF"
NearBtn.TextColor3 = Color3.fromRGB(200,200,200)
NearBtn.TextSize = S(11)
NearBtn.Font = Enum.Font.GothamBold
NearBtn.Parent = Content
Instance.new("UICorner", NearBtn).CornerRadius = UDim.new(0,6)

-- ══════════════════════════════
--      PREV / TARGET / NEXT
-- ══════════════════════════════
local PrevBtn = Instance.new("TextButton")
PrevBtn.Size = UDim2.new(0, S(44), 0, S(26))
PrevBtn.Position = UDim2.new(0, S(8), 0, S(174))
PrevBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
PrevBtn.BorderSizePixel = 0
PrevBtn.Text = "◀"
PrevBtn.TextColor3 = Color3.fromRGB(220,220,220)
PrevBtn.TextSize = S(14)
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.Parent = Content
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0,6)

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(0, S(104), 0, S(26))
TargetLabel.Position = UDim2.new(0, S(56), 0, S(174))
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
NextBtn.Position = UDim2.new(0, S(166), 0, S(174))
NextBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
NextBtn.BorderSizePixel = 0
NextBtn.Text = "▶"
NextBtn.TextColor3 = Color3.fromRGB(220,220,220)
NextBtn.TextSize = S(14)
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = Content
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(206))

-- ══════════════════════════════
--       SCAN TOGGLE BUTTON
-- ══════════════════════════════
local ScanToggleBtn = Instance.new("TextButton")
ScanToggleBtn.Size = UDim2.new(1, -S(16), 0, S(26))
ScanToggleBtn.Position = UDim2.new(0, S(8), 0, S(212))
ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
ScanToggleBtn.BorderSizePixel = 0
ScanToggleBtn.Text = "🔍 Scan Menu : OFF"
ScanToggleBtn.TextColor3 = Color3.fromRGB(200,200,200)
ScanToggleBtn.TextSize = S(11)
ScanToggleBtn.Font = Enum.Font.GothamBold
ScanToggleBtn.Parent = Content
Instance.new("UICorner", ScanToggleBtn).CornerRadius = UDim.new(0,6)

Divider(Content, S(244))

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -S(16), 0, S(20))
StatusLabel.Position = UDim2.new(0, S(8), 0, S(249))
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● Idle"
StatusLabel.TextColor3 = Color3.fromRGB(120,120,120)
StatusLabel.TextSize = S(11)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Content

-- ══════════════════════════════
--         SCAN FRAME
-- ══════════════════════════════
local ScanFrame = Instance.new("Frame")
ScanFrame.Size = UDim2.new(0, SS(200), 0, SS(280))
ScanFrame.Position = UDim2.new(0.5, SS(120), 0.5, -SS(140))
ScanFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
ScanFrame.BorderSizePixel = 0
ScanFrame.ClipsDescendants = true
ScanFrame.Visible = false
ScanFrame.Parent = ScreenGui
Instance.new("UICorner", ScanFrame).CornerRadius = UDim.new(0,8)

local ScanTitleBar = Instance.new("Frame")
ScanTitleBar.Size = UDim2.new(1, 0, 0, SS(28))
ScanTitleBar.BackgroundColor3 = Color3.fromRGB(28,28,28)
ScanTitleBar.BorderSizePixel = 0
ScanTitleBar.Parent = ScanFrame

MakeDraggable(ScanFrame, ScanTitleBar)

local ScanTitle = Instance.new("TextLabel")
ScanTitle.Size = UDim2.new(1, -SS(60), 1, 0)
ScanTitle.Position = UDim2.new(0, SS(8), 0, 0)
ScanTitle.BackgroundTransparency = 1
ScanTitle.Text = "🔍 Scan"
ScanTitle.TextColor3 = Color3.fromRGB(255,255,255)
ScanTitle.TextSize = SS(12)
ScanTitle.Font = Enum.Font.GothamBold
ScanTitle.TextXAlignment = Enum.TextXAlignment.Left
ScanTitle.Parent = ScanTitleBar

local ScanSizeBox = Instance.new("TextBox")
ScanSizeBox.Size = UDim2.new(0, SS(24), 0, SS(18))
ScanSizeBox.Position = UDim2.new(1, -SS(56), 0.5, -SS(9))
ScanSizeBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
ScanSizeBox.BorderSizePixel = 0
ScanSizeBox.Text = tostring(Settings.ScanMenuSize)
ScanSizeBox.TextColor3 = Color3.fromRGB(255,255,255)
ScanSizeBox.TextSize = SS(10)
ScanSizeBox.Font = Enum.Font.Gotham
ScanSizeBox.Parent = ScanTitleBar
Instance.new("UICorner", ScanSizeBox).CornerRadius = UDim.new(0,4)

local ScanMinBtn = Instance.new("TextButton")
ScanMinBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ScanMinBtn.Position = UDim2.new(1, -SS(34), 0.5, -SS(10))
ScanMinBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
ScanMinBtn.BorderSizePixel = 0
ScanMinBtn.Text = "–"
ScanMinBtn.TextColor3 = Color3.fromRGB(255,255,255)
ScanMinBtn.TextSize = SS(12)
ScanMinBtn.Font = Enum.Font.GothamBold
ScanMinBtn.Parent = ScanTitleBar
Instance.new("UICorner", ScanMinBtn).CornerRadius = UDim.new(0,4)

local ScanCloseBtn = Instance.new("TextButton")
ScanCloseBtn.Size = UDim2.new(0, SS(20), 0, SS(20))
ScanCloseBtn.Position = UDim2.new(1, -SS(12), 0.5, -SS(10))
ScanCloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
ScanCloseBtn.BorderSizePixel = 0
ScanCloseBtn.Text = "✕"
ScanCloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
ScanCloseBtn.TextSize = SS(10)
ScanCloseBtn.Font = Enum.Font.GothamBold
ScanCloseBtn.Parent = ScanTitleBar
Instance.new("UICorner", ScanCloseBtn).CornerRadius = UDim.new(0,4)

local DoScanBtn = Instance.new("TextButton")
DoScanBtn.Size = UDim2.new(1, -SS(16), 0, SS(26))
DoScanBtn.Position = UDim2.new(0, SS(8), 0, SS(34))
DoScanBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
DoScanBtn.BorderSizePixel = 0
DoScanBtn.Text = "🔍 Scan Now"
DoScanBtn.TextColor3 = Color3.fromRGB(220,220,220)
DoScanBtn.TextSize = SS(11)
DoScanBtn.Font = Enum.Font.GothamBold
DoScanBtn.Parent = ScanFrame
Instance.new("UICorner", DoScanBtn).CornerRadius = UDim.new(0,6)

local ScanCountLabel = Instance.new("TextLabel")
ScanCountLabel.Size = UDim2.new(1, -SS(16), 0, SS(14))
ScanCountLabel.Position = UDim2.new(0, SS(8), 0, SS(62))
ScanCountLabel.BackgroundTransparency = 1
ScanCountLabel.Text = "0 found"
ScanCountLabel.TextColor3 = Color3.fromRGB(100,100,100)
ScanCountLabel.TextSize = SS(9)
ScanCountLabel.Font = Enum.Font.Gotham
ScanCountLabel.TextXAlignment = Enum.TextXAlignment.Left
ScanCountLabel.Parent = ScanFrame

local ScanScroll = Instance.new("ScrollingFrame")
ScanScroll.Size = UDim2.new(1, -SS(8), 1, -SS(78))
ScanScroll.Position = UDim2.new(0, SS(4), 0, SS(76))
ScanScroll.BackgroundTransparency = 1
ScanScroll.BorderSizePixel = 0
ScanScroll.ScrollBarThickness = 3
ScanScroll.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
ScanScroll.CanvasSize = UDim2.new(0,0,0,0)
ScanScroll.Parent = ScanFrame

local ScanLayout = Instance.new("UIListLayout")
ScanLayout.Padding = UDim.new(0, SS(3))
ScanLayout.Parent = ScanScroll

-- ══════════════════════════════
--        TEAM COLOR
-- ══════════════════════════════
local function GetTeamColor(model)
    local p = Players:GetPlayerFromCharacter(model)
    if p and p.Team then
        return p.Team.TeamColor.Color
    end
    local myTeam = LocalPlayer.Team
    if p and myTeam then
        if p.Team and p.Team == myTeam then
            return Color3.fromRGB(60,200,100)
        else
            return Color3.fromRGB(220,60,60)
        end
    end
    return Color3.fromRGB(180,180,180)
end

-- ══════════════════════════════
--        CORE FUNCTIONS
-- ══════════════════════════════
local function GetTargetList()
    if not HumanoidRootPart then return {} end
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

    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
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
    if lockConnection then lockConnection:Disconnect() lockConnection = nil end
    local timer = 0
    lockConnection = RunService.Heartbeat:Connect(function(dt)
        if not HumanoidRootPart then return end
        Settings.LockStrength = tonumber(StrBox.Text) or 0.3

        if not currentTarget or Settings.NearestMode then
            timer = timer + dt
            if timer >= SCAN_INTERVAL then
                timer = 0
                local list = GetTargetList()
                targetList = list
                if #list > 0 then
                    if Settings.NearestMode then
                        SetTarget(list[1].model)
                        targetIndex = 1
                    elseif not currentTarget then
                        SetTarget(list[1].model)
                        targetIndex = 1
                    end
                end
            end
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
    if lockConnection then
        lockConnection:Disconnect()
        lockConnection = nil
    end
    SetTarget(nil)
end

-- ══════════════════════════════
--        BUTTON LOGIC
-- ══════════════════════════════
LockBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        LockBtn.Text = "🔒 Lock : ON"
        LockBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
        StartLock()
    else
        LockBtn.Text = "🔓 Lock : OFF"
        LockBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        StopLock()
    end
end)

NearBtn.MouseButton1Click:Connect(function()
    Settings.NearestMode = not Settings.NearestMode
    if Settings.NearestMode then
        NearBtn.Text = "📍 Nearest : ON"
        NearBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
    else
        NearBtn.Text = "📍 Nearest : OFF"
        NearBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    end
end)

PrevBtn.MouseButton1Click:Connect(function()
    if #targetList == 0 then
        targetList = GetTargetList()
    end
    if #targetList > 0 then
        targetIndex = targetIndex - 1
        if targetIndex < 1 then targetIndex = #targetList end
        SetTarget(targetList[targetIndex].model)
    end
end)

NextBtn.MouseButton1Click:Connect(function()
    if #targetList == 0 then
        targetList = GetTargetList()
    end
    if #targetList > 0 then
        targetIndex = targetIndex + 1
        if targetIndex > #targetList then targetIndex = 1 end
        SetTarget(targetList[targetIndex].model)
    end
end)

-- MINIMIZE main
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized
        and UDim2.new(0, S(220), 0, S(30))
        or UDim2.new(0, S(220), 0, S(310))
end)

CloseBtn.MouseButton1Click:Connect(function()
    StopLock()
    ScreenGui:Destroy()
end)

-- SCAN TOGGLE
local scanVisible = false
ScanToggleBtn.MouseButton1Click:Connect(function()
    scanVisible = not scanVisible
    ScanFrame.Visible = scanVisible
    ScanToggleBtn.Text = scanVisible and "🔍 Scan Menu : ON" or "🔍 Scan Menu : OFF"
    ScanToggleBtn.BackgroundColor3 = scanVisible
        and Color3.fromRGB(40,80,40)
        or Color3.fromRGB(35,35,35)
end)

ScanCloseBtn.MouseButton1Click:Connect(function()
    scanVisible = false
    ScanFrame.Visible = false
    ScanToggleBtn.Text = "🔍 Scan Menu : OFF"
    ScanToggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
end)

-- SCAN MINIMIZE
local scanMin = false
ScanMinBtn.MouseButton1Click:Connect(function()
    scanMin = not scanMin
    ScanScroll.Visible = not scanMin
    DoScanBtn.Visible = not scanMin
    ScanCountLabel.Visible = not scanMin
    ScanFrame.Size = scanMin
        and UDim2.new(0, SS(200), 0, SS(28))
        or UDim2.new(0, SS(200), 0, SS(280))
end)

-- SCAN NOW
DoScanBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(ScanScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local list = GetTargetList()
    targetList = list
    ScanCountLabel.Text = #list .. " found"

    for i, entry in ipairs(list) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, SS(24))
        btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
        btn.BorderSizePixel = 0
        btn.Text = string.format("[%d] %s  %.0fm", i, entry.name, entry.dist)
        btn.TextColor3 = GetTeamColor(entry.model)
        btn.TextSize = SS(9)
        btn.Font = Enum.Font.Gotham
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = ScanScroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, SS(6))

        btn.MouseButton1Click:Connect(function()
            targetIndex = i
            SetTarget(entry.model)
        end)
    end

    ScanScroll.CanvasSize = UDim2.new(0, 0, 0, ScanLayout.AbsoluteContentSize.Y + SS(4))
end)

-- SCAN SIZE adjust
ScanSizeBox.FocusLost:Connect(function()
    local v = tonumber(ScanSizeBox.Text)
    if v and v >= 5 and v <= 20 then
        Settings.ScanMenuSize = v
    end
    ScanSizeBox.Text = tostring(Settings.ScanMenuSize)
end)
