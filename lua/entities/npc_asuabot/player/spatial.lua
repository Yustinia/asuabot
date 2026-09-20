function ENT:IsTouchingPlayer(target, distanceThreshold)
	if not IsValid(target) or not target:IsPlayer() or not target:Alive() then
		return false
	end

	distanceThreshold = distanceThreshold or 60

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

--- checks whether the bot is observed by a given entity player
--- @param entity any
--- @return boolean
function ENT:IsObservedBy(entity, threshold)
	threshold = threshold or 0.5

	if not IsValid(entity) then
		return false
	end

	if not entity:IsLineOfSightClear(self) then
		return false
	end

	local dirToBot = (self:GetPos() - entity:GetPos()):GetNormalized()
	local entityForward = entity:GetForward()

	return entityForward:Dot(dirToBot) > threshold
end

--- checks if the player is visible to the bot
--- @param target any
--- @return boolean
function ENT:IsTargetVisible(target)
	if not IsValid(target) then
		return false
	end

	return self:IsLineOfSightClear(target)
end

--- checks if the player can be seen while considering FOV and range
--- @param target any
--- @return boolean
function ENT:CanSee(target)
	if not IsValid(target) then
		return false
	end

	local dist = self:GetPos():Distance(target:GetPos())
	if dist > self:GetMaxVisionRange() then
		return false
	end

	return self:IsLineOfSightClear(target)
end

function ENT:RecordLastSeenPosition(pos)
	-- PrintMessage(HUD_PRINTTALK, "RealTime: " .. tostring(self.TargetLastSeenPos))
	-- for i = 1, #self.LastSeenTargetPositions do
	-- 	PrintMessage(HUD_PRINTTALK, "[" .. i .. "]: " .. tostring(self.LastSeenTargetPositions[i]))
	-- end

	if CurTime() - self.LastSeenRecordTime < self.LastSeenRecordInterval then
		return
	end

	local lastPos = self.LastSeenTargetPositions[1]
	if lastPos and lastPos:Distance(pos) < self.LastSeenRecordMinDist then
		return
	end

	table.insert(self.LastSeenTargetPositions, 1, pos)

	if #self.LastSeenTargetPositions > self.LastSeenTargetSize then
		table.remove(self.LastSeenTargetPositions)
	end

	self.LastSeenRecordTime = CurTime()
end

function ENT:GetPlayerPosition()
	if not IsValid(self.Target) then
		return nil
	end

	return self.Target:GetPos()
end

function ENT:GetPlayerDistance()
	if not IsValid(self.Target) then
		return nil
	end

	return self:GetPos():Distance(self.Target:GetPos())
end

function ENT:GetPlayerDirection()
	if not IsValid(self.Target) then
		return nil
	end

	local d = self.Target:GetPos() - self:GetPos()
	d.z = 0

	if d:Length() < 1 then
		return false
	end

	return d:GetNormalized()
end

function ENT:GetPlayerRelativeVelocity()
	if not IsValid(self.Target) then
		return nil
	end

	return self.Target:GetVelocity() - self:GetVelocity()
end
