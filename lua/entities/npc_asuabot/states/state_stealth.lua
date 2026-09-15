include("entities/npc_asuabot/helper.lua")

local STALK_SPD = 600
local STALK_ACCEL = 400
local STALK_DUR = 8
local STALK_PROXIMITY = 200
local STALK_HIDE_THRESH = 60

local BEHIND_SPD = 1200
local BEHIND_ACCEL = 10000
local BEHIND_THRESH = 60
local BEHIND_DUR = 20
local BEHIND_DIST = 200

function ENT:StateStalk()
	self:HandleSpeed(STALK_SPD, STALK_ACCEL)

	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local hidePos
	if math.random(1, 2) == 1 then
		hidePos = self:FindHidingSpot(target)
	else
		hidePos = self:FindClosestHidingSpot(target)
	end

	if not hidePos then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(STALK_HIDE_THRESH)
	path:Compute(self, hidePos)

	while path:IsValid() do
		path:Update(self)
		self:ClearObstacles()

		if self:IsTouchingPlayer(target) then
			self:PushOnContact(target)
			self.CurrentState = "Avoid"
			return
		end

		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end

		if self:GetPos():Distance(hidePos) < STALK_HIDE_THRESH then
			break
		end

		coroutine.yield()
	end

	self:HandleSpeed(0, 0)

	local stalkStartTime = CurTime()

	while IsValid(target) and target:Alive() do
		self.loco:FaceTowards(target:GetPos())

		if CurTime() - stalkStartTime >= STALK_DUR then
			self.CurrentState = "Wander"
			return
		end

		if self:IsTouchingPlayer(target) then
			self:TeleportToDistantNavSpot()
			self.CurrentState = "Wander"
			return
		end

		if self:GetPos():Distance(target:GetPos()) <= STALK_PROXIMITY then
			self.CurrentState = "Avoid"
			return
		end

		if self:IsObservedBy(target) then
			self.CurrentState = "Avoid"
			return
		end

		coroutine.yield()
	end
end

function ENT:StateBehind()
	self:HandleSpeed(BEHIND_SPD, BEHIND_ACCEL)

	local target = self:GetClosestPlayer()
	if not IsValid(target) then
		self.CurrentState = "Wander"
		return
	end

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(BEHIND_THRESH)

	local stateStartTime = CurTime()

	local behindPos = target:GetPos() - (target:GetForward() * BEHIND_DIST)
	self:SetPos(behindPos)
	while IsValid(target) and target:Alive() do
		if target.Asuabot_IsThirdPerson then
			target.Asuabot_IsThirdPerson = false

			if math.random(1, 2) == 1 then
				self:TeleportToDistantNavSpot()
				self.CurrentState = "Wander"
				return
			else
				target:TakeDamage(25, self, self)
				self:TeleportToDistantNavSpot()
				self.CurrentState = "Wander"
				return
			end
		end

		if CurTime() - stateStartTime >= BEHIND_DUR then
			self.CurrentState = "Wander"
			return
		end

		local behindPos = target:GetPos() - (target:GetForward() * BEHIND_DIST)

		if path:GetAge() > 0.2 then
			path:Compute(self, behindPos)
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
