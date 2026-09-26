-- function ENT:FindNearestNavArea() end
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
-- function ENT:FindNavAreaByCondition() end
-- function ENT:CheckNavReachability() end
-- function ENT:GetNavAreaConnections() end
-- function ENT:GetNavAreaSize() end
