AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

include("states/state_aggression.lua")
include("states/state_cinematic.lua")
include("states/state_evasion.lua")
include("states/state_movement.lua")
include("states/state_stealth.lua")

util.AddNetworkString("Asuabot_ThirdPersonToggle")
util.AddNetworkString("Asuabot_DisplayJumpscare")

net.Receive("Asuabot_ThirdPersonToggle", function(len, ply)
	if IsValid(ply) then
		ply.Asuabot_IsThirdPerson = true

		timer.Simple(2, function()
			if IsValid(ply) then
				ply.Asuabot_IsThirdPerson = false
			end
		end)
	end
end)

function ENT:Initialize()
	self:SetModel("models/player/kleiner.mdl")
	self:SetHealth(1000)
	self:SetCollisionGroup(COLLISION_GROUP_NPC)
	self:SetSolid(SOLID_BBOX)

	self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))

	self:TeleportToDistantNavSpot()
	self.CurrentState = "Wander"
end

-- Nextbot loop
function ENT:RunBehaviour()
	while true do
		if self.CurrentState == "Wander" then
			self:StateWander()
		elseif self.CurrentState == "Chase" then
			self:StateChase()
		elseif self.CurrentState == "Rushing" then
			self:StateRushing()
		elseif self.CurrentState == "Flickering" then
			self:StateFlickering()
		elseif self.CurrentState == "Stalk" then
			self:StateStalk()
		elseif self.CurrentState == "Behind" then
			self:StateBehind()
		elseif self.CurrentState == "Avoid" then
			self:StateAvoid()
		elseif self.CurrentState == "FakeOutRush" then
			self:StateFakeOutRush()
		else
			self.CurrentState = "Wander"
			self:StateWander()
		end

		coroutine.yield()
	end
end
