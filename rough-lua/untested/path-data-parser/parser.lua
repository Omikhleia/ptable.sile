--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the path-data-parser JavaScript library.
-- (https://github.com/pshihn/path-data-parser/)
-- License: MIT
-- Copyright (c) 2019 Preet Shihn
--
local COMMAND = 0
local NUMBER = 1
local EOD = 2

local PARAMS = {
  A = 7,
  a = 7,
  C = 6,
  c = 6,
  H = 1,
  h = 1,
  L = 2,
  l = 2,
  M = 2,
  m = 2,
  Q = 4,
  q = 4,
  S = 4,
  s = 4,
  T = 2,
  t = 2,
  V = 1,
  v = 1,
  Z = 0,
  z = 0,
}

local function tokenize (d)
  local tokens = {}
  while d ~= '' do
    local i, j = d:find("^[ \t\r\n,]+")
    if i then
      d = d:sub(j + 1)
    else
      i, j = d:find("^[aAcChHlLmMqQsStTvVzZ]")
      if i then
        tokens[#tokens + 1] = { type = COMMAND, text = d:sub(i, j) }
        d = d:sub(j + 1)
      else
        i, j = d:find("^[+-]?%.?[0-9]+%.?[eE0-9]*")
          -- PORTING NOTE:
          -- JS has "^(([-+]?[0-9]+(\.[0-9]*)?|[-+]?^.[0-9]+)([eE][-+]?[0-9]+)?)")
          -- Lua does not support such complex regexps, so we use a simpler one
          -- but it will not catch some malformed numbers.
        if i then
          tokens[#tokens + 1] = { type = NUMBER, text = tostring(tonumber(d:sub(i, j))) }
          d = d:sub(j + 1)
        else
          return {}
        end
      end
    end
  end
  tokens[#tokens + 1] = { type = EOD, text = '' }
  return tokens
end

local function isType (token, type)
  return token.type == type
end

local function parsePath (d)
  local segments = {}
  local tokens = tokenize(d)
  local mode = 'BOD'
  local index = 1
  local token = tokens[index]
  while not isType(token, EOD) do
    local paramsCount
    local params = {}
    if mode == 'BOD' then
      if token.text == 'M' or token.text == 'm' then
        index = index + 1
        paramsCount = PARAMS[token.text]
        mode = token.text
      else
        return parsePath('M0,0' .. d)
      end
    elseif isType(token, NUMBER) then
      paramsCount = PARAMS[mode]
    else
      index = index + 1
      paramsCount = PARAMS[token.text]
      mode = token.text
    end
    if (index + paramsCount) <= #tokens then
      for i = index, index + paramsCount - 1 do
        local numbeToken = tokens[i]
        if isType(numbeToken, NUMBER) then
          params[#params + 1] = tonumber(numbeToken.text)
        else
          error('Param not a number: ' .. mode .. ',' .. numbeToken.text)
        end
      end
      if type(PARAMS[mode]) == 'number' then
        local segment = { key = mode, data = params }
        segments[#segments + 1] = segment
        index = index + paramsCount
        token = tokens[index]
        if mode == 'M' then
          mode = 'L'
        end
        if mode == 'm' then
          mode = 'l'
        end
      else
        error('Bad segment: ' .. mode)
      end
    else
      error('Path data ended short')
    end
  end
  return segments
end

local function serialize (segments)
  local tokens = {}
  for _, segment in ipairs(segments) do
    tokens[#tokens + 1] = segment.key
    if segment.key == 'C' or segment.key == 'c' then
      tokens[#tokens + 1] = segment.data[1]
      tokens[#tokens + 1] = tostring(segment.data[2]) .. ','
      tokens[#tokens + 1] = segment.data[3]
      tokens[#tokens + 1] = tostring(segment.data[4]) .. ','
      tokens[#tokens + 1] = segment.data[5]
      tokens[#tokens + 1] = segment.data[6]
    elseif segment.key == 'S' or segment.key == 's'
        or segment.key == 'Q' or segment.key == 'q' then
      tokens[#tokens + 1] = segment.data[1]
      tokens[#tokens + 1] = tostring(segment.data[2]) .. ','
      tokens[#tokens + 1] = segment.data[3]
      tokens[#tokens + 1] = segment.data[4]
    else
      pl.tablex.insertvalues(tokens, segment.data)
    end
  end
  return table.concat(tokens, ' ')
end

return {
  parsePath = parsePath,
  serialize = serialize,
}