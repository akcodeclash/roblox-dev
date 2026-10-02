--!strict
-- Runs the unit tests at server start in Studio. Results go to the Output window.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

if RunService:IsStudio() then
	local unitTest = ServerStorage:FindFirstChild("UnitTest")
	local runner = unitTest and unitTest:FindFirstChild("RunUnitTest")
	if runner and runner:IsA("ModuleScript") then
		(require(runner) :: any)(nil, 5)
	end
end
