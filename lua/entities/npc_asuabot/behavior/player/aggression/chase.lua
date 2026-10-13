local SPEED = 1200
local ACCEL = 1000
local MIN_LOOK_AHEAD = 200
local GOAL_THRESH = 0
local DAMAGE = 20
local SIGHT_RANGE = 2000
local MEMORY_DUR = 5

ENT.StateRules.Chase = {
	min = 14,
	max = 20,
	cd = 75,
	needsTarget = true,
	block = { "Rush", "Charge", "Pounce", "Blink", "Ambush" },
}

ENT.UtilityScores.Chase = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local close = math.max(Consider(ctx.Distance, 0, SIGHT_RANGE, Curves.LinearInverse), 0.15)
	local memory = Consider(ctx.LastSeenAge, 0, MEMORY_DUR, function(x)
		return Curves.PowerInverseIn(x, 3)
	end)
	local open = ctx.PlayerEnclosed and 0.7 or 1

	if trace then
		trace.Close = close
		trace.Memory = memory
		trace.Open = open
	end

	return WeightedGeoMean({
		{ score = close, weight = 1 },
		{ score = memory, weight = 1.2 },
		{ score = open, weight = 0.4 },
	})
end

ENT.StateEnter.Chase = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.Done = true
		return
	end

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(gl.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Chase = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not ctx.TargetValid then
		sc.Done = true
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
		self:PunchEntity(ctx.Target)
		sc.Done = true
		sc.Caught = true
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
	self:RefreshPathIfStale(ctx.Target, "Chase")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Chase = function(self)
	local gl, sc = self:ReturnContext()

	if not sc.Caught then
		return
	end

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	local nav = self:FindRandomNavArea()
	if nav then
		self:Teleport(nav)
	end
end
