local SPEED = 2500
local ACCEL = 3500
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 0
local DAMAGE = 20
local TRIGGER_RANGE = 2500

ENT.StateRules.Blink = {
	min = 8,
	max = 30,
	cd = 100,
	needsTarget = true,
}

ENT.UtilityScores.Blink = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local close = Consider(ctx.Distance, 0, TRIGGER_RANGE, Curves.LinearInverse)

	if trace then
		trace.Close = close
	end

	return WeightedGeoMean({
		{ score = close, weight = 1 },
	})
end

ENT.StateEnter.Blink = function(self)
	local sc = self.StateContext
	sc.Frozen = nil

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Blink = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	local sc = self.StateContext
	local seen = self:IsPlayerLookingAtBot(ctx.Target)

	if seen ~= sc.Frozen then
		sc.Frozen = seen
		if seen then
			self:HandleSpeed(0, 0)
		else
			self:HandleSpeed(SPEED, ACCEL)
		end
	end

	if seen then
		return
	end

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
		self:PunchEntity(ctx.Target)
		self.StateContext.Done = true
		return
	end

	self:RefreshPathIfStale(ctx.Target, "Chase")
	path:Update(self)
	self:ClearObstacles()
end
