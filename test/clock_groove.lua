include('sky/lib/prelude')
sky.use('sky/lib/core/groove')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/device/make_note')
sky.use('sky/lib/engine/polysub')

chain = sky.Chain{
  --sky.Logger{ show_beats = true },
  --sky.PolySub{}
  sky.Output{ name = "UM-ONE" },
}

local build_clock = function(note_num, to_chain, ch)
  return sky.Clock{
    chain = sky.Chain{
      function(event, output)
        if sky.is_clock(event) then
          output(event)
          output(sky.mk_note_on(note_num, 100, ch))
        end
      end,
      sky.MakeNote{ duration = 1/16 },
      sky.Forward(to_chain),
    }
  }
end

clk1 = build_clock(68, chain, 1)
clk2 = build_clock(40, chain, 2)

g1 = sky.Groove.straight(3)
g2 = sky.Groove.straight(2)
 
--g1 = sky.Groove.new{ 0.34, 0.34 }
--g2 = sky.Groove.new{ 0.53 }

function start()
  clk1.interval = 1/3
  clk2.interval = 1/2
  clk1:play_sync(g1)
  clk2:play_sync(g2)
  --clk1:start()
  --clk2:start()
end

function stop()
  clk1:stop()
  clk2:stop()
end

function init()
  -- polysub
  --params:set('ampatk', 0.01)
  --params:set('amprel', 0.05)

  --start()

  --screen.aa(1)
  clock.run(function()
    while true do
      clock.sync(1/1)
      redraw()
    end
  end)
end

local scaler = sky.build_scalex(0, 1, 0, 1)

function head_position(fractional, exp)
  return scaler(fractional, exp)
end

e1 = 1
e2 = 1
e3 = 1

local last_x1 = 0
local last_x2 = 0

function redraw()
  local beats = clock.get_beats()
  local _, f1 = math.modf(beats/8)
  local _, f2 = math.modf(beats/16)
  local x1 = head_position(f1, e1)
  local x2 = head_position(f2, e2)

  if (x1 < last_x1) or (x2 < last_x2) then
    screen.clear()
  end

  -- first
  screen.move(0, 4)
  screen.line(128 * x1, 4)
  screen.close()
  screen.stroke()
  -- second
  screen.move(0, 8)
  screen.line(128 * x2, 8)
  screen.close()
  screen.stroke()
  screen.update()
  
  last_x1 = x1
  last_x2 = x2
end

function cleanup()
  stop()
end