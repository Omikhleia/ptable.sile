--- Adapter for Grail color compatibility with SILE
local color
if SILE then
  color = SILE.types.color
else
  -- Minimal reimplementation of the SILE color class
  -- to be used in Grail when SILE is not available.
  -- We don't reimplement the named colors, only the RGB/CMYK/Gray internal representation.
  color = pl.class({
    type = "color",
    r = nil,
    g = nil,
    b = nil,
    c = nil,
    m = nil,
    y = nil,
    k = nil,
    l = nil,
  })

  function color:_init (input)
    local c = type(input) == "string" and self:parse(input) or input
    for k, v in pairs(c) do
       self[k] = v
    end
    return self
  end

  function color.parse (_, input)
    local r, g, b, c, m, y, k, l
    if not input or type(input) ~= "string" then
      SU.error("Not a color specification string (" .. tostring(input) .. ")")
    end
    r, g, b = input:match("^#(%x%x)(%x%x)(%x%x)$")
    if r then
      return { r = tonumber("0x" .. r) / 255, g = tonumber("0x" .. g) / 255, b = tonumber("0x" .. b) / 255 }
    end
    r, g, b = input:match("^#(%x)(%x)(%x)$")
    if r then
      return { r = tonumber("0x" .. r) / 15, g = tonumber("0x" .. g) / 15, b = tonumber("0x" .. b) / 15 }
    end
    c, m, y, k = input:match("^(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)$")
    if c then
      return { c = tonumber(c) / 255, m = tonumber(m) / 255, y = tonumber(y) / 255, k = tonumber(k) / 255 }
    end
    c, m, y, k = input:match("^(%d+%.?%d*)%%%s+(%d+%.?%d*)%%%s+(%d+%.?%d*)%%%s+(%d+%.?%d*)%%$")
    if c then
      return { c = tonumber(c) / 100, m = tonumber(m) / 100, y = tonumber(y) / 100, k = tonumber(k) / 100 }
    end
    r, g, b = input:match("^(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)$")
    if r then
      return { r = tonumber(r) / 255, g = tonumber(g) / 255, b = tonumber(b) / 255 }
    end
    r, g, b = input:match("^(%d+%.?%d*)%%%s+(%d+%.?%d*)%%%s+(%d+%.?%d*)%%$")
    if r then
      return { r = tonumber(r) / 100, g = tonumber(g) / 100, b = tonumber(b) / 100 }
    end
    l = input:match("^(%d+.?%d*)$")
    if l then
      return { l = tonumber(l) / 255 }
    end
    SU.error("Unparsable color " .. input)
  end
end

return color
