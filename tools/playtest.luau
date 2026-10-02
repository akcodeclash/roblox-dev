-- Prelude for execute_luau (Server datamodel, during a playtest). Append test lines after this text.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()

local function character()
	local model = player.Character or player.CharacterAdded:Wait()
	model:WaitForChild("HumanoidRootPart")
	model:WaitForChild("Humanoid")
	return model
end

local function stage()
	return player:WaitForChild("leaderstats", 10):WaitForChild("Stage", 10).Value
end

local function padFor(n)
	for _, pad in CollectionService:GetTagged("Checkpoint") do
		if pad:IsDescendantOf(Workspace) and pad:GetAttribute("Stage") == n then
			return pad
		end
	end
	error("no checkpoint pad for stage " .. n)
end

-- Puts the character on top of a part and gives touches time to register.
local function standOn(part)
	character():PivotTo(CFrame.new(part.Position + Vector3.new(0, part.Size.Y / 2 + 3, 0)))
	task.wait(1)
end

-- Kills the character and returns where the new one ends up.
local function killAndRespawn()
	character():FindFirstChildOfClass("Humanoid").Health = 0
	local new = player.CharacterAdded:Wait()
	local root = new:WaitForChild("HumanoidRootPart")
	task.wait(1)
	return root.Position
end
