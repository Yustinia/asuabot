--- Checks line of sight between two arbitrary world positions, not tied to any entity.
-- Use this when neither endpoint is "where an entity currently stands" — e.g. evaluating
-- a candidate spot the bot hasn't moved to yet. For entity-to-entity/target checks, prefer
-- Entity:IsLineOfSightClear() instead, which is simpler and already engine-provided.
-- @param fromPos Vector: trace start position
-- @param toPos Vector: trace end position
-- @return boolean: true if the trace reaches toPos unobstructed
function ENT:CheckLOS(fromPos, toPos)
	local tr = util.TraceLine({
		start = fromPos,
		endpos = toPos,
		mask = MASK_OPAQUE,
		filter = self,
	})

	return tr.Fraction >= 1.0
end

--- Checks whether a target position falls within a viewer's field of view.
-- Uses the viewer's FACING direction (eye angles / forward vector), not their movement direction.
-- @param viewerPos Vector: the viewer's position
-- @param viewerForward Vector: the viewer's normalized forward/facing vector
-- @param targetPos Vector: the position being checked
-- @param fovAngle number: full FOV cone angle in degrees (e.g. 90 = 45 degrees either side)
-- @return boolean
function ENT:CheckFOV(viewerPos, viewerForward, targetPos, fovAngle)
	local dirToTarget = (targetPos - viewerPos):GetNormalized()
	local dot = viewerForward:Dot(dirToTarget)

	local fovCos = math.cos(math.rad(fovAngle * 0.5))
	return dot >= fovCos
end

-- function ENT:FindVisibleEntities() end
-- function ENT:FindVisiblePlayers() end
