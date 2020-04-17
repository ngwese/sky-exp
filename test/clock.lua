include('sky/lib/prelude')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/device/utility')

clk = sky.SystemClock{
  chain = sky.Chain{
    sky.Logger{}
  },
}

function init()
  --clk:start()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  clk:stop()
end