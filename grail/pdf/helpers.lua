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

--- Builds a PDF graphics path from a starting position (x, y)
-- and a set of relative segments which can be either lines (2 coords)
-- or bezier curves (6 segments).
--
-- @tparam  number    x         Starting position X coordinate
-- @tparam  number    y         Starting position Y coordinate
-- @tparam  number    segments  Relative segments
-- @treturn string              PDF graphics path
local function makePathHelper (x, y, segments)
  local paths = { { _r(x), _r(y), "m" } }
  for i = 1, #segments do
    local s = segments[i]
    if #s == 2 then
      -- line
      x = s[1] + x
      y = s[2] + y
      paths[#paths + 1] = { _r(x), _r(y), "l" }
    else
      -- bezier curve
      paths[#paths + 1] = { _r(s[1] + x), _r(s[2] + y), _r(s[3] + x), _r(s[4] + y), _r(s[5] + x), _r(s[6] + y), "c" }
      x = s[5] + x
      y = s[6] + y
    end
  end
  for i, v in ipairs(paths) do
    paths[i] = table.concat(v, " ")
  end
  return table.concat(paths, " ")
end

return {
  _r = _r,
  makeColorHelper = makeColorHelper,
  makePathHelper = makePathHelper,
}
