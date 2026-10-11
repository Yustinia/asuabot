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
	local sc = self.StateContext
	sc.Goal = nil
	sc.Caught = false

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.Done = true
		return
	end

	local goal = self:FindClosePosWithoutLOS(SCAN_RADIUS, target)
	if not goal then
		sc.Done = true
		return
	end

	sc.Goal = goal
	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Retreat = function(self, ctx)
	local sc = self.StateContext

	if not sc.Goal then
		return
	end

	local path = self.GlobalContext.Path

	if self:IsAtPosition(sc.Goal, ARRIVE_DIST) then
		sc.Caught = true
		sc.Done = true
		return
	end

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

ENT.StateExit.Retreat = function(self)
	if self.StateContext.Caught then
		local path = self.GlobalContext.Path
		if path and path:IsValid() then
			path:Invalidate()
		end

		local nav = self:FindRandomNavArea()
		if nav then
			self:Teleport(nav)
		end
	end
end
