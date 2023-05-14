--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023 Didier Willis
--
-- Public API consists in:
-- - a PathRenderer class that provides basic drawing methods, using a default
--   painter.
-- - a RoughPainter class, an instance of which may be passed to the
--   PathRenderer constructor, to replace the default renderer by the rough
--   one.
--

local RoughGenerator = require("packages.framebox.graphics.rough").RoughGenerator

-- HELPERS

--- Round number
--
-- @tparam  number    number    number value
-- @return                      rounded value for output
local function _r (number)
  -- Lua 5.3+ formats floats as 1.0 and integers as 1
  -- Also some PDF readers do not like double precision.
  return math.floor(number) == number and math.floor(number) or tonumber(string.format("%.5f", number))
end

--- Builds a PDF graphics color (stroke or fill) from a SILE parsed color.
--
-- @tparam  table     color     SILE color object
-- @tparam  boolean   stroke    Stroke or fill
-- @treturn string              PDF graphics color
local function makeColorHelper (color, stroke)
  local colspec
  local colop
  if color.r then -- RGB
    colspec = table.concat({ _r(color.r), _r(color.g), _r(color.b) }, " ")
    colop = stroke and "RG" or "rg"
  elseif color.c then -- CMYK
    colspec = table.concat({ _r(color.c), _r(color.m), _r(color.y), _r(color.k) }, " ")
    colop = stroke and "K" or "k"
  elseif color.l then -- Grayscale
    colspec = _r(color.l)
    colop = stroke and "G" or "g"
  else
    SU.error("Invalid color specification")
  end
  return colspec .. " " .. colop
end

--- Builds a PDF graphics path from a starting position (x, y)
-- and a set of relative segments which can be either lines (2 coords)
-- or bezier curves (6 segments).
--
-- @tparam  number    x         Starting position X coordinate
-- @tparam  number    y         Starting position Y coordinate
-- @tparam  number    segments  Relative segments
-- @treturn string              PDF graphics path
local function makePathHelper (x, y, segments)
  local paths = { { _r(x), _r(y), "m" } }
  for i = 1, #segments do
    local s = segments[i]
    if #s == 2 then
      -- line
      x = s[1] + x
      y = s[2] + y
      paths[#paths + 1] = { _r(x), _r(y), "l" }
    else
      -- bezier curve
      paths[#paths + 1] = { _r(s[1] + x), _r(s[2] + y), _r(s[3] + x), _r(s[4] + y), _r(s[5] + x), _r(s[6] + y), "c" }
      x = s[5] + x
      y = s[6] + y
    end
  end
  for i, v in ipairs(paths) do
    paths[i] = table.concat(v, " ")
  end
  return table.concat(paths, " ")
end

local DefaultPainter = pl.class()

-- Line from (x1, y1) to (x2, y2).
function DefaultPainter.line (_, x1, y1, x2, y2, options)
  return {
    path = table.concat({ _r(x1), _r(y1), "m", _r(x2 - x1), _r(y2 - y1), "l" }, " "),
    options = options,
  }
end

--- Path for a rectangle with upper left (x, y), with given width and height.
function DefaultPainter.rectangle (_, x, y , w , h, options)
  return {
    path = table.concat({ _r(x), _r(y), _r(w), _r(h), "re" }, " "),
    options = options,
  }
end

--- Path for a rounded rectangle with upper left (x, y), with given width,
-- height and border radius.
function DefaultPainter.roundedRectangle (_, x, y , w , h, rx, ry, options)
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
  return {
    path = makePathHelper(x0, y, segments),
    options = options,
  }
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
    path = makePathHelper(x0, y, segments),
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
    path = makePathHelper(x0, y, segments),
  }
end

--- Path for a curly brace between (x1,y1) and (x2,y2),
-- with given width and thickness in points,
-- and curvyness from 0.5 (normal) to higher values for a more "expressive" bracket.
--
-- Algorithm derived from https://gist.github.com/alexhornbake/6005176 (which used
-- quadratic Bezier curves, but it doesn't really matter much here).
--
function DefaultPainter.curlyBrace (_, x1, y1 , x2 , y2, width, thickness, curvyness, options)
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
  return {
    path = table.concat({
      -- TOP SEGMENT
      -- From (x1, y1)
      _r(x1), _r(y1), "m",
      -- Goto (qx2, qy2) vith control point (qx1, qy1) on current position (x1, y1)
      _r(qx1), _r(qy1), _r(qx2), _r(qy2), "v",
      -- Then go to (tx, ty) with the reflexion of the previous control point
      -- ((2 * point - control) is the reflexion of control relative to point)
      _r(2 * qx2 - qx1), _r(2 * qy2 - qy1), _r(tx), _r(ty), "v",
      -- TOP SEGMENT THICKNESS
      -- Go back to (qx2b, qy2b) with control control point on it.
      _r(2 * qx2b - qx1), _r(2 * qy2b - qy1), _r(qx2b), _r(qy2b), "y",
      -- And back to the original point (x1, y1), with control point on it.
      _r(qx1), _r(qy1), _r(x1), _r(y1), "y",
      -- BOTTOM SEGMENT
      -- Same thing but from (x2, y2) to (tx, ty) and backwards with thickness.
      _r(x2), _r(y2), "m",
      _r(qx3), _r(qy3), _r(qx4), _r(qy4), "v",
      _r(2 * qx4 - qx3), _r(2 * qy4 - qy3), _r(tx), _r(ty), "v",
      _r(2 * qx4b - qx3), _r(2 * qy4b - qy3), _r(qx4b), _r(qy4b), "y",
      _r(qx3), _r(qy3), _r(x2), _r(y2), "y",
      -- Round line caps and line joins
      1, "J", 1, "j",
    }, " "),
    options = options
  }
end

function DefaultPainter.draw (_, drawable, clippable)
  local o = drawable.options
  local path

  if o.strokeWidth == 0 or not o.stroke then
    if o.fill then
      -- Fill only
      path = table.concat({
        drawable.path,
        makeColorHelper(o.fill, false),
        "f"
      }, " ")
    else
      path = ""
    end
  elseif o.fill then
    -- Stroke and fill
    path = table.concat({
      drawable.path,
      makeColorHelper(o.stroke, true),
      makeColorHelper(o.fill, false),
      _r(o.strokeWidth), "w",
      "B"
    }, " ")
  else
    -- Stroke only
    path = table.concat({
      drawable.path,
      makeColorHelper(o.stroke, true),
      _r(o.strokeWidth), "w",
      "S"
    }, " ")
  end
  if clippable then
    -- Enclose drawing path in a group with the clipping path
    path = table.concat({
      "q",
      clippable.path, "W n",
      path,
      "Q"
    }, " ")
  end
  return path
end

local RoughPainter = pl.class()

function RoughPainter:_init (options)
  self.gen = RoughGenerator(options)
end

function RoughPainter:line (x1, y1, x2, y2, options)
  return self.gen:line(x1, y1, x2, y2, options)
end

function RoughPainter:rectangle (x, y , w , h, options)
  return self.gen:rectangle(x, y , w , h, options)
end

function RoughPainter.roundedRectangle ()
  SU.error("Rounded rectangle not implemented in RoughPainter")
end

function RoughPainter.curlyBrace ()
  SU.error("Curly brace not implemented in RoughPainter")
end

function RoughPainter:draw (drawable)
  local sets = drawable.sets or {}
  local o = drawable.options
  local precision = drawable.options.fixedDecimalPlaceDigits
  local g = {}
  for _, drawing in ipairs(sets) do
    local path
    if drawing.type == "path" then
      path = table.concat({
          self:opsToPath(drawing, precision),
          makeColorHelper(o.stroke, true),
          _r(o.strokeWidth), "w",
          "S"
      }, " ")
    elseif drawing.type == "fillPath" then
      SU.error("Path filling not yet implemented.")
    elseif drawing.type == "fillSketch" then
      path = table.concat({
        self:opsToPath(drawing, precision),
        makeColorHelper(o.fill, true),
        _r(o.strokeWidth), "w",
        "S"
      }, " ")
    end
    if path then
      g[#g + 1] = path
    end
  end
  return table.concat(g, " ")
end

function RoughPainter.opsToPath (_, drawing, _)  -- self, drawing, precision
  local path = {}
  for _, item in ipairs(drawing.ops) do
    local data = item.data
    -- NOTE: we currently ignore the decimal precision option
    if item.op == "move" then
        path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " m"
    elseif item.op == 'bcurveTo' then
        path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " " .. _r(data[5]) .. " " .. _r(data[6]) .. " c"
    elseif item.op == "lineTo" then
        path[#path + 1] = _r(data[1]) .. " " ..  _r(data[2]) .. " l"
    end
  end
  return table.concat(path, " ")
end


local PathRenderer = pl.class()

function PathRenderer:_init (adapter)
  self.adapter = adapter or DefaultPainter()
end

function PathRenderer:line (x1, y1, x2, y2, options)
  local drawable = self.adapter:line(x1, y1, x2, y2, options)
  return self.adapter:draw(drawable)
end

function PathRenderer:rectangle (x, y , w , h, options)
  local drawable = self.adapter:rectangle(x, y, w, h, options)
  return self.adapter:draw(drawable)
end

function PathRenderer:rectangleShadow (x, y , w , h, s, options)
  local drawable = self.adapter:rectangle(x + s, y + s, w, h, options)
  local cliparea = self.adapter:rectangleClip(x, y, w, h, s)
  return self.adapter:draw(drawable, cliparea)
end

function PathRenderer:roundedRectangle (x, y , w , h, rx, ry, options)
  local drawable = self.adapter:roundedRectangle(x, y, w, h, rx, ry, options)
  return self.adapter:draw(drawable)
end

function PathRenderer:roundedRectangleShadow (x, y , w , h, rx, ry, s, options)
  local drawable = self.adapter:roundedRectangle(x + s, y + s, w, h, rx, ry, options)
  local cliparea = self.adapter:roundedRectangleClip(x, y, w, h, rx, ry, s)
  return self.adapter:draw(drawable, cliparea)
end

function PathRenderer:curlyBrace (x1, y1 , x2 , y2, width, thickness, curvyness, options)
  local drawable = self.adapter:curlyBrace( x1, y1 , x2 , y2, width, thickness, curvyness, options)
  return self.adapter:draw(drawable)
end

-- Exports

return {
  PathRenderer = PathRenderer,
  RoughPainter = RoughPainter,
}

