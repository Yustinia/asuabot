local WANDER_SPD = 500
local WANDER_ACCEL = 500
local WANDER_GOAL_THRESH = 120
local WANDER_SCAN_RAD = 2000
-- local WANDER_RETRY_WAIT = 1
local WANDER_PATH_AGE = 0.08
local WANDER_AHEAD_DIST = 150
local WANDER_LIFETIME_DUR = 20

ENT.UtilityScores.Wander = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 1.0
	end

	local notVisible = ctx.Visible and 0 or 1
	local far = Consider(ctx.Distance, 0, 2000, Curves.LinearIn)

	local wanderTime = (ctx.CurrentState == "Wander") and ctx.StateTime or 0 -- NEW
	local stamina = Consider(wanderTime, 0, WANDER_LIFETIME_DUR, function(x)
		return Curves.PowerInverseIn(x, 3)
	end) -- NEW

	if trace then
		trace.NotVisible = notVisible
		trace.Far = far
		trace.Stamina = stamina
	end

	local score = WeightedGeoMean({
		{ score = notVisible, weight = 1 },
		{ score = far, weight = 0.5 },
		{ score = stamina, weight = 1 },
	})

	return math.max(score, 0.1)
end

ENT.StateEnter.Wander = function(self)
	self:HandleSpeed(WANDER_SPD, WANDER_ACCEL)

	self.GlobalContext.ProgressPosition = self:GetPos()
	self.GlobalContext.ProgressTime = CurTime()

	self.StateContext.Wander = {
		TargetPosition = self:FindWanderSpot(WANDER_SCAN_RAD),
	}
	self:ComputeRoutingPath(self.StateContext.Wander.TargetPosition, WANDER_AHEAD_DIST, WANDER_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Wander = function(self, ctx)
	if not self.GlobalContext.Path or not self.GlobalContext.Path:IsValid() then
		return
	end

	if self:IsAtPosition(self.StateContext.Wander.TargetPosition, WANDER_GOAL_THRESH) then
		self.StateContext.Wander.TargetPosition = self:FindWanderSpot(WANDER_SCAN_RAD)
		self:ComputeRoutingPath(
			self.StateContext.Wander.TargetPosition,
			WANDER_AHEAD_DIST,
			WANDER_GOAL_THRESH,
			"Follow"
		)
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, 1)
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(WANDER_PATH_AGE, self.StateContext.Wander.TargetPosition, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

-- function ENT:StateWander()
-- 	self:HandleSpeed(WANDER_SPD, WANDER_ACCEL)

-- 	self.Target = self:FindClosestPlayer()
-- 	local targetPos = self:FindWanderSpot(WANDER_SCAN_RAD)

-- 	if not self:ComputeRoutingPath(targetPos, WANDER_AHEAD_DIST, WANDER_GOAL_THRESH, "Follow") then
-- 		coroutine.wait(WANDER_RETRY_WAIT)
-- 		return
-- 	end

-- 	while self.Path:IsValid() do
-- 		if self:IsAtPosition(targetPos, WANDER_GOAL_THRESH) then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		if self:IsTouchingPlayer(self.Target) then
-- 			self:DamageEntity(self.Target, 1)
-- 		end

-- 		if self:IsTargetVisible(self.Target) then
-- 			self.TargetLastSeenPos = self.Target:GetPos()
-- 			self:RecordLastSeenPosition(self.Target:GetPos())
-- 		end

-- 		if self:HandleStuckCheck() then
-- 			return
-- 		end

-- 		self:RefreshPathIfStale(WANDER_PATH_AGE, targetPos, "Follow")

-- 		self.Path:Update(self)
-- 		self:ClearObstacles()
-- 		coroutine.yield()
-- 	end
-- end
