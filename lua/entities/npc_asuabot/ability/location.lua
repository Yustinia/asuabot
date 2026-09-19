--- finds a random spot in a scan radius to wander to
--- @param scanRadius number relative to the bot to scan candidate spots
--- @return CNavArea targetArea random point in the candidate area
function ENT:FindWanderSpot(scanRadius)
	scanRadius = scanRadius or 1000

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
	return candidateNavs[math.random(#candidateNavs)]:GetRandomPoint()
end

--- finds a random spot in a scan radius to flee to
--- relative to the player to obtain the farthest distance
--- @param scanRadius number relative to the bot to scan candidate spots
--- @return any bestSpot farthest with the bot's radius relative to the player
function ENT:FindFleeSpot(scanRadius)
	scanRadius = scanRadius or 1000

	local hideSpots = navmesh.Find(self:GetPos(), scanRadius, 20, 50)
	if not hideSpots or #hideSpots == 0 then
		return nil
	end

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
	scanRadius = scanRadius or 1000

	local areas = navmesh.Find(self.Target:GetPos(), scanRadius, 20, 50)
	local targetEye = self.Target:EyePos()

	table.Shuffle(areas)

	for _, area in ipairs(areas) do
		local center = area:GetCenter()
		local tr = util.TraceLine({
			start = center + Vector(0, 0, 64),
			endpos = targetEye,
			mask = MASK_BLOCKLOS,
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
			mask = MASK_BLOCKLOS,
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

	return navs[math.random(#navs)]:GetRandomPoint()
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

	return selectedArea:GetRandomPoint()
end

--- finds the farthest area from the navmesh
---@return unknown farthestArea random point from the navmesh
function ENT:FindFarthestNavSpot()
	local navs = self.CachedNavAreas
	if not navs or #navs == 0 then
		return nil
	end

	local botPos = self:GetPos()
	local farthestArea = navs[1]
	local longestDist = farthestArea:GetCenter():Distance(botPos)

	for i = 1, #navs do
		local area = navs[i]
		local dist = area:GetCenter():Distance(botPos)

		if dist > longestDist then
			longestDist = dist
			farthestArea = area
		end
	end

	return farthestArea:GetRandomPoint()
end

--- finds the closest area from the navmesh
--- @return unknown shortestArea random point from the navmesh
function ENT:FindNearestNavSpot()
	local navs = self.CachedNavAreas
	if not navs or #navs == 0 then
		return nil
	end

	local botPos = self:GetPos()
	local currentArea = navmesh.GetNearestNavArea(botPos)

	local nearestArea = nil
	local shortestDist = math.huge

	for i = 1, #navs do
		local area = navs[i]

		if area ~= currentArea then
			local dist = area:GetCenter():Distance(botPos)

			if dist < shortestDist then
				shortestDist = dist
				nearestArea = area
			end
		end
	end

	if not nearestArea then
		return nil
	end

	return nearestArea:GetRandomPoint()
end

--- finds the closest player regardless of sight
--- @return Player|nil
function ENT:FindClosestPlayer()
	local closest = nil
	local minDist = math.huge
	local myPos = self:GetPos()

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE then
			local distSq = myPos:DistToSqr(ply:GetPos())
			if distSq < minDist then
				minDist = distSq
				closest = ply
			end
		end
	end
	return closest
end
