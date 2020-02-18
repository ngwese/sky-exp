include('sky/lib/prelude')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/device/switcher')
sky.use('sky/lib/engine/polysub')
sky.use('sky/lib/io/grid')

local halfsecond = include('awake/lib/halfsecond')

g = grid.connect()

logger = sky.Logger{
  bypass = true,
}

out1 = sky.Switcher{
  which = 1,
  sky.Output{ name = "UM-ONE" },
  sky.PolySub{},
}

chain = sky.Chain{
  sky.esNoteGesture{},
  sky.esNoteRender{ grid = g, brightness = 4 },
  sky.Held{},      -- track held notes, emit on change
  sky.Pattern{},   -- generate pattern when held notes change
  sky.Arp{},       -- generate notes from pattern
  logger,
  sky.esNoteRender{ grid = g, brightness = 6 },
  out1,
}

in1 = sky.Input{
  name = "AXIS-64",
  chain = chain,
}

in2 = sky.GridInput{
  grid = g,
  chain = chain,
}

clk = sky.Clock{
  interval = sky.bpm_to_sec(60, 4),
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
