function ENT:Teleport(vectorPos)
	self:SetPos(vectorPos)
end
-- function ENT:PlaySound() end
-- function ENT:SetCollisionState() end

function ENT:SetAccel(accel)
	self.loco:SetAcceleration(accel)
end

function ENT:SetSpeed(speed)
	self.loco:SetDesiredSpeed(speed)
end

function ENT:HandleSpeed(speed, accel)
	speed = speed or 200
	accel = accel or 400

	self:SetSpeed(speed)
	self:SetAccel(accel)
end
