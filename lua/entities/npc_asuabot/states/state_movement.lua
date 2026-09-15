include("entities/npc_asuabot/helper.lua")

local SPEED_WANDER = 300

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
