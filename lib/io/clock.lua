
local _regular = function (this, yield)
  this:emit_start()
  while true do
    this:emit_tick()
    yield(this.interval)
  end
end

local _groove = function(this, groove)
  this:emit_start()
  for _, beat in groove:cycle() do
    this:emit_tick()
    clock.sync(beat)
  end
end

--
-- Clock (independent, free running)
--

local Clock = {}
Clock.__index = Clock

function Clock.new(o)
  local o = setmetatable(o or {}, Clock)
  o.interval = o.interval or 0.5
  o._tick = 0
  o._id = nil
  return o
end

function Clock:_cancel()
  if self._id ~= nil then
    clock.cancel(self._id)
  end
end

function Clock:start()
  self:_cancel()
  self._id = clock.run(_regular, self, clock.sleep)
end

function Clock:start_sync()
  self:_cancel()
  self._id = clock.run(_regular, self, clock.sync)
end

function Clock:play_once(groove)
  self:_cancel()
  self._id = clock.run(function()
    self:emit_start()
    for _, v in groove:iter() do
      self:emit_tick()
      clock.sleep(v)
    end
    self:stop() -- automatically stop
  end)
end

function Clock:play(groove)
  self:_cancel()
  self._id = clock.run(function()
    self:emit_start()
    for _, v in groove:cycle() do
      self:emit_tick()
      clock.sleep(v)
    end
  end)
end

function Clock:play_sync(groove)
  self:_cancel()
  self._id = clock.run(_groove, self, groove)
end

function Clock:stop()
  if self._id ~= nil then
    clock.cancel(self._id)
    self._id = nil
    self:emit_stop()
  end
end

function Clock:is_running()
  return self._id ~= nil
end

function Clock:emit(event)
  if self.chain ~= nil then
    self.chain:process(event)
  end
end

function Clock:emit_start()
  self:emit(sky.mk_start(self))
end

function Clock:emit_stop()
  self:emit(sky.mk_stop(self))
end

function Clock:emit_tick()
  self._tick = self._tick + 1
  self:emit(sky.mk_clock(self._tick, self))
end

--
-- SystemClock
--

local SystemClock = {}
SystemClock.__index = SystemClock

local singleton_system_clock = nil

-- wire up transport callbacks
clock.transport.start = function()
  if singleton_system_clock ~= nil then
    singleton_system_clock:start()
  end
end

clock.transport.stop = function()
  if singleton_system_clock ~= nil then
    singleton_system_clock:stop()
  end
end

function SystemClock.new(o)
  if singleton_system_clock == nil then
    local o = setmetatable(o or {}, SystemClock)
    o.division = o.division or 1
    o._tick = 0
    o._id = nil
    singleton_system_clock = o
  end
  return singleton_system_clock
end

function SystemClock:start()
  -- FIXME: what should happen if this is called directly?
  if self._id ~= nil then
    --print("canceling before re-start", self._id)
    clock.cancel(self._id)
  end
  self._id = clock.run(function()
    self:emit(sky.mk_start(self))
    while true do
      self._tick = self._tick + 1
      self:emit(sky.mk_clock(self._tick, self))
      clock.sync(self.division)
    end
  end)
  --print("started", self._id)
end

function SystemClock:stop()
  -- FIXME: what should happen if this is called directly?
  if self._id ~= nil then
    --print("canceling explict stop", self._id)
    clock.cancel(self._id)
    self._id = nil
    self:emit(sky.mk_stop(self))
  end
end

function SystemClock:is_running()
  return self._id ~= nil
end

function SystemClock:emit(event)
  if self.chain ~= nil then
    self.chain:process(event)
  end
end

return {
  Clock = Clock.new,
  SystemClock = SystemClock.new,
}