--
-- Renderer class to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--

-- HELPERS

--- Round number to string for output.
--
-- @tparam  number    number    number value
-- @treturn string              rounded value as string
local function _r (number)
  -- Lua 5.3+ formats floats as 1.0 and integers as 1
  -- Also some PDF readers do not like double precision.
  return math.floor(number) == number and tostring(math.floor(number)) or string.format("%.5f", number)
end

--- Builds a PDF graphics color (stroke or fill) from a SILE parsed color.
--
-- @tparam  table|nil  color     SILE color object
-- @tparam  boolean    stroke    Stroke or fill
-- @treturn string               PDF graphics color
local function makeColorHelper (color, stroke)
  if not color then
    return "" -- let current color be used
  end
  local colspec
  local colop
  if color.r then -- RGB
    colspec = table.concat({ _r(color.r), _r(color.g), _r(color.b) }, " ")
    colop = stroke and "RG" or "rg"
  elseif color.c then -- CMYK
    colspec = table.concat({ _r(color.c), _r(color.m), _r(color.y), _r(color.k) }, " ")
    colop = stroke and "K" or "k"
  elseif color.l then -- Grayscale
    colspec = _r(color.l)
    colop = stroke and "G" or "g"
  else
    SU.error("Invalid color specification")
  end
  return colspec .. " " .. colop
end

local function opsToPath (drawing, _)  -- drawing, precision
  local path = {}
  for _, item in ipairs(drawing.ops) do
    local data = item.data
    -- NOTE: we currently ignore the decimal precision option
    if item.op == "move" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " m"
    elseif item.op == 'bcurveTo' then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " " .. _r(data[5]) .. " " .. _r(data[6]) .. " c"
    elseif item.op == "vcurveTo" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " v"
    elseif item.op == "ycurveTo" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " y"
    elseif item.op == "rect" then
      path[#path + 1] = _r(data[1]) .. " " .. _r(data[2]) .. " " .. _r(data[3]) .. " " .. _r(data[4]) .. " re"
    elseif item.op == "lineTo" then
      path[#path + 1] = _r(data[1]) .. " " ..  _r(data[2]) .. " l"
    end
  end
  return table.concat(path, " ")
end

-- PDF PATH RENDERER

local base = require("grail.renderers.base")
local PathRenderer = pl.class(base)

function PathRenderer:draw (drawable, clippable)
  local sets = drawable.sets or {}
  local o = drawable.options
  local precision = drawable.options.fixedDecimalPlaceDigits
  local g = {}
  for _, drawing in ipairs(sets) do
    local path = opsToPath(drawing, precision)
    if o.rounded == true then
      path = path .. " 1 J 1 j"
    end
    -- path = stroke only
    if drawing.type == "path" then
      path = table.concat({
          path,
          makeColorHelper(o.stroke, true),
          _r(o.strokeWidth), "w",
          "S"
      }, " ")
    -- fillPath = fill only
    elseif drawing.type == "fillPath" then
      path = table.concat({
        path,
        makeColorHelper(o.fill, false),
        "f"
      }, " ")
    -- fillSketch = stroke only
    elseif drawing.type == "fillSketch" then
      path = table.concat({
        path,
        makeColorHelper(o.fill, true),
        _r(o.strokeWidth), "w",
        "S"
      }, " ")
    -- shape = fill and stroke in one operation
    elseif drawing.type == "shape" then
      path = table.concat({
        path,
        makeColorHelper(o.stroke, true),
        makeColorHelper(o.fill, false),
        _r(o.strokeWidth), "w",
        "B"
      }, " ")
    else
      SU.error("Unknown drawing type: " .. drawing.type)
    end
    if path then
      g[#g + 1] = path
    end
  end
  local path = table.concat(g, " ")
  if clippable then
    -- Enclose drawing path in a group with the clipping path
    clippable.options = drawable.options
    local clip = opsToPath(clippable.sets[1], precision)
     path = table.concat({
       "q",
       clip, "W n",
       path,
       "Q"
     }, " ")
  end
  return path
end

return PathRenderer
