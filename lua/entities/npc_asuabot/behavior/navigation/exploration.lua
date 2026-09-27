local EXPLORATION_MIN_DIST = 2000
local EXPLORATION_LIFETIME_DUR = 25
local EXPLORATION_COOLDOWN_DUR = 50

ENT.BucketStates.Exploration = {
	"Survey",
}

ENT.UtilityBuckets.Exploration = function(self, ctx, trace)
	if self.GlobalContext.PreviousBucket == "Exploration" then
		return 0.0
	end

	local far = Consider(ctx.Distance, 0, EXPLORATION_MIN_DIST, function(x)
		return Curves.PowerOut(x, 3)
	end)

	local bucketTime = (ctx.CurrentBucket == "Exploration") and ctx.BucketTime or 0
	local stamina = Consider(bucketTime, 0, EXPLORATION_LIFETIME_DUR, Curves.LinearInverse)

	if trace then
		trace.Far = far
		trace.Stamina = stamina
	end

	local score = WeightedGeoMean({
		{ score = far, weight = 1.4 },
		{ score = stamina, weight = 1.2 },
	})

	return score
end

ENT.BucketExit.Exploration = function(self)
	local bucketTime = CurTime() - self.GlobalContext.BucketStartTime
	if bucketTime >= EXPLORATION_LIFETIME_DUR then
		self.GlobalContext.BucketCooldownUntil["Exploration"] = CurTime() + EXPLORATION_COOLDOWN_DUR
	end
end
