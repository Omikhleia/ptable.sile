--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
local renderer = require("rough-lua.rough.renderer")
local line, rectangle,
      ellipseWithParams, generateEllipseParams,
      arc, curve, linearPath,
      svgPath,
      patternFillArc, patternFillPolygons, solidFillPolygon
        = renderer.line, renderer.rectangle,
        renderer.ellipseWithParams, renderer.generateEllipseParams,
        renderer.arc, renderer.curve, renderer.linearPath,
        renderer.svgPath,
        renderer.patternFillArc, renderer.patternFillPolygons, renderer.solidFillPolygon
-- PORTING NOTE:
-- I ported the module but haven't tested it for now
-- local curveToBezier = require("rough-lua.points-on-curve.curve-to-bezier").curveToBezier
-- local pointsOnPath = require("rough-lua.points-on-curve").pointsOnPath
-- local pointsOnBezierCurves = require("rough-lua.points-on-curve").pointsOnBezierCurves
local pointsOnPath = function () error("Not implemented") end
local curveToBezier = function () error("Not implemented") end
local pointsOnBezierCurves = function () error("Not implemented") end


local RoughGenerator = pl.class({
  defaultOptions = {
    maxRandomnessOffset = 2,
    roughness = 1,
    bowing = 1,
    stroke = { l = 0 }, -- PORTING NOTE: COMPAT WITH SILE PARSED COLORS
    strokeWidth = 1,
    curveTightness = 0,
    curveFitting = 0.95,
    curveStepCount = 9,
    fillStyle = 'hachure',
    fillWeight = -1,
    hachureAngle = -41,
    hachureGap = -1,
    dashOffset = -1,
    dashGap = -1,
    zigzagOffset = -1,
    seed = 0,
    disableMultiStroke = false,
    disableMultiStrokeFill = false,
    preserveVertices = false,
  },

  _init = function (self, options)
    if options then
      self.defaultOptions = self:_o(options)
    end
  end,

  _d = function (self, shape, sets, options)
    return { shape = shape, sets = sets or {}, options = options or self.defaultOptions }
  end,

  _o = function (self, options)
    return options and pl.tablex.union(self.defaultOptions, options) or self.defaultOptions
  end,

  line = function (self, x1, y1, x2, y2, options)
    local o = self:_o(options)
    return self:_d('line', { line(x1, y1, x2, y2, o) }, o)
  end,

  rectangle = function (self, x, y, width, height, options)
    local o = self:_o(options)
    local paths = {}
    local outline = rectangle(x, y, width, height, o)
    if o.fill then
      local points = { {x, y}, {x + width, y}, {x + width, y + height}, {x, y + height} }
      if o.fillStyle == 'solid' then
        paths[#paths + 1] = solidFillPolygon({ points }, o)
      else
        paths[#paths + 1] = patternFillPolygons({ points }, o)
      end
    end
    if o.stroke ~= 'none' then
      paths[#paths+1] = outline
    end
    return self:_d('rectangle', paths, o)
  end,

  ellipse = function (self, x, y, width, height, options)
    local o = self:_o(options)
    local paths = {}
    local ellipseParams = generateEllipseParams(width, height, o)
    local ellipseResponse = ellipseWithParams(x, y, o, ellipseParams)
    if o.fill then
      if o.fillStyle == 'solid' then
        local shape = ellipseWithParams(x, y, o, ellipseParams).opset
        shape.type = 'fillPath'
        paths[#paths + 1] = shape
      else
        paths[#paths + 1] = patternFillPolygons({ ellipseResponse.estimatedPoints }, o)
      end
    end
    if o.stroke ~= 'none' then
      paths[#paths + 1] = ellipseResponse.opset
    end
    return self:_d('ellipse', paths, o)
  end,

  circle = function (self, x, y, diameter, options)
    local ret = self:ellipse(x, y, diameter, diameter, options)
    ret.shape = 'circle'
    return ret
  end,

  linearPath = function (self, points, options)
    local o = self:_o(options)
    return self:_d('linearPath', { linearPath(points, false, o) }, o)
  end,

  arc = function (self, x, y, width, height, start, stop, closed, options)
    local o = self:_o(options)
    local paths = {}
    local outline = arc(x, y, width, height, start, stop, closed, true, o)
    if closed and o.fill then
      if o.fillStyle == 'solid' then
        local fillOptions = pl.tablex.copy(o)
        fillOptions.disableMultiStroke = true
        local shape = arc(x, y, width, height, start, stop, true, false, fillOptions)
        shape.type = 'fillPath'
        paths[#paths + 1] = shape
      else
        paths[#paths + 1] = patternFillArc(x, y, width, height, start, stop, o)
      end
    end
    if o.stroke ~= 'none' then
      paths[#paths + 1] = outline
    end
    return self:_d('arc', paths, o)
  end,

  curve = function (self, pointOrPoints, options)
    local o = self:_o(options)
    local paths = {}
    local outline = curve(pointOrPoints, o)
    if o.fill and o.fill ~= 'none' then
      if o.fillStyle == 'solid' then
        local fillShape = curve(
          pointOrPoints,
          pl.tablex.union(o, {
            disableMultiStroke = true,
            roughness = o.roughness and (o.roughness + o.fillShapeRoughnessGain) or 0
          }
        ))
        paths[#paths + 1] = {
          type = 'fillPath',
          ops = self:_mergedShape(fillShape.ops),
        }
      else
        local polyPoints = {}
        local inputPoints = pointOrPoints
        if #inputPoints > 0 then
          local p1 = inputPoints[1]
          local pointsList = type(p1[1]) == 'number' and { inputPoints } or inputPoints
          for _, points in ipairs(pointsList) do
            if #points < 3 then
              pl.tablex.insertvalues(polyPoints, points) -- = JS polyPoints.push(...points)
            elseif #points == 3 then
              local t = pointsOnBezierCurves(curveToBezier({ points[1], points[1], points[2], points[3] }), 10, (1 + o.roughness) / 2)
              pl.tablex.insertvalues(polyPoints, t) -- = JS polyPoints.push(...t)
            else
              local t = pointsOnBezierCurves(curveToBezier(points), 10, (1 + o.roughness) / 2)
              pl.tablex.insertvalues(polyPoints, t) -- = JS polyPoints.push(...t)
            end
          end
        end
        if #polyPoints > 0 then
          paths[#paths + 1] = patternFillPolygons({ polyPoints }, o)
        end
      end
    end
    if o.stroke ~= 'none' then
      paths[#paths + 1] = outline
    end
    return self:_d('curve', paths, o)
  end,

  polygon = function (self, points, options)
    local o = self:_o(options)
    local paths = {}
    local outline = linearPath(points, true, o)
    if o.fill then
      if o.fillStyle == 'solid' then
        paths[#paths + 1] = solidFillPolygon({ points }, o)
      else
        paths[#paths + 1] = patternFillPolygons({ points }, o)
      end
    end
    if o.stroke ~= 'none' then
      paths[#paths + 1] = outline
    end
    return self:_d('polygon', paths, o)
  end,

  path = function (self, d, options)
    local o = self:_o(options)
    local paths = {}
    if not d then
      return self:_d('path', paths, o)
    end
    d = d:gsub('\n', ' '):gsub('(-%s)', '-'):gsub('(%s%s)', ' ')

    local hasFill = o.fill and o.fill ~= 'transparent' and o.fill ~= 'none'
    local hasStroke = o.stroke ~= 'none'
    local simplified = o.simplification and o.simplification < 1
    local distance = simplified and (4 - 4 * (o.simplification or 1)) or ((1 + o.roughness) / 2)
    local sets = pointsOnPath(d, 1, distance)
    local shape = svgPath(d, o)

    if hasFill then
      if o.fillStyle == 'solid' then
        if #sets == 1 then
          local fillShape = svgPath(d, pl.tablex.union(o, { disableMultiStroke = true, roughness = o.roughness and (o.roughness + o.fillShapeRoughnessGain) or 0 }))
          paths[#paths + 1] = {
            type = 'fillPath',
            ops = self:_mergedShape(fillShape.ops),
          }
        else
          paths[#paths + 1] = solidFillPolygon(sets, o)
        end
      else
        paths[#paths + 1] = patternFillPolygons(sets, o)
      end
    end
    if hasStroke then
      if simplified then
        for _, set in ipairs(sets) do
          paths[#paths + 1] = linearPath(set, false, o)
        end
      else
        paths[#paths + 1] = shape
      end
    end

    return self:_d('path', paths, o)
  end,

  opsToPath = function (_, drawing, fixedDecimals)
    local path = ''
    for _, item in ipairs(drawing.ops) do
      local data = fixedDecimals and pl.tablex.map(item.data, function (d) return tonumber(string.format('%.' .. fixedDecimals .. 'f', d)) end) or item.data
      if item.op == 'move' then
        path = path .. 'M' .. data[1] .. ' ' .. data[2] .. ' '
      elseif item.op == 'bcurveTo' then
        path = path .. 'C' .. data[1] .. ' ' .. data[2] .. ', ' .. data[3] .. ' ' .. data[4] .. ', ' .. data[5] .. ' ' .. data[6] .. ' '
      elseif item.op == 'lineTo' then
        path = path .. 'L' .. data[1] .. ' ' .. data[2] .. ' '
      end
    end
    return path:trim()
  end,

  toPaths = function (self, drawable)
    local sets = drawable.sets or {}
    local o = drawable.options or self.defaultOptions
    local paths = {}
    for _, drawing in ipairs(sets) do
      local path = nil
      if drawing.type == 'path' then
        path = {
          d = self:opsToPath(drawing),
          stroke = o.stroke,
          strokeWidth = o.strokeWidth,
          fill = 'none',
        }
      elseif drawing.type == 'fillPath' then
        path = self:fillSketch(drawing, o)
      elseif drawing.type == 'fillSketch' then
        path = self:fillSketch(drawing, o)
      end
      if path then
        paths[#paths + 1] = path
      end
    end
    return paths
  end,

  fillSketch = function (self, drawing, o)
    local fweight = o.fillWeight
    if fweight < 0 then
      fweight = o.strokeWidth / 2
    end
    return {
      d = self:opsToPath(drawing),
      stroke = 'none',
      strokeWidth = fweight,
      fill = o.fill or 'none',
    }
  end,

  _mergedShape = function (_, input)
    return pl.tablex.filter(input, function (d, i)
      if i == 1 then
        return true
      end
      if d.op == 'move' then
        return false
      end
      return true
    end)
  end,
})

-- Exports

return {
  RoughGenerator = RoughGenerator,
}
