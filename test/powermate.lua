include('sky/lib/prelude')
sky.use('sky/lib/io/powermate')

local source = sky.PowerMateInput{
  chain = sky.Chain{ sky.Logger{} },
}

function redraw()
  screen.clear()
  screen.update()
end
