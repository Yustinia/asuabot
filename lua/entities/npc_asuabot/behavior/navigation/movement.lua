local NAVIGATION_MIN_DIST = 4000

ENT.BucketStates.Navigation = {
	"Wander",
	"Drift",
}

ENT.UtilityBuckets.Navigation = function(self, ctx, trace)
	if self.GlobalContext.PreviousBucket == "Navigation" then
		return 0.0
	end

	local far = Consider(ctx.Distance, 0, NAVIGATION_MIN_DIST, function(x)
		return Curves.PowerOut(x, 4)
	end)

	if trace then
		trace.Far = far
	end

	return far
end
