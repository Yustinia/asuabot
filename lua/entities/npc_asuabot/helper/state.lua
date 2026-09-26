local STATE_MARGIN = 0.08

function ENT:SampleContext()
	local ctx = {}

	if not IsValid(self.GlobalContext.Target) then
		self.GlobalContext.Target = self:FindClosestPlayer()
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

	ctx.SeenAge = CurTime() - self.GlobalContext.TargetLastSeenTime
	ctx.CurrentState = self.GlobalContext.CurrentState
	ctx.StateTime = CurTime() - self.GlobalContext.StateStartTime

	return ctx
end

function ENT:SelectState(ctx)
	local scores, traces = {}, {}
	local bestScore, bestName = -math.huge, nil

	for name, scoreFunc in pairs(self.UtilityScores) do
		local onCooldown = CurTime() < (self.GlobalContext.CooldownUntil[name] or 0)

		if onCooldown then
			scores[name] = 0
		else
			traces[name] = {}
			scores[name] = scoreFunc(self, ctx, traces[name])
		end

		if scores[name] > bestScore then
			bestScore = scores[name]
			bestName = name
		end
	end

	-- debug data
	self.GlobalContext.DebugScores = scores
	self.GlobalContext.DebugBest = bestName
	self.GlobalContext.DebugTraces = traces
	self.GlobalContext.DebugCD = self.GlobalContext.CooldownUntil

	local sweep = self.StateContext.Sweep
	self.GlobalContext.DebugSweepIndex = sweep and sweep.CurrentIndex or 0
	self.GlobalContext.DebugSweepTotal = sweep and #sweep.SweepPoints or 0

	self.GlobalContext.DebugLastSeenPositions = self.GlobalContext.LastSeenTargetPositions
	-- debug data

	local candidates = {}
	for name, score in pairs(scores) do
		if score >= bestScore - STATE_MARGIN then
			table.insert(candidates, name)
		end
	end

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
