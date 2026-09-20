local POUNCE_SPD = 2400
local POUNCE_ACCEL = 3600
local POUNCE_GOAL_THRESH = 0
local POUNCE_AHEAD_DIST = 600
local POUNCE_LIFETIME_DUR = 2
local POUNCE_PATH_AGE = 0.1

function ENT:StatePounce()
	self:HandleSpeed(POUNCE_SPD, POUNCE_ACCEL)

	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	self:ComputeRoutingPath(self.Target, POUNCE_AHEAD_DIST, POUNCE_GOAL_THRESH, "Chase")

	local pounceStartTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			-- DO SOMETHING
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		if CurTime() - pounceStartTime > POUNCE_LIFETIME_DUR then
			self:SetState("Wander")
			return
		end

		self:RefreshPathIfStale(POUNCE_PATH_AGE, self.Target, "Chase")

		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end
