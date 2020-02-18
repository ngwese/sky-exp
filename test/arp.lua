include('sky/lib/prelude')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/device/switcher')
sky.use('sky/lib/engine/polysub')

local halfsecond = include('awake/lib/halfsecond')

logger = sky.Logger{
  bypass = false,
}

out1 = sky.Switcher{
  which = 1,
  sky.Output{ name = "UM-ONE" },
  sky.PolySub{},
}

chain = sky.Chain{
  sky.Held{ debug = true },      -- track held notes, emit on change
  sky.Pattern{ debug = true },   -- generate pattern when held notes change
  sky.Arp{},       -- generate notes from pattern
  logger,
  out1,
}

in1 = sky.Input{
  name = "AXIS-64 USB Keyboard",
  chain = chain,
}

in2 = sky.Input{
  name = "TOUCHE",
  chain = chain,
}

clk = sky.Clock{
  interval = sky.bpm_to_sec(100, 4),
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
  source:cleanup()
end
