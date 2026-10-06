function Consider(raw, lo, hi, curveFn)
	local x = math.Clamp((raw - lo) / (hi - lo), 0, 1)
	return curveFn(x)
end

function WeightedGeoMean(entries)
	local acc, sumW = 0, 0

	for _, e in pairs(entries) do
		if e.score <= 0 then
			return 0
		end

		acc = acc + e.weight * math.log(e.score)
		sumW = sumW + e.weight
	end

	return math.exp(acc / sumW)
end
