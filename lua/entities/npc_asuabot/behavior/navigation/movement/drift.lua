local DRIFT_SPD = 200
local DRIFT_ACCEL = 300
local DRIFT_GOAL_THRESH = 120
local DRIFT_SCAN_RAD = 1000
local DRIFT_PATH_AGE = 0.08
local DRIFT_AHEAD_DIST = 150
local DRIFT_LIFETIME_DUR = 20
local DRIFT_DAMAGE = 1

ENT.UtilityScores.Drift = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 1.0
	end

	local far = Consider(ctx.Distance, 0, 1000, function(x)
		return Curves.PowerOut(x, 3)
	end)

	if trace then
		trace.Far = far
	end

	local score = WeightedGeoMean({
		{ score = far, weight = 0.5 },
	})

	return math.max(score, 0.1)
end

ENT.StateEnter.Drift = function(self)
	self:HandleSpeed(DRIFT_SPD, DRIFT_ACCEL)

	self.GlobalContext.ProgressPosition = self:GetPos()
	self.GlobalContext.ProgressTime = CurTime()

	self.StateContext.DRIFT = {
		TargetPosition = self:FindNearestNavArea(DRIFT_SCAN_RAD),
	}

	local ctxDrift = self.StateContext.Drift
	self:ComputeRoutingPath(ctxDrift.TargetPosition, DRIFT_AHEAD_DIST, DRIFT_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Drift = function(self, ctx)
	local ctxDrift = self.StateContext.Drift

	if not self.GlobalContext.Path or not self.GlobalContext.Path:IsValid() then
		return
	end

	if self:IsAtPosition(self.StateContext.DRIFT.TargetPosition, DRIFT_GOAL_THRESH) then
		ctxDrift.TargetPosition = self:FindDistantNavArea(DRIFT_SCAN_RAD)
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

ENT.StateExit.Drift = function(self) end
