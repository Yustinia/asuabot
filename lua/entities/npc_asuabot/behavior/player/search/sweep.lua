local SPEED = 450
local ACCEL = 600
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 80
local WAIT_DUR = 3

ENT.StateRules.Sweep = {
	min = 8,
	max = 90,
	cd = 150,
}

ENT.UtilityScores.Sweep = function(self, ctx, trace)
	local pos = self.GlobalContext.TargetLastSeenPos

	if trace then
		trace.HasPos = pos and 1 or 0
		trace.Visible = ctx.Visible and 1 or 0
	end

	if not ctx.TargetValid or not pos or ctx.Visible then
		return 0
	end

	return 0.7
end

ENT.StateEnter.Sweep = function(self)
	local sc = self.StateContext
	sc.Phase = "none"
	sc.Route = {}
	sc.Index = 1
	sc.WaitUntil = 0

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
	local sc = self.StateContext

	if sc.Phase == "none" then
		return
	end

	local path = self.GlobalContext.Path

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

		sc.Phase = "sweep"
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

		sc.Phase = "wait"
		sc.WaitUntil = CurTime() + WAIT_DUR
		self:HandleSpeed(0, 0)

		if path and path:IsValid() then
			path:Invalidate()
		end
		return
	end

	if not path or not path:IsValid() then
		self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(goal, "Follow")
	path:Update(self)
	self:ClearObstacles()
end
