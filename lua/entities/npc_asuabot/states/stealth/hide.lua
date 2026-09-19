local HIDE_SPD = 300
local HIDE_ACCEL = 400
local HIDE_GOAL_THRESH = 0
local HIDE_PATH_AGE = 0.8
local HIDE_AHEAD_DIST = 80

function ENT:StateHide()
	self:HandleSpeed(HIDE_SPD, HIDE_ACCEL)
	self.Target = self:FindClosestPlayer()

	local targetPos = nil

	if math.random(1, 2) == 1 then
		targetPos = self:FindHideSpot()
	else
		targetPos = self:FindClosestHideSpot()
	end

	if not self:ComputeRoutingPath(targetPos, HIDE_AHEAD_DIST, HIDE_GOAL_THRESH, "Follow") then
		return
	end

	while self.Path:IsValid() do
		if self:IsAtPosition(targetPos, HIDE_GOAL_THRESH) then
			-- DO SOMETHING
		end

		if self:IsObservedBy(self.Target) then
			-- DO SOMETHING
		end

		self:RefreshPathIfStale(HIDE_PATH_AGE, targetPos, "Follow")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end
end
