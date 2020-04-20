local MakeNote = {}
MakeNote.__index = MakeNote

function MakeNote.new(o)
  local o = setmetatable(o or {}, MakeNote)
  o._scheduler = nil
  return o
end

function MakeNote:device_inserted(chain)
  if self._scheduler ~= nil then
    error('MakeNote: one instance cannot be used in multiple chains at the same time')
  end
  self._scheduler = chain:scheduler(self)
end

function MakeNote:device_removed(chain)
  self._scheduler = nil
end

function MakeNote:process(event, output, state)
  if event.from == self then  -- previously scheduled
    output(event)
  elseif sky.is_type(event, sky.types.NOTE_ON) and event.duration ~= nil then
    output(event)
    local note_off = sky.mk_note_off(event.note, 0, event.ch)
    note_off.from = self
    self._scheduler:sync(event.duration, note_off)
  else
    output(event)
  end
end

return {
  MakeNote = MakeNote.new,
}