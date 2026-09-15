include("entities/npc_asuabot/helper.lua")

local SPEED_AVOID = 400
local SPEED_FAKEOUT = 2000

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
				coroutine.wait(2) -- Hold face-to-face for 2 seconds

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
	local isLethal = (math.random(1, 2) == 1)

	while IsValid(target) and target:Alive() do
		if path:GetAge() > 0.1 then
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		-- On contact range (~50 HU)
		if self:GetPos():DistToSqr(target:GetPos()) <= 2500 then
			-- Trigger Sequence 5 (Face-To-Face Jumpscare)
			if isLethal then
				-- Sequence 13: Snap face-to-face, hold 0.5s, deal damage
				self:ExecuteFaceToFaceJumpscare(target, 0.5, true)
			else
				-- Sequence 12: Snap face-to-face, hold 2.0s, no damage
				self:ExecuteFaceToFaceJumpscare(target, 2.0, false)
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
