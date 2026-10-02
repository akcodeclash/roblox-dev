--!strict
local Touch = require(script.Parent.Touch)

local TAG = "KillPart"

local KillParts = {}

function KillParts.start()
	Touch.onTagTouched(TAG, function(_part: BasePart, hit: BasePart)
		local _player, humanoid = Touch.getLivingPlayer(hit)
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

return KillParts
