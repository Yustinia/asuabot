ENT.BucketStates.Aggression = {
	"Chase",
}

ENT.UtilityBuckets.Aggression = function(self, ctx, trace)
	local close = Consider(ctx.Distance, 0, 2000, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)

	if trace then
		trace.Close = close
	end

	local score = WeightedGeoMean({
		{ score = close, weight = 1.2 },
	})

	return score
end
