local SPEED = 2400
local ACCEL = 1600
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 0
local DAMAGE = 20
local SIGHT_RANGE = 1500
local MEMORY_DUR = 5

ENT.StateRules.Rush = {
	min = 10,
	max = 18,
	cd = 80,
	needsTarget = true,
	block = { "Chase", "Charge", "Pounce", "Blink", "Ambush" },
}

ENT.UtilityScores.Rush = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local range = math.max(
		Consider(ctx.Distance, 0, SIGHT_RANGE, function(x)
			return Curves.Bell(x, 0.4, 0.25)
		end),
		0.15
	)
	local memory = Consider(ctx.LastSeenAge, 0, MEMORY_DUR, function(x)
		return Curves.SmoothStepInverseOut(x, 3)
	end)
	local watched = ctx.Observe and 1 or 0.6
	local wounded = math.max(
		Consider(ctx.HealthFrac, 0, 1, function(x)
			return Curves.SmoothStepOut(x, 2)
		end),
		0.4
	)

	if trace then
		trace.Range = range
		trace.Memory = memory
		trace.Watched = watched
		trace.Wounded = wounded
	end

	return WeightedGeoMean({
		{ score = range, weight = 1 },
		{ score = memory, weight = 1.4 },
		{ score = watched, weight = 0.8 },
		{ score = wounded, weight = 0.8 },
	})
end

ENT.StateEnter.Rush = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		return
	end

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(gl.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Rush = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not ctx.TargetValid then
		sc.Done = true
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
		self:PunchEntity(ctx.Target)
		self.StateContext.Done = true
		self.StateContext.Caught = true
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

ENT.StateExit.Rush = function(self)
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
