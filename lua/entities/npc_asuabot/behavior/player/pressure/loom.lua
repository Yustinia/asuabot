local DIST = 100
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
	sc.Appeared = false
	sc.InSequence = true

	self:HandleSpeed(0, 0)
	local path = self.GlobalContext.Path
	if path and path:IsValid() then
		path:Invalidate()
	end

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local side = math.random(2) == 1 and 1 or -1
	local yaw = target:EyeAngles().y + EDGE_ANGLE * side
	local pos = target:GetPos() + Angle(0, yaw, 0):Forward() * DIST

	local area = navmesh.GetNearestNavArea(pos)
	if not IsValid(area) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	self:Teleport(area:GetClosestPointOnArea(pos))
	sc.Appeared = true
end

ENT.StateUpdate.Loom = function(self, ctx)
	local sc = self.StateContext

	if not ctx.PlayerStill then
		sc.InSequence = false
		sc.Done = true
	end
end

ENT.StateExit.Loom = function(self)
	if not self.StateContext.Appeared then
		return
	end

	local path = self.GlobalContext.Path
	if path and path:IsValid() then
		path:Invalidate()
	end

	local nav = self:FindRandomNavArea()
	if nav then
		self:Teleport(nav)
	end
end
