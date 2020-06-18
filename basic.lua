include('sky/lib/prelude')
sky.use('sky/lib/device/transpose')
sky.use('sky/lib/engine/polysub')

source = sky.Input{
  name = "AXIS-64 USB Keyboard",
  -- name = "UM-ONE",
  chain = sky.Chain{ sky.Send("keys") },
}

double = sky.Chain{
  sky.Receive("keys"),
  -- NOTE: this is a wart. since transpose mutates the event, the single
  --       source event must be cloned so that transpose doesn't affect
  --       the source event being injected a second time
  function(event, output)
    output(sky.clone(event))
  end,
  sky.Transpose{ semitones = 12 },
  sky.Receive("keys"),
  sky.Send("out"),
}

sink = sky.Chain{ sky.Receive("out"), sky.Logger{}, sky.PolySub{} }

function init()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  source:cleanup()
end