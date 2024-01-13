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

local DashedFiller = pl.class()

function DashedFiller:_init (helper)
  self.helper = helper
end

function DashedFiller:fillPolygons (polygonList, o)
  local lines = polygonHachureLines(polygonList, o)
  return { type = 'fillSketch', ops = self:dashedLine(lines, o) }
end

function DashedFiller:dashedLine (lines, o)
  local offset = o.dashOffset < 0 and (o.hachureGap < 0 and (o.strokeWidth * 4) or o.hachureGap) or o.dashOffset
  local gap = o.dashGap < 0 and (o.hachureGap < 0 and (o.strokeWidth * 4) or o.hachureGap) or o.dashGap
  local ops = {}
  for _, line in ipairs(lines) do
    local length = lineLength(line)
    local count = math.floor(length / (offset + gap))
    local startOffset = (length + gap - (count * (offset + gap))) / 2
    local p1 = line[1]
    local p2 = line[2]
    if p1[1] > p2[1] then
      p1 = line[2]
      p2 = line[1]
    end
    local alpha = math.atan((p2[2] - p1[2]) / (p2[1] - p1[1]))
    for i = 0, count - 1 do
      local lstart = i * (offset + gap)
      local lend = lstart + offset
      local start = { p1[1] + (lstart * math.cos(alpha)) + (startOffset * math.cos(alpha)), p1[2] + lstart * math.sin(alpha) + (startOffset * math.sin(alpha)) }
      local end_ = { p1[1] + (lend * math.cos(alpha)) + (startOffset * math.cos(alpha)), p1[2] + (lend * math.sin(alpha)) + (startOffset * math.sin(alpha)) }
      local t = self.helper.doubleLineOps(start[1], start[2], end_[1], end_[2], o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
    end
  end
  return ops
end

return {
  DashedFiller = DashedFiller
}
