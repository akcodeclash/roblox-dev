--!strict
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local PlayerData = require(script.Parent.PlayerData)
local Rules = require(script.Parent.Rules)
local Touch = require(script.Parent.Touch)

local TAG = "Checkpoint"
local STAGE_ATTRIBUTE = "Stage"

local Checkpoints = {}

local function getPadStage(pad: Instance): number?
	local stage = pad:GetAttribute(STAGE_ATTRIBUTE)
	if type(stage) == "number" then
		return stage
	end
	return nil
end

-- Returns the pad for the given stage, or for the highest stage below it when that pad does not exist.
function Checkpoints.getPad(stage: number): BasePart?
	local best: BasePart? = nil
	local bestStage = -math.huge
	for _, instance in CollectionService:GetTagged(TAG) do
		if instance:IsA("BasePart") and instance:IsDescendantOf(Workspace) then
			local padStage = getPadStage(instance)
			if padStage and padStage <= stage and padStage > bestStage then
				best = instance
				bestStage = padStage
			end
		end
	end
	return best
end

function Checkpoints.start()
	local seen: { [number]: boolean } = {}
	for _, instance in CollectionService:GetTagged(TAG) do
		local padStage = getPadStage(instance)
		if not padStage then
			warn("[Checkpoints] pad has no number attribute 'Stage': " .. instance:GetFullName())
		elseif seen[padStage] then
			warn(string.format("[Checkpoints] more than one pad for stage %d: %s", padStage, instance:GetFullName()))
		else
			seen[padStage] = true
		end
	end

	Touch.onTagTouched(TAG, function(pad: BasePart, hit: BasePart)
		local padStage = getPadStage(pad)
		if not padStage then
			return
		end
		local player = Touch.getLivingPlayer(hit)
		if not player then
			return
		end
		local current = PlayerData.getStage(player)
		local nextStage = Rules.nextStage(current, padStage)
		if nextStage ~= current then
			PlayerData.setStage(player, nextStage)
		end
	end)
end

return Checkpoints
