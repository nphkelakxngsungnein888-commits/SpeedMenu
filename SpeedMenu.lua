local ok, result = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/nphkelakxngsungnein888-commits/SpeedMenu/refs/heads/main/SpeedMenu.lua")
end)

local g = Instance.new("ScreenGui")
g.Parent = game.Players.LocalPlayer.PlayerGui
local f = Instance.new("Frame")
f.Size = UDim2.new(0,300,0,80)
f.Position = UDim2.new(0.5,-150,0.5,-40)
f.BackgroundColor3 = ok and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0)
f.Parent = g
local t = Instance.new("TextLabel")
t.Size = UDim2.new(1,0,1,0)
t.BackgroundTransparency = 1
t.TextColor3 = Color3.fromRGB(255,255,255)
t.TextSize = 14
t.Font = Enum.Font.GothamBold
t.Text = ok and "✅ ดึงได้! ยาว: "..#result.." chars" or "❌ ดึงไม่ได้: "..tostring(result)
t.Parent = f
