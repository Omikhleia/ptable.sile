--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
local hachureLines = require("rough-lua.rough.fillers.hachure-fill").hachureLines

local jsshims = require("rough-lua.rough.jsshims")
local math_round = jsshims.math_round

local PRNG = require("prng-prigarin")

local function polygonHachureLines (polygonList, o)
  local angle = o.hachureAngle + 90
  local gap = o.hachureGap
  if gap < 0 then
    gap = o.strokeWidth * 4
  end
  gap = math_round(math.max(gap, 0.1))
  local skipOffset = 1
  if o.roughness >= 1 then
    -- PORTING NOTE: Slightly different approach to randomization.
    -- We never rely on math.random() but always use our PRNG.
    local rand = o.randomizer and o.randomizer:random() or PRNG(o.seed or 0):random()
    if rand > 0.7 then
      skipOffset = gap
    end
  end
  return hachureLines(polygonList, gap, angle, skipOffset or 1)
end

return {
  polygonHachureLines = polygonHachureLines,
}
