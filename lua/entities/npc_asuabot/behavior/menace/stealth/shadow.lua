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
	if trace then
		trace.Distance = ctx.Distance
		trace.Visible = ctx.Visible and 1 or 0
	end

	if not ctx.TargetValid or ctx.Distance > START_RANGE or ctx.Distance <= CATCH_RADIUS then
		return 0
	end

	return 0.55
end

ENT.StateEnter.Shadow = function(self)
	local sc = self.StateContext
	sc.Caught = false
	sc.Slowed = false

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.Done = true
		return
	end

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Shadow = function(self, ctx)
	local sc = self.StateContext

	if sc.Done or not ctx.TargetValid then
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

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:RefreshPathIfStale(ctx.Target, "Chase")
	path:Update(self)
	self:ClearObstacles()
end

ENT.StateExit.Shadow = function(self)
	if not self.StateContext.Caught then
		return
	end

	local path = self.GlobalContext.Path
	if path and path:IsValid() then
		path:Invalidate()
	end

	local nav = self:FindRandomNavArea()
	if nav then
		self:Teleport(nav)
	end
end
