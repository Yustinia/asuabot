AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

include("states/state_aggression.lua")
include("states/state_cinematic.lua")
include("states/state_evasion.lua")
include("states/state_movement.lua")
include("states/state_stealth.lua")

util.AddNetworkString("Asuabot_ThirdPersonToggle")
util.AddNetworkString("Asuabot_DisplayJumpscare")

-- Listen for third-person toggles and flag the player
net.Receive("Asuabot_ThirdPersonToggle", function(len, ply)
	if IsValid(ply) then
		ply.Asuabot_IsThirdPerson = true

		-- Reset the flag after a short delay so they aren't permanently marked
		timer.Simple(2, function()
			if IsValid(ply) then
				ply.Asuabot_IsThirdPerson = false
			end
		end)
	end
end)

-- Helper: Scans navmesh for spots that block Line-of-Sight to the player
function ENT:FindHidingSpot(target)
	local areas = navmesh.Find(target:GetPos(), 1500, 100, 20)
	local targetEye = target:EyePos()

	-- Shuffle areas for randomness
	table.Random(areas)

	for _, area in ipairs(areas) do
		local center = area:GetCenter()
		local tr = util.TraceLine({
			start = center + Vector(0, 0, 64), -- Eye level of the spot
			endpos = targetEye,
			mask = MASK_OPAQUE, -- Only hit solid world geometry
		})

		-- If the trace hits something before reaching the player, it's hidden
		if tr.Hit and tr.Fraction < 1.0 then
			return center
		end
	end
	return nil
end

function ENT:Initialize()
	self:SetModel("models/player/kleiner.mdl") -- Invisible physical hull
	self:SetHealth(1000)
	self:SetCollisionGroup(COLLISION_GROUP_NPC)
	self:SetSolid(SOLID_BBOX)

	-- Using a standard player bounding box for navigation
	self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))

	self.CurrentState = "Peek"
end

-- ==========================================
-- Helper Functions
-- ==========================================

function ENT:GetClosestPlayer()
	local closest = nil
	local minDist = math.huge
	local myPos = self:GetPos()

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and not ply:GetObserverMode() ~= OBS_MODE_NONE then
			local distSq = myPos:DistToSqr(ply:GetPos())
			if distSq < minDist then
				minDist = distSq
				closest = ply
			end
		end
	end
	return closest
end

-- Checks if the Nextbot is inside the player's FOV and not behind a wall
function ENT:IsObservedBy(ply)
	if not IsValid(ply) then
		return false
	end
	if not ply:IsLineOfSightClear(self) then
		return false
	end

	local dirToBot = (self:GetPos() - ply:GetPos()):GetNormalized()
	local plyAim = ply:GetAimVector()
	-- 0.5 dot product roughly equates to a 90-degree FOV cone
	return plyAim:Dot(dirToBot) > 0.5
end

-- ==========================================
-- Evasive Helpers & Collision Hooks
-- ==========================================

-- Helper: Scans nearby navmesh and returns the point furthest from the target
function ENT:FindFleeSpot(target)
	-- Find nav areas within 2000 HU [Source: Training data / General knowledge domain]
	local hideSpots = navmesh.Find(self:GetPos(), 2000, 100, 20)
	local bestSpot = nil
	local maxDist = 0

	for _, area in ipairs(hideSpots) do
		local dist = area:GetCenter():DistToSqr(target:GetPos())
		if dist > maxDist then
			maxDist = dist
			bestSpot = area:GetCenter()
		end
	end

	return bestSpot
end

-- Sequence 10: Avoid -> Collision -> Avoid
function ENT:OnContact(ent)
	if self.CurrentState == "Avoid" and IsValid(ent) and ent:IsPlayer() then
		-- Deal partial damage [Source: Training data / General knowledge domain]
		ent:TakeDamage(15, self, self)

		-- Calculate push vector away from the Nextbot
		local pushVec = ent:GetPos() - self:GetPos()
		pushVec.z = 0 -- Ensure no vertical movement (Z-axis lock) [Source: Mathematical derivation shown above]
		pushVec:Normalize()

		-- Apply heavy horizontal impulse velocity to the player [Source: Training data / General knowledge domain]
		ent:SetVelocity(pushVec * 1500)
	end
end

-- ==========================================
-- State Machine (Core Loop)
-- ==========================================

function ENT:RunBehaviour()
	while true do
		if self.CurrentState == "Wander" then
			self:StateWander()
		elseif self.CurrentState == "Chase" then
			self:StateChase()
		elseif self.CurrentState == "Rushing" then
			self:StateRushing()
		elseif self.CurrentState == "Flickering" then
			self:StateFlickering()
		elseif self.CurrentState == "Stalk" then
			self:StateStalk()
		elseif self.CurrentState == "Peek" then
			self:StatePeek()
		elseif self.CurrentState == "Behind" then
			self:StateBehind()
		elseif self.CurrentState == "Avoid" then
			self:StateAvoid()
		elseif self.CurrentState == "FakeOutRush" then
			self:StateFakeOutRush()
		else
			-- Fallback if state is undefined
			self.CurrentState = "Wander"
			self:StateWander()
		end

		-- Safety yield: Prevents infinite loop server crashes if a state function exits immediately
		coroutine.yield()
	end
end
