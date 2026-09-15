include("entities/npc_asuabot/helper.lua")

local WANDER_SPD = 500
local WANDER_ACCEL = 500

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
		if self:IsTouchingPlayer(target) then
			target:TakeDamage(1, self, self)
			self:PushOnContact(target)
		end

		if math.random(1, 2000) == 1 then
			self.CurrentState = table.Random({ "Chase", "Rushing", "Flickering" })
			return
		end

		if IsValid(target) and self:IsLineOfSightClear(target) then
			if math.random(1, 100) <= 10 then
				self.CurrentState = "FakeOutRush"
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
