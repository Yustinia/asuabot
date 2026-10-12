local SPEED = 2000
local ACCEL = 2000
local SCAN_RADIUS = 2000
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 60
local SIGHT_RANGE = 1500

ENT.StateRules.Hide = {
	min = 6,
	max = 24,
	cd = 35,
	needsTarget = true,
	block = { "Peek", "Ambush", "Retreat", "Flee" },
}

ENT.UtilityScores.Hide = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local near = Consider(ctx.Distance, 0, SIGHT_RANGE, Curves.LinearInverse)
	local seen = ctx.Observe and 1 or 0.2

	if trace then
		trace.Near = near
		trace.Seen = seen
	end

	return WeightedGeoMean({
		{ score = near, weight = 1 },
		{ score = seen, weight = 1.5 },
	})
end

ENT.StateEnter.Hide = function(self)
	local gl, sc = self.ReturnContext()

	sc.Goal = nil
	sc.Vanish = false

	if not IsValid(gl.Target) then
		sc.Done = true
		return
	end

	local goal = self:FindClosePosWithoutLOS(SCAN_RADIUS, gl.target)
	if not goal then
		sc.Done = true
		return
	end

	sc.Goal = goal

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Hide = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not sc.Goal then
		sc.Done = true
		return
	end

	if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
		sc.Vanish = true
		sc.Done = true
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(sc.Goal, "Follow")
	self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Hide = function(self)
	local gl, sc = self:ReturnContext()

	if not sc.Vanish then
		return
	end

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	local nav = self:FindRandomNavArea()
	if nav then
		self:Teleport(nav)
	end
end
