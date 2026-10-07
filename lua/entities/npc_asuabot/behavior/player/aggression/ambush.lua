local SPEED = 3000
local ACCEL = 4000
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 0
local DAMAGE = 20
local TRIGGER_RANGE = 800

ENT.StateRules.Ambush = {
	min = 4,
	max = 4,
	cd = 320,
	needsTarget = true,
}

ENT.UtilityScores.Ambush = function(self, ctx, trace)
	if not ctx.TargetValid or not self.GlobalContext.Concealed then
		return 0
	end

	local within = ctx.Distance <= TRIGGER_RANGE

	if not (ctx.Visible or within) then
		return 0
	end

	if trace then
		trace.Visible = ctx.Visible and 1 or 0
		trace.Within = within and 1 or 0
	end

	return 1
end

ENT.StateEnter.Ambush = function(self)
	self:HandleSpeed(SPEED, ACCEL)

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Ambush = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
		return
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
		self:PunchEntity(ctx.Target)
		self.StateContext.Done = true
		return
	end

	self:RefreshPathIfStale(ctx.Target, "Chase")
	path:Update(self)
	self:ClearObstacles()
end
