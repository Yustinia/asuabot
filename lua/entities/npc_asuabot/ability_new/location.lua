--- finds a random spot in a scan radius to wander to
--- @param scanRadius number relative to the bot to scan candidate spots
--- @return CNavArea targetArea random point in the candidate area
function ENT:FindWanderSpot(scanRadius)
	local navs = self.CachedNavAreas

	if not navs or #navs == 0 then
		return nil
	end

	local myPos = self:GetPos()
	local nearbyNavs = {}

	for i = 1, #navs do
		local area = navs[i]

		if area:GetCenter():Distance(myPos) <= scanRadius then
			table.insert(nearbyNavs, area)
		end
	end

	local candidateNavs = #nearbyNavs > 0 and nearbyNavs or navs

	local targetArea = candidateNavs[math.random(#candidateNavs)]

	return targetArea:GetRandomPoint()
end

--- finds a random spot in a scan radius to flee to
--- relative to the player to obtain the farthest distance
--- @param scanRadius number relative to the bot to scan candidate spots
--- @return any bestSpot farthest with the bot's radius relative to the player
function ENT:FindFleeSpot(scanRadius)
	local hideSpots = navmesh.Find(self:GetPos(), scanRadius, 20, 50)
	local bestSpot = nil
	local maxDist = 0

	for _, area in ipairs(hideSpots) do
		local dist = area:GetCenter():Distance(self.Target:GetPos())
		if dist > maxDist then
			maxDist = dist
			bestSpot = area:GetCenter()
		end
	end

	return bestSpot
end

--- finds a random hiding spot relative to the scan radius of the player
--- @param scanRadius any relative to the player
--- @return unknown hideSpot random hiding spot
function ENT:FindHideSpot(scanRadius)
	local areas = navmesh.Find(self.Target:GetPos(), scanRadius, 20, 50)
	local targetEye = self.Target:EyePos()

	table.Shuffle(areas)

	for _, area in ipairs(areas) do
		local center = area:GetCenter()
		local tr = util.TraceLine({
			start = center + Vector(0, 0, 64),
			endpos = targetEye,
			mask = MASK_OPAQUE,
		})

		if tr.Hit and tr.Fraction < 1.0 then
			return center
		end
	end

	return nil
end

--- finds the closest hiding spot relative to the scan radius of the player
---@param scanRadius any relative to the player
---@return unknown closestSpot hiding spot closest to the player
function ENT:FindClosestHideSpot(scanRadius)
	local areas = navmesh.Find(self.Target:GetPos(), scanRadius, 20, 50)
	local targetEye = self.Target:EyePos()

	local closestSpot = nil
	local closestDist = math.huge

	for _, area in ipairs(areas) do
		local center = area:GetCenter()

		local tr = util.TraceLine({
			start = center + Vector(0, 0, 64),
			endpos = targetEye,
			mask = MASK_OPAQUE,
		})

		if tr.Hit and tr.Fraction < 1.0 then
			local dist = center:Distance(self.Target:GetPos())

			if dist < closestDist then
				closestDist = dist
				closestSpot = center
			end
		end
	end

	return closestSpot
end

--- finds a random point in the entire navmesh
--- @return unknown randomArea randomly selected point in a navmesh
function ENT:FindRandomNavSpot()
	local navs = self.CachedNavAreas

	if not navs or #navs == 0 then
		return nil
	end

	local randomArea = navs[math.random(#navs)]

	if IsValid(randomArea) then
		return randomArea:GetRandomPoint()
	end

	return nil
end

--- finds the farthest point away from the player with a minimum distance
--- relative to the navmesh center
--- @param minDistance any minimum distance away from the player and center
--- @return unknown selectedArea random point from the navmesh
function ENT:FindDistantFromPlayerSpot(minDistance)
	local navs = self.CachedNavAreas

	if not navs or #navs == 0 then
		return nil
	end

	local validSpots = {}

	for i = 1, #navs do
		local area = navs[i]
		local spot = area:GetCenter()
		local isFarEnough = true

		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() then
				if spot:Distance(ply:GetPos()) < minDistance then
					isFarEnough = false
					break
				end
			end
		end

		if isFarEnough then
			table.insert(validSpots, area)
		end
	end

	local selectedArea = (#validSpots > 0) and validSpots[math.random(#validSpots)] or navs[math.random(#navs)]

	if IsValid(selectedArea) then
		return selectedArea:GetRandomPoint()
	end

	return nil
end

--- finds the farthest area from the navmesh
---@return unknown farthestArea random point from the navmesh
function ENT:FindFarthestNavSpot()
	local navs = self.CachedNavAreas

	if not navs or #navs == 0 then
		return nil
	end

	local botPos = self:GetPos()
	local farthestArea = nil
	local longestDist = 0

	for i = 1, #navs do
		local area = navs[i]

		if IsValid(area) then
			local dist = area:GetCenter():Distance(botPos)

			if dist > longestDist then
				longestDist = dist
				farthestArea = area
			end
		end
	end

	if IsValid(farthestArea) then
		return farthestArea:GetRandomPoint()
	end

	return nil
end

--- finds the closest area from the navmesh
--- @return unknown shortestArea random point from the navmesh
function ENT:FindNearestNavSpot()
	local navs = self.CachedNavAreas

	if not navs or #navs == 0 then
		return nil
	end

	local botPos = self:GetPos()
	local nearestArea = nil
	local shortestDist = math.huge

	for i = 1, #navs do
		local area = navs[i]

		if IsValid(area) then
			local dist = area:GetCenter():Distance(botPos)

			if dist < shortestDist then
				shortestDist = dist
				nearestArea = area
			end
		end
	end

	if IsValid(nearestArea) then
		return nearestArea:GetRandomPoint()
	end

	return nil
end

--- finds the closest path length from the navmesh
--- @return unknown shortestPath random point from the closest path
function ENT:FindNearestReachableSpot()
	local navs = self.CachedNavAreas

	if not navs or #navs == 0 then
		return nil
	end

	local botPos = self:GetPos()
	local nearestArea = nil
	local shortestPathLen = math.huge

	for i = 1, #navs do
		local area = navs[i]

		if IsValid(area) then
			local areaCenter = area:GetCenter()

			local pathLen = navmesh.GetPathDistance(botPos, areaCenter)

			if pathLen and pathLen > 0 and pathLen < shortestPathLen then
				shortestPathLen = pathLen
				nearestArea = area
			end
		end
	end

	if IsValid(nearestArea) then
		return nearestArea:GetRandomPoint()
	end

	return nil
end

--- finds a random position that provides line-of-sight cover from the current target.
---
--- if scanRadius is provided, it dynamically searches for navigation areas
--- within that distance around the bot. If omitted, it evaluates all cached
--- navigation areas on the map.
---
--- @param scanRadius number Optional maximum radius around the bot to search for cover areas.
--- @return unknown coverSpot a 3D position vector for a valid cover spot, or nil if no target exists or no cover spot is found.
function ENT:FindCoverSpot(scanRadius)
	local navs = nil

	if scanRadius then
		navs = navmesh.Find(self:GetPos(), scanRadius, 20, 50)
	else
		navs = self.CachedNavAreas
	end

	if not navs or #navs == 0 then
		return nil
	end

	local targetEye = self.Target:EyePos()
	local validCoverSpots = {}

	for i = 1, #navs do
		local area = navs[i]
		if IsValid(area) then
			local center = area:GetCenter()

			local tr = util.TraceLine({
				start = center + Vector(0, 0, 64),
				endpos = targetEye,
				mask = MASK_OPAQUE,
			})

			if tr.Hit and tr.Fraction < 1.0 then
				table.insert(validCoverSpots, center)
			end
		end
	end

	if #validCoverSpots > 0 then
		return validCoverSpots[math.random(#validCoverSpots)]
	end

	return nil
end

--- finds the farthest route away from the player
--- @param scanRadius any if provided, will choose an area within the scan radius; otherwise, when omitted will use the entire navmesh
--- @return unknown escapeRoute
function ENT:FindEscapeSpot(scanRadius)
	local navs = nil

	if scanRadius then
		navs = navmesh.Find(self:GetPos(), scanRadius, 20, 50)
	else
		navs = self.CachedNavAreas
	end

	if not navs or #navs == 0 then
		return nil
	end

	local targetPos = self.Target:GetPos()
	local bestSpot = nil
	local maxPathDist = 0

	for i = 1, #navs do
		local area = navs[i]
		if IsValid(area) then
			local center = area:GetCenter()
			local pathLen = navmesh.GetPathDistance(targetPos, center)

			if pathLen and pathLen > maxPathDist then
				maxPathDist = pathLen
				bestSpot = center
			end
		end
	end

	return bestSpot
end

--- Finds a hidden spot close to the target to wait for an element of surprise.
---
--- Searches navigation areas near the target, filtering for positions that block
--- line-of-sight while selecting the one closest to the target.
--- @param scanRadius number|nil Radius around the target to search (default 1000).
--- @return Vector|nil Vector position of the ambush spot, or nil if none found.
function ENT:FindAmbushSpot(scanRadius)
	scanRadius = scanRadius or 1000

	local targetPos = self.Target:GetPos()
	local targetEye = self.Target:EyePos()

	local navs = navmesh.Find(targetPos, scanRadius, 20, 50)
	if not navs or #navs == 0 then
		return nil
	end

	local bestSpot = nil
	local shortestDist = math.huge

	for i = 1, #navs do
		local area = navs[i]
		if IsValid(area) then
			local center = area:GetCenter()

			local tr = util.TraceLine({
				start = center + Vector(0, 0, 64),
				endpos = targetEye,
				mask = MASK_OPAQUE,
			})

			if tr.Hit and tr.Fraction < 1.0 then
				local dist = center:Distance(targetPos)
				if dist < shortestDist then
					shortestDist = dist
					bestSpot = center
				end
			end
		end
	end

	return bestSpot
end

--- return the last and most recent player position
--- @return targetLastPosition
function ENT:FindInvestigateSpot()
	if not self.TargetLastSeenPos then
		return nil
	end

	return self.TargetLastSeenPos
end

--- returns various positions the player reached
--- @return targetLastOldPosition
function ENT:FindPatrolSpot()
	if #self.LastSeenTargetPositions < 5 then
		return nil
	end

	self.PatrolIndex = (self.PatrolIndex or 0) + 1

	if self.PatrolIndex > #self.LastSeenTargetPositions then
		return nil
	end

	return self.LastSeenTargetPositions[self.PatrolIndex]
end

--- Finds a position behind or to the side of a target outside their field of view.
---
--- @param target Entity|nil Target entity (defaults to self.Target).
--- @return Vector|nil Flanking position, or nil if none found.
function ENT:FindFlankSpot(distance)
	local targetPos = self.Target:GetPos()
	local targetForward = self.Target:GetForward()

	local navs = navmesh.Find(targetPos, distance, 20, 50)
	if not navs or #navs == 0 then
		return nil
	end

	local validFlankSpots = {}

	for i = 1, #navs do
		local area = navs[i]
		if IsValid(area) then
			local center = area:GetCenter()
			local dirToSpot = (center - targetPos):GetNormalized()

			local dot = targetForward:Dot(dirToSpot)

			if dot <= 0.3 then
				table.insert(validFlankSpots, center)
			end
		end
	end

	if #validFlankSpots > 0 then
		return validFlankSpots[math.random(#validFlankSpots)]
	end

	return nil
end

--- Finds a navigation position within a min/max distance ring around a target.
---
--- @param minDist number Minimum distance constraint.
--- @param maxDist number Maximum distance constraint.
--- @return Vector|nil Random position inside the ring, or nil if none found.
function ENT:FindPointNearTarget(minDist, maxDist)
	local targetPos = self.Target:GetPos()

	local navs = navmesh.Find(targetPos, maxDist, 20, 50)
	if not navs or #navs == 0 then
		return nil
	end

	local validSpots = {}

	for i = 1, #navs do
		local area = navs[i]
		if IsValid(area) then
			local center = area:GetCenter()
			local dist = center:Distance(targetPos)

			if dist >= minDist and dist <= maxDist then
				table.insert(validSpots, center)
			end
		end
	end

	if #validSpots > 0 then
		return validSpots[math.random(#validSpots)]
	end

	return nil
end

--- Finds a position at roughly the specified distance away from a target.
---
--- @param distance number Desired distance to step away.
--- @return Vector|nil Position at the specified distance away, or nil.
function ENT:FindPointAwayFromTarget(distance)
	local targetPos = self.Target:GetPos()

	local awayDir = (self:GetPos() - targetPos):GetNormalized()
	local idealPos = targetPos + (awayDir * distance)

	local nearestArea = navmesh.GetNearestNavArea(idealPos)
	if IsValid(nearestArea) then
		return nearestArea:GetClosestPointOnArea(idealPos)
	end

	return nil
end

--- Calculates a position along the line segment between two points offset by a given distance.
---
--- @param posA Vector Starting origin point.
--- @param posB Vector Destination point facing direction.
--- @param distance number Units to travel from posA towards posB.
--- @return Vector|nil Closest navmesh position near the calculated point, or nil.
function ENT:FindPointBetween(posA, posB, distance)
	local dir = (posB - posA):GetNormalized()
	local calculatedPos = posA + (dir * distance)

	local nearestArea = navmesh.GetNearestNavArea(calculatedPos)
	if IsValid(nearestArea) then
		return nearestArea:GetClosestPointOnArea(calculatedPos)
	end

	return calculatedPos
end
