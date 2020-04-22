
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
  o.show_beats = props.show_beats or false
  o.filter = props.filter or function(...) return false end
  return o
end

function Logger:process(event, output, state)
  if not self.bypass then
    local c = state.process_count
    if not self.filter(event) then
      if self.show_beats then
        print(c, clock.get_beats(), sky.to_string(event))
      else
        print(c, sky.to_string(event))
      end
    end
  end
  -- always output incoming event
  output(event)
end

--
-- Map
--

local Map = {}
Map.__index = Map

function Map.new(props)
  local o = setmetatable(props, Map)
  o.match = props.match or function(e) return false end
  o.action = props.action or function(e) return e end
  return o
end

function Map:process(event, output, state)
  if self.match(event) then
    output(self.action(event))
  else
    output(event)
  end
end

--
-- module
--
return {
  Func = Func.new,
  Thru = Thru.new,
  Logger = Logger.new,
  Map = Map.new,
}
