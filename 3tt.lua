--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

--// STATE
local saves = {}
local selectedIndex = nil
local clickTP = false
local lockPos = nil

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "TP_Save_UI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 240)
frame.Position = UDim2.new(0.02, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -60, 0, 25)
title.Position = UDim2.new(0, 5, 0, 0)
title.Text = "Teleport Save"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,25,0,25)
close.Position = UDim2.new(1,-25,0,0)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(120,0,0)

local mini = Instance.new("TextButton", frame)
mini.Size = UDim2.new(0,25,0,25)
mini.Position = UDim2.new(1,-50,0,0)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(60,60,60)

-- ปุ่ม Save
local saveBtn = Instance.new("TextButton", frame)
saveBtn.Size = UDim2.new(0.33,-5,0,30)
saveBtn.Position = UDim2.new(0,5,0,30)
saveBtn.Text = "+ Save"
saveBtn.BackgroundColor3 = Color3.fromRGB(40,120,40)

-- 🔥 ปุ่ม Click TP (กลาง)
local clickBtn = Instance.new("TextButton", frame)
clickBtn.Size = UDim2.new(0.33,-5,0,30)
clickBtn.Position = UDim2.new(0.33,0,0,30)
clickBtn.Text = "Click TP OFF"
clickBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)

-- ปุ่ม Delete
local deleteBtn = Instance.new("TextButton", frame)
deleteBtn.Size = UDim2.new(0.33,-5,0,30)
deleteBtn.Position = UDim2.new(0.66,0,0,30)
deleteBtn.Text = "Delete"
deleteBtn.BackgroundColor3 = Color3.fromRGB(120,40,40)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,-10,1,-70)
scroll.Position = UDim2.new(0,5,0,65)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,4)
layout.Parent = scroll

--// DRAG
local dragging = false
local dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function()
    dragging = false
end)

--// CLOSE / MINI
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local minimized = false
mini.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    saveBtn.Visible = not minimized
    deleteBtn.Visible = not minimized
    clickBtn.Visible = not minimized
    frame.Size = minimized and UDim2.new(0,200,0,30) or UDim2.new(0,200,0,240)
end)

--// CLEAR
local function clearButtons()
    for _,v in pairs(scroll:GetChildren()) do
        if not v:IsA("UIListLayout") then
            v:Destroy()
        end
    end
end

--// CREATE BUTTON
local function createButton(i, pos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-5,0,25)
    btn.Text = "Save "..i
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = scroll

    btn.MouseButton1Click:Connect(function()
        selectedIndex = i

        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:FindFirstChild("HumanoidRootPart")

        if root then
            root.CFrame = CFrame.new(pos.x, pos.y, pos.z)
        end
    end)
end

--// REFRESH
local function refresh()
    clearButtons()
    for i, pos in ipairs(saves) do
        createButton(i, pos)
    end
    scroll.CanvasSize = UDim2.new(0,0,0,#saves * 30)
end

--// SAVE
saveBtn.MouseButton1Click:Connect(function()
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local pos = {
        x = root.Position.X,
        y = root.Position.Y,
        z = root.Position.Z
    }

    table.insert(saves, pos)
    createButton(#saves, pos)
    scroll.CanvasSize = UDim2.new(0,0,0,#saves * 30)
end)

--// DELETE
deleteBtn.MouseButton1Click:Connect(function()
    if selectedIndex then
        table.remove(saves, selectedIndex)
        selectedIndex = nil
        refresh()
    end
end)

--// 🔥 CLICK TP
clickBtn.MouseButton1Click:Connect(function()
    clickTP = not clickTP
    clickBtn.Text = clickTP and "Click TP ON" or "Click TP OFF"
    clickBtn.BackgroundColor3 = clickTP and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

mouse.Button1Down:Connect(function()
    if not clickTP then return end

    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local hit = mouse.Hit
    if hit then
        lockPos = hit.Position
        root.CFrame = CFrame.new(lockPos + Vector3.new(0,3,0))
    end
end)

-- 🔥 กันโดนวาปกลับ
RunService.RenderStepped:Connect(function()
    if clickTP and lockPos then
        local char = player.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if (root.Position - lockPos).Magnitude > 10 then
            root.CFrame = CFrame.new(lockPos + Vector3.new(0,3,0))
        end
    end
end)

-- INIT
refresh()
