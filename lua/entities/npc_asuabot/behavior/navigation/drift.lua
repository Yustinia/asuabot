local SPEED = 200
local ACCEL = 300
local SCAN_RADIUS = 1200
local MIN_LOOK_AHEAD = 150
local GOAL_THRESH = 20

ENT.StateRules.Drift = {
	min = 10,
	max = 30,
	cd = 20,
}

ENT.UtilityScores.Drift = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.7
	end

	local near = Consider(ctx.Distance, 0, SCAN_RADIUS, Curves.LinearInverse)
	local distance = Consider(ctx.Distance, 0, 4000, function(x)
		return Curves.Bell(x, nil, 0.15)
	end)

	if trace then
		trace.Near = near
		trace.Distance = distance
	end

	return WeightedGeoMean({
		{ score = near, weight = 1.5 },
		{ score = distance, weight = 0.8 },
	})
end

ENT.StateEnter.Drift = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	local goal = self:FindNearbyNavArea(SCAN_RADIUS)
	if not goal then
		sc.Done = true
		return
	end

	sc.Goal = goal

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")

	gl.Target:EmitSound("Asuabot.Screech")
end

ENT.StateUpdate.Drift = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not gl.Path or not gl.Path:IsValid() then
		local goal = self:FindNearbyNavArea(SCAN_RADIUS)
		if not goal then
			sc.Done = true
			return
		end

		sc.Goal = goal
		self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")

		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(self.StateContext.Goal, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()

	self:EmitLoop(ctx.Target, "Asuabot.Ambiance")
end

ENT.StateExit.Drift = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	gl.Target:StopSound("Asuabot.Ambiance")
end
