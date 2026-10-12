local SPEED = 600
local ACCEL = 800
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 0
local MIN_RADIUS = 400
local MAX_RADIUS = 600
local SEEN_DELAY = 1
local LOOK_THRESHOLD = 0.966
local DAMAGE = 2

local function Reappear(self, target)
	local spot = self:FindPositionBehindTarget(target, MIN_RADIUS, MAX_RADIUS)
	if spot then
		self:Teleport(spot)
	end

	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateRules.Apparition = {
	min = 15,
	max = 25,
	cd = 120,
	needsTarget = true,
	block = { "Loom", "Stare" },
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
	local gl, sc = self:ReturnContext()

	sc.SeenSince = nil

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.Done = true
		return
	end

	self:HandleSpeed(SPEED, ACCEL)
	Reappear(self, gl.Target)
end

ENT.StateUpdate.Apparition = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not ctx.TargetValid then
		sc.Done = true
		return
	end

	if self:IsPlayerLookingAtBot(ctx.Target, LOOK_THRESHOLD) then
		sc.SeenSince = sc.SeenSince or CurTime()

		if CurTime() - sc.SeenSince >= SEEN_DELAY then
			sc.SeenSince = nil

			Reappear(self, ctx.Target)
			return
		end
	else
		sc.SeenSince = nil
	end

	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
	self:RefreshPathIfStale(ctx.Target, "Chase")
	gl.Path:Update(self)
	self:ClearObstacles()
end
