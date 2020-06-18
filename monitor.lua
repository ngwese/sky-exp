include('sky/lib/prelude')

local chain = sky.Chain{
  sky.Logger{},
  sky.Output{ device = midi.connect(2) },
}

source = sky.Input{
  device = midi.connect(1),
  -- name = "AXIS-64",
  chain = chain,
}

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  source:cleanup()
end