local SPEED = 450
local ACCEL = 600
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 80
local WAIT_DUR = 3

ENT.StateRules.Patrol = {
	min = 10,
	max = 90,
	cd = 200,
	needsTarget = true,
}

ENT.UtilityScores.Patrol = function(self, ctx, trace)
	local glb = self.GlobalContext
	local list = glb.LastSeenTargetPositions
	local count = list and #list or 0
	local required = glb.LastSeenTargetSize

	if trace then
		trace.Points = count
		trace.Visible = ctx.Visible and 1 or 0
	end

	if not ctx.TargetValid or count < required or ctx.Visible then
		return 0
	end

	return 0.6
end

ENT.StateEnter.Patrol = function(self)
	local sc = self.StateContext
	sc.Route = {}
	sc.Index = 1
	sc.Arrived = false
	sc.WaitUntil = 0

	for _, pos in ipairs(self.GlobalContext.LastSeenTargetPositions or {}) do
		sc.Route[#sc.Route + 1] = pos
	end

	if #sc.Route == 0 then
		sc.Done = true
		return
	end

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(sc.Route[1], MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Patrol = function(self, ctx)
	local sc = self.StateContext
	local goal = sc.Route and sc.Route[sc.Index]

	if not goal then
		return
	end

	if sc.Arrived then
		if CurTime() < sc.WaitUntil then
			return
		end

		sc.Index = sc.Index + 1
		sc.Arrived = false

		local nextGoal = sc.Route[sc.Index]
		if not nextGoal then
			sc.Done = true
			return
		end

		self:HandleSpeed(SPEED, ACCEL)
		self:ComputeRoutingPath(nextGoal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	if self:IsAtPosition(goal, GOAL_THRESH) then
		sc.Arrived = true
		sc.WaitUntil = CurTime() + WAIT_DUR
		self:HandleSpeed(0, 0)

		local path = self.GlobalContext.Path
		if path and path:IsValid() then
			path:Invalidate()
		end
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	self:RefreshPathIfStale(goal, "Follow")
	path:Update(self)
	self:ClearObstacles()
end
