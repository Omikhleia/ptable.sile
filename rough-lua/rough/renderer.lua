--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--

local jsshims = require("rough-lua.rough.jsshims")
local array_concat = jsshims.array_concat
local PRNG = require("prng-prigarin")

local pathDataParser = require("rough-lua.untested.path-data-parser")
local parsePath, normalize, absolutize
        = pathDataParser.parsePath, pathDataParser.normalize, pathDataParser.absolutize

local getFiller = require("rough-lua.rough.fillers.filler").getFiller

local function cloneOptionsAlterSeed (ops)
  local result = pl.tablex.copy(ops)
  result.randomizer = nil
  if ops.seed then
    result.seed = ops.seed + 1
  end
  return result
end

local function random (ops)
  if not ops.randomizer then
    ops.randomizer = PRNG(ops.seed or 0)
  end
  return ops.randomizer:random()
end

local function _offset (min, max, ops, roughnessGain)
  return ops.roughness * (roughnessGain or 1) * ((random(ops) * (max - min)) + min)
end

local function _offsetOpt (x, ops, roughnessGain)
  return _offset(-x, x, ops, roughnessGain or 1)
end

local function _line (x1, y1, x2, y2, o, move, overlay)
  local lengthSq = (x1 - x2)^2 + (y1 - y2)^2
  local length = math.sqrt(lengthSq)
  local roughnessGain
  if length < 200 then
    roughnessGain = 1
  elseif length > 500 then
    roughnessGain = 0.4
  else
    roughnessGain = (-0.0016668) * length + 1.233334
  end

  local offset = o.maxRandomnessOffset or 0
  if (offset * offset * 100) > lengthSq then
    offset = length / 10
  end
  local halfOffset = offset / 2
  local divergePoint = 0.2 + random(o) * 0.2
  local midDispX = o.bowing * o.maxRandomnessOffset * (y2 - y1) / 200
  local midDispY = o.bowing * o.maxRandomnessOffset * (x1 - x2) / 200
  midDispX = _offsetOpt(midDispX, o, roughnessGain)
  midDispY = _offsetOpt(midDispY, o, roughnessGain)
  local ops = {}
  local randomHalf = function() return _offsetOpt(halfOffset, o, roughnessGain) end
  local randomFull = function() return _offsetOpt(offset, o, roughnessGain) end
  local preserveVertices = o.preserveVertices
  if move then
    if overlay then
      local t = {
        op = 'move',
        data = {
          x1 + (preserveVertices and 0 or randomHalf()),
          y1 + (preserveVertices and 0 or randomHalf()),
        }
      }
      ops[#ops+1] = t
    else
      local t = {
        op = 'move',
        data = {
          x1 + (preserveVertices and 0 or _offsetOpt(offset, o, roughnessGain)),
          y1 + (preserveVertices and 0 or _offsetOpt(offset, o, roughnessGain)),
        },
      }
      ops[#ops+1] = t
    end
  end
  if overlay then
    local t = {
      op = 'bcurveTo',
      data = {
          midDispX + x1 + (x2 - x1) * divergePoint + randomHalf(),
          midDispY + y1 + (y2 - y1) * divergePoint + randomHalf(),
          midDispX + x1 + 2 * (x2 - x1) * divergePoint + randomHalf(),
          midDispY + y1 + 2 * (y2 - y1) * divergePoint + randomHalf(),
          x2 + (preserveVertices and 0 or randomHalf()),
          y2 + (preserveVertices and 0 or randomHalf()),
        }
    }
    ops[#ops+1] = t
  else
    local t = {
      op = 'bcurveTo',
      data = {
        midDispX + x1 + (x2 - x1) * divergePoint + randomFull(),
        midDispY + y1 + (y2 - y1) * divergePoint + randomFull(),
        midDispX + x1 + 2 * (x2 - x1) * divergePoint + randomFull(),
        midDispY + y1 + 2 * (y2 - y1) * divergePoint + randomFull(),
        x2 + (preserveVertices and 0 or randomFull()),
        y2 + (preserveVertices and 0 or randomFull()),
      }
    }
    ops[#ops+1] = t
  end
  return ops
end

local function _doubleLine (x1, y1, x2, y2, o, filling)
  local singleStroke = filling and o.disableMultiStrokeFill or o.disableMultiStroke
  local o1 = _line(x1, y1, x2, y2, o, true, false)
  if singleStroke then
    return o1
  end
  local o2 = _line(x1, y1, x2, y2, o, true, true)
  return array_concat(o1, o2)
end

local function _curve (points, closePoint, o)
  local len = #points
  local ops = {}
  if len > 3 then
    local b = { 0,0,0,0 }
    local s = 1 - o.curveTightness
    ops[#ops+1] = {
      op = 'move',
      data = {
        points[1][1],
        points[1][2]
      }
    }
    for i = 2, len - 2 do
      local cachedVertArray = points[i]
      b[1] = { cachedVertArray[1], cachedVertArray[2] }
      b[2] = { cachedVertArray[1] + (s * points[i + 1][1] - s * points[i - 1][1]) / 6, cachedVertArray[2] + (s * points[i + 1][2] - s * points[i - 1][2]) / 6 }
      b[3] = { points[i + 1][1] + (s * points[i][1] - s * points[i + 2][1]) / 6, points[i + 1][2] + (s * points[i][2] - s * points[i + 2][2]) / 6 }
      b[4] = { points[i + 1][1], points[i + 1][2] }
      ops[#ops+1] = {
        op = 'bcurveTo',
        data = { b[2][1], b[2][2], b[3][1], b[3][2], b[4][1], b[4][2] }
      }
    end
    if closePoint and #closePoint == 2 then
      local ro = o.maxRandomnessOffset
      ops[#ops+1] = {
        op = 'lineTo',
        data = {
          closePoint[1] + _offsetOpt(ro, o),
          closePoint[2] + _offsetOpt(ro, o)
        }
      }
    end
  elseif len == 3 then
    ops[#ops+1] = {
      op = 'move',
      data = { points[1][1], points[1][2] }
    }
    ops[#ops+1] = {
      op = 'bcurveTo',
      data = { points[1][1], points[1][2], points[2][1], points[2][2], points[3][1], points[3][2] }
    }
  elseif len == 2 then
    local t = _line(points[1][1], points[1][2], points[2][1], points[2][2], o, true, true)
    pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
  end
  return ops
end

local function _curveWithOffset (points, offset, o)
  if #points == 0 then
    return {}
  end
  local ps = {}
  ps[1] = {
    points[1][1] + _offsetOpt(offset, o),
    points[1][2] + _offsetOpt(offset, o)
  }
  ps[2] = {
    points[1][1] + _offsetOpt(offset, o),
    points[1][2] + _offsetOpt(offset, o)
  }
  for i = 2, #points do
    ps[#ps+1] = {
      points[i][1] + _offsetOpt(offset, o),
      points[i][2] + _offsetOpt(offset, o)
    }
    if i == #points then
      ps[#ps+1] = {
        points[i][1] + _offsetOpt(offset, o),
        points[i][2] + _offsetOpt(offset, o)
      }
    end
  end
  return _curve(ps, nil, o)
end

local function _computeEllipsePoints (increment, cx, cy, rx, ry, offset, overlap, o)
  local coreOnly = o.roughness == 0
  local corePoints = {}
  local allPoints = {}
  if coreOnly then
    increment = increment / 4
    allPoints[1] = {
      cx + rx * math.cos(-increment),
      cy + ry * math.sin(-increment)
    }
    for angle = 0, math.pi * 2, increment do
      local p = {
        cx + rx * math.cos(angle),
        cy + ry * math.sin(angle)
      }
      corePoints[#corePoints+1] = p
      allPoints[#allPoints+1] = p
    end
    allPoints[#allPoints+1] = {
      cx + rx * math.cos(0),
      cy + ry * math.sin(0)
    }
    allPoints[#allPoints+1] = {
      cx + rx * math.cos(increment),
      cy + ry * math.sin(increment)
    }
  else
    local radOffset = _offsetOpt(0.5, o) - (math.pi / 2)
    allPoints[1] = {
      _offsetOpt(offset, o) + cx + 0.9 * rx * math.cos(radOffset - increment),
      _offsetOpt(offset, o) + cy + 0.9 * ry * math.sin(radOffset - increment)
    }
    local endAngle = math.pi * 2 + radOffset - 0.01
    for angle = radOffset, endAngle, increment do
      local p = {
        _offsetOpt(offset, o) + cx + rx * math.cos(angle),
        _offsetOpt(offset, o) + cy + ry * math.sin(angle)
      }
      corePoints[#corePoints+1] = p
      allPoints[#allPoints+1] = p
    end
    allPoints[#allPoints+1] = {
      _offsetOpt(offset, o) + cx + rx * math.cos(radOffset + math.pi * 2 + overlap * 0.5),
      _offsetOpt(offset, o) + cy + ry * math.sin(radOffset + math.pi * 2 + overlap * 0.5)
    }
    allPoints[#allPoints+1] = {
      _offsetOpt(offset, o) + cx + 0.98 * rx * math.cos(radOffset + overlap),
      _offsetOpt(offset, o) + cy + 0.98 * ry * math.sin(radOffset + overlap)
    }
    allPoints[#allPoints+1] = {
      _offsetOpt(offset, o) + cx + 0.9 * rx * math.cos(radOffset + overlap * 0.5),
      _offsetOpt(offset, o) + cy + 0.9 * ry * math.sin(radOffset + overlap * 0.5)
    }
  end
  return allPoints, corePoints
end

local function _arc (increment, cx, cy, rx, ry, strt, stp, offset, o)
  local radOffset = strt + _offsetOpt(0.1, o)
  local points = {}
  points[1] = {
    _offsetOpt(offset, o) + cx + 0.9 * rx * math.cos(radOffset - increment),
    _offsetOpt(offset, o) + cy + 0.9 * ry * math.sin(radOffset - increment)
  }
  for angle = radOffset, stp, increment do
    points[#points+1] = {
      _offsetOpt(offset, o) + cx + rx * math.cos(angle),
      _offsetOpt(offset, o) + cy + ry * math.sin(angle)
    }
  end
  points[#points+1] = {
    cx + rx * math.cos(stp),
    cy + ry * math.sin(stp)
  }
  points[#points+1] = {
    cx + rx * math.cos(stp),
    cy + ry * math.sin(stp)
  }
  return _curve(points, nil, o)
end

local function _bezierTo (x1, y1, x2, y2, x, y, current, o)
  local ops = {}
  local ros = {o.maxRandomnessOffset or 1, (o.maxRandomnessOffset or 1) + 0.3}
  local iterations = o.disableMultiStroke and 1 or 2
  local preserveVertices = o.preserveVertices
  for i = 1, iterations do
    if i == 1 then
      ops[#ops+1] = {
        op = 'move',
        data = { current[1], current[2] }
      }
    else
      ops[#ops+1] = {
        op = 'move',
        data = {
          current[1] + (preserveVertices and 0 or _offsetOpt(ros[1], o)),
          current[2] + (preserveVertices and 0 or _offsetOpt(ros[1], o))
        }
      }
    end
    local f = preserveVertices and { x, y } or { x + _offsetOpt(ros[i], o), y + _offsetOpt(ros[i], o) }
    ops[#ops+1] = {
      op = 'bcurveTo',
      data = {
        x1 + _offsetOpt(ros[i], o),
        y1 + _offsetOpt(ros[i], o),
        x2 + _offsetOpt(ros[i], o),
        y2 + _offsetOpt(ros[i], o),
        f[1],
        f[2]
      }
    }
  end
  return ops
end

-- Public functions

local function line (x1, y1, x2, y2, o)
  return { type = 'path', ops = _doubleLine(x1, y1, x2, y2, o) }
end

local function linearPath (points, close, o)
  local len = #(points or {})
  if len >= 2 then
    local ops = {}
    for i = 1, len - 1 do
      local t = _doubleLine(points[i][1], points[i][2], points[i + 1][1], points[i + 1][2], o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
    end
    if close then
      local t = _doubleLine(points[len][1], points[len][2], points[1][1], points[1][2], o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
    end
    return { type = 'path', ops = ops }
  elseif len == 2 then
    return line(points[1][1], points[1][2], points[2][1], points[2][2], o)
  end
  return { type = 'path', ops = {} }
end

local function polygon (points, o)
  return linearPath(points, true, o)
end

local function rectangle (x, y, width, height, o)
  local points = {
    {x, y},
    {x + width, y},
    {x + width, y + height},
    {x, y + height}
  }
  return polygon(points, o)
end

local function curve (inputPoints, o)
  if #inputPoints > 0 then
    local p1 = inputPoints[1]
    local pointsList = (type(p1[1]) == 'number') and {inputPoints} or inputPoints
    local o1 = _curveWithOffset(pointsList[1], 1 * (1 + o.roughness * 0.2), o)
    local o2 = o.disableMultiStroke and {} or _curveWithOffset(pointsList[1], 1.5 * (1 + o.roughness * 0.22), cloneOptionsAlterSeed(o))
    for i = 2, #pointsList do
      local points = pointsList[i]
      if #points > 0 then
        local underlay = _curveWithOffset(points, 1 * (1 + o.roughness * 0.2), o)
        local overlay = o.disableMultiStroke and {} or _curveWithOffset(points, 1.5 * (1 + o.roughness * 0.22), cloneOptionsAlterSeed(o))
        for _, item in ipairs(underlay) do
          if item.op ~= 'move' then
            o1[#o1+1] = item
          end
        end
        for _, item in ipairs(overlay) do
          if item.op ~= 'move' then
            o2[#o2+1] = item
          end
        end
      end
    end
    return { type = 'path', ops = array_concat(o1, o2) }
  end
  return { type = 'path', ops = {} }
end

local function generateEllipseParams (width, height, o)
  local psq = math.sqrt(math.pi * 2 * math.sqrt(((width / 2)^2 + (height / 2)^2) / 2))
  local stepCount = math.ceil(math.max(o.curveStepCount, (o.curveStepCount / math.sqrt(200)) * psq))
  local increment = (math.pi * 2) / stepCount
  local rx = math.abs(width / 2)
  local ry = math.abs(height / 2)
  local curveFitRandomness = 1 - o.curveFitting
  rx = rx + _offsetOpt(rx * curveFitRandomness, o)
  ry = ry + _offsetOpt(ry * curveFitRandomness, o)
  return { increment = increment, rx = rx, ry = ry }
end

local function ellipseWithParams (x, y, o, ellipseParams)
  local ap1, cp1 = _computeEllipsePoints(ellipseParams.increment, x, y, ellipseParams.rx, ellipseParams.ry, 1, ellipseParams.increment * _offset(0.1, _offset(0.4, 1, o), o), o)
  local o1 = _curve(ap1, nil, o)
  if not o.disableMultiStroke and o.roughness ~= 0 then
    local ap2 = _computeEllipsePoints(ellipseParams.increment, x, y, ellipseParams.rx, ellipseParams.ry, 1.5, 0, o)
    local o2 = _curve(ap2, nil, o)
    pl.tablex.insertvalues(o1, o2) -- JS version used array_concat but seems avoidable here
  end
  return { estimatedPoints = cp1, opset = { type = 'path', ops = o1 } }
end

local function ellipse (x, y, width, height, o)
  local params = generateEllipseParams(width, height, o)
  return ellipseWithParams(x, y, o, params).opset
end

local function arc (x, y, width, height, start, stop, closed, roughClosure, o)
  local cx = x
  local cy = y
  local rx = math.abs(width / 2)
  local ry = math.abs(height / 2)
  rx = rx + _offsetOpt(rx * 0.01, o)
  ry = ry + _offsetOpt(ry * 0.01, o)
  local strt = start
  local stp = stop
  while strt < 0 do
    strt = strt + math.pi * 2
    stp = stp + math.pi * 2
  end
  if (stp - strt) > (math.pi * 2) then
    strt = 0
    stp = math.pi * 2
  end
  local ellipseInc = (math.pi * 2) / o.curveStepCount
  local arcInc = math.min(ellipseInc / 2, (stp - strt) / 2)
  local ops = _arc(arcInc, cx, cy, rx, ry, strt, stp, 1, o)
  if not o.disableMultiStroke then
    local o2 = _arc(arcInc, cx, cy, rx, ry, strt, stp, 1.5, o)
    pl.tablex.insertvalues(ops, o2) -- = JS ops.push(...o2)
  end
  if closed then
    if roughClosure then
      local t = _doubleLine(cx, cy, cx + rx * math.cos(strt), cy + ry * math.sin(strt), o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
      t = _doubleLine(cx, cy, cx + rx * math.cos(stp), cy + ry * math.sin(stp), o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
    else
      ops[#ops+1] = { op = 'lineTo', data = {cx, cy} }
      ops[#ops+1] = { op = 'lineTo', data = {cx + rx * math.cos(strt), cy + ry * math.sin(strt)} }
    end
  end
  return { type = 'path', ops = ops }
end

local function svgPath (path, o)
  local segments = normalize(absolutize(parsePath(path))) -- FIXME
  local ops = {}
  local first = {0, 0}
  local current = {0, 0}
  for _, item in ipairs(segments) do
    local key = item.key
    local data = item.data
    if key == 'M' then
      current = {data[1], data[2]}
      first = {data[1], data[2]}
    elseif key == 'L' then
      local t = _doubleLine(current[1], current[2], data[1], data[2], o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
      current = { data[1], data[2] }
    elseif key == 'C' then
      local x1, y1, x2, y2, x, y = data[1], data[2], data[3], data[4], data[5], data[6]
      local t = _bezierTo(x1, y1, x2, y2, x, y, current, o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
      current = {x, y}
    elseif key == 'Z' then
      local t = _doubleLine(current[1], current[2], first[1], first[2], o)
      pl.tablex.insertvalues(ops, t) -- = JS ops.push(...t)
      current = {first[1], first[2]}
    end
  end
  return { type = 'path', ops = ops }
end

-- helpers

local function doubleLineFillOps (x1, y1, x2, y2, o)
  return _doubleLine(x1, y1, x2, y2, o, true)
end

local helper = {
  randOffset = _offsetOpt,
  randOffsetWithRange =_offset,
  ellipse = ellipse,
  doubleLineOps = doubleLineFillOps,
}

-- Fills

local function solidFillPolygon (polygonList, o)
  local ops = {}
  for _, points in ipairs(polygonList) do
    if #points > 0 then
      local offset = o.maxRandomnessOffset or 0
      local len = #points
      if len > 2 then
        ops[#ops+1] = {
          op = 'move',
          data = {
            points[1][1] + _offsetOpt(offset, o),
            points[1][2] + _offsetOpt(offset, o)
          }
        }
        for i = 2, len do
          ops[#ops+1] = {
            op = 'lineTo',
            data = {
              points[i][1] + _offsetOpt(offset, o),
              points[i][2] + _offsetOpt(offset, o)
            }
          }
        end
      end
    end
  end
  return { type = 'fillPath', ops = ops }
end

local function patternFillPolygons (polygonList, o)
  return getFiller(o, helper):fillPolygons(polygonList, o)
end

local function patternFillArc (x, y, width, height, start, stop, o)
  local cx = x
  local cy = y
  local rx = math.abs(width / 2)
  local ry = math.abs(height / 2)
  rx = rx + _offsetOpt(rx * 0.01, o)
  ry = ry + _offsetOpt(ry * 0.01, o)
  local strt = start
  local stp = stop
  while strt < 0 do
    strt = strt + math.pi * 2
    stp = stp + math.pi * 2
  end
  if (stp - strt) > (math.pi * 2) then
    strt = 0
    stp = math.pi * 2
  end
  local increment = (stp - strt) / o.curveStepCount
  local points = {}
  for angle = strt, stp, increment do
    points[#points+1] = {cx + rx * math.cos(angle), cy + ry * math.sin(angle)}
  end
  points[#points+1] = {cx + rx * math.cos(stp), cy + ry * math.sin(stp)}
  points[#points+1] = {cx, cy}
  return patternFillPolygons({ points }, o)
end

return {
  line = line,
  rectangle = rectangle,
  ellipseWithParams = ellipseWithParams,
  generateEllipseParams = generateEllipseParams,
  arc = arc,
  curve = curve,
  linearPath = linearPath,
  svgPath = svgPath,
  patternFillArc = patternFillArc,
  patternFillPolygons = patternFillPolygons,
  solidFillPolygon = solidFillPolygon,
}
