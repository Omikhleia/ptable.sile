--
-- Some classes to build PDF graphics drawings (path strings)
-- License: MIT
-- 2022, 2023, 2025 Didier Willis
--

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

return {
  _r = _r,
  makeColorHelper = makeColorHelper,
}
