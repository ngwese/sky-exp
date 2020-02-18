include('sky/lib/prelude')
sky.use('sky/lib/engine/polysub')

source = sky.Input{
  name = "AXIS-64 USB Keyboard",
  chain = sky.Chain{
    sky.Logger{},
    sky.PolySub{}
  },
}

function redraw()
  screen.clear()
  screen.update()
end