-- Tests for ReplicatedStorage.Shared.SpinnerMotion: bar pose from the shared clock.
return function(t)
	local SpinnerMotion = require(game:GetService("ReplicatedStorage").Shared.SpinnerMotion)
	local expect = t.expect

	local function near(a, b)
		return math.abs(a - b) < 1e-4
	end

	-- Angle grows linearly with time, wrapped into one turn.
	t.test("yaw is speed times time wrapped to one turn", function()
		expect.equal(SpinnerMotion.yaw(2, 3), 6)
		expect.truthy(near(SpinnerMotion.yaw(2, 4), 8 - 2 * math.pi))
		expect.truthy(near(SpinnerMotion.yaw(-2.5, 4), -10 + 4 * math.pi))
	end)

	-- Server timestamps are around 1.7e9 s; the bar must still turn smoothly there.
	t.test("cframe keeps turning at server timestamps", function()
		local speed, t = 1.5, 1.7e9
		local a = SpinnerMotion.cframe(Vector3.zero, speed, t).RightVector
		local b = SpinnerMotion.cframe(Vector3.zero, speed, t + 0.1).RightVector
		local turned = math.acos(math.clamp(a:Dot(b), -1, 1))
		expect.truthy(math.abs(turned - speed * 0.1) < 1e-3)
	end)

	-- The bar stays centred on its pivot whatever the time.
	t.test("cframe keeps the pivot position", function()
		local pivot = Vector3.new(0, 101.5, 580)
		expect.equal(SpinnerMotion.cframe(pivot, 1.5, 123.456).Position, pivot)
	end)

	-- At time zero the bar lies along X, as built.
	t.test("cframe at time zero is unrotated", function()
		local right = SpinnerMotion.cframe(Vector3.zero, 1.5, 0).RightVector
		expect.truthy(near(right.X, 1) and near(right.Z, 0))
	end)

	-- A quarter turn at positive speed swings the +X end toward -Z (right-handed about +Y).
	t.test("cframe turns a quarter at pi over two speed", function()
		local speed = 2
		local right = SpinnerMotion.cframe(Vector3.zero, speed, math.pi / 2 / speed).RightVector
		expect.truthy(near(right.X, 0) and near(right.Z, -1))
	end)

	-- Negative speed turns the other way.
	t.test("cframe with negative speed turns the other way", function()
		local speed = -2
		local right = SpinnerMotion.cframe(Vector3.zero, speed, math.pi / 2 / -speed).RightVector
		expect.truthy(near(right.X, 0) and near(right.Z, 1))
	end)
end
