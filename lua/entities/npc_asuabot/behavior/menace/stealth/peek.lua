local SPEED = 1800
local ACCEL = 3000
local SCAN_RADIUS = 2000
local MIN_LOOK_AHEAD = 80
local GOAL_THRESH = 60
local TRIGGER_RANGE = 500
local LOOK_THRESHOLD = 0.966
local MAX_START_DIST = 2000
local WAIT_DUR = 30
local OUT_DUR = 20

ENT.StateRules.Peek = {
	min = 8,
	max = 90,
	cd = 200,
	needsTarget = true,
}

ENT.UtilityScores.Peek = function(self, ctx, trace)
	if trace then
		trace.Distance = ctx.Distance
	end

	if not ctx.TargetValid or ctx.Distance > MAX_START_DIST then
		return 0
	end

	return 0.7
end

ENT.StateEnter.Peek = function(self)
	local sc = self.StateContext
	sc.Phase = "none"
	sc.Goal = nil
	sc.HideSpot = nil
	sc.InSequence = true

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.Done = true
		return
	end

	local goal = self:FindClosePosWithoutLOS(SCAN_RADIUS, target)
	if not goal then
		sc.Done = true
		return
	end

	sc.Goal = goal
	sc.HideSpot = goal
	sc.Phase = "hide"
	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Peek = function(self, ctx)
	local sc = self.StateContext

	if sc.Phase == "none" or not ctx.TargetValid then
		return
	end

	local path = self.GlobalContext.Path

	if sc.Phase == "hide" then
		if self:IsAtPosition(sc.HideSpot, GOAL_THRESH) then
			self:HandleSpeed(0, 0)
			if path and path:IsValid() then
				path:Invalidate()
			end
			sc.Phase = "wait"
			sc.WaitUntil = CurTime() + WAIT_DUR
			return
		end

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
			return
		end

		if self:HandleStuckCheck() then
			return
		end

		self:RefreshPathIfStale(sc.HideSpot, "Follow")
		path:Update(self)
		self:ClearObstacles()
		return
	end

	if sc.Phase == "wait" then
		local inBand = ctx.Distance > TRIGGER_RANGE and ctx.Distance <= MAX_START_DIST

		if not ctx.Visible and inBand then
			sc.Phase = "out"
			sc.OutUntil = CurTime() + OUT_DUR
			self:HandleSpeed(SPEED, ACCEL)
			self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
			return
		end

		if CurTime() >= sc.WaitUntil then
			sc.InSequence = false
			sc.Done = true
		end
		return
	end

	if sc.Phase == "out" or sc.Phase == "watch" then
		local close = ctx.Distance <= TRIGGER_RANGE
		local looked = self:IsPlayerLookingAtBot(ctx.Target, LOOK_THRESHOLD)

		if close or looked or CurTime() >= sc.OutUntil then
			sc.Phase = "return"
			self:HandleSpeed(SPEED, ACCEL)
			self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
			return
		end
	end

	if sc.Phase == "out" then
		if ctx.Visible then
			sc.Seen = true
			sc.Phase = "watch"
			self:HandleSpeed(0, 0)
			if path and path:IsValid() then
				path:Invalidate()
			end
			return
		end

		if CurTime() >= sc.OutUntil then
			sc.Phase = "return"
			self:HandleSpeed(SPEED, ACCEL)
			self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
			return
		end

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
			return
		end

		self:RefreshPathIfStale(ctx.Target, "Chase")
		path:Update(self)
		return
	end

	if sc.Phase == "watch" then
		local close = ctx.Distance <= TRIGGER_RANGE
		local looked = self:IsPlayerLookingAtBot(ctx.Target, LOOK_THRESHOLD)

		if close or looked or CurTime() >= sc.OutUntil then
			sc.Phase = "return"
			self:HandleSpeed(SPEED, ACCEL)
			self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		end
		return
	end

	if sc.Phase == "return" then
		if self:IsAtPosition(sc.HideSpot, GOAL_THRESH) then
			if path and path:IsValid() then
				path:Invalidate()
			end

			local nav = self:FindRandomNavArea()
			if nav then
				self:Teleport(nav)
			end

			sc.InSequence = false
			sc.Done = true
			return
		end

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
			return
		end

		self:RefreshPathIfStale(sc.HideSpot, "Follow")
		path:Update(self)
	end
end
