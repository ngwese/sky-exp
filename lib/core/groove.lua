
local cycle = function(list)
  local next = function(a, i)
    i = i + 1
    local v = a[i]
    if v == nil then
      i = 1
      v = a[i]
    end
    --print(i, v)
    return i, v
  end
  return next, list, 0
end

local Groove = {}
Groove.__index = Groove

function Groove.new(o)
  local o = setmetatable(o, Groove)
  return o
end

function Groove.straight(steps)
  local t = {}
  local dt = 1 / (steps - 1)
  for i = 0, 1, dt do
    table.insert(t, dt)
  end
  return Groove.new(t)
end

function Groove.normalize(timings)
  local t = {}
  local max = timings[#timings]
  local range = max - timings[1]
  for i, n in ipairs(timings) do
    table.insert(t, n / range)
  end
  return Groove.new(t)
end

function Groove:iter()
  return ipairs(self)
end

function Groove:cycle()
  return cycle(self)
end

return {
  Groove = Groove,
  cycle = cycle,
}