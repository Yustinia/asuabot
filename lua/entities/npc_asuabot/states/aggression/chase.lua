local CHASE_SPD = 800
local CHASE_ACCEL = 800
local CHASE_GOAL_THRESH = 0
local CHASE_AHEAD_DIST = 140
local CHASE_DMG = 20
local CHASE_PATH_AGE = 0.1
local INTERCEPT_INTERVAL = 0.1
local CHASE_LOST_TARGET_DUR = 5
local CHASE_LIFETIME_DUR = 11
local CHASE_COOLDOWN_DUR = 24

ENT.UtilityScores.Chase = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.00
	end

	local distance = Consider(ctx.Distance, 0, 4000, function(x)
		return Curves.PowerInverseIn(x, 2)
	end)
	local memory = Consider(ctx.SeenAge, 0, CHASE_LOST_TARGET_DUR, Curves.LinearOut)
	local speed = Consider(ctx.PlayerSpeed, 0, 1000, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	local chaseTime = (ctx.CurrentState == "Chase") and ctx.StateTime or 0
	local stamina = Consider(chaseTime, 0, CHASE_LIFETIME_DUR, Curves.LinearOut)

	-- debug
	if trace then
		trace.Distance = distance
		trace.Memory = memory
		trace.Speed = speed
		trace.Stamina = stamina
	end
	-- debug

	local score = WeightedGeoMean({
		{ score = distance, weight = 1.20 },
		{ score = memory, weight = 1.00 },
		{ score = speed, weight = 0.7 },
		{ score = stamina, weight = 0.5 },
	})

	return math.max(score, 0.1)
end

ENT.StateEnter.Chase = function(self)
	self:HandleSpeed(CHASE_SPD, CHASE_ACCEL)
	self.GlobalContext.InterceptLastRecompute = 0
	self:ComputeRoutingPath(self.GlobalContext.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Chase = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, CHASE_DMG)
		return
	end

	if CurTime() - self.GlobalContext.InterceptLastRecompute > INTERCEPT_INTERVAL then
		self.GlobalContext.InterceptLastRecompute = CurTime()
		if self:ShouldIntercept(ctx.Target) then
			self:ComputeRoutingPath(self:FindInterceptPoint(ctx.Target), CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Follow")
		else
			self:ComputeRoutingPath(ctx.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")
		end
	else
		self:RefreshPathIfStale(CHASE_PATH_AGE, ctx.Target, "Chase")
	end

	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Chase = function(self)
	local chaseTime = CurTime() - self.GlobalContext.StateStartTime

	local exhausted = chaseTime >= CHASE_LIFETIME_DUR
	if exhausted then
		self.GlobalContext.CooldownUntil["Chase"] = CurTime() + CHASE_COOLDOWN_DUR
	end
end

-- function ENT:StateChase()
-- 	self:HandleSpeed(CHASE_SPD, CHASE_ACCEL)

-- 	self.Target = self:FindClosestPlayer()
-- 	if not IsValid(self.Target) then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	self:ComputeRoutingPath(self.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")

-- 	local chaseStartTime = CurTime()
-- 	local lastPathRecompute = 0

-- 	while IsValid(self.Target) and self.Target:Alive() do
-- 		if self:IsTouchingPlayer(self.Target) then
-- 			self:DamageEntity(self.Target, CHASE_DMG)

-- 			if math.random(1, 2) == 1 then
-- 				self:TeleportToDistantNavSpot()
-- 			end

-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		if self:IsTargetVisible(self.Target) then
-- 			self.TargetLastSeenTime = CurTime()
-- 			self.TargetLastSeenPos = self.Target:GetPos()
-- 			self:RecordLastSeenPosition(self.Target:GetPos())
-- 		elseif CurTime() - self.TargetLastSeenTime > CHASE_LOST_TARGET_DUR then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		if CurTime() - chaseStartTime > CHASE_LIFETIME_DUR then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		if CurTime() - lastPathRecompute > INTERCEPT_INTERVAL then
-- 			lastPathRecompute = CurTime()

-- 			if self:ShouldIntercept(self.Target) then
-- 				local interceptPos = self:FindInterceptPoint(self.Target)
-- 				self:ComputeRoutingPath(interceptPos, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Follow")
-- 			else
-- 				self:ComputeRoutingPath(self.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")
-- 			end
-- 		else
-- 			self:RefreshPathIfStale(CHASE_PATH_AGE, self.Target, "Chase")
-- 		end

-- 		self.Path:Update(self)
-- 		self:ClearObstacles()
-- 		coroutine.yield()
-- 	end
-- end
