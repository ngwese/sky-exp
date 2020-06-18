include('sky/lib/prelude')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/device/switcher')
sky.use('sky/lib/engine/polysub')
sky.use('sky/lib/io/grid')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/device/es')

local halfsecond = include('awake/lib/halfsecond')

g = grid.connect()

logger = sky.Logger{
  filter = sky.is_clock,
  bypass = true
}

out1 = sky.Switcher{
  which = 2,
  sky.Output{ name = "UM-ONE" },
  sky.PolySub{},
}

arp1 = sky.Group{
  sky.Held{},      -- track held notes, emit on change
  sky.Pattern{},   -- generate pattern when held notes change
  sky.Arp{},       -- generate notes from pattern
}

chain = sky.Chain{
  sky.GridGestureRegion{
    sky.esNoteGesture{},
  },
  arp1,
  logger,
  sky.GridDisplay{
    grid = g,
    sky.esNoteRender{},
  },
  out1,
}

in1 = sky.Input{
  name = "AXIS-49",
  chain = chain,
}

in2 = sky.GridInput{
  grid = g,
  chain = chain,
}

clk = sky.Clock{
  interval = sky.bpm_to_sec(120, 4),
  chain = chain,
}

function init()
  halfsecond.init()

  -- halfsecond
  params:set('delay', 0.13)
  params:set('delay_rate', 0.95)
  params:set('delay_feedback', 0.27)
  -- polysub
  params:set('amprel', 0.1)

  clk:start()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  clk:cleanup()
  in1:cleanup()
end
