--- return boolean whether the entity is within tolerated distance
--- @param pos any
--- @param tolerance any
--- @return boolean
function ENT:IsAtPosition(pos, tolerance)
	tolerance = tolerance or 60

	return self:GetPos():Distance(pos) <= tolerance
end

function ENT:GetMovementDirection()
	return self.loco:GetGroundMotionVector()
end

function ENT:IsMoving()
	return self.loco:IsAttemptingToMove()
end
