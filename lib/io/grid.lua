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
  o.topleft = props.topleft or DEFAULT_TOPLEFT
  return o
end

function esNoteGesture:process(event, output, state)
  if event.type == GridInput.GRID_KEY_EVENT then
    if self:in_note_area(event.x, event.y) then
      -- invert y and shift to zero based coordinates
      local x = event.x - self.topleft[1]
      local y = 8 - event.y
      --print("note key: ", x, y)
      if event.z == 1 then
        local e = sky.mk_note_on(note_for(self.root, x, y), self.vel, self.ch)
        e.grid_xy = {event.x, event.y}
        output(e)
      else
        local e = sky.mk_note_off(note_for(self.root, x, y), self.vel, self.ch)
        e.grid_xy = {event.x, event.y}
        output(e)
      end
    end
  end
  -- pass original input event on
  output(event)
end

function esNoteGesture:in_note_area(x, y)
  -- test if the raw x,y is in the gesture area
  return x >= self.topleft[1] and y >= self.topleft[2]
end

--
-- esNoteRender
--
local esNoteRender = {}
esNoteRender.__index = esNoteRender

function esNoteRender.new(props)
  local o = setmetatable(props, esNoteRender)
  o.grid = props.grid or grid.connect()
  o.brightness = props.brightness or 10
  o.topleft = props.topleft or DEFAULT_TOPLEFT
  o.mapper = build_note_map(48, 15, 8)
  return o
end

function esNoteRender:process(event, output, state)
  if sky.is_note(event) then
    -- whether on or off
    local state = 1
    if event.type == sky.types.NOTE_OFF then state = 0 end

    -- light up all candidate locations
    local locations = self.mapper(event.note)
    if locations then
      for _, l in ipairs(locations) do
        local x, y = self.topleft[1] + l[1], 8 - l[2]
        self.grid:led(x, y, state * self.brightness)
      end
    end

    -- if the incoming event has grid press data use that too
    local hint = event.grid_xy
    if hint then
      self.grid:led(hint[1], hint[2], state * 15)
    end

    -- TODO: move this to a fixed refresh timer system???
    self.grid:refresh()
  end
  output(event)
end

return {
  GridInput = GridInput.new,
  esNoteGesture = esNoteGesture.new,
  esNoteRender = esNoteRender.new,
}




