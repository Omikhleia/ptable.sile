--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--
local PDFHelpers = require("grail.pdf.helpers")
local _r, makeColorHelper, makePathHelper = PDFHelpers._r, PDFHelpers.makeColorHelper, PDFHelpers.makePathHelper

local DefaultPainter = pl.class()

DefaultPainter.defaultOptions = {
  strokeWidth = 1,
}

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
    path = table.concat({ _r(x1), _r(y1), "m", _r(x2 - x1), _r(y2 - y1), "l" }, " "),
    options = o,
  }
end

--- Path for a rectangle with upper left (x, y), with given width and height.
function DefaultPainter:rectangle (x, y , w , h, options)
  local o = self:_o(options)
  return {
    path = table.concat({ _r(x), _r(y), _r(w), _r(h), "re" }, " "),
    options = o,
  }
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
  return {
    path = makePathHelper(x0, y, segments),
    options = o,
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
function DefaultPainter:curlyBrace (x1, y1 , x2 , y2, width, thickness, curvyness, options)
  local o = self:_o(options)

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
    options = o
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

function DefaultPainter.draw (_, drawable, clippable)
  local o = drawable.options
  local path

  if o.strokeWidth == 0 or o.stroke == 'none' then
    if o.fill ~= 'none' then
      -- Fill only
      path = table.concat({
        drawable.path,
        makeColorHelper(o.fill, false),
        "f"
      }, " ")
    else
      path = ""
    end
  elseif o.fill ~= 'none' then
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

return {
  DefaultPainter = DefaultPainter
}