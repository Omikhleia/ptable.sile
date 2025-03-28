--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--
local DefaultPainter = require("grail.painters.default").DefaultPainter

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

function PathRenderer:ellipse (x, y , w , h, options)
  local drawable = self.adapter:ellipse(x, y, w, h, options)
  return self.adapter:draw(drawable)
end

function PathRenderer:circle (x, y , w , h, options)
  local drawable = self.adapter:circle(x, y, w, h, options)
  return self.adapter:draw(drawable)
end

function PathRenderer:arc (x, y , w , h, start, stop, closed, options)
  local drawable = self.adapter:arc(x, y, w, h, start, stop, closed, options)
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
  PathRenderer = PathRenderer
}
