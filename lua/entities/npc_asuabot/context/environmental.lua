local FAN_DIST = 800 -- fan length; must cover the largest threshold below
local OPEN_DIST = 400 -- open: every ray clear this far
local CORNER_DIST = 200 -- cornered: rays blocked within this
local CORNER_RAYS = 6
local ROOM_RAYS = 6 -- enclosed: rays blocked within FAN_DIST
local CEILING_DIST = 400 -- enclosed: solid, non-sky ceiling within this

--- Classifies the target's surroundings from one ray fan plus one upward trace.
-- @return boolean open, boolean cornered, boolean enclosed
function ENT:SampleSurroundings(target)
	local pos = target:GetPos() + Vector(0, 0, 32)
	local open, nearBlocked, farBlocked = true, 0, 0

	for i = 0, 7 do
		local tr = util.TraceLine({
			start = pos,
			endpos = pos + Angle(0, i * 45, 0):Forward() * FAN_DIST,
			mask = MASK_SOLID_BRUSHONLY,
			filter = { target, self },
		})

		if tr.Hit then
			farBlocked = farBlocked + 1
			local d = tr.Fraction * FAN_DIST
			if d < OPEN_DIST then
				open = false
			end
			if d < CORNER_DIST then
				nearBlocked = nearBlocked + 1
			end
		end
	end

	local up = util.TraceLine({
		start = pos,
		endpos = pos + Vector(0, 0, CEILING_DIST),
		mask = MASK_SOLID_BRUSHONLY,
		filter = { target, self },
	})
	local roofed = up.Hit and not up.HitSky

	return open, nearBlocked >= CORNER_RAYS, roofed and farBlocked >= ROOM_RAYS
end
