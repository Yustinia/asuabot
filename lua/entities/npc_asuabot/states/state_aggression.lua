include("entities/npc_asuabot/helper.lua")

local CHASE_SPD = 600
local CHASE_ACCEL = 800
local CHASE_DUR = 12
local CHASE_HID = 4
local CHASE_AGE = 0.5

local RUSH_SPD = 1200
local RUSH_ACCEL = 2000
local RUSH_DUR = 16
local RUSH_AGE = 0.2

local SPEED_FLICKER = 800

function ENT:StateChase()
	self:HandleSpeed(CHASE_SPD, CHASE_ACCEL)
	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(0)

	local stateStartTime = CurTime()
	local lastSeenTime = CurTime()

	while IsValid(target) and target:Alive() do
		if CurTime() - stateStartTime >= CHASE_DUR then
			self.CurrentState = "Wander"
			return
		end

		if target:IsLineOfSightClear(self) then
			lastSeenTime = CurTime()
		elseif CurTime() - lastSeenTime >= CHASE_HID then
			self.CurrentState = "Wander"
			return
		end

		if path:GetAge() > CHASE_AGE then
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		self:ClearObstacles()

		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end
		coroutine.yield()
	end
end

function ENT:StateRushing()
	self:HandleSpeed(RUSH_SPD, RUSH_ACCEL)

	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(0)

	local stateStartTime = CurTime()

	while IsValid(target) and target:Alive() do
		if CurTime() - stateStartTime >= RUSH_DUR then
			self.CurrentState = "Wander"
			return
		end

		if path:GetAge() > RUSH_AGE then
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		self:ClearObstacles()

		if self.loco:IsStuck() then
			self:HandleStuck()
			path:Compute(self, target:GetPos())
		end

		coroutine.yield()
	end
end

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
