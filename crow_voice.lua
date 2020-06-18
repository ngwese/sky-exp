include('sky/lib/prelude')
sky.use('sky/lib/io/crow')

clk = sky.Input{
  name = "AXIS-64",
  chain = sky.Chain{
    sky.Logger{},
    sky.CrowVoice{},
  },
}

function init()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
end