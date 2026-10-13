local SPEED = 1800
local ACCEL = 3000
local SCAN_RADIUS = 2000
local MIN_LOOK_AHEAD = 80
local GOAL_THRESH = 60
local TRIGGER_RANGE = 500
local LOOK_THRESHOLD = 0.966
local MAX_START_DIST = 2000
local OUT_DUR = 20

local function PhaseChange(gl, sc, phaseName)
	sc.Phase = phaseName
	gl.ProgressPosition = nil
end

local Phases = {}

-- go to the hiding position
Phases.hide = function(self, ctx, gl, sc)
	if self:IsAtPosition(sc.HideSpot, GOAL_THRESH) then
		PhaseChange(gl, sc, "out")

		sc.OutUntil = CurTime() + OUT_DUR
		self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	self:RefreshPathIfStale(sc.HideSpot, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

-- bot chases the player
Phases.out = function(self, ctx, gl, sc)
	if ctx.Visible then
		PhaseChange(gl, sc, "watch")

		self:HandleSpeed(0, 0)

		if gl.Path and gl.Path:IsValid() then
			gl.Path:Invalidate()
		end

		return
	end

	if CurTime() >= sc.OutUntil then
		PhaseChange(gl, sc, "back")

		self:HandleSpeed(SPEED, ACCEL)
		self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
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

-- bot watching player
Phases.watch = function(self, ctx, gl, sc)
	local close = ctx.Distance <= TRIGGER_RANGE
	local looked = self:IsPlayerLookingAtBot(ctx.Target, LOOK_THRESHOLD)

	if close or looked or CurTime() >= sc.OutUntil then
		PhaseChange(gl, sc, "back")

		self:HandleSpeed(SPEED, ACCEL)
		self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	end
end

-- bot returning to hide position
Phases.back = function(self, ctx, gl, sc)
	if self:IsAtPosition(sc.HideSpot, GOAL_THRESH) then
		sc.Vanish = true
		sc.InSequence = false
		sc.Done = true
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(sc.HideSpot, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
	self:RefreshPathIfStale(sc.HideSpot, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateRules.Peek = {
	min = 8,
	max = 90,
	cd = 200,
	needsTarget = true,
	block = { "Hide", "Ambush" },
}

ENT.UtilityScores.Peek = function(self, ctx, trace)
	if not ctx.TargetValid or ctx.Distance > MAX_START_DIST then
		return 0
	end

	local range = Consider(ctx.Distance, 0, MAX_START_DIST, function(x)
		return Curves.Bell(x, 0.65, 0.3)
	end)
	local unseen = ctx.Observe and 0.3 or 1
	local moving = math.max(Consider(ctx.PlayerSpeed, 0, 250, Curves.Linear), 0.3)
	local cover = ctx.PlayerInOpen and 0.3 or 1
	local fresh = math.max(Consider(ctx.LastSeenAge, 0, 30, Curves.Linear), 0.3)

	if trace then
		trace.Range = range
		trace.Unseen = unseen
		trace.Moving = moving
		trace.Cover = cover
		trace.Fresh = fresh
	end

	return WeightedGeoMean({
		{ score = range, weight = 1 },
		{ score = unseen, weight = 1.2 },
		{ score = moving, weight = 0.8 },
		{ score = cover, weight = 1 },
		{ score = fresh, weight = 0.8 },
	})
end

ENT.StateEnter.Peek = function(self)
	local gl, sc = self:ReturnContext()

	sc.Phase = "none"
	sc.HideSpot = nil
	sc.OutUntil = 0
	sc.Vanish = false
	sc.InSequence = true

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local goal = self:FindClosePosWithoutLOS(SCAN_RADIUS, gl.Target)
	if not goal then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.HideSpot = goal
	sc.Phase = "hide"

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Peek = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if sc.Phase == "none" or not ctx.TargetValid then
		sc.Done = true
		sc.InSequence = false
		return
	end

	Phases[sc.Phase](self, ctx, gl, sc)
end

ENT.StateExit.Peek = function(self)
	local gl, sc = self:ReturnContext()

	if not sc.Vanish then
		return
	end

	if gl.Path or gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	local nav = self:FindRandomNavArea()
	if nav then
		self:Teleport(nav)
	end
end
