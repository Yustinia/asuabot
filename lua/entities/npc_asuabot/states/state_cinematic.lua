function ENT:TriggerDisplayJumpscare(target, duration)
	if not IsValid(target) or not target:IsPlayer() then
		return
	end

	duration = duration or 1.5

	-- Send net message to trigger client-side full-screen HUD overlay
	net.Start("Asuabot_DisplayJumpscare")
	net.WriteFloat(duration)
	net.Send(target)
end

function ENT:ExecuteFaceToFaceJumpscare(target, holdTime, dealDamage)
	if not IsValid(target) or not target:IsPlayer() then
		return
	end

	holdTime = holdTime or 2.0
	dealDamage = dealDamage or false

	-- Calculate position directly in front of player's eye level
	local eyePos = target:EyePos()
	local forwardVec = target:GetAimVector()
	local facePos = eyePos + (forwardVec * 35) -- 35 HU directly in front of camera

	-- Snap position and align angles directly towards player view
	self:SetPos(facePos - Vector(0, 0, 36)) -- Adjust height relative to origin
	self:SetAngles((-forwardVec):Angle())

	-- Freeze locomotion during close-up hold
	self.loco:SetDesiredSpeed(0)

	if dealDamage then
		target:TakeDamage(35, self, self)
	end

	-- Hold position for duration
	coroutine.wait(holdTime)
end
