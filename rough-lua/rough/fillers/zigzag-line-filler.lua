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

local jsshims = require("rough-lua.rough.jsshims")
local math_round = jsshims.math_round

local ZigZagLineFiller = pl.class()

function ZigZagLineFiller:_init (helper)
  self.helper = helper
end

function ZigZagLineFiller:fillPolygons (polygonList, o)
  local gap = o.hachureGap < 0 and (o.strokeWidth * 4) or o.hachureGap
  local zo = o.zigzagOffset < 0 and gap or o.zigzagOffset
  o = pl.tablex.copy(o)
  o.hachureGap = gap + zo
  local lines = polygonHachureLines(polygonList, o)
  return { type = 'fillSketch', ops = self:zigzagLines(lines, zo, o) }
end

function ZigZagLineFiller:zigzagLines (lines, zo, o)
  local ops = {}
  for _, line in ipairs(lines) do
    local length = lineLength(line)
    local count = math_round(length / (2 * zo))
    local p1 = line[1]
    local p2 = line[2]
    if p1[1] > p2[1] then
      p1 = line[2]
      p2 = line[1]
    end
    local alpha = math.atan((p2[2] - p1[2]) / (p2[1] - p1[1]))
    for i = 0, count - 1 do
      local lstart = i * 2 * zo
      local lend = (i + 1) * 2 * zo
      local dz = math.sqrt(2 * zo^2) -- = JS Math.sqrt(2 * Math.pow(zo, 2)) dubious?
      local start = { p1[1] + (lstart * math.cos(alpha)), p1[2] + lstart * math.sin(alpha) }
      local end_ = { p1[1] + (lend * math.cos(alpha)), p1[2] + (lend * math.sin(alpha)) }
      local middle = { start[1] + dz * math.cos(alpha + math.pi / 4), start[2] + dz * math.sin(alpha + math.pi / 4) }
      local t = self.helper.doubleLineOps(start[1], start[2], middle[1], middle[2], o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
      t = self.helper.doubleLineOps(middle[1], middle[2], end_[1], end_[2], o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
    end
  end
  return ops
end

return {
  ZigZagLineFiller = ZigZagLineFiller,
}
