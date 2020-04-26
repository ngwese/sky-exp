local math = require('math')
require('asl')

local WatchTable = include('sky/lib/container/watchtable')

--
-- CrowVoice
--
local CrowVoice = sky.Device()
CrowVoice.__index = CrowVoice

function CrowVoice.new(props)
  local o = setmetatable(props, CrowVoice)
  -- crow.connected() always returns false?
  o:_clear()
  o.held = 0
  return o
end

function CrowVoice:_clear()
  crow.clear()
  -- pitch
  crow.output[1].volts = 0
  crow.output[1].slew = 0
  -- trigger
  --crow.output[2].action = pulse(0.1, 9, 1)
  crow.output[3].shape = 'exp'
  crow.output[3].slew = 0.4
  crow.output[4].action = lfo(1, 5)
  crow.output[4]()
end

function CrowVoice:process(event, output, state)

  if sky.is_type(event, sky.types.NOTE_ON) then
    crow.output[1].volts = (event.note / 12) - 4
    --crow.output[1]()
    crow.output[2].volts = 5
    crow.output[3].volts = (event.note / 127) * 3
    self.held = self.held + 1
  elseif sky.is_type(event, sky.types.NOTE_OFF) then
    self.held = self.held - 1
    if self.held < 1 then
      crow.output[2].volts = 0
    end
  end
  output(event)
end

local Watch

--
-- CrowShape
--

local CrowShape = sky.Device()
CrowShape.__index = CrowShape

function CrowShape.new(shapes)
  local o = {}
  o._shapes = shapes
  setmetatable(o, CrowShape)
  o:_clear()
  return o
end

function CrowShape:_clear()
  crow.clear()
  for i = 1, 4 do
    crow.output[i].action = self[i]
  end
end

function CrowShape:__index(k)
  if type(k) == 'number' and k >= 1 and k <= 4 then
    return self._shapes[k]
  end
  return rawget(CrowShape, k)
end

function CrowShape:__newindex(k, v)
  if type(k) == 'number' and k >= 1 and k <= 4 then
    self._shapes[k] = v
    crow.output[k].action = v
  end
  rawget(self, k, v)
end

function CrowShape:process(event, output, state)
  if sky.is_type(event, sky.types.TRIGGER) then
    crow.output[event.which]()
  end
  output(event)
end


return {
  CrowVoice = CrowVoice.new,
  CrowShape = CrowShape.new,
}




