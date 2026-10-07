local PEEK_SPEED = 1800
local PEEK_ACCEL = 3000
local MIN_LOOK_AHEAD = 80
local GOAL_THRESH = 60
local TRIGGER_RANGE = 500
local LOOK_THRESHOLD = 0.966
local WATCH_UNTIL = 24
local MAX_START_DIST = 2000

ENT.StateRules.Peek = {
	min = 2,
	max = 30,
	cd = 200,
	needsTarget = true,
}

ENT.UtilityScores.Peek = function(self, ctx, trace)
	if not ctx.TargetValid or not self.GlobalContext.Concealed then
		return 0
	end

	if ctx.Visible or ctx.Distance <= TRIGGER_RANGE or ctx.Distance > MAX_START_DIST then
		return 0
	end

	if trace then
		trace.Concealed = self.GlobalContext.Concealed and 1 or 0
		trace.Visible = ctx.Visible and 1 or 0
		trace.InBand = (ctx.Distance > TRIGGER_RANGE and ctx.Distance <= MAX_START_DIST) and 1 or 0
	end

	return 0.8
end

ENT.StateEnter.Peek = function(self)
	local sc = self.StateContext
	sc.HideSpot = self:GetPos()
	sc.Phase = "none"

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	sc.Phase = "out"
	sc.InSequence = true
	self.StateContext.InSequence = true
	self:HandleSpeed(PEEK_SPEED, PEEK_ACCEL)
	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Peek = function(self, ctx)
	local sc = self.StateContext

	if sc.Phase == "none" or sc.Phase == "done" or not ctx.TargetValid then
		return
	end

	local path = self.GlobalContext.Path

	if sc.Phase == "out" or sc.Phase == "watch" then
		local close = ctx.Distance <= TRIGGER_RANGE
		local looked = self:IsPlayerLookingAtBot(ctx.Target, LOOK_THRESHOLD)

		if close or looked or ctx.StateTime >= WATCH_UNTIL then
			sc.Phase = "return"
			self:HandleSpeed(PEEK_SPEED, PEEK_ACCEL)
			self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
			return
		end
	end

	if sc.Phase == "out" then
		if ctx.Visible then
			self:HandleSpeed(0, 0)
			if path and path:IsValid() then
				path:Invalidate()
			end
			sc.Phase = "watch"
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
		return
	end

	if sc.Phase == "return" then
		if self:IsAtPosition(sc.HideSpot, GOAL_THRESH) then
			self:HandleSpeed(0, 0)
			if path and path:IsValid() then
				path:Invalidate()
			end
			sc.Phase = "done"
			self.StateContext.InSequence = false
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
