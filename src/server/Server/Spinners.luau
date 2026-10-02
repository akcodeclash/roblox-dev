--!strict
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local TAG = "Spinner"

local Spinners = {}

-- Spinner bars are unanchored kill parts. Keep their physics on the server
-- so a nearby client can never take ownership and move one onto other players.
local function claim(instance: Instance)
	if instance:IsA("BasePart") and instance:IsDescendantOf(Workspace) and not instance.Anchored then
		instance:SetNetworkOwner(nil)
	end
end

function Spinners.start()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(claim)
	for _, instance in CollectionService:GetTagged(TAG) do
		claim(instance)
	end
end

return Spinners
