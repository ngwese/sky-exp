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
-- Scheduler (of chain device callback events)
--

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new(chain, device_index)
  local o = setmetatable({}, Scheduler)
  o.chain = chain
  o.device_index = device_index
  o.clock_pool = Deque.new()
  return o
end

function Scheduler:sync_old(when, events)
  local coro = self.clock_pool:pop()

  if coro == nil then
    coro = clock.create(function(self, id, when, events)
      while true do
        -- print('pre sync', id)
        clock.sync(when)
        -- print('post sync', id)
        -- if type(events) == 'table' then
        --   for i, e in ipairs(events) do
        --     -- FIXME: push everything into a source Deque, exponential
        --     -- complexity in source/sink management if events are done one-by-one
        --     self.chain:process(e, self.device_index)
        --   end
        -- else
          print('pre process', id, sky.to_string(events), self.device_index)
          self.chain:process(events, self.device_index)
          -- print('post process', id)
        -- end
        -- print('pushing back in pool', id)
        self.clock_pool:push_back(id)
        -- print('suspending', id)
        clock.suspend()
      end
    end)
    -- print('allocated coro:', coro)
  end
  -- print('resuming coro:', self, coro, when, sky.to_string(events))

  clock.resume(coro, self, coro, when, events)
end

local _scheduler_coro = function(self, when, events, method)
  method(when)
  self.chain:process(events, self.device_index)
end

function Scheduler:sync(when, events)
  clock.run(_scheduler_coro, self, when, events, clock.sync)
end

function Scheduler:sleep(when, events)
  clock.run(_scheduler_coro, self, when, events, clock.sleep)
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
    if d.device_inserted ~= nil then
      d:device_inserted(o)
    end
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

-- function Chain:schedule_init(who)
--   self._schedules[who] = {
--     clock = clock.allocate(function()
--       self:
--     end)
--   }

-- function Chain:schedule_sync(who, when)

--   local outstanding = self._schedules[who]
--   if outstanding == nil then
--     -- easy case, no existing
--     outstanding = { when }
--     self._schedules[who] = outstanding
--   end



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
