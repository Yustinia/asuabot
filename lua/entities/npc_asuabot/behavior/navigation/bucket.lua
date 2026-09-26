local NAVIGATION_MIN_DIST = 4000

ENT.BucketStates.Navigation = { "Wander" }

ENT.UtilityBuckets.Navigation = function(self, ctx, trace)
	local far = Consider(ctx.Distance, 0, NAVIGATION_MIN_DIST, function(x)
		return Curves.PowerOut(x, 4)
	end)

	if trace then
		trace.Far = far
	end

	return far
end
