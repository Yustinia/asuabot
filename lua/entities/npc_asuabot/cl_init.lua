include("shared.lua")

-- Using a default Garry's Mod sprite material as a placeholder
local botMaterial = Material("vgui/entities/npc_asuabot")

function ENT:Draw()
	-- Render a 2D sprite at the bot's position, elevated slightly (Z axis)
	render.SetMaterial(botMaterial)
	-- Width and Height set to 100 HU for visibility
	render.DrawSprite(self:GetPos() + Vector(0, 0, 50), 100, 100, color_white)
end
