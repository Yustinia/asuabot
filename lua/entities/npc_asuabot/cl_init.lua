include("shared.lua")

-- Using a default Garry's Mod sprite material as a placeholder
local botMaterial = Material("sprites/glow04_noz")

function ENT:Draw()
	-- Render a 2D sprite at the bot's position, elevated slightly (Z axis)
	render.SetMaterial(botMaterial)
	-- Width and Height set to 100 HU for visibility
	render.DrawSprite(self:GetPos() + Vector(0, 0, 50), 100, 100, color_white)
end

local wasThirdPerson = false

hook.Add("Think", "Asuabot_ThirdPersonTracker", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then
		return
	end

	-- In Garry's Mod, vanilla third-person and most mods trigger this flag to render the player model
	local isThirdPerson = ply:ShouldDrawLocalPlayer()

	if isThirdPerson ~= wasThirdPerson then
		wasThirdPerson = isThirdPerson
		if isThirdPerson then
			net.Start("Asuabot_ThirdPersonToggle")
			net.SendToServer()
		end
	end
end)
