local SPEED = 1000
local ACCEL = 1200
local MIN_LOOK_AHEAD = 120
local GOAL_THRESH = 60
local MIN_RADIUS = 1000

ENT.StateRules.Flee = {
	min = 5,
	max = 30,
	cd = 60,
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
	local sc = self.StateContext
	sc.Goal = nil
	sc.InSequence = true

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local goal = self:FindPositionRadial(target, MIN_RADIUS, nil, false)
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
	local sc = self.StateContext

	if sc.Done or not sc.Goal then
		return
	end

	if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(sc.Goal, "Follow")
	path:Update(self)
	self:ClearObstacles()
end
