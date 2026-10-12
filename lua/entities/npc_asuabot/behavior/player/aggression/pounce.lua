local SPEED = 10000
local ACCEL = 10000
local MIN_LOOK_AHEAD = 60
local GOAL_THRESH = 60
local DAMAGE = 20
local SIGHT_RANGE = 1800
local WAIT_DUR = 3 -- wait until next pounce
local LEAP_TIMEOUT = 2

local function PhaseChange(gl, sc, phaseName)
	sc.Phase = phaseName
	gl.ProgressPosition = nil
end

local Phases = {}

Phases.leap = function(self, ctx, gl, sc)
	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
		self:PunchEntity(ctx.Target)
		self:HandleSpeed(0, 0)
		sc.Done = true
		sc.Caught = true
		return
	end

	if self:IsAtPosition(sc.LockedPos, GOAL_THRESH) or CurTime() >= sc.LeapUntil then
		self:HandleSpeed(0, 0)

		if gl.Path and gl.Path:IsValid() then
			gl.Path:Invalidate()
		end

		PhaseChange(gl, sc, "wait")

		sc.WaitUntil = CurTime() + WAIT_DUR
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(sc.LockedPos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	self:RefreshPathIfStale(sc.LockedPos, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

Phases.wait = function(self, ctx, gl, sc)
	if CurTime() < sc.WaitUntil then
		return
	end

	sc.LockedPos = ctx.Target:GetPos()
	sc.LeapUntil = CurTime() + LEAP_TIMEOUT

	PhaseChange(gl, sc, "leap")

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(sc.LockedPos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateRules.Pounce = {
	min = 14,
	max = 20,
	cd = 80,
	needsTarget = true,
	block = { "Chase", "Rush", "Charge", "Blink", "Ambush", "Feint" },
}

ENT.UtilityScores.Pounce = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	local close = Consider(ctx.Distance, 0, SIGHT_RANGE, Curves.LinearInverse)
	local moving = math.max(Consider(ctx.PlayerSpeed, 0, 300, Curves.Linear), 0.2)

	if trace then
		trace.Close = close
		trace.Moving = moving
	end

	return WeightedGeoMean({
		{ score = close, weight = 1 },
		{ score = moving, weight = 1.2 },
	})
end

ENT.StateEnter.Pounce = function(self)
	local gl, sc = self:ReturnContext()

	sc.Phase = "none"

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		return
	end

	sc.LockedPos = gl.Target:GetPos()
	sc.LeapUntil = CurTime() + LEAP_TIMEOUT
	sc.Phase = "leap"

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(sc.LockedPos, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Pounce = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if sc.Phase == "none" or not ctx.TargetValid then
		sc.Done = true
		return
	end

	Phases[sc.Phase](self, ctx, gl, sc)
end

ENT.StateExit.Pounce = function(self)
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
