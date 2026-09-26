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
		ctx.Visible = self:IsTargetVisibleFromBot(ctx.Target)
		ctx.Observe = self:IsPlayerLookingAtBot(ctx.Target)
		ctx.PlayerSpeed = ctx.Target:GetVelocity():Length2D()
		if ctx.Visible then
			self.GlobalContext.TargetLastSeenTime = CurTime()
			self.GlobalContext.TargetLastSeenPos = ctx.Target:GetPos()
			self:RecordLastSeenPosition(ctx.Target:GetPos())
		end
	end

	-- used for minimum state runtime duration (memory)
	ctx.LastSeenAge = CurTime() - self.GlobalContext.TargetLastSeenTime
	-- used for maximum state runtime duration (stamina)
	ctx.StateTime = CurTime() - self.GlobalContext.StateStartTime

	ctx.CurrentState = self.GlobalContext.CurrentState

	return ctx
end

function ENT:SelectState(ctx)
	local bucketScores, bucketTraces = {}, {}
	local bestBucketScore, bestBucketName = -math.huge, nil
	for name, scoreFunc in pairs(self.UtilityBuckets) do
		bucketTraces[name] = {}
		local score = scoreFunc(self, ctx, bucketTraces[name])
		bucketScores[name] = score

		if score > bestBucketScore then
			bestBucketScore = score
			bestBucketName = name
		end
	end

	local bucketMembers = self.BucketStates[bestBucketName]

	local scores, traces = {}, {}
	local bestScore, bestName = -math.huge, nil
	for _, name in ipairs(bucketMembers) do
		local onCooldown = CurTime() < (self.GlobalContext.CooldownUntil[name] or 0)

		traces[name] = {}

		if onCooldown then
			scores[name] = 0
		else
			local score = self.UtilityScores[name](self, ctx, traces[name])
			scores[name] = score
		end

		if scores[name] > bestScore then
			bestScore = scores[name]
			bestName = name
		end
	end

	local candidates = {}
	for name, score in pairs(scores) do
		if score >= bestScore - STATE_MARGIN then
			table.insert(candidates, name)
		end
	end

	-- store bucket scores to debug
	self.GlobalContext.DebugBucketScores = bucketScores
	self.GlobalContext.DebugBucketTraces = bucketTraces
	self.GlobalContext.DebugBestBucket = bestBucketName

	-- store state scores to debug
	self.GlobalContext.DebugScores = scores
	self.GlobalContext.DebugTraces = traces
	self.GlobalContext.DebugBest = bestName

	-- debug timers
	self.GlobalContext.DebugCooldown = self.GlobalContext.CooldownUntil

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
