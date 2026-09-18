AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

include("ability/location.lua")
include("ability/maneuver.lua")
include("ability/movement.lua")
include("ability/perception.lua")
include("ability/physical.lua")

include("states/state_movement.lua")

function ENT:Initialize()
	-- Model / appearance
	self:SetModel("models/player/kleiner.mdl")
	self:SetSpawnEffect(false)

	-- Health
	self:SetHealth(99999)
	self:SetMaxHealth(99999)

	-- Collision / movement
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_NPC)
	self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))

	-- NextBot vision
	self:SetFOV(360)
	self:SetMaxVisionRange(10000)

	-- NextBot Status
	self.loco:SetStepHeight(18)
	self.loco:SetJumpHeight(58)
	self.loco:SetDeathDropHeight(200)

	-- Navmesh cache
	self.CachedNavAreas = navmesh.GetAllNavAreas()

	-- AI State
	self.CurrentState = "Wander"

	self.Target = nil
	self.TargetLastSeenPos = nil
	self.TargetLastSeenTime = 0

	self.PlayerList = {}

	self.Path = nil

	-- Timing
	self.PushIntensity = 1500
	self.PushCD = 0.5
	self.NextPushTime = 0

	self.DamageCD = 0.5
	self.NextDamageTime = 0

	-- Movement
	self.StuckTries = 0
	self.StuckMax = 3
	self.LastStuck = 0

	self.ProgressPos = nil
	self.ProgressTime = 0

	-- Spawn Initialization
	-- self:TeleportToDistantNavSpot(self.CachedNavAreas)
end

-- Nextbot loop
function ENT:RunBehaviour()
	while true do
		if self.CurrentState == "Wander" then
			self:StateWander()
		else
			self.CurrentState = "Wander"
			self:StateWander()
		end

		coroutine.yield()
	end
end
