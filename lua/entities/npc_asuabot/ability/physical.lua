local PUSH_INTENSITY = 1500
local PUSH_CD = 0.5
local DMG_CD = 0.5

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

function ENT:PushOnContact(target)
	if CurTime() >= self.NextPushTime then
		local pushVec = target:GetPos() - self:GetPos()
		pushVec.z = 15
		pushVec:Normalize()

		target:SetVelocity(pushVec * PUSH_INTENSITY)

		self.NextPushTime = CurTime() + PUSH_CD
	end
end

function ENT:DealDmgOnContact(target, amount)
	amount = amount or 1

	if CurTime() >= self.NextDamageTime then
		target:TakeDamage(amount, self, self)

		self.NextDamageTime = CurTime() + DMG_CD
	end
end
