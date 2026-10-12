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

	if trace then
		trace.HasPos = pos and 1 or 0
		trace.Visible = ctx.Visible and 1 or 0
	end

	if not ctx.TargetValid or not pos or ctx.Visible then
		return 0
	end

	if self:GetPos():Distance(pos) <= GOAL_THRESH then
		return 0
	end

	return 0.7
end

ENT.StateEnter.Investigate = function(self)
	local gl, sc = self:ReturnContext()

	sc.Goal = nil
	sc.Arrived = false
	sc.WaitUntil = 0

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
