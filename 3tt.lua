--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

--// STATE
local monsterList = {}
local selectedTarget = nil

--// UI CREATE
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "MonsterTP_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 180, 0, 220)
frame.Position = UDim2.new(0.02, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -60, 0, 25)
title.Position = UDim2.new(0, 5, 0, 0)
title.Text = "Monster TP"
title.TextSize = 14
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 25, 0, 25)
close.Position = UDim2.new(1, -25, 0, 0)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(120,0,0)

local mini = Instance.new("TextButton", frame)
mini.Size = UDim2.new(0, 25, 0, 25)
mini.Position = UDim2.new(1, -50, 0, 0)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(60,60,60)

local scanBtn = Instance.new("TextButton", frame)
scanBtn.Size = UDim2.new(1, -10, 0, 30)
scanBtn.Position = UDim2.new(0, 5, 0, 30)
scanBtn.Text = "Scan Monsters"
scanBtn.BackgroundColor3 = Color3.fromRGB(40,120,40)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -10, 1, -70)
scroll.Position = UDim2.new(0, 5, 0, 65)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 4)

--// DRAG
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--// CLOSE / MINI
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    scanBtn.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,180,0,30) or UDim2.new(0,180,0,220)
end)

--// HELPER
local function getRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model.PrimaryPart
end

--// SCAN (FIXED)
local function scanMonsters()
    monsterList = {}
    scroll:ClearAllChildren()
    layout.Parent = scroll

    local count = 0
    local foundNames = {}

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= player.Character then

            -- ❌ ตัด player ออก
            if Players:GetPlayerFromCharacter(v) then continue end

            local root = getRoot(v)

            -- 🔥 เงื่อนไขใหม่: มี root ก็ถือว่าใช้ได้
            if root then
                if foundNames[v.Name] then continue end
                foundNames[v.Name] = true

                count += 1
                table.insert(monsterList, v)

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -5, 0, 25)
                btn.Text = v.Name
                btn.TextSize = 12
                btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Parent = scroll

                btn.MouseButton1Click:Connect(function()
                    selectedTarget = v

                    local char = player.Character
                    if not char then return end

                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    local targetRoot = getRoot(v)

                    if myRoot and targetRoot then
                        -- 🔥 วาป
                        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
                    end
                end)
            end
        end
    end

    scroll.CanvasSize = UDim2.new(0,0,0,count * 30)
    print("✅ Scan เจอ:", count)
end

scanBtn.MouseButton1Click:Connect(scanMonsters)
