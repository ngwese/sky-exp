
-- reference: https://en.wikipedia.org/wiki/Swing_(jazz_performance_style)
local Swing = {}
Swing.__index = Swing

function Swing.new(o)
  local o = setmetatable(o, Groove)
  o.range = o.range or 1/4
  o.amount = o.amount or 0
  return o
end


local Groove = {}
Groove.__index = Groove

function Groove.new(o)
  local o = setmetatable(o, Groove)
  return o
end

function Groove.straight(steps)
  local t = {}
  local dt = 1 / steps
  for i = 1, steps - 1 do
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

return {
  Groove = Groove,
  Swing = Swing,
}