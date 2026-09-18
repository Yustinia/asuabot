include("shared.lua")

-- Using a default Garry's Mod sprite material as a placeholder
local botMaterial = Material("vgui/entities/npc_asuabot")

function ENT:Draw()
	render.SetMaterial(botMaterial)
	render.DrawSprite(self:GetPos() + Vector(0, 0, 50), 100, 100, color_white)
end
