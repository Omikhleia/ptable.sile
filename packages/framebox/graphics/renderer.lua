-- Compatibility with ptable 3.x
local PathRenderer = require("grail.renderer").PathRenderer
local RoughPainter = require("grail.painters.rough").RoughPainter

SU.warn("Direct use of the graphics module from framebox is deprecated. Please use the grail module instead.")

return {
  PathRenderer = PathRenderer,
  RoughPainter = RoughPainter,
}
