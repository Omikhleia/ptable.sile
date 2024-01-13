local RoughGenerator = require("rough-lua.rough.generator").RoughGenerator

SU.warn("The rough.lua module is deprecated. Please use the rough-lua module instead.")

return {
  RoughGenerator = RoughGenerator,
}
