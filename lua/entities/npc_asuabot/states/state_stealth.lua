include("entities/npc_asuabot/helper.lua")

local STALK_SPD = 600
local STALK_ACCEL = 400
local STALK_DUR = 8
local STALK_PROXIMITY = 200
local STALK_HIDE_THRESH = 60

local SPEED_PEEK = 300
local SPEED_BEHIND = 250

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
	path:SetGoalTolerance(20)
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

function ENT:StatePeek()
	self.loco:SetDesiredSpeed(SPEED_PEEK)
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

	-- Teleport to a random navmesh area far away instead of deleting the entity
	local navs = navmesh.GetAllNavAreas()
	if #navs > 0 then
		local randomArea = navs[math.random(1, #navs)]
		self:SetPos(randomArea:GetRandomPoint())
	end

	self.CurrentState = "Wander"
end

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
