local EVASION_LIFETIME_DUR = 75
local EVASION_COOLDOWN_DUR = 100

ENT.BucketStates.Evasion = {
	"Flee",
	"Retreat",
}

ENT.UtilityBuckets.Evasion = function(self, ctx, trace)
	if self.GlobalContext.PreviousBucket == "Evasion" then
		return 0.0
	end

	local bucketTime = (ctx.CurrentBucket == "Evasion") and ctx.BucketTime or 0
	local stamina = Consider(bucketTime, 0, EVASION_LIFETIME_DUR, Curves.LinearInverse)

	if trace then
		trace.Stamina = stamina
	end

	local score = WeightedGeoMean({
		{ score = stamina, weight = 1.2 },
	})

	return score
end

ENT.BucketExit = function(self)
	local bucketTime = CurTime() - self.GlobalContext.BucketStartTime
	if bucketTime >= EVASION_LIFETIME_DUR then
		self.GlobalContext.BucketCooldownUntil["Evasion"] = CurTime() + EVASION_COOLDOWN_DUR
	end
end
