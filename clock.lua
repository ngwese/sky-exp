include('sky/lib/prelude')
sky.use('sky/lib/core/groove')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/io/crow')

shapes = sky.CrowShape{
  ar(0.025, 0.1), adsr(0.1, 0.5, 2, 2), pulse(1, 5, 1), lfo(1, 5),
}

which = 1

local clock2trig = function(event, output)
  if sky.is_clock(event) then output(sky.mk_trigger(which))
  else output(event) end
end

clk = sky.Clock{
  chain = sky.Chain{
    clock2trig,     -- transform clock events to trigger events
    sky.Logger{},   -- show what is going on
    shapes,         -- trigger crow shapes
  },
}

function init()
  clk:start()
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  clk:stop()
end