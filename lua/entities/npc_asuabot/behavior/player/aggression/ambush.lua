local HIDE_SPEED = 2000
local HIDE_ACCEL = 2000
local SPEED = 3000
local ACCEL = 4000
local MIN_RAD = 1400
local MAX_RAD = 1900
local START_RANGE = 2500
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 60
local STRIKE_THRESH = 0
local DAMAGE = 20
local TRIGGER_RANGE = 800
local WAIT_DUR = 30 -- wait at position for 30s
local STRIKE_DUR = 4 -- how long strike sequence happens

ENT.StateRules.Ambush = {
	min = 10,
	max = 60,
	cd = 320,
	needsTarget = true,
}

ENT.UtilityScores.Ambush = function(self, ctx, trace)
	if trace then
		trace.Distance = ctx.Distance
	end

	if not ctx.TargetValid or ctx.Distance > START_RANGE then
		return 0
	end

	return 0.75
end

ENT.StateEnter.Ambush = function(self)
	local sc = self.StateContext
	sc.Phase = "none"
	sc.Goal = nil
	sc.InSequence = true

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.Done = true
		return
	end

	local goal = self:FindPosInRangeWithoutLOS(MIN_RAD, MAX_RAD, target)
	if not goal then
		sc.Done = true
		return
	end

	sc.Goal = goal
	sc.Phase = "hide"
	self:HandleSpeed(HIDE_SPEED, HIDE_ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Ambush = function(self, ctx)
	local sc = self.StateContext

	if sc.Phase == "none" or not ctx.TargetValid then
		return
	end

	local path = self.GlobalContext.Path

	if sc.Phase == "hide" then
		if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
			self:HandleSpeed(0, 0)
			if path and path:IsValid() then
				path:Invalidate()
			end
			sc.Phase = "wait"
			sc.WaitUntil = CurTime() + WAIT_DUR
			return
		end

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
			return
		end

		if self:HandleStuckCheck() then
			return
		end

		self:RefreshPathIfStale(sc.Goal, "Follow")
		path:Update(self)
		self:ClearObstacles()
		return
	end

	if sc.Phase == "wait" then
		if ctx.Visible or ctx.Distance <= TRIGGER_RANGE then
			sc.Phase = "strike"
			sc.StrikeUntil = CurTime() + STRIKE_DUR
			self:HandleSpeed(SPEED, ACCEL)
			self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, STRIKE_THRESH, "Chase")
			return
		end

		if CurTime() >= sc.WaitUntil then
			sc.InSequence = false
			sc.Done = true
		end
		return
	end

	if sc.Phase == "strike" then
		if ctx.Touching then
			self:DamageEntity(ctx.Target, DAMAGE)
			self:PunchEntity(ctx.Target)

			if path and path:IsValid() then
				path:Invalidate()
			end

			local nav = self:FindRandomNavArea()
			if nav then
				self:Teleport(nav)
			end

			sc.InSequence = false
			sc.Done = true
			sc.Caught = true
			return
		end

		if CurTime() >= sc.StrikeUntil then
			sc.InSequence = false
			sc.Done = true
			return
		end

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, STRIKE_THRESH, "Chase")
			return
		end

		self:RefreshPathIfStale(ctx.Target, "Chase")
		path:Update(self)
		self:ClearObstacles()
	end
end

ENT.StateExit.Ambush = function(self)
	if self.StateContext.Caught then
		local path = self.GlobalContext.Path
		if path and path:IsValid() then
			path:Invalidate()
		end

		local nav = self:FindRandomNavArea()
		if nav then
			self:Teleport(nav)
		end
	end
end
