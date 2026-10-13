local SPEED = 3000
local ACCEL = 4000
local MIN_RAD = 1400
local MAX_RAD = 1900
local START_RANGE = 2500
local MIN_LOOK_AHEAD = 100
local GOAL_THRESH = 60
local STRIKE_THRESH = 0
local DAMAGE = 20
local TRIGGER_RANGE = 800
local WAIT_DUR = 30 -- wait at position for 30s
local STRIKE_DUR = 4 -- how long strike sequence happens

local function PhaseChange(gl, sc, phaseName)
	sc.Phase = phaseName
	gl.ProgressPosition = nil
end

local Phases = {}

Phases.hide = function(self, ctx, gl, sc)
	if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
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

	self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	self:RefreshPathIfStale(sc.Goal, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()

	self:EmitLoop(ctx.Target, "Asuabot.Foley")
end

Phases.wait = function(self, ctx, gl, sc)
	if ctx.Visible or ctx.Distance <= TRIGGER_RANGE then
		PhaseChange(gl, sc, "strike")

		sc.StrikeUntil = CurTime() + STRIKE_DUR

		self:HandleSpeed(SPEED, ACCEL)
		self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, STRIKE_THRESH, "Chase")

		return
	end

	if CurTime() >= sc.WaitUntil then
		sc.InSequence = false
		sc.Done = true
	end

	ctx.Target:StopSound("Asuabot.Foley")
	self:EmitLoop(ctx.Target, "Asuabot.Ambiance")
end

Phases.strike = function(self, ctx, gl, sc)
	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
		self:PunchEntity(ctx.Target)

		sc.InSequence = false
		sc.Done = true
		sc.Caught = true

		ctx.Target:EmitSound("Asuabot.Slam")
		return
	end

	if CurTime() >= sc.StrikeUntil then
		sc.InSequence = false
		sc.Done = true
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, STRIKE_THRESH, "Chase")
	self:RefreshPathIfStale(ctx.Target, "Chase")
	gl.Path:Update(self)
	self:ClearObstacles()

	ctx.Target:StopSound("Asuabot.Ambiance")
	self:EmitLoop(ctx.Target, "Asuabot.Jumpscare")
end

ENT.StateRules.Ambush = {
	min = 10,
	max = 60,
	cd = 320,
	needsTarget = true,
	block = { "Chase", "Rush", "Charge", "Blink", "Pounce", "Peek" },
}

ENT.UtilityScores.Ambush = function(self, ctx, trace)
	if not ctx.TargetValid or ctx.Distance > START_RANGE then
		return 0
	end

	local range = Consider(ctx.Distance, 0, START_RANGE, function(x)
		return Curves.Bell(x, 0.7, 0.25)
	end)
	local moving = math.max(Consider(ctx.PlayerSpeed, 0, 300, Curves.Linear), 0.2)
	local unseen = ctx.Observe and 0.3 or 1
	local enclosed = ctx.PlayerEnclosed and 1 or 0.5

	if trace then
		trace.Range = range
		trace.Moving = moving
		trace.Unseen = unseen
		trace.Enclosed = enclosed
	end

	return WeightedGeoMean({
		{ score = range, weight = 1 },
		{ score = moving, weight = 1.2 },
		{ score = unseen, weight = 1 },
		{ score = enclosed, weight = 0.8 },
	})
end

ENT.StateEnter.Ambush = function(self)
	local gl, sc = self:ReturnContext()

	sc.Phase = "none"
	sc.Goal = nil
	sc.InSequence = true

	if not IsValid(gl.Target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local goal = self:FindPosInRangeWithoutLOS(MIN_RAD, MAX_RAD, gl.Target)
	if not goal then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.Goal = goal
	sc.Phase = "hide"

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")

	gl.Target:EmitSound("Asuabot.Screech")
end

ENT.StateUpdate.Ambush = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if sc.Done then
		return
	end

	Phases[sc.Phase](self, ctx, gl, sc)
end

ENT.StateExit.Ambush = function(self)
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

	gl.Target:StopSound("Asuabot.Jumpscare")
	gl.Target:StopSound("Asuabot.Ambiance")
	gl.Target:StopSound("Asuabot.Foley")
end
