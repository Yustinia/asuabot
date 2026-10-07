local SPEED = 10000
local ACCEL = 10000
local MIN_LOOK_AHEAD = 60
local GOAL_THRESH = 60
local DAMAGE = 20
local SIGHT_RANGE = 1800
local WAIT_DUR = 3
local LEAP_TIMEOUT = 2

ENT.StateRules.Pounce = {
	min = 6,
	max = 20,
	cd = 80,
	needsTarget = true,
}

ENT.UtilityScores.Pounce = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local close = Consider(ctx.Distance, 0, SIGHT_RANGE, Curves.LinearInverse)
	local moving = math.max(Consider(ctx.PlayerSpeed, 0, 300, Curves.Linear), 0.2)

	if trace then
		trace.Close = close
		trace.Moving = moving
	end

	return WeightedGeoMean({
		{ score = close, weight = 1 },
		{ score = moving, weight = 1.2 },
	})
end

ENT.StateEnter.Pounce = function(self)
	local sc = self.StateContext
	sc.Phase = "none"

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	sc.LockedPos = target:GetPos()
	sc.LeapUntil = CurTime() + LEAP_TIMEOUT
	sc.Phase = "leap"
	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(sc.LockedPos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Pounce = function(self, ctx)
	local sc = self.StateContext

	if sc.Phase == "none" or not ctx.TargetValid then
		return
	end

	local path = self.GlobalContext.Path

	if sc.Phase == "leap" then
		if ctx.Touching then
			self:DamageEntity(ctx.Target, DAMAGE)
			self:PunchEntity(ctx.Target)
			self:HandleSpeed(0, 0)
			sc.Done = true
			return
		end

		if self:IsAtPosition(sc.LockedPos, GOAL_THRESH) or CurTime() >= sc.LeapUntil then
			self:HandleSpeed(0, 0)
			if path and path:IsValid() then
				path:Invalidate()
			end
			sc.Phase = "wait"
			sc.WaitUntil = CurTime() + WAIT_DUR
			return
		end

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(sc.LockedPos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
			return
		end

		self:RefreshPathIfStale(sc.LockedPos, "Follow")
		path:Update(self)
		self:ClearObstacles()
		return
	end

	if sc.Phase == "wait" then
		if CurTime() < sc.WaitUntil then
			return
		end

		sc.LockedPos = ctx.Target:GetPos()
		sc.LeapUntil = CurTime() + LEAP_TIMEOUT
		sc.Phase = "leap"
		self:HandleSpeed(SPEED, ACCEL)
		self:ComputeRoutingPath(sc.LockedPos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	end
end
