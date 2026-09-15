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

-- Listen for third-person toggles and flag the player
net.Receive("Asuabot_ThirdPersonToggle", function(len, ply)
	if IsValid(ply) then
		ply.Asuabot_IsThirdPerson = true

		-- Reset the flag after a short delay so they aren't permanently marked
		timer.Simple(2, function()
			if IsValid(ply) then
				ply.Asuabot_IsThirdPerson = false
			end
		end)
	end
end)

function ENT:Initialize()
	self:SetModel("models/player/kleiner.mdl") -- Invisible physical hull
	self:SetHealth(1000)
	self:SetCollisionGroup(COLLISION_GROUP_NPC)
	self:SetSolid(SOLID_BBOX)

	self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))

	-- self:TeleportToDistantNavSpot()
	self.CurrentState = "Stalk"
end

-- ==========================================
-- Helper Functions
-- ==========================================

-- Checks if the Nextbot is inside the player's FOV and not behind a wall
function ENT:IsObservedBy(ply)
	if not IsValid(ply) then
		return false
	end
	if not ply:IsLineOfSightClear(self) then
		return false
	end

	local dirToBot = (self:GetPos() - ply:GetPos()):GetNormalized()
	local plyAim = ply:GetAimVector()
	return plyAim:Dot(dirToBot) > 0.5
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
		elseif self.CurrentState == "Peek" then
			self:StatePeek()
		elseif self.CurrentState == "Behind" then
			self:StateBehind()
		elseif self.CurrentState == "Avoid" then
			self:StateAvoid()
		elseif self.CurrentState == "FakeOutRush" then
			self:StateFakeOutRush()
		else
			-- Fallback if state is undefined
			self.CurrentState = "Wander"
			self:StateWander()
		end

		-- Safety yield: Prevents infinite loop server crashes if a state function exits immediately
		coroutine.yield()
	end
end
