--
-- HACK/WORKAROUND FOR HBOX BUILDING LOGIC
-- THIS FILE WILL EVENTUALLY BE REMOVED, DO NOT DEPEND ON IT!
-- See SILE PR https://github.com/sile-typesetter/sile/pull/1702
-- It made it in SILE 0.14.9 but I had a few other packages depending on
-- this compatibility shim, so I'm keeping it for now.
-- We added it here early to fix migrating content issues:
--   https://github.com/Omikhleia/ptable.sile/issues/2
--
-- License: MIT
--

-- Logic for building an hbox from content.
-- It returns the hbox and an horizontal list of (migrating) elements
-- extracted outside of it.
-- None of these are pushed to the typesetter node queue. The caller
-- is responsible of doing it, if the hbox is built for anything
-- else than e.g. measuring it. Likewise, the call has to decide
-- what to do with the migrating content.
local _rtl_pre_post = function (box, atypesetter, line)
  local advance = function () atypesetter.frame:advanceWritingDirection(box:scaledWidth(line)) end
  if atypesetter.frame:writingDirection() == "RTL" then
    advance()
    return function () end
  else
    return advance
  end
end
local function makeHbox (content)
  local SELF = SILE.typesetter
  local recentContribution = {}
  local migratingNodes = {}

  -- HACK HBOX
  -- This is from the original implementation.
  -- It would be somewhat cleaner to use a temporary typesetter state
  -- (pushState/popState) rather than using the current one, removing
  -- the processed nodes from it afterwards. However, as long
  -- as leaving horizontal mode is not strictly forbidden here, it would
  -- lead to a possibly different result (the output queue being skipped).
  local index = #(SELF.state.nodes)+1
  SELF.state.hmodeOnly = true
  SILE.process(content)
  SELF.state.hmodeOnly = false -- Wouldn't be needed in a temporary state

  local l = SILE.length()
  local h, d = SILE.length(), SILE.length()
  for i = index, #(SELF.state.nodes) do
    local node = SELF.state.nodes[i]
    if node.is_migrating then
      migratingNodes[#migratingNodes+1] = node
    elseif node.is_unshaped then
      local shape = node:shape()
      for _, attr in ipairs(shape) do
        recentContribution[#recentContribution+1] = attr
        h = attr.height > h and attr.height or h
        d = attr.depth > d and attr.depth or d
        l = l + attr:lineContribution():absolute()
      end
    else
      recentContribution[#recentContribution+1] = node
      l = l + node:lineContribution():absolute()
      h = node.height > h and node.height or h
      d = node.depth > d and node.depth or d
    end
    SELF.state.nodes[i] = nil -- wouldn't be needed in a temporary state
  end

  local hbox = SILE.nodefactory.hbox({
      height = h,
      width = l,
      depth = d,
      value = recentContribution,
      outputYourself = function (box, atypesetter, line)
        local _post = _rtl_pre_post(box, atypesetter, line)
        local ox = atypesetter.frame.state.cursorX
        local oy = atypesetter.frame.state.cursorY
        SILE.outputter:setCursor(atypesetter.frame.state.cursorX, atypesetter.frame.state.cursorY)
        for _, node in ipairs(box.value) do
          node:outputYourself(atypesetter, line)
        end
        atypesetter.frame.state.cursorX = ox
        atypesetter.frame.state.cursorY = oy
        _post()
        SU.debug("hboxes", function ()
          SILE.outputter:debugHbox(box, box:scaledWidth(line))
          return "Drew debug outline around hbox"
        end)
      end
    })
  return hbox, migratingNodes
end

local function pushHlist (hlist)
  local SELF = SILE.typesetter
  for _, h in ipairs(hlist) do
    SELF:pushHorizontal(h)
  end
end

return {
  makeHbox = makeHbox,
  pushHlist = pushHlist
}
