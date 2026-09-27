local AGGRESSION_LIFETIME_DUR = 120
local AGGRESSION_COOLDOWN_DUR = 120

ENT.BucketStates.Aggression = {
	"Chase",
}

ENT.UtilityBuckets.Aggression = function(self, ctx, trace)
	if self.GlobalContext.PreviousBucket == "Aggression" then
		return 0.0
	end

	local bucketTime = (ctx.CurrentBucket == "Aggression") and ctx.BucketTime or 0
	local stamina = Consider(bucketTime, 0, AGGRESSION_LIFETIME_DUR, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	local close = Consider(ctx.Distance, 0, 2000, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	if trace then
		trace.Close = close
		trace.Stamina = stamina
	end

	local score = WeightedGeoMean({
		{ score = close, weight = 1.2 },
		{ score = stamina, weight = 0.7 },
	})

	return score
end

ENT.BucketExit.Aggression = function(self)
	local bucketTime = CurTime() - self.GlobalContext.BucketStartTime
	if bucketTime >= AGGRESSION_LIFETIME_DUR then
		self.GlobalContext.BucketCooldownUntil["Aggression"] = CurTime() + AGGRESSION_COOLDOWN_DUR
	end
end
