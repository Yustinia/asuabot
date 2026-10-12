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

ENT.UtilityScores.Wander = function(self, ctx)
	return 0.5
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
end

ENT.StateExit.Wander = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end
end
