function ENT:PushEntity(target, force)
	force = force or 1500

	if CurTime() >= self.NextPushTime then
		local pushVec = target:GetPos() - self:GetPos()
		pushVec.z = 15
		pushVec:Normalize()

		target:SetVelocity(pushVec * force)

		self.NextPushTime = CurTime() + self.PushCD
	end
end

function ENT:DamageEntity(target, amount)
	amount = amount or 1

	if CurTime() >= self.NextDamageTime then
		target:TakeDamage(amount, self, self)

		self.NextDamageTime = CurTime() + self.DamageCD
	end
end

function ENT:PullEntity(target, force)
	force = force or 800

	if CurTime() < (self.NextPullTime or 0) then
		return
	end

	if not IsValid(target) then
		return
	end

	local pullVec = self:GetPos() - target:GetPos()
	pullVec.z = 0
	pullVec:Normalize()

	target:SetVelocity(pullVec * force)

	self.NextPullTime = CurTime() + self.PullCD
end
