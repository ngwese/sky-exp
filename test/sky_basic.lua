local sky = include('sky/lib/prelude')

sky.use('sky/lib/device/transpose')

engine.name = 'SimplePassThru'

t = sky.Transpose{ semitones = 0 }

local chain = sky.Chain{
  t,
  sky.Logger{},
  sky.Output{ device = midi.connect(2) },
}

local source = sky.Input{
  --device = midi.connect(1),
  name = "AXIS-64 USB Keyboard",
  chain = chain,
}

local clk = sky.Clock{
  interval = sky.bpm_to_sec(30, 4),
  chain = chain,
}

function init()
  --clk:start()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  --clk:cleanup()
  source:cleanup()
end