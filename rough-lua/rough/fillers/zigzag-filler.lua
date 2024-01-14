--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
local HachureFiller = require("rough-lua.rough.fillers.hachure-filler").HachureFiller
local polygonHachureLines = require("rough-lua.rough.fillers.scan-line-hachure").polygonHachureLines
local lineLength = require("rough-lua.rough.geometry").lineLength

local ZigZagFiller = pl.class(HachureFiller)

function ZigZagFiller:fillPolygons (polygonList, o)
  local gap = o.hachureGap
  if gap < 0 then
    gap = o.strokeWidth * 4
  end
  gap = math.max(gap, 0.1)
  local o2 = pl.tablex.deepcopy(o)
  o2.hachureGap = gap
  local lines = polygonHachureLines(polygonList, o2)
  local zigZagAngle = (math.pi / 180) * o.hachureAngle
  local zigzagLines = {}
  local dgx = gap * 0.5 * math.cos(zigZagAngle)
  local dgy = gap * 0.5 * math.sin(zigZagAngle)
  for _, line in ipairs(lines) do
    if lineLength(line) then
      zigzagLines[#zigzagLines + 1] = {
        { line[1][1] - dgx, line[1][2] + dgy },
        { line[2][1], line[2][2] },
      }
      zigzagLines[#zigzagLines + 1] = {
        { line[1][1] + dgx, line[1][2] - dgy },
        { line[2][1], line[2][2] },
      }
    end
  end
  local ops = self:renderLines(zigzagLines, o)
  return { type = 'fillSketch', ops = ops }
end

return {
  ZigZagFiller = ZigZagFiller
}
