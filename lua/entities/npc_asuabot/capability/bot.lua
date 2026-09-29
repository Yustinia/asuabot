function ENT:Teleport(vectorPos)
	self:SetPos(vectorPos)
end

--- Plays a sound from the bot's own position.
-- @param soundPath string: sound file path
-- @param volume number|nil: 0-1, defaults to engine default if omitted
-- @param pitch number|nil: 0-255, defaults to 100 if omitted
-- @return nil
function ENT:PlaySound(soundPath, volume, pitch)
	self:EmitSound(soundPath, volume and (volume * 100) or 75, pitch or 100)
end

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

function ENT:PunchEntity(target)
	if CurTime() < (self.GlobalContext.NextPunchTime or 0) then
		return
	end

	if not IsValid(target) then
		return
	end

	target:ViewPunch(
		Angle(
			(math.random(0, 1) == 0) and -30 or 30,
			(math.random(0, 1) == 0) and -60 or 60,
			(math.random(0, 1) == 0) and -45 or 45
		)
	)

	self.GlobalContext.NextPunchTime = CurTime() + 2.0
end
