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

	local close = Consider(ctx.Distance, 0, SIGHT_RANGE, Curves.LinearInverse)
	local memory = Consider(ctx.LastSeenAge, 0, MEMORY_DUR, function(x)
		return Curves.SmoothStepInverseOut(x, 3)
	end)

	if trace then
		trace.Close = close
		trace.Memory = memory
	end

	return WeightedGeoMean({
		{ score = close, weight = 1 },
		{ score = memory, weight = 1.4 },
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
