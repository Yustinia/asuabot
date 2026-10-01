function ENT:GetPlayerHealth(target)
	if not IsValid(target) then
		return
	end

	return target:Health()
end
