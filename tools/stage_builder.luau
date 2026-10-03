-- Prelude for execute_luau (Edit datamodel). Append a `return buildStage({...})` call after this text.
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local KILL_COLOR = Color3.fromRGB(255, 60, 60)
local PAD_COLOR = Color3.fromRGB(245, 245, 245)

local function getStagesFolder()
	local folder = Workspace:FindFirstChild("Stages")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Stages"
		folder.Parent = Workspace
	end
	return folder
end

local function newPart(className, name, size, position, color, parent)
	local part = Instance.new(className)
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function buildStage(spec)
	local stages = getStagesFolder()
	local name = "Stage" .. spec.number
	if stages:FindFirstChild(name) then
		error(name .. " already exists. Delete it in Studio first if a rebuild is intended.")
	end

	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("Number", spec.number)
	model.Parent = stages

	local order = 0
	local function walkable(part)
		part:SetAttribute("Order", order)
		order += 1
	end

	for _, p in spec.parts do
		local position = spec.origin + p.offset
		if p.kind == "pad" then
			local pad = newPart("Part", "Checkpoint", p.size, position, p.color or PAD_COLOR, model)
			pad:SetAttribute("Stage", p.stage or spec.number)
			CollectionService:AddTag(pad, "Checkpoint")
			walkable(pad)
		elseif p.kind == "platform" then
			walkable(newPart("Part", "Platform", p.size, position, spec.color, model))
		elseif p.kind == "kill" then
			local kill = newPart("Part", "Kill", p.size, position, KILL_COLOR, model)
			kill.Material = Enum.Material.Neon
			CollectionService:AddTag(kill, "KillPart")
		elseif p.kind == "truss" then
			walkable(newPart("TrussPart", "Truss", p.size, position, spec.color, model))
		elseif p.kind == "conveyor" then
			local conveyor = newPart("Part", "Conveyor", p.size, position, spec.color, model)
			conveyor.Material = Enum.Material.DiamondPlate
			conveyor.AssemblyLinearVelocity = p.velocity
			conveyor:SetAttribute("ConveyorVelocity", p.velocity)
			CollectionService:AddTag(conveyor, "Conveyor")
			walkable(conveyor)
		elseif p.kind == "spinner" then
			-- Anchored; the Spinners modules turn it from the server clock (no physics).
			local bar = newPart("Part", "SpinnerBar", p.size, position, KILL_COLOR, model)
			bar.Material = Enum.Material.Neon
			bar.CanCollide = false
			bar:SetAttribute("Pivot", position)
			bar:SetAttribute("SpinSpeed", p.speed)
			CollectionService:AddTag(bar, "Spinner")
		else
			error("unknown part kind: " .. tostring(p.kind))
		end
	end

	return string.format("%s built: %d instances", name, #model:GetDescendants())
end
