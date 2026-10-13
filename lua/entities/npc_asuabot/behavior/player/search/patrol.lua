local SPEED = 450
local ACCEL = 600
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 80
local WAIT_DUR = 3

ENT.StateRules.Patrol = {
	min = 10,
	max = 90,
	cd = 200,
	block = { "Investigate", "Sweep" },
}

ENT.UtilityScores.Patrol = function(self, ctx, trace)
	local glb = self.GlobalContext
	local list = glb.LastSeenTargetPositions
	local count = list and #list or 0

	if not ctx.TargetValid or count < glb.LastSeenTargetSize or ctx.Visible then
		return 0
	end

	local cold = math.max(
		Consider(ctx.LastSeenAge, 0, 90, function(x)
			return Curves.PowerIn(x, 1.5)
		end),
		0.2
	)
	local far = math.max(Consider(ctx.Distance, 0, 4000, Curves.Linear), 0.3)

	if trace then
		trace.Points = count
		trace.Cold = cold
		trace.Far = far
	end

	return WeightedGeoMean({
		{ score = cold, weight = 1.3 },
		{ score = far, weight = 0.6 },
	})
end

ENT.StateEnter.Patrol = function(self)
	local gl, sc = self:ReturnContext()

	sc.Route = {}
	sc.Index = 1
	sc.Arrived = false
	sc.WaitUntil = 0

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

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
	local gl, sc = self:ReturnContext()

	local goal = sc.Route and sc.Route[sc.Index]

	if not goal then
		sc.Done = true
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

		gl.ProgressPosition = nil

		self:ComputeRoutingPath(nextGoal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	if self:IsAtPosition(goal, GOAL_THRESH) then
		sc.Arrived = true
		sc.WaitUntil = CurTime() + WAIT_DUR
		self:HandleSpeed(0, 0)

		if gl.Path and gl.Path:IsValid() then
			gl.Path:Invalidate()
		end
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	self:RefreshPathIfStale(goal, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Patrol = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end
end
