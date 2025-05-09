--
-- Struts (rules with no width but a certain height) for SILE
--
-- License: MIT
-- Copyright (C) 2021-2025 Omikhleia / Didier Willis
--
local base = require("packages.base")
local package = pl.class(base)
package._name = "struts"

function package:_init ()
  base._init(self)
  self:loadPackage("rebox")
end

function package:declareSettings ()
  SILE.settings:declare({
    parameter = "strut.character",
    type = "string",
    default = "|",
    help = "Strut character"
  })

  SILE.settings:declare({
    parameter = "strut.ruledepth",
    type = "measurement",
    default = SILE.types.measurement("0.3bs"),
    help = "Strut rule depth"
  })

  SILE.settings:declare({
    parameter = "strut.ruleheight",
    type = "measurement",
    default = SILE.types.measurement("1bs"),
    help = "Strut rule height"
  })
end

function package:registerCommands ()
  -- A strut character (for a given font selection) will be used a lot.
  -- It would be a bit dumb to recompute it each time, so let's cache it.
  local strutCache = {}

  local _key = function (options)
    return table.concat({ options.family,
      ("%g"):format(options.size),
      ("%d"):format(options.weight),
      options.style,
      options.variant,
      options.features,
      options.filename }, ";")
  end
  local characterStrut = function ()
    local key = _key(SILE.font.loadDefaults({}))
    local strutCached = strutCache[key]
    if strutCached then return strutCached end
    local hbox = SILE.typesetter:makeHbox({ SILE.settings:get("strut.character") })
    strutCache[key] = {
      height = hbox.height,
      depth = hbox.depth,
    }
    return strutCache[key]
  end

  self:registerCommand("strut", function (options, _)
    local method = options.method or "character"
    local show = SU.boolean(options.show, true)
    local strut
    if method == "rule" then
      strut = {
        height = SILE.types.length(SILE.settings:get("strut.ruleheight")):absolute(),
        depth = SILE.types.length(SILE.settings:get("strut.ruledepth")):absolute(),
      }
      if show then
        -- The content there could be anything, we just want to be sure we get a box
        SILE.call("rebox", { phantom = true, height = strut.height, depth = strut.depth, width = SILE.types.length() }, {})
      end
    elseif method == "character" then
      strut = characterStrut()
      if show then
        SILE.call("rebox", { phantom = true, width = SILE.types.length() }, { SILE.settings:get("strut.character") })
      end
    else
      SU.error("Unknown strut method '" .. method .. "'")
    end
    return strut
  end, "Formats a strut box, shows it if requested, and returns its height and depth dimentions to Lua.")
end

package.documentation = [[
\begin{document}
\use[module=packages.struts]
In professional typesetting, a “strut” is a rule with no width but a certain height
and depth, to help guaranteeing that an element has a certain minimal height and depth,
e.g. in tabular environments or in boxes.

Two possible implementations are proposed by the \autodoc:package{struts} package:
one based on a character, defined via the \autodoc:setting{strut.character} setting,
by default the vertical bar (|),
and one relative to the current baseline skip, via the \autodoc:setting{strut.ruledepth}
and \autodoc:setting{strut.ruleheight} settings, by default respectively 0.3bs and 1bs,
following the same definition as in LaTeX.
So they do not achieve exactly the same effect:
the former should ideally be a character that covers the maximum ascender and descender
heights in the current font; the latter uses an alignment at the baseline skip level
assuming it is reasonably fixed.

The standalone user command is \autodoc:command{\strut[method=<method>]},
where the method can be “character” (default) or “rule”.
It returns the height and depth dimensions (for possible use in Lua code).
If needed, the \autodoc:parameter{show} option indicates whether the rule should be inserted at this
point (defaults to true, again this is mostly intended at Lua code, where you could want to compute
the current strut dimensions \em{without} adding it to the text flow).

\end{document}]]

return package
