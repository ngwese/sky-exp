-- midi helper module
-- @module process
-- @alias process

local Deque = sky.use('sky/lib/container/deque')

--
-- Input class (event source)
--
local Input = {}
Input.__index = Input

function Input.new(o)
  local o = setmetatable(o or {}, Input)

  -- determine which device to use
  if not o.device then
    if o.name then
      -- attempt to find the midi device by name
      for i,v in ipairs(midi.vports) do
        if sky.starts_with(v.name, o.name) then
          o.device = midi.connect(i)
        end
      end
    else
      o.device = midi.connect(1)
    end
  end

  -- set defaults
  --o.device = o.device or midi.connect(1)
  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  if o.device == nil then
    local n = o.name or "<none>"
    print("warning: input not connected to device " .. n)
    return o
  end

  -- install device event handler
  o.device.event = function(data)
    o:on_midi_event(data)
  end

  return o
end

function Input:on_midi_event(data)
  if not self.enabled or self.chain == nil then
    -- nothing to do
    return
  end

  local event = midi.to_msg(data)
  if event ~= nil then
    self.chain:process(event)
  end
end


-- allow this input to invoke callbacks
function Input:enable()
  self.enabled = true
end

-- temporarily stop this input from invoking callbacks
function Input:disable()
  self.enabled = false
end

-- perminantly remove this input from receiving further events
function Input:cleanup()
  self:disable()
  if self.device and self.device.cleanup then
    self.device:cleanup()
  end
end

--
-- Output class (event sink)
--
local Output = {}
Output.__index = Output

function Output.new(o)
  local o = setmetatable(o or {}, Output)

  -- determine which device to use
  if not o.device then
    if o.name then
      -- attempt to find the midi device by name
      for i,v in ipairs(midi.vports) do
        if sky.starts_with(v.name, o.name) then
          o.device = midi.connect(i)
        end
      end
    else
      o.device = midi.connect(2)
    end
  end

  if o.device == nil then
    local n = o.name or "<none>"
    print("warning: output not connected to device " .. n)
  end

  if type(o.enabled) ~= "boolean" then
    o.enabled = true
  end

  return o
end

function Output:process(event, output)
  local t = event.type
  if self.enabled and self.device and (t ~= nil) then
    -- filter out non-midi events
    if sky.type_names[t] ~= nil then
      self.device:send(event)
    end
  end

  -- pass events on
  output(event)
end

--
-- Chain class
--
local Chain = {}
Chain.__index = Chain

function Chain.new(devices)
  local o = setmetatable({}, Chain)
  o.bypass = false
  o.devices = devices or {}

  -- rip through devices and if there are functions wrap them in a
  -- generic processor object which supports bypass etc.
  for i, d in ipairs(o.devices) do
    if type(d) == 'function' then
      o.devices[i] = sky.Func(d)
    end
  end

  o._state = { process_count = 0 }
  o._buffers = { Deque.new(), Deque.new() }
  return o
end

function Chain:init()
  self:process(sky.mk_script_init())
end

function Chain:redraw()
  self:process(sky.mk_script_redraw())
end

function Chain:cleanup()
  self:process(sky.mk_script_cleanup())
end

function Chain:process(event)
  if self.bypass then
    return
  end

  local state = self._state
  state.process_count = state.process_count + 1

  local source = self._buffers[1]
  local sink = self._buffers[2]

  return self._process(event, state, self.devices, source, sink)
end

function Chain._process(event, state, devices, source, sink)
  source:clear()
  sink:clear()

  local output = function(event)
    sink:push_back(event)
  end

  -- populate the source event queue with the event to process
  source:push_back(event)

  for i, processor in ipairs(devices) do
    event = source:pop()
    while event do
      -- print("\ndevice:", i, "event:", event, "processor:", processor)
      processor:process(event, output, state)
      event = source:pop()
      -- print("sink c:", sink:count())
    end

    -- swap input/output buffers
    local t = source
    source = sink
    sink = t

    -- event = source:pop()
    if source:count() == 0 then
      -- no more events to process, end chain processing early
      -- print("breaking out of process loop")
      break
    end
  end

  -- return output buffer of last processor
  return source
end

function Chain:run(events)
  local output = Deque.new()
  for i, ein in ipairs(events) do
    local r = self:process(ein)
    if r ~= nil then
      -- flatten output
      output:extend_back(r)
    end
  end
  return output:to_array()
end

--
-- Group
--
local Group = {}
Group.__index = Group

function Group.new(props)
  local o = setmetatable({}, Group)
  o.bypass = props.bypass or false
  o.source = Deque.new()
  o.sink = Deque.new()
  o.devices = {}
  for _, v in ipairs(props) do
    table.insert(o.devices, v)
  end
  return o
end

function Group:process(event, output, state)
  if self.bypass then
    output(event)
  else
    -- process children in the same manner as a chain then output all the results
    local results = Chain._process(event, state, self.devices, self.source, self.sink)
    for _, v in results:ipairs() do
      output(v)
    end
  end
end

--
-- module
--

return {
  -- objects
  Input = Input.new,
  Output = Output.new,
  Chain = Chain.new,
  Group = Group.new,

  -- debug
  __input_count = input_count,
  __inputs = inputs,
}
