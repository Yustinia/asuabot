local AMBUSH_SCAN_RAD = 4000
local AMBUSH_TRIGGER_RADIUS = 1000

local AMBUSH_APPROACH_SPD = 600
local AMBUSH_APPROACH_ACCEL = 600
local AMBUSH_APPROACH_GOAL_THRESH = 30
local AMBUSH_APPROACH_AHEAD_DIST = 300
local AMBUSH_APPROACH_PATH_AGE = 0.1

function ENT:StateAmbushApproach()
	self:HandleSpeed(AMBUSH_APPROACH_SPD, AMBUSH_APPROACH_ACCEL)
	self.Target = self:FindClosestPlayer()

	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	local hideSpot = self:FindHideSpot(AMBUSH_SCAN_RAD)
	if not hideSpot then
		self:SetState("Wander")
		return
	end

	if not self:ComputeRoutingPath(hideSpot, AMBUSH_APPROACH_AHEAD_DIST, AMBUSH_APPROACH_GOAL_THRESH, "Follow") then
		self:SetState("Wander")
		return
	end

	while self.Path:IsValid() and IsValid(self.Target) and self.Target:Alive() do
		if self:IsAtPosition(hideSpot, AMBUSH_APPROACH_GOAL_THRESH) then
			self:HandleSpeed(0, 0)
			break -- reached concealment, move to waiting phase
		end

		if self:IsObservedBy(self.Target) then
			-- DO SOMETHING
		end

		self:RefreshPathIfStale(AMBUSH_APPROACH_PATH_AGE, hideSpot, "Follow")
		self.Path:Update(self)
		self:ClearObstacles()

		coroutine.yield()
	end

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsObservedBy(self.Target) then
			-- DO SOMETHING
		end

		local dist = self:GetPos():Distance(self.Target:GetPos())

		if dist <= AMBUSH_TRIGGER_RADIUS then
			self:SetState("Pounce")
			return
		end

		coroutine.yield()
	end

	self:SetState("Wander")
end

local AMBUSH_TP_LIFT = Vector(0, 0, 10)

function ENT:StateAmbushTP()
	self.Target = self:FindClosestPlayer()

	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	local hideSpot = self:FindHideSpot(AMBUSH_SCAN_RAD)
	if not hideSpot then
		self:SetState("Wander")
		return
	end

	self:SetPos(hideSpot + AMBUSH_TP_LIFT)

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsObservedBy(self.Target) then
			-- DO SOMETHING
		end

		local dist = self:GetPos():Distance(self.Target:GetPos())

		if dist <= AMBUSH_TRIGGER_RADIUS then
			self:SetState("Pounce")
			return
		end

		coroutine.yield()
	end

	self:SetState("Wander")
end
