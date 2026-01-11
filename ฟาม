--// FISCH AUTO QUEST - READY TO USE VERSION
--// UI FIXED | PlayerGui | LocalScript

-----------------------------
-- SERVICES
-----------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-----------------------------
-- CONFIG (ถ้าเกมอัปเดต ค่อยแก้)
-----------------------------
local QUEST_GUI_NAME = "QuestGui"
local QUEST_TEXT_NAME = "QuestText"
local PROGRESS_TEXT_NAME = "ProgressText"

local FISH_REMOTE_NAME = "CatchFish"
local QUEST_ACCEPT_REMOTE = "AcceptQuest"
local QUEST_TURNIN_REMOTE = "CompleteQuest"

-----------------------------
-- STATE
-----------------------------
local enabled = false

-----------------------------
-- UTILS
-----------------------------
local function findRemote(name)
	for _,v in pairs(game:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name == name then
			return v
		end
	end
end

local function getQuestInfo()
	local gui = playerGui:FindFirstChild(QUEST_GUI_NAME)
	if not gui then return nil end

	local questText = gui:FindFirstChild(QUEST_TEXT_NAME, true)
	local progressText = gui:FindFirstChild(PROGRESS_TEXT_NAME, true)

	if questText and questText.Text ~= "" then
		return {
			name = questText.Text,
			progress = progressText and progressText.Text or ""
		}
	end
	return nil
end

-----------------------------
-- QUEST ACTIONS
-----------------------------
local function acceptQuest()
	local r = findRemote(QUEST_ACCEPT_REMOTE)
	if r then r:FireServer() end
end

local function turnInQuest()
	local r = findRemote(QUEST_TURNIN_REMOTE)
	if r then r:FireServer() end
end

local function autoFish()
	local r = findRemote(FISH_REMOTE_NAME)
	if r then
		r:FireServer(true) -- ข้ามมินิเกม
	end
end

-----------------------------
-- UI (FIXED 100%)
-----------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FischAutoQuestUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.fromScale(0.24,0.06)
button.Position = UDim2.fromScale(0.02,0.7)
button.Text = "AUTO QUEST : OFF"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.BackgroundColor3 = Color3.fromRGB(180,60,60)
button.TextColor3 = Color3.new(1,1,1)
button.BorderSizePixel = 0

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.25,0)
corner.Parent = button

button.MouseButton1Click:Connect(function()
	enabled = not enabled
	button.Text = enabled and "AUTO QUEST : ON" or "AUTO QUEST : OFF"
	button.BackgroundColor3 = enabled
		and Color3.fromRGB(60,180,90)
		or Color3.fromRGB(180,60,60)
end)

-----------------------------
-- MAIN LOOP
-----------------------------
task.spawn(function()
	while task.wait(0.6) do
		if not enabled then continue end

		local quest = getQuestInfo()

		-- ไม่มีเควส → รับ
		if not quest then
			acceptQuest()
			task.wait(1.5)
			continue
		end

		-- ทำเควสตกปลา
		autoFish()

		-- เควสเสร็จ
		if quest.progress:lower():find("complete")
		or quest.progress:lower():find("done") then
			task.wait(0.8)
			turnInQuest()
			task.wait(1.5)
		end
	end
end)
