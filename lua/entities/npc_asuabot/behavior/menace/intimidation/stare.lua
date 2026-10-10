local MIN_RADIUS = 200
local MAX_RADIUS = 400

ENT.StateRules.Stare = {
	min = 5,
	max = 30,
	cd = 90,
	needsTarget = true,
}

ENT.UtilityScores.Stare = function(self, ctx, trace)
	if not ctx.TargetValid then
		return 0
	end

	if trace then
		trace.Distance = ctx.Distance
	end

	return 0.6
end

ENT.StateEnter.Stare = function(self)
	local sc = self.StateContext
	sc.Seen = false
	sc.Vanish = false

	self:HandleSpeed(0, 0)
	local path = self.GlobalContext.Path
	if path and path:IsValid() then
		path:Invalidate()
	end

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		sc.Done = true
		return
	end

	local spot = self:FindPositionBehindTarget(target, MIN_RADIUS, MAX_RADIUS)
	if not spot then
		sc.Done = true
		return
	end

	self:Teleport(spot)
end

ENT.StateUpdate.Stare = function(self, ctx)
	local sc = self.StateContext
	if sc.Done or not ctx.TargetValid then
		return
	end

	local looking = self:IsPlayerLookingAtBot(ctx.Target)

	if not sc.Seen then
		if looking then
			sc.Seen = true
		end
		return
	end

	if not looking then
		sc.Vanish = true
		sc.Done = true
	end
end

ENT.StateExit.Stare = function(self)
	if not self.StateContext.Vanish then
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
