local SPEED = 500
local ACCEL = 500
local MIN_LOOK_AHEAD = 80
local GOAL_THRESH = 0
local CRUMB_THRESH = 60
local CRUMB_DIST = 150
local SEEN_DELAY = 1
local START_RANGE = 2500
local DAMAGE = 20

ENT.StateRules.Creep = {
	min = 6,
	max = 40,
	cd = 120,
	needsTarget = true,
	block = { "Shadow", "Apparition" },
}

ENT.UtilityScores.Creep = function(self, ctx, trace)
	if trace then
		trace.Distance = ctx.Distance
		trace.Observe = ctx.Observe and 1 or 0
	end

	if not ctx.TargetValid or ctx.Observe or ctx.Distance > START_RANGE then
		return 0
	end

	return 0.6
end

ENT.StateEnter.Creep = function(self)
	local sc = self.StateContext
	sc.Phase = "none"
	sc.Crumbs = {}
	sc.SeenSince = nil
	sc.Caught = false
	sc.InSequence = true

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.Crumbs[1] = self:GetPos()
	sc.Phase = "approach"
	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(target, MIN_LOOK_AHEAD, GOAL_THRESH, "Chase")
end

ENT.StateUpdate.Creep = function(self, ctx)
	local sc = self.StateContext

	if sc.Done or sc.Phase == "none" or not ctx.TargetValid then
		return
	end

	local path = self.GlobalContext.Path
	local mutual = ctx.Observe and ctx.Visible

	if sc.Phase == "approach" then
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
				sc.Phase = "back"
				self:ComputeRoutingPath(sc.Crumbs[#sc.Crumbs], MIN_LOOK_AHEAD, CRUMB_THRESH, "Follow")
				return
			end
		else
			sc.SeenSince = nil
		end

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
		return
	end

	if sc.Phase == "back" then
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

		if not path or not path:IsValid() then
			self:ComputeRoutingPath(goal, MIN_LOOK_AHEAD, CRUMB_THRESH, "Follow")
			return
		end

		if self:HandleStuckCheck() then
			return
		end

		self:RefreshPathIfStale(goal, "Follow")
		path:Update(self)
		self:ClearObstacles()
	end
end

ENT.StateExit.Creep = function(self)
	if self.StateContext.Caught then
		local path = self.GlobalContext.Path
		if path and path:IsValid() then
			path:Invalidate()
		end

		local nav = self:FindRandomNavArea()
		if nav then
			self:Teleport(nav)
		end
	end
end
