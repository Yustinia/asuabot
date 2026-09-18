include("entities/npc_asuabot/helper.lua")

local CHASE_SPD = 600
local CHASE_ACCEL = 800
local CHASE_DUR = 12
local CHASE_HID = 4
local CHASE_AGE = 0.5
local CHASE_DMG = 10

local RUSH_SPD = 1200
local RUSH_ACCEL = 2000
local RUSH_DUR = 16
local RUSH_AGE = 0.2

local FLICKER_SPD = 600
local FLICKER_ACCEL = 600
local FLICKER_DUR = 4
local FLICKER_LIFETIME = 12

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
		if self:IsTouchingPlayer(target) then
			target:TakeDamage(CHASE_DMG, self, self)
			self:TeleportToDistantNavSpot()
			self.CurrentState = "Wander"
			return
		end

		if CurTime() - stateStartTime >= CHASE_DUR then
			self.CurrentState = "Wander"
			return
		end

		if target:IsLineOfSightClear(self) then
			lastSeenTime = CurTime()
		elseif CurTime() - lastSeenTime >= CHASE_HID then
			self:TeleportToDistantNavSpot()
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
		if self:IsTouchingPlayer(target) then
			target:TakeDamage(25, self, self)
			self:TeleportToDistantNavSpot()
			self.CurrentState = "Wander"
			return
		end

		if CurTime() - stateStartTime >= RUSH_DUR then
			self.CurrentState = "Avoid"
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
	local flickerStartTime = CurTime()
	local isCurrentlyObserved = false

	while IsValid(target) and target:Alive() do
		if CurTime() - flickerStartTime >= FLICKER_LIFETIME then
			self:TeleportToDistantNavSpot()
			self.CurrentState = "Wander"
			return
		end

		if self:IsTouchingPlayer(target) then
			target:TakeDamage(2, self, self)

			-- HANDLE JUMPSCARE

			self.CurrentState = "Behind"
			return
		end

		local wasObserved = isCurrentlyObserved
		isCurrentlyObserved = self:IsObservedBy(target)

		if isCurrentlyObserved then
			self:HandleSpeed(0, 0)

			if not wasObserved then
				observedStartTime = CurTime()
			end

			if CurTime() - observedStartTime >= FLICKER_DUR then
				self:TeleportToDistantNavSpot()
				self.CurrentState = "Wander"
				return
			end
		else
			self:HandleSpeed(FLICKER_SPD, FLICKER_ACCEL)

			if path:GetAge() > 0.5 then
				path:Compute(self, target:GetPos())
			end
			path:Update(self)

			self:ClearObstacles()

			if self.loco:IsStuck() then
				self:HandleStuck()
				path:Compute(self, target:GetPos())
			end
		end

		coroutine.yield()
	end
end
