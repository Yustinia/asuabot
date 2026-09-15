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

-- cl_init.lua additions

net.Receive("Asuabot_DisplayJumpscare", function()
	local duration = net.ReadFloat() or 1.5
	local hideTime = CurTime() + duration

	-- Hook into HUDPaint to render full-screen image overlay
	hook.Add("HUDPaint", "Asuabot_JumpscareOverlay", function()
		if CurTime() > hideTime then
			hook.Remove("HUDPaint", "Asuabot_JumpscareOverlay")
			return
		end

		-- Covers the entire display screen using the placeholder material
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(botMaterial)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end)
end)
