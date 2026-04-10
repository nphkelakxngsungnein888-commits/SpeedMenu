-- Lock Menu v19 | Based on v17 (stable) + Crosshair + AimX + SubLock + NoCamZoom
-- CoreGui parent + keepalive

--// SERVICES
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()

-- ══ SAVE / LOAD ══
local _S = _G.LockMenuSave or {}
local Settings = {
    LockStrength  = _S.LockStrength or 1,
    LockRange     = _S.LockRange    or 200,
    Mode          = _S.Mode         or "NPC",
    Enabled       = false,
    NearestMode   = _S.NearestMode  or false,
    FilterColor   = nil,
    ESPEnabled    = false,
    ExcludeColors = {},
    MouseLock     = false,
}
local AIM_OFFSET   = _S.AIM_OFFSET   or 0   -- ขึ้น/ลง
local AIM_OFFSET_X = _S.AIM_OFFSET_X or 0   -- ซ้าย/ขวา
local CAM_DISTANCE = _S.CAM_DISTANCE or 0
local CAM_HEIGHT   = 3
local LOCK_CAM_DIST = nil  -- จำระยะกล้องตอนกด Lock

local function SaveSettings()
    _G.LockMenuSave = {
        LockStrength = Settings.LockStrength,
        LockRange    = Settings.LockRange,
        Mode         = Settings.Mode,
        NearestMode  = Settings.NearestMode,
        AIM_OFFSET   = AIM_OFFSET,
        AIM_OFFSET_X = AIM_OFFSET_X,
        CAM_DISTANCE = CAM_DISTANCE,
    }
end

-- ══ STATE ══
local Character     = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local currentTarget = nil
local targetList    = {}
local targetIndex   = 1
local lockConn      = nil
local foundColors   = {}
local forceRescan   = false
local TPScanEnabled = false
local scanTPMode    = "single"
local scanTPRapidHz = 10
local scanTPRapidConn = nil
local espBoxes      = {}
local espTimer      = 0
local ESP_INTERVAL  = 0.3
local SCAN_INT      = 0.1
local tpSaves       = {}
local tpSelected    = nil
local clickTP       = false
local lockPos       = nil
-- CamSystem
local camLocked   = false
local camFreecam  = false
local camDist     = 50
local camSpeed    = 5
local camAngleX   = 0
local camAngleY   = 0
local camMove     = Vector3.new()
local camFreePos  = Vector3.new()

-- ══ GUI CLEANUP ══
pcall(function()
    for _, n in ipairs({"LM_v16","LM_v17","LM_v18","LM_v19","LM_v19_Cross"}) do
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg and pg:FindFirstChild(n) then pg:FindFirstChild(n):Destroy() end
        if CoreGui:FindFirstChild(n) then CoreGui:FindFirstChild(n):Destroy() end
    end
end)

-- ══ MAIN GUI ══
local SG = Instance.new("ScreenGui")
SG.Name = "LM_v19"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.DisplayOrder = 999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = CoreGui

-- Keepalive
task.spawn(function()
    while task.wait(1) do
        if not SG or not SG.Parent then SG.Parent = CoreGui end
    end
end)

-- ══ CROSSHAIR GUI ══
local CrossSG = Instance.new("ScreenGui")
CrossSG.Name = "LM_v19_Cross"
CrossSG.ResetOnSpawn = false
CrossSG.IgnoreGuiInset = true
CrossSG.DisplayOrder = 1000
CrossSG.Parent = CoreGui

local CrossOuter = Instance.new("Frame")
CrossOuter.Size = UDim2.new(0,22,0,22)
CrossOuter.AnchorPoint = Vector2.new(0.5,0.5)
CrossOuter.Position = UDim2.new(0.5,0,0.5,0)
CrossOuter.BackgroundTransparency = 1
CrossOuter.BorderSizePixel = 0
CrossOuter.Visible = false
CrossOuter.Parent = CrossSG
Instance.new("UICorner", CrossOuter).CornerRadius = UDim.new(1,0)
local CrossRing = Instance.new("UIStroke", CrossOuter)
CrossRing.Color = Color3.fromRGB(255,60,60)
CrossRing.Thickness = 2

local CrossH = Instance.new("Frame")
CrossH.Size = UDim2.new(0,14,0,2)
CrossH.AnchorPoint = Vector2.new(0.5,0.5)
CrossH.BackgroundColor3 = Color3.fromRGB(255,60,60)
CrossH.BorderSizePixel = 0
CrossH.Visible = false
CrossH.Parent = CrossSG
Instance.new("UICorner",CrossH).CornerRadius = UDim.new(0,1)

local CrossV = Instance.new("Frame")
CrossV.Size = UDim2.new(0,2,0,14)
CrossV.AnchorPoint = Vector2.new(0.5,0.5)
CrossV.BackgroundColor3 = Color3.fromRGB(255,60,60)
CrossV.BorderSizePixel = 0
CrossV.Visible = false
CrossV.Parent = CrossSG
Instance.new("UICorner",CrossV).CornerRadius = UDim.new(0,1)

local function UpdateCrosshairPos()
    local offX = AIM_OFFSET_X * 8
    local offY = -AIM_OFFSET  * 8
    CrossOuter.Position = UDim2.new(0.5, offX, 0.5, offY)
    CrossH.Position     = UDim2.new(0.5, offX, 0.5, offY)
    CrossV.Position     = UDim2.new(0.5, offX, 0.5, offY)
end

local function SetCrosshair(on)
    CrossOuter.Visible = on
    CrossH.Visible = on
    CrossV.Visible = on
    if on then UpdateCrosshairPos() end
end

-- ══ UI FACTORY ══
local function Hex(c)
    return string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
end

local function mkFrame(par,sz,pos,bg,clip,r)
    local f = Instance.new("Frame")
    f.Size=sz; f.Position=pos
    f.BackgroundColor3 = bg or Color3.fromRGB(13,13,19)
    f.BorderSizePixel = 0
    if clip then f.ClipsDescendants = true end
    f.Parent = par
    if r ~= false then Instance.new("UICorner",f).CornerRadius = UDim.new(0,r or 8) end
    return f
end

local function mkBtn(par,txt,sz,pos,bg,tc,ts)
    local b = Instance.new("TextButton")
    b.Size=sz; b.Position=pos
    b.BackgroundColor3 = bg or Color3.fromRGB(28,28,44)
    b.BorderSizePixel=0; b.Text=txt
    b.TextColor3 = tc or Color3.fromRGB(205,205,255)
    b.TextSize = ts or 11; b.Font = Enum.Font.GothamBold
    b.AutoButtonColor=false; b.Parent=par
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local function mkLbl(par,txt,sz,pos,ts,tc,font,xa)
    local l = Instance.new("TextLabel")
    l.Size=sz; l.Position=pos; l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3 = tc or Color3.fromRGB(155,155,205)
    l.TextSize = ts or 10; l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.Parent=par; return l
end

local function mkInp(par,def,sz,pos)
    local b = Instance.new("TextBox")
    b.Size=sz; b.Position=pos
    b.BackgroundColor3=Color3.fromRGB(19,19,30); b.BorderSizePixel=0
    b.Text=tostring(def); b.TextColor3=Color3.fromRGB(225,225,255)
    b.TextSize=11; b.Font=Enum.Font.Gotham; b.Parent=par
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end

local function mkDiv(par,y)
    local d = Instance.new("Frame")
    d.Size=UDim2.new(1,-16,0,1); d.Position=UDim2.new(0,8,0,y)
    d.BackgroundColor3=Color3.fromRGB(36,36,55); d.BorderSizePixel=0; d.Parent=par
end

local function mkAccent(par,col)
    local a = Instance.new("Frame")
    a.Size=UDim2.new(1,0,0,2); a.Position=UDim2.new(0,0,1,-2)
    a.BackgroundColor3 = col or Color3.fromRGB(72,110,245)
    a.BorderSizePixel=0; a.Parent=par
end

local function mkDrag(frame,handle,lockFn)
    local drag,ds,sp = false,nil,nil
    handle.InputBegan:Connect(function(i)
        if lockFn and lockFn() then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=frame.Position
        end
    end)
    local function mv(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end
    local function en(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end
    handle.InputChanged:Connect(mv); UserInputService.InputChanged:Connect(mv)
    handle.InputEnded:Connect(en);   UserInputService.InputEnded:Connect(en)
end

local function mkResize(titleBar, frame, minW, maxW, minH, maxH)
    local bS=mkBtn(titleBar,"◀",UDim2.new(0,18,0,18),UDim2.new(0,4,0.5,-9),Color3.fromRGB(28,28,46),Color3.fromRGB(150,150,210),9)
    local bL=mkBtn(titleBar,"▶",UDim2.new(0,18,0,18),UDim2.new(0,24,0.5,-9),Color3.fromRGB(28,28,46),Color3.fromRGB(150,150,210),9)
    local step=20
    bS.Activated:Connect(function()
        local s=frame.AbsoluteSize
        frame.Size=UDim2.new(0,math.max(minW,s.X-step),0,math.max(minH,s.Y-step))
    end)
    bL.Activated:Connect(function()
        local s=frame.AbsoluteSize
        frame.Size=UDim2.new(0,math.min(maxW,s.X+step),0,math.min(maxH,s.Y+step))
    end)
end

-- ══ SUB-MENU LOCK HELPER ══
local function mkSubLockBtn(tb, frame, lockState)
    local btn = mkBtn(tb,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-70,0.5,-11),Color3.fromRGB(40,40,62))
    btn.Activated:Connect(function()
        lockState[1] = not lockState[1]
        btn.Text = lockState[1] and "🔒" or "🔓"
        btn.BackgroundColor3 = lockState[1] and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62)
    end)
    return btn
end

-- ══════════════════════════════════════════════
--   MAIN FRAME
-- ══════════════════════════════════════════════
local menuLocked = false
-- ขนาดสูงขึ้นจากเดิม 370 → 440 เพื่อรองรับ AimX + MouseLock
local MF = mkFrame(SG, UDim2.new(0,232,0,440), UDim2.new(0.5,-116,0.5,-220), Color3.fromRGB(11,11,17), true)

local TB = mkFrame(MF, UDim2.new(1,0,0,32), UDim2.new(0,0,0,0), Color3.fromRGB(17,17,28), false, 8)
TB.ClipsDescendants=false; mkAccent(TB)
mkDrag(MF, TB, function() return menuLocked end)
mkLbl(TB,"⚔ Lock Menu v19",UDim2.new(1,-112,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(TB, MF, 180, 320, 300, 500)
local BtnLockMenu = mkBtn(TB,"🔓",UDim2.new(0,22,0,22),UDim2.new(1,-72,0.5,-11),Color3.fromRGB(40,40,62))
local BtnMin      = mkBtn(TB,"–", UDim2.new(0,22,0,22),UDim2.new(1,-48,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),14)
local BtnClose    = mkBtn(TB,"✕", UDim2.new(0,22,0,22),UDim2.new(1,-24,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)

local Con = Instance.new("Frame")
Con.Size=UDim2.new(1,0,1,-32); Con.Position=UDim2.new(0,0,0,32)
Con.BackgroundTransparency=1; Con.Parent=MF

-- MODE
mkLbl(Con,"🎯 MODE",UDim2.new(0,80,0,13),UDim2.new(0,8,0,6),9)
local BtnPlayer = mkBtn(Con,"👤 Player",UDim2.new(0,100,0,26),UDim2.new(0,8,0,21),Color3.fromRGB(28,28,46),Color3.fromRGB(148,158,218))
local BtnNPC    = mkBtn(Con,"🤖 NPC",   UDim2.new(0,100,0,26),UDim2.new(0,116,0,21),Color3.fromRGB(62,92,205),Color3.fromRGB(255,255,255))

local function UpdateModeUI()
    if Settings.Mode=="Player" then
        BtnPlayer.BackgroundColor3=Color3.fromRGB(62,92,205); BtnPlayer.TextColor3=Color3.fromRGB(255,255,255)
        BtnNPC.BackgroundColor3=Color3.fromRGB(28,28,46);    BtnNPC.TextColor3=Color3.fromRGB(148,158,218)
    else
        BtnNPC.BackgroundColor3=Color3.fromRGB(62,92,205);   BtnNPC.TextColor3=Color3.fromRGB(255,255,255)
        BtnPlayer.BackgroundColor3=Color3.fromRGB(28,28,46); BtnPlayer.TextColor3=Color3.fromRGB(148,158,218)
    end
end; UpdateModeUI()

mkDiv(Con,53)

-- RANGE
mkLbl(Con,"📏 Range",UDim2.new(1,-16,0,13),UDim2.new(0,8,0,57),9)
local InpRange = mkInp(Con, Settings.LockRange, UDim2.new(1,-16,0,24), UDim2.new(0,8,0,70))

mkDiv(Con,100)

-- AIM Y + AIM X
mkLbl(Con,"⬆ Aim Y (↑บน ↓ล่าง)",  UDim2.new(0,108,0,13), UDim2.new(0,8,0,104),  9)
mkLbl(Con,"↔ Aim X (←ซ้าย →ขวา)", UDim2.new(0,108,0,13), UDim2.new(0,118,0,104), 9)
local InpAim  = mkInp(Con, AIM_OFFSET,   UDim2.new(0,80,0,22), UDim2.new(0,8,0,117))
local InpAimX = mkInp(Con, AIM_OFFSET_X, UDim2.new(0,80,0,22), UDim2.new(0,118,0,117))
-- +/- Y
local BtnAimUp = mkBtn(Con,"+",UDim2.new(0,22,0,20),UDim2.new(0,90,0,117),Color3.fromRGB(35,55,35),Color3.fromRGB(175,255,175),12)
local BtnAimDn = mkBtn(Con,"–",UDim2.new(0,22,0,20),UDim2.new(0,90,0,139),Color3.fromRGB(55,28,28),Color3.fromRGB(255,175,175),12)
-- +/- X
local BtnAimXR = mkBtn(Con,"+",UDim2.new(0,22,0,20),UDim2.new(0,200,0,117),Color3.fromRGB(35,55,35),Color3.fromRGB(175,255,175),12)
local BtnAimXL = mkBtn(Con,"–",UDim2.new(0,22,0,20),UDim2.new(0,200,0,139),Color3.fromRGB(55,28,28),Color3.fromRGB(255,175,175),12)

-- CAM DIST
mkLbl(Con,"📷 Cam Dist", UDim2.new(1,-16,0,13), UDim2.new(0,8,0,165), 9)
local InpCamDst = mkInp(Con, CAM_DISTANCE, UDim2.new(1,-16,0,22), UDim2.new(0,8,0,178))

mkDiv(Con,206)

-- LOCK + NEAREST
local BtnLock = mkBtn(Con,"🔓 Lock : OFF",    UDim2.new(1,-16,0,28), UDim2.new(0,8,0,212), Color3.fromRGB(24,24,40), Color3.fromRGB(175,175,255), 12)
local BtnNear = mkBtn(Con,"📍 Nearest : OFF", UDim2.new(1,-16,0,26), UDim2.new(0,8,0,246), Color3.fromRGB(24,24,40), Color3.fromRGB(148,148,210), 11)

-- PREV/TARGET/NEXT
local BtnPrev = mkBtn(Con,"◀",UDim2.new(0,38,0,26),UDim2.new(0,8,0,278),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)
local TgtLbl  = Instance.new("TextLabel")
TgtLbl.Size=UDim2.new(0,122,0,26); TgtLbl.Position=UDim2.new(0,50,0,278)
TgtLbl.BackgroundColor3=Color3.fromRGB(15,15,26); TgtLbl.BorderSizePixel=0; TgtLbl.Text="No Target"
TgtLbl.TextColor3=Color3.fromRGB(130,170,255); TgtLbl.TextSize=10; TgtLbl.Font=Enum.Font.GothamBold
TgtLbl.TextTruncate=Enum.TextTruncate.AtEnd; TgtLbl.Parent=Con
Instance.new("UICorner",TgtLbl).CornerRadius=UDim.new(0,5)
local BtnNext = mkBtn(Con,"▶",UDim2.new(0,38,0,26),UDim2.new(0,176,0,278),Color3.fromRGB(28,28,46),Color3.fromRGB(175,175,255),13)

mkDiv(Con,310)

-- FEATURE ROW
local BtnESP    = mkBtn(Con,"👁 ESP",   UDim2.new(0,42,0,26),UDim2.new(0,8,0,316),  Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnScan   = mkBtn(Con,"🔍 Scan",  UDim2.new(0,42,0,26),UDim2.new(0,54,0,316), Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnCamSys = mkBtn(Con,"📷 Cam",   UDim2.new(0,42,0,26),UDim2.new(0,100,0,316),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnTP     = mkBtn(Con,"🚀 TP",    UDim2.new(0,38,0,26),UDim2.new(0,146,0,316),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)
local BtnMove   = mkBtn(Con,"🏃 Move",  UDim2.new(0,42,0,26),UDim2.new(0,188,0,316),Color3.fromRGB(24,24,40),Color3.fromRGB(148,148,210),9)

-- MOUSE LOCK
mkDiv(Con,348)
local BtnMouseLock = mkBtn(Con,"🖱️ Mouse Lock : OFF", UDim2.new(1,-16,0,26), UDim2.new(0,8,0,354), Color3.fromRGB(24,24,40), Color3.fromRGB(200,160,255), 11)

mkDiv(Con,386)
local StatusLbl = mkLbl(Con,"● Idle",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,391),10,Color3.fromRGB(60,60,90))

-- ══════════════════════════════════════════════
--   SCAN FRAME
-- ══════════════════════════════════════════════
local SF = mkFrame(SG, UDim2.new(0,220,0,340), UDim2.new(0.5,126,0.5,-170), Color3.fromRGB(11,11,17), true)
SF.Visible = false
local scanLocked = {false}
local STB = mkFrame(SF, UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), Color3.fromRGB(17,17,28), false, 8); mkAccent(STB)
mkDrag(SF, STB, function() return scanLocked[1] end)
mkLbl(STB,"🔍 Scan",UDim2.new(1,-132,1,0),UDim2.new(0,52,0,0),12,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(STB, SF, 160, 320, 200, 500)
local BtnTPScan  = mkBtn(STB,"🚀",UDim2.new(0,22,0,22),UDim2.new(1,-138,0.5,-11),Color3.fromRGB(30,80,30))
local BtnCP2     = mkBtn(STB,"🎨",UDim2.new(0,22,0,22),UDim2.new(1,-114,0.5,-11),Color3.fromRGB(48,48,160))
local BtnExc     = mkBtn(STB,"🚫",UDim2.new(0,22,0,22),UDim2.new(1,-90,0.5,-11), Color3.fromRGB(100,30,30),Color3.fromRGB(255,170,170))
mkSubLockBtn(STB, SF, scanLocked)
local BtnSMin    = mkBtn(STB,"–",UDim2.new(0,20,0,20),UDim2.new(1,-46,0.5,-10),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),12)
local BtnSClose  = mkBtn(STB,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-24,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10)

local FBar = mkFrame(SF, UDim2.new(1,-16,0,22), UDim2.new(0,8,0,32), Color3.fromRGB(16,16,26), false, 5)
local FLbl = mkLbl(FBar,"🎨 Filter: ทั้งหมด",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(120,120,170))
local BtnCF = mkBtn(FBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)

local EBar = mkFrame(SF, UDim2.new(1,-16,0,22), UDim2.new(0,8,0,56), Color3.fromRGB(20,10,10), false, 5)
local ELbl = mkLbl(EBar,"🚫 Exclude: ไม่มี",UDim2.new(1,-28,1,0),UDim2.new(0,6,0,0),9,Color3.fromRGB(170,105,105))
local BtnCE = mkBtn(EBar,"✕",UDim2.new(0,20,0,16),UDim2.new(1,-22,0.5,-8),Color3.fromRGB(62,24,24),Color3.fromRGB(255,140,140),9)

local BtnDoScan   = mkBtn(SF,"🔍 Scan Now",UDim2.new(1,-16,0,26),UDim2.new(0,8,0,80),Color3.fromRGB(32,32,66),Color3.fromRGB(180,180,255),11)
local ScanCntLbl  = mkLbl(SF,"0 found",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,108),9,Color3.fromRGB(70,70,110))
local SScr = Instance.new("ScrollingFrame")
SScr.Size=UDim2.new(1,-8,1,-125); SScr.Position=UDim2.new(0,4,0,124)
SScr.BackgroundTransparency=1; SScr.BorderSizePixel=0; SScr.ScrollBarThickness=3
SScr.CanvasSize=UDim2.new(0,0,0,0); SScr.Parent=SF
local SLayout = Instance.new("UIListLayout"); SLayout.Padding=UDim.new(0,3); SLayout.Parent=SScr

-- ══ COLOR PICKER POPUP ══
local CPop = mkFrame(SG, UDim2.new(0,200,0,230), UDim2.new(0.5,126,0.5,175), Color3.fromRGB(12,12,18), true)
CPop.Visible=false; CPop.ZIndex=10
local CPBar = mkFrame(CPop, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), Color3.fromRGB(17,17,28), false, 8); CPBar.ZIndex=10
mkDrag(CPop, CPBar, nil)
mkLbl(CPBar,"🎨 Filter Color",UDim2.new(1,-28,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnCPClose = mkBtn(CPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10); BtnCPClose.ZIndex=10
local BtnCPAll   = mkBtn(CPop,"✅ แสดงทั้งหมด",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,30),Color3.fromRGB(26,46,26),Color3.fromRGB(170,255,170),9); BtnCPAll.ZIndex=10
local CPScr = Instance.new("ScrollingFrame")
CPScr.Size=UDim2.new(1,-8,1,-56); CPScr.Position=UDim2.new(0,4,0,54)
CPScr.BackgroundTransparency=1; CPScr.BorderSizePixel=0; CPScr.ScrollBarThickness=3
CPScr.CanvasSize=UDim2.new(0,0,0,0); CPScr.ZIndex=10; CPScr.Parent=CPop
local CPLayout = Instance.new("UIListLayout"); CPLayout.Padding=UDim.new(0,3); CPLayout.Parent=CPScr

-- ══ EXCLUDE POPUP ══
local EPop = mkFrame(SG, UDim2.new(0,200,0,260), UDim2.new(0.5,126,0.5,175), Color3.fromRGB(16,8,8), true)
EPop.Visible=false; EPop.ZIndex=10
local EPBar = mkFrame(EPop, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), Color3.fromRGB(25,12,12), false, 8); EPBar.ZIndex=10
mkDrag(EPop, EPBar, nil)
mkLbl(EPBar,"🚫 Exclude Color",UDim2.new(1,-28,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,190,190),Enum.Font.GothamBold)
local BtnEPClose = mkBtn(EPBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10); BtnEPClose.ZIndex=10
mkLbl(EPop,"กดสีที่ไม่ต้องการล็อค → OK",UDim2.new(1,-16,0,20),UDim2.new(0,8,0,30),9,Color3.fromRGB(190,148,148))
local BtnEPOk = mkBtn(EPop,"✅ OK ยืนยัน",UDim2.new(1,-16,0,22),UDim2.new(0,8,0,52),Color3.fromRGB(26,50,26),Color3.fromRGB(170,255,170),9); BtnEPOk.ZIndex=10
local EPScr = Instance.new("ScrollingFrame")
EPScr.Size=UDim2.new(1,-8,1,-80); EPScr.Position=UDim2.new(0,4,0,78)
EPScr.BackgroundTransparency=1; EPScr.BorderSizePixel=0; EPScr.ScrollBarThickness=3
EPScr.CanvasSize=UDim2.new(0,0,0,0); EPScr.ZIndex=10; EPScr.Parent=EPop
local EPLayout = Instance.new("UIListLayout"); EPLayout.Padding=UDim.new(0,3); EPLayout.Parent=EPScr

-- ══ TP MODE POPUP ══
local TPModePopup = mkFrame(SG, UDim2.new(0,200,0,160), UDim2.new(0.5,126,0.5,175), Color3.fromRGB(12,15,22), true)
TPModePopup.Visible=false; TPModePopup.ZIndex=12
local TPMBar = mkFrame(TPModePopup, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0), Color3.fromRGB(18,22,35), false, 8)
TPMBar.ZIndex=12; mkDrag(TPModePopup, TPMBar, nil)
do local a=Instance.new("Frame"); a.Size=UDim2.new(1,0,0,2); a.Position=UDim2.new(0,0,1,-2)
   a.BackgroundColor3=Color3.fromRGB(50,200,120); a.BorderSizePixel=0; a.Parent=TPMBar end
mkLbl(TPMBar,"🚀 TP Mode",UDim2.new(1,-30,1,0),UDim2.new(0,8,0,0),10,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
local BtnTPMClose = mkBtn(TPMBar,"✕",UDim2.new(0,20,0,20),UDim2.new(1,-22,0.5,-10),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),10)
BtnTPMClose.ZIndex=12

local tpModeSelect = 1
local tpRapidSpeed = 0.05
local BtnTPM1 = mkBtn(TPModePopup,"1️⃣ ปกติ (วาปครั้งเดียว)",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,32),Color3.fromRGB(25,75,25),Color3.fromRGB(180,255,180),10)
BtnTPM1.ZIndex=12; BtnTPM1.TextXAlignment=Enum.TextXAlignment.Left
local BtnTPM2 = mkBtn(TPModePopup,"2️⃣ รัว (วาปซ้ำๆ)",UDim2.new(1,-16,0,28),UDim2.new(0,8,0,64),Color3.fromRGB(35,35,55),Color3.fromRGB(155,155,220),10)
BtnTPM2.ZIndex=12; BtnTPM2.TextXAlignment=Enum.TextXAlignment.Left
mkLbl(TPModePopup,"⚡ ความเร็วรัว (วิ/วาป)",UDim2.new(1,-16,0,14),UDim2.new(0,8,0,96),9,Color3.fromRGB(120,120,170))
local InpTPSpeed = mkInp(TPModePopup, tpRapidSpeed, UDim2.new(1,-16,0,24), UDim2.new(0,8,0,112))
InpTPSpeed.ZIndex=12

local function UpdateTPModeUI()
    BtnTPM1.BackgroundColor3 = tpModeSelect==1 and Color3.fromRGB(25,100,25) or Color3.fromRGB(25,45,25)
    BtnTPM2.BackgroundColor3 = tpModeSelect==2 and Color3.fromRGB(60,40,100) or Color3.fromRGB(35,35,55)
end; UpdateTPModeUI()

-- ══ CAMERA SYSTEM FRAME ══
local CamF = mkFrame(SG, UDim2.new(0,190,0,200), UDim2.new(0.5,-340,0.5,-100), Color3.fromRGB(11,11,17), true)
CamF.Visible = false
local camFrameLocked = {false}
local CamTB = mkFrame(CamF, UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), Color3.fromRGB(17,17,28), false, 8)
mkAccent(CamTB, Color3.fromRGB(245,150,50))
mkDrag(CamF, CamTB, function() return camFrameLocked[1] end)
mkLbl(CamTB,"📷 Camera System",UDim2.new(1,-75,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(CamTB, CamF, 160, 280, 160, 320)
mkSubLockBtn(CamTB, CamF, camFrameLocked)
local BtnCamMin   = mkBtn(CamTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnCamClose = mkBtn(CamTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)

local CamCon = Instance.new("Frame")
CamCon.Size=UDim2.new(1,0,1,-30); CamCon.Position=UDim2.new(0,0,0,30)
CamCon.BackgroundTransparency=1; CamCon.Parent=CamF

local BtnCamLock = mkBtn(CamCon,"🔒 Lock Cam OFF",UDim2.new(1,-10,0,30),UDim2.new(0,5,0,5), Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
local BtnCamFree = mkBtn(CamCon,"🎥 FreeCam OFF", UDim2.new(1,-10,0,30),UDim2.new(0,5,0,40),Color3.fromRGB(150,32,32),Color3.fromRGB(255,190,190),11)
mkLbl(CamCon,"📏 Distance",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,76),9)
local InpCamDist = mkInp(CamCon, camDist, UDim2.new(1,-10,0,26), UDim2.new(0,5,0,89))
mkLbl(CamCon,"⚡ Speed",UDim2.new(1,-10,0,13),UDim2.new(0,5,0,120),9)
local InpCamSpd  = mkInp(CamCon, camSpeed, UDim2.new(1,-10,0,26), UDim2.new(0,5,0,133))

local CtrlPad = mkFrame(SG, UDim2.new(0,160,0,160), UDim2.new(0.75,0,0.6,0), nil, false, 0)
CtrlPad.BackgroundTransparency=1; CtrlPad.Visible=false
local function mkPad(txt,pos)
    return mkBtn(CtrlPad,txt,UDim2.new(0,45,0,45),pos,Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
end
local bF=mkPad("↑",UDim2.new(0.5,-22,0,0));  local bB=mkPad("↓",UDim2.new(0.5,-22,0,90))
local bL=mkPad("←",UDim2.new(0,0,0.5,-22));  local bR=mkPad("→",UDim2.new(0,90,0.5,-22))
local bU=mkPad("▲",UDim2.new(0,0,0,0));       local bD=mkPad("▼",UDim2.new(0,90,0,0))
local function bindPad(b,v)
    b.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then camMove=camMove+v end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then camMove=camMove-v end
    end)
end
bindPad(bF,Vector3.new(0,0,-1)); bindPad(bB,Vector3.new(0,0,1))
bindPad(bL,Vector3.new(-1,0,0)); bindPad(bR,Vector3.new(1,0,0))
bindPad(bU,Vector3.new(0,1,0));  bindPad(bD,Vector3.new(0,-1,0))

-- ══ TP FRAME ══
local TF = mkFrame(SG, UDim2.new(0,210,0,260), UDim2.new(0.5,-340,0.5,110), Color3.fromRGB(11,11,17), true)
TF.Visible = false
local tpFrameLocked = {false}
local TFTB = mkFrame(TF, UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), Color3.fromRGB(17,17,28), false, 8)
mkAccent(TFTB, Color3.fromRGB(50,190,110))
mkDrag(TF, TFTB, function() return tpFrameLocked[1] end)
mkLbl(TFTB,"🚀 Teleport Save",UDim2.new(1,-75,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(TFTB, TF, 160, 320, 200, 400)
mkSubLockBtn(TFTB, TF, tpFrameLocked)
local BtnTFMin   = mkBtn(TFTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnTFClose = mkBtn(TFTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)
local BtnTPSave  = mkBtn(TF,"+ Save",    UDim2.new(0,60,0,26),UDim2.new(0,5,0,34),  Color3.fromRGB(20,68,20),Color3.fromRGB(170,255,170),11)
local BtnTPClic  = mkBtn(TF,"Click TP OFF",UDim2.new(0,80,0,26),UDim2.new(0,68,0,34),Color3.fromRGB(130,32,32),Color3.fromRGB(255,170,170),10)
local BtnTPDel   = mkBtn(TF,"Delete",    UDim2.new(0,55,0,26),UDim2.new(0,152,0,34),Color3.fromRGB(72,24,24),Color3.fromRGB(255,140,140),10)
local TPScr = Instance.new("ScrollingFrame")
TPScr.Size=UDim2.new(1,-10,1,-68); TPScr.Position=UDim2.new(0,5,0,64)
TPScr.BackgroundColor3=Color3.fromRGB(13,13,20); TPScr.BorderSizePixel=0
TPScr.ScrollBarThickness=3; TPScr.CanvasSize=UDim2.new(0,0,0,0); TPScr.Parent=TF
Instance.new("UICorner",TPScr).CornerRadius=UDim.new(0,5)
local TPLayout = Instance.new("UIListLayout"); TPLayout.Padding=UDim.new(0,4); TPLayout.Parent=TPScr

-- ══ MOVEMENT PANEL FRAME ══
local MvF = mkFrame(SG, UDim2.new(0,260,0,360), UDim2.new(0.5,-130,0.5,-180), Color3.fromRGB(11,11,17), true)
MvF.Visible = false
local mvFrameLocked = {false}
local MvTB = mkFrame(MvF, UDim2.new(1,0,0,30), UDim2.new(0,0,0,0), Color3.fromRGB(17,17,28), false, 8)
do local a=Instance.new("Frame"); a.Size=UDim2.new(1,0,0,2); a.Position=UDim2.new(0,0,1,-2)
   a.BackgroundColor3=Color3.fromRGB(80,200,100); a.BorderSizePixel=0; a.Parent=MvTB end
mkDrag(MvF, MvTB, function() return mvFrameLocked[1] end)
mkLbl(MvTB,"🏃 Movement Panel",UDim2.new(1,-75,1,0),UDim2.new(0,52,0,0),11,Color3.fromRGB(255,255,255),Enum.Font.GothamBold)
mkResize(MvTB, MvF, 180, 340, 200, 500)
mkSubLockBtn(MvTB, MvF, mvFrameLocked)
local BtnMvMin   = mkBtn(MvTB,"–",UDim2.new(0,22,0,22),UDim2.new(1,-46,0.5,-11),Color3.fromRGB(40,40,62),Color3.fromRGB(255,255,255),13)
local BtnMvClose = mkBtn(MvTB,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-23,0.5,-11),Color3.fromRGB(150,32,32),Color3.fromRGB(255,255,255),12)

local MvScr = Instance.new("ScrollingFrame")
MvScr.Size=UDim2.new(1,-8,1,-36); MvScr.Position=UDim2.new(0,4,0,36)
MvScr.BackgroundTransparency=1; MvScr.BorderSizePixel=0
MvScr.ScrollBarThickness=3; MvScr.ScrollBarImageColor3=Color3.fromRGB(60,60,100)
MvScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
MvScr.CanvasSize=UDim2.new(0,0,0,0); MvScr.Parent=MvF
local MvLayout = Instance.new("UIListLayout"); MvLayout.Padding=UDim.new(0,6); MvLayout.Parent=MvScr
Instance.new("UIPadding",MvScr).PaddingTop=UDim.new(0,6)

-- ══ MOVEMENT STATE ══
local mvState = {
    walkSpeed=16, jumpPower=50, multiJump=5, flySpeed=60, heightLock=0,
    enableSpeed=false, enableJump=false, enableMultiJump=false,
    enableFly=false, enableHeight=false, enableNoclip=false, enableAntiTP=true,
}
local mvChar, mvHumanoid, mvRoot
local mvJumpCount=0; local mvCanJumpAgain=false; local mvJumpDebounce=false
local mvFlying=false; local mvFlyBV=nil; local mvFlyBG=nil
local mvStateConn=nil; local mvLastPos=nil

local function mvSetupChar(char)
    mvChar=char
    mvHumanoid=char:WaitForChild("Humanoid")
    mvRoot=char:WaitForChild("HumanoidRootPart")
    mvJumpCount=0; mvCanJumpAgain=false; mvJumpDebounce=false; mvLastPos=nil
    if mvStateConn then mvStateConn:Disconnect() end
    mvStateConn=mvHumanoid.StateChanged:Connect(function(_,new)
        if new==Enum.HumanoidStateType.Landed then mvJumpCount=0; mvCanJumpAgain=false
        elseif new==Enum.HumanoidStateType.Freefall then mvCanJumpAgain=true end
    end)
end
if LocalPlayer.Character then mvSetupChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(mvSetupChar)

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.Space then
        if mvState.enableMultiJump and mvHumanoid then
            if mvJumpDebounce then return end
            mvJumpDebounce=true
            if mvCanJumpAgain and mvJumpCount<mvState.multiJump then
                mvJumpCount=mvJumpCount+1; mvCanJumpAgain=false
                mvHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            task.delay(0.15,function() mvJumpDebounce=false end)
        end
    end
end)

-- Fly (pcall กัน error ถ้าบางแมพบล็อก)
local mvControls = nil
pcall(function()
    local pm = require(LocalPlayer:WaitForChild("PlayerScripts",5):WaitForChild("PlayerModule",5))
    mvControls = pm:GetControls()
end)

local function mvStartFly()
    if not mvRoot then return end; mvFlying=true
    mvFlyBV=Instance.new("BodyVelocity",mvRoot); mvFlyBV.MaxForce=Vector3.new(1e6,1e6,1e6)
    mvFlyBG=Instance.new("BodyGyro",mvRoot); mvFlyBG.MaxTorque=Vector3.new(1e6,1e6,1e6)
    if mvHumanoid then mvHumanoid.AutoRotate=false end
end
local function mvStopFly()
    mvFlying=false
    if mvFlyBV then mvFlyBV:Destroy() end
    if mvFlyBG then mvFlyBG:Destroy() end
    if mvHumanoid then mvHumanoid.AutoRotate=true end
end

local mvRayParams = RaycastParams.new()
mvRayParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.RenderStepped:Connect(function()
    if not mvHumanoid or not mvRoot then return end
    mvHumanoid.WalkSpeed = mvState.enableSpeed and mvState.walkSpeed or 16
    mvHumanoid.JumpPower = mvState.enableJump  and mvState.jumpPower  or 50
    if mvState.enableFly and mvFlying and mvFlyBV and mvFlyBG and mvControls then
        local cf=Camera.CFrame; local mv2=mvControls:GetMoveVector()
        local dir=(cf.LookVector*-mv2.Z)+(cf.RightVector*mv2.X)+(cf.UpVector*-mv2.Y)
        mvFlyBV.Velocity=dir*mvState.flySpeed
        mvFlyBG.CFrame=CFrame.new(mvRoot.Position,mvRoot.Position+cf.LookVector)
    end
    if mvState.enableHeight then
        mvRayParams.FilterDescendantsInstances={mvChar}
        local res=workspace:Raycast(mvRoot.Position,Vector3.new(0,-1000,0),mvRayParams)
        if res then
            local tgt=res.Position+res.Normal*mvState.heightLock
            mvRoot.CFrame=CFrame.new(mvRoot.Position.X,tgt.Y,mvRoot.Position.Z)
            mvRoot.Velocity=Vector3.new(mvRoot.Velocity.X,0,mvRoot.Velocity.Z)
        end
    end
    if mvState.enableNoclip and mvChar then
        for _,v in pairs(mvChar:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide=false; v.Massless=true end
        end
    end
    if mvState.enableAntiTP then
        if mvLastPos then
            local dist=(mvRoot.Position-mvLastPos).Magnitude
            local spd=mvRoot.Velocity.Magnitude
            if dist>30 and spd<120 then mvRoot.CFrame=CFrame.new(mvLastPos) end
        end
        mvLastPos=mvRoot.Position
    end
end)

local function mkMvRow(emoji,name,defVal,onToggle,onVal)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,44)
    row.BackgroundColor3=Color3.fromRGB(18,18,28); row.BorderSizePixel=0; row.Parent=MvScr
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0,120,1,0); lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=emoji.." "..name
    lbl.TextColor3=Color3.fromRGB(200,200,255); lbl.TextSize=10; lbl.Font=Enum.Font.GothamBold
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row
    local tog=mkBtn(row,"OFF",UDim2.new(0,44,0,26),UDim2.new(0,130,0.5,-13),Color3.fromRGB(140,30,30),Color3.fromRGB(255,200,200),10)
    local on=false
    tog.Activated:Connect(function()
        on=not on; tog.Text=on and "ON" or "OFF"
        tog.BackgroundColor3=on and Color3.fromRGB(25,90,25) or Color3.fromRGB(140,30,30)
        tog.TextColor3=on and Color3.fromRGB(180,255,180) or Color3.fromRGB(255,200,200)
        onToggle(on)
    end)
    if defVal ~= -1 then
        local box=mkInp(row,defVal,UDim2.new(0,58,0,26),UDim2.new(1,-66,0.5,-13))
        box.FocusLost:Connect(function()
            local v=tonumber(box.Text); if v then onVal(v) else box.Text=tostring(defVal) end
        end)
    end
    return tog
end

mkMvRow("🏃","WalkSpeed", 16,  function(v) mvState.enableSpeed=v end,    function(v) mvState.walkSpeed=v end)
mkMvRow("🦘","JumpPower",  50,  function(v) mvState.enableJump=v end,     function(v) mvState.jumpPower=v end)
mkMvRow("🔁","MultiJump",  5,   function(v) mvState.enableMultiJump=v end,function(v) mvState.multiJump=v end)
mkMvRow("🕊️","FlySpeed",  60,  function(v) mvState.enableFly=v; if v then mvStartFly() else mvStopFly() end end, function(v) mvState.flySpeed=v end)
mkMvRow("📏","HeightLock", 0,   function(v) mvState.enableHeight=v end,   function(v) mvState.heightLock=v end)
mkMvRow("🧱","Noclip",     -1,  function(v) mvState.enableNoclip=v end,   function() end)
mkMvRow("🛡️","AntiTP",    -1,  function(v) mvState.enableAntiTP=v end,   function() end)

-- ══════════════════════════════════════════════
--   CORE LOGIC
-- ══════════════════════════════════════════════
local function GetTeamColor(model)
    local p=Players:GetPlayerFromCharacter(model)
    if p and p.Team then return p.Team.TeamColor.Color end
    if p then
        local mt=LocalPlayer.Team
        if mt and p.Team then return p.Team==mt and Color3.fromRGB(50,190,90) or Color3.fromRGB(210,50,50) end
    end
    return Color3.fromRGB(210,110,40)
end

local function IsExcluded(color)
    local h=Hex(color)
    for _,eh in ipairs(Settings.ExcludeColors) do if eh==h then return true end end
    return false
end

local function GetRoot(model)
    local r=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model.PrimaryPart
    if not r then for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then return p end end end
    return r
end

local function GetTargetList()
    local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return {} end
    local list={}
    local range=tonumber(InpRange.Text) or Settings.LockRange
    if Settings.Mode=="Player" then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                local hum=p.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health>0 then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    if dist<=range then
                        local col=GetTeamColor(p.Character)
                        if not IsExcluded(col) then
                            table.insert(list,{model=p.Character,name=p.Name,dist=dist,color=col})
                        end
                    end
                end
            end
        end
    else
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj~=Character and not Players:GetPlayerFromCharacter(obj) then
                local hum=obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    local hrp=GetRoot(obj)
                    if hrp then
                        local dist=(hrp.Position-myHRP.Position).Magnitude
                        if dist<=range then
                            local col=GetTeamColor(obj)
                            if not IsExcluded(col) then
                                table.insert(list,{model=obj,name=obj.Name,dist=dist,color=col})
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(list,function(a,b) return a.dist<b.dist end)
    return list
end

local function FilterList(list)
    if not Settings.FilterColor then return list end
    local fh=Hex(Settings.FilterColor); local out={}
    for _,e in ipairs(list) do if Hex(e.color)==fh then table.insert(out,e) end end
    return out
end

local function SetTarget(model)
    currentTarget=model
    if model then
        TgtLbl.Text=model.Name; StatusLbl.Text="🔒 "..model.Name
        StatusLbl.TextColor3=Color3.fromRGB(90,178,255)
    else
        TgtLbl.Text="No Target"; StatusLbl.Text="● Idle"
        StatusLbl.TextColor3=Color3.fromRGB(60,60,90)
    end
end

-- ══ ESP ══
local function ClearESP()
    for _,bb in pairs(espBoxes) do pcall(function() bb:Destroy() end) end
    espBoxes={}
end

local function UpdateESP()
    local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then ClearESP(); return end
    local list=GetTargetList(); local active={}
    for _,e in ipairs(list) do
        local m=e.model; active[m]=true
        local hrp=GetRoot(m); if not hrp then continue end
        if not espBoxes[m] then
            local bb=Instance.new("BillboardGui")
            bb.Adornee=hrp; bb.AlwaysOnTop=true; bb.LightInfluence=0
            bb.Size=UDim2.new(0,40,0,50); bb.Parent=hrp
            local box=Instance.new("Frame"); box.Size=UDim2.new(1,0,1,0)
            box.BackgroundTransparency=1; box.BorderSizePixel=0; box.Parent=bb
            local sk=Instance.new("UIStroke"); sk.Color=Color3.fromRGB(255,255,255); sk.Thickness=1.5; sk.Parent=box
            local dl=Instance.new("TextLabel"); dl.Name="D"
            dl.Size=UDim2.new(1,0,0,14); dl.Position=UDim2.new(0,0,1,2)
            dl.BackgroundTransparency=1; dl.TextColor3=Color3.fromRGB(255,255,255)
            dl.TextSize=11; dl.Font=Enum.Font.GothamBold; dl.Text="0m"; dl.Parent=bb
            espBoxes[m]=bb
        end
        local s=math.clamp(80/math.max(e.dist,5),1.2,5)
        espBoxes[m].Size=UDim2.new(0,s*8,0,s*12)
        local dl=espBoxes[m]:FindFirstChild("D")
        if dl then dl.Text=string.format("%.0fm",e.dist) end
    end
    for m,bb in pairs(espBoxes) do
        if not active[m] then pcall(function() bb:Destroy() end); espBoxes[m]=nil end
    end
end

-- ══ COLOR / EXCLUDE PICKER ══
local function UpdateCPicker()
    for _,c in ipairs(CPScr:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local n=0
    for hs,col in pairs(foundColors) do
        n=n+1
        local b=mkBtn(CPScr,"  #"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left; b.ZIndex=11
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        if Settings.FilterColor and Hex(Settings.FilterColor)==hs then
            local sk=Instance.new("UIStroke"); sk.Color=Color3.fromRGB(255,255,255); sk.Thickness=2; sk.Parent=b
        end
        b.Activated:Connect(function()
            Settings.FilterColor=col; FLbl.Text="🎨 #"..hs; FLbl.TextColor3=col
            BtnCP2.BackgroundColor3=col; CPop.Visible=false; UpdateCPicker()
        end)
    end
    CPScr.CanvasSize=UDim2.new(0,0,0,CPLayout.AbsoluteContentSize.Y+4)
    if n==0 then mkLbl(CPScr,"Scan ก่อน",UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),9,Color3.fromRGB(90,90,120)).ZIndex=11 end
end

local pendEx={}
local function UpdateEPicker()
    for _,c in ipairs(EPScr:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local n=0
    for hs,col in pairs(foundColors) do
        n=n+1; local sel=false
        for _,h in ipairs(pendEx) do if h==hs then sel=true; break end end
        local b=mkBtn(EPScr,(sel and "✓ " or "  ").."#"..hs,UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),
            sel and Color3.fromRGB(90,30,30) or col,Color3.fromRGB(255,255,255),9)
        b.TextXAlignment=Enum.TextXAlignment.Left; b.ZIndex=11
        b.Activated:Connect(function()
            local found=false
            for i,h in ipairs(pendEx) do if h==hs then table.remove(pendEx,i); found=true; break end end
            if not found then table.insert(pendEx,hs) end; UpdateEPicker()
        end)
    end
    EPScr.CanvasSize=UDim2.new(0,0,0,EPLayout.AbsoluteContentSize.Y+4)
    if n==0 then mkLbl(EPScr,"Scan ก่อน",UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),9,Color3.fromRGB(120,70,70)).ZIndex=11 end
    ELbl.Text=#Settings.ExcludeColors>0 and "🚫 Exclude: "..#Settings.ExcludeColors.." สี" or "🚫 Exclude: ไม่มี"
    ELbl.TextColor3=#Settings.ExcludeColors>0 and Color3.fromRGB(255,120,120) or Color3.fromRGB(170,100,100)
end

-- ══════════════════════════════════════════════
--   LOCK CORE
-- ══════════════════════════════════════════════
local function StartLock()
    if lockConn then lockConn:Disconnect(); lockConn=nil end
    local timer=0

    -- จำระยะกล้อง ณ ตอนกด Lock → ไม่ซูมออก
    local myHRP0 = Character and Character:FindFirstChild("HumanoidRootPart")
    LOCK_CAM_DIST = myHRP0
        and math.clamp((myHRP0.Position - Camera.CFrame.Position).Magnitude, 6, 40)
        or 16

    Camera.CameraType = Enum.CameraType.Scriptable
    SetCrosshair(true)

    lockConn=RunService.RenderStepped:Connect(function(dt)
        local myHRP=Character and Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local str   = math.clamp(Settings.LockStrength, 0.01, 0.99)
        local alpha = 1 - (1-str)^(math.min(dt,0.05)*60)
        local camD  = LOCK_CAM_DIST or 16

        if currentTarget then
            local hum=currentTarget:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health<=0 or not currentTarget.Parent then
                SetTarget(nil); forceRescan=true
            end
        end

        if not currentTarget or Settings.NearestMode or forceRescan then
            timer=timer+dt
            if forceRescan or timer>=SCAN_INT then
                timer=0; forceRescan=false
                local raw=GetTargetList(); local fil=FilterList(raw); targetList=fil
                if #fil>0 and (Settings.NearestMode or not currentTarget) then
                    SetTarget(fil[1].model); targetIndex=1
                end
            end
        end

        -- ไม่มีเป้า: กล้องติด HRP ระยะเดิม
        if not currentTarget then
            local lv = Camera.CFrame.LookVector
            local cp = myHRP.Position + Vector3.new(0,1.5,0) - lv * camD
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(cp, myHRP.Position+Vector3.new(0,1.5,0)), 0.15)
            return
        end

        local hrp=GetRoot(currentTarget)
        local hum=currentTarget:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 or not currentTarget.Parent then
            SetTarget(nil); forceRescan=true; return
        end

        local myPos = myHRP.Position
        local head  = currentTarget:FindFirstChild("Head")
        local tBase = head and head.Position or hrp.Position

        -- AIM POINT รวม offset Y และ X
        local camRight = Camera.CFrame.RightVector
        local aimPoint = tBase
            + Vector3.new(0,1,0) * AIM_OFFSET
            + camRight           * AIM_OFFSET_X

        -- กล้องอยู่หลัง HRP ระยะคงที่
        local dirFlat = Vector3.new(aimPoint.X-myPos.X, 0, aimPoint.Z-myPos.Z)
        local backDir = dirFlat.Magnitude>0.1 and dirFlat.Unit or Vector3.new(0,0,1)
        local camPos  = myHRP.Position + Vector3.new(0,1.5,0) - backDir * camD

        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(camPos, aimPoint), alpha)

        -- redirect Mouse.Hit → aimPoint (สำหรับยิง)
        if Settings.MouseLock then
            pcall(function() Mouse.Hit = CFrame.new(aimPoint) end)
        end

        -- หมุนตัวละคร XZ
        if dirFlat.Magnitude > 0.1 then
            myHRP.CFrame = myHRP.CFrame:Lerp(CFrame.new(myPos, myPos+dirFlat.Unit), alpha)
        end
    end)
end

local function StopLock()
    if lockConn then lockConn:Disconnect(); lockConn=nil end
    SetTarget(nil)
    LOCK_CAM_DIST = nil
    Camera.CameraType = Enum.CameraType.Custom
    SetCrosshair(false)
end

-- ══ ESP + TP ANCHOR (Heartbeat) ══
RunService.Heartbeat:Connect(function(dt)
    if Settings.ESPEnabled then
        espTimer=espTimer+dt
        if espTimer>=ESP_INTERVAL then espTimer=0; UpdateESP() end
    end
    if clickTP and lockPos then
        local char=LocalPlayer.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        if (root.Position-lockPos).Magnitude>10 then root.CFrame=CFrame.new(lockPos+Vector3.new(0,3,0)) end
    end
end)

-- ══ CAMERA SYSTEM LOOP ══
RunService.RenderStepped:Connect(function(dt)
    if camLocked and not camFreecam then
        local char=LocalPlayer.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local look=Camera.CFrame.LookVector
        Camera.CFrame=CFrame.new(root.Position - look*camDist, root.Position)
    end
    if camFreecam then
        local rot=CFrame.Angles(0,math.rad(camAngleX),0)*CFrame.Angles(math.rad(camAngleY),0,0)
        local d=rot.LookVector
        camFreePos = camFreePos
            + d               * camMove.Z * camSpeed * dt * 60
            + rot.RightVector * camMove.X * camSpeed * dt * 60
            + Vector3.new(0,1,0) * camMove.Y * camSpeed * dt * 60
        Camera.CFrame=CFrame.new(camFreePos, camFreePos+d)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if camFreecam and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        camAngleX=camAngleX-input.Delta.X*0.2
        camAngleY=math.clamp(camAngleY-input.Delta.Y*0.2,-80,80)
    end
end)

-- ══ TP ══
local function TPRefresh()
    for _,c in ipairs(TPScr:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    for i,pos in ipairs(tpSaves) do
        local b=mkBtn(TPScr,string.format("📍 %d  (%.0f,%.0f,%.0f)",i,pos.x,pos.y,pos.z),
            UDim2.new(1,-5,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(19,19,30),Color3.fromRGB(160,180,255),10)
        b.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,8)
        b.Activated:Connect(function()
            tpSelected=i
            local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root=char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame=CFrame.new(pos.x,pos.y,pos.z) end
            for _,c2 in ipairs(TPScr:GetChildren()) do
                if c2:IsA("TextButton") then c2.BackgroundColor3=Color3.fromRGB(19,19,30) end
            end
            b.BackgroundColor3=Color3.fromRGB(32,50,84)
        end)
    end
    TPScr.CanvasSize=UDim2.new(0,0,0,#tpSaves*30)
end

-- Rapid TP
local rapidTPConn = nil
local rapidTPTarget = nil
local function doTP(hrp)
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    if hrp and hrp.Parent then root.CFrame=hrp.CFrame*CFrame.new(0,0,-2) end
end
-- ประกาศก่อน startRapidTP เพื่อกัน forward reference error
local function stopRapidTP()
    if rapidTPConn then rapidTPConn:Disconnect(); rapidTPConn=nil end; rapidTPTarget=nil
end
local function startRapidTP(hrp)
    stopRapidTP()
    rapidTPTarget=hrp
    rapidTPConn=RunService.Heartbeat:Connect(function()
        if not rapidTPTarget or not rapidTPTarget.Parent then stopRapidTP(); return end
        doTP(rapidTPTarget)
        task.wait(tpRapidSpeed)
    end)
end

-- ══ RESPAWN ══
LocalPlayer.CharacterAdded:Connect(function(c)
    Character=c; c:WaitForChild("HumanoidRootPart"); currentTarget=nil; ClearESP()
    Camera.CameraType = Enum.CameraType.Custom
    if Settings.Enabled then
        task.wait(0.5)
        Camera.CameraType = Enum.CameraType.Scriptable
        StartLock()
    end
end)

-- ══════════════════════════════════════════════
--   BUTTON CONNECTIONS
-- ══════════════════════════════════════════════
InpRange.FocusLost:Connect(function()
    local v=tonumber(InpRange.Text)
    if v then Settings.LockRange=v; InpRange.Text=tostring(v); SaveSettings()
    else InpRange.Text=tostring(Settings.LockRange) end
end)

InpAim.FocusLost:Connect(function()
    local v=tonumber(InpAim.Text)
    if v then AIM_OFFSET=v; InpAim.Text=tostring(v); UpdateCrosshairPos(); SaveSettings()
    else InpAim.Text=tostring(AIM_OFFSET) end
end)
InpAimX.FocusLost:Connect(function()
    local v=tonumber(InpAimX.Text)
    if v then AIM_OFFSET_X=v; InpAimX.Text=tostring(v); UpdateCrosshairPos(); SaveSettings()
    else InpAimX.Text=tostring(AIM_OFFSET_X) end
end)
BtnAimUp.Activated:Connect(function()
    AIM_OFFSET=AIM_OFFSET+0.5; InpAim.Text=tostring(AIM_OFFSET); UpdateCrosshairPos(); SaveSettings()
end)
BtnAimDn.Activated:Connect(function()
    AIM_OFFSET=AIM_OFFSET-0.5; InpAim.Text=tostring(AIM_OFFSET); UpdateCrosshairPos(); SaveSettings()
end)
BtnAimXR.Activated:Connect(function()
    AIM_OFFSET_X=AIM_OFFSET_X+0.5; InpAimX.Text=tostring(AIM_OFFSET_X); UpdateCrosshairPos(); SaveSettings()
end)
BtnAimXL.Activated:Connect(function()
    AIM_OFFSET_X=AIM_OFFSET_X-0.5; InpAimX.Text=tostring(AIM_OFFSET_X); UpdateCrosshairPos(); SaveSettings()
end)
InpCamDst.FocusLost:Connect(function()
    local v=tonumber(InpCamDst.Text)
    if v then CAM_DISTANCE=v; InpCamDst.Text=tostring(v); SaveSettings()
    else InpCamDst.Text=tostring(CAM_DISTANCE) end
end)
InpCamDist.FocusLost:Connect(function()
    local v=tonumber(InpCamDist.Text); if v then camDist=v else InpCamDist.Text=tostring(camDist) end
end)
InpCamSpd.FocusLost:Connect(function()
    local v=tonumber(InpCamSpd.Text); if v then camSpeed=v else InpCamSpd.Text=tostring(camSpeed) end
end)

BtnPlayer.Activated:Connect(function() Settings.Mode="Player"; currentTarget=nil; UpdateModeUI(); SaveSettings() end)
BtnNPC.Activated:Connect(function()    Settings.Mode="NPC";    currentTarget=nil; UpdateModeUI(); SaveSettings() end)

BtnLock.Activated:Connect(function()
    Settings.Enabled=not Settings.Enabled
    if Settings.Enabled then
        BtnLock.Text="🔒 Lock : ON"; BtnLock.BackgroundColor3=Color3.fromRGB(20,58,20)
        StartLock()
    else
        BtnLock.Text="🔓 Lock : OFF"; BtnLock.BackgroundColor3=Color3.fromRGB(24,24,40)
        StopLock()
    end
end)

BtnNear.Activated:Connect(function()
    Settings.NearestMode=not Settings.NearestMode
    BtnNear.Text=Settings.NearestMode and "📍 Nearest : ON" or "📍 Nearest : OFF"
    BtnNear.BackgroundColor3=Settings.NearestMode and Color3.fromRGB(20,58,20) or Color3.fromRGB(24,24,40)
    SaveSettings()
end)

BtnPrev.Activated:Connect(function()
    if #targetList==0 then targetList=FilterList(GetTargetList()) end
    if #targetList>0 then targetIndex=targetIndex-1; if targetIndex<1 then targetIndex=#targetList end; SetTarget(targetList[targetIndex].model) end
end)
BtnNext.Activated:Connect(function()
    if #targetList==0 then targetList=FilterList(GetTargetList()) end
    if #targetList>0 then targetIndex=targetIndex+1; if targetIndex>#targetList then targetIndex=1 end; SetTarget(targetList[targetIndex].model) end
end)

BtnESP.Activated:Connect(function()
    Settings.ESPEnabled=not Settings.ESPEnabled
    BtnESP.Text=Settings.ESPEnabled and "👁 ESP ON" or "👁 ESP"
    BtnESP.BackgroundColor3=Settings.ESPEnabled and Color3.fromRGB(20,50,74) or Color3.fromRGB(24,24,40)
    if not Settings.ESPEnabled then ClearESP() end
end)

BtnMouseLock.Activated:Connect(function()
    Settings.MouseLock=not Settings.MouseLock
    BtnMouseLock.Text=Settings.MouseLock and "🖱️ Mouse Lock : ON" or "🖱️ Mouse Lock : OFF"
    BtnMouseLock.BackgroundColor3=Settings.MouseLock and Color3.fromRGB(64,20,90) or Color3.fromRGB(24,24,40)
    BtnMouseLock.TextColor3=Settings.MouseLock and Color3.fromRGB(230,180,255) or Color3.fromRGB(200,160,255)
end)

BtnLockMenu.Activated:Connect(function()
    menuLocked=not menuLocked
    BtnLockMenu.Text=menuLocked and "🔒" or "🔓"
    BtnLockMenu.BackgroundColor3=menuLocked and Color3.fromRGB(72,52,16) or Color3.fromRGB(40,40,62)
end)

local minimized=false
BtnMin.Activated:Connect(function()
    minimized=not minimized; Con.Visible=not minimized
    MF.Size=minimized and UDim2.new(0,232,0,32) or UDim2.new(0,232,0,440)
end)
BtnClose.Activated:Connect(function()
    StopLock(); ClearESP()
    pcall(function() SG:Destroy() end)
    pcall(function() CrossSG:Destroy() end)
end)

-- Scan
local scanVis=false
BtnScan.Activated:Connect(function()
    scanVis=not scanVis; SF.Visible=scanVis
    BtnScan.BackgroundColor3=scanVis and Color3.fromRGB(24,40,74) or Color3.fromRGB(24,24,40)
end)
BtnSClose.Activated:Connect(function()
    scanVis=false; SF.Visible=false; CPop.Visible=false; EPop.Visible=false
    BtnScan.BackgroundColor3=Color3.fromRGB(24,24,40)
end)
local sMin=false
BtnSMin.Activated:Connect(function()
    sMin=not sMin; SScr.Visible=not sMin; BtnDoScan.Visible=not sMin
    ScanCntLbl.Visible=not sMin; FBar.Visible=not sMin; EBar.Visible=not sMin
    SF.Size=sMin and UDim2.new(0,220,0,30) or UDim2.new(0,220,0,340)
    if sMin then CPop.Visible=false; EPop.Visible=false end
end)
BtnDoScan.Activated:Connect(function()
    for _,c in ipairs(SScr:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
    local raw=GetTargetList(); foundColors={}
    for _,e in ipairs(raw) do local h=Hex(e.color); if not foundColors[h] then foundColors[h]=e.color end end
    local list=FilterList(raw); targetList=list
    ScanCntLbl.Text=#list.." found  (raw:"..#raw..")"
    for i,e in ipairs(list) do
        local b=mkBtn(SScr,string.format("  [%d] %s  %.0fm",i,e.name,e.dist),
            UDim2.new(1,0,0,26),UDim2.new(0,0,0,0),Color3.fromRGB(14,14,22),e.color,9)
        b.TextXAlignment=Enum.TextXAlignment.Left
        local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,6,0,6); dot.Position=UDim2.new(0,4,0.5,-3)
        dot.BackgroundColor3=e.color; dot.BorderSizePixel=0; dot.Parent=b
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        b.Activated:Connect(function()
            targetIndex=i; SetTarget(e.model)
            if TPScanEnabled then
                local hrp=GetRoot(e.model)
                if hrp then
                    if tpModeSelect==1 then stopRapidTP(); doTP(hrp)
                    else startRapidTP(hrp) end
                end
            end
        end)
    end
    SScr.CanvasSize=UDim2.new(0,0,0,SLayout.AbsoluteContentSize.Y+4)
    UpdateCPicker(); UpdateEPicker()
end)

BtnCP2.Activated:Connect(function() CPop.Visible=not CPop.Visible; EPop.Visible=false; if CPop.Visible then UpdateCPicker() end end)
BtnCPClose.Activated:Connect(function() CPop.Visible=false end)
BtnCPAll.Activated:Connect(function()
    Settings.FilterColor=nil; FLbl.Text="🎨 Filter: ทั้งหมด"; FLbl.TextColor3=Color3.fromRGB(120,120,170)
    BtnCP2.BackgroundColor3=Color3.fromRGB(48,48,160); CPop.Visible=false; UpdateCPicker()
end)
BtnCF.Activated:Connect(function()
    Settings.FilterColor=nil; FLbl.Text="🎨 Filter: ทั้งหมด"; FLbl.TextColor3=Color3.fromRGB(120,120,170)
    BtnCP2.BackgroundColor3=Color3.fromRGB(48,48,160); UpdateCPicker()
end)

BtnExc.Activated:Connect(function()
    EPop.Visible=not EPop.Visible; CPop.Visible=false
    if EPop.Visible then pendEx={}; for _,h in ipairs(Settings.ExcludeColors) do table.insert(pendEx,h) end; UpdateEPicker() end
end)
BtnEPClose.Activated:Connect(function() EPop.Visible=false; pendEx={} end)
BtnEPOk.Activated:Connect(function()
    Settings.ExcludeColors={}; for _,h in ipairs(pendEx) do table.insert(Settings.ExcludeColors,h) end
    UpdateEPicker(); EPop.Visible=false; pendEx={}
end)
BtnCE.Activated:Connect(function() Settings.ExcludeColors={}; pendEx={}; UpdateEPicker() end)

-- Camera System
local camVis=false
BtnCamSys.Activated:Connect(function()
    camVis=not camVis; CamF.Visible=camVis
    BtnCamSys.BackgroundColor3=camVis and Color3.fromRGB(74,50,16) or Color3.fromRGB(24,24,40)
end)
local camMin2=false
BtnCamMin.Activated:Connect(function()
    camMin2=not camMin2; CamCon.Visible=not camMin2
    CamF.Size=camMin2 and UDim2.new(0,190,0,30) or UDim2.new(0,190,0,200)
    if camMin2 then CtrlPad.Visible=false end
end)
BtnCamClose.Activated:Connect(function()
    camVis=false; CamF.Visible=false; CtrlPad.Visible=false; camFreecam=false
    BtnCamSys.BackgroundColor3=Color3.fromRGB(24,24,40)
end)
BtnCamLock.Activated:Connect(function()
    camLocked=not camLocked
    BtnCamLock.Text=camLocked and "🔒 Lock Cam ON" or "🔒 Lock Cam OFF"
    BtnCamLock.BackgroundColor3=camLocked and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
end)
BtnCamFree.Activated:Connect(function()
    camFreecam=not camFreecam
    BtnCamFree.Text=camFreecam and "🎥 FreeCam ON" or "🎥 FreeCam OFF"
    BtnCamFree.BackgroundColor3=camFreecam and Color3.fromRGB(20,84,20) or Color3.fromRGB(150,32,32)
    CtrlPad.Visible=camFreecam
    if camFreecam then camFreePos=Camera.CFrame.Position end
end)

-- TP
local tpVis=false
BtnTP.Activated:Connect(function()
    tpVis=not tpVis; TF.Visible=tpVis
    BtnTP.BackgroundColor3=tpVis and Color3.fromRGB(16,50,26) or Color3.fromRGB(24,24,40)
    if tpVis then TPRefresh() end
end)
local tpMin=false
BtnTFMin.Activated:Connect(function()
    tpMin=not tpMin; TPScr.Visible=not tpMin
    BtnTPSave.Visible=not tpMin; BtnTPClic.Visible=not tpMin; BtnTPDel.Visible=not tpMin
    TF.Size=tpMin and UDim2.new(0,210,0,30) or UDim2.new(0,210,0,260)
end)
BtnTFClose.Activated:Connect(function() tpVis=false; TF.Visible=false; BtnTP.BackgroundColor3=Color3.fromRGB(24,24,40) end)
BtnTPSave.Activated:Connect(function()
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    table.insert(tpSaves,{x=root.Position.X,y=root.Position.Y,z=root.Position.Z}); TPRefresh()
end)
BtnTPDel.Activated:Connect(function()
    if tpSelected then table.remove(tpSaves,tpSelected); tpSelected=nil; TPRefresh() end
end)
BtnTPClic.Activated:Connect(function()
    clickTP=not clickTP; if not clickTP then lockPos=nil end
    BtnTPClic.Text=clickTP and "Click TP ON" or "Click TP OFF"
    BtnTPClic.BackgroundColor3=clickTP and Color3.fromRGB(20,92,40) or Color3.fromRGB(130,32,32)
end)
Mouse.Button1Down:Connect(function()
    if not clickTP then return end
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local hit=Mouse.Hit
    if hit then lockPos=hit.Position; root.CFrame=CFrame.new(lockPos+Vector3.new(0,3,0)) end
end)

-- TP Mode Popup
BtnTPMClose.Activated:Connect(function() TPModePopup.Visible=false end)
BtnTPM1.Activated:Connect(function() tpModeSelect=1; UpdateTPModeUI() end)
BtnTPM2.Activated:Connect(function() tpModeSelect=2; UpdateTPModeUI() end)
InpTPSpeed.FocusLost:Connect(function()
    local v=tonumber(InpTPSpeed.Text); if v then tpRapidSpeed=v else InpTPSpeed.Text=tostring(tpRapidSpeed) end
end)

-- Movement Panel
local mvVis=false
BtnMove.Activated:Connect(function()
    mvVis=not mvVis; MvF.Visible=mvVis
    BtnMove.BackgroundColor3=mvVis and Color3.fromRGB(20,70,25) or Color3.fromRGB(24,24,40)
end)
local mvMin=false
BtnMvMin.Activated:Connect(function()
    mvMin=not mvMin; MvScr.Visible=not mvMin
    MvF.Size=mvMin and UDim2.new(0,260,0,30) or UDim2.new(0,260,0,360)
end)
BtnMvClose.Activated:Connect(function()
    mvVis=false; MvF.Visible=false
    BtnMove.BackgroundColor3=Color3.fromRGB(24,24,40)
end)

BtnTPScan.Activated:Connect(function()
    TPScanEnabled=not TPScanEnabled
    if TPScanEnabled then
        BtnTPScan.BackgroundColor3=Color3.fromRGB(20,120,20)
        TPModePopup.Visible=true
    else
        BtnTPScan.BackgroundColor3=Color3.fromRGB(30,80,30)
        TPModePopup.Visible=false
        stopRapidTP()
    end
end)

-- ══ INIT ══
if Settings.NearestMode then BtnNear.Text="📍 Nearest : ON"; BtnNear.BackgroundColor3=Color3.fromRGB(20,58,20) end
