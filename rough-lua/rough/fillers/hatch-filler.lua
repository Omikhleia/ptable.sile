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

local HatchFiller = pl.class(HachureFiller)

function HatchFiller:fillPolygons (polygonList, o)
  local set = self._base.fillPolygons(self, polygonList, o)
  local o2 = pl.tablex.copy(o)
  o2.hachureAngle = o.hachureAngle + 90
  local set2 = self._base.fillPolygons(self, polygonList, o2)
  pl.tablex.insertvalues(set.ops, set2.ops)
  return set
end

return {
  HatchFiller = HatchFiller
}
