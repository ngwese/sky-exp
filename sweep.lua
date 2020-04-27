include('sky/lib/prelude')
sky.use('sky/lib/device/make_note')

--
-- Step
--

local Step = {}
Step.__index = Step

function Step.new(chance, velocity, duration)
  local o = setmetatable({}, Step)
  o.chance = chance or 0      -- [0, 1] for probability
  o.velocity = velocity or 1  -- [0, 1]
  o.duration = duration or 1  -- [0, 1] where duration is a multiplier on 1/row.res
  return o
end

function Step:is_active()
  return self.chance > 0
end

--
-- Row
--

local Row = {}
Row.__index = Row

local MAX_STEPS = 16

function Row.new(props)
  local o = setmetatable({} or props, Row)
  o:set_n(o.n or 8)
  o:set_res(o.res or 4)
  o:set_bend(o.bend or 1.0)
  o:set_offset(o.offset or 0)
  o.steps = {}
  o:steps_clear()
  return o
end

function Row:set_res(r)
  self.res = util.clamp(math.floor(r), 4, 32)
  return self
end

function Row:set_n(n)
  self.n = util.clamp(math.floor(n), 2, 32)
  return self
end

function Row:set_bend(b)
  self.bend = util.clamp(b, 0.2, 5)
  return self
end

function Row:set_offset(o)
  self.offset = math.floor(o)
  return self
end

function Row:steps_clear()
  for i = 1, MAX_STEPS do
    self.steps[i] = Step.new(0) -- zero chance
  end
end

function Row:randomize()
  for i, s in ipairs(self.steps) do
    local chance = math.random()
    print(self, i, s, chance)
    if chance > 0.3 then chance = math.random() else chance = 0 end -- random chance for ~20% of steps (but not really)
    if chance > 0 then
      s.chance = chance
      s.velocity = math.random()
      s.duration = math.random()
      tab.print(s)
    end
  end
end

--
-- RowRender
--

local RowRender = {}
RowRender.__index = RowRender
RowRender.HEIGHT = 15
RowRender.STEP_WIDTH = 6
RowRender.BAR_WIDTH = 4
RowRender.BAR_HEIGHT = 10

function RowRender.new(x, y)
  local o = setmetatable({}, RowRender)
  o.topleft = {x or 1, y or 1}
  return o
end

function RowRender:draw(row)
  -- precaution, close any path which may have been left open
  --screen.close()
  -- draw from bottom, left
  local x = self.topleft[1]
  local y = self.topleft[2] + self.BAR_HEIGHT
  for i, step in ipairs(row.steps) do
    --screen.move(x, y)
    if step:is_active() then
      local width = math.floor(util.linlin(0, 1, 1, self.BAR_WIDTH, step.duration)) -- FIXME: 0 duration really?
      local height = math.floor(util.linlin(0, 1, 1, self.BAR_HEIGHT, step.velocity))
      print("drawing", x, y, width, height)
      screen.rect(x, y, width, height)
      screen.level(10)
      screen.fill()
    end
    x = x + self.STEP_WIDTH
  end
end

local function layout_vertical(x, y, widgets)
  -- adjust the widget top/left origin such that they are arranged in a stack
  local top = y
  for i, w in ipairs(widgets) do
    w.topleft[1] = x
    w.topleft[2] = top
    top = top + w.HEIGHT
  end
end

--
-- script logic
--

rows = { Row.new(), Row.new(), Row.new(), Row.new() }
renderers = { RowRender.new(), RowRender.new(), RowRender.new() }

function redraw()
  screen.clear()
  for i, r in ipairs(renderers) do
    --print("drawing", i, r)
    r:draw(rows[i])
  end
  screen.update()
end

function init()
  -- testing
  for i, r in ipairs(rows) do
    r:randomize()
  end
  layout_vertical(8, 4, renderers)

  -- screen
  -- clock.run(function()
  --   while true do
  --     clock.sleep(1/2)
  --     redraw()
  --   end
  -- end)
end

