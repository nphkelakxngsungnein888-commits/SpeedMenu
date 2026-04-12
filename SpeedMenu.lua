local ok, result = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/nphkelakxngsungnein888-commits/SpeedMenu/refs/heads/main/SpeedMenu.lua")
end)
if ok then
    print("ดึงได้ ยาว: "..#result)
else
    print("ดึงไม่ได้: "..tostring(result))
end
