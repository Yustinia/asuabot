local SPEED = 30000
local ACCEL = 1000
local MIN_LOOK_AHEAD = 200
local GOAL_THRESH = 0
local DAMAGE = 25
local TRIGGER_MIN = 800
local TRIGGER_MAX = 2500

ENT.StateRules.Charge = {
	min = 18,
	max = 25,
	cd = 60,
	needsTarget = true,
	block = { "Chase", "Rush", "Pounce", "Blink", "Ambush" },
}

ENT.UtilityScores.Charge = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local range = math.max(
		Consider(ctx.Distance, TRIGGER_MIN - 600, TRIGGER_MAX + 600, function(x)
			return Curves.Bell(x, 0.3, 0.25)
		end),
		0.1
	)
	local clear = ctx.PlayerInOpen and 1 or (ctx.PlayerEnclosed and 0.4 or 0.7)
	local watched = ctx.Observe and 1 or 0.7
	local unarmed = ctx.HoldingRanged and 0.5 or 1

	if trace then
		trace.Range = range
		trace.Clear = clear
		trace.Watched = watched
		trace.Unarmed = unarmed
	end

	return WeightedGeoMean({
		{ score = range, weight = 1 },
		{ score = clear, weight = 1 },
		{ score = watched, weight = 0.6 },
		{ score = unarmed, weight = 0.8 },
	})
end

ENT.StateEnter.Charge = function(self)
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

ENT.StateUpdate.Charge = function(self, ctx)
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

ENT.StateExit.Charge = function(self)
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
