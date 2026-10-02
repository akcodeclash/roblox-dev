--!strict
local Players = game:GetService("Players")

local PlayerData = require(script.Parent.PlayerData)

local Leaderboard = {}

local function setUp(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = PlayerData.getStage(player)
	stage.Parent = leaderstats
	leaderstats.Parent = player
end

function Leaderboard.start()
	Players.PlayerAdded:Connect(setUp)
	for _, player in Players:GetPlayers() do
		setUp(player)
	end
	PlayerData.onStageChanged(function(player: Player, stage: number)
		local leaderstats = player:FindFirstChild("leaderstats")
		local value = leaderstats and leaderstats:FindFirstChild("Stage")
		if value and value:IsA("IntValue") then
			value.Value = stage
		end
	end)
end

return Leaderboard
