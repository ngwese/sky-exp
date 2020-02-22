local table = require('table')
local Deque = sky.use('sky/lib/container/deque')

--
-- Held(note) class
--
local Held = {}
Held.__index = Held
Held.EVENT = 'HELD'

function Held.new(o)
  local o = setmetatable(o or {}, Held)
  o._ordering = Deque.new()
  o.debug = o.debug or false
  return o
end

function Held:mk_event(notes)
  return { type = Held.EVENT, notes = notes }
end

function Held.is_match(a, b)
  return (a.ch == b.ch) and (a.note == b.note)
end

function Held:track_note_off(event)
  local match = self._ordering:remove(event, self.is_match)
  -- print("track off: ")
  -- for i,v in ipairs(self._ordering:to_array()) do
  --   print(i, '\t', sky.to_string(v))
  -- end
  return match ~= nil
end

function Held:track_note_on(event)
  local k = sky.to_id(event.ch, event.note)
  self._ordering:push_back(event)
  -- print("track on: ")
  -- for i,v in ipairs(self._ordering:to_array()) do
  --   print(i, '\t', sky.to_string(v))
  -- end
  return true
end

function Held:process(event, output)
  local changed = false
  local t = event.type

  -- TODO: implement "hold" mode

  if t == sky.types.NOTE_ON then
    if event.vel == 0 then
      changed = self:track_note_off(event)
    else
      changed = self:track_note_on(event)
    end
  elseif t == sky.types.NOTE_OFF then
    changed = self:track_note_off(event)
  else
    -- pass unprocessed events
    output(event)
  end

  if changed then
    local held = self._ordering:to_array()

    -- debug
    if self.debug then
      print("HELD >>")
      for i, e in ipairs(held) do
	      print(i, sky.to_string(e))
      end
      print("<<")
    end

    output(self:mk_event(held))
  end
end


--
-- Pattern class
--
local Pattern = {}
Pattern.__index = Pattern
Pattern.EVENT = 'PATTERN'
Pattern.builder = {}

function Pattern.new(o)
  local o = setmetatable(o or {}, Pattern)
  o.style = o.syle or 'as_played'
  o.debug = o.debug or false

  return o
end

function Pattern:mk_event(value)
  return { type = Pattern.EVENT, value = value }
end

function Pattern:process(event, output, state)
  if event.type == Held.EVENT then
    local builder = self.builder[self.style]
    if builder ~= nil then
      local pattern = builder(event.notes)
      output(self:mk_event(pattern))
      if self.debug then
        print("PAT >>>")
        for i, e in ipairs(pattern) do
          print(i, sky.to_string(e))
        end
        print("<<< PAT")
      end
    end
  else
    output(event)
  end
end

function Pattern.builder.up(notes)
  local cmp = function(a, b)
    return a.note < b.note
  end
  -- MAINT: in-place sort so note order is lost
  if #notes > 1 then
    table.sort(notes, cmp)
  end
  return notes
end

function Pattern.builder.down(notes)
  local cmp = function(a, b)
    return a.note > b.note
  end
  if #notes > 1 then
    table.sort(notes, cmp)
  end
  return notes
end

function Pattern.builder.up_down(notes)
end

function Pattern.builder.up_and_down(notes)
end

function Pattern.builder.converge(notes)
end

function Pattern.builder.diverge(notes)
end

function Pattern.builder.as_played(notes)
  return notes
end

function Pattern.builder.random(notes)
end


--
-- Arp class
--
local Arp = {}
Arp.__index = Arp

function Arp.new(o)
  local o = setmetatable(o or {}, Arp)
  o._pattern = nil
  o._step = 1
  o._length = 0
  o._last = nil
  return o
end

function Arp:set_pattern(notes)
  self._pattern = notes
  self._step = 1
  self._length = #notes
end

function Arp:process(event, output, state)
  if event.type == Pattern.EVENT then
    -- capture and queue up new pattern
    --print("arp got pattern change")
    self:set_pattern(event.value)
    return
  end

  if sky.is_clock(event) then
    local last = self._last
    if last ~= nil then
      -- kill previous
      local off = sky.mk_note_off(last.note, last.vel, last.ch)
      self._last = nil
      output(off)
    end

    if self._pattern ~= nil and self._length > 0 then
      local n = self._step
      local next = self._pattern[n]
      -- print("arp", n, to_string(next))
      output(next)
      self._last = next
      n = n + 1
      if n > self._length then
	      self._step = 1
      else
	      self._step = n
      end
    end
  end

  if sky.is_note(event) then
    -- don't pass notes
    return
  end

  -- pass everything else
  output(event)
end

--
-- module
--

return {
  Held = Held.new,
  Pattern = Pattern.new,
  Arp = Arp.new,
  -- exported event types
  HELD_EVENT = Held.EVENT,
  PATTERN_EVENT = Pattern.EVENT,
}