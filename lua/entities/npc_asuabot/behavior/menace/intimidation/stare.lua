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

	self:HandleSpeed(0, 0)
	local path = self.GlobalContext.Path
	if path and path:IsValid() then
		path:Invalidate()
	end

	local target = self.GlobalContext.Target
	if not IsValid(target) then
		return
	end

	local spot = self:FindPositionBehindTarget(target, MIN_RADIUS, MAX_RADIUS)
	if not spot then
		sc.Done = true
		return
	end

	self:SetPos(spot)
end

ENT.StateUpdate.Stare = function(self, ctx)
	if not ctx.TargetValid then
		return
	end

	local sc = self.StateContext
	local looking = self:IsPlayerLookingAtBot(ctx.Target)

	if not sc.Seen then
		if looking then
			sc.Seen = true
		end
		return
	end

	if not looking then
		local nav = self:FindRandomNavArea()
		if nav then
			self:Teleport(nav)
		end
		sc.Done = true
	end
end
