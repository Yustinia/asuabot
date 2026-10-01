--- Finds door entities within a radius of a position.
-- Catches the standard Source door classes. Custom/workshop doors using non-standard
-- classes won't be found by this — expect inconsistent coverage across maps.
-- @param pos Vector
-- @param radius number
-- @return table: list of door entities found
function ENT:FindDoors(pos, radius)
	local classes = { "prop_door_rotating", "func_door", "func_door_rotating" }
	local found = {}

	for _, class in ipairs(classes) do
		for _, door in ipairs(ents.FindByClass(class)) do
			if IsValid(door) and door:GetPos():Distance(pos) <= radius then
				table.insert(found, door)
			end
		end
	end

	return found
end

--- Finds ladder entities within a radius of a position.
-- Finding only — Nextbot locomotion has no native ladder-climb support, so this
-- is informational (e.g. for avoidance or future custom climbing logic), not usable
-- for traversal as-is.
-- @param pos Vector
-- @param radius number
-- @return table: list of ladder entities found
function ENT:FindLadders(pos, radius)
	local found = {}

	for _, ladder in ipairs(ents.FindByClass("func_useableladder")) do
		if IsValid(ladder) and ladder:GetPos():Distance(pos) <= radius then
			table.insert(found, ladder)
		end
	end

	return found
end

--- Finds hazard entities within a radius of a position.
-- Covers standard damaging triggers and common hazard-adjacent entities.
-- Finding only — avoiding these in pathing would need the same cost-override
-- approach flagged as fragile for FindAlternativePath, not included here.
-- @param pos Vector
-- @param radius number
-- @return table: list of hazard entities found
function ENT:FindHazards(pos, radius)
	local classes = { "trigger_hurt", "env_fire", "trigger_push" }
	local found = {}

	for _, class in ipairs(classes) do
		for _, hazard in ipairs(ents.FindByClass(class)) do
			if IsValid(hazard) and hazard:GetPos():Distance(pos) <= radius then
				table.insert(found, hazard)
			end
		end
	end

	return found
end
