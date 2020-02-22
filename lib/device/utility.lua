
--
-- Func class
--
local Func = {}
Func.__index = Func

function Func.new(f)
  local o = setmetatable({}, Func)
  o.f = f
  o.bypass = false
  return o
end

function Func:process(event, output, state)
  if self.bypass then
    output(event)
  else
    self.f(event, output, state)
  end
end


--
-- Thru class
--
local Thru = {}
Thru.__index = Thru

function Thru.new()
  local o = setmetatable({}, Thru)
  o.bypass = false
  return o
end

function Thru:process(event, output)
  if not self.bypass then
    output(event)
  end
end

--
-- Logger
--
local tu = require('tabutil')

local Logger = {}
Logger.__index = Logger

function Logger.new(props)
  local o = setmetatable(props, Logger)
  o.bypass = props.bypass or false
  return o
end

function Logger:process(event, output, state)
  if not self.bypass then
    local c = state.process_count
    if self.filter then
      if not self.filter(event) then
        print(c, sky.to_string(event))
      end
    else
      print(c, sky.to_string(event))
    end
  end
  -- always output incoming event
  output(event)
end

return {
  Func = Func.new,
  Thru = Thru.new,
  Logger = Logger.new,
}
