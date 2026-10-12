local SPEED = 2500
local ACCEL = 3500
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 0
local DAMAGE = 20
local TRIGGER_RANGE = 2500

ENT.StateRules.Blink = {
	min = 20,
	max = 45,
	cd = 100,
	needsTarget = true,
	block = { "Chase", "Rush", "Charge", "Pounce", "Ambush" },
}

ENT.UtilityScores.Blink = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local close = Consider(ctx.Distance, 0, TRIGGER_RANGE, Curves.LinearInverse)

	if trace then
		trace.Close = close
	end

	return WeightedGeoMean({
		{ score = close, weight = 1 },
	})
end

ENT.StateEnter.Blink = function(self)
	local gl, sc = self:ReturnContext()

	sc.Frozen = nil

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.Done = true
		return
	end

	self:ComputeRoutingPath(gl.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Blink = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not ctx.TargetValid then
		sc.Done = true
		return
	end

	local seen = self:IsPlayerLookingAtBot(ctx.Target)
	if seen ~= sc.Frozen then
		sc.Frozen = seen
		gl.ProgressPosition = nil

		if seen then
			self:HandleSpeed(0, 0)
		else
			self:HandleSpeed(SPEED, ACCEL)
		end
	end

	if seen then
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

ENT.StateExit.Blink = function(self)
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
