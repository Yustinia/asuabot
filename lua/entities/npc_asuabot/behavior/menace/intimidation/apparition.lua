local SPEED = 600
local ACCEL = 800
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 0
local MIN_RADIUS = 400
local MAX_RADIUS = 600
local SEEN_DELAY = 1
local LOOK_THRESHOLD = 0.966
local DAMAGE = 2

ENT.StateRules.Apparition = {
	min = 15,
	max = 25,
	cd = 120,
	needsTarget = true,
}

ENT.UtilityScores.Apparition = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	if trace then
		trace.Distance = ctx.Distance
	end

	return 0.6
end

ENT.StateEnter.Apparition = function(self)
	local sc = self.StateContext
	sc.SeenSince = nil

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	self:HandleSpeed(SPEED, ACCEL)

	local spot = self:FindPositionBehindTarget(target, MIN_RADIUS, MAX_RADIUS)
	if spot then
		self:SetPos(spot)
	end

	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Apparition = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	local sc = self.StateContext

	if self:IsPlayerLookingAtBot(ctx.Target, LOOK_THRESHOLD) then
		sc.SeenSince = sc.SeenSince or CurTime()

		if CurTime() - sc.SeenSince >= SEEN_DELAY then
			sc.SeenSince = nil

			local spot = self:FindPositionBehindTarget(ctx.Target, MIN_RADIUS, MAX_RADIUS)
			if spot then
				self:SetPos(spot)
				self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
			end
			return
		end
	else
		sc.SeenSince = nil
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
	end

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
		return
	end

	self:RefreshPathIfStale(ctx.Target, "Chase")
	path:Update(self)
	self:ClearObstacles()
end
