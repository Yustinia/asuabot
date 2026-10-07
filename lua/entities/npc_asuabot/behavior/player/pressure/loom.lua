local SPEED = 2400
local ACCEL = 3600
local MIN_LOOK_AHEAD = 60
local GOAL_THRESH = 40
local DIST = 150
local EDGE_ANGLE = 50
local STILL_REQUIRED = 1.5

ENT.StateRules.Loom = {
	min = 5,
	max = 40,
	cd = 120,
	needsTarget = true,
}

ENT.UtilityScores.Loom = function(self, ctx, trace)
	if trace then
		trace.StillFor = ctx.StillFor
	end

	if not ctx.TargetValid or ctx.StillFor < STILL_REQUIRED then
		return 0
	end

	return 0.8
end

ENT.StateEnter.Loom = function(self)
	local sc = self.StateContext
	sc.Goal = nil

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	local side = math.random(2) == 1 and 1 or -1
	local yaw = target:EyeAngles().y + EDGE_ANGLE * side
	local pos = target:GetPos() + Angle(0, yaw, 0):Forward() * DIST

	local area = navmesh.GetNearestNavArea(pos)
	if not IsValid(area) then
		sc.Done = true
		return
	end

	sc.Goal = area:GetClosestPointOnArea(pos)
	self:HandleSpeed(SPEED, ACCEL)
	self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
end

ENT.StateUpdate.Loom = function(self, ctx)
	local sc = self.StateContext

	if not ctx.PlayerStill then
		sc.Done = true
		return
	end

	if not sc.Goal then
		return
	end

	if self:IsAtPosition(sc.Goal, GOAL_THRESH) then
		self:HandleSpeed(0, 0)
		local path = self.GlobalContext.Path
		if path and path:IsValid() then
			path:Invalidate()
		end
		return
	end

	local path = self.GlobalContext.Path
	if not path or not path:IsValid() then
		self:ComputeRoutingPath(sc.Goal, MIN_LOOK_AHEAD, GOAL_THRESH, "Follow")
		return
	end

	self:RefreshPathIfStale(sc.Goal, "Follow")
	path:Update(self)
end

ENT.StateExit.Loom = function(self)
	local nav = self:FindRandomNavArea()
	if nav then
		self:Teleport(nav)
	end
end
