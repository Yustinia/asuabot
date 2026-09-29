function ENT:FindRandomNavArea()
	local navs = self.GlobalContext.CachedNavmesh
	if not navs or #navs == 0 then
		return nil
	end

	return navs[math.random(#navs)]:GetRandomPoint()
end

function ENT:FindDistantNavArea(scanRadius)
	scanRadius = scanRadius or 1000

	local navs = self.GlobalContext.CachedNavmesh
	if not navs or #navs == 0 then
		return nil
	end

	local botPos = self:GetPos()
	local candidateNavs = {}

	for i = 1, #navs do
		local area = navs[i]
		if area:GetCenter():Distance(botPos) > scanRadius then
			table.insert(candidateNavs, area)
		end
	end

	if #candidateNavs == 0 then
		return nil
	end

	return candidateNavs[math.random(#candidateNavs)]:GetRandomPoint()
end

function ENT:FindNearbyNavArea(scanRadius)
	scanRadius = scanRadius or 1000

	local navs = self.GlobalContext.CachedNavmesh
	if not navs or #navs == 0 then
		return nil
	end

	local botPos = self:GetPos()
	local candidateNavs = {}

	for i = 1, #navs do
		local area = navs[i]
		if area:GetCenter():Distance(botPos) < scanRadius then
			table.insert(candidateNavs, area)
		end
	end

	if #candidateNavs == 0 then
		return nil
	end

	return candidateNavs[math.random(#candidateNavs)]:GetRandomPoint()
end

--- Returns the nav areas directly connected to the given area.
-- Thin wrapper, kept for naming consistency with the rest of the capability list.
-- @param area CNavArea
-- @return table: list of adjacent CNavArea objects
function ENT:GetNavAreaConnections(area)
	if not IsValid(area) then
		return {}
	end
	return area:GetAdjacentAreas()
end

--- Returns a nav area's flat footprint size (width * length).
-- Useful for distinguishing large open rooms from small/narrow areas (chokepoints, hallways).
-- @param area CNavArea
-- @return number
function ENT:GetNavAreaSize(area)
	if not IsValid(area) then
		return 0
	end
	return area:GetSizeX() * area:GetSizeY()
end

-- function ENT:FindNavAreaByCondition() end
-- function ENT:CheckNavReachability() end
