-- Tests for ServerScriptService.Server.Rules: stage advancing, stored-value cleanup, save merging.
return function(t)
	local Rules = require(game:GetService("ServerScriptService").Server.Rules)
	local expect = t.expect

	-- The pad one above the current stage advances the player.
	t.test("advances to the next stage", function()
		expect.equal(Rules.nextStage(3, 4), 4)
	end)

	-- Touching the current stage's own pad changes nothing.
	t.test("stays when touching the current pad", function()
		expect.equal(Rules.nextStage(3, 3), 3)
	end)

	-- Walking back onto an earlier pad never lowers progress.
	t.test("stays when touching an earlier pad", function()
		expect.equal(Rules.nextStage(3, 1), 3)
	end)

	-- A pad more than one ahead is ignored, so teleporting ahead gains nothing.
	t.test("stays when touching a pad two ahead", function()
		expect.equal(Rules.nextStage(1, 3), 1)
	end)

	-- The finish pad (11) is reached from stage 10 like any other step.
	t.test("advances from the last stage to finished", function()
		expect.equal(Rules.nextStage(10, 11), 11)
	end)

	-- A valid stored stage is kept as is.
	t.test("sanitize keeps a valid stage", function()
		expect.equal(Rules.sanitizeStage(7), 7)
	end)

	-- Missing data means a new player.
	t.test("sanitize turns nil into the first stage", function()
		expect.equal(Rules.sanitizeStage(nil), 1)
	end)

	-- A wrong type is treated as missing.
	t.test("sanitize turns a string into the first stage", function()
		expect.equal(Rules.sanitizeStage("5"), 1)
	end)

	-- NaN is a number that fails comparisons; it must not survive.
	t.test("sanitize turns NaN into the first stage", function()
		expect.equal(Rules.sanitizeStage(0 / 0), 1)
	end)

	-- Infinite values are rejected.
	t.test("sanitize turns infinity into the first stage", function()
		expect.equal(Rules.sanitizeStage(math.huge), 1)
	end)

	-- Stages below the first are raised to the first.
	t.test("sanitize raises zero and negatives to the first stage", function()
		expect.equal(Rules.sanitizeStage(0), 1)
		expect.equal(Rules.sanitizeStage(-3), 1)
	end)

	-- Fractions are rounded down to a whole stage.
	t.test("sanitize rounds a fraction down", function()
		expect.equal(Rules.sanitizeStage(4.7), 4)
	end)

	-- A save never lowers stored progress.
	t.test("merge keeps the stored stage when it is higher", function()
		expect.equal(Rules.mergeStage(8, 2), 8)
	end)

	-- New progress replaces older stored progress.
	t.test("merge keeps the memory stage when it is higher", function()
		expect.equal(Rules.mergeStage(2, 8), 8)
	end)

	-- Nothing stored yet: the memory stage is written.
	t.test("merge uses the memory stage when nothing is stored", function()
		expect.equal(Rules.mergeStage(nil, 5), 5)
	end)

	-- Garbage in storage is treated as nothing stored.
	t.test("merge ignores a malformed stored stage", function()
		expect.equal(Rules.mergeStage("oops", 5), 5)
	end)
end
