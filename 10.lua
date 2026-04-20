-- ============================================================
-- GAG AUTO BUY v3.0 - GROW A GARDEN
-- Features:
--   ✅ Auto scan ชื่อของในร้านจริงจาก ReplicatedStorage
--   ✅ ซื้อทุกอย่างที่มีขาย
--   ✅ ซื้อจนเงินหมด / stock หมด
--   ✅ อยู่ที่ไหนก็ซื้อได้ (ไม่ต้อง teleport)
--   ✅ เปิด/ปิดได้ มี UI เต็มรูปแบบ
-- Platform: Mobile (Dobex) | Version: 3.0
-- ============================================================

-- SERVICES
local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

-- VARIABLES
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP          = Character:WaitForChild("HumanoidRootPart")

local autoBuyEnabled  = false
local scannedItems    = {}   -- { name = true }
local blockedItems    = {}   -- { name = true }  (user กด block)
local buyInterval     = 0.25 -- วินาทีระหว่างการซื้อแต่ละครั้ง
local lastStatus      = ""

-- ============================================================
-- RESPAWN SAFETY
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP       = char:WaitForChild("HumanoidRootPart")
    warn("[GAG-Buy] Respawned — ready")
end)

local function GetHRP()
    if not Character or not Character.Parent then
        Character = LocalPlayer.Character
    end
    if Character then
        HRP = Character:FindFirstChild("HumanoidRootPart")
    end
    return HRP
end

-- ============================================================
-- CORE: หา RemoteEvent / RemoteFunction สำหรับซื้อของ
-- ============================================================
local cachedBuyRemote = nil

local function FindBuyRemote()
    if cachedBuyRemote and cachedBuyRemote.Parent then
        return cachedBuyRemote
    end

    -- keywords ที่เกี่ยวกับการซื้อ
    local keywords = {"buy", "purchase", "shop", "order", "acquire", "get"}

    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local nameLow = v.Name:lower()
            for _, kw in ipairs(keywords) do
                if nameLow:find(kw) then
                    cachedBuyRemote = v
                    warn("[GAG-Buy] Found remote: " .. v.Name .. " (" .. v.ClassName .. ")")
                    return v
                end
            end
        end
    end

    warn("[GAG-Buy] ❌ No buy remote found")
    return nil
end

-- ============================================================
-- CORE: SCAN ของในร้านจาก ReplicatedStorage
-- ============================================================
local function ScanItems()
    scannedItems = {}
    local found = 0

    -- Method 1: หา folder ที่ชื่อเกี่ยวกับ shop/item/seed/gear
    local shopKeywords = {
        "shop", "item", "seed", "gear", "product",
        "stock", "catalog", "store", "goods", "inventory"
    }

    local function ScanFolder(folder, depth)
        if depth > 4 then return end
        for _, child in ipairs(folder:GetChildren()) do
            local nameLow = child.Name:lower()
            -- ถ้าเป็น folder ที่น่าสนใจ → เข้าไปสแกนต่อ
            if child:IsA("Folder") or child:IsA("Configuration") then
                for _, kw in ipairs(shopKeywords) do
                    if nameLow:find(kw) then
                        ScanFolder(child, depth + 1)
                        break
                    end
                end
            end
            -- เก็บชื่อ object ที่น่าจะเป็นสินค้า
            if child:IsA("StringValue") or child:IsA("IntValue")
                or child:IsA("NumberValue") or child:IsA("BoolValue")
                or child:IsA("ModuleScript") or child:IsA("Folder") then
                -- กรองชื่อที่ดูเป็นสินค้า
                local clean = child.Name
                    :gsub("^%s+", ""):gsub("%s+$", "")
                if #clean >= 3 and #clean <= 40
                    and not clean:lower():find("^remote")
                    and not clean:lower():find("^event")
                    and not clean:lower():find("^function")
                    and not clean:lower():find("handler")
                    and not clean:lower():find("manager")
                    and not clean:lower():find("system")
                    and not clean:lower():find("module") then
                    if not scannedItems[clean] then
                        scannedItems[clean] = true
                        found = found + 1
                    end
                end
            end
        end
    end

    -- สแกน ReplicatedStorage ทั้งหมด
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        local nameLow = child.Name:lower()
        for _, kw in ipairs(shopKeywords) do
            if nameLow:find(kw) then
                ScanFolder(child, 0)
                break
            end
        end
    end

    -- Method 2: ถ้ายังไม่เจอ → scan workspace หา BillboardGui / SurfaceGui ที่แสดงชื่อสินค้า
    if found == 0 then
        warn("[GAG-Buy] RS scan empty — trying workspace GUI scan")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local parent = obj.Parent
                if parent and (
                    parent:IsA("BillboardGui") or
                    parent:IsA("SurfaceGui") or
                    parent:IsA("ScreenGui")
                ) then
                    local txt = obj.Text:gsub("^%s+",""):gsub("%s+$","")
                    if #txt >= 3 and #txt <= 40
                        and not txt:lower():find("buy")
                        and not txt:lower():find("sell")
                        and not txt:lower():find("price")
                        and not txt:lower():find("%$")
                        and not txt:match("^%d") then
                        if not scannedItems[txt] then
                            scannedItems[txt] = true
                            found = found + 1
                        end
                    end
                end
            end
        end
    end

    -- Fallback: รายการ Grow A Garden ที่รู้จัก
    if found == 0 then
        warn("[GAG-Buy] Using known GAG item fallback list")
        local fallback = {
            -- Seeds
            "Carrot Seed","Strawberry Seed","Blueberry Seed","Tomato Seed",
            "Corn Seed","Watermelon Seed","Pumpkin Seed","Grape Seed",
            "Mango Seed","Dragon Fruit Seed","Bamboo Seed","Cactus Seed",
            "Mushroom Seed","Sunflower Seed","Rose Seed",
            -- Gear
            "Watering Can","Fertilizer","Shovel","Hoe","Rake",
            "Sprinkler","Basic Sprinkler","Advanced Sprinkler",
            "Trowel","Harvest Tool",
            -- Special
            "Magic Bean","Golden Seed","Mystery Seed"
        }
        for _, name in ipairs(fallback) do
            scannedItems[name] = true
            found = found + 1
        end
    end

    warn("[GAG-Buy] Total items scanned: " .. found)
    return scannedItems
end

-- ============================================================
-- CORE: ซื้อของ 1 รายการ (ยิง Remote ตรง ไม่ต้อง teleport)
-- ============================================================
local function TryBuyItem(itemName)
    if not itemName then return false end

    -- เช็ค character alive
    local hrp = GetHRP()
    if not hrp then
        warn("[GAG-Buy] No HRP — skip buy")
        return false
    end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        warn("[GAG-Buy] Dead — skip buy")
        return false
    end

    local remote = FindBuyRemote()
    if not remote then return false end

    local success = false

    -- ลอง patterns ต่างๆ ที่เกมอาจใช้
    local buyArgs = {
        {itemName},
        {itemName, 1},
        {itemName, 1, "buy"},
        {1, itemName},
        {{item = itemName, amount = 1}},
        {{name = itemName, quantity = 1}},
    }

    for _, args in ipairs(buyArgs) do
        if success then break end
        local ok = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(table.unpack(args))
                success = true
            elseif remote:IsA("RemoteFunction") then
                local result = remote:InvokeServer(table.unpack(args))
                success = result ~= false and result ~= nil
            end
        end)
        if ok and success then
            warn("[GAG-Buy] ✅ Bought: " .. itemName)
            return true
        end
        task.wait(0.05)
    end

    -- Fallback: scan remote ทั้งหมดอีกครั้ง
    if not success then
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction"))
                and v.Name:lower():find("buy") then
                pcall(function()
                    if v:IsA("RemoteEvent") then
                        v:FireServer(itemName)
                    else
                        v:InvokeServer(itemName)
                    end
                    success = true
                end)
                if success then break end
            end
        end
    end

    return success
end

-- ============================================================
-- CORE: ซื้อทุกอย่างจนหมด (loop จนกว่าจะ fail)
-- ============================================================
local function BuyAllUntilEmpty()
    local totalBought = 0
    local failCount   = {}  -- นับครั้งที่ fail ต่อ item

    for itemName, _ in pairs(scannedItems) do
        if not autoBuyEnabled then break end
        if blockedItems[itemName] then continue end

        failCount[itemName] = 0
        local itemBought = 0

        -- ซื้อวนจนกว่าจะ fail 3 ครั้งติด (= หมด stock หรือเงินหมด)
        while autoBuyEnabled do
            local ok = TryBuyItem(itemName)
            if ok then
                itemBought  = itemBought + 1
                totalBought = totalBought + 1
                failCount[itemName] = 0
            else
                failCount[itemName] = failCount[itemName] + 1
                if failCount[itemName] >= 3 then
                    warn("[GAG-Buy] Stock/money empty for: " .. itemName
                        .. " (bought " .. itemBought .. ")")
                    break
                end
            end
            task.wait(buyInterval)
        end
    end

    return totalBought
end

-- ============================================================
-- UI
-- ============================================================
local oldGui = PlayerGui:FindFirstChild("GAGAutoBuyUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "GAGAutoBuyUI"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.Parent          = PlayerGui

-- Main Frame
local Main = Instance.new("Frame")
Main.Name                 = "Main"
Main.Size                 = UDim2.new(0, 300, 0, 500)
Main.Position             = UDim2.new(0, 16, 0.5, -250)
Main.BackgroundColor3     = Color3.fromRGB(13, 17, 23)
Main.BorderSizePixel      = 0
Main.Active               = true
Main.ClipsDescendants     = true
Main.Parent               = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

-- Stroke
local Stroke = Instance.new("UIStroke")
Stroke.Color     = Color3.fromRGB(34, 197, 94)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.4
Stroke.Parent    = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 16)
TitleCorner.Parent = TitleBar

-- fix bottom corner ของ titlebar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 8)
TitleFix.Position = UDim2.new(0, 0, 1, -8)
TitleFix.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 36, 1, 0)
TitleIcon.Position = UDim2.new(0, 10, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🌱"
TitleIcon.TextSize = 20
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextColor3 = Color3.fromRGB(255,255,255)
TitleIcon.Parent = TitleBar

local TitleTxt = Instance.new("TextLabel")
TitleTxt.Size = UDim2.new(1, -100, 1, 0)
TitleTxt.Position = UDim2.new(0, 46, 0, 0)
TitleTxt.BackgroundTransparency = 1
TitleTxt.Text = "GAG Auto Buy v3"
TitleTxt.TextColor3 = Color3.fromRGB(134, 239, 172)
TitleTxt.TextSize = 14
TitleTxt.Font = Enum.Font.GothamBold
TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
TitleTxt.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,100,100)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Status Box
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -16, 0, 34)
StatusBox.Position = UDim2.new(0, 8, 0, 54)
StatusBox.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
StatusBox.BorderSizePixel = 0
StatusBox.Parent = Main
Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 8)

local StatusTxt = Instance.new("TextLabel")
StatusTxt.Size = UDim2.new(1, -12, 1, 0)
StatusTxt.Position = UDim2.new(0, 8, 0, 0)
StatusTxt.BackgroundTransparency = 1
StatusTxt.Text = "⬛ OFF — กด SCAN แล้วกด START"
StatusTxt.TextColor3 = Color3.fromRGB(150, 200, 150)
StatusTxt.TextSize = 11
StatusTxt.Font = Enum.Font.Gotham
StatusTxt.TextXAlignment = Enum.TextXAlignment.Left
StatusTxt.TextTruncate = Enum.TextTruncate.AtEnd
StatusTxt.Parent = StatusBox

-- Scan Button
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, -16, 0, 38)
ScanBtn.Position = UDim2.new(0, 8, 0, 94)
ScanBtn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
ScanBtn.Text = "🔍  SCAN ของในร้าน"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.TextSize = 13
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.BorderSizePixel = 0
ScanBtn.Parent = Main
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 10)

-- Item Count Label
local CountTxt = Instance.new("TextLabel")
CountTxt.Size = UDim2.new(1, -16, 0, 20)
CountTxt.Position = UDim2.new(0, 8, 0, 138)
CountTxt.BackgroundTransparency = 1
CountTxt.Text = "📦 รายการ: 0  |  🚫 บล็อก: 0"
CountTxt.TextColor3 = Color3.fromRGB(100, 160, 100)
CountTxt.TextSize = 11
CountTxt.Font = Enum.Font.Gotham
CountTxt.TextXAlignment = Enum.TextXAlignment.Left
CountTxt.Parent = Main

-- Item List Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 0, 240)
Scroll.Position = UDim2.new(0, 8, 0, 160)
Scroll.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(34, 197, 94)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = Main
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 10)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 3)
ListLayout.SortOrder = Enum.SortOrder.Name
ListLayout.Parent = Scroll

local ListPad = Instance.new("UIPadding")
ListPad.PaddingTop    = UDim.new(0, 4)
ListPad.PaddingLeft   = UDim.new(0, 4)
ListPad.PaddingRight  = UDim.new(0, 4)
ListPad.PaddingBottom = UDim.new(0, 4)
ListPad.Parent = Scroll

-- Speed Selector
local SpeedFrame = Instance.new("Frame")
SpeedFrame.Size = UDim2.new(1, -16, 0, 32)
SpeedFrame.Position = UDim2.new(0, 8, 0, 406)
SpeedFrame.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
SpeedFrame.BorderSizePixel = 0
SpeedFrame.Parent = Main
Instance.new("UICorner", SpeedFrame).CornerRadius = UDim.new(0, 8)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0.5, 0, 1, 0)
SpeedLabel.Position = UDim2.new(0, 10, 0, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "⚡ Speed: Normal"
SpeedLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
SpeedLabel.TextSize = 11
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = SpeedFrame

local SpeedFast = Instance.new("TextButton")
SpeedFast.Size = UDim2.new(0, 56, 0, 22)
SpeedFast.Position = UDim2.new(1, -126, 0.5, -11)
SpeedFast.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
SpeedFast.Text = "Fast"
SpeedFast.TextColor3 = Color3.fromRGB(0, 0, 0)
SpeedFast.TextSize = 11
SpeedFast.Font = Enum.Font.GothamBold
SpeedFast.BorderSizePixel = 0
SpeedFast.Parent = SpeedFrame
Instance.new("UICorner", SpeedFast).CornerRadius = UDim.new(0, 6)

local SpeedNormal = Instance.new("TextButton")
SpeedNormal.Size = UDim2.new(0, 60, 0, 22)
SpeedNormal.Position = UDim2.new(1, -64, 0.5, -11)
SpeedNormal.BackgroundColor3 = Color3.fromRGB(50, 80, 50)
SpeedNormal.Text = "Normal"
SpeedNormal.TextColor3 = Color3.fromRGB(200, 255, 200)
SpeedNormal.TextSize = 11
SpeedNormal.Font = Enum.Font.GothamBold
SpeedNormal.BorderSizePixel = 0
SpeedNormal.Parent = SpeedFrame
Instance.new("UICorner", SpeedNormal).CornerRadius = UDim.new(0, 6)

-- Start / Stop Buttons
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.5, -6, 0, 44)
StartBtn.Position = UDim2.new(0, 8, 0, 446)
StartBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
StartBtn.Text = "▶  START"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextSize = 14
StartBtn.Font = Enum.Font.GothamBold
StartBtn.BorderSizePixel = 0
StartBtn.Parent = Main
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 12)

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.5, -6, 0, 44)
StopBtn.Position = UDim2.new(0.5, -2, 0, 446)
StopBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
StopBtn.Text = "⏹  STOP"
StopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
StopBtn.TextSize = 14
StopBtn.Font = Enum.Font.GothamBold
StopBtn.BorderSizePixel = 0
StopBtn.Parent = Main
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 12)

-- ============================================================
-- BUILD ITEM LIST UI
-- ============================================================
local itemRowMap = {}  -- { [name] = Frame }

local function UpdateCountLabel()
    local total   = 0
    local blocked = 0
    for name, _ in pairs(scannedItems) do
        total = total + 1
        if blockedItems[name] then blocked = blocked + 1 end
    end
    CountTxt.Text = "📦 รายการ: " .. total .. "  |  🚫 บล็อก: " .. blocked
end

local function BuildItemRows()
    -- ลบของเก่า
    for _, row in pairs(itemRowMap) do row:Destroy() end
    itemRowMap = {}

    local count = 0
    local names = {}
    for name, _ in pairs(scannedItems) do
        table.insert(names, name)
    end
    table.sort(names)

    for _, itemName in ipairs(names) do
        count = count + 1
        local isBlocked = blockedItems[itemName] == true

        local Row = Instance.new("Frame")
        Row.Name = itemName
        Row.Size = UDim2.new(1, 0, 0, 30)
        Row.BackgroundColor3 = isBlocked
            and Color3.fromRGB(40, 15, 15)
            or  Color3.fromRGB(20, 30, 20)
        Row.BorderSizePixel = 0
        Row.Parent = Scroll
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -70, 1, 0)
        NameLbl.Position = UDim2.new(0, 8, 0, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = (isBlocked and "🚫 " or "✅ ") .. itemName
        NameLbl.TextColor3 = isBlocked
            and Color3.fromRGB(120, 60, 60)
            or  Color3.fromRGB(180, 255, 180)
        NameLbl.TextSize = 11
        NameLbl.Font = Enum.Font.Gotham
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.Parent = Row

        -- Block / Unblock Button
        local BlockBtn = Instance.new("TextButton")
        BlockBtn.Size = UDim2.new(0, 58, 0, 22)
        BlockBtn.Position = UDim2.new(1, -62, 0.5, -11)
        BlockBtn.BackgroundColor3 = isBlocked
            and Color3.fromRGB(22, 100, 40)
            or  Color3.fromRGB(100, 20, 20)
        BlockBtn.Text = isBlocked and "✅ ON" or "🚫 OFF"
        BlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        BlockBtn.TextSize = 10
        BlockBtn.Font = Enum.Font.GothamBold
        BlockBtn.BorderSizePixel = 0
        BlockBtn.Parent = Row
        Instance.new("UICorner", BlockBtn).CornerRadius = UDim.new(0, 6)

        local capturedName = itemName
        BlockBtn.MouseButton1Click:Connect(function()
            if blockedItems[capturedName] then
                blockedItems[capturedName] = nil
            else
                blockedItems[capturedName] = true
            end
            -- Rebuild row นี้ใหม่
            BuildItemRows()
            UpdateCountLabel()
        end)

        itemRowMap[itemName] = Row
    end

    Scroll.CanvasSize = UDim2.new(0, 0, 0, (count * 33) + 8)
    UpdateCountLabel()
end

-- ============================================================
-- DRAG SYSTEM (Mobile-safe)
-- ============================================================
local dragging, dragStart, startPos = false, nil, nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ============================================================
-- BUTTON LOGIC
-- ============================================================

CloseBtn.MouseButton1Click:Connect(function()
    autoBuyEnabled = false
    ScreenGui:Destroy()
    warn("[GAG-Buy] UI closed")
end)

ScanBtn.MouseButton1Click:Connect(function()
    ScanBtn.Text = "⏳  กำลังสแกน..."
    ScanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    StatusTxt.Text = "🔍 กำลังสแกนของในร้าน..."
    task.wait(0.3)

    ScanItems()
    BuildItemRows()

    local cnt = 0
    for _ in pairs(scannedItems) do cnt = cnt + 1 end

    ScanBtn.Text = "🔄  SCAN อีกครั้ง (" .. cnt .. " รายการ)"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
    StatusTxt.Text = "✅ สแกนเสร็จ " .. cnt .. " รายการ — กด START ได้เลย"
    warn("[GAG-Buy] Scan done: " .. cnt .. " items")
end)

SpeedFast.MouseButton1Click:Connect(function()
    buyInterval = 0.1
    SpeedLabel.Text = "⚡ Speed: Fast (0.1s)"
    SpeedFast.BackgroundColor3   = Color3.fromRGB(34, 197, 94)
    SpeedNormal.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
end)

SpeedNormal.MouseButton1Click:Connect(function()
    buyInterval = 0.25
    SpeedLabel.Text = "⚡ Speed: Normal (0.25s)"
    SpeedFast.BackgroundColor3   = Color3.fromRGB(20, 80, 40)
    SpeedNormal.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
end)

StartBtn.MouseButton1Click:Connect(function()
    local cnt = 0
    for _ in pairs(scannedItems) do cnt = cnt + 1 end

    if cnt == 0 then
        StatusTxt.Text = "⚠️ กด SCAN ก่อน!"
        return
    end

    autoBuyEnabled = true
    StatusTxt.Text = "🟢 กำลังซื้อ... (ซื้อจนหมด)"
    StatusBox.BackgroundColor3 = Color3.fromRGB(15, 40, 15)
    StartBtn.Text = "⏳  RUNNING"
    StartBtn.BackgroundColor3 = Color3.fromRGB(15, 100, 45)
    warn("[GAG-Buy] Auto buy started")

    task.spawn(function()
        while autoBuyEnabled do
            -- ตรวจ character
            if not GetHRP() then
                StatusTxt.Text = "⚠️ รอ respawn..."
                task.wait(3)
            else
                StatusTxt.Text = "🟢 กำลังซื้อรอบใหม่..."
                local total = BuyAllUntilEmpty()
                if autoBuyEnabled then
                    StatusTxt.Text = "✅ ซื้อรอบนี้: " .. total .. " ชิ้น | รอ restock..."
                    warn("[GAG-Buy] Round done: " .. total .. " bought — waiting restock")
                    -- รอ restock (Grow a Garden restock ทุก ~1-5 นาที)
                    local waitTime = 60
                    for i = waitTime, 1, -1 do
                        if not autoBuyEnabled then break end
                        StatusTxt.Text = "⏳ รอ restock: " .. i .. "s"
                        task.wait(1)
                    end
                end
            end
        end
        StatusTxt.Text = "⬛ OFF — หยุดแล้ว"
        warn("[GAG-Buy] Loop ended")
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    autoBuyEnabled = false
    StatusBox.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
    StatusTxt.Text = "⬛ OFF — กด START เพื่อเริ่มใหม่"
    StartBtn.Text = "▶  START"
    StartBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
    warn("[GAG-Buy] Stopped by user")
end)

-- ============================================================
-- AUTO SCAN ตอนโหลด
-- ============================================================
task.spawn(function()
    task.wait(1.5)
    StatusTxt.Text = "🔍 Auto scanning..."
    ScanItems()
    BuildItemRows()
    local cnt = 0
    for _ in pairs(scannedItems) do cnt = cnt + 1 end
    ScanBtn.Text = "🔄  SCAN อีกครั้ง (" .. cnt .. " รายการ)"
    StatusTxt.Text = "✅ พร้อม! " .. cnt .. " รายการ — กด START ได้เลย"
    warn("[GAG-Buy] v3.0 loaded ✅ | Items: " .. cnt)
end)
