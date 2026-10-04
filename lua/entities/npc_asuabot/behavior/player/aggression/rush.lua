local RUSH_SPD = 2000
local RUSH_ACCEL = 2000
local RUSH_GOAL_THRESH = 0
local RUSH_AHEAD_DIST = 0
local RUSH_DMG = 20
local RUSH_PATH_AGE = 0.1
local RUSH_LIFETIME_DUR = 10
local RUSH_COOLDOWN_DUR = 30

ENT.UtilityScores.Rush = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.0
	end

	local distance = Consider(ctx.Distance, 0, 4000, Curves.LinearInverse)

	local rushTime = (ctx.CurrentState == "Rush") and ctx.StateTime or 0
	local stamina = Consider(rushTime, 0, RUSH_LIFETIME_DUR, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	if trace then
		trace.Distance = distance
		trace.Stamina = stamina
	end

	return WeightedGeoMean({
		{ score = distance, weight = 1 },
		{ score = stamina, weight = 1 },
	})
end

ENT.StateEnter.Rush = function(self)
	self:HandleSpeed(RUSH_SPD, RUSH_ACCEL)
	self:ComputeRoutingPath(self.GlobalContext.Target, RUSH_AHEAD_DIST, RUSH_GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Rush = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, RUSH_DMG)
		self:PunchEntity(ctx.Target)
	end

	self:RefreshPathIfStale(RUSH_PATH_AGE, ctx.Target, "Chase")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Rush = function(self)
	local rushTime = CurTime() - self.GlobalContext.StateStartTime
	local exhausted = rushTime >= RUSH_LIFETIME_DUR

	if exhausted then
		self.GlobalContext.CooldownUntil["Rush"] = CurTime() + RUSH_COOLDOWN_DUR
	end
end
