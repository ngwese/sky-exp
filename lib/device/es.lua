sky.use('sky/lib/io/grid')

ES_DEFAULT_BOUNDS = {1,1,16,8}
ES_DEFAULT_ROOT_NOTE = 48

local function pack_xy(x, y)
  return x << 8 | y
end

local function unpack_x(packed)
  return packed >> 8
end

local function unpack_y(packed)
  return 0x0F & packed
end

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
  o.root = props.root or ES_DEFAULT_ROOT_NOTE-- midi note number
  o.vel = props.vel or 127
  o.ch = props.ch or 1
  return o
end

function esNoteGesture:process(event, output, props)
  -- mark event as being processed
  event.esNoteGesture = self
  -- invert y and shift to zero based coordinates
  local x = event.local_x - 1
  local y = props.region.bounds[4] - event.local_y
  --print("note key: ", x, y)
  if event.z == 1 then
    local e = sky.mk_note_on(note_for(self.root, x, y), self.vel, self.ch)
    output(e)
  else
    local e = sky.mk_note_off(note_for(self.root, x, y), self.vel, self.ch)
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
  -- led brightness levels
  o.note_level = props.note_level or 7
  o.key_level = props.key_level or 15
  -- position
  o.root = props.root or ES_DEFAULT_ROOT_NOTE
  o:set_bounds(props.bounds or ES_DEFAULT_BOUNDS)
  -- held grid key state
  o._key_held = {}
  o._note_held = {}
  return o
end

function esNoteRender:set_bounds(bounds)
  self.bounds = bounds
  self.width = bounds[3] - (bounds[1] - 1)
  self.height = bounds[4] - (bounds[2] - 1)
  self._mapper = build_note_map(self.root, self.width, self.height)
end

function esNoteRender:render(event, props)
  if sky.is_type(event, sky.GRID_KEY_EVENT) and event.esNoteGesture then
    local k = pack_xy(event.x, event.y)
    if event.z == 1 then self._key_held[k] = true else self._key_held[k] = nil end
    props.grid:led(event.x, event.y, event.z * self.key_level)
  elseif sky.is_note(event) then
    -- whether on or off
    local state = 1
    if event.type == sky.types.NOTE_OFF then state = 0 end

    -- light up all candidate locations
    local locations = self._mapper(event.note)
    if locations then
      for _, l in ipairs(locations) do
        local x, y = self.bounds[1] + l[1], self.height - l[2]
        if self._key_held[pack_xy(x, y)] ~= nil then
          props.grid:led(x, y, self.key_level)
        else
          props.grid:led(x, y, state * self.note_level)
        end
      end
    end
  end
end

return {
  esNoteGesture = esNoteGesture.new,
  esNoteRender = esNoteRender.new,
}




