local POUNCE_SPD = 2400
local POUNCE_ACCEL = 3600
local POUNCE_GOAL_THRESH = 0
local POUNCE_AHEAD_DIST = 600
local POUNCE_DAMAGE = 100
local POUNCE_LIFETIME_DUR = 4
local POUNCE_PATH_AGE = 0.1
local POUNCE_COOLDOWN_DUR = 120
local POUNCE_MIN_DIST = 800
local POUNCE_MAX_DIST = 2500

ENT.UtilityScores.Pounce = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.0
	end

	local pounce = self.StateContext.Pounce
	if ctx.CurrentState == "Pounce" and pounce and CurTime() < pounce.LockedUntil then
		return 1.0
	end

	if not ctx.Visible then
		return 0.0
	end
	if ctx.Distance < POUNCE_MIN_DIST then
		return 0.0
	end
	if ctx.Distance > POUNCE_MAX_DIST then
		return 0.0
	end

	local far = Consider(ctx.Distance, POUNCE_MIN_DIST, POUNCE_MAX_DIST, Curves.LinearIn)

	if trace then
		trace.Far = far
	end

	return far
end

ENT.StateEnter.Pounce = function(self)
	self:HandleSpeed(POUNCE_SPD, POUNCE_ACCEL)
	self.GlobalContext.TargetLastSeenTime = CurTime()
	self:ComputeRoutingPath(self.GlobalContext.Target, POUNCE_AHEAD_DIST, POUNCE_GOAL_THRESH, "Chase")

	self.StateContext.Pounce = {
		LockedUntil = CurTime() + POUNCE_LIFETIME_DUR,
	}
end

ENT.StateUpdate.Pounce = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, POUNCE_DAMAGE)
		return
	end

	if ctx.Visible then
		self.GlobalContext.TargetLastSeenTime = CurTime()
		self.GlobalContext.TargetLastSeenPos = ctx.Target:GetPos()
		self:RecordLastSeenPosition(ctx.Target:GetPos())
	end

	self:RefreshPathIfStale(POUNCE_PATH_AGE, ctx.Target, "Chase")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Pounce = function(self)
	self.GlobalContext.CooldownUntil["Pounce"] = CurTime() + POUNCE_COOLDOWN_DUR
end

-- function ENT:StatePounce()
-- 	self:HandleSpeed(POUNCE_SPD, POUNCE_ACCEL)

-- 	self.Target = self:FindClosestPlayer()
-- 	if not IsValid(self.Target) then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	self:ComputeRoutingPath(self.Target, POUNCE_AHEAD_DIST, POUNCE_GOAL_THRESH, "Chase")

-- 	local pounceStartTime = CurTime()

-- 	while IsValid(self.Target) and self.Target:Alive() do
-- 		if self:IsTouchingPlayer(self.Target) then
-- 			-- DO SOMETHING
-- 		end

-- 		if self:IsTargetVisible(self.Target) then
-- 			self.TargetLastSeenPos = self.Target:GetPos()
-- 			self:RecordLastSeenPosition(self.Target:GetPos())
-- 		end

-- 		if CurTime() - pounceStartTime > POUNCE_LIFETIME_DUR then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		self:RefreshPathIfStale(POUNCE_PATH_AGE, self.Target, "Chase")

-- 		self.Path:Update(self)
-- 		self:ClearObstacles()
-- 		coroutine.yield()
-- 	end
-- end
