-- Compatibility with ptable 2.x (for other modules that depended on framebox.graphics)
local RoughGenerator = require("rough-lua.rough.generator").RoughGenerator

SU.warn("Direct use of the rough.lua module from framebox is deprecated. Please use the rough-lua module instead.")

return {
  RoughGenerator = RoughGenerator,
}
