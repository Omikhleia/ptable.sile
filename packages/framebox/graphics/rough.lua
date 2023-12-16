local RoughGenerator = require("packages.framebox.rough-lua.generator").RoughGenerator

SU.warn("The rough.lua module is deprecated. Please use the rough-lua module instead.")

return {
  RoughGenerator = RoughGenerator,
}
