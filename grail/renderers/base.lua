--
-- Base path renderer class for Grail
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--
local DefaultPainter = require("grail.painters.default")

local PathRenderer = pl.class()

function PathRenderer:_init (painter)
  self.painter = painter or DefaultPainter()
end

function PathRenderer:line (x1, y1, x2, y2, options)
  local drawable = self.painter:line(x1, y1, x2, y2, options)
  return self:draw(drawable)
end

function PathRenderer:rectangle (x, y , w , h, options)
  local drawable = self.painter:rectangle(x, y, w, h, options)
  return self:draw(drawable)
end

function PathRenderer:ellipse (x, y , w , h, options)
  local drawable = self.painter:ellipse(x, y, w, h, options)
  return self:draw(drawable)
end

function PathRenderer:circle (x, y , w , h, options)
  local drawable = self.painter:circle(x, y, w, h, options)
  return self:draw(drawable)
end

function PathRenderer:arc (x, y , w , h, start, stop, closed, options)
  local drawable = self.painter:arc(x, y, w, h, start, stop, closed, options)
  return self:draw(drawable)
end

function PathRenderer:rectangleShadow (x, y , w , h, s, options)
  local drawable = self.painter:rectangle(x + s, y + s, w, h, options)
  local cliparea = self.painter:rectangleClip(x, y, w, h, s)
  return self:draw(drawable, cliparea)
end

function PathRenderer:roundedRectangle (x, y , w , h, rx, ry, options)
  local drawable = self.painter:roundedRectangle(x, y, w, h, rx, ry, options)
  return self:draw(drawable)
end

function PathRenderer:roundedRectangleShadow (x, y , w , h, rx, ry, s, options)
  local drawable = self.painter:roundedRectangle(x + s, y + s, w, h, rx, ry, options)
  local cliparea = self.painter:roundedRectangleClip(x, y, w, h, rx, ry, s)
  return self:draw(drawable, cliparea)
end

function PathRenderer:curlyBrace (x1, y1 , x2 , y2, width, thickness, curvyness, options)
  local drawable = self.painter:curlyBrace( x1, y1 , x2 , y2, width, thickness, curvyness, options)
  return self:draw(drawable)
end

function PathRenderer:pieSector (x, y, radius, startAngle, arcAngle, ratio, options)
  local drawable = self.painter:pieSector(x, y, radius, startAngle, arcAngle, ratio, options)
  return self:draw(drawable)
end

function PathRenderer.draw (_, _, _) -- self, drawable, clippable
  SU.error("PathRenderer:draw() is abstract")
end

-- Exports

return PathRenderer
