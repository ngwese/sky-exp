include('sky/lib/prelude')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/device/switcher')
sky.use('sky/lib/engine/polysub')
sky.use('sky/lib/io/norns')
sky.use('sky/lib/io/grid')
sky.use('sky/lib/io/crow')
sky.use('sky/lib/device/ui')
--sky.use('sky/lib/device/es')
sky.use('sky/lib/device/linn')

local halfsecond = include('awake/lib/halfsecond')
local util = require('util')
local math = require('math')

g = grid.connect()

logger = sky.Logger{
  filter = sky.is_clock,
  bypass = true
}

out1 = sky.CrowVoice{
}

arp1 = sky.Group{
  bypass = false,
  sky.Held{},      -- track held notes, emit on change
  sky.Pattern{},   -- generate pattern when held notes change
  sky.Arp{         -- generate notes from pattern
    mode = sky.ARP_QUEUE_MODE,
  },
}

main = sky.Chain{
  sky.GridGestureRegion{
    --sky.esShapeGesture{},
    sky.linnGesture{},
  },
 -- arp1,
  logger,
  sky.GridDisplay{
    grid = g,
    sky.linnRender{},
  },
  out1,
}

in2 = sky.GridInput{
  grid = g,
  chain = main,
}

clk = sky.Clock{
  interval = sky.bpm_to_sec(120, 4),
  chain = main,
}

function init()
  halfsecond.init()

  -- halfsecond
  params:set('delay', 0.13)
  params:set('delay_rate', 0.95)
  params:set('delay_feedback', 0.27)
  -- polysub
  --params:set('amprel', 0.1)

  main:init()

  clk:start()
end

function redraw()
  screen.clear()
  screen.update()
  main:redraw()
end

function cleanup()
  main:cleanup()
  clk:cleanup()
end
