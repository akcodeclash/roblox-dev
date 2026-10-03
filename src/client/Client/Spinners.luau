--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SpinnerMotion = require(ReplicatedStorage.Shared.SpinnerMotion)

local TAG = "Spinner"

local Spinners = {}

-- Bars are anchored and never move on the server. Each client turns them from
-- the shared server clock, so what the player sees is what the server tests
-- hits against, with no physics replication lag.
function Spinners.start()
	RunService.PreRender:Connect(function()
		local now = Workspace:GetServerTimeNow()
		for _, bar in CollectionService:GetTagged(TAG) do
			local pivot = bar:GetAttribute("Pivot")
			local speed = bar:GetAttribute("SpinSpeed")
			if bar:IsA("BasePart") and typeof(pivot) == "Vector3" and type(speed) == "number" then
				bar.CFrame = SpinnerMotion.cframe(pivot, speed, now)
			end
		end
	end)
end

return Spinners
