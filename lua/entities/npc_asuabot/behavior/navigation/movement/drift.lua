-- drift finds a location inside an 800 scan radius

local DRIFT_SPD = 200
local DRIFT_ACCEL = 300
local DRIFT_GOAL_THRESH = 120
local DRIFT_SCAN_RAD = 800
local DRIFT_PATH_AGE = 0.08
local DRIFT_AHEAD_DIST = 150
local DRIFT_DAMAGE = 1
local DRIFT_LIFETIME_DUR = 30
local DRIFT_COOLDOWN_DUR = 50

ENT.UtilityScores.Drift = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.0
	end

	if self:GetPlayerHealth(ctx.Target) >= 30 then
		return 0.0
	end

	local far = Consider(ctx.Distance, 0, DRIFT_SCAN_RAD, function(x)
		return Curves.PowerOut(x, 3)
	end)

	local driftTime = (ctx.CurrentState == "Drift") and ctx.StateTime or 0
	local stamina = Consider(driftTime, 0, DRIFT_LIFETIME_DUR, function(x)
		return Curves.PowerInverseIn(x, 2)
	end)

	if trace then
		trace.Far = far
		trace.Stamina = stamina
	end

	local score = WeightedGeoMean({
		{ score = far, weight = 0.7 },
		{ score = stamina, weight = 1.2 },
	})

	return score
end

ENT.StateEnter.Drift = function(self)
	self:HandleSpeed(DRIFT_SPD, DRIFT_ACCEL)

	self.StateContext.Drift = {
		TargetPosition = self:FindNearbyNavArea(DRIFT_SCAN_RAD),
	}

	local ctxDrift = self.StateContext.Drift
	self:ComputeRoutingPath(ctxDrift.TargetPosition, DRIFT_AHEAD_DIST, DRIFT_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Drift = function(self, ctx)
	local ctxDrift = self.StateContext.Drift

	if not self.GlobalContext.Path or not self.GlobalContext.Path:IsValid() then
		return
	end

	if self:IsAtPosition(ctxDrift.TargetPosition, DRIFT_GOAL_THRESH) then
		ctxDrift.TargetPosition = self:FindNearbyNavArea(DRIFT_SCAN_RAD)
		self:ComputeRoutingPath(ctxDrift.TargetPosition, DRIFT_AHEAD_DIST, DRIFT_GOAL_THRESH, "Follow")
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, DRIFT_DAMAGE)
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(DRIFT_PATH_AGE, ctxDrift.TargetPosition, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Drift = function(self)
	self.GlobalContext.CooldownUntil["Drift"] = CurTime() + DRIFT_COOLDOWN_DUR
end
