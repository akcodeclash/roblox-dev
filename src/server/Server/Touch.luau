--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Touch = {}

-- Returns the player whose living character the touching part belongs to.
function Touch.getLivingPlayer(hit: BasePart): (Player?, Humanoid?)
	local model = hit:FindFirstAncestorOfClass("Model")
	while model do
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				return player, humanoid
			end
			return nil, nil
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

-- Calls callback(part, hit) whenever a part carrying the tag is touched,
-- including parts tagged after this call.
function Touch.onTagTouched(tag: string, callback: (part: BasePart, hit: BasePart) -> ())
	local connections: { [Instance]: RBXScriptConnection } = {}

	local function add(instance: Instance)
		if instance:IsA("BasePart") and not connections[instance] then
			connections[instance] = instance.Touched:Connect(function(hit: BasePart)
				callback(instance, hit)
			end)
		end
	end

	local function remove(instance: Instance)
		local connection = connections[instance]
		if connection then
			connection:Disconnect()
			connections[instance] = nil
		end
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	for _, instance in CollectionService:GetTagged(tag) do
		add(instance)
	end
end

return Touch
