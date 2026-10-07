function ENT:IsPlayerInOpenArea(target, minDist)
	minDist = minDist or 400
	local pos = target:GetPos() + Vector(0, 0, 32)
	local directions = 8

	for i = 0, directions - 1 do
		local ang = (360 / directions) * i
		local dir = Angle(0, ang, 0):Forward()

		local tr = util.TraceLine({
			start = pos,
			endpos = pos + dir * minDist,
			filter = target,
		})

		if tr.Fraction < 1.0 then
			return false
		end
	end

	return true
end

function ENT:IsPlayerCornered(target, checkDist, blockedThreshold)
	checkDist = checkDist or 200
	blockedThreshold = blockedThreshold or 6

	local pos = target:GetPos() + Vector(0, 0, 32)
	local directions = 8
	local blockedCount = 0

	for i = 0, directions - 1 do
		local ang = (360 / directions) * i
		local dir = Angle(0, ang, 0):Forward()

		local tr = util.TraceLine({
			start = pos,
			endpos = pos + dir * checkDist,
			filter = target,
		})

		if tr.Fraction < 1.0 then
			blockedCount = blockedCount + 1
		end
	end

	return blockedCount >= blockedThreshold
end
