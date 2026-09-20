local WANDER_SPD = 500
local WANDER_ACCEL = 500
local WANDER_GOAL_THRESH = 120
local WANDER_SCAN_RAD = 2000
local WANDER_RETRY_WAIT = 1
local WANDER_PATH_AGE = 0.08
local WANDER_AHEAD_DIST = 150

function ENT:StateWander()
	self:HandleSpeed(WANDER_SPD, WANDER_ACCEL)

	self.Target = self:FindClosestPlayer()
	local targetPos = self:FindWanderSpot(WANDER_SCAN_RAD)

	if not self:ComputeRoutingPath(targetPos, WANDER_AHEAD_DIST, WANDER_GOAL_THRESH, "Follow") then
		coroutine.wait(WANDER_RETRY_WAIT)
		return
	end

	while self.Path:IsValid() do
		if self:IsAtPosition(targetPos, WANDER_GOAL_THRESH) then
			self:SetState("Wander")
			return
		end

		if self:IsTouchingPlayer(self.Target) then
			self:DamageEntity(self.Target, 1)
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		if self:CheckProgress() then
			self:HandleStuck()

			if self.StuckTries >= self.StuckMax then
				self:SetState("Wander")
				return
			end
		end

		self:RefreshPathIfStale(WANDER_PATH_AGE, targetPos, "Follow")

		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end
