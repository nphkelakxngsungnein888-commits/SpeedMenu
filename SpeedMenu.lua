-- LocalScript

-- กำหนดตัวแปรอ้างอิง
local PlayerGui = script.Parent
local MainFrame = PlayerGui:WaitForChild("MainGUI").MainFrame -- สมมติว่าโครงสร้างคือ MainGUI -> MainFrame
local ControlFrame = MainFrame:WaitForChild("ControlFrame")
local MenuButtonCollapsed = MainFrame:WaitForChild("MenuButtonCollapsed") -- ปุ่ม "เมนู" ตอนยุบ
local MenuButtonExpanded = MainFrame:WaitForChild("MenuButtonExpanded")   -- ปุ่ม "เมนู" ตอนขยาย
local ToggleUseButton = MainFrame:WaitForChild("ToggleUseButton")
local ValueButton1 = ControlFrame:WaitForChild("ValueButton1")
local InputBox1 = ControlFrame:WaitForChild("InputBox1") -- ช่องใส่ค่า
-- ... กำหนดตัวแปรสำหรับ ValueButton2, 3 และ InputBox2, 3 ที่เหลือ

-- สถานะเริ่มต้น
local isExpanded = true -- สถานะขยาย/ยุบ
local isEnabled = true  -- สถานะเปิด/ปิดการใช้งาน

-- ฟังก์ชันสำหรับอัปเดตสถานะ UI
local function UpdateUI(expanded)
    -- ซ่อน/แสดงกรอบควบคุมหลัก
    ControlFrame.Visible = expanded
    
    -- สลับการมองเห็นปุ่มเมนู
    MenuButtonCollapsed.Visible = not expanded
    MenuButtonExpanded.Visible = expanded
    
    -- หากต้องการให้ MainFrame ทั้งหมดเปลี่ยนขนาด/ตำแหน่ง 
    -- คุณสามารถใช้ TweenService เพื่อทำให้ดูสวยงามขึ้นได้ 
    -- แต่สำหรับการสลับการมองเห็นธรรมดาทำได้ตามข้างบน
    
    isExpanded = expanded
end

-- ฟังก์ชันสำหรับสลับการเปิด/ปิดการใช้งาน
local function ToggleUsage()
    isEnabled = not isEnabled
    
    -- อัปเดตข้อความบนปุ่ม
    if isEnabled then
        ToggleUseButton.Text = "เปิด-ปิดการใช้งาน" -- หรือข้อความที่สื่อถึง "เปิดอยู่"
        -- เปิดใช้งานปุ่มปรับค่า
        ValueButton1.Active = true
        ValueButton2.Active = true
        ValueButton3.Active = true
        ControlFrame.BackgroundTransparency = 0 -- ทำให้ทึบ
    else
        ToggleUseButton.Text = "เปิด-ปิดการใช้งาน" -- หรือข้อความที่สื่อถึง "ปิดอยู่"
        -- ปิดใช้งานปุ่มปรับค่า
        ValueButton1.Active = false
        ValueButton2.Active = false
        ValueButton3.Active = false
        ControlFrame.BackgroundTransparency = 0.5 -- ทำให้จางลงเพื่อบ่งชี้ว่าปิดใช้งาน
    end
end

-- ฟังก์ชันสำหรับการคลิกปุ่มปรับค่า (ตัวอย่างสำหรับปุ่ม 1)
local function AdjustValue1()
    if isEnabled then
        local valueText = InputBox1.Text
        local numericValue = tonumber(valueText)
        
        if numericValue then
            -- ส่งค่าไปยัง Server หรือใช้ค่าใน LocalScript
            print("ตั้งค่าตัวกระจาย 1 เป็น: " .. numericValue)
            -- ตัวอย่าง: ส่งค่าไปที่ Server ผ่าน RemoteEvent
            -- game.ReplicatedStorage.RemoteEvents.SetValue1:FireServer(numericValue)
        else
            warn("กรุณาใส่ค่าที่เป็นตัวเลขในช่องปรับค่า 1")
        end
    end
end

-- เชื่อมต่อเหตุการณ์
MenuButtonCollapsed.MouseButton1Click:Connect(function()
    UpdateUI(true) -- ยุบ -> ขยาย
end)

MenuButtonExpanded.MouseButton1Click:Connect(function()
    UpdateUI(false) -- ขยาย -> ยุบ
end)

ToggleUseButton.MouseButton1Click:Connect(ToggleUsage)

ValueButton1.MouseButton1Click:Connect(AdjustValue1)
-- ValueButton2.MouseButton1Click:Connect(AdjustValue2)
-- ValueButton3.MouseButton1Click:Connect(AdjustValue3)

-- กำหนดสถานะเริ่มต้นเมื่อเกมเริ่ม
UpdateUI(isExpanded)
ToggleUsage() -- กำหนดสถานะเริ่มต้นของปุ่มเปิด/ปิด

