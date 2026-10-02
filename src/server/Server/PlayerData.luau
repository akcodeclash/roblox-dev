--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Rules = require(script.Parent.Rules)

local STORE_NAME = "PlayerData"
local SAVE_INTERVAL = 180
local MAX_ATTEMPTS = 5
local FIRST_RETRY_DELAY = 1

type Session = {
	stage: number,
	savedStage: number?,
}
type StageCallback = (player: Player, stage: number) -> ()

local PlayerData = {}

local sessions: { [Player]: Session } = {}
local stageChangedCallbacks: { StageCallback } = {}
local stageRestoredCallbacks: { StageCallback } = {}
local store: DataStore? = nil

local function keyFor(player: Player): string
	return "User_" .. player.UserId
end

local function fire(callbacks: { StageCallback }, player: Player, stage: number)
	for _, callback in callbacks do
		task.spawn(callback, player, stage)
	end
end

-- Runs fn up to MAX_ATTEMPTS times, waiting longer after each failure.
local function withRetries(description: string, fn: () -> any): (boolean, any)
	local delay = FIRST_RETRY_DELAY
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(string.format("[PlayerData] %s failed (attempt %d of %d): %s", description, attempt, MAX_ATTEMPTS, tostring(result)))
		if attempt < MAX_ATTEMPTS then
			task.wait(delay * (1 + 0.5 * math.random()))
			delay *= 2
		end
	end
	return false, nil
end

local function load(player: Player)
	local dataStore = store
	if not dataStore then
		return
	end
	local ok, value = withRetries("load for " .. keyFor(player), function()
		return dataStore:GetAsync(keyFor(player))
	end)
	local session = sessions[player]
	if not ok or not session then
		return
	end
	local storedStage = if type(value) == "table" then Rules.sanitizeStage(value.stage) else Rules.FIRST_STAGE
	session.savedStage = storedStage
	if storedStage > session.stage then
		session.stage = storedStage
		fire(stageChangedCallbacks, player, storedStage)
		fire(stageRestoredCallbacks, player, storedStage)
	end
end

local function save(player: Player)
	local dataStore = store
	local session = sessions[player]
	if not dataStore or not session then
		return
	end
	local stage = session.stage
	-- A stored stage is never below FIRST_STAGE, so with no load result that is the baseline.
	if (session.savedStage or Rules.FIRST_STAGE) >= stage then
		return
	end
	local ok = withRetries("save for " .. keyFor(player), function()
		dataStore:UpdateAsync(keyFor(player), function(old: any)
			local data = if type(old) == "table" then old else {}
			data.stage = Rules.mergeStage(data.stage, stage)
			return data
		end)
		return nil
	end)
	if ok then
		session.savedStage = stage
	end
end

local function onPlayerAdded(player: Player)
	if sessions[player] then
		return
	end
	local session: Session = { stage = Rules.FIRST_STAGE, savedStage = nil }
	sessions[player] = session
	task.spawn(load, player)
	task.spawn(function()
		task.wait(math.random() * SAVE_INTERVAL)
		while sessions[player] == session do
			save(player)
			task.wait(SAVE_INTERVAL)
		end
	end)
end

local function onPlayerRemoving(player: Player)
	save(player)
	sessions[player] = nil
end

local function onClose()
	local pending = 0
	for player in sessions do
		pending += 1
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end

function PlayerData.getStage(player: Player): number
	local session = sessions[player]
	return if session then session.stage else Rules.FIRST_STAGE
end

function PlayerData.setStage(player: Player, stage: number)
	local session = sessions[player]
	if not session or session.stage == stage then
		return
	end
	session.stage = stage
	fire(stageChangedCallbacks, player, stage)
end

function PlayerData.onStageChanged(callback: StageCallback)
	table.insert(stageChangedCallbacks, callback)
end

function PlayerData.onStageRestored(callback: StageCallback)
	table.insert(stageRestoredCallbacks, callback)
end

function PlayerData.start()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] data store unavailable; progress will not be saved this session: " .. tostring(result))
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(onClose)
end

return PlayerData
