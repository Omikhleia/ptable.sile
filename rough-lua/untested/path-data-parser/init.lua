--
-- License: MIT
-- Copyright (c) 2023, Didier Willis
--
-- This is a straightforward port of the path-data-parser JavaScript library.
-- (https://github.com/pshihn/path-data-parser/)
-- License: MIT
-- Copyright (c) 2019 Preet Shihn
--
local normalize = require("rough-lua.untested.path-data-parser.normalize").normalize
local absolutize = require("rough-lua.untested.path-data-parser.absolutize").absolutize
local parsePath = require("rough-lua.untested.path-data-parser.parser").parsePath
local serialize = require("rough-lua.untested.path-data-parser.parser").serialize

return {
  parsePath = parsePath,
  serialize = serialize,
  absolutize = absolutize,
  normalize = normalize,
}
