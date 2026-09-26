local WANDER_SPEED = 500
local WANDER_ACCEl = 700


ENT.UtilityScores.Wander = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0.00
	end

	local distance = Consider(ctx.Distance, 0, 2000, function(x)
		return Curves.PowerOut(x, 3)
	end)

	local score = WeightedGeoMean({
		{ score = distance, weight = 1.2 },
	})

	return math.max(score, 0.10)
end

ENT.StateEnter.Wander = function(self)
    self:HandleSpeed
end

ENT.StateUpdate.Wander = function(self, ctx) end

ENT.StateExit.Wander = function(self) end
