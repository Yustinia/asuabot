-- wander finds a location outside of the 2000 scan radius

local WANDER_SPD = 500
local WANDER_ACCEL = 500
local WANDER_GOAL_THRESH = 120
local WANDER_SCAN_RAD = 2000
local WANDER_PATH_AGE = 0.08
local WANDER_AHEAD_DIST = 150
local WANDER_DAMAGE = 1
local WANDER_LIFETIME_DUR = 20
local WANDER_COOLDOWN_DUR = 40

ENT.UtilityScores.Wander = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.0
	end

	if self:GetPlayerHealth(ctx.Target) < 30 then
		return 0.0
	end

	local far = Consider(ctx.Distance, 0, 2000, function(x)
		return Curves.PowerOut(x, 3)
	end)

	local wanderTime = (ctx.CurrentState == "Wander") and ctx.StateTime or 0
	local stamina = Consider(wanderTime, 0, WANDER_LIFETIME_DUR, function(x)
		return Curves.PowerInverseIn(x, 2)
	end)

	if trace then
		trace.Far = far
		trace.Stamina = stamina
	end

	local score = WeightedGeoMean({
		{ score = far, weight = 0.5 },
		{ score = stamina, weight = 1 },
	})

	return score
end

ENT.StateEnter.Wander = function(self)
	self:HandleSpeed(WANDER_SPD, WANDER_ACCEL)

	self.StateContext.Wander = self.StateContext.Wander or {}
	local ctxWander = self.StateContext.Wander
	ctxWander.TargetPosition = self:FindDistantNavArea(WANDER_SCAN_RAD)

	self:ComputeRoutingPath(ctxWander.TargetPosition, WANDER_AHEAD_DIST, WANDER_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Wander = function(self, ctx)
	local ctxWander = self.StateContext.Wander

	if not self.GlobalContext.Path or not self.GlobalContext.Path:IsValid() then
		return
	end

	if self:IsAtPosition(ctxWander.TargetPosition, WANDER_GOAL_THRESH) then
		ctxWander.TargetPosition = self:FindDistantNavArea(WANDER_SCAN_RAD)
		self:ComputeRoutingPath(ctxWander.TargetPosition, WANDER_AHEAD_DIST, WANDER_GOAL_THRESH, "Follow")
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, WANDER_DAMAGE)
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(WANDER_PATH_AGE, ctxWander.TargetPosition, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Wander = function(self)
	self.GlobalContext.CooldownUntil["Wander"] = CurTime() + WANDER_COOLDOWN_DUR
end
