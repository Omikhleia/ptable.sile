--
-- Fancy framed boxes for SILE
--
-- KNOWN ISSUE: RTL and BTT writing directions are not officialy supported yet (untested)
--
-- License: MIT
-- Copyright (C) 2021-2025 Omikhleia / Didier Willis
--
local PathRenderer = require("grail.renderer")
local RoughPainter = require("grail.painters.rough")

local base = require("packages.base")
local package = pl.class(base)
package._name = "framebox"

-- LOW-LEVEL REBOXING HELPERS

-- Rewraps an hbox into another fake hbox, adding padding all around it.
-- It assumes the original hbox is NOT in the typesetter queue
-- (i.e. was only built and stored earlier).
-- It returns the wrapped box without pushing it to the typesetter.
-- @tparam hbox       hbox         The hbox to wrap for padding
-- @tparam number     left         Left padding (in points)
-- @tparam number     right        Right padding (in points)
-- @tparam number     top          Top padding (in points)
-- @tparam number     bottom       Bottom padding (in points)
-- @treturn hbox                   (Fake) hbox
local function adjustPaddingHbox (hbox, left, right, top, bottom)
  return { -- HACK NOTE: Efficient but might be bad to fake an hbox here without all methods.
    inner = hbox,
    width = hbox.width + left + right,
    height = hbox.height + top,
    depth = hbox.depth + bottom,
    outputYourself = function (self, typesetter, line)
      typesetter.frame:advanceWritingDirection(left)
      self.inner:outputYourself(typesetter, line)
      typesetter.frame:advanceWritingDirection(right)
    end
  }
end

-- Rewraps an hbox into another hbox responsible for framing it,
-- via a path construction callback called with the target width,
-- height and depth (assuming 0,0 as original point on the baseline)
-- and must return a PDF graphics.
-- It assumes the initial hbox is NOT in the typesetter queue
-- (i.e. was only built and stored earlier).
-- It pushes the resulting hbox to the typesetter queue,
-- immediately followed by any passed hlist (migrating nodes).
-- @tparam hbox       hbox         The hbox to re-frame
-- @tparam array      hlist        Migrating node list
-- @tparam number|nil shadowsize   Shadow size (in points)
-- @tparam function   pathfn       Path construction calback
local function frameHbox (hbox, hlist, shadowsize, pathfn)
  local shadowpadding = shadowsize or 0
  SILE.typesetter:pushHbox({
    inner = hbox,
    width = hbox.width,
    height = hbox.height,
    depth = hbox.depth,
    outputYourself = function (self, typesetter, line)
      local saveX = typesetter.frame.state.cursorX
      local saveY = typesetter.frame.state.cursorY
      -- Scale to line to take into account strech/shrinkability
      local outputWidth = self:scaledWidth(line)
      -- Force advancing to get the new cursor position
      typesetter.frame:advanceWritingDirection(outputWidth)
      local newX = typesetter.frame.state.cursorX

      -- Compute the target width, height, depth for the frame
      local w = (newX - saveX):tonumber() - shadowpadding
      local h = self.height:tonumber()
      local d = self.depth:tonumber() - shadowpadding

      -- Compute and draw the PDF graphics (path)
      local path = pathfn(w, h, d)
      if path then
        SILE.outputter:drawSVG(path, saveX, saveY, w, h + d, 1)
      end

      -- Restore cursor position and output the content last (so it appears
      -- on top of the frame)
      typesetter.frame.state.cursorX = saveX
      self.inner:outputYourself(typesetter, line)
      typesetter.frame.state.cursorX = newX
    end
  })
  SILE.typesetter:pushHlist(hlist)
end

-- SETTINGS

function package:declareSettings ()
  SILE.settings:declare({
    parameter = "framebox.padding",
    type = "measurement",
    default = SILE.types.measurement("2pt"),
    help = "Padding applied to a framed box."
  })

  SILE.settings:declare({
    parameter = "framebox.borderwidth",
    type = "measurement",
    default = SILE.types.measurement("0.4pt"),
    help = "Border width applied to a frame box."
  })

  SILE.settings:declare({
    parameter = "framebox.cornersize",
    type = "measurement",
    default = SILE.types.measurement("5pt"),
    help = "Corner size (arc radius) for rounded boxes."
  })

  SILE.settings:declare({
    parameter = "framebox.shadowsize",
    type = "measurement",
    default = SILE.types.measurement("3pt"),
    help = "Shadow width applied to a framed box when dropped shadow is enabled."
  })
end

-- BASIC BOX-FRAMING COMMANDS

function package:registerCommands ()
  self:registerCommand("framebox", function (options, content)
    local padding = SU.cast("measurement", options.padding or SILE.settings:get("framebox.padding")):tonumber()
    local borderwidth = SU.cast("measurement", options.borderwidth or SILE.settings:get("framebox.borderwidth")):tonumber()
    local bordercolor
    if borderwidth ~= 0 then
      bordercolor = options.bordercolor and SILE.types.color(options.bordercolor)
    end
    local fillcolor = options.fillcolor and SILE.types.color(options.fillcolor) or 'none'
    local shadow = SU.boolean(options.shadow, false)
    local shadowsize = shadow and SU.cast("measurement", options.shadowsize or SILE.settings:get("framebox.shadowsize")):tonumber() or 0
    local shadowcolor = shadow and options.shadowcolor and SILE.types.color(options.shadowcolor)

    local hbox, hlist = SILE.typesetter:makeHbox(content)
    hbox = adjustPaddingHbox(hbox, padding, padding + shadowsize, padding, padding + shadowsize)

    frameHbox(hbox, hlist, shadowsize, function (w, h, d)
      local painter = PathRenderer()
      local shadowpath, path
      if shadowsize ~= 0 then
        shadowpath = painter:rectangleShadow(0, d, w , h + d, shadowsize, {
          fill = shadowcolor,
          stroke = 'none'
        })
      end
      path = painter:rectangle(0, d , w , h + d, {
        fill = fillcolor, stroke = bordercolor, strokeWidth = borderwidth
      })
      return shadowpath and shadowpath .. " " .. path or path
    end)
  end, "Frames content in a square box.")

  self:registerCommand("roundbox", function (options, content)
    local padding = SU.cast("measurement", options.padding or SILE.settings:get("framebox.padding")):tonumber()
    local borderwidth = SU.cast("measurement", options.borderwidth or SILE.settings:get("framebox.borderwidth")):tonumber()
    local bordercolor
    if borderwidth ~= 0 then
      bordercolor = options.bordercolor and SILE.types.color(options.bordercolor)
    end
    local fillcolor = options.fillcolor and SILE.types.color(options.fillcolor) or 'none'
    local shadow = SU.boolean(options.shadow, false)
    local shadowsize = shadow and SU.cast("measurement", options.shadowsize or SILE.settings:get("framebox.shadowsize")):tonumber() or 0
    local shadowcolor = shadow and options.shadowcolor and SILE.types.color(options.shadowcolor)

    local cornersize = SU.cast("measurement", options.cornersize or SILE.settings:get("framebox.cornersize")):tonumber()

    local hbox, hlist = SILE.typesetter:makeHbox(content)
    hbox = adjustPaddingHbox(hbox, padding, padding + shadowsize, padding, padding + shadowsize)

    frameHbox(hbox, hlist, shadowsize, function (w, h, d)
      local H = h + d
      local smallest = w < H and w or H
      cornersize = cornersize < 0.5 * smallest and cornersize or math.floor(0.5 * smallest)

      local painter = PathRenderer()
      local shadowpath, path
      if shadowsize ~= 0 then
        shadowpath = painter:roundedRectangleShadow(0, d , w , H, cornersize, cornersize, shadowsize, {
          fill = shadowcolor,
          stroke = 'none'
        })
      end
      path = painter:roundedRectangle(0, d , w , H, cornersize, cornersize, {
        fill = fillcolor, stroke = bordercolor, strokeWidth = borderwidth
      })
      return shadowpath and shadowpath .. " " .. path or path
    end)
  end, "Frames content in a rounded box.")

  self:registerCommand("roughbox", function (options, content)
    local padding = SU.cast("measurement", options.padding or SILE.settings:get("framebox.padding")):tonumber()
    local border = SU.boolean(options.border, true)
    local borderwidth = SU.cast("measurement", options.borderwidth or SILE.settings:get("framebox.borderwidth")):tonumber()
    if borderwidth <= 0 then
      border = false
      -- This is actually a stroke width, so we need to make sure it is not 0
      -- (for hachures etc.)
      borderwidth = SILE.settings:get("framebox.borderwidth"):tonumber()
    end
    local bordercolor = options.bordercolor and SILE.types.color(options.bordercolor)
    local fillcolor = options.fillcolor and SILE.types.color(options.fillcolor)
    local enlarge = SU.boolean(options.enlarge, false)

    local hbox, hlist = SILE.typesetter:makeHbox(content)
    if enlarge then
      hbox = adjustPaddingHbox(hbox, padding, padding, padding, padding)
    end

    local roughOpts = {
      roughness = options.roughness and SU.cast("number", options.roughness) or nil,
      bowing = options.bowing and SU.cast("number", options.bowing) or nil,
      preserveVertices = SU.boolean(options.preserve, false),
      disableMultiStroke = SU.boolean(options.singlestroke, false),
      strokeWidth = borderwidth,
      stroke = border and bordercolor or 'none',
      fill = fillcolor,
      fillStyle = options.fillstyle or 'hachure'
    }

    frameHbox(hbox, hlist, nil, function (w, h, d)
      local H = h + d
      local x = 0
      local y = d
      if not enlarge then
        x = -padding
        y = d - padding
        H = H + 2 * padding
        w = w + 2 * padding
      end
      local painter = PathRenderer(RoughPainter())
      return painter:rectangle(x, y, w, H, roughOpts)
    end)
  end, "Frames content in a rough (sketchy) box.")

  self:registerCommand("bracebox", function (options, content)
    local padding = SU.cast("measurement", options.padding or SILE.types.measurement("0.25em")):tonumber()
    local strokewidth = SU.cast("measurement", options.strokewidth or SILE.types.measurement("0.033em")):tonumber()
    local bracecolor = options.bracecolor and SILE.types.color(options.bracecolor)
    local bracewidth = SU.cast("measurement", options.bracewidth or SILE.types.measurement("0.25em")):tonumber()
    local bracethickness = SU.cast("measurement", options.bracethickness or SILE.types.measurement("0.05em")):tonumber()
    local curvyness = SU.cast("number", options.curvyness or 0.6)
    local left, right
    if options.side == "left" or not options.side then left = true
    elseif options.side == "right" then right = true
    elseif options.side == "both" then left, right = true, true
    else SU.error("Invalid side parameter") end

    local hbox, hlist = SILE.typesetter:makeHbox(content)
    hbox = adjustPaddingHbox(hbox, left and bracewidth + padding or 0, right and bracewidth + padding or 0, 0, 0)

    frameHbox(hbox, hlist, nil, function (w, h, d)
      local painter = PathRenderer()
      local lb, rb
      if left then
        lb = painter:curlyBrace(bracewidth, d, bracewidth, 2*d+h, bracewidth, bracethickness, curvyness, {
          fill = bracecolor,
          stroke = bracecolor,
          strokeWidth = strokewidth
        })
      end
      if right then
        rb = painter:curlyBrace(w-bracewidth, d, w-bracewidth, 2*d+h, -bracewidth, bracethickness, curvyness, {
          fill = bracecolor,
          stroke = bracecolor,
          strokeWidth = strokewidth
        })
      end
      return lb and (rb and lb .. " " .. rb or lb) or rb
    end)
  end, "Frames content in a box with curly brace(s).")

end

package.documentation = [[
\begin{document}
\use[module=packages.parbox]
\use[module=packages.framebox]

As its name implies, the \autodoc:package{framebox} package provide several horizontal box framing goodies.

The \autodoc:command{\framebox} command frames its content in a \framebox{square box.}

The frame border width relies on the
\autodoc:setting{framebox.borderwidth} setting (defaults to 0.4pt), unless the
\autodoc:parameter{borderwidth} option is explicitly specified as command argument.

The padding distance between the content and the frame relies on the
\autodoc:setting{framebox.padding} setting (defaults to 2pt), again unless the
\autodoc:parameter{padding} option is explicitly specified.

If the \autodoc:parameter{shadow} option is set to true, a \framebox[shadow=true]{dropped shadow} is applied.

The shadow width (or offset size) relies on the
\autodoc:setting{framebox.shadowsize} setting (defaults to 3pt), unless the
\autodoc:parameter{shadowsize} option is explicitly specified.

With the well-named \autodoc:parameter{bordercolor}, \autodoc:parameter{fillcolor}
and \autodoc:parameter{shadowcolor} options, one can also specify how the box
is \framebox[shadow=true, bordercolor=#b94051, fillcolor=#ecb0b8, shadowcolor=220]{colored.}
The color specifications are the same as defined in the \autodoc:package{color} package.

The \autodoc:command{\roundbox} command frames its content in a \roundbox{rounded box.}
It supports the same options, so one can have a \roundbox[shadow=true]{dropped shadow} too.

Or likewise, \roundbox[shadow=true, bordercolor=#b94051, fillcolor=#ecb0b8, shadowcolor=220]{apply colors.}

The radius of the rounded corner arc relies on the \autodoc:setting{framebox.cornersize} setting (defaults to 5pt),
unless the \autodoc:parameter{cornersize} option, as usual, is explicitly specified as argument to the command.
(If one of the sides of the boxed content is smaller than that, then the maximum allowed rounding effect
will be computed instead.)

For authors thriving for fancyness, there is the \autodoc:command{\roughbox} command that frames its content
in a \em{sketchy}, hand-drawn-like style\footnote{The implementation is based on a partial port of
the \em{rough.js} JavaScript library. It uses its own pseudo-random number generator, so that
rough sketches in your document all look different but remain the same when the document is rebuilt.}:
\roughbox[bordercolor=#59b24c]{a rough box.}

As above, the \autodoc:parameter{padding}, \autodoc:parameter{borderwidth} and \autodoc:parameter{bordercolor}
options all apply, as well as \autodoc:parameter{fillcolor},
so one can make a \roughbox[bordercolor=#b94051,fillcolor=220]{rough \em{hachured} box.}

Sketching options are
\autodoc:parameter{roughness} (numerical value indicating how rough the drawing is; 0 would be a perfect rectangle, the default value is 1 and there is no upper limit to this value but a value over 10 is mostly useless),
\autodoc:parameter{bowing} (numerical value indicating how curvy the lines are when
drawing a sketch; a value of 0 will cause straight lines and the default value is 1),
\autodoc:parameter{preserve} (defaults to false; when set to true, the \roughbox[bordercolor=#22427c, preserve=true]{locations} of the end points are not randomized),
\autodoc:parameter{singlestroke} (defaults to false; if set to true, a single stroke is applied
to sketch the shape instead of multiple strokes).
For instance, here is a single-stroked \roughbox[bordercolor=#59b24c, singlestroke=true]{rough box,}
and a cross-hatched \roughbox[border=false, fillcolor=#ecebbd, fillstyle=cross-hatch]{rough box.}

The last example also shows the \autodoc:parameter{fillstyle} option (defaults to “hachure”).
It can also be set to “solid”, “zigzag”, “cross-hatch”, “dashed” or “zigzag-line”.

\smallskip
\roughbox[bordercolor=150, fillcolor=#bcc6d7, singlestroke=true]{Hachure,}\kern[width=0.8em]
\roughbox[bordercolor=150, fillcolor=#bcc6d7, singlestroke=true, fillstyle=solid]{solid,}\kern[width=0.8em]
\roughbox[bordercolor=150, fillcolor=#bcc6d7, singlestroke=true, fillstyle=zigzag]{zigzag,}\kern[width=0.8em]
\roughbox[bordercolor=150, fillcolor=#bcc6d7, singlestroke=true, fillstyle=cross-hatch]{cross-hatch,}\kern[width=0.8em]
\roughbox[bordercolor=150, fillcolor=#bcc6d7, singlestroke=true, fillstyle=dashed]{dashed,}\kern[width=0.8em]
\roughbox[bordercolor=150, fillcolor=#bcc6d7, singlestroke=true, fillstyle=zigzag-line]{zigag-line.}

\smallskip
The border width is actually the stroke width, also used for the hachures, etc.
Use \autodoc:parameter{border=false} if you want to disable the border and only keep the fill.

Compared to the previous box framing commands, rough boxes by default do not take up more horizontal
and vertical space due to their padding, as if the sketchy box was indeed manually added
upon an existing text, without altering line height and spacing. Set the \autodoc:parameter{enlarge}
option to true \roughbox[bordercolor=#22427c, enlarge=true]{to revert} this behavior (but also note
that due to their rough style, these boxes may still sometimes overlap with surrounding content).

The \autodoc:command{\bracebox} commands draws a nice curly brace, by default on the left side of its
\bracebox{\strut{}content}.
The \autodoc:parameter{side} options may be set to \bracebox[side=right]{\strut{}“right”} or
\bracebox[side=both]{\strut{}“both”}.
As for fine-tuning options, \autodoc:parameter{padding} controls the space between the brace and the content
(defaults to 0.25em),
\autodoc:parameter{bracewidth} defines the width of the whole brace (defaults to 0.25em),
\autodoc:parameter{strokewidth} (defaults to 0.033em) and \autodoc:parameter{bracethickness} (0.05em) define
the drawing characteristics of the brace.
Its color can be changed with \autodoc:parameter{bracecolor}.
Finally, \autodoc:parameter{curvyness} (defaults to 0.6) is a number between 0.5 and 1, defining how curvy
is the brace: 0.5 is the “normal” value (quite straight) and higher values giving a more “expressive”
brace (anything above 0.725 is probably quite useless). As can be seen with the default values,
they should be in a unit relative to the current font, so as to fit best with its current size.
The default values are rather arbitrary but were found decent for a variety of fonts. Wait,
we do hear you, at this point. Why you would possibly want this \autodoc:command{\bracebox} thing where you
could use a regular character? Because it adapts to its content height, and an example further below
will show you its full potential.

As final notes, the box logic provided in this package applies to the natural size of the box content.

Thus \roundbox{a}, \roundbox{b} and \roundbox{p.}

To avoid such an effect, one could for instance consider inserting a \autodoc:command{\strut} in the content.
This command is provided by the \autodoc:package{struts} package.

Thus now \roundbox{\strut{}a}, \roundbox{\strut{}b} and \roundbox{\strut{}p.}

The \autodoc:package{parbox} package can also be used to shape whole paragraphs into an horizontal box.
It may make a good candidate if you want to use the commands provided here around paragraphs:

\center{\framebox[shadow=true]{\parbox[valign=middle,width=5cm]{This is a long content as a boxed
paragraph.\footnote{Did we mention that footnotes are supported in all these boxes?
Now you know.}}}}

\smallskip
Or also\dotfill{} \bracebox{\parbox[valign=middle,width=6cm]{\noindent This is a another paragraph, but now with a nice
curly brace.}}

\smallskip
And as real last words, obviously, framed boxes are just horizonal boxes, so they will not be subject
to line-breaking and the users are warned that they have to check that their content doesn’t cause
the line to overflow. Also, as can be seen in the examples above, the padding and the dropped shadow may
naturally alter the line height.

\end{document}]]

return package
