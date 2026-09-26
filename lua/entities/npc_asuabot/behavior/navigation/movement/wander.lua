local WANDER_SPD = 500
local WANDER_ACCEL = 500
local WANDER_GOAL_THRESH = 120
local WANDER_SCAN_RAD = 2000
local WANDER_PATH_AGE = 0.08
local WANDER_AHEAD_DIST = 150
local WANDER_LIFETIME_DUR = 20

ENT.UtilityScores.Wander = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 1.0
	end

	local far = Consider(ctx.Distance, 0, 2000, function(x)
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
