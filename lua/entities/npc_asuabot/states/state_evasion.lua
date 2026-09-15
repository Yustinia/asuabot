include("entities/npc_asuabot/helper.lua")

local AVOID_SPD = 700
local AVOID_ACCEL = 800
local AVOID_DUR = 12
local AVOID_FAKEOUT_TIMER = 3
local AVOID_RAD = 2000
local AVOID_FAKEOUT_DIST = 60
local AVOID_GOAL_TOLERANCE = 60

local FAKEOUT_SPD = 2000
local FAKEOUT_ACCEL = 6000

function ENT:StateAvoid()
	self:HandleSpeed(AVOID_SPD, AVOID_ACCEL)

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
	path:SetGoalTolerance(AVOID_GOAL_TOLERANCE)
	path:Compute(self, fleePos)

	local avoidStartTime = CurTime()
	local chaseStartTime = 0
	local isBeingChased = false

	while path:IsValid() and IsValid(target) and target:Alive() do
		if CurTime() - avoidStartTime >= AVOID_DUR then
			self.CurrentState = "Wander"
			self:TeleportToDistantNavSpot()
			return
		end

		if self:GetPos():Distance(fleePos) <= AVOID_GOAL_TOLERANCE then
			self.CurrentState = "Wander"
			self:TeleportToDistantNavSpot()
			return
		end

		if self:GetPos():Distance(target:GetPos()) <= AVOID_RAD then
			if not isBeingChased then
				isBeingChased = true
				chaseStartTime = CurTime()
			end

			if CurTime() - chaseStartTime >= AVOID_FAKEOUT_TIMER then
				self:HandleSpeed(FAKEOUT_SPD, FAKEOUT_ACCEL)

				-- Rush directly into the player's face
				local counterPath = Path("Follow")
				counterPath:Compute(self, target:GetPos())

				while counterPath:IsValid() and self:GetPos():Distance(target:GetPos()) > AVOID_FAKEOUT_DIST do
					counterPath:Compute(self, target:GetPos())
					counterPath:Update(self)
					coroutine.yield()
				end

				coroutine.wait(2)

				self.CurrentState = "Avoid"
				return
			end
		else
			isBeingChased = false
		end

		path:Update(self)

		self:ClearObstacles()

		if self.loco:IsStuck() then
			self:HandleStuck()
			path:Compute(self, target:GetPos())
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

	self:HandleSpeed(0, 0)
	self.loco:FaceTowards(target:GetPos())
	coroutine.wait(5)

	self:HandleSpeed(FAKEOUT_SPD, FAKEOUT_ACCEL)
	local path = Path("Follow")

	while IsValid(target) and target:Alive() do
		if path:GetAge() > 0.1 then
			path:Compute(self, target:GetPos())
		end
		path:Update(self)

		if self:GetPos():Distance(target:GetPos()) <= 50 then
			self:ExecuteFaceToFaceJumpscare(target)
			self:HandleSpeed(0, 0)
			coroutine.wait(2)

			self.CurrentState = "Avoid"
			return
		end

		if self.loco:IsStuck() then
			self:HandleStuck()
			self.CurrentState = "Avoid"
			return
		end

		coroutine.yield()
	end
end
