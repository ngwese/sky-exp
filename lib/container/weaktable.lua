-- weaktable - a table with weakly held keys and values
-- @module weaktable
-- @alias WeakTable

local WeakTable = {}
WeakTable.__index = WeakTable
WeakTable.__mode = "kv"  --  invoke dark magic: https://www.lua.org/pil/17.html

--- Create a table with weak keys and values
--
-- A table with weakly held keys and values allows objects to be added to a
-- table but it won't prevent those objects from being garbage collected
--
-- @tparam table initial Initial table contents, optional.
-- @treturn table
function WeakTable.new(t)
  local t = setmetatable(t or {}, WeakTable)
  return t
end

return WeakTable
