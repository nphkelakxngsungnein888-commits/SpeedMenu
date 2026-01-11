--// FISCH QUEST LOOP (NPC-LOCKED VERSION)
--// Ghost Hub Ready | Safe Logic

-------------------------
-- SERVICES
-------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-------------------------
-- UI CLEAN
-------------------------
if playerGui:FindFirstChild("FischQuestNPCUI") then
	playerGui.FischQuestNPCUI:Destroy()
end

-------------------------
-- STATE
-------------------------
local Enabled = false
local LastQuestPrompt = nil

-------------------------
-- CAPTURE NPC PROMPT
-------------------------
for _,v in ipairs(workspace:GetDescendants()) do
	if v:IsA("ProximityPrompt") then
		v.Triggered:Connect(function(plr)
			if plr == player then
				LastQuestPrompt = v
			end
		end)
	end
end

-------------------------
-- UTILS
-------------------------
local function hasQuestUI()
	for _,v in ipairs(playerGui:GetChildren()) do
		if v:IsA("ScreenGui") and v.Name:lower():find("quest") then
			return true
		end
	end
	return false
end

local function questCompleted()
	for _,v in ipairs(playerGui:GetDescendants()) do
		if v:IsA("TextLabel") then
			local t = v.Text:lower()
			if t:find("complete") or t:find("done") then
				return true
			end
		end
	end
	return false
end

-------------------------
-- AUTO FISH (เฉพาะที่ทำได้)
-------------------------
local function autoFish()
	for _,r in ipairs(game:GetDescendants()) do
		if r:IsA("RemoteEvent") and r.Name:lower():find("fish") then
			pcall(function()
				r:FireServer(true)
			end)
		end
	end
end

-------------------------
-- UI
-------------------------
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "FischQuestNPCUI"
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.fromScale(0.22,0.055)
btn.Position = UDim2.fromScale(0.02,0.72)
btn.Text = "AUTO QUEST : OFF"
btn.TextScaled = true
btn.Font = Enum.Font.GothamBold
btn.BackgroundColor3 = Color3.fromRGB(170,50,50)
btn.TextColor3 = Color3.new(1,1,1)
btn.BorderSizePixel = 0

Instance.new("UICorner", btn).CornerRadius = UDim.new(0.25,0)

btn.MouseButton1Click:Connect(function()
	Enabled = not Enabled
	btn.Text = Enabled and "AUTO QUEST : ON" or "AUTO QUEST : OFF"
	btn.BackgroundColor3 = Enabled and Color3.fromRGB(60,170,90)
		or Color3.fromRGB(170,50,50)
end)

-------------------------
-- MAIN LOOP
-------------------------
task.spawn(function()
	while task.wait(0.7) do
		if not Enabled then continue end

		if hasQuestUI() then
			autoFish()

			if questCompleted() then
				task.wait(1)
				if LastQuestPrompt then
					fireproximityprompt(LastQuestPrompt)
				end
			end
		end
	end
eend 
