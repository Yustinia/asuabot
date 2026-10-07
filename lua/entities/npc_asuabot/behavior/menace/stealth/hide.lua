local SPEED = 2000
local ACCEL = 2000
local SCAN_RADIUS = 800
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 60
local SIGHT_RANGE = 1500

ENT.StateRules.Hide = {
	min = 6,
	max = 24,
	cd = 35,
	needsTarget = true,
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
	local sc = self.StateContext
	sc.Goal = nil
	sc.Arrived = false
	self.GlobalContext.Concealed = false

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	local goal = self:FindPositionWithoutLOS(SCAN_RADIUS, target:GetPos())
	if not goal then
		return
	end

	sc.Goal = goal
	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Hide = function(self, ctx)
	local sc = self.StateContext

	if not sc.Goal or sc.Arrived then
		return
	end

	if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
		sc.Arrived = true
		self:HandleSpeed(0, 0)

		local path = self.GlobalContext.Path
		if path and path:IsValid() then
			path:Invalidate()
		end

		self.GlobalContext.Concealed = true
		return
	end

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	self:RefreshPathIfStale(sc.Goal, "Follow")
	path:Update(self)
end

ENT.StateExit.Hide = function(self)
	self.GlobalContext.Concealed = false
end
