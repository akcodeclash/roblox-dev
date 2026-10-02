--!strict
local Rules = {}

Rules.FIRST_STAGE = 1

-- A checkpoint counts only when it is exactly one above the player's stage.
function Rules.nextStage(currentStage: number, touchedStage: number): number
	if touchedStage == currentStage + 1 then
		return touchedStage
	end
	return currentStage
end

-- Turns any stored value into a whole stage number of at least FIRST_STAGE.
function Rules.sanitizeStage(value: unknown): number
	if type(value) ~= "number" then
		return Rules.FIRST_STAGE
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return Rules.FIRST_STAGE
	end
	return math.max(Rules.FIRST_STAGE, math.floor(value))
end

-- A save keeps whichever stage is higher, so stored progress never goes down.
function Rules.mergeStage(storedStage: unknown, memoryStage: number): number
	return math.max(Rules.sanitizeStage(storedStage), memoryStage)
end

return Rules
