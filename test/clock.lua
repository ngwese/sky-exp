include('sky/lib/prelude')
sky.use('sky/lib/core/groove')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/io/crow')

shapes = sky.CrowShape{
  ar(0.025, 0.1), adsr(0.1, 0.5, 2, 2), pulse(1, 5, 1), lfo(1, 5),
}

which = 1

clk = sky.Clock{
  chain = sky.Chain{
    -- transform clock events to trigger events
    sky.Func(function(event, output)
      if sky.is_clock(event) then output(sky.mk_trigger(which)) end
      -- else output(event) end
    end),
    
    -- show what is going on
    sky.Logger{},
    
    -- trigger crow shapes
    shapes,
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