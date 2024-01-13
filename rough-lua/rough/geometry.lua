--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
local function lineLength (line)
  local p1 = line[1]
  local p2 = line[2]
  return math.sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)
end

return {
  lineLength = lineLength
}
