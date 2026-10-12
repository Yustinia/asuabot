local MIN_RADIUS = 200
local MAX_RADIUS = 400

ENT.StateRules.Stare = {
	min = 5,
	max = 30,
	cd = 90,
	needsTarget = true,
	block = { "Loom", "Apparition" },
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
	local gl, sc = self:ReturnContext()

	sc.Seen = false
	sc.Vanish = false

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.Done = true
		return
	end

	local spot = self:FindPositionBehindTarget(gl.Target, MIN_RADIUS, MAX_RADIUS)
	if not spot then
		sc.Done = true
		return
	end

	self:HandleSpeed(0, 0)
	self:Teleport(spot)
end

ENT.StateUpdate.Stare = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not ctx.TargetValid then
		sc.Done = true
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
	local gl, sc = self:ReturnContext()

	if not sc.Vanish then
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
