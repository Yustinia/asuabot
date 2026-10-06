function ENT:GetPlayerPosition(target)
	return target:GetPos()
end

function ENT:GetPlayerDistance(target)
	return self:Distance(target:GetPos())
end

function ENT:GetPlayerOccupiedNavArea(target)
	return navmesh.GetNearestNavArea(target:GetPos())
end

function ENT:GetPlayerDirection(target)
	return target:GetForward()
end

function ENT:IsPlayerBehindBot(target)
	local dirToPlayer = (target:GetPos() - self:GetPos()):GetNormalized()

	return self:GetForward():Dot(dirToPlayer) < 0
end

function ENT:IsPlayerFrontBot(target)
	local dirToPlayer = (target:GetPos() - self:GetPos()):GetNormalized()

	return self:GetForward():Dot(dirToPlayer) > 0
end

function ENT:GetPlayerRelativeVelocity(target)
	return target:GetVelocity() - self:GetVelocity()
end

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
