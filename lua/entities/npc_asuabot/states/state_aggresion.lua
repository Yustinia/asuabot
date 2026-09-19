local CHASE_SPD = 600
local CHASE_ACCEL = 300
local CHASE_GOAL_THRESH = 0
local CHASE_AHEAD_DIST = 140
local CHASE_DMG = 20
local CHASE_LIFETIME_DUR = 12
local CHASE_PATH_AGE = 0.1
local CHASE_LOST_TARGET_DUR = 5

local RUSH_SPD = 1200
local RUSH_ACCEL = 1200
local RUSH_GOAL_THRESH = 0
local RUSH_AHEAD_DIST = 300
local RUSH_DMG = 40
local RUSH_LIFETIME_DUR = 20
local RUSH_PATH_AGE = 0.1

local BLINK_SPD = 600
local BLINK_ACCEL = 600
local BLINK_LIFETIME_DUR = 12
local BLINK_PATH_AGE = 0.4
local BLINK_STARE_LIFETIME_DUR = 4
local BLINK_AHEAD_DIST = 100
local BLINK_GOAL_THRESH = 0
local BLINK_DMG = 20

function ENT:StateChase()
	self:HandleSpeed(CHASE_SPD, CHASE_ACCEL)

	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	self:ComputeRoutingPath(self.Target, CHASE_AHEAD_DIST, CHASE_GOAL_THRESH, "Chase")

	local chaseStartTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			self:DamageEntity(self.Target, CHASE_DMG)

			if math.random(1, 2) == 1 then
				self:TeleportToDistantNavSpot()
			end

			self:SetState("Wander")
			return
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		elseif CurTime() - self.TargetLastSeenTime > CHASE_LOST_TARGET_DUR then
			self:SetState("Wander")
			return
		end

		if CurTime() - chaseStartTime > CHASE_LIFETIME_DUR then
			self:SetState("Wander")
			return
		end

		self:RefreshPathIfStale(CHASE_PATH_AGE, self.Target, "Chase")

		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end

function ENT:StateRush()
	self:HandleSpeed(RUSH_SPD, RUSH_ACCEL)

	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self:SetState("Wander")
		return
	end

	self:ComputeRoutingPath(self.Target, RUSH_AHEAD_DIST, RUSH_GOAL_THRESH, "Chase")

	local chaseStartTime = CurTime()

	while IsValid(self.Target) and self.Target:Alive() do
		if self:IsTouchingPlayer(self.Target) then
			self:DamageEntity(self.Target, RUSH_DMG)

			if math.random(1, 2) == 1 then
				self:TeleportToDistantNavSpot()
			end

			self:SetState("Wander")
			return
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		if CurTime() - chaseStartTime > RUSH_LIFETIME_DUR then
			self:SetState("Wander")
			return
		end

		self:RefreshPathIfStale(RUSH_PATH_AGE, self.Target, "Chase")

		self.Path:Update(self)
		self:ClearObstacles()
		coroutine.yield()
	end
end

function ENT:StateBlink()
	self.Target = self:FindClosestPlayer()
	if not IsValid(self.Target) then
		self.CurrentState = "Wander"
		return
	end

	self:ComputeRoutingPath(self.Target, BLINK_AHEAD_DIST, BLINK_GOAL_THRESH, "Chase")

	local observedStartTime = 0
	local blinkStartTime = CurTime()
	local isCurrentlyObserved = false

	while IsValid(self.Target) and self.Target:Alive() do
		if CurTime() - blinkStartTime >= BLINK_LIFETIME_DUR then
			self:TeleportToDistantNavSpot()
			self:SetState("Wander")
			return
		end

		if self:IsTouchingPlayer(self.Target) then
			self:DamageEntity(self.Target, BLINK_DMG)

			-- DO SOMETHING

			self:SetState("Wander")
			return
		end

		if self:IsTargetVisible(self.Target) then
			self.TargetLastSeenTime = CurTime()
			self.TargetLastSeenPos = self.Target:GetPos()
			self:RecordLastSeenPosition(self.Target:GetPos())
		end

		local wasObserved = isCurrentlyObserved
		isCurrentlyObserved = self:IsObservedBy(self.Target)

		if isCurrentlyObserved then
			self:HandleSpeed(0, 0)

			if not wasObserved then
				observedStartTime = CurTime()
			end

			if CurTime() - observedStartTime >= BLINK_STARE_LIFETIME_DUR then
				self:TeleportToDistantNavSpot()
				self.CurrentState = "Wander"
				return
			end
		else
			self:HandleSpeed(BLINK_SPD, BLINK_ACCEL)

			self:RefreshPathIfStale(BLINK_PATH_AGE, self.Target, "Chase")

			self.Path:Update(self)
			self:ClearObstacles()
		end

		coroutine.yield()
	end
end
