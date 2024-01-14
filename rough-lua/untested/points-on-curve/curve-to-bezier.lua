--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the bezier-points JavaScript library.
-- (https://github.com/pshihn/bezier-points)
-- License: MIT
-- Copyright (c) 2020 Preet Shihn
--
local function clone (p)
  return { p[1], p[2] }
end

local function curveToBezier (pointsIn, curveTightness)
  local len = #pointsIn
  if len < 3 then
    error('A curve must have at least three points.')
  end
  local out = {}
  if len == 3 then
    out[#out + 1] = clone(pointsIn[1])
    out[#out + 1] = clone(pointsIn[2])
    out[#out + 1] = clone(pointsIn[3])
    out[#out + 1] = clone(pointsIn[3])
  else
    local points = {}
    points[#points + 1] = pointsIn[1]
    points[#points + 1] = pointsIn[1]
    for i = 2, #pointsIn do
      points[#points + 1] = pointsIn[i]
      if i == (#pointsIn - 1) then
        points[#points + 1] = pointsIn[i]
      end
    end
    local b = {}
    local s = 1 - curveTightness
    out[#out + 1] = clone(points[1])
    for i = 2, (#points - 2) do
      local cachedVertArray = points[i]
      b[1] = { cachedVertArray[1], cachedVertArray[2] }
      b[2] = { cachedVertArray[1] + (s * points[i + 1][1] - s * points[i - 1][1]) / 6, cachedVertArray[2] + (s * points[i + 1][2] - s * points[i - 1][2]) / 6 }
      b[3] = { points[i + 1][1] + (s * points[i][1] - s * points[i + 2][1]) / 6, points[i + 1][2] + (s * points[i][2] - s * points[i + 2][2]) / 6 }
      b[4] = { points[i + 1][1], points[i + 1][2] }
      out[#out + 1] = b[2]
      out[#out + 1] = b[3]
      out[#out + 1] = b[4]
    end
  end
  return out
end

-- Exports

return {
  curveToBezier = curveToBezier,
}
