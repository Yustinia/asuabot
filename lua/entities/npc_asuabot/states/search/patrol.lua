local PATROL_SPD = 400
local PATROL_ACCEL = 400
local PATROL_PATH_AGE = 0.1
local PATROL_GOAL_THRESH = 120
local PATROL_AHEAD_DIST = 100
local PATROL_COOLDOWN_DUR = 60
local PATROL_RAMP_DUR = 30

ENT.UtilityScores.Patrol = function(self, ctx, trace)
	if self.GlobalContext.PreviousState == "Patrol" then
		return 0.0
	end

	local hasHistory = #self.GlobalContext.LastSeenTargetPositions >= self.GlobalContext.LastSeenTargetSize
	if not hasHistory or ctx.Visible then
		return 0.0
	end

	local patrol = self.StateContext.Patrol
	if patrol and patrol.Completed then
		return 0.0
	end

	local urgency = Consider(ctx.SeenAge, 0, PATROL_RAMP_DUR, function(x)
		return Curves.PowerOut(x, 3)
	end)

	if trace then
		trace.HasHistory = hasHistory and 1 or 0
		trace.Urgency = urgency
	end

	return urgency
end

ENT.StateEnter.Patrol = function(self)
	self:HandleSpeed(PATROL_SPD, PATROL_ACCEL)

	self.StateContext.Patrol = {
		Points = self.GlobalContext.LastSeenTargetPositions,
		CurrentIndex = 1,
	}

	self:ComputeRoutingPath(self.StateContext.Patrol.Points[1], PATROL_AHEAD_DIST, PATROL_GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Patrol = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	local patrol = self.StateContext.Patrol
	local point = patrol.Points[patrol.CurrentIndex]

	if self:IsAtPosition(point, PATROL_GOAL_THRESH) then
		patrol.CurrentIndex = patrol.CurrentIndex + 1

		if patrol.CurrentIndex > #patrol.Points then
			patrol.Completed = true
		else
			self:ComputeRoutingPath(patrol.Points[patrol.CurrentIndex], PATROL_AHEAD_DIST, PATROL_GOAL_THRESH, "Follow")
		end

		if self:HandleStuckCheck() then
			return
		end

		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(PATROL_PATH_AGE, point, "Follow")
	self.GlobalContext.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Patrol = function(self)
	self.GlobalContext.CooldownUntil["Patrol"] = CurTime() + PATROL_COOLDOWN_DUR
end

-- function ENT:StatePatrol()
-- 	self:HandleSpeed(PATROL_SPD, PATROL_ACCEL)

-- 	local targetPos = self:GetNextPatrolSpot()
-- 	if not targetPos then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	if not self:ComputeRoutingPath(targetPos, PATROL_AHEAD_DIST, PATROL_GOAL_THRESH, "Follow") then
-- 		self:SetState("Wander")
-- 		return
-- 	end

-- 	while self.Path:IsValid() do
-- 		if self:IsAtPosition(targetPos, PATROL_GOAL_THRESH) then
-- 			-- advances to the next patrol spot
-- 			coroutine.wait(PATROL_WAYPOINT_WAIT)
-- 			return
-- 		end

-- 		if self:IsTargetVisible(self.Target) then
-- 			-- DO SOMETHING
-- 		end

-- 		if self:HandleStuckCheck() then
-- 			return
-- 		end

-- 		self:RefreshPathIfStale(PATROL_PATH_AGE, targetPos, "Follow")
-- 		self.Path:Update(self)
-- 		self:ClearObstacles()

-- 		coroutine.yield()
-- 	end
-- end
