local SPEED = 800
local ACCEL = 800
local MIN_LOOK_AHEAD = 200
local GOAL_THRESH = 0
local DAMAGE = 20
local SIGHT_RANGE = 2000
local MEMORY_DUR = 5

ENT.StateRules.Chase = {
	min = 8,
	max = 16,
	cd = 75,
}

ENT.UtilityScores.Chase = function(self, ctx)
	if not ctx.TargetValid then
		return 0
	end

	local close = Consider(ctx.Distance, 0, SIGHT_RANGE, Curves.LinearInverse)

	local memory = Consider(ctx.LastSeenAge, 0, MEMORY_DUR, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	return WeightedGeoMean({
		{ score = close, weight = 1 },
		{ score = memory, weight = 1.2 },
	})
end

ENT.StateEnter.Chase = function(self)
	self:HandleSpeed(SPEED, ACCEL)

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Chase = function(self, ctx)
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
	end

	self:RefreshPathIfStale(ctx.Target, "Chase")
	path:Update(self)
	self:ClearObstacles()
end
