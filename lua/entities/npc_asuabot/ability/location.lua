function ENT:FindFleeSpot(target)
	local radiusDist = 2000

	local hideSpots = navmesh.Find(self:GetPos(), radiusDist, 100, 20)
	local bestSpot = nil
	local maxDist = 0

	for _, area in ipairs(hideSpots) do
		local dist = area:GetCenter():DistToSqr(target:GetPos())
		if dist > maxDist then
			maxDist = dist
			bestSpot = area:GetCenter()
		end
	end

	return bestSpot
end

function ENT:FindHidingSpot(target)
	local areas = navmesh.Find(target:GetPos(), 1500, 100, 20)
	local targetEye = target:EyePos()

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

function ENT:FindClosestHidingSpot(target)
	local areas = navmesh.Find(target:GetPos(), 1500, 100, 20)
	local targetEye = target:EyePos()

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
			local dist = center:Distance(target:GetPos())

			if dist < closestDist then
				closestDist = dist
				closestSpot = center
			end
		end
	end

	return closestSpot
end

function ENT:GetClosestPlayer()
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
