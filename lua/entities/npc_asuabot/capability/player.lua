function ENT:FindNearestPlayer()
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

--- Finds all players within a given radius of a position.
-- @param pos Vector: center point
-- @param radius number: search radius
-- @return table: list of Player entities within range
function ENT:FindPlayersInRad(pos, radius)
	local found = {}

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and ply:GetPos():Distance(pos) <= radius then
			table.insert(found, ply)
		end
	end

	return found
end
