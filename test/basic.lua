include('sky/lib/prelude')
sky.use('sky/lib/device/transpose')
sky.use('sky/lib/engine/polysub')

t = sky.Transpose{ semitones = 12 }

source = sky.Input{
  name = "AXIS-64 USB Keyboard",
  chain = sky.Chain{ sky.Send("keys") },
}

c1 = sky.Receive("keys", sky.Chain{ sky.Send("out") })
c2 = sky.Receive("keys", sky.Chain{ t, sky.Send("out") })
sink = sky.Receive("out", sky.Chain{ sky.Logger{}, sky.PolySub{} })

function init()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  source:cleanup()
end