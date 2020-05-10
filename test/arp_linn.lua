include('sky/lib/prelude')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/device/switcher')
sky.use('sky/lib/engine/polysub')
sky.use('sky/lib/io/norns')
sky.use('sky/lib/io/grid')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/device/ui')
sky.use('sky/lib/device/es')
sky.use('sky/lib/device/linn')

local halfsecond = include('awake/lib/halfsecond')
local util = require('util')
local math = require('math')

g = grid.connect()

logger = sky.Logger{
  filter = sky.is_clock,
  bypass = true
}

out1 = sky.Switcher{
  which = 1,
  sky.Output{ name = "UM-ONE" },
  sky.PolySub{},
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
    sky.esShapeGesture{},
    sky.linnGesture{},
  },
  arp1,
  logger,
  sky.GridDisplay{
    grid = g,
    sky.linnRender{},
  },
  out1,
}

in1 = sky.Input{
  name = "AXIS-49",
  chain = main,
}

in2 = sky.GridInput{
  grid = g,
  chain = main,
}

in3 = sky.Input{
  name = "TOUCHE",
  chain = sky.Chain{
    sky.Map{
      match = sky.matcher{ type = sky.types.CONTROL_CHANGE, cc = 17 },
      action = function(e)
        e.cc = 52 -- dsi evolver lpf frequency
        e.val = math.floor(util.linlin(0, 127, 23, 127, e.val))
        return e
      end,
    },
    sky.Forward(main)
  },
}

clk = sky.Clock{
  interval = sky.bpm_to_sec(120, 4),
  chain = main,
}

ui = sky.NornsInput{
  chain = sky.Chain{
    sky.Toggle{
      match = sky.matcher{ type = sky.KEY_EVENT, num = 3 },
      action = function(state)
        arp1.devices[1].hold = state
        print('arp1.devices[1].hold = ', state)
      end,
    },
    sky.Toggle{
      match = sky.matcher{ type = sky.KEY_EVENT, num = 2},
      action = function(state)
        if state then out1.which = 2 else out1.which = 1 end
        print('out1.which = ', out1.which)
      end,
    },
    sky.Toggle{
      match = sky.matcher{ type = sky.KEY_EVENT, num = 1},
      action = function(state)
        arp1.bypass = state
        print('arp1.bypass = ', state)
      end,
    }
  }
}


function init()
  halfsecond.init()

  -- halfsecond
  params:set('delay', 0.13)
  params:set('delay_rate', 0.95)
  params:set('delay_feedback', 0.27)
  -- polysub
  params:set('amprel', 0.1)

  ui.chain:init()
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
  in1:cleanup()
end
