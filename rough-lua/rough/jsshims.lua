--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- Some convenience JavaScript-like functions to make the porting easier.
-- (So the code looks more like the original JavaScript code.)
--
--

-- JS Math.round
local function math_round (x)
  return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

-- JS Array.splice
local function array_splice (t, start, length) -- from xlua
  length = length or 1
  start = start or 1
  local ending = start + length
  local spliced = {}
  local remainder = {}
  for i, item in ipairs(t) do
    if i < start or i >= ending then
      table.insert(spliced, item)
    else
      table.insert(remainder, item)
    end
  end
  return spliced, remainder
end

-- JS Array.code
local function array_concat (t1, t2)
  local t = {}
  pl.tablex.insertvalues(t, t1)
  pl.tablex.insertvalues(t, t2)
  return t
end

return {
  math_round = math_round,
  array_splice = array_splice,
  array_concat = array_concat,
}
