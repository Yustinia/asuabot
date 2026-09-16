include("entities/npc_asuabot/helper.lua")

local WANDER_SPD = 500
local WANDER_ACCEL = 500

local FAKEOUT_SPD = 2000
local FAKEOUT_ACCEL = 6000
local FAKEOUT_GOAL_THRESH = 60

function ENT:StateWander()
	self:HandleSpeed(WANDER_SPD, WANDER_ACCEL)

	local target = self:GetClosestPlayer()
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
		local randomChance = math.random(1, 500)

		if IsValid(target) and self:IsTouchingPlayer(target) then
			target:TakeDamage(1, self, self)
			self:PushOnContact(target)
		end

		if IsValid(target) and self:IsLineOfSightClear(target) then
			-- 2%
			if randomChance <= 2 then
				self.CurrentState = "FakeOutRush"
				return

			-- 8%
			elseif randomChance <= 10 then
				self.CurrentState = "Flickering"
				return

			-- 6%
			elseif randomChance <= 16 then
				self.CurrentState = "Chase"
				return

			-- 3%
			elseif randomChance <= 19 then
				self.CurrentState = "Rushing"
				return
			end
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

function ENT:FakeRush(target)
	if not IsValid(target) or not target:Alive() then
		return false
	end

	self:HandleSpeed(FAKEOUT_SPD, FAKEOUT_ACCEL)

	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(FAKEOUT_GOAL_THRESH)

	while IsValid(target) and target:Alive() do
		if self:GetPos():Distance(target:GetPos()) <= FAKEOUT_GOAL_THRESH then
			return
		end

		path:Compute(self, target:GetPos())
		path:Update(self)

		self:ClearObstacles()

		if self.loco:IsStuck() then
			self:HandleStuck()
			return
		end

		coroutine.yield()
	end

	return
end
