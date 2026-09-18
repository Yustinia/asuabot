include("entities/npc_asuabot/helper.lua")

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

function ENT:ExecuteFaceToFaceJumpscare(target)
	if not IsValid(target) or not target:IsPlayer() then
		return
	end

	local eyePos = target:EyePos()
	local forwardVec = target:GetAimVector()
	local facePos = eyePos + (forwardVec * 35)

	self:SetPos(facePos - Vector(0, 0, 36))
	self:SetAngles((-forwardVec):Angle())
end
