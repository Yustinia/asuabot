local SPEED = 3000
local ACCEL = 10000
local MIN_LOOK_AHEAD = 60
local GOAL_THRESH = 0
local STOP_DIST = 20
local START_RANGE = 1500
local HOLD_DUR = 3

local function PhaseChange(gl, sc, phaseName)
	sc.Phase = phaseName
	gl.ProgressPosition = nil
end

local Phases = {}

Phases.dash = function(self, ctx, gl, sc)
	if ctx.Distance <= STOP_DIST then
		self:HandleSpeed(0, 0)

		if gl.Path and gl.Path:IsValid() then
			gl.Path:Invalidate()
		end

		PhaseChange(gl, sc, "hold")

		sc.HoldUntil = CurTime() + HOLD_DUR
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

Phases.hold = function(self, ctx, gl, sc)
	if CurTime() >= sc.HoldUntil then
		sc.InSequence = false
		sc.Done = true
	end
end

ENT.StateRules.Feint = {
	min = 4,
	max = 12,
	cd = 60,
	needsTarget = true,
	block = { "Pounce", "Charge", "Rush" },
}

ENT.UtilityScores.Feint = function(self, ctx, trace)
	if not ctx.TargetValid or not ctx.Visible then
		return 0
	end

	if ctx.Distance <= STOP_DIST or ctx.Distance > START_RANGE then
		return 0
	end

	local range = math.max(
		Consider(ctx.Distance, STOP_DIST, START_RANGE, function(x)
			return Curves.Bell(x, 0.5, 0.3)
		end),
		0.2
	)
	local watched = ctx.Observe and 1 or 0.4
	local room = ctx.PlayerInOpen and 1 or 0.6
	local healthy = math.max(Consider(ctx.HealthFrac, 0, 1, Curves.Linear), 0.4)

	if trace then
		trace.Range = range
		trace.Watched = watched
		trace.Room = room
		trace.Healthy = healthy
	end

	return WeightedGeoMean({
		{ score = range, weight = 1 },
		{ score = watched, weight = 1.3 },
		{ score = room, weight = 0.8 },
		{ score = healthy, weight = 0.6 },
	})
end

ENT.StateEnter.Feint = function(self)
	local gl, sc = self:ReturnContext()

	sc.Phase = "none"
	sc.HoldUntil = 0
	sc.InSequence = true

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.Phase = "dash"

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(gl.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Feint = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if sc.Phase == "none" or not ctx.TargetValid then
		sc.InSequence = false
		sc.Done = true
		return
	end

	Phases[sc.Phase](self, ctx, gl, sc)
end

ENT.StateExit.Feint = function(self)
	local gl, sc = self:ReturnContext()

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end
end
