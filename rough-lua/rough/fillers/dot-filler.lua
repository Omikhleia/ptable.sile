--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
local polygonHachureLines = require("rough-lua.rough.fillers.scan-line-hachure").polygonHachureLines
local lineLength = require("rough-lua.rough.geometry").lineLength

local DotFiller = pl.class()

function DotFiller:_init (helper)
  self.helper = helper
end

function DotFiller:fillPolygons (polygonList, o)
  o = pl.tablex.deepcopy(o)
  o.hachureAngle = 0
  local lines = polygonHachureLines(polygonList, o)
  return self:dotsOnLines(lines, o)
end

function DotFiller:dotsOnLines (lines, o)
  local ops = {}
  local gap = o.hachureGap
  if gap < 0 then
    gap = o.strokeWidth * 4
  end
  gap = math.max(gap, 0.1)
  local fweight = o.fillWeight
  if fweight < 0 then
    fweight = o.strokeWidth / 2
  end
  local ro = gap / 4
  for _, line in ipairs(lines) do
    local length = lineLength(line)
    local dl = length / gap
    local count = math.ceil(dl) - 1
    local offset = length - (count * gap)
    local x = ((line[1][1] + line[2][1]) / 2) - (gap / 4)
    local minY = math.min(line[1][2], line[2][2])
    for i = 0, count - 1 do
      local y = minY + offset + (i * gap)
      local cx = (x - ro) + math.random() * 2 * ro
      local cy = (y - ro) + math.random() * 2 * ro
      local el = self.helper.ellipse(cx, cy, fweight, fweight, o)
      pl.tablex.insertvalues(ops, el.ops) -- = JS ops.push(...el.ops)
    end
  end
  return { type = 'fillSketch', ops = ops }
end

return {
  DotFiller = DotFiller
}
