local WeakTable = sky.use('sky/lib/container/weaktable')

--
-- Clock global transport callbacks
--
local CLOCKS = WeakTable.new()

clock.transport.start = function()
  for c, _ in pairs(CLOCKS) do
    -- c:start()
  end
end

clock.transport.stop = function()
  for c, _ in pairs(CLOCKS) do
    -- c:stop()
  end
end

--
-- Clock coroutines
--

local _fixed = function (this, yield, interval)
  this:emit_start()
  while true do
    print(this, interval)
    this:emit_tick()
    yield(interval)
  end
end

local _iterable = function(this, yield, auto_stop, ...)
  this:emit_start()
  for i, interval in ... do
    print(this, i, interval)
    this:emit_tick()
    yield(interval)
  end
  if auto_stop then
    this:emit_stop()
  end
end

--
-- Clock
--

local Clock = {}
Clock.__index = Clock

function Clock.new(o)
  local o = setmetatable(o or {}, Clock)
  o.groove = o.groove -- TODO: should interval just be a groove of one element?
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
  self._id = clock.run(_fixed, self, clock.sleep, self.interval)
end

function Clock:start_sync()
  self:_cancel()
  self._id = clock.run(_fixed, self, clock.sync, self.interval)
end

function Clock:play_once()
  self:_cancel()
  self._id = clock.run(_iterable, self, clock.sleep, true, ipairs(groove))
end

function Clock:play_once_sync()
  self:_cancel()
  self._id = clock.run(_iterable, self, clock.sync, true, ipairs(groove))
end

function Clock:play(groove)
  self:_cancel()
  self._id = clock.run(_iterable, self, clock.sleep, false, sky.cycle(groove))
end

function Clock:play_sync(groove)
  self:_cancel()
  self._id = clock.run(_iterable, self, clock.sync, false, sky.cycle(groove))
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

return {
  Clock = Clock.new,

  -- for debugging
  __CLOCKS = CLOCKS,
}