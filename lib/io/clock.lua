local clock = require('clock')

--
-- Clock (independent, free running)
--

local Clock = {}
Clock.__index = Clock

function Clock.new(o)
  local o = setmetatable(o or {}, Clock)
  o.interval = o.interval or 1
  o._tick = 0
  o._id = nil
  return o
end

function Clock:start()
  self._id = clock.run(function()
    self:emit(sky.mk_start(self))
    while true do
      self._tick = self._tick + 1
      self:emit(sky.mk_clock(self._tick, self))
      clock.sleep(self.interval)
    end
  end)
end

function Clock:stop()
  if self._id ~= nil then
    clock.cancel(self._id)
    self._id = nil
    self:emit(sky.mk_stop(self))
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

--
-- SystemClock
--

local SystemClock = {}
SystemClock.__index = SystemClock

-- FIXME: make singleton?

function SystemClock.new(o)
  local o = setmetatable(o or {}, SystemClock)
  o.division = o.division or 1
  o._tick = 0
  o._id = nil
  -- wire up transport callbacks
  clock.transport.start = function() o:start() end
  clock.transport.stop = function() o:stop() end
  return o
end

function SystemClock:start()
  -- FIXME: what should happen if this is called directly?
  if self._id ~= nil then
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
end

function SystemClock:stop()
  -- FIXME: what should happen if this is called directly?
  if self._id ~= nil then
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