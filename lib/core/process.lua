-- midi helper module
-- @module process
-- @alias process

local Deque = sky.use('sky/lib/container/deque')

--
-- Device class
--
local Device = {}
Device.__index = Device

function Device.new(props)
  local o = setmetatable(props or {}, Device)
  o.bypass = o.bypass or false
  return o
end

function Device:device_inserted(chain)
  -- nothing to do
end

function Device:device_removed(chain)
  -- nothing to do
end

function Device:process(event, output, state)
  if self.bypass then return end
  output(event)
end

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
local Output = Device.new()
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
-- Scheduler (of chain device callback events)
--

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(chain, device_index)
  local o = setmetatable({}, Scheduler)
  o.chain = chain
  o.device_index = device_index
  o.clock_pool = Deque.new()
  o.clock_id = nil
  return o
end

local _scheduler_coro = function(self, when, event, method)
  method(when)
  self.chain:process(event, self.device_index)
end

function Scheduler:sync(when, event)
  clock.run(_scheduler_coro, self, when, event, clock.sync)
end

function Scheduler:sleep(when, event)
  clock.run(_scheduler_coro, self, when, event, clock.sleep)
end

function Scheduler:now(event)
  self.chain:process(event, self.device_index)
end

function Scheduler:run(coro, ...)
  self:cancel()
  local output = function(event)
    self.chain:process(event, self.device_index)
  end
  self.clock_id = clock.run(coro, output)
end

function Scheduler:cancel()
  if self.clock_id ~= nil then
    clock.cancel(self.clock_id)
    self.clock_id = nil
  end
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

  o._state = { process_count = 0 }
  o._buffers = { Deque.new(), Deque.new() }
  o._schedulers = {}

  -- rip through devices and if there are functions wrap them in a
  -- generic processor object which supports bypass etc.
  for i, d in ipairs(o.devices) do
    if type(d) == 'function' then
      d = sky.Func(d)
      o.devices[i] = d
    end
    -- handle insertion callback
    d:device_inserted(o)
  end

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

function Chain:process(event, from_device)
  -- print('chain:process', sky.to_string(event), from_device)
  if self.bypass then
    return
  end

  local state = self._state
  state.process_count = state.process_count + 1

  local source = self._buffers[1]
  local sink = self._buffers[2]

  return self._process(event, state, self.devices, source, sink, from_device)
end

local function ipairs_from(tbl, start)
  local iter = function(tbl, i)
    i = i + 1
    local v = tbl[i]
    if v ~= nil then return i, v end
  end
  local initial = 0
  if start then initial = start - 1 end
  return iter, tbl, initial
end

function Chain._process(event, state, devices, source, sink, from_device)
  source:clear()
  sink:clear()

  local output = function(event)
    sink:push_back(event)
  end

  -- populate the source event queue with the event to process
  source:push_back(event)

  for i, processor in ipairs_from(devices, from_device) do

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

function Chain:scheduler(device)
  local s = self._schedulers[device]
  if s == nil then
    -- location the position of the device within the chain so processing can
    -- start there
    local device_index = 0
    for i, d in ipairs(self.devices) do
      if d == device then
        device_index = i
        break
      end
    end
    if device_index < 1 then
      error('device not a member of this chain')
    end
    s = Scheduler.new(self, device_index)
    self._schedulers[device] = s
  end
  return s
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
  Device = Device.new,
  Input = Input.new,
  Output = Output.new,
  Chain = Chain.new,
  Group = Group.new,

  -- debug
  __input_count = input_count,
  __inputs = inputs,
}
