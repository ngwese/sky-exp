include('sky/lib/prelude')
sky.use('sky/lib/device/make_note')
sky.use('sky/lib/engine/polysub')

local fixed_duration = function(event, output, state)
  if sky.is_type(event, sky.types.NOTE_OFF) then
    -- print('suppressing NOTE_OFF', sky.to_string(event))
    return
  end
  if sky.is_type(event, sky.types.NOTE_ON) then
    event.duration = 1/4
  end
  output(event)
end

chain = sky.Chain{
  fixed_duration,
  sky.MakeNote{},
  sky.Logger{},
  sky.PolySub{}
}

in1 = sky.Input{ name = "AXIS-64", chain = chain }

function init()
  -- polysub
  params:set('ampatk', 0.01)
  params:set('amprel', 0.05)
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
end