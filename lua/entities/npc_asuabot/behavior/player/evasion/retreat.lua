local SPEED = 2400
local ACCEL = 3600
local SCAN_RADIUS = 1200
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 20
local ARRIVE_DIST = 40

ENT.StateRules.Retreat = {
	min = 4,
	max = 20,
	cd = 90,
	needsTarget = true,
	block = { "Hide", "Flee" },
}

ENT.UtilityScores.Retreat = function(self, ctx, trace)
	if trace then
		trace.Observe = ctx.Observe and 1 or 0
	end

	if not ctx.TargetValid or not ctx.Observe then
		return 0
	end

	return 0.6
end

ENT.StateEnter.Retreat = function(self)
	local gl, sc = self:ReturnContext()

	sc.Goal = nil
	sc.Caught = false

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.Done = true
		return
	end

	local goal = self:FindClosePosWithoutLOS(SCAN_RADIUS, gl.Target)
	if not goal then
		sc.Done = true
		return
	end

	sc.Goal = goal

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Retreat = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not sc.Goal or not ctx.TargetValid then
		sc.Done = true
	end

	if self:IsAtPosition(sc.Goal, ARRIVE_DIST) then
		sc.Caught = true
		sc.Done = true
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	self:RefreshPathIfStale(sc.Goal, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Retreat = function(self)
	local gl, sc = self:ReturnContext()

	if not sc.Caught then
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
