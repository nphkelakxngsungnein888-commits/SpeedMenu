local vu = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

local clickPos = nil
local clicking = false
local speed = 0.05

-- สร้าง UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0,200,0,180)
Frame.Position = UDim2.new(0,20,0,200)

local Toggle = Instance.new("TextButton")
Toggle.Parent = Frame
Toggle.Size = UDim2.new(1,0,0,40)
Toggle.Text = "เปิด Auto Click"

local Select = Instance.new("TextButton")
Select.Parent = Frame
Select.Size = UDim2.new(1,0,0,40)
Select.Position = UDim2.new(0,0,0,50)
Select.Text = "เลือกจุดคลิก"

local Speed = Instance.new("TextButton")
Speed.Parent = Frame
Speed.Size = UDim2.new(1,0,0,40)
Speed.Position = UDim2.new(0,0,0,100)
Speed.Text = "เพิ่มความเร็ว"

-- ปุ่มเปิด/ปิด
Toggle.MouseButton1Click:Connect(function()
    clicking = not clicking
    
    if clicking then
        Toggle.Text = "ปิด Auto Click"
    else
        Toggle.Text = "เปิด Auto Click"
    end
end)

-- เลือกตำแหน่งคลิก
Select.MouseButton1Click:Connect(function()
    Select.Text = "แตะหน้าจอเพื่อเลือก"
    
    local touch = UIS.TouchTap:Wait()
    clickPos = touch[1]
    
    Select.Text = "เลือกจุดแล้ว"
end)

-- เพิ่มความเร็ว
Speed.MouseButton1Click:Connect(function()
    speed = speed - 0.01
    
    if speed <= 0.01 then
        speed = 0.01
    end
    
    Speed.Text = "Speed: "..speed
end)

-- ระบบคลิกออโต้
while true do
    if clicking and clickPos then
        vu:Button1Down(clickPos, workspace.CurrentCamera.CFrame)
        wait(speed)
        vu:Button1Up(clickPos, workspace.CurrentCamera.CFrame)
    end
    wait(speed)
end
