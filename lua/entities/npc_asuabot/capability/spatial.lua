function ENT:IsAtPosition(pos, tolerance)
	tolerance = tolerance or 60

	return self:GetPos():Distance(pos) <= tolerance
end

function ENT:FindPositionBetweenEntities(entA, entB, biasTowardA)
	if not IsValid(entA) or not IsValid(entB) then
		return nil
	end
	biasTowardA = biasTowardA or 0.5

	local mid = LerpVector(biasTowardA, entA:GetPos(), entB:GetPos())
	return navmesh.GetNearestNavArea(mid)
end

--- Finds a nearby nav area with no line of sight to a given position.
-- @param scanRadius number: search radius around the bot
-- @param avoidPos Vector: the position to stay hidden from (usually the player)
-- @return Vector|nil: center of a qualifying area, or nil if none found
function ENT:FindPositionWithoutLOS(scanRadius, avoidPos)
	local candidates = {}

	for _, area in pairs(self.GlobalContext.CachedNavmesh) do
		local center = area:GetCenter()
		if center:Distance(self:GetPos()) <= scanRadius then
			if not self:CheckLOS(center, avoidPos) then
				table.insert(candidates, center)
			end
		end
	end

	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(#candidates)]
end

--- Finds a nearby nav area WITH line of sight to a given position.
-- Mirror of FindPositionWithoutLOS — same loop, inverted condition.
-- @param scanRadius number
-- @param targetPos Vector: the position that must be visible from the candidate spot
-- @return Vector|nil
function ENT:FindPositionWithLOS(scanRadius, targetPos)
	local candidates = {}

	for _, area in pairs(self.GlobalContext.CachedNavmesh) do
		local center = area:GetCenter()
		if center:Distance(self:GetPos()) <= scanRadius then
			if self:CheckLOS(center, targetPos) then
				table.insert(candidates, center)
			end
		end
	end

	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(#candidates)]
end

--- Finds a hiding spot: close to the bot, not visible from the player.
-- @param scanRadius number
-- @param playerPos Vector
-- @return Vector|nil
function ENT:FindHidePosition(scanRadius, playerPos)
	return self:FindPositionWithoutLOS(scanRadius, playerPos)
end
