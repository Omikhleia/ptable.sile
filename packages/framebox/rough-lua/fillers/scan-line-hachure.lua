--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
local hachureLines = require("packages.framebox.rough-lua.fillers.hachure-fill").hachureLines

local jsshims = require("packages.framebox.rough-lua.jsshims")
local math_round = jsshims.math_round

local PRNG = require("packages.framebox.graphics.prng")
local prng = PRNG()

local function polygonHachureLines (polygonList, o)
  local angle = o.hachureAngle + 90
  local gap = o.hachureGap
  if gap < 0 then
    gap = o.strokeWidth * 4
  end
  gap = math_round(math.max(gap, 0.1))
  local skipOffset = 1
  if o.roughness >= 1 then
    if prng:random() > 0.7 then
      skipOffset = gap
    end
  end
  return hachureLines(polygonList, gap, angle, skipOffset or 1)
end

return {
  polygonHachureLines = polygonHachureLines,
}
