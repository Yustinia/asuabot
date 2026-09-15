AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Speeds (Hammer Units per second)
local SPEED_WANDER = 300
local SPEED_CHASE = 300
local SPEED_RUSH = 700
local SPEED_FLICKER = 800
local SPEED_STALK = 150
local SPEED_BEHIND = 250

util.AddNetworkString("Asuabot_ThirdPersonToggle")

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

	self.CurrentState = "Wander"
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
local SPEED_AVOID = 400
local SPEED_FAKEOUT = 900

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
			coroutine.yield()
		end
	end
end

-- ==========================================
-- Sequence 3: Wander
-- ==========================================
function ENT:StateWander()
	self.loco:SetDesiredSpeed(SPEED_WANDER)

	local navs = navmesh.GetAllNavAreas()
	if #navs == 0 then
		coroutine.wait(1)
		return
	end

	local targetArea = navs[math.random(1, #navs)]
	local targetPos = targetArea:GetRandomPoint()

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)
	path:Compute(self, targetPos)

	while path:IsValid() do
		-- Random chance to switch to aggressive states (testing purposes)
		if math.random(1, 300) == 1 then
			self.CurrentState = table.Random({ "Chase", "Rushing", "Flickering" })
			return
		end

		path:Update(self)
		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end
		coroutine.yield()
	end
end

-- ==========================================
-- Sequence 1: Chase (1a, 1b)
-- ==========================================
function ENT:StateChase()
	self.loco:SetDesiredSpeed(SPEED_CHASE)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)

	local stateStartTime = CurTime()
	local lastSeenTime = CurTime()

	while IsValid(target) and target:Alive() do
		-- 1b: Loss of Interest (10 seconds limit)
		if CurTime() - stateStartTime >= 10 then
			self.CurrentState = "Wander"
			return
		end

		-- 1a: Loss of Sight (3 seconds hidden)
		if target:IsLineOfSightClear(self) then
			lastSeenTime = CurTime()
		elseif CurTime() - lastSeenTime >= 3 then
			self.CurrentState = "Wander"
			return
		end

		-- Path update logic
		if path:GetAge() > 0.5 then
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end
		coroutine.yield()
	end
end

-- ==========================================
-- Sequence 2: Rushing (2a, 2b)
-- ==========================================
function ENT:StateRushing()
	self.loco:SetDesiredSpeed(SPEED_RUSH)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)

	local stateStartTime = CurTime()

	while IsValid(target) and target:Alive() do
		-- 2b: Loss of Interest (8 seconds limit)
		if CurTime() - stateStartTime >= 8 then
			self.CurrentState = "Wander"
			return
		end

		-- 2a: Path Collision / Stuck
		if self.loco:IsStuck() or (self:GetVelocity():LengthSqr() < 400 and path:GetAge() > 1) then
			-- Pretending to choose "another sequence" per instructions
			self.CurrentState = "Wander"
			return
		end

		if path:GetAge() > 0.2 then -- Faster recalculation for high speeds
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		coroutine.yield()
	end
end

-- ==========================================
-- Sequence 18: Flickering (18a, 18b)
-- ==========================================
function ENT:StateFlickering()
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)

	local observedStartTime = 0
	local isCurrentlyObserved = false

	while IsValid(target) and target:Alive() do
		local wasObserved = isCurrentlyObserved
		isCurrentlyObserved = self:IsObservedBy(target)

		if isCurrentlyObserved then
			self.loco:SetDesiredSpeed(0) -- Freeze

			if not wasObserved then
				observedStartTime = CurTime()
			end

			-- 18b: Timeout (Stared at for 8 seconds)
			if CurTime() - observedStartTime >= 8 then
				-- [Placeholder] Fade away opacity logic goes here
				self.CurrentState = "Wander"
				return
			end
		else
			self.loco:SetDesiredSpeed(SPEED_FLICKER)

			-- 18a: Reach Target while unobserved (Distance check ~50 HU)
			if self:GetPos():DistToSqr(target:GetPos()) <= 2500 then
				-- [Placeholder] Display Jumpscare Trigger goes here
				self.CurrentState = "Wander"
				return
			end

			if path:GetAge() > 0.5 then
				path:Compute(self, target:GetPos())
			end
			path:Update(self)

			if self.loco:IsStuck() then
				self:HandleStuck()
				return
			end
		end

		coroutine.yield()
	end
end

-- ==========================================
-- Sequence 6: Stalk
-- ==========================================
function ENT:StateStalk()
	self.loco:SetDesiredSpeed(SPEED_STALK)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local hidePos = self:FindHidingSpot(target)
	if not hidePos then
		self.CurrentState = "Wander"
		return
	end -- Fallback if no cover found

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)
	path:Compute(self, hidePos)

	-- Move to cover
	while path:IsValid() do
		path:Update(self)
		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end
		if self:GetPos():DistToSqr(hidePos) < 2500 then
			break
		end
		coroutine.yield()
	end

	-- Wait in cover and look at player
	local observedStartTime = 0
	local hasBeenSpotted = false

	while IsValid(target) and target:Alive() do
		-- Constantly face the player while stalking
		self.loco:FaceTowards(target:GetPos())

		if self:IsObservedBy(target) then
			if not hasBeenSpotted then
				hasBeenSpotted = true
				observedStartTime = CurTime()
			end

			-- Retreat after 3 seconds of being seen
			if CurTime() - observedStartTime >= 3 then
				self.CurrentState = "Avoid" -- Transition to Avoid (Category 3)
				return
			end

			-- Sequence 7: Stalk -> Jumpscare -> Disappear
			-- If player pushes within 1050 HU (approx 20m) before 3s is up
			if self:GetPos():DistToSqr(target:GetPos()) <= 1102500 then
				-- [Placeholder] Execute Jumpscare / Disappear
				self:Remove()
				return
			end
		else
			-- If they look away before 3 seconds, reset the timer
			hasBeenSpotted = false
		end

		coroutine.yield()
	end
end

-- ==========================================
-- Sequence 11: Peek
-- ==========================================
function ENT:StatePeek()
	self.loco:SetDesiredSpeed(SPEED_STALK)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	-- Find cover
	local hidePos = self:FindHidingSpot(target)
	if hidePos then
		local path = Path("Follow")
		path:Compute(self, hidePos)
		while path:IsValid() do
			path:Update(self)
			if self:GetPos():DistToSqr(hidePos) < 2500 then
				break
			end
			coroutine.yield()
		end
	end

	-- Step out (peek) by moving slightly towards the player
	local peekPos = self:GetPos() + (target:GetPos() - self:GetPos()):GetNormalized() * 100
	self.loco:Approach(peekPos, 1)

	-- Hold the peek for 0.5 seconds
	coroutine.wait(0.5)

	-- Instantly disappear
	self:Remove()
end

-- ==========================================
-- Sequence 14, 15, 16: Behind
-- ==========================================
function ENT:StateBehind()
	self.loco:SetDesiredSpeed(SPEED_BEHIND)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(50)

	local stateStartTime = CurTime()

	while IsValid(target) and target:Alive() do
		-- Sequence 15 & 16: Third Person Check
		if target.Asuabot_IsThirdPerson then
			target.Asuabot_IsThirdPerson = false -- Consume the flag

			-- 50/50 chance for Seq 15 (Disappear) or Seq 16 (Jumpscare)
			if math.random(1, 2) == 1 then
				self:Remove() -- Seq 15
				return
			else
				-- Seq 16 [Placeholder]: Display Jumpscare -> Damage -> Disappear
				target:TakeDamage(25, self, self)
				self:Remove()
				return
			end
		end

		-- Base Sequence 14: Stay behind for 10 seconds
		if CurTime() - stateStartTime >= 10 then
			self.CurrentState = "Wander"
			return
		end

		-- Calculate position behind the player (200 units back)
		local behindPos = target:GetPos() - (target:GetForward() * 200)

		-- Path to the calculated rear vector
		if path:GetAge() > 0.2 then
			path:Compute(self, behindPos)
		end
		path:Update(self)

		coroutine.yield()
	end
end

-- ==========================================
-- Sequence 8 & 9: Avoid & Anti-Chase Counter
-- ==========================================
function ENT:StateAvoid()
	self.loco:SetDesiredSpeed(SPEED_AVOID)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local fleePos = self:FindFleeSpot(target)
	if not fleePos then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(50)
	path:Compute(self, fleePos)

	local avoidStartTime = CurTime()
	local chaseStartTime = 0
	local isBeingChased = false

	while path:IsValid() and IsValid(target) and target:Alive() do
		-- Base Sequence 8 Timeout: Re-evaluate state after 8 seconds of fleeing
		if CurTime() - avoidStartTime >= 8 then
			self.CurrentState = "Wander"
			return
		end

		-- Sequence 9: Avoid -> Jumpscare -> Avoid
		-- Check if player is pursuing within 1050 HU (approx 20m) [Source: Training data / General knowledge domain]
		if self:GetPos():DistToSqr(target:GetPos()) <= 1102500 then
			if not isBeingChased then
				isBeingChased = true
				chaseStartTime = CurTime()
			end

			-- If chased for 5 seconds continuously
			if CurTime() - chaseStartTime >= 5 then
				self.loco:SetDesiredSpeed(SPEED_FAKEOUT)

				-- Rush directly into the player's face
				local counterPath = Path("Follow")
				counterPath:Compute(self, target:GetPos())

				while counterPath:IsValid() and self:GetPos():DistToSqr(target:GetPos()) > 2500 do
					counterPath:Compute(self, target:GetPos())
					counterPath:Update(self)
					coroutine.yield()
				end

				-- Stun the player briefly [Source: Training data / General knowledge domain]
				target:Freeze(true)
				coroutine.wait(2) -- Hold face-to-face for 2 seconds
				target:Freeze(false)

				-- Resume avoiding without dealing damage
				self.CurrentState = "Avoid"
				return
			end
		else
			isBeingChased = false
		end

		path:Update(self)
		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end
		coroutine.yield()
	end
end

-- ==========================================
-- Sequence 12 & 13: Wander -> Rush -> FakeOut
-- ==========================================
function ENT:StateFakeOutRush()
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	-- 1. The Silence (Freeze in place for 5 seconds)
	self.loco:SetDesiredSpeed(0)
	self.loco:FaceTowards(target:GetPos())
	coroutine.wait(5)

	-- 2. The High-Speed Rush
	self.loco:SetDesiredSpeed(SPEED_FAKEOUT)
	local path = Path("Follow")

	-- 50/50 chance to dictate if this is Seq 12 (No Damage) or Seq 13 (Damage)
	local isLethal = (math.random(1, 2) == 1)

	while IsValid(target) and target:Alive() do
		-- Compute shortest path strictly to the player's real-time position
		if path:GetAge() > 0.1 then
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		-- Stop when directly face-to-face (within ~50 HU) [Source: Training data / General knowledge domain]
		if self:GetPos():DistToSqr(target:GetPos()) <= 2500 then
			self.loco:SetDesiredSpeed(0)

			if isLethal then
				-- Seq 13: Deal damage, hold for a split second, then flee
				target:TakeDamage(40, self, self)
				coroutine.wait(0.5)
			else
				-- Seq 12: No damage, hold the face-to-face tension for 2 seconds
				coroutine.wait(2)
			end

			self.CurrentState = "Avoid"
			return
		end

		if self.loco:IsStuck() then
			self.CurrentState = "Avoid"
			return
		end
		coroutine.yield()
	end
end
