include('sky/lib/prelude')

engine.name = 'SimplePassThru'

local chain = sky.Chain{
  sky.Logger{},
  sky.Output{ device = midi.connect(2) },
}

local source = sky.Input{
  device = midi.connect(1),
  chain = chain,
}

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  source:cleanup()
end