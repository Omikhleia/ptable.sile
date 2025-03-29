--- Color class for Grail
--
-- @copyright License: MIT (c) 2024, 2025 Omikhleia, Didier Willis
--
local base = require("grail.color.compat") -- To extend the SILE color class if available
local Color = pl.class(base)

-- Converts an RGB (Red, Green, Blue) color to HSL (Hue, Saturation, Lightness)
-- @tparam table color Table with RGB values (r, g, b) in the range 0..1.
-- @treturn number h Hue (0..1)
-- @treturn number s Saturation (0..1)
-- @treturn number l Lightness (0..1)
local function rgbToHsl (color)
  local r, g, b = color.r, color.g, color.b
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s
  local l = (max + min) / 2

  if min == max then
    -- achromatic
    h = 0
    s = 0
  else
    local d = max - min
    s = l > 0.5 and (d / (2 - max - min)) or (d / (max + min))
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    else -- max == b
      h = (r - g) / d + 4
    end
    h = h / 6
  end
  return h, s, l
end

--- Helper for Hue to RGB conversion, used in HSL to RGB conversion.
local function hue2rgb (p, q, t)
  if t < 0 then t = t + 1 end
  if t > 1 then t = t - 1 end
  if t < 1/6 then return p + (q - p) * 6 * t end
  if t < 1/2 then return q end
  if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
  return p
end

--- Converts HSL (Hue, Saturation, Lightness) to RGB (Red, Green, Blue) to RGB (Red, Green, Blue).
-- @tparam number h Hue (0..1)
-- @tparam number s Saturation (0..1)
-- @tparam number l Lightness (0..1)
-- @treturn table   Table with RGB values (r, g, b) in the range 0..1
local function hslToRgb (h, s, l)
  local r, g, b;

  if s == 0 then
    -- achromatic
    r = l
    g = l
    b = l
  else
    local q = (l < 0.5) and (l * (1 + s)) or (l + s - l * s)
    local p = 2 * l - q
    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end
  return { r = r, g = g, b = b }
end

-- Converts a color to HSL (Hue, Saturation, Lightness) values.
-- @treturn number h Hue (0..1)
-- @treturn number s Saturation (0..1)
-- @treturn number l Lightness (0..1)
function Color:toHsl ()
  if self.r then
    return rgbToHsl(self)
  end
  if self.k then
    -- First convert CMYK to RGB
    local kr = (1 - self.k)
    return rgbToHsl({
      r = (1 - self.c) * kr,
      g = (1 - self.m) * kr,
      b = (1 - self.y) * kr,
    })
  end
  if self.l then
    -- First convert Grayscale to RGB
    return rgbToHsl({
      r = self.l,
      g = self.l,
      b = self.l,
    })
  end
  SU.error("Invalid color specification")
end

--- Static method to create a Color object from HSL values
-- @tparam number h Hue (0..1)
-- @tparam number s Saturation (0..1)
-- @tparam number l Lightness (0..1)
-- @treturn Color A new Color object
function Color.fromHsl (h, s, l)
  return Color(hslToRgb(h, s, l))
end

return Color
