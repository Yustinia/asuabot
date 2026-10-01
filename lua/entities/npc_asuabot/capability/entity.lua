--- Finds all entities of a given class.
-- @param class string
-- @return table
function ENT:FindEntitiesByClass(class)
	return ents.FindByClass(class)
end

--- Finds the nearest entity of a given class to a position.
-- @param pos Vector
-- @param class string
-- @return Entity|nil
function ENT:FindNearestEntity(pos, class)
	local nearest, nearestDist = nil, math.huge

	for _, ent in ipairs(ents.FindByClass(class)) do
		if IsValid(ent) then
			local dist = ent:GetPos():Distance(pos)
			if dist < nearestDist then
				nearest, nearestDist = ent, dist
			end
		end
	end

	return nearest
end
