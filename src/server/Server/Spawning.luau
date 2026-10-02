--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Checkpoints = require(script.Parent.Checkpoints)
local PlayerData = require(script.Parent.PlayerData)
local Rules = require(script.Parent.Rules)

-- Height of the character's pivot above the pad's top surface.
local PAD_CLEARANCE = 4

local Spawning = {}

-- Stage 1 needs nothing: the engine spawns characters on the stage 1 pad, which is a SpawnLocation.
local function placeOnPad(player: Player)
	local stage = PlayerData.getStage(player)
	if stage == Rules.FIRST_STAGE then
		return
	end
	local character = player.Character
	local pad = Checkpoints.getPad(stage)
	if not character or not pad then
		return
	end
	local position = pad.Position + Vector3.new(0, pad.Size.Y / 2 + PAD_CLEARANCE, 0)
	-- The course runs along +Z, so face that way.
	character:PivotTo(CFrame.lookAt(position, position + Vector3.zAxis))
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart")
	if not character:IsDescendantOf(Workspace) then
		character.AncestryChanged:Wait()
	end
	-- Let the engine finish its own spawn placement before moving the character.
	RunService.Heartbeat:Wait()
	if player.Character == character then
		placeOnPad(player)
	end
end

function Spawning.start()
	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			onCharacterAdded(player, character)
		end)
		local character = player.Character
		if character then
			task.spawn(onCharacterAdded, player, character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	PlayerData.onStageRestored(function(player: Player)
		placeOnPad(player)
	end)
end

return Spawning
