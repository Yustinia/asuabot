local SPEED = 3000
local ACCEL = 10000
local MIN_LOOK_AHEAD = 60
local GOAL_THRESH = 0
local STOP_DIST = 20
local START_RANGE = 1500
local HOLD_DUR = 3

ENT.StateRules.Feint = {
	min = 4,
	max = 12,
	cd = 60,
	needsTarget = true,
	block = { "Pounce", "Charge", "Rush" },
}

ENT.UtilityScores.Feint = function(self, ctx, trace)
	if trace then
		trace.Distance = ctx.Distance
		trace.Visible = ctx.Visible and 1 or 0
	end

	-- needs the player in view, and room to dash before stopping
	if not ctx.TargetValid or not ctx.Visible then
		return 0
	end

	if ctx.Distance <= STOP_DIST or ctx.Distance > START_RANGE then
		return 0
	end

	return 0.65
end

ENT.StateEnter.Feint = function(self)
	local sc = self.StateContext
	sc.Phase = "none"
	sc.HoldUntil = 0
	sc.InSequence = true

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.Phase = "dash"
	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Feint = function(self, ctx)
	local sc = self.StateContext

	if sc.Phase == "none" or not ctx.TargetValid then
		return
	end

	local path = self.GlobalContext.Path

	if sc.Phase == "dash" then
		if ctx.Distance <= STOP_DIST then
			self:HandleSpeed(0, 0)
			if path and path:IsValid() then
				path:Invalidate()
			end
			sc.Phase = "hold"
			sc.HoldUntil = CurTime() + HOLD_DUR
			return
		end

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
			return
		end

		self:RefreshPathIfStale(ctx.Target, "Chase")
		path:Update(self)
		self:ClearObstacles()
		return
	end

	if sc.Phase == "hold" then
		if CurTime() >= sc.HoldUntil then
			sc.InSequence = false
			sc.Done = true
		end
	end
end
