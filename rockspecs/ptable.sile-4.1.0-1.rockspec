rockspec_format = "3.0"
package = "ptable.sile"
version = "4.1.0-1"
source = {
  url = "git+https://github.com/Omikhleia/ptable.sile.git",
  tag = "v4.1.0",
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
  "grail",
}
build = {
  type = "builtin",
  modules = {
    ["sile.packages.struts"]                      = "packages/struts/init.lua",
    ["sile.packages.parbox"]                      = "packages/parbox/init.lua",
    ["sile.packages.ptable"]                      = "packages/ptable/init.lua",
    ["sile.packages.framebox"]                    = "packages/framebox/init.lua",
    ["sile.packages.framebox.graphics.renderer"]  = "packages/framebox/graphics/renderer.lua",
    ["sile.packages.framebox.graphics.rough"]     = "packages/framebox/graphics/rough.lua",
  }
}
