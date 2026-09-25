local DOOR_CLASSES = { "prop_door_rotating", "func_door", "func_door_rotating" }
function ENT:FindAllDoors()
	local allDoors = {}

	for _, class in ipairs(DOOR_CLASSES) do
		for _, door in ipairs(ents.FindByClass(class)) do
			table.insert(allDoors, door)
		end
	end

	return allDoors
end

function ENT:FindClosestPlayer()
	local closest = nil
	local minDist = math.huge
	local myPos = self:GetPos()

	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE then
			local distSq = myPos:DistToSqr(ply:GetPos())
			if distSq < minDist then
				minDist = distSq
				closest = ply
			end
		end
	end
	return closest
end
