--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--
local RoughGenerator = require("rough-lua.rough.generator").RoughGenerator
local PRNG = require("prng-prigarin")

local RoughPainter = pl.class()
local prng = PRNG()

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

function RoughPainter.rectangleClip ()
  SU.error("Rectangle clipping not implemented in RoughPainter")
end

function RoughPainter.roundedRectangle ()
  SU.error("Rounded rectangle not implemented in RoughPainter")
end

function RoughPainter.roundedRectangleClip ()
  SU.error("Rounded rectangle clip not implemented in RoughPainter")
end

function RoughPainter.curlyBrace ()
  SU.error("Curly brace not implemented in RoughPainter")
end

function RoughPainter.pieSector ()
  SU.error("Pie sector not implemented in RoughPainter")
end

return RoughPainter
