function ENT:ConfigRoutingPath(minLookAheadDist, goalTolerance)
	self.Path:SetMinLookAheadDistance(minLookAheadDist)
	self.Path:SetGoalTolerance(goalTolerance)
end

function ENT:ComputeRoutingPath(target, minLookAheadDist, goalTolerance, mode)
	if not self.Path then
		if mode == "Follow" then
			self.Path = Path("Follow")
		elseif mode == "Chase" then
			self.Path = Path("Chase")
		end
	end

	self:ConfigRoutingPath(minLookAheadDist, goalTolerance)

	if mode == "Follow" then
		self.Path:Compute(self, target)
	elseif mode == "Chase" then
		self.Path:Chase(self, target)
	end

	if self.Path:IsValid() then
		return self.Path
	end

	return false
end

function ENT:CanReach(pos)
	-- Determines whether the NPC can reach a given position.
end

function ENT:CanNavigateTo(pos)
	-- Determines whether a valid navigation route exists to a position.
end
