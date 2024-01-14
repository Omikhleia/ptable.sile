--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the bezier-points JavaScript library.
-- (https://github.com/pshihn/bezier-points)
-- License: MIT
-- Copyright (c) 2020 Preet Shihn
--

local function lerp (a, b, t)
  return {a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t}
end

-- Distance between 2 points squared
local function distanceSq (p1, p2)
  return (p1[1] - p2[1]) ^ 2 + (p1[2] - p2[2]) ^ 2
end

-- Distance squared from a point p to the line segment vw
local function distanceToSegmentSq (p, v, w)
  local l2 = distanceSq(v, w)
  if l2 == 0 then
    return distanceSq(p, v)
  end
  local t = ((p[1] - v[1]) * (w[1] - v[1]) + (p[2] - v[2]) * (w[2] - v[2])) / l2
  t = math.max(0, math.min(1, t))
  return distanceSq(p, lerp(v, w, t))
end

-- Adapted from https://seant23.wordpress.com/2010/11/12/offset-bezier-curves/
local function flatness (points, offset)
  local p1 = points[offset + 1]
  local p2 = points[offset + 2]
  local p3 = points[offset + 3]
  local p4 = points[offset + 4]

  local ux = 3 * p2[1] - 2 * p1[1] - p4[1]
  ux = ux * ux
  local uy = 3 * p2[2] - 2 * p1[2] - p4[2]
  uy = uy * uy
  local vx = 3 * p3[1] - 2 * p4[1] - p1[1]
  vx = vx * vx
  local vy = 3 * p3[2] - 2 * p4[2] - p1[2]
  vy = vy * vy

  if ux < vx then
    ux = vx
  end
  if uy < vy then
    uy = vy
  end
  return ux + uy
end

local function getPointsOnBezierCurveWithSplitting (points, offset, tolerance, newPoints)
  local outPoints = newPoints or {}
  if flatness(points, offset) < tolerance then
    local p0 = points[offset + 1]
    if #outPoints > 0 then
      local d = math.sqrt(distanceSq(outPoints[#outPoints], p0))
      if d > 1 then
        table.insert(outPoints, p0)
      end
    else
      table.insert(outPoints, p0)
    end
    table.insert(outPoints, points[offset + 4])
  else
    -- subdivide
    local t = .5
    local p1 = points[offset + 1]
    local p2 = points[offset + 2]
    local p3 = points[offset + 3]
    local p4 = points[offset + 4]

    local q1 = lerp(p1, p2, t)
    local q2 = lerp(p2, p3, t)
    local q3 = lerp(p3, p4, t)

    local r1 = lerp(q1, q2, t)
    local r2 = lerp(q2, q3, t)

    local red = lerp(r1, r2, t)

    getPointsOnBezierCurveWithSplitting({p1, q1, r1, red}, 0, tolerance, outPoints)
    getPointsOnBezierCurveWithSplitting({red, r2, q3, p4}, 0, tolerance, outPoints)
  end
  return outPoints
end

-- Ramer–Douglas–Peucker algorithm
-- https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
local function simplifyPoints (points, start, finish, distance)
  local outPoints = {}
  local s = points[start]
  local e = points[finish]
  local maxDistSq = 0
  local maxNdx = 1
  for i = start + 1, finish - 1 do
    local distSq = distanceToSegmentSq(points[i], s, e)
    if distSq > maxDistSq then
      maxDistSq = distSq
      maxNdx = i
    end
  end
  if math.sqrt(maxDistSq) > distance then
    local t1 = simplifyPoints(points, start, maxNdx + 1, distance)
    local t2 = simplifyPoints(points, maxNdx, finish, distance)
    for _, v in ipairs(t1) do
      table.insert(outPoints, v)
    end
    for _, v in ipairs(t2) do
      table.insert(outPoints, v)
    end
  else
    if #outPoints == 0 then
      table.insert(outPoints, s)
    end
    table.insert(outPoints, e)
  end
  return outPoints
end

local function simplify (points, distance)
  return simplifyPoints(points, 1, #points, distance)
end

local function pointsOnBezierCurves (points, tolerance, distance)
  local newPoints = {}
  local numSegments = (#points - 1) / 3
  for i = 0, numSegments - 1 do
    local offset = i * 3
    getPointsOnBezierCurveWithSplitting(points, offset, tolerance, newPoints)
  end
  if distance and distance > 0 then
    return simplifyPoints(newPoints, 1, #newPoints, distance)
  end
  return newPoints
end

-- Exports

return {
  simplify = simplify,
  simplifyPoints = simplifyPoints,
  pointsOnBezierCurves = pointsOnBezierCurves,
}
