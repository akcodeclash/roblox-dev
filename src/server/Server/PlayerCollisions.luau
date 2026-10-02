--!strict
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local GROUP = "Players"

local PlayerCollisions = {}

local function assign(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = GROUP
	end
end

local function onCharacterAdded(character: Model)
	character.DescendantAdded:Connect(assign)
	for _, descendant in character:GetDescendants() do
		assign(descendant)
	end
end

-- Characters pass through each other, so one player cannot push another off the course.
function PlayerCollisions.start()
	PhysicsService:RegisterCollisionGroup(GROUP)
	PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(onCharacterAdded)
		local character = player.Character
		if character then
			onCharacterAdded(character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlayerCollisions
