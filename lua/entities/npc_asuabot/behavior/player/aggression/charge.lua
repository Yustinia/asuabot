local SPEED = 30000
local ACCEL = 1000
local MIN_LOOK_AHEAD = 200
local GOAL_THRESH = 0
local DAMAGE = 25
local TRIGGER_MIN = 800
local TRIGGER_MAX = 2500

ENT.StateRules.Charge = {
	min = 6,
	max = 25,
	cd = 60,
	needsTarget = true,
}

ENT.UtilityScores.Charge = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local range = Consider(ctx.Distance, TRIGGER_MIN - 600, TRIGGER_MAX + 600, function(x)
		return Curves.Bell(x, 0.25)
	end)

	if trace then
		trace.Range = range
	end

	return WeightedGeoMean({
		{ score = range, weight = 1 },
	})
end

ENT.StateEnter.Charge = function(self)
	self:HandleSpeed(SPEED, ACCEL)

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Charge = function(self, ctx)
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
