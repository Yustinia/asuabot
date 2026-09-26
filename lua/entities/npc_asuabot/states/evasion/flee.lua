local FLEE_SPD = 800
local FLEE_ACCEL = 800
local FLEE_PATH_AGE = 0.2
local FLEE_AHEAD_DIST = 100
local FLEE_GOAL_THRESH = 40
local FLEE_SCAN_RAD = 8000
local FLEE_DAMAGE = 20

ENT.UtilityScores.Flee = function(self, ctx)
	return 0.00
end

ENT.StateEnter.Flee = function(self)
	self:HandleSpeed(FLEE_SPD, FLEE_ACCEL)
	self.GlobalContext.ProgressPosition = self:GetPos()
	self.GlobalContext.ProgressTime = CurTime()

	self.StateContext.Flee = {
		TargetPosition = self:FindFleeSpot(FLEE_SCAN_RAD),
	}
	self:ComputeRoutingPath(self.StateContext.Flee.TargetPosition, FLEE_AHEAD_DIST, FLEE_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Flee = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if not self.GlobalContext.Path or not self.GlobalContext.Path:IsValid() then
		return
	end

	if self:IsAtPosition(self.StateContext.Flee.TargetPosition, FLEE_GOAL_THRESH) then
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, FLEE_DAMAGE)
	end

	if ctx.Visible then
		self.GlobalContext.TargetLastSeenPos = ctx.Target:GetPos()
		self.GlobalContext.TargetLastSeenTime = CurTime()
		self:RecordLastSeenPosition(ctx.Target:GetPos())
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(FLEE_PATH_AGE, self.StateContext.Flee.TargetPosition, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

-- function ENT:StateFlee()
-- 	self:HandleSpeed(FLEE_SPD, FLEE_ACCEL)

-- 	self.Target = self:FindClosestPlayer()
-- 	local targetPos = self:FindFleeSpot(FLEE_SCAN_RAD)

-- 	if not self:ComputeRoutingPath(targetPos, FLEE_AHEAD_DIST, FLEE_GOAL_THRESH, "Follow") then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	while self.Path:IsValid() do
-- 		if self:IsAtPosition(targetPos, FLEE_GOAL_THRESH) then
-- 			return
-- 		end

-- 		if self:HandleStuckCheck() then
-- 			return
-- 		end

-- 		self:RefreshPathIfStale(FLEE_PATH_AGE, targetPos, "Follow")
-- 		self.Path:Update(self)
-- 		self:ClearObstacles()

-- 		coroutine.yield()
-- 	end
-- end
