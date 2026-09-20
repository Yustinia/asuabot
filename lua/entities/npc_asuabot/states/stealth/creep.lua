local CREEP_SPD = 150
local CREEP_ACCEL = 300
local CREEP_GOAL_THRESH = 120
local CREEP_PATH_AGE = 0.2
local CREEP_AHEAD_DIST = 70
local CREEP_LIFETIME_DUR = 20

function ENT:StateCreep()
	self:HandleSpeed(CREEP_SPD, CREEP_ACCEL)

	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	self:ComputeRoutingPath(self.Target, CREEP_AHEAD_DIST, CREEP_GOAL_THRESH, "Chase")

	local creepStartTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			-- DO SOMETHING
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		if CurTime() - creepStartTime > CREEP_LIFETIME_DUR then
			self:SetState("Wander")
			return
		end

		self:RefreshPathIfStale(CREEP_PATH_AGE, self.Target, "Chase")
		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end
