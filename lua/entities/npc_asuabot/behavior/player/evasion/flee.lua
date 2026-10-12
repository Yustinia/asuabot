local SPEED = 2000
local ACCEL = 2400
local MIN_LOOK_AHEAD = 120
local GOAL_THRESH = 60
local MIN_RADIUS = 1000

ENT.StateRules.Flee = {
	min = 5,
	max = 30,
	cd = 60,
	needsTarget = true,
	block = { "Retreat", "Hide" },
}

ENT.UtilityScores.Flee = function(self, ctx, trace)
	if trace then
		trace.Observe = ctx.Observe and 1 or 0
	end

	if not ctx.TargetValid or not ctx.Observe then
		return 0
	end

	return 0.7
end

ENT.StateEnter.Flee = function(self)
	local gl, sc = self:ReturnContext()

	sc.Goal = nil
	sc.InSequence = true

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local goal = self:FindPositionRadial(gl.Target, MIN_RADIUS, nil, false)
	if not goal then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.Goal = goal

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Flee = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not sc.Goal or not ctx.TargetValid then
		sc.Done = true
		sc.InSequence = false
		return
	end

	if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
		sc.InSequence = false
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

ENT.StateExit.Flee = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end
end
