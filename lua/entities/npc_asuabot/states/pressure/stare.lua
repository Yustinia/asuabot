local STARE_SPAWN_DIST = 700
local STARE_LIFETIME_DIR = 15
local STARE_HALF_ANGLE = 20
local STARE_DIRECT_DOT = math.cos(math.rad(STARE_HALF_ANGLE))
local STARE_LIFT = Vector(0, 0, 10)

function ENT:StateStare()
	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	local spawnSpot = self:FindRearSpot(STARE_SPAWN_DIST)
	if not spawnSpot then
		self:SetState("Wander")
		return
	end

	self:SetPos(spawnSpot + STARE_LIFT)
	coroutine.wait(0.2)

	self:HandleSpeed(0, 0)

	local stareStartTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsObservedBy(self.Target, STARE_DIRECT_DOT) and self:IsTargetVisible(self.Target) then
			self:SetState("Pounce")
			return
		end

		if CurTime() - stareStartTime > STARE_LIFETIME_DIR then
			self:SetState("Wander")
			return
		end

		coroutine.yield()
	end
end
