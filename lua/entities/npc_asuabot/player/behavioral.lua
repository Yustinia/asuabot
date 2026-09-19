function ENT:IsPlayerStationary(speedThresh)
	if not IsValid(self.Target) then
		return false
	end

	speedThresh = speedThresh or 10

	return self.Target:GetVelocity():Length2D() <= speedThresh
end
function ENT:IsPlayerApproaching()
	if not IsValid(self.Target) then
		return false
	end

	local direction = self:GetPlayerDirection()
	local relativeVel = self:GetPlayerRelativeVelocity()

	if not direction or not relativeVel then
		return false
	end

	return relativeVel:Dot(direction) < 0
end

function ENT:IsPlayerRetreating()
	if not IsValid(self.Target) then
		return false
	end

	local direction = self:GetPlayerDirection()
	local relativeVelocity = self:GetPlayerRelativeVelocity()

	if not direction or not relativeVelocity then
		return false
	end

	return relativeVelocity:Dot(direction) > 0
end

-- function ENT:IsPlayerStrafing() end
-- function ENT:IsPlayerCirclingBot() end

function ENT:GetPlayerApproachSpeed()
	local dir = self:GetPlayerDirection()
	local rel = self:GetPlayerRelativeVelocity()
	if not dir and not rel then
		return false
	end

	return -rel:Dot(dir)
end
-- function ENT:GetPlayerRecentPathDirection() end

-- function ENT:HasPlayerRecentlyChangedDirection() end
