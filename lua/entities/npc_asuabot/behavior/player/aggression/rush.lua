local SPEED = 2400
local ACCEL = 1600
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 0
local DAMAGE = 20
local SIGHT_RANGE = 1500
local MEMORY_DUR = 5

ENT.StateRules.Rush = {
	min = 8,
	max = 12,
	cd = 80,
	needsTarget = true,
}

ENT.UtilityScores.Rush = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local close = Consider(ctx.Distance, 0, SIGHT_RANGE, Curves.LinearInverse)
	local memory = Consider(ctx.LastSeenAge, 0, MEMORY_DUR, function(x)
		return Curves.SmoothStepInverseOut(x, 3)
	end)

	if trace then
		trace.Close = close
		trace.Memory = memory
	end

	return WeightedGeoMean({
		{ score = close, weight = 1 },
		{ score = memory, weight = 1.4 },
	})
end

ENT.StateEnter.Rush = function(self)
	self:HandleSpeed(SPEED, ACCEL)

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Rush = function(self, ctx)
	if not ctx.TargetValid then
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
