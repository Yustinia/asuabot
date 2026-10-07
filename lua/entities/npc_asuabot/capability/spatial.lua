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

--- Finds a nav area behind the target, at a radial distance from it.
-- Prefers spots with no line of sight to the target, and falls back to any spot behind them.
-- @param target Player: who to stay behind
-- @param minRadius number: closest allowed distance from the target
-- @param maxRadius number: farthest allowed distance from the target
-- @return Vector|nil: center of a qualifying area, or nil if none found
function ENT:FindPositionBehindTarget(target, minRadius, maxRadius)
	if not IsValid(target) then
		return nil
	end

	local tPos = target:GetPos()
	local eye = target:EyePos()

	local fwd = target:GetForward()
	fwd.z = 0
	fwd:Normalize()

	local behind, hidden = {}, {}

	for _, area in pairs(self.GlobalContext.CachedNavmesh) do
		local center = area:GetCenter()
		local dist = center:Distance(tPos)

		if dist >= minRadius and dist <= maxRadius then
			local dir = center - tPos
			dir.z = 0
			dir:Normalize()

			if fwd:Dot(dir) < -0.2 then
				behind[#behind + 1] = center

				if not self:CheckLOS(center + Vector(0, 0, 40), eye) then
					hidden[#hidden + 1] = center
				end
			end
		end
	end

	local pool = #hidden > 0 and hidden or behind
	if #pool == 0 then
		return nil
	end

	return pool[math.random(#pool)]
end
