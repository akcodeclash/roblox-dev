-- Run with execute_luau (Edit datamodel). Returns "OK ..." or a list of jumps that exceed the limits.
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local jumpHeight = if StarterPlayer.CharacterUseJumpPower
	then StarterPlayer.CharacterJumpPower ^ 2 / (2 * Workspace.Gravity)
	else StarterPlayer.CharacterJumpHeight
local reach = StarterPlayer.CharacterWalkSpeed * 2 * math.sqrt(2 * jumpHeight / Workspace.Gravity)
local MAX_GAP = 0.75 * reach
local MAX_RISE = 0.6 * jumpHeight
local MAX_TRUSS_GAP = 1.5

local function bounds(part)
	local cf = part.CFrame
	local half = part.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local extent = Vector3.new(
		math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z
	)
	return cf.Position - extent, cf.Position + extent
end

local function numberOf(instance, attribute)
	local value = instance:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

local stages = Workspace:FindFirstChild("Stages")
if not stages then
	return "Workspace.Stages does not exist"
end

local models = stages:GetChildren()
table.sort(models, function(a, b)
	return numberOf(a, "Number") < numberOf(b, "Number")
end)

local steps = {}
for _, model in models do
	local parts = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and type(descendant:GetAttribute("Order")) == "number" then
			table.insert(parts, descendant)
		end
	end
	table.sort(parts, function(a, b)
		return numberOf(a, "Order") < numberOf(b, "Order")
	end)
	for _, part in parts do
		table.insert(steps, part)
	end
end

local problems = {}
for i = 1, #steps - 1 do
	local a, b = steps[i], steps[i + 1]
	local aMin, aMax = bounds(a)
	local bMin, bMax = bounds(b)
	local dx = math.max(0, aMin.X - bMax.X, bMin.X - aMax.X)
	local dz = math.max(0, aMin.Z - bMax.Z, bMin.Z - aMax.Z)
	local gap = math.sqrt(dx * dx + dz * dz)
	local rise = bMax.Y - aMax.Y
	local label = string.format("%s[%d] -> %s[%d]", a.Parent.Name, numberOf(a, "Order"), b.Parent.Name, numberOf(b, "Order"))
	if a:IsA("TrussPart") or b:IsA("TrussPart") then
		if gap > MAX_TRUSS_GAP then
			table.insert(problems, string.format("%s: truss gap %.1f (max %.1f)", label, gap, MAX_TRUSS_GAP))
		end
	else
		if gap > MAX_GAP then
			table.insert(problems, string.format("%s: gap %.1f (max %.1f)", label, gap, MAX_GAP))
		end
		if rise > MAX_RISE then
			table.insert(problems, string.format("%s: rise %.1f (max %.1f)", label, rise, MAX_RISE))
		end
	end
end

if #problems == 0 then
	return string.format("OK: %d jumps checked, max gap %.1f, max rise %.1f", #steps - 1, MAX_GAP, MAX_RISE)
end
return table.concat(problems, "\n")
