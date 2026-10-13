local DIST = 100
local EDGE_ANGLE = 50
local STILL_REQUIRED = 1.5

ENT.StateRules.Loom = {
	min = 5,
	max = 40,
	cd = 120,
	needsTarget = true,
	block = { "Stare", "Apparition" },
}

ENT.UtilityScores.Loom = function(self, ctx, trace)
	if not ctx.TargetValid or ctx.StillFor < STILL_REQUIRED then
		return 0
	end

	local patience = math.max(
		Consider(ctx.StillFor, STILL_REQUIRED, 15, function(x)
			return Curves.PowerOut(x, 2)
		end),
		0.5
	)
	local dark = ctx.Flashlight and 0.7 or 1
	local tight = ctx.PlayerEnclosed and 1 or 0.7

	if trace then
		trace.StillFor = ctx.StillFor
		trace.Patience = patience
		trace.Dark = dark
		trace.Tight = tight
	end

	return WeightedGeoMean({
		{ score = patience, weight = 1.2 },
		{ score = dark, weight = 0.6 },
		{ score = tight, weight = 0.8 },
	})
end

ENT.StateEnter.Loom = function(self)
	local gl, sc = self:ReturnContext()

	sc.Appeared = false
	sc.InSequence = true

	if gl.Path and gl.Path:IsValid() then
		gl.Path:Invalidate()
	end

	if not IsValid(gl.Target) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	local side = math.random(2) == 1 and 1 or -1
	local yaw = gl.Target:EyeAngles().y + EDGE_ANGLE * side
	local pos = gl.Target:GetPos() + Angle(0, yaw, 0):Forward() * DIST

	local area = navmesh.GetNearestNavArea(pos)
	if not IsValid(area) then
		sc.InSequence = false
		sc.Done = true
		return
	end

	sc.Appeared = true

	self:HandleSpeed(0, 0)
	self:Teleport(area:GetClosestPointOnArea(pos))
end

ENT.StateUpdate.Loom = function(self, ctx)
	local gl, sc = self:ReturnContext()

	if not ctx.PlayerStill then
		sc.InSequence = false
		sc.Done = true
	end
end

ENT.StateExit.Loom = function(self)
	local gl, sc = self:ReturnContext()

	if not sc.Appeared then
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
