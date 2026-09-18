function ENT:IsObservedBy(ply)
	if not IsValid(ply) then
		return false
	end
	if not ply:IsLineOfSightClear(self) then
		return false
	end

	local dirToBot = (self:GetPos() - ply:GetPos()):GetNormalized()
	local plyAim = ply:GetAimVector()
	return plyAim:Dot(dirToBot) > 0.5
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
