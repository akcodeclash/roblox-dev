--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SpinnerMotion = require(ReplicatedStorage.Shared.SpinnerMotion)

local TAG = "Spinner"
-- One-way latency above this is not trusted; the bar is rewound by at most this much.
local MAX_LAG = 0.3

local Spinners = {}

local function livingCharacter(player: Player): (Model?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return character, humanoid
	end
	return nil, nil
end

-- Spinner bars are anchored and never move on the server; clients draw them
-- from the server clock. Each frame the bar's pose is computed from that clock,
-- rewound by the player's ping so it lines up with where the server currently
-- sees the character, which is where the player saw themself against the bar.
function Spinners.start()
	RunService.Heartbeat:Connect(function()
		local now = Workspace:GetServerTimeNow()
		local bars = CollectionService:GetTagged(TAG)
		for _, player in Players:GetPlayers() do
			local character, humanoid = livingCharacter(player)
			if not character or not humanoid then
				continue
			end
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { character }
			-- GetNetworkPing is a round trip; the character's position is one way old.
			local t = now - math.min(player:GetNetworkPing() / 2, MAX_LAG)
			for _, bar in bars do
				local pivot = bar:GetAttribute("Pivot")
				local speed = bar:GetAttribute("SpinSpeed")
				if bar:IsA("BasePart") and typeof(pivot) == "Vector3" and type(speed) == "number" then
					local cframe = SpinnerMotion.cframe(pivot, speed, t)
					if #Workspace:GetPartBoundsInBox(cframe, bar.Size, params) > 0 then
						humanoid.Health = 0
						break
					end
				end
			end
		end
	end)
end

return Spinners
