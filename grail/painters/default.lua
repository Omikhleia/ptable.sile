--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--
local PDFHelpers = require("grail.pdf.helpers")
local _r, makeColorHelper = PDFHelpers._r, PDFHelpers.makeColorHelper

local DefaultPainter = pl.class()

DefaultPainter.defaultOptions = {
  strokeWidth = 1,
}

--- Builds a graphics path from a starting position (x, y)
-- and a set of relative segments which can be either lines (2 coords)
-- or bezier curves (6 segments).
--
-- @tparam  number    x         Starting position X coordinate
-- @tparam  number    y         Starting position Y coordinate
-- @tparam  number    segments  Relative segments
-- @treturn table               Graphics path
local function makePathHelper (x, y, segments)
  local paths = {
    {
      op = "move",
      data = { _r(x), _r(y) }
    }
  }
  for i = 1, #segments do
    local s = segments[i]
    if #s == 2 then
      -- line
      x = s[1] + x
      y = s[2] + y
      paths[#paths + 1] = {
        op = "lineTo",
        data = { _r(x), _r(y) },
      }
    else
      -- bezier curve
      paths[#paths + 1] = {
        op = "bcurveTo",
        data = { _r(s[1] + x), _r(s[2] + y), _r(s[3] + x), _r(s[4] + y), _r(s[5] + x), _r(s[6] + y) }
      }
      x = s[5] + x
      y = s[6] + y
    end
  end
  return paths
end

--- Given an outline and options, returns a set of operations to either fill or stroke the outline.
-- Operatior types are compatible with rough-lua:
--   - fillPath: fill only
--   - path: stroke only
-- We support another type:
--   - shape: fill and stroke in one operation
-- Here, we don't need to support one type from rough-lua:
--   - fillSketch: stroke only (for pattern sketches)
-- Also, our sets just need to contain one element.
-- (rough-lua needs multiple elements for stroking and filling, esp. with patterns)
--
-- @tparam  table    outline  Outline path
-- @tparam  table    o        Options
-- @treturn table             Set of operations
local function strokeAndOrFill (outline, o)
  if o.stroke ~= "none" and o.strokeWidth > 0 then
    if o.fill ~= "none" then
      -- Fill and stroke
      return {
        {
          type = "shape",
          ops = outline
        }
      }
    end
    -- Stroke only
    return {
      {
        type = "path",
        ops = outline
      }
    }
  end
  if o.fill ~= "none" then
    -- Fill only
    return {
      {
        type = "fillPath",
        ops = outline
      }
    }
  end
  -- Neither fill nor stroke, i.e. nothing to do
  return {}
end

function DefaultPainter:_init (options)
  if options then
    self.defaultOptions = self:_o(options)
  end
end

function DefaultPainter:_o (options)
  return options and pl.tablex.union(self.defaultOptions, options) or self.defaultOptions
end

-- Line from (x1, y1) to (x2, y2).
function DefaultPainter:line (x1, y1, x2, y2, options)
  local o = self:_o(options)
  return {
    shape = "line",
    options = o,
    sets = {
      {
        type = "path",
        ops = {
          {
            op = "move",
            data = { _r(x1), _r(y1) }
          },
          {
            op = "lineTo",
            data = { _r(x2 -x1), _r(y2 - y1) }
          }
        }
      }

    }
  }
end

--- Path for a rectangle with upper left (x, y), with given width and height.
function DefaultPainter:rectangle (x, y , w , h, options)
  local o = self:_o(options)
  local outline = {
    {
      op = "rect",
      data = { _r(x), _r(y), _r(w), _r(h) }
    }
  }
  local paths = {
    shape = "rectangle",
    options = o,
    sets = strokeAndOrFill(outline, o)
  }
  return paths
end

--- Path for a rounded rectangle with upper left (x, y), with given width,
-- height and border radius.
function DefaultPainter:roundedRectangle (x, y , w , h, rx, ry, options)
  local o = self:_o(options)
  local arc = 4 / 3 * (1.4142135623730951 - 1)
  -- starting point
  local x0 = x + rx
  -- table of segments (2 coords) or bezier curves (6 coords)
  local segments = {
    {(w - 2 * rx), 0}, -- horizontal top line
    {(rx * arc), 0, rx, ry - (ry * arc), rx, ry}, -- top right curve
    {0, (h - 2 * ry)}, -- vertical right line
    {0, (ry * arc), -(rx * arc), ry, -rx, ry}, -- bottom right curve
    {(-w + 2 * rx), 0}, -- horizontal bottom line
    {-(rx * arc), 0, -rx, -(ry * arc), -rx, -ry}, -- bottom left curve
    {0, (-h + 2 * ry)}, -- vertical left line
    {0, -(ry * arc), (rx * arc), -ry, rx, -ry} -- top left curve
  }
  local outline = makePathHelper(x0, y, segments)
  local paths = {
    shape = "roundedRectangle",
    options = o,
    sets = strokeAndOrFill(outline, o)
  }
  return paths
end

-- Clipping path for an L-shaped area on a rectangle.
function DefaultPainter.rectangleClip (_, x, y , w , h, s)
  local x0
  local segments
  if s >= 0 then
    x0 = x + w
    segments = {
      {x + s, 0}, {0, h + s}, {-(w + s), 0}, {0, -s}, {w, 0}, {0, -h}
    }
  else
    x0 = x
    segments = {
      {x + w, 0}, {0, s}, {s - w, 0}, {0, h - s}, {-s, 0}, {0, -h}
    }
  end
  return {
    shape = "rectangleClip",
    options = {},
    sets = {
      {
        type = 'path',
        ops = makePathHelper(x0, y, segments),
      }
    }
  }
end

-- Clipping path for an L-shaped clipping area on a rounded rectangle.
function DefaultPainter.roundedRectangleClip (_, x, y , w , h, rx, ry, s)
  local arc = 4 / 3 * (1.4142135623730951 - 1)
  -- starting point
  local x0
  -- table of segments (2 coords) or bezier curves (6 coords)
  local segments
  if s >= 0 then
    x0 = x + w -rx
    segments = {
      {rx * arc, 0, rx, ry - (ry * arc), rx, ry},
      {0, h - 2 * ry},
      {0, ry * arc, -rx * arc, ry, -rx, ry},
      {-w + 2 * rx, 0},
      {-rx * arc, 0, -rx, -ry * arc, -rx, -ry},
      {0, ry + s},
      {w + s, 0},
      {0, -h -s},
      {-(s + rx), 0},
    }
  else
    x0 = x + rx
    segments = {
      {x + w - 2 * rx, 0},
      {rx * arc, 0, rx, ry - ry * arc, rx, ry},
      {0, s - ry},
      {s - w, 0},
      {0, h - s},
      {rx - s, 0},
      {-rx * arc, 0, -rx, -ry * arc, -rx, -ry},
      {0, -h + 2 * ry},
      {0, -ry * arc, rx * arc, -ry, rx, -ry}
    }
  end
  return {
    shape = "roundedRectangleClip",
    options = {},
    sets = {
      {
        type = 'path',
        ops = makePathHelper(x0, y, segments)
      }
    }
  }
end

--- Path for a curly brace between (x1,y1) and (x2,y2),
-- with given width and thickness in points,
-- and curvyness from 0.5 (normal) to higher values for a more "expressive" bracket.
--
-- Algorithm derived from https://gist.github.com/alexhornbake/6005176 (which used
-- quadratic Bezier curves, but it doesn't really matter much here).
--
function DefaultPainter:curlyBrace (x1, y1 , x2 , y2, width, thickness, curvyness, options)
  local o = self:_o(options)
  if o.rounded == nil then
    o.rounded = true -- default to round line caps and line joins
  end
  -- Calculate unit vector
  local dx = x1 - x2
  local dy = y1 - y2
  local len = math.sqrt(dx*dx + dy*dy)
  dx =  dx / len
  dy =  dy / len
  -- Calculate Control Points of path,
  -- Top segment:
  --   Q1    --P1
  --        /
  --       |
  --       Q2 Q2b
  --      /
  --     /
  -- T--
  --
  local qx1 = x1 + curvyness * width * dy
  local qy1 = y1 - curvyness * width * dx
  local qx2 = (x1 - 0.25 * len * dx) + (1 - curvyness) * width * dy
  local qy2 = (y1 - 0.25 *len * dy) - (1 - curvyness) * width * dx
  -- 'Middle' point (the pointing terminator of the brace)
  local tx = (x1 -  0.5 * len * dx) + width * dy
  local ty = (y1 -  0.5 * len * dy) - width * dx
  -- Bottom segment (same logic)
  local qx3 = x2 + curvyness * width * dy
  local qy3 = y2 - curvyness * width * dx
  local qx4 = (x1 - 0.75 * len * dx) + (1 - curvyness) * width * dy
  local qy4 = (y1 - 0.75 * len * dy) - (1 - curvyness) * width * dx
  -- Thickness
  local thickoffset = width > 0 and thickness or -thickness
  local qx2b, qy2b = qx2 - thickoffset * dy, qy2 - thickoffset * dx
  local qx4b, qy4b = qx4 - thickoffset * dy, qy4 - thickoffset * dx
  local outline = {
    -- TOP SEGMENT
    -- From (x1, y1)
    {
      op = "move",
      data = { _r(x1), _r(y1) }
    },
    -- Goto (qx2, qy2) vith control point (qx1, qy1) on current position (x1, y1)
    {
      op = "vcurveTo",
      data = { _r(qx1), _r(qy1), _r(qx2), _r(qy2) }
    },
    -- Then go to (tx, ty) with the reflexion of the previous control point
    -- ((2 * point - control) is the reflexion of control relative to point)
    {
      op = "vcurveTo",
      data = { _r(2 * qx2 - qx1), _r(2 * qy2 - qy1), _r(tx), _r(ty) }
    },
    -- TOP SEGMENT THICKNESS
    -- Go back to (qx2b, qy2b) with control control point on it.
    {
      op = "ycurveTo",
      data = { _r(2 * qx2b - qx1), _r(2 * qy2b - qy1), _r(qx2b), _r(qy2b) }
    },
    -- And back to the original point (x1, y1), with control point on it.
    {
      op = "ycurveTo",
      data = { _r(qx1), _r(qy1), _r(x1), _r(y1) }
    },
    -- BOTTOM SEGMENT
    -- Same thing but from (x2, y2) to (tx, ty) and backwards with thickness.
    {
      op = "move",
      data = { _r(x2), _r(y2) }
    },
    {
      op = "vcurveTo",
      data = { _r(qx3), _r(qy3), _r(qx4), _r(qy4) }
    },
    {
      op = "vcurveTo",
      data = { _r(2 * qx4 - qx3), _r(2 * qy4 - qy3), _r(tx), _r(ty) }
    },
    {
      op = "ycurveTo",
      data = { _r(2 * qx4b - qx3), _r(2 * qy4b - qy3), _r(qx4b), _r(qy4b) }
    },
    {
      op = "ycurveTo",
      data = { _r(qx3), _r(qy3), _r(x2), _r(y2) }
    },
  }
  return {
    shape = "curlyBrace",
    options = o,
    sets = strokeAndOrFill(outline, o)
  }
end

function DefaultPainter.ellipse ()
  SU.error("Ellipse not implemented in DefaultPainter")
end

function DefaultPainter.circle ()
  SU.error("Circle not implemented in DefaultPainter")
end

function DefaultPainter.arc ()
  SU.error("Arc not implemented in DefaultPainter")
end

function DefaultPainter:draw (drawable, clippable)
  local sets = drawable.sets or {}
  local o = drawable.options
  local precision = drawable.options.fixedDecimalPlaceDigits
  local g = {}
  for _, drawing in ipairs(sets) do
    local path = self:opsToPath(drawing, precision)
    if o.rounded == true then
      path = path .. " 1 J 1 j"
    end
    -- path = stroke only
    if drawing.type == "path" then
      path = table.concat({
          path,
          makeColorHelper(o.stroke, true),
          _r(o.strokeWidth), "w",
          "S"
      }, " ")
    -- fillPath = fill only
    elseif drawing.type == "fillPath" then
      path = table.concat({
        path,
        makeColorHelper(o.fill, false),
        _r(o.strokeWidth), "w",
        "f"
      }, " ")
    -- fillSketch = stroke only
    elseif drawing.type == "fillSketch" then
      path = table.concat({
        path,
        makeColorHelper(o.fill, true),
        _r(o.strokeWidth), "w",
        "S"
      }, " ")
    -- shape = fill and stroke in one operation
    elseif drawing.type == "shape" then
      path = table.concat({
        path,
        makeColorHelper(o.stroke, true),
        makeColorHelper(o.fill, false),
        _r(o.strokeWidth), "w",
        "B"
      }, " ")
    else
      SU.error("Unknown drawing type: " .. drawing.type)
    end
    if path then
      g[#g + 1] = path
    end
  end
  local path = table.concat(g, " ")
  if clippable then
    -- Enclose drawing path in a group with the clipping path
    clippable.options = drawable.options
    local clip = self:opsToPath(clippable.sets[1], precision)
     path = table.concat({
       "q",
       clip, "W n",
       path,
       "Q"
     }, " ")
  end
  return path
end

function DefaultPainter.opsToPath (_, drawing, _)  -- self, drawing, precision
  local path = {}
  for _, item in ipairs(drawing.ops) do
    local data = item.data
    -- NOTE: we currently ignore the decimal precision option
    if item.op == "move" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " m"
    elseif item.op == 'bcurveTo' then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " " .. _r(data[5]) .. " " .. _r(data[6]) .. " c"
    elseif item.op == "vcurveTo" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " v"
    elseif item.op == "ycurveTo" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " y"
    elseif item.op == "rect" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " re"
    elseif item.op == "lineTo" then
      path[#path + 1] = _r(data[1]) .. " " ..  _r(data[2]) .. " l"
    end
  end
  return table.concat(path, " ")
end

return {
  DefaultPainter = DefaultPainter
}
