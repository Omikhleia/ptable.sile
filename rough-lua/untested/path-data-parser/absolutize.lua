--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the path-data-parser JavaScript library.
-- (https://github.com/pshihn/path-data-parser/)
-- License: MIT
-- Copyright (c) 2019 Preet Shihn
--
local function absolutize(segments)
  local cx, cy = 0, 0
  local subx, suby = 0, 0
  local out = {}
  for _, segment in ipairs(segments) do
    local key, data = segment.key, segment.data
    if key == 'M' then
      out[#out + 1] = { key = 'M', data = pl.tablex.copy(data) }
      cx, cy = data[1], data[2]
      subx, suby = data[1], data[2]
    elseif key == 'm' then
      cx = cx + data[1]
      cy = cy + data[2]
      out[#out + 1] = { key = 'M', data = { cx, cy } }
      subx, suby = cx, cy
    elseif key == 'L' then
      out[#out + 1] = { key = 'L', data = pl.tablex.copy(data) }
      cx, cy = data[1], data[2]
    elseif key == 'l' then
      cx = cx + data[1]
      cy = cy + data[2]
      out[#out + 1] = { key = 'L', data = { cx, cy } }
    elseif key == 'C' then
      out[#out + 1] = { key = 'C', data = pl.tablex.copy(data) }
      cx, cy = data[5], data[6]
    elseif key == 'c' then
      local newdata = pl.tablex.map(data, function (d, i)
        return (i % 2) == 0 and (d + cx) or (d + cy)
      end)
      out[#out + 1] = { key = 'C', data = newdata }
      cx, cy = newdata[5], newdata[6]
    elseif key == 'Q' then
      out[#out + 1] = { key = 'Q', data = pl.tablex.copy(data) }
      cx, cy = data[2], data[3]
    elseif key == 'q' then
      local newdata = pl.tablex.map(data, function (d, i)
        return (i % 2) == 0 and (d + cx) or (d + cy)
      end)
      out[#out + 1] = { key = 'Q', data = newdata }
      cx, cy = newdata[2], newdata[3]
    elseif key == 'A' then
      out[#out + 1] = { key = 'A', data = pl.tablex.copy(data) }
      cx, cy = data[5], data[6]
    elseif key == 'a' then
      cx = cx + data[5]
      cy = cy + data[6]
      out[#out + 1] = { key = 'A', data = { data[1], data[2], data[3], data[4], data[5], cx, cy } }
    elseif key == 'H' then
      out[#out + 1] = { key = 'H', data = pl.tablex.copy(data) }
      cx = data[1]
    elseif key == 'h' then
      cx = cx + data[1]
      out[#out + 1] = { key = 'H', data = { cx } }
    elseif key == 'V' then
      out[#out + 1] = { key = 'V', data = pl.tablex.copy(data) }
      cy = data[1]
    elseif key == 'v' then
      cy = cy + data[1]
      out[#out + 1] = { key = 'V', data = { cy } }
    elseif key == 'S' then
      out[#out + 1] = { key = 'S', data = pl.tablex.copy(data) }
      cx, cy = data[2], data[3]
    elseif key == 's' then
      local newdata = pl.tablex.map(data, function (d, i)
        return (i % 2) == 0 and (d + cx) or (d + cy)
      end)
      out[#out + 1] = { key = 'S', data = newdata }
      cx, cy = newdata[2], newdata[3]
    elseif key == 'T' then
      out[#out + 1] = { key = 'T', data = pl.tablex.copy(data) }
      cx, cy = data[1], data[2]
    elseif key == 't' then
      cx = cx + data[1]
      cy = cy + data[2]
      out[#out + 1] = { key = 'T', data = { cx, cy } }
    elseif key == 'Z' or key == 'z' then
      out[#out + 1] = { key = 'Z', data = {} }
      cx, cy = subx, suby
    end
  end
  return out
end

return {
  absolutize = absolutize,
}
