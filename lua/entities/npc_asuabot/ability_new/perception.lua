--- checks whether the bot is observed by a given entity player
--- @param entity any
--- @return boolean
function ENT:IsObservedBy(entity)
	if not IsValid(entity) then
		return false
	end

	if not entity:IsLineOfSightClear(self) then
		return false
	end

	local dirToBot = (self:GetPos() - entity:GetPos()):GetNormalized()
	local entityForward = entity:GetForward()

	return entityForward:Dot(dirToBot) > 0.5
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

--- gets the closest visible player considering direct line of sight
--- @return Player|nil
function ENT:GetClosestVisiblePlayer()
	local closest = nil
	local minDist = math.huge
	local myPos = self:GetPos()

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE and self:IsLineOfSightClear(ply) then
			local distSq = myPos:DistToSqr(ply:GetPos())
			if distSq < minDist then
				minDist = distSq
				closest = ply
			end
		end
	end
	return closest
end

function ENT:RecordLastSeenPosition(pos)
	if CurTime() - self.LastSeenRecordTime < self.LastSeenRecordInterval then
		return
	end

	table.insert(self.LastSeenTargetPositions, 1, pos)

	if #self.LastSeenTargetPositions > self.LastSeenTargetSize then
		table.remove(self.LastSeenTargetPositions)
	end

	self.LastSeenRecordTime = CurTime()
end
