-- Compatibility with ptable 3.x (for other modules that depended on framebox.graphics)
local PathRenderer = require("grail.renderers.pdf")
local RoughPainter = require("grail.painters.rough")

SU.warn("Direct use of the graphics module from framebox is deprecated. Please use the grail module instead.")

return {
  PathRenderer = PathRenderer,
  RoughPainter = RoughPainter,
}
