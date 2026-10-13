local SCAN_RADIUS = 3000
local MIN_LOOK_AHEAD = 120
local GOAL_THRESH = 20
local SPEED = 600
local ACCEl = 600

ENT.StateRules.Wander = {
	min = 20,
	max = 110,
	cd = 45,
}

ENT.UtilityScores.Wander = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.7
	end

	local playerInOpen = ctx.PlayerInOpen and 0.7 or 0.2
	local distance = Consider(ctx.Distance, 0, 4000, function(x)
		return Curves.Bell(x, nil, 0.2)
	end)

	if trace then
		trace.PlayerInOpen = playerInOpen
		trace.Distance = distance
	end

	return WeightedGeoMean({
		{ score = playerInOpen, weight = 1.2 },
		{ score = distance, weight = 1.1 },
	})
end

ENT.StateEnter.Wander = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	local goal = self:FindDistantNavArea(SCAN_RADIUS)
	if not goal then
		sc.Done = true
		return
	end

	sc.Goal = goal

	self:HandleSpeed(SPEED, ACCEl)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")

	gl.Target:EmitSound("Asuabot.Screech")
end

ENT.StateUpdate.Wander = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not gl.Path or not gl.Path:IsValid() then
		local goal = self:FindDistantNavArea(SCAN_RADIUS)
		if not goal then
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

ENT.StateExit.Wander = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	gl.Target:StopSound("Asuabot.Ambiance")
end
