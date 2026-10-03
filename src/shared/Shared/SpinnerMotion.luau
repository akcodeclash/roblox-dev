--!strict
-- Where a spinner bar is at a given server time. Pure, so the client can draw
-- the bar and the server can test hits from the same clock without replication.
local SpinnerMotion = {}

local TURN = 2 * math.pi

-- Radians turned after t seconds at speed radians per second, wrapped to one
-- turn. t is a server timestamp (around 1.7e9), so the raw product is far too
-- large for CFrame.Angles, which works in single precision.
function SpinnerMotion.yaw(speed: number, t: number): number
	return (speed * t) % TURN
end

-- The bar's CFrame: centred on the pivot, turned about the vertical axis.
function SpinnerMotion.cframe(pivot: Vector3, speed: number, t: number): CFrame
	return CFrame.new(pivot) * CFrame.Angles(0, SpinnerMotion.yaw(speed, t), 0)
end

return SpinnerMotion
