function ENT:IsTouchingPlayer(target, distanceThreshold)
	if not IsValid(target) or not target:IsPlayer() or not target:Alive() then
		return false
	end

	distanceThreshold = distanceThreshold or 60

	local dist = self:GetPos():Distance(target:GetPos())
	if dist <= distanceThreshold then
		return true
	end

	local botTorso = self:GetPos() + Vector(0, 0, 36)
	local plyTorso = target:GetPos() + Vector(0, 0, 36)

	local tr = util.TraceHull({
		start = botTorso,
		endpos = plyTorso,
		mins = Vector(-10, -10, -10),
		maxs = Vector(10, 10, 10),
		filter = self,
	})

	return tr.Hit and tr.Entity == target and botTorso:Distance(plyTorso) <= (distanceThreshold + 20)
end

function ENT:PushOnContact(ent)
	local pushIntensity = 2500

	if IsValid(ent) and ent:IsPlayer() then
		local pushVec = ent:GetPos() - self:GetPos()
		pushVec.z = 0
		pushVec:Normalize()

		ent:SetVelocity(pushVec * pushIntensity)
	end
end
