local CHASE_SPD = 800
local CHASE_ACCEL = 800
local CHASE_GOAL_THRESH = 0
local CHASE_AHEAD_DIST = 140
local CHASE_DMG = 20
local CHASE_PATH_AGE = 0.1
local CHASE_LOST_TARGET_DUR = 5
local CHASE_LIFETIME_DUR = 12
local CHASE_COOLDOWN_DUR = 30

ENT.UtilityScores.Chase = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.0
	end

	local distance = Consider(ctx.Distance, 0, 2000, Curves.LinearInverse)

	local memory = Consider(ctx.LastSeenAge, 0, CHASE_LOST_TARGET_DUR, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	local chaseTime = (ctx.CurrentState == "Chase") and ctx.StateTime or 0
	local stamina = Consider(chaseTime, 0, CHASE_LIFETIME_DUR, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	if trace then
		trace.Distance = distance
		trace.Memory = memory
		trace.Stamina = stamina
	end

	return WeightedGeoMean({
		{ score = distance, weight = 1 },
		{ score = memory, weight = 1.2 },
		{ score = stamina, weight = 0.8 },
	})
end

ENT.StateEnter.Chase = function(self)
	self:HandleSpeed(CHASE_SPD, CHASE_ACCEL)
	self:ComputeRoutingPath(self.GlobalContext.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Chase = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, CHASE_DMG)
		self:PunchEntity(ctx.Target)
	end

	self:RefreshPathIfStale(CHASE_PATH_AGE, ctx.Target, "Chase")
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
