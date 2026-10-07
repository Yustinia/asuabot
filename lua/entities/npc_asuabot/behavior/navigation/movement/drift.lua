-- behavior/navigation/movement/drift.lua
local SPEED = 200
local ACCEL = 300
local SCAN_RADIUS = 1200
local MIN_LOOK_AHEAD = 150
local GOAL_THRESH = 120

ENT.StateRules.Drift = {
	min = 10,
	max = 30,
	cd = 20,
}

ENT.UtilityScores.Drift = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local near = Consider(ctx.Distance, 0, SCAN_RADIUS, Curves.LinearInverse)

	if trace then
		trace.Near = near
	end

	return WeightedGeoMean({
		{ score = near, weight = 1 },
	})
end

ENT.StateEnter.Drift = function(self)
	self:HandleSpeed(SPEED, ACCEL)

	local goal = self:FindNearbyNavArea(SCAN_RADIUS)
	if not goal then
		return
	end

	self.StateContext.Goal = goal
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Drift = function(self, ctx)
	local path = self.GlobalContext.Path

	if not path or not path:IsValid() then
		local goal = self:FindNearbyNavArea(SCAN_RADIUS)
		if not goal then
			return
		end

		self.StateContext.Goal = goal
		self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	self:RefreshPathIfStale(self.StateContext.Goal, "Follow")
	path:Update(self)
end
