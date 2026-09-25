-- function ENT:FindHidePosition() end
-- function ENT:FindCoverPosition() end
-- function ENT:FindElevatedPosition() end
-- function ENT:FindPositionBetweenEntities() end
-- function ENT:FindPositionWithLOS() end
-- function ENT:FindPositionWithoutLOS() end
-- function ENT:FindAmbushPosition() end

function ENT:IsAtPosition(pos, tolerance)
	tolerance = tolerance or 60

	return self:GetPos():Distance(pos) <= tolerance
end
