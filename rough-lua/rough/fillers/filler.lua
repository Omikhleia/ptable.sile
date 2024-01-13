--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
local HachureFiller = require("rough-lua.rough.fillers.hachure-filler").HachureFiller
local ZigZagFiller = require("rough-lua.rough.fillers.zigzag-filler").ZigZagFiller
local HatchFiller = require("rough-lua.rough.fillers.hatch-filler").HatchFiller
local DotFiller = require("rough-lua.rough.fillers.dot-filler").DotFiller
local DashedFiller = require("rough-lua.rough.fillers.dashed-filler").DashedFiller
local ZigZagLineFiller = require("rough-lua.rough.fillers.zigzag-line-filler").ZigZagLineFiller

local fillers = {}

local function getFiller (o, helper)
  local fillerName = o.fillStyle or 'hachure'
  if not fillers[fillerName] then
    if fillerName == 'zigzag' then
      fillers[fillerName] = ZigZagFiller(helper)
    elseif fillerName == 'cross-hatch' then
      fillers[fillerName] = HatchFiller(helper)
    elseif fillerName == 'dots' then
      fillers[fillerName] = DotFiller(helper)
    elseif fillerName == 'dashed' then
      fillers[fillerName] = DashedFiller(helper)
    elseif fillerName == 'zigzag-line' then
      fillers[fillerName] = ZigZagLineFiller(helper)
    else
      fillerName = 'hachure'
      fillers[fillerName] = HachureFiller(helper)
    end
  end
  return fillers[fillerName]
end

return {
  getFiller = getFiller,
}
