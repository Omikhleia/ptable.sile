--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--
local RoughGenerator = require("rough-lua.rough.generator").RoughGenerator
local PRNG = require("prng-prigarin")

local RoughPainter = pl.class()
local prng = PRNG()

local PDFHelpers = require("grail.pdf.helpers")
local _r, makeColorHelper = PDFHelpers._r, PDFHelpers.makeColorHelper

function RoughPainter:_init (options)
  local o = options or {}
  if not o.randomizer then
    o.randomizer = prng -- use common 'static' PRNG instance
    -- so that all sketchy drawings look random but reproducible
  end
  self.gen = RoughGenerator(o)
end

function RoughPainter:line (x1, y1, x2, y2, options)
  return self.gen:line(x1, y1, x2, y2, options)
end

function RoughPainter:rectangle (x, y , w , h, options)
  return self.gen:rectangle(x, y , w , h, options)
end

function RoughPainter:ellipse (x, y , w , h, options)
  return self.gen:ellipse(x, y , w , h, options)
end

function RoughPainter:circle (x, y , diameter, options)
  return self.gen:circle(x, y , diameter, options)
end

function RoughPainter:arc (x, y , w , h, start, stop, closed, options)
  return self.gen:arc(x, y , w , h, start, stop, closed, options)
end

function RoughPainter.rectangleShadow ()
  SU.error("Rectangle shadow not implemented in RoughPainter")
end

function RoughPainter.roundedRectangle ()
  SU.error("Rounded rectangle not implemented in RoughPainter")
end

function RoughPainter.roundedRectangleShadow ()
  SU.error("Rounded rectangle shadow not implemented in RoughPainter")
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
      path = table.concat({
        self:opsToPath(drawing, precision),
        makeColorHelper(o.fill, false),
        _r(o.strokeWidth), "w",
        "f"
      }, " ")
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

return {
  RoughPainter = RoughPainter,
}
