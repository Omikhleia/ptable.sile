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

local HachureFiller = pl.class()

function HachureFiller:_init (helper)
  self.helper = helper
end

function HachureFiller:fillPolygons (polygonList, o)
  local lines = polygonHachureLines(polygonList, o)
  local ops = self:renderLines(lines, o)
  return { type = 'fillSketch', ops = ops }
end

function HachureFiller:renderLines (lines, o)
  local ops = {}
  for _, line in ipairs(lines) do
    local t = self.helper.doubleLineOps(line[1][1], line[1][2], line[2][1], line[2][2], o)
    pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
  end
  return ops
end

return {
  HachureFiller = HachureFiller,
}
