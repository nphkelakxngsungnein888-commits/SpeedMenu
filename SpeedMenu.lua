local ok, err = pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/nphkelakxngsungnein888-commits/SpeedMenu/refs/heads/main/SpeedMenu.lua")
    local fn, loadErr = loadstring(code)
    if fn then fn()
    else error("loadstring fail: "..tostring(loadErr)) end
end)

if not ok then
    local g = Instance.new("ScreenGui")
    g.Parent = game.Players.LocalPlayer.PlayerGui
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,340,0,120)
    f.Position = UDim2.new(0.5,-170,0.5,-60)
    f.BackgroundColor3 = Color3.fromRGB(180,0,0)
    f.Parent = g
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,0,1,0)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.fromRGB(255,255,255)
    t.TextSize = 11
    t.Font = Enum.Font.GothamBold
    t.TextWrapped = true
    t.Text = "❌ "..tostring(err)
    t.Parent = f
end
