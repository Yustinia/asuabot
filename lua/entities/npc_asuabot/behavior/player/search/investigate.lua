local SPEED = 500
local ACCEL = 600
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 80
local WAIT_DUR = 3

ENT.StateRules.Investigate = {
	min = 7,
	max = 20,
	cd = 300,
	block = { "Sweep" },
}

ENT.UtilityScores.Investigate = function(self, ctx, trace)
	local pos = self.GlobalContext.TargetLastSeenPos

	if not ctx.TargetValid or not pos or ctx.Visible then
		return 0
	end

	local dist = self:GetPos():Distance(pos)
	if dist <= GOAL_THRESH then
		return 0
	end

	local fresh = math.max(
		Consider(ctx.LastSeenAge, 0, 30, function(x)
			return Curves.PowerInverseOut(x, 2)
		end),
		0.2
	)
	local reach = math.max(Consider(dist, 0, 3000, Curves.LinearInverse), 0.3)

	if trace then
		trace.Fresh = fresh
		trace.Reach = reach
	end

	return WeightedGeoMean({
		{ score = fresh, weight = 1.3 },
		{ score = reach, weight = 0.7 },
	})
end

ENT.StateEnter.Investigate = function(self)
	local gl, sc = self:ReturnContext()

	sc.Goal = nil
	sc.Arrived = false
	sc.WaitUntil = 0

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	local pos = self.GlobalContext.TargetLastSeenPos
	if not pos then
		sc.Done = true
		return
	end

	sc.Goal = pos

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(pos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Investigate = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not sc.Goal then
		sc.Done = true
		return
	end

	if sc.Arrived then
		if CurTime() >= sc.WaitUntil then
			sc.Done = true
		end
		return
	end

	if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
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

	self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	self:RefreshPathIfStale(sc.Goal, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Investigate = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end
end
