Curves = {}

local function Clamp01(x)
	return math.Clamp(x, 0, 1)
end

--- Starts slow and speeds up as it goes (like pressing harder on the gas pedal).
-- Keeps the input value between 0 and 1, then multiplies it by itself 'k' times.
-- @param x number: The current progress or input value (usually from 0 to 1).
-- @param k number|nil: How steep or sharp the curve is (defaults to 2 if omitted).
-- @return number: The calculated curve value.
function Curves.PowerIn(x, k)
	x = Clamp01(x)
	k = k or 2

	return math.pow(x, k)
end

--- Starts high and curves down to zero, dropping faster as it goes (the opposite of PowerIn).
-- Keeps the input value between 0 and 1, calculates the power, and flips the result.
-- @param x number: The current progress or input value (usually from 0 to 1).
-- @param k number|nil: How steep or sharp the curve is (defaults to 2 if omitted).
-- @return number: The inverted curve value starting at 1 and ending at 0.
function Curves.PowerInverseIn(x, k)
	x = Clamp01(x)
	k = k or 2

	return 1 - math.pow(x, k)
end

--- Starts at 1 and drops quickly at first, then slows down as it reaches 0.
-- Keeps the input value between 0 and 1, flips the progress, and multiplies it by itself 'k' times.
-- @param x number: The current progress or input value (usually from 0 to 1).
-- @param k number|nil: How steep or sharp the curve is (defaults to 2 if omitted).
-- @return number: The calculated curve value moving from 1 down to 0.
function Curves.PowerInverseOut(x, k)
	x = Clamp01(x)
	k = k or 2

	return math.pow((1 - x), k)
end

--- Starts fast and slows down to a gentle stop (like hitting the brakes on a car).
-- Keeps the input value between 0 and 1, flips the progress to apply the power, then flips the result back.
-- @param x number: The current progress or input value (usually from 0 to 1).
-- @param k number|nil: How steep or sharp the curve is (defaults to 2 if omitted).
-- @return number: The calculated curve value starting slow and leveling out near 1.
function Curves.PowerOut(x, k)
	x = Clamp01(x)
	k = k or 2

	return 1 - math.pow((1 - x), k)
end

--- Moves at a constant, steady speed from start to finish with no acceleration or slowdown.
-- Ensures the input stays safely between 0 and 1.
-- @param x number: The current progress or input value.
-- @return number: The original value clamped between 0 and 1.
-- [Source: Standard definition in computer graphics / easing functions]
function Curves.LinearIn(x)
	return Clamp01(x)
end

--- Moves at a constant, steady speed in reverse, going straight from 1 down to 0.
-- Ensures the input stays safely between 0 and 1, then flips the direction.
-- @param x number: The current progress or input value.
-- @return number: The reversed value moving from 1 down to 0.
function Curves.LinearOut(x)
	return 1 - Clamp01(x)
end

return Curves
