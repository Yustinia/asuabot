local SPEED = 700
local SEEN_SPEED_MULT = 0.3
local ACCEL = 900
local MIN_LOOK_AHEAD = 120
local GOAL_THRESH = 0
local START_RANGE = 3000
local CATCH_RADIUS = 150
local PULL_FORCE = 2400

ENT.StateRules.Shadow = {
	min = 6,
	max = 45,
	cd = 100,
	needsTarget = true,
	block = { "Creep" },
}

ENT.UtilityScores.Shadow = function(self, ctx, trace)
	if not ctx.TargetValid or ctx.Distance > START_RANGE or ctx.Distance <= CATCH_RADIUS then
		return 0
	end

	local wounded = math.max(
		Consider(ctx.HealthFrac, 0, 1, function(x)
			return Curves.SmoothStepOut(x, 2)
		end),
		0.25
	)
	local range = Consider(ctx.Distance, CATCH_RADIUS, START_RANGE, function(x)
		return Curves.PowerInverseIn(x, 2)
	end)
	local unseen = ctx.Observe and 0.4 or 1
	local moving = math.max(Consider(ctx.PlayerSpeed, 0, 250, Curves.Linear), 0.3)

	if trace then
		trace.Wounded = wounded
		trace.Range = math.max(range, 0.2)
		trace.Unseen = unseen
		trace.Moving = moving
	end

	return WeightedGeoMean({
		{ score = wounded, weight = 1.4 },
		{ score = math.max(range, 0.2), weight = 0.8 },
		{ score = unseen, weight = 1 },
		{ score = moving, weight = 0.8 },
	})
end

ENT.StateEnter.Shadow = function(self)
	local gl, sc = self:ReturnContext()

	sc.Caught = false
	sc.Slowed = false

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

ENT.StateUpdate.Shadow = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not ctx.TargetValid then
		sc.Done = true
		return
	end

	if ctx.Distance <= CATCH_RADIUS then
		sc.Caught = true
		sc.Done = true

		return
	end

	if ctx.Visible and PULL_FORCE and PULL_FORCE > 0 then
		self:DragEntity(ctx.Target, PULL_FORCE)
	end

	local seen = ctx.Visible and true or false
	if seen ~= sc.Slowed then
		sc.Slowed = seen
		self:HandleSpeed(seen and SPEED * SEEN_SPEED_MULT or SPEED, ACCEL)
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
	self:RefreshPathIfStale(ctx.Target, "Chase")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Shadow = function(self)
	local gl, sc = self:ReturnContext()

	if not self.StateContext.Caught then
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
