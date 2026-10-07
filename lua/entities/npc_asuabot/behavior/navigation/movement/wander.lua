local SCAN_RADIUS = 3000
local MIN_LOOK_AHEAD = 120
local GOAL_THRESH = 20
local SPEED = 600
local ACCEl = 600

ENT.StateRules.Wander = {
	min = 40,
	max = 120,
	cd = 45,
}

ENT.UtilityScores.Wander = function(self, ctx)
	return 0.5
end

ENT.StateEnter.Wander = function(self)
	local goal = self:FindDistantNavArea(SCAN_RADIUS)
	if not goal then
		return
	end

	self.StateContext.Goal = goal
	self:HandleSpeed(SPEED, ACCEl)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Wander = function(self, ctx)
	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		local goal = self:FindDistantNavArea(SCAN_RADIUS)
		if not goal then
			return
		end

		self.StateContext.Goal = goal
		self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")

		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(self.StateContext.Goal, "Follow")
	path:Update(self)
	self:ClearObstacles()
end
