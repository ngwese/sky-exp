include('sky/lib/prelude')
sky.use('sky/lib/io/norns')

ui = sky.NornsInput{
  chain = sky.Chain{ sky.Logger{} },
}

function redraw()
  screen.clear()
  screen.update()
end
