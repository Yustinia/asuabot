function ENT:GetPlayerPosition()
	return self.GlobalContext.Target:GetPos()
end

function ENT:GetPlayerDistance()
	return self:Distance(self.GlobalContext.Target:GetPos())
end

function ENT:GetPlayerOccupiedNavArea()
	return navmesh.GetNearestNavArea(self.Target:GetPos())
end

-- function ENT:GetPlayerDirection()
-- function ENT:IsPlayerAboveBot()
-- function ENT:IsPlayerBelowBot()
-- function ENT:IsPlayerOnHighGround()
-- function ENT:IsPlayerOnLowGround()
-- function ENT:IsPlayerBehindBot()
-- function ENT:IsPlayerFrontBot()
-- function ENT:GetPlayerRelativeVelocity()

function ENT:IsTouchingPlayer(target, distanceThreshold)
	if not IsValid(target) or not target:IsPlayer() or not target:Alive() then
		return false
	end

	distanceThreshold = distanceThreshold or 30

	local dist = self:GetPos():Distance(target:GetPos())
	if dist <= distanceThreshold then
		return true
	end

	local botTorso = self:GetPos() + Vector(0, 0, 36)
	local plyTorso = target:GetPos() + Vector(0, 0, 36)

	local tr = util.TraceHull({
		start = botTorso,
		endpos = plyTorso,
		mins = Vector(-10, -10, -10),
		maxs = Vector(10, 10, 10),
		filter = self,
	})

	return tr.Hit and tr.Entity == target and botTorso:Distance(plyTorso) <= (distanceThreshold + 20)
end

function ENT:RecordLastSeenPosition(pos)
	if CurTime() - self.GlobalContext.LastSeenRecordTime < self.GlobalContext.LastSeenRecordInterval then
		return
	end

	local lastPos = self.GlobalContext.LastSeenTargetPositions[1]
	if lastPos and lastPos:Distance(pos) < self.GlobalContext.LastSeenRecordMinDist then
		return
	end

	table.insert(self.GlobalContext.LastSeenTargetPositions, 1, pos)

	if #self.GlobalContext.LastSeenTargetPositions > self.GlobalContext.LastSeenTargetSize then
		table.remove(self.GlobalContext.LastSeenTargetPositions)
	end

	self.GlobalContext.LastSeenRecordTime = CurTime()
end
