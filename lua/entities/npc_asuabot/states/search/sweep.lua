local SWEEP_SPD = 350
local SWEEP_ACCEL = 400
local SWEEP_GOAL_THRESH = 80
local SWEEP_AHEAD_DIST = 300
local SWEEP_PATH_AGE = 0.1
local SWEEP_WAYPOINT_WAIT = 2
local SWEEP_COOLDOWN_DUR = 60
local SWEEP_RAMP_DUR = 15

ENT.UtilityScores.Sweep = function(self, ctx, trace)
	if self.GlobalContext.PreviousState == "Sweep" then
		return 0.0
	end
	if ctx.Visible then
		return 0.0
	end

	local sweep = self.StateContext.Sweep
	if sweep and sweep.Completed then
		return 0.0
	end

	local urgency = Consider(ctx.SeenAge, 0, SWEEP_RAMP_DUR, function(x)
		return Curves.PowerOut(x, 2)
	end)

	if trace then
		trace.Urgency = urgency
	end

	return urgency
end

ENT.StateEnter.Sweep = function(self)
	self:HandleSpeed(SWEEP_SPD, SWEEP_ACCEL)

	local anchorPos = self.GlobalContext.TargetLastSeenPos
	local anchorArea = navmesh.GetNearestNavArea(anchorPos)

	local sweepPoints = { anchorArea:GetCenter() }
	for _, area in pairs(anchorArea:GetAdjacentAreas()) do
		table.insert(sweepPoints, area:GetCenter())
	end

	self.StateContext.Sweep = {
		SweepPoints = sweepPoints,
		CurrentIndex = 1,
		WaitUntil = 0,
	}

	self:ComputeRoutingPath(sweepPoints[1], SWEEP_AHEAD_DIST, SWEEP_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Sweep = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	local sweep = self.StateContext.Sweep
	local point = sweep.SweepPoints[sweep.CurrentIndex]

	if CurTime() < sweep.WaitUntil then
		return
	end

	if self:IsAtPosition(point, SWEEP_GOAL_THRESH) then
		sweep.CurrentIndex = sweep.CurrentIndex + 1

		if sweep.CurrentIndex > #sweep.SweepPoints then
			sweep.Completed = true
		else
			sweep.WaitUntil = CurTime() + SWEEP_WAYPOINT_WAIT
			self:ComputeRoutingPath(
				sweep.SweepPoints[sweep.CurrentIndex],
				SWEEP_AHEAD_DIST,
				SWEEP_GOAL_THRESH,
				"Follow"
			)
		end

		return
	end

	self:RefreshPathIfStale(SWEEP_PATH_AGE, point, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Sweep = function(self)
	self.GlobalContext.CooldownUntil["Sweep"] = CurTime() + SWEEP_COOLDOWN_DUR
end

-- function ENT:StateSweep()
-- 	self:HandleSpeed(SWEEP_SPD, SWEEP_ACCEL)

-- 	local anchorPos = self.TargetLastSeenPos
-- 	if not anchorPos then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	local anchorArea = navmesh.GetNearestNavArea(anchorPos)
-- 	if not IsValid(anchorArea) then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	local sweepPoints = { anchorArea:GetCenter() }
-- 	local adjacent = anchorArea:GetAdjacentAreas()
-- 	for _, area in pairs(adjacent) do
-- 		table.insert(sweepPoints, area:GetCenter())
-- 	end

-- 	for i = 1, #sweepPoints do
-- 		local targetPos = sweepPoints[i]

-- 		if not self:ComputeRoutingPath(targetPos, SWEEP_AHEAD_DIST, SWEEP_GOAL_THRESH, "Follow") then
-- 			self:SetState("Wander")
-- 			return
-- 		end

-- 		while self.Path:IsValid() do
-- 			if self:IsAtPosition(targetPos, SWEEP_GOAL_THRESH) then
-- 				break
-- 			end

-- 			if self:IsTargetVisible(self.Target) then
-- 				self.TargetLastSeenPos = self.Target:GetPos()
-- 				self:RecordLastSeenPosition(self.Target:GetPos())
-- 				self.TargetLastSeenTime = CurTime()

-- 				-- DO SOMETHING
-- 				return
-- 			end

-- 			self:RefreshPathIfStale(SWEEP_PATH_AGE, targetPos, "Follow")
-- 			self.Path:Update(self)
-- 			self:ClearObstacles()

-- 			coroutine.yield()
-- 		end

-- 		if i < #sweepPoints then
-- 			coroutine.wait(SWEEP_WAYPOINT_WAIT)
-- 		end
-- 	end
-- end
