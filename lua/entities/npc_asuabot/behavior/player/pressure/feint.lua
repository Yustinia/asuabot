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
	if trace then
		trace.Distance = ctx.Distance
		trace.Visible = ctx.Visible and 1 or 0
	end

	-- needs the player in view, and room to dash before stopping
	if not ctx.TargetValid or not ctx.Visible then
		return 0
	end

	if ctx.Distance <= STOP_DIST or ctx.Distance > START_RANGE then
		return 0
	end

	return 0.65
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
