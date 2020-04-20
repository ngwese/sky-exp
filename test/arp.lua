include('sky/lib/prelude')
sky.use('sky/lib/core/groove')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/device/switcher')
sky.use('sky/lib/device/make_note')
sky.use('sky/lib/engine/polysub')

local halfsecond = include('awake/lib/halfsecond')

logger = sky.Logger{
  bypass = true,
}

out1 = sky.Switcher{
  which = 2,
  sky.Output{ name = "UM-ONE" },
  sky.PolySub{},
}

chain = sky.Chain{
  sky.Held{ debug = true },        -- track held notes, emit on change
  sky.Pattern{ debug = true },     -- generate pattern when held notes change
  sky.Arp{},                       -- generate notes from pattern
  sky.MakeNote{ duration = 1/16 }, -- make note duration a 16th 
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
  chain = chain,
}

g1 = sky.Groove.new{ 1/4, 1/4, 1/8, 3/8 }

function init()
  halfsecond.init()

  -- halfsecond
  params:set('delay', 0.13)
  params:set('delay_rate', 0.95)
  params:set('delay_feedback', 0.27)
  -- polysub
  params:set('ampatk', 0.04)
  params:set('amprel', 0.1)

  clk:play_sync(g1)
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  clk:cleanup()
  source:cleanup()
end
