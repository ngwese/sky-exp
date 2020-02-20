local table = require('table')

--
-- GridInput
--
local GridInput = {}
GridInput.__index = GridInput
GridInput.GRID_KEY_EVENT = 'GRID_KEY'

function GridInput.new(props)
  local o = setmetatable(props, GridInput)
  o.grid = props.grid or grid.connect()
  if o.grid then
    o.grid.key = function(x, y, s)
      o:on_key_event(x, y, s)
    end
  end
end

function GridInput:on_key_event(x, y, z)
  if self.chain then
    self.chain:process({
      type = GridInput.GRID_KEY_EVENT,
      grid = self.grid,
      x = x,
      y = y,
      z = z,
    })
  end
end

--
-- GridDisplay
--
local GridDisplay = {}
GridDisplay.__index = GridDisplay

function GridDisplay.new(props)
  local o = setmetatable(props, GridDisplay)
  o.grid = props.grid or grid.connect()
  return o
end

function GridDisplay:process(event, output, state)
  local props = { grid = self.grid, bounds = state.bounds }
  for i, child in ipairs(self) do
    props.position = i
    child:render(event, props)
  end
  self.grid:refresh()
  output(event)
end

--
-- GridGestureRegion
--
local GridGestureRegion = {}
GridGestureRegion.__index = GridGestureRegion

function GridGestureRegion.new(props)
  local o = setmetatable(props, GridGestureRegion)
  o.bounds = props.bounds or {1,1,16,8}
  return o
end

function GridGestureRegion:in_bounds(key_event)
  return self.bounds[1] <= key_event.x
    and key_event.x <= self.bounds[3]
    and self.bounds[2] <= key_event.y
    and key_event.y <= self.bounds[4]
end

function GridGestureRegion:to_local(key_event)
  key_event.local_x = key_event.x - (self.bounds[1] - 1)
  key_event.local_y = key_event.y - (self.bounds[2] - 1)
  return key_event
end

function GridGestureRegion:process(event, output, state)
  state.bounds = self.bounds
  if sky.is_type(event, GridInput.GRID_KEY_EVENT) and self:in_bounds(event) then
    local props = { region = self }
    local e = self:to_local(event)
    for i, child in ipairs(self) do
      props.position = i
      child:process(e, output, props)
    end
  end
  output(event)
end


--
-- misc helpers
--

DEFAULT_TOPLEFT = {2, 1}

local function note_for(root, x, y)
  return root + x + (y * 5)
end

local function build_note_map(root, width, height)
  local map = {}
  for x = 0, width-1 do
    for y = 0, height-1 do
      local note_num = note_for(root, x, y)
      local locations = map[note_num]
      if locations == nil then
        locations = {}
        map[note_num] = locations
      end
      table.insert(locations, {x, y})
    end
  end

  return function(note_num)
    return map[note_num]
  end
end

--
-- esNoteGesture
--
local esNoteGesture = {}
esNoteGesture.__index = esNoteGesture
esNoteGesture.EVENT = esNoteGesture

function esNoteGesture.new(props)
  local o = setmetatable(props, esNoteGesture)
  o.root = props.root or 48 -- midi note number
  o.vel = props.vel or 127
  o.ch = props.ch or 1
  return o
end

function esNoteGesture:process(event, output, props)
  -- invert y and shift to zero based coordinates
  local x = event.local_x
  local y = props.region.bounds[4] - event.local_y
  --print("note key: ", x, y)
  if event.z == 1 then
    local e = sky.mk_note_on(note_for(self.root, x, y), self.vel, self.ch)
    e.grid_xy = {event.x, event.y} -- FIXME: these are local coord
    output(e)
  else
    local e = sky.mk_note_off(note_for(self.root, x, y), self.vel, self.ch)
    e.grid_xy = {event.x, event.y}
    output(e)
  end
end

--
-- esNoteRender
--
local esNoteRender = {}
esNoteRender.__index = esNoteRender

function esNoteRender.new(props)
  local o = setmetatable(props, esNoteRender)
  o.mid_bright = props.mid_bright or 3
  o.brightness = props.brightness or 15
  o.topleft = props.topleft or DEFAULT_TOPLEFT
  o._mapper = nil
  o._bounds = nil
  return o
end

function esNoteRender:render(event, props)
  if sky.is_note(event) then
    if self._bounds == nil then
      self._bounds = props.bounds
      self._mapper = build_note_map(48, self._bounds[3] - (self._bounds[1] - 1), self._bounds[4] - (self._bounds[2] - 1))
    end
    if self._bounds ~= props.bounds then
      self._mapper = build_note_map(48, self._bounds[3] - (self._bounds[1] - 1), self._bounds[4] - (self._bounds[2] - 1))
    end

    -- whether on or off
    local state = 1
    if event.type == sky.types.NOTE_OFF then state = 0 end

    -- light up all candidate locations
    local locations = self._mapper(event.note)
    if locations then
      for _, l in ipairs(locations) do
        local x, y = self.topleft[1] + l[1], 8 - l[2]
        props.grid:led(x, y, state * self.mid_bright)
      end
    end

    -- if the incoming event has grid press data use that too
    local hint = event.grid_xy
    if hint then
      props.grid:led(hint[1], hint[2], state * self.brightness)
    end
  end
end

return {
  GridInput = GridInput.new,
  GridDisplay = GridDisplay.new,
  GridGestureRegion = GridGestureRegion.new,
  esNoteGesture = esNoteGesture.new,
  esNoteRender = esNoteRender.new,
}




