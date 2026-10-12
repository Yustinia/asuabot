function ENT:Teleport(vectorPos)
	self:SetPos(vectorPos)
	self.loco:SetVelocity(Vector(0, 0, 0))
	self.loco:ClearStuck()

	-- reset progress position since it's far
	self.GlobalContext.ProgressPosition = nil
end

--- Re-emits a sound each time its length elapses.
-- @param ent Entity: emitter (the bot or the player)
-- @param key string: unique key for this loop
-- @param name string: registered sound name
-- @param file string: the file path, used only to read its length
function ENT:EmitLoop(ent, key, name, file)
	local sc = self.StateContext
	sc.LoopNext = sc.LoopNext or {}

	if CurTime() < (sc.LoopNext[key] or 0) then
		return
	end

	sc.LoopNext[key] = CurTime() + SoundDuration(file) - 0.05
	ent:EmitSound(name)
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
