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
	self:SetModel("models/player/kleiner.mdl")
	self:SetSpawnEffect(false)
	self:SetHealth(99999)
	self:SetCollisionGroup(COLLISION_GROUP_NPC)
	self:SetSolid(SOLID_BBOX)
	self:SetFOV(360)
	self:SetMaxVisionRange(10000)

	self:SetCollisionBounds(Vector(-8, -8, 0), Vector(8, 8, 8))

	self.CachedNavAreas = navmesh.GetAllNavAreas()

	self.NextPushTime = 0
	self.NextDamageTime = 0

	self.StuckTries = 0
	self.LastStuck = 0

	-- self:TeleportToDistantNavSpot(self.CachedNavAreas)
	self.CurrentState = "Wander"
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
