package = "ptable.sile"
version = "dev-1"
source = {
  url = "git+https://github.com/Omikhleia/ptable.sile.git",
}
description = {
  summary = "Paragraph boxes, framed boxes and table packages for the SILE typesetting system.",
  detailed = [[
    This package for the SILE typesetter provides struts, paragraph boxes
    (parbox), framed boxes (framebox) and tables (ptable).
  ]],
  homepage = "https://github.com/Omikhleia/ptable.sile",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1",
  "silex.sile",
}
build = {
  type = "builtin",
  modules = {
    ["sile.packages.struts"]                      = "packages/struts/init.lua",
    ["sile.packages.parbox"]                      = "packages/parbox/init.lua",
    ["sile.packages.ptable"]                      = "packages/ptable/init.lua",
    ["sile.packages.framebox"]                    = "packages/framebox/init.lua",
    ["sile.packages.framebox.graphics.prng"]      = "packages/framebox/graphics/prng.lua",
    ["sile.packages.framebox.graphics.renderer"]  = "packages/framebox/graphics/renderer.lua",
    ["sile.packages.framebox.graphics.rough"]     = "packages/framebox/graphics/rough.lua",
    ["sile.resilient-compat.hboxing"]             = "resilient-compat/hboxing.lua",
  }
}
