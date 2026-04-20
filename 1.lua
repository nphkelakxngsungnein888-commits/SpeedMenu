-- ============================================================
-- GAG AUTO BUY v3.1 - GROW A GARDEN
-- Features:
--   ✅ Scan ทุกร้านในแมพจาก workspace (ProximityPrompt + Billboard + Model)
--   ✅ Scan ของในแต่ละร้านจาก ReplicatedStorage + workspace GUI
--   ✅ ซื้อทุกอย่างที่มีขายจนหมด stock / เงินหมด
--   ✅ อยู่ที่ไหนก็ซื้อได้ (ยิง Remote ตรง ไม่ต้อง teleport)
--   ✅ UI แสดงร้านทั้งหมดที่เจอในแมพ + รายการของ + บล็อกได้
-- Platform: Mobile (Dobex) | Version: 3.1
-- ============================================================

-- SERVICES
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

-- VARIABLES
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP         = Character:WaitForChild("HumanoidRootPart")

local autoBuyEnabled = false
local scannedItems   = {}  -- { [itemName] = shopName }
local blockedItems   = {}  -- { [itemName] = true }
local buyInterval    = 0.25
-- allShops = { [shopName] = { prompt=obj|nil, position=vec3|nil, source="..." } }
local allShops       = {}
local shopCount      = 0

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
-- KEYWORDS
-- ============================================================
local SHOP_KW = {
    "shop","store","merchant","vendor","seller","npc",
    "seed","gear","tool","supply","market","stand",
    "pete","paul","farmer","shopkeeper","trader","buy"
}
local ITEM_BL = {
    "buy","sell","close","back","exit","menu","shop","store",
    "welcome","hello","interact","press","click","touch","open",
    "enter","leave","cancel","confirm","ok","yes","no","coins",
    "cash","money","balance","level","rank","info","help","quest"
}

local function MatchKw(str)
    local s = str:lower()
    for _, kw in ipairs(SHOP_KW) do
        if s:find(kw) then return true end
    end
    return false
end

local function IsBlacklisted(str)
    local s = str:lower():gsub("^%s+",""):gsub("%s+$","")
    for _, bl in ipairs(ITEM_BL) do
        if s == bl then return true end
    end
    return false
end

-- ============================================================
-- SCAN: หาทุกร้านในแมพ
-- ============================================================
local function ScanAllShopsInMap()
    allShops  = {}
    shopCount = 0

    -- Method 1: ProximityPrompt
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local at  = obj.ActionText or ""
            local ot  = obj.ObjectText or ""
            local pn  = (obj.Parent and obj.Parent.Name) or ""
            if MatchKw(at .. " " .. ot .. " " .. pn) then
                local pos = nil
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    pos = part.Position
                elseif part then
                    local mdl = part.Parent
                    if mdl and mdl:IsA("Model") then
                        local pp = mdl.PrimaryPart or mdl:FindFirstChildOfClass("BasePart")
                        if pp then pos = pp.Position end
                    end
                end
                local name = ot ~= "" and ot or at ~= "" and at or pn ~= "" and pn or ("Shop_"..shopCount)
                if not allShops[name] then
                    allShops[name] = { prompt=obj, position=pos, source="proxprompt" }
                    shopCount = shopCount + 1
                    warn("[GAG-Buy] 🚪 Shop (Prompt): " .. name)
                end
            end
        end
    end

    -- Method 2: BillboardGui / SurfaceGui
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") then
                    local txt = child.Text:gsub("^%s+",""):gsub("%s+$","")
                    if #txt >= 3 and MatchKw(txt) then
                        local part = obj.Parent
                        local pos  = (part and part:IsA("BasePart")) and part.Position or nil
                        if not allShops[txt] then
                            allShops[txt] = { prompt=nil, position=pos, source="billboard" }
                            shopCount = shopCount + 1
                            warn("[GAG-Buy] 📋 Shop (Billboard): " .. txt)
                        end
                        break
                    end
                end
            end
        end
    end

    -- Method 3: Model ชื่อตรง keyword
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and MatchKw(obj.Name) then
            if not allShops[obj.Name] then
                local pp  = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                allShops[obj.Name] = {
                    prompt   = nil,
                    position = pp and pp.Position or nil,
                    source   = "model"
                }
                shopCount = shopCount + 1
                warn("[GAG-Buy] 🏠 Shop (Model): " .. obj.Name)
            end
        end
    end

    -- Method 4: ReplicatedStorage folder
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if MatchKw(child.Name) and not allShops[child.Name] then
            allShops[child.Name] = { prompt=nil, position=nil, source="replstorage" }
            shopCount = shopCount + 1
            warn("[GAG-Buy] 📦 Shop (RS): " .. child.Name)
        end
    end

    warn("[GAG-Buy] Total shops: " .. shopCount)
    return allShops
end

-- ============================================================
-- SCAN: หาของในทุกร้าน
-- ============================================================
local function ScanItemsFromAllShops()
    scannedItems = {}
    local found  = 0

    local RS_KW = {
        "shop","item","seed","gear","product","stock",
        "catalog","store","goods","inventory","tool","supply"
    }

    local function ScanRSFolder(folder, shopName, depth)
        if depth > 5 then return end
        for _, child in ipairs(folder:GetChildren()) do
            local nl = child.Name:lower()
            if child:IsA("Folder") or child:IsA("Configuration") then
                for _, kw in ipairs(RS_KW) do
                    if nl:find(kw) then ScanRSFolder(child, shopName, depth+1); break end
                end
            end
            if child:IsA("StringValue") or child:IsA("IntValue")
                or child:IsA("NumberValue") or child:IsA("BoolValue")
                or child:IsA("Folder") then
                local clean = child.Name:gsub("^%s+",""):gsub("%s+$","")
                if #clean >= 3 and #clean <= 50
                    and not IsBlacklisted(clean)
                    and not clean:lower():find("remote")
                    and not clean:lower():find("event")
                    and not clean:lower():find("handler")
                    and not clean:lower():find("manager")
                    and not clean:lower():find("system")
                    and not clean:lower():find("script")
                    and not clean:lower():find("service") then
                    if not scannedItems[clean] then
                        scannedItems[clean] = shopName or "Unknown"
                        found = found + 1
                    end
                end
            end
        end
    end

    -- สแกนจากทุก shop ที่เจอ
    for shopName, _ in pairs(allShops) do
        local rsFolder = ReplicatedStorage:FindFirstChild(shopName)
        if rsFolder then ScanRSFolder(rsFolder, shopName, 0) end
    end

    -- สแกน RS ทั้งหมดด้วย keyword
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        local nl = child.Name:lower()
        for _, kw in ipairs(RS_KW) do
            if nl:find(kw) then ScanRSFolder(child, child.Name, 0); break end
        end
    end

    -- Method 2: workspace GUI
    if found == 0 then
        warn("[GAG-Buy] RS empty — scanning workspace GUI...")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Parent then
                local parent = obj.Parent
                if parent:IsA("BillboardGui") or parent:IsA("SurfaceGui") then
                    local txt = obj.Text:gsub("^%s+",""):gsub("%s+$","")
                    if #txt >= 3 and #txt <= 50
                        and not IsBlacklisted(txt)
                        and not txt:match("^%d")
                        and not txt:find("%$") then
                        local shopName = "Workspace"
                        local gp = parent.Parent
                        if gp then
                            if MatchKw(gp.Name) then shopName = gp.Name
                            elseif gp.Parent and MatchKw(gp.Parent.Name) then
                                shopName = gp.Parent.Name
                            end
                        end
                        if not scannedItems[txt] then
                            scannedItems[txt] = shopName
                            found = found + 1
                        end
                    end
                end
            end
        end
    end

    -- Fallback
    if found == 0 then
        warn("[GAG-Buy] Using GAG fallback list")
        local fb = {
            {"Carrot Seed","Seed Shop"},{"Strawberry Seed","Seed Shop"},
            {"Blueberry Seed","Seed Shop"},{"Tomato Seed","Seed Shop"},
            {"Corn Seed","Seed Shop"},{"Watermelon Seed","Seed Shop"},
            {"Pumpkin Seed","Seed Shop"},{"Grape Seed","Seed Shop"},
            {"Mango Seed","Seed Shop"},{"Dragon Fruit Seed","Seed Shop"},
            {"Bamboo Seed","Seed Shop"},{"Cactus Seed","Seed Shop"},
            {"Mushroom Seed","Seed Shop"},{"Sunflower Seed","Seed Shop"},
            {"Rose Seed","Seed Shop"},{"Magic Bean","Seed Shop"},
            {"Golden Seed","Seed Shop"},{"Mystery Seed","Seed Shop"},
            {"Watering Can","Gear Shop"},{"Fertilizer","Gear Shop"},
            {"Shovel","Gear Shop"},{"Hoe","Gear Shop"},
            {"Basic Sprinkler","Gear Shop"},{"Advanced Sprinkler","Gear Shop"},
            {"Trowel","Gear Shop"},{"Harvest Tool","Gear Shop"},
            {"Recall Wrench","Gear Shop"},{"Favorite Tool","Gear Shop"},
        }
        for _, p in ipairs(fb) do
            scannedItems[p[1]] = p[2]
            found = found + 1
        end
    end

    warn("[GAG-Buy] Total items: " .. found)
    return scannedItems
end

-- ============================================================
-- FIND BUY REMOTE
-- ============================================================
local cachedBuyRemote = nil

local function FindBuyRemote()
    if cachedBuyRemote and cachedBuyRemote.Parent then return cachedBuyRemote end
    local kws = {"buy","purchase","shop","order","acquire"}
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local nl = v.Name:lower()
            for _, kw in ipairs(kws) do
                if nl:find(kw) then
                    cachedBuyRemote = v
                    warn("[GAG-Buy] Remote: " .. v.Name .. " (" .. v.ClassName .. ")")
                    return v
                end
            end
        end
    end
    warn("[GAG-Buy] ❌ No buy remote")
    return nil
end

-- ============================================================
-- TRY BUY
-- ============================================================
local function TryBuyItem(itemName)
    if not itemName then return false end
    local hrp = GetHRP()
    if not hrp then return false end
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local remote = FindBuyRemote()
    if not remote then return false end

    local success = false
    local argSets = {
        {itemName},
        {itemName, 1},
        {itemName, 1, "buy"},
        {1, itemName},
        {{item=itemName, amount=1}},
        {{name=itemName, quantity=1}},
    }

    for _, args in ipairs(argSets) do
        if success then break end
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(table.unpack(args)); success = true
            elseif remote:IsA("RemoteFunction") then
                local r = remote:InvokeServer(table.unpack(args))
                success = r ~= false and r ~= nil
            end
        end)
        if success then warn("[GAG-Buy] ✅ " .. itemName); return true end
        task.wait(0.04)
    end

    -- fallback: scan all
    if not success then
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name:lower():find("buy") then
                pcall(function()
                    if v:IsA("RemoteEvent") then v:FireServer(itemName)
                    else v:InvokeServer(itemName) end
                    success = true
                end)
                if success then break end
            end
        end
    end
    return success
end

-- ============================================================
-- BUY ALL UNTIL EMPTY
-- ============================================================
local function BuyAllUntilEmpty()
    local total = 0
    local failC = {}

    for itemName, _ in pairs(scannedItems) do
        if not autoBuyEnabled then break end
        if blockedItems[itemName] then continue end

        failC[itemName] = 0
        local itemBought = 0

        while autoBuyEnabled do
            local ok = TryBuyItem(itemName)
            if ok then
                itemBought = itemBought + 1
                total      = total + 1
                failC[itemName] = 0
            else
                failC[itemName] = failC[itemName] + 1
                if failC[itemName] >= 3 then
                    if itemBought > 0 then
                        warn("[GAG-Buy] Done: " .. itemName .. " x" .. itemBought)
                    end
                    break
                end
            end
            task.wait(buyInterval)
        end
    end
    return total
end

-- ============================================================
-- UI
-- ============================================================
local oldGui = PlayerGui:FindFirstChild("GAGAutoBuyUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "GAGAutoBuyUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.Parent         = PlayerGui

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 310, 0, 560)
Main.Position         = UDim2.new(0, 16, 0.5, -280)
Main.BackgroundColor3 = Color3.fromRGB(13,17,23)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.ClipsDescendants = true
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,16)
local Stroke = Instance.new("UIStroke")
Stroke.Color=Color3.fromRGB(34,197,94); Stroke.Thickness=1.5; Stroke.Transparency=0.4
Stroke.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size=UDim2.new(1,0,0,48); TitleBar.BackgroundColor3=Color3.fromRGB(17,24,39)
TitleBar.BorderSizePixel=0; TitleBar.Parent=Main
Instance.new("UICorner",TitleBar).CornerRadius=UDim.new(0,16)
local TFix=Instance.new("Frame"); TFix.Size=UDim2.new(1,0,0,8)
TFix.Position=UDim2.new(0,0,1,-8); TFix.BackgroundColor3=Color3.fromRGB(17,24,39)
TFix.BorderSizePixel=0; TFix.Parent=TitleBar

local TitleTxt=Instance.new("TextLabel")
TitleTxt.Size=UDim2.new(1,-50,1,0); TitleTxt.Position=UDim2.new(0,14,0,0)
TitleTxt.BackgroundTransparency=1; TitleTxt.Text="🌱 GAG Auto Buy v3.1"
TitleTxt.TextColor3=Color3.fromRGB(134,239,172); TitleTxt.TextSize=14
TitleTxt.Font=Enum.Font.GothamBold; TitleTxt.TextXAlignment=Enum.TextXAlignment.Left
TitleTxt.Parent=TitleBar

local CloseBtn=Instance.new("TextButton")
CloseBtn.Size=UDim2.new(0,32,0,32); CloseBtn.Position=UDim2.new(1,-40,0.5,-16)
CloseBtn.BackgroundColor3=Color3.fromRGB(60,20,20); CloseBtn.Text="✕"
CloseBtn.TextColor3=Color3.fromRGB(255,100,100); CloseBtn.TextSize=13
CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.BorderSizePixel=0; CloseBtn.Parent=TitleBar
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,8)

-- Status
local StatusBox=Instance.new("Frame")
StatusBox.Size=UDim2.new(1,-16,0,34); StatusBox.Position=UDim2.new(0,8,0,54)
StatusBox.BackgroundColor3=Color3.fromRGB(20,30,20); StatusBox.BorderSizePixel=0
StatusBox.Parent=Main; Instance.new("UICorner",StatusBox).CornerRadius=UDim.new(0,8)
local StatusTxt=Instance.new("TextLabel")
StatusTxt.Size=UDim2.new(1,-12,1,0); StatusTxt.Position=UDim2.new(0,8,0,0)
StatusTxt.BackgroundTransparency=1; StatusTxt.Text="⬛ OFF — กด SCAN ก่อน"
StatusTxt.TextColor3=Color3.fromRGB(150,200,150); StatusTxt.TextSize=11
StatusTxt.Font=Enum.Font.Gotham; StatusTxt.TextXAlignment=Enum.TextXAlignment.Left
StatusTxt.TextTruncate=Enum.TextTruncate.AtEnd; StatusTxt.Parent=StatusBox

-- Shop section label
local ShopLabel=Instance.new("TextLabel")
ShopLabel.Size=UDim2.new(1,-16,0,18); ShopLabel.Position=UDim2.new(0,8,0,94)
ShopLabel.BackgroundTransparency=1; ShopLabel.Text="🏪 ร้านที่พบในแมพ:"
ShopLabel.TextColor3=Color3.fromRGB(134,239,172); ShopLabel.TextSize=11
ShopLabel.Font=Enum.Font.GothamBold; ShopLabel.TextXAlignment=Enum.TextXAlignment.Left
ShopLabel.Parent=Main

local ShopScroll=Instance.new("ScrollingFrame")
ShopScroll.Size=UDim2.new(1,-16,0,80); ShopScroll.Position=UDim2.new(0,8,0,114)
ShopScroll.BackgroundColor3=Color3.fromRGB(10,14,20); ShopScroll.BorderSizePixel=0
ShopScroll.ScrollBarThickness=3; ShopScroll.ScrollBarImageColor3=Color3.fromRGB(34,197,94)
ShopScroll.CanvasSize=UDim2.new(0,0,0,0); ShopScroll.Parent=Main
Instance.new("UICorner",ShopScroll).CornerRadius=UDim.new(0,8)
local ShopLayout=Instance.new("UIListLayout")
ShopLayout.Padding=UDim.new(0,3); ShopLayout.SortOrder=Enum.SortOrder.Name
ShopLayout.Parent=ShopScroll
local ShopPad=Instance.new("UIPadding")
ShopPad.PaddingTop=UDim.new(0,4); ShopPad.PaddingLeft=UDim.new(0,4)
ShopPad.PaddingRight=UDim.new(0,4); ShopPad.Parent=ShopScroll

-- Scan button
local ScanBtn=Instance.new("TextButton")
ScanBtn.Size=UDim2.new(1,-16,0,36); ScanBtn.Position=UDim2.new(0,8,0,200)
ScanBtn.BackgroundColor3=Color3.fromRGB(37,99,235); ScanBtn.Text="🔍  SCAN ทุกร้านในแมพ"
ScanBtn.TextColor3=Color3.fromRGB(255,255,255); ScanBtn.TextSize=13
ScanBtn.Font=Enum.Font.GothamBold; ScanBtn.BorderSizePixel=0; ScanBtn.Parent=Main
Instance.new("UICorner",ScanBtn).CornerRadius=UDim.new(0,10)

-- Count label
local CountTxt=Instance.new("TextLabel")
CountTxt.Size=UDim2.new(1,-16,0,18); CountTxt.Position=UDim2.new(0,8,0,242)
CountTxt.BackgroundTransparency=1; CountTxt.Text="📦 ของ: 0  |  🏪 ร้าน: 0  |  🚫 บล็อก: 0"
CountTxt.TextColor3=Color3.fromRGB(100,160,100); CountTxt.TextSize=11
CountTxt.Font=Enum.Font.Gotham; CountTxt.TextXAlignment=Enum.TextXAlignment.Left
CountTxt.Parent=Main

-- Item section label
local ItemLbl=Instance.new("TextLabel")
ItemLbl.Size=UDim2.new(1,-16,0,18); ItemLbl.Position=UDim2.new(0,8,0,262)
ItemLbl.BackgroundTransparency=1; ItemLbl.Text="🛒 รายการของทั้งหมด:"
ItemLbl.TextColor3=Color3.fromRGB(134,239,172); ItemLbl.TextSize=11
ItemLbl.Font=Enum.Font.GothamBold; ItemLbl.TextXAlignment=Enum.TextXAlignment.Left
ItemLbl.Parent=Main

local Scroll=Instance.new("ScrollingFrame")
Scroll.Size=UDim2.new(1,-16,0,188); Scroll.Position=UDim2.new(0,8,0,282)
Scroll.BackgroundColor3=Color3.fromRGB(10,14,20); Scroll.BorderSizePixel=0
Scroll.ScrollBarThickness=3; Scroll.ScrollBarImageColor3=Color3.fromRGB(34,197,94)
Scroll.CanvasSize=UDim2.new(0,0,0,0); Scroll.Parent=Main
Instance.new("UICorner",Scroll).CornerRadius=UDim.new(0,10)
local ListLayout=Instance.new("UIListLayout")
ListLayout.Padding=UDim.new(0,3); ListLayout.SortOrder=Enum.SortOrder.Name
ListLayout.Parent=Scroll
local ListPad=Instance.new("UIPadding")
ListPad.PaddingTop=UDim.new(0,4); ListPad.PaddingLeft=UDim.new(0,4)
ListPad.PaddingRight=UDim.new(0,4); ListPad.PaddingBottom=UDim.new(0,4)
ListPad.Parent=Scroll

-- Speed
local SpeedFrame=Instance.new("Frame")
SpeedFrame.Size=UDim2.new(1,-16,0,30); SpeedFrame.Position=UDim2.new(0,8,0,476)
SpeedFrame.BackgroundColor3=Color3.fromRGB(17,24,39); SpeedFrame.BorderSizePixel=0
SpeedFrame.Parent=Main; Instance.new("UICorner",SpeedFrame).CornerRadius=UDim.new(0,8)
local SpeedLabel=Instance.new("TextLabel")
SpeedLabel.Size=UDim2.new(0.5,0,1,0); SpeedLabel.Position=UDim2.new(0,10,0,0)
SpeedLabel.BackgroundTransparency=1; SpeedLabel.Text="⚡ Normal (0.25s)"
SpeedLabel.TextColor3=Color3.fromRGB(180,180,200); SpeedLabel.TextSize=11
SpeedLabel.Font=Enum.Font.Gotham; SpeedLabel.TextXAlignment=Enum.TextXAlignment.Left
SpeedLabel.Parent=SpeedFrame
local SpeedFast=Instance.new("TextButton")
SpeedFast.Size=UDim2.new(0,50,0,20); SpeedFast.Position=UDim2.new(1,-114,0.5,-10)
SpeedFast.BackgroundColor3=Color3.fromRGB(30,60,30); SpeedFast.Text="Fast"
SpeedFast.TextColor3=Color3.fromRGB(200,255,200); SpeedFast.TextSize=11
SpeedFast.Font=Enum.Font.GothamBold; SpeedFast.BorderSizePixel=0; SpeedFast.Parent=SpeedFrame
Instance.new("UICorner",SpeedFast).CornerRadius=UDim.new(0,6)
local SpeedNormal=Instance.new("TextButton")
SpeedNormal.Size=UDim2.new(0,58,0,20); SpeedNormal.Position=UDim2.new(1,-60,0.5,-10)
SpeedNormal.BackgroundColor3=Color3.fromRGB(34,197,94); SpeedNormal.Text="Normal"
SpeedNormal.TextColor3=Color3.fromRGB(0,0,0); SpeedNormal.TextSize=11
SpeedNormal.Font=Enum.Font.GothamBold; SpeedNormal.BorderSizePixel=0; SpeedNormal.Parent=SpeedFrame
Instance.new("UICorner",SpeedNormal).CornerRadius=UDim.new(0,6)

-- Start / Stop
local StartBtn=Instance.new("TextButton")
StartBtn.Size=UDim2.new(0.5,-6,0,42); StartBtn.Position=UDim2.new(0,8,0,512)
StartBtn.BackgroundColor3=Color3.fromRGB(22,163,74); StartBtn.Text="▶  START"
StartBtn.TextColor3=Color3.fromRGB(255,255,255); StartBtn.TextSize=14
StartBtn.Font=Enum.Font.GothamBold; StartBtn.BorderSizePixel=0; StartBtn.Parent=Main
Instance.new("UICorner",StartBtn).CornerRadius=UDim.new(0,12)
local StopBtn=Instance.new("TextButton")
StopBtn.Size=UDim2.new(0.5,-6,0,42); StopBtn.Position=UDim2.new(0.5,-2,0,512)
StopBtn.BackgroundColor3=Color3.fromRGB(80,20,20); StopBtn.Text="⏹  STOP"
StopBtn.TextColor3=Color3.fromRGB(255,100,100); StopBtn.TextSize=14
StopBtn.Font=Enum.Font.GothamBold; StopBtn.BorderSizePixel=0; StopBtn.Parent=Main
Instance.new("UICorner",StopBtn).CornerRadius=UDim.new(0,12)

-- ============================================================
-- BUILD UI
-- ============================================================
local shopRowMap = {}
local itemRowMap = {}

local function UpdateCount()
    local total, blocked = 0, 0
    for n,_ in pairs(scannedItems) do
        total = total + 1
        if blockedItems[n] then blocked = blocked + 1 end
    end
    CountTxt.Text = "📦 ของ: "..total.."  |  🏪 ร้าน: "..shopCount.."  |  🚫 บล็อก: "..blocked
end

local function BuildShopRows()
    for _,r in pairs(shopRowMap) do r:Destroy() end
    shopRowMap = {}
    local names = {}
    for n,_ in pairs(allShops) do table.insert(names,n) end
    table.sort(names)
    for _, sn in ipairs(names) do
        local data = allShops[sn]
        local icon = data.source=="proxprompt" and "🚪"
            or data.source=="billboard" and "📋"
            or data.source=="model" and "🏠" or "📦"
        local Row=Instance.new("Frame")
        Row.Name=sn; Row.Size=UDim2.new(1,0,0,26)
        Row.BackgroundColor3=Color3.fromRGB(20,35,20)
        Row.BorderSizePixel=0; Row.Parent=ShopScroll
        Instance.new("UICorner",Row).CornerRadius=UDim.new(0,6)
        local Lbl=Instance.new("TextLabel")
        Lbl.Size=UDim2.new(1,-8,1,0); Lbl.Position=UDim2.new(0,8,0,0)
        Lbl.BackgroundTransparency=1
        Lbl.Text=icon.." "..sn.."  ["..data.source.."]"
        Lbl.TextColor3=Color3.fromRGB(160,240,160); Lbl.TextSize=11
        Lbl.Font=Enum.Font.Gotham; Lbl.TextXAlignment=Enum.TextXAlignment.Left
        Lbl.TextTruncate=Enum.TextTruncate.AtEnd; Lbl.Parent=Row
        table.insert(shopRowMap, Row)
    end
    ShopScroll.CanvasSize=UDim2.new(0,0,0,(#names*29)+8)
end

local function BuildItemRows()
    for _,r in pairs(itemRowMap) do r:Destroy() end
    itemRowMap = {}
    local names = {}
    for n,_ in pairs(scannedItems) do table.insert(names,n) end
    table.sort(names)
    for _, itemName in ipairs(names) do
        local shopTag = scannedItems[itemName] or ""
        local isBlock = blockedItems[itemName] == true
        local Row=Instance.new("Frame")
        Row.Name=itemName; Row.Size=UDim2.new(1,0,0,30)
        Row.BackgroundColor3=isBlock and Color3.fromRGB(40,15,15) or Color3.fromRGB(20,30,20)
        Row.BorderSizePixel=0; Row.Parent=Scroll
        Instance.new("UICorner",Row).CornerRadius=UDim.new(0,6)
        local NameLbl=Instance.new("TextLabel")
        NameLbl.Size=UDim2.new(1,-70,1,0); NameLbl.Position=UDim2.new(0,8,0,0)
        NameLbl.BackgroundTransparency=1
        NameLbl.Text=(isBlock and "🚫 " or "✅ ")..itemName
            ..(shopTag~="" and ("  · "..shopTag) or "")
        NameLbl.TextColor3=isBlock and Color3.fromRGB(120,60,60) or Color3.fromRGB(180,255,180)
        NameLbl.TextSize=10; NameLbl.Font=Enum.Font.Gotham
        NameLbl.TextXAlignment=Enum.TextXAlignment.Left
        NameLbl.TextTruncate=Enum.TextTruncate.AtEnd; NameLbl.Parent=Row
        local BlockBtn=Instance.new("TextButton")
        BlockBtn.Size=UDim2.new(0,56,0,22); BlockBtn.Position=UDim2.new(1,-60,0.5,-11)
        BlockBtn.BackgroundColor3=isBlock and Color3.fromRGB(22,100,40) or Color3.fromRGB(100,20,20)
        BlockBtn.Text=isBlock and "✅ ON" or "🚫 OFF"
        BlockBtn.TextColor3=Color3.fromRGB(255,255,255); BlockBtn.TextSize=10
        BlockBtn.Font=Enum.Font.GothamBold; BlockBtn.BorderSizePixel=0; BlockBtn.Parent=Row
        Instance.new("UICorner",BlockBtn).CornerRadius=UDim.new(0,6)
        local cn=itemName
        BlockBtn.MouseButton1Click:Connect(function()
            blockedItems[cn] = not blockedItems[cn] or nil
            BuildItemRows(); UpdateCount()
        end)
        table.insert(itemRowMap, Row)
    end
    Scroll.CanvasSize=UDim2.new(0,0,0,(#names*33)+8)
    UpdateCount()
end

-- ============================================================
-- DRAG
-- ============================================================
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=i.Position; startPos=Main.Position end end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=false end end)

-- ============================================================
-- BUTTONS
-- ============================================================
CloseBtn.MouseButton1Click:Connect(function()
    autoBuyEnabled=false; ScreenGui:Destroy(); warn("[GAG-Buy] Closed") end)

ScanBtn.MouseButton1Click:Connect(function()
    ScanBtn.Text="⏳  กำลังสแกนแมพ..."
    ScanBtn.BackgroundColor3=Color3.fromRGB(60,60,60)
    StatusTxt.Text="🔍 สแกนร้านทั้งหมดในแมพ..."
    task.wait(0.3)
    ScanAllShopsInMap(); BuildShopRows()
    ScanItemsFromAllShops(); BuildItemRows()
    local cnt=0; for _ in pairs(scannedItems) do cnt=cnt+1 end
    ScanBtn.Text="🔄  SCAN อีกครั้ง"
    ScanBtn.BackgroundColor3=Color3.fromRGB(37,99,235)
    StatusTxt.Text="✅ ร้าน: "..shopCount.."  ของ: "..cnt.." — กด START"
    warn("[GAG-Buy] Scan done | shops:"..shopCount.." items:"..cnt) end)

SpeedFast.MouseButton1Click:Connect(function()
    buyInterval=0.1; SpeedLabel.Text="⚡ Fast (0.1s)"
    SpeedFast.BackgroundColor3=Color3.fromRGB(34,197,94)
    SpeedNormal.BackgroundColor3=Color3.fromRGB(30,50,30) end)

SpeedNormal.MouseButton1Click:Connect(function()
    buyInterval=0.25; SpeedLabel.Text="⚡ Normal (0.25s)"
    SpeedFast.BackgroundColor3=Color3.fromRGB(30,60,30)
    SpeedNormal.BackgroundColor3=Color3.fromRGB(34,197,94) end)

StartBtn.MouseButton1Click:Connect(function()
    local cnt=0; for _ in pairs(scannedItems) do cnt=cnt+1 end
    if cnt==0 then StatusTxt.Text="⚠️ กด SCAN ก่อน!"; return end
    autoBuyEnabled=true
    StatusBox.BackgroundColor3=Color3.fromRGB(15,40,15)
    StatusTxt.Text="🟢 กำลังซื้อ..."
    StartBtn.Text="⏳  RUNNING"; StartBtn.BackgroundColor3=Color3.fromRGB(15,100,45)
    warn("[GAG-Buy] Started")
    task.spawn(function()
        while autoBuyEnabled do
            if not GetHRP() then
                StatusTxt.Text="⚠️ รอ respawn..."; task.wait(3)
            else
                StatusTxt.Text="🟢 กำลังซื้อรอบใหม่..."
                local total=BuyAllUntilEmpty()
                if autoBuyEnabled then
                    warn("[GAG-Buy] Round done: "..total.." items")
                    for i=60,1,-1 do
                        if not autoBuyEnabled then break end
                        StatusTxt.Text="⏳ รอ restock: "..i.."s | ซื้อไป: "..total
                        task.wait(1)
                    end
                end
            end
        end
        StatusTxt.Text="⬛ OFF"; warn("[GAG-Buy] Loop ended") end) end)

StopBtn.MouseButton1Click:Connect(function()
    autoBuyEnabled=false
    StatusBox.BackgroundColor3=Color3.fromRGB(20,30,20)
    StatusTxt.Text="⬛ OFF — กด START เพื่อเริ่มใหม่"
    StartBtn.Text="▶  START"; StartBtn.BackgroundColor3=Color3.fromRGB(22,163,74)
    warn("[GAG-Buy] Stopped") end)

-- ============================================================
-- AUTO SCAN ON LOAD
-- ============================================================
task.spawn(function()
    task.wait(2)
    StatusTxt.Text="🔍 Auto scanning map..."
    ScanAllShopsInMap(); BuildShopRows()
    ScanItemsFromAllShops(); BuildItemRows()
    local cnt=0; for _ in pairs(scannedItems) do cnt=cnt+1 end
    ScanBtn.Text="🔄  SCAN อีกครั้ง"
    StatusTxt.Text="✅ ร้าน: "..shopCount.."  ของ: "..cnt.." — กด START"
    warn("[GAG-Buy] v3.1 ready | shops:"..shopCount.." items:"..cnt) end)
