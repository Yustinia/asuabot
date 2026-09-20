local CHASE_SPD = 600
local CHASE_ACCEL = 300
local CHASE_GOAL_THRESH = 0
local CHASE_AHEAD_DIST = 140
local CHASE_DMG = 20
local CHASE_LIFETIME_DUR = 12
local CHASE_PATH_AGE = 0.1
local CHASE_LOST_TARGET_DUR = 5
local INTERCEPT_INTERVAL = 0.1

function ENT:StateChase()
	self:HandleSpeed(CHASE_SPD, CHASE_ACCEL)

	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	self:ComputeRoutingPath(self.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")

	local chaseStartTime = CurTime()
	local lastPathRecompute = 0

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			self:DamageEntity(self.Target, CHASE_DMG)

			if math.random(1, 2) == 1 then
				self:TeleportToDistantNavSpot()
			end

			self:SetState("Wander")
			return
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		elseif CurTime() - self.TargetLastSeenTime > CHASE_LOST_TARGET_DUR then
			self:SetState("Wander")
			return
		end

		if CurTime() - chaseStartTime > CHASE_LIFETIME_DUR then
			self:SetState("Wander")
			return
		end

		if CurTime() - lastPathRecompute > INTERCEPT_INTERVAL then
			lastPathRecompute = CurTime()

			if self:ShouldIntercept(self.Target) then
				local interceptPos = self:FindInterceptPoint(self.Target)
				self:ComputeRoutingPath(interceptPos, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Follow")
			else
				self:ComputeRoutingPath(self.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")
			end
		else
			self:RefreshPathIfStale(CHASE_PATH_AGE, self.Target, "Chase")
		end

		self.Path:Update(self)
		self.Path:Draw()
		self:ClearObstacles()
		coroutine.yield()
	end
end
