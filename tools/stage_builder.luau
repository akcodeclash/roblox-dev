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
			local className = if spec.number == 1 and p.stage == nil then "SpawnLocation" else "Part"
			local pad = newPart(className, "Checkpoint", p.size, position, p.color or PAD_COLOR, model)
			pad:SetAttribute("Stage", p.stage or spec.number)
			CollectionService:AddTag(pad, "Checkpoint")
			if pad:IsA("SpawnLocation") then
				pad.Neutral = true
				pad.Duration = 0
				-- Turn the pad so players spawn facing down the course (+Z).
				pad.CFrame = CFrame.new(position) * CFrame.Angles(0, math.pi, 0)
			end
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
			local pivot = newPart("Part", "SpinnerPivot", Vector3.new(1, 1, 1), position, spec.color, model)
			pivot.Transparency = 1
			pivot.CanCollide = false
			pivot.CanTouch = false
			local bar = newPart("Part", "SpinnerBar", p.size, position, KILL_COLOR, model)
			bar.Material = Enum.Material.Neon
			bar.Anchored = false
			bar.CanCollide = false
			bar:SetAttribute("SpinSpeed", p.speed)
			CollectionService:AddTag(bar, "KillPart")
			CollectionService:AddTag(bar, "Spinner")
			-- A hinge turns about its attachments' X axis; rotate them so X points up.
			local pivotAttachment = Instance.new("Attachment")
			pivotAttachment.CFrame = CFrame.Angles(0, 0, math.pi / 2)
			pivotAttachment.Parent = pivot
			local barAttachment = Instance.new("Attachment")
			barAttachment.CFrame = CFrame.Angles(0, 0, math.pi / 2)
			barAttachment.Parent = bar
			local hinge = Instance.new("HingeConstraint")
			hinge.Attachment0 = pivotAttachment
			hinge.Attachment1 = barAttachment
			hinge.ActuatorType = Enum.ActuatorType.Motor
			hinge.AngularVelocity = p.speed
			hinge.MotorMaxTorque = math.huge
			hinge.Parent = pivot
		else
			error("unknown part kind: " .. tostring(p.kind))
		end
	end

	return string.format("%s built: %d instances", name, #model:GetDescendants())
end
