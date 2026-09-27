local EXPLORATION_MIN_DIST = 2000

ENT.BucketStates.Exploration = {
	"Survey",
}

ENT.UtilityBuckets.Exploration = function(self, ctx, trace)
	local far = Consider(ctx.Distance, 0, EXPLORATION_MIN_DIST, function(x)
		return Curves.PowerOut(x, 3)
	end)

	if trace then
		trace.Far = far
	end

	local score = WeightedGeoMean({
		{ score = far, weight = 1.4 },
	})

	return score
end
