--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the rough.js JavaScript library.
-- (https://github.com/rough-stuff/rough)
-- License MIT
-- Copyright (c) 2019 Preet Shihn
--
-- https://github.com/pshihn/hachure-fill
-- MIT License
-- Copyright (c) 2023 Preet Shihn
--

local jsshims = require("rough-lua.rough.jsshims")
local array_splice = jsshims.array_splice
local math_round = jsshims.math_round

local rotatePoints = function (points, center, degrees)
  if points and #points > 0 then
    local cx, cy = center[1], center[2]
    local angle = (math.pi / 180) * degrees
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    for _, p in ipairs(points) do
      local x, y = p[1], p[2]
      p[1] = ((x - cx) * cos) - ((y - cy) * sin) + cx
      p[2] = ((x - cx) * sin) + ((y - cy) * cos) + cy
    end
  end
end

local function rotateLines (lines, center, degrees)
  local points = {}
  for _, line in ipairs(lines) do
    for _, p in ipairs(line) do
      points[#points + 1] = p
    end
  end
  rotatePoints(points, center, degrees)
end

local function areSamePoints(p1, p2)
  return p1[1] == p2[1] and p1[2] == p2[2]
end

local function straightHachureLines (polygons, gap, hachureStepOffset)
  local vertexArray = {}
  for _, polygon in ipairs(polygons) do
    local vertices = polygon
    if not areSamePoints(vertices[1], vertices[#vertices]) then
      vertices[#vertices + 1] = { vertices[1][1], vertices[1][2] }
    end
    if #vertices > 2 then
      vertexArray[#vertexArray + 1] = vertices
    end
  end

  local lines = {}
  gap = math.max(gap, 0.1)

  -- Create sorted edges table
  local edges = {}

  for _, vertices in ipairs(vertexArray) do
    for i = 1, #vertices - 1 do
      local p1 = vertices[i]
      local p2 = vertices[i + 1]
      if p1[2] ~= p2[2] then
        local ymin = math.min(p1[2], p2[2])
        edges[#edges + 1] = {
          ymin = ymin,
          ymax = math.max(p1[2], p2[2]),
          x = (ymin == p1[2]) and p1[1] or p2[1],
          islope = (p2[1] - p1[1]) / (p2[2] - p1[2]),
        }
      end
    end
  end

  local f = function (e1, e2)
    if e1.ymin < e2.ymin then
      return true
    end
    if e1.ymin > e2.ymin then
      return false
    end
    if e1.x < e2.x then
      return true
    end
    if e1.x > e2.x then
      return false
    end
    if (e1.ymax < e2.ymax) then
      return true
    end
    -- PORTING NOTE:
    -- Lua sorting differs from JS
    -- Not so sure about the correctness here!
    return false
  end
  table.sort(edges, f)
  if #edges == 0 then
    return lines
  end

  -- Start scanning
  local activeEdges = {}
  local y = edges[1].ymin
  local iteration = 0
  while #activeEdges > 0 or #edges > 0 do
    if #edges > 0 then
      local ix = -1
      for i = 1, #edges do
        if edges[i].ymin > y then
          break
        end
        ix = i
      end
      local removed
      edges, removed = array_splice(edges, 1, ix)
      for _, edge in ipairs(removed) do
        activeEdges[#activeEdges + 1] = { s = y, edge = edge }
      end
    end
    activeEdges = pl.tablex.filter(activeEdges, function (ae)
      if ae.edge.ymax <= y then
        return false
      end
      return true
    end)
    table.sort(activeEdges, function (ae1, ae2)
      if ae1.edge.x < ae2.edge.x then
        return true
      end
      return false
    end)

    -- fill between the edges
    if (hachureStepOffset ~= 1) or (iteration % gap == 0) then
      if #activeEdges > 1 then
        for i = 1, #activeEdges, 2 do
          local nexti = i + 1
          if nexti > #activeEdges then
            break
          end
          local ce = activeEdges[i].edge
          local ne = activeEdges[nexti].edge
          lines[#lines + 1] = {
            { math_round(ce.x), y },
            { math_round(ne.x), y },
          }
        end
      end
    end
    y = y + hachureStepOffset
    for _, ae in ipairs(activeEdges) do
      ae.edge.x = ae.edge.x + (hachureStepOffset * ae.edge.islope)
    end
    iteration = iteration + 1
  end
  return lines
end

local function hachureLines (polygons, hachureGap, hachureAngle, hachureStepOffset)
  local angle = hachureAngle
  local gap = math.max(hachureGap, 0.1)
  local polygonList = (polygons[1] and polygons[1][1] and type(polygons[1][1]) == 'number') and { polygons } or polygons
  local rotationCenter = { 0, 0 }
  if angle then
    for _, polygon in ipairs(polygonList) do
      rotatePoints(polygon, rotationCenter, angle)
    end
  end
  local lines = straightHachureLines(polygonList, gap, hachureStepOffset)
  if angle then
    for _, polygon in ipairs(polygonList) do
      rotatePoints(polygon, rotationCenter, -angle)
    end
    rotateLines(lines, rotationCenter, -angle)
  end
  return lines
end

return {
  hachureLines = hachureLines,
}
