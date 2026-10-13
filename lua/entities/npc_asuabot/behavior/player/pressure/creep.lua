local SPEED = 500
local ACCEL = 500
local MIN_LOOK_AHEAD = 80
local GOAL_THRESH = 0
local CRUMB_THRESH = 60
local CRUMB_DIST = 150
local SEEN_DELAY = 1
local START_RANGE = 2500
local DAMAGE = 20

local function PhaseChange(gl, sc, phaseName)
	sc.Phase = phaseName
	gl.ProgressPosition = nil
end

local Phases = {}

Phases.approach = function(self, ctx, gl, sc, mutual)
	if ctx.Touching then
		self:DamageEntity(ctx.Target, DAMAGE)
		self:PunchEntity(ctx.Target)
		sc.Caught = true
		sc.InSequence = false
		sc.Done = true
		return
	end

	local last = sc.Crumbs[#sc.Crumbs]
	if self:GetPos():Distance(last) >= CRUMB_DIST then
		sc.Crumbs[#sc.Crumbs + 1] = self:GetPos()
	end

	if mutual then
		sc.SeenSince = sc.SeenSince or CurTime()

		if CurTime() - sc.SeenSince >= SEEN_DELAY then
			PhaseChange(gl, sc, "back")

			self:ComputeRoutingPath(sc.Crumbs[#sc.Crumbs], MIN_LOOK_AHEAD, CRUMB_THRESH, "Follow")
			return
		end
	else
		sc.SeenSince = nil
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(ctx.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
	self:RefreshPathIfStale(ctx.Target, "Chase")
	gl.Path:Update(self)
	self:ClearObstacles()
end

Phases.back = function(self, ctx, gl, sc, mutual)
	if not mutual then
		sc.Caught = true
		sc.InSequence = false
		sc.Done = true
		return
	end

	local goal = sc.Crumbs[#sc.Crumbs]

	if not goal then
		sc.Caught = true
		sc.InSequence = false
		sc.Done = true
		return
	end

	if self:IsAtPosition(goal, CRUMB_THRESH) then
		sc.Crumbs[#sc.Crumbs] = nil

		local nextGoal = sc.Crumbs[#sc.Crumbs]
		if nextGoal then
			self:ComputeRoutingPath(nextGoal, MIN_LOOK_AHEAD, CRUMB_THRESH, "Follow")
		end
		return
	end

	if self:HandleStuckCheck() then
		return
	end

	self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, CRUMB_THRESH, "Follow")
	self:RefreshPathIfStale(goal, "Follow")
	gl.Path:Update(self)
	self:ClearObstacles()
end

ENT.StateRules.Creep = {
	min = 6,
	max = 40,
	cd = 120,
	needsTarget = true,
	block = { "Shadow", "Apparition" },
}

ENT.UtilityScores.Creep = function(self, ctx, trace)
	if not ctx.TargetValid or ctx.Observe or ctx.Distance > START_RANGE then
		return 0
	end

	local range = math.max(Consider(ctx.Distance, 0, START_RANGE, Curves.LinearInverse), 0.2)
	local dark = ctx.Flashlight and 0.7 or 1
	local cover = ctx.PlayerInOpen and 0.5 or 1
	local distracted = math.max(Consider(ctx.PlayerSpeed, 0, 250, Curves.Linear), 0.4)

	if trace then
		trace.Range = range
		trace.Dark = dark
		trace.Cover = cover
		trace.Distracted = distracted
	end

	return WeightedGeoMean({
		{ score = range, weight = 1 },
		{ score = dark, weight = 0.7 },
		{ score = cover, weight = 1 },
		{ score = distracted, weight = 0.6 },
	})
end

ENT.StateEnter.Creep = function(self)
	local gl, sc = self:ReturnContext()

	sc.Phase = "none"
	sc.Crumbs = {}
	sc.SeenSince = nil
	sc.Caught = false
	sc.InSequence = true

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.Crumbs[1] = self:GetPos()
	sc.Phase = "approach"

	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(gl.Target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Creep = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if sc.Phase == "none" or not ctx.TargetValid then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local mutual = ctx.Observe and ctx.Visible

	Phases[sc.Phase](self, ctx, gl, sc, mutual)
end

ENT.StateExit.Creep = function(self)
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
