include('sky/lib/prelude')
sky.use('sky/lib/core/groove')
sky.use('sky/lib/device/arp')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/engine/polysub')

chain = sky.Chain{
  sky.Held{},      -- track held notes, emit on change
  sky.Pattern{},   -- generate pattern when held notes change
  sky.Arp{},       -- generate notes from pattern
  sky.Logger{},
  sky.PolySub{}
}

clk = sky.Clock{ chain = chain }
in1 = sky.Input{ name = "AXIS-64", chain = chain }

g1 = sky.Groove.new{ 1/4, 1/4, 1/8, 3/8 }

function init()
  -- polysub
  params:set('ampatk', 0.01)
  params:set('amprel', 0.05)

  clk:play_sync(g1)
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  clk:stop()
end