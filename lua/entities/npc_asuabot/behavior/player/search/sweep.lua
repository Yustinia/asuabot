local SPEED = 450
local ACCEL = 600
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 80
local WAIT_DUR = 3

local function PhaseChange(gl, sc, phaseName)
	sc.Phase = phaseName
	gl.ProgressPosition = nil
end

ENT.StateRules.Sweep = {
	min = 8,
	max = 90,
	cd = 150,
	block = { "Investigate" },
}

ENT.UtilityScores.Sweep = function(self, ctx, trace)
	local pos = self.GlobalContext.TargetLastSeenPos

	if not ctx.TargetValid or not pos or ctx.Visible then
		return 0
	end

	local cooling = math.max(
		Consider(ctx.LastSeenAge, 0, 60, function(x)
			return Curves.Bell(x, 0.4, 0.25)
		end),
		0.2
	)
	local tight = ctx.PlayerEnclosed and 1 or 0.7

	if trace then
		trace.Cooling = cooling
		trace.Tight = tight
	end

	return WeightedGeoMean({
		{ score = cooling, weight = 1.3 },
		{ score = tight, weight = 0.5 },
	})
end

ENT.StateEnter.Sweep = function(self)
	local gl, sc = self:ReturnContext()

	sc.Phase = "none"
	sc.Route = {}
	sc.Index = 1
	sc.WaitUntil = 0

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	local pos = self.GlobalContext.TargetLastSeenPos
	if not pos then
		sc.Done = true
		return
	end

	sc.Origin = pos
	sc.Phase = "go"

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(pos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Sweep = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if sc.Phase == "none" then
		sc.Done = true
		return
	end

	if sc.Phase == "wait" then
		if CurTime() < sc.WaitUntil then
			return
		end

		if sc.Index == 0 then
			local area = navmesh.GetNearestNavArea(sc.Origin)
			for _, adj in ipairs(self:GetNavAreaConnections(area)) do
				sc.Route[#sc.Route + 1] = adj:GetCenter()
			end

			if #sc.Route == 0 then
				sc.Done = true
				return
			end

			local from = self:GetPos()
			table.sort(sc.Route, function(a, b)
				return a:DistToSqr(from) < b:DistToSqr(from)
			end)
		end

		sc.Index = sc.Index + 1
		local nextGoal = sc.Route[sc.Index]
		if not nextGoal then
			sc.Done = true
			return
		end

		PhaseChange(gl, sc, "sweep")

		self:HandleSpeed(SPEED, ACCEL)
		self:ComputeRoutingPath(nextGoal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	local goal = sc.Phase == "go" and sc.Origin or sc.Route[sc.Index]
	if not goal then
		return
	end

	if self:IsAtPosition(goal, GOAL_THRESH) then
		if sc.Phase == "go" then
			sc.Index = 0
		end

		PhaseChange(gl, sc, "wait")

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

ENT.StateExit.Sweep = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end
end
