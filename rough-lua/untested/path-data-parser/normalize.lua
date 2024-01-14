-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the path-data-parser JavaScript library.
-- (https://github.com/pshihn/path-data-parser/)
-- License: MIT
-- Copyright (c) 2019 Preet Shihn
--
local jsshims = require("rough-lua.rough.jsshims")
local array_concat = jsshims.array_concat

local function degToRad (degrees)
  return (math.pi * degrees) / 180
end

local function rotate (x, y, angleRad)
  local X = x * math.cos(angleRad) - y * math.sin(angleRad)
  local Y = x * math.sin(angleRad) + y * math.cos(angleRad)
  return { X, Y }
end

local function arcToCubicCurves (x1, y1, x2, y2, r1, r2, angle, largeArcFlag, sweepFlag, recursive)
  local angleRad = degToRad(angle)
  local params = {}
  local f1, f2, cx, cy
  if recursive then
    f1, f2, cx, cy = recursive[1], recursive[2], recursive[3], recursive[4]
  else
    x1, y1 = rotate(x1, y1, -angleRad)
    x2, y2 = rotate(x2, y2, -angleRad)
    local x = (x1 - x2) / 2
    local y = (y1 - y2) / 2
    local h = (x * x) / (r1 * r1) + (y * y) / (r2 * r2)
    if h > 1 then
      h = math.sqrt(h)
      r1 = h * r1
      r2 = h * r2
    end
    local sign = (largeArcFlag == sweepFlag) and -1 or 1
    local r1Pow = r1 * r1
    local r2Pow = r2 * r2
    local left = r1Pow * r2Pow - r1Pow * y * y - r2Pow * x * x
    local right = r1Pow * y * y + r2Pow * x * x
    local k = sign * math.sqrt(math.abs(left / right))
    cx = k * r1 * y / r2 + (x1 + x2) / 2
    cy = k * -r2 * x / r1 + (y1 + y2) / 2
    f1 = math.asin(((y1 - cy) / r2))
    f2 = math.asin(((y2 - cy) / r2))
    if x1 < cx then
      f1 = math.pi - f1
    end
    if x2 < cx then
      f2 = math.pi - f2
    end
    if f1 < 0 then
      f1 = math.pi * 2 + f1
    end
    if f2 < 0 then
      f2 = math.pi * 2 + f2
    end
    if sweepFlag and f1 > f2 then
      f1 = f1 - math.pi * 2
    end
    if not sweepFlag and f2 > f1 then
      f2 = f2 - math.pi * 2
    end
  end
  local df = f2 - f1
  if math.abs(df) > (math.pi * 120 / 180) then
    local f2old = f2
    local x2old = x2
    local y2old = y2
    if sweepFlag and f2 > f1 then
      f2 = f1 + (math.pi * 120 / 180) * (1)
    else
      f2 = f1 + (math.pi * 120 / 180) * (-1)
    end
    x2 = cx + r1 * math.cos(f2)
    y2 = cy + r2 * math.sin(f2)
    params = arcToCubicCurves(x2, y2, x2old, y2old, r1, r2, angle, 0, sweepFlag, { f2, f2old, cx, cy })
  end
  df = f2 - f1
  local c1 = math.cos(f1)
  local s1 = math.sin(f1)
  local c2 = math.cos(f2)
  local s2 = math.sin(f2)
  local t = math.tan(df / 4)
  local hx = 4 / 3 * r1 * t
  local hy = 4 / 3 * r2 * t
  local m1 = { x1, y1 }
  local m2 = { x1 + hx * s1, y1 - hy * c1 }
  local m3 = { x2 + hx * s2, y2 - hy * c2 }
  local m4 = { x2, y2 }
  m2[1] = 2 * m1[1] - m2[1]
  m2[2] = 2 * m1[2] - m2[2]
  if recursive then
    return array_concat({ m2, m3, m4 }, params)
  else
    params = array_concat({ m2, m3, m4 }, params)
    local curves = {}
    for i = 1, #params, 3 do
      local ro1 = rotate(params[i][1], params[i][2], angleRad)
      local ro2 = rotate(params[i + 1][1], params[i + 1][2], angleRad)
      local ro3 = rotate(params[i + 2][1], params[i + 2][2], angleRad)
      curves[#curves + 1] = { ro1[1], ro1[2], ro2[1], ro2[2], ro3[1], ro3[2] }
    end
    return curves
  end
end

local function normalize(segments)
  local out = {}
  local lastType = ''
  local cx, cy = 0, 0
  local subx, suby = 0, 0
  local lcx, lcy = 0, 0
  for _, segment in ipairs(segments) do
    local key, data = segment.key, segment.data
    if key == 'M' then
      out[#out + 1] = { key = 'M', data = pl.tablex.copy(data) }
      cx, cy = data[1], data[2]
      subx, suby = data[1], data[2]
    elseif key == 'C' then
      out[#out + 1] = { key = 'C', data = pl.tablex.copy(data) }
      cx, cy = data[5], data[6]
      lcx, lcy = data[3], data[4]
    elseif key == 'L' then
      out[#out + 1] = { key = 'L', data = pl.tablex.copy(data) }
      cx, cy = data[1], data[2]
    elseif key == 'H' then
      cx = data[1]
      out[#out + 1] = { key = 'L', data = { cx, cy } }
    elseif key == 'V' then
      cy = data[1]
      out[#out + 1] = { key = 'L', data = { cx, cy } }
    elseif key == 'S' then
      local cx1, cy1
      if lastType == 'C' or lastType == 'S' then
        cx1 = cx + (cx - lcx)
        cy1 = cy + (cy - lcy)
      else
        cx1 = cx
        cy1 = cy
      end
      out[#out + 1] = { key = 'C', data = { cx1, cy1, pl.tablex.copy(data) } }
      lcx, lcy = data[1], data[2]
      cx, cy = data[3], data[4]
    elseif key == 'T' then
      local x, y = data[1], data[2]
      local x1, y1
      if lastType == 'Q' or lastType == 'T' then
        x1 = cx + (cx - lcx)
        y1 = cy + (cy - lcy)
      else
        x1 = cx
        y1 = cy
      end
      local cx1 = cx + 2 * (x1 - cx) / 3
      local cy1 = cy + 2 * (y1 - cy) / 3
      local cx2 = x + 2 * (x1 - x) / 3
      local cy2 = y + 2 * (y1 - y) / 3
      out[#out + 1] = { key = 'C', data = { cx1, cy1, cx2, cy2, x, y } }
      lcx, lcy = x1, y1
      cx, cy = x, y
    elseif key == 'Q' then
      local x1, y1, x, y = data[1], data[2], data[3], data[4]
      local cx1 = cx + 2 * (x1 - cx) / 3
      local cy1 = cy + 2 * (y1 - cy) / 3
      local cx2 = x + 2 * (x1 - x) / 3
      local cy2 = y + 2 * (y1 - y) / 3
      out[#out + 1] = { key = 'C', data = { cx1, cy1, cx2, cy2, x, y } }
      lcx, lcy = x1, y1
      cx, cy = x, y
    elseif key == 'A' then
      local r1, r2 = math.abs(data[1]), math.abs(data[2])
      local angle = data[3]
      local largeArcFlag = data[4]
      local sweepFlag = data[5]
      local x, y = data[6], data[7]
      if r1 == 0 or r2 == 0 then
        out[#out + 1] = { key = 'C', data = { cx, cy, x, y, x, y } }
        cx, cy = x, y
      else
        if cx ~= x or cy ~= y then
          local curves = arcToCubicCurves(cx, cy, x, y, r1, r2, angle, largeArcFlag, sweepFlag)
          for _, curve in ipairs(curves) do
            out[#out + 1] = { key = 'C', data = curve }
          end
          cx, cy = x, y
        end
      end
    elseif key == 'Z' then
      out[#out + 1] = { key = 'Z', data = {} }
      cx, cy = subx, suby
    end
    lastType = key
  end
  return out
end

return {
  normalize = normalize,
  arcToCubicCurves = arcToCubicCurves,
}
