local STATE_MARGIN = 0.08

function ENT:SampleContext()
	local ctx = {}

	if not IsValid(self.GlobalContext.Target) then
		self.GlobalContext.Target = self:FindNearestPlayer()
	end

	ctx.Target = self.GlobalContext.Target
	ctx.TargetValid = IsValid(ctx.Target) and ctx.Target:Alive()

	if ctx.TargetValid then
		ctx.Distance = self:GetPos():Distance(ctx.Target:GetPos())
		ctx.Touching = self.IsTouchingPlayer(self, ctx.Target)
		ctx.Visible = self:IsTargetVisible(ctx.Target)
		ctx.Observe = self:IsObservedBy(ctx.Target)
		ctx.PlayerSpeed = ctx.Target:GetVelocity():Length2D()
		if ctx.Visible then
			self.GlobalContext.TargetLastSeenTime = CurTime()
			self.GlobalContext.TargetLastSeenPos = ctx.Target:GetPos()
			self:RecordLastSeenPosition(ctx.Target:GetPos())
		end
	end

	ctx.LastSeenAge = CurTime() - self.GlobalContext.TargetLastSeenTime
	ctx.CurrentState = self.GlobalContext.CurrentState
	ctx.StateTime = CurTime() - self.GlobalContext.StateStartTime

	return ctx
end

function ENT:SelectState(ctx)
	local bucketTraces = {}
	local bestBucketScore, bestBucketName = -math.huge, nil
	for name, scoreFunc in pairs(self.UtilityBuckets) do
		bucketTraces[name] = {}
		local score = scoreFunc(self, ctx, bucketTraces[name])
		if score > bestBucketScore then
			bestBucketScore, bestBucketName = score, name
		end
	end

	local bucketMembers = self.BucketStates[bestBucketName]

	local scores, traces = {}, {}
	local bestScore, bestName = -math.huge, nil
	for _, name in ipairs(bucketMembers) do
		traces[name] = {}

		local score = self.UtilityScores[name](self, ctx, traces[name])
		scores[name] = score

		if score > bestScore then
			bestScore = score
			bestName = name
		end
	end

	local candidates = {}
	for name, score in pairs(scores) do
		if score >= bestScore - STATE_MARGIN then
			table.insert(candidates, name)
		end
	end

	-- persist to use the same state if it's still inside the table
	if #candidates > 1 and table.HasValue(candidates, self.GlobalContext.CurrentState) then
		return self.GlobalContext.CurrentState
	end

	return candidates[math.random(#candidates)]
end

function Consider(raw, lo, hi, curveFn)
	local x = math.Clamp((raw - lo) / (hi - lo), 0, 1)
	return curveFn(x)
end

function WeightedGeoMean(entries)
	local acc, sumW = 0, 0

	for _, e in pairs(entries) do
		if e.score <= 0 then
			return 0
		end

		acc = acc + e.weight * math.log(e.score)
		sumW = sumW + e.weight
	end

	return math.exp(acc / sumW)
end
