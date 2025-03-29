--- Approximate an ellipse arc with successive bezier curves.
-- Based on L. Maisonobe, "Drawing an elliptical arc using polylines,
-- quadratic orcubic Bezier curves", 2003, §3.4.1)

--- @module grail.shapes.arc
--- @copyright License: MIT (c) 2024; 2025 Omikhleia, Didier Willis

--- Compute the control points of a Bezier curve approximating an ellipse arc.
---@param x          number Position of the center of the ellipse on the x-axis
---@param y          number Position of the center of the ellipse on the y-axis
---@param a          number Semi-axis of the ellipse in the x-axis
---@param b          number Semi-axis of the ellipse in the y-axis
---@param startAngle number Start angle of the arc in radians
---@param arcAngle   number Angle of the arc in radians
---@return table     Bezier control points as a table of 8 numbers (start point, 2 control points, end point)
local function _arcBezierCurve (x, y, a, b, startAngle, arcAngle)
  local cx = x
  local cy = y
  -- Trigonometric operations used later.
  local cos1 = math.cos(startAngle)
  local sin1 = math.sin(startAngle)
  local cos2 = math.cos(startAngle + arcAngle)
  local sin2 = math.sin(startAngle + arcAngle)

  -- P1 = start point
  local p1x = cx + a * cos1
  local p1y = cy - b * sin1

  -- D1 = First derivative at start point.
  local d1x = -a * sin1
  local d1y = -b * cos1

  -- P2 = End point
  local p2x = cx + a * cos2
  local p2y = cy - b * sin2

  -- D2 = First derivative at end point
  local d2x = -a * sin2
  local d2y = -b * cos2

  -- Alpha "constant"
  local aux = math.tan(arcAngle / 2)
  local alpha = math.sin(arcAngle) * (math.sqrt(4 + 3 * aux * aux) - 1.0) / 3.0

  -- Q1 = First control point
  local q1x = p1x + alpha * d1x
  local q1y = p1y + alpha * d1y

  -- Q2 = Second control point.
  local q2x = p2x - alpha * d2x;
  local q2y = p2y - alpha * d2y;

  return { p1x, p1y, q1x, q1y, q2x, q2y, p2x, p2y }
end

--- Maximum angle per curve
-- N.B. the angle step should be computed to minimize errors, instead of
-- hard-coding a 15 degrees value here...
local maxAnglePerCurve = 15 * math.pi / 180

--- Approximate an ellipse arc with successive bezier curves.
---@param x          number Position of the center of the ellipse on the x-axis
---@param y          number Position of the center of the ellipse on the y-axis
---@param a          number Semi-axis of the ellipse in the x-axis
---@param b          number Semi-axis of the ellipse in the y-axis
---@param startAngle number Start angle of the arc in radians
---@param arcAngle   number Angle of the arc in radians
---@return table     List of curves (initial 2-point position, then 3-point curves)
local function arcToBezierCurves (x, y, a, b, startAngle, arcAngle, closed)
  local n = math.ceil(math.abs(arcAngle / maxAnglePerCurve))
  local actualArcAngle = arcAngle / n
  local currentStartAngle = startAngle
  local curves = {}

  for i = 1, n do
    local bezier = _arcBezierCurve(x, y, a, b, currentStartAngle, actualArcAngle)
    if i == 1 then
      curves[#curves + 1] = { bezier[1], bezier[2] }
    end
    curves[#curves + 1] = { bezier[3], bezier[4], bezier[5], bezier[6], bezier[7], bezier[8] }
    currentStartAngle = currentStartAngle + actualArcAngle;
  end
  if closed then
    -- Add a line to the start point
    curves[#curves+1] =  {x, y}
    -- Add a line to the arc start point
    curves[#curves+1] = { curves[1][1], curves[1][2] }
  end
  return curves
end

return arcToBezierCurves
