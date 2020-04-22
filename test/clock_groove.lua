include('sky/lib/prelude')
sky.use('sky/lib/core/groove')
sky.use('sky/lib/io/clock')
sky.use('sky/lib/device/make_note')
sky.use('sky/lib/engine/polysub')

chain = sky.Chain{
  sky.Logger{ show_beats = true },
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
      sky.MakeNote{ duration = 1/16 }, -- FIXME: this ends on next 16ths inverval boundry not 1/16th in length
      sky.Forward(to_chain),
    }
  }
end

clk1 = build_clock(68, chain, 1)
clk2 = build_clock(40, chain, 2)

g1 = sky.Groove.straight(3)
g2 = sky.Groove.straight(2)

function start()
  clk1.interval = 1/3
  clk2.interval = 1/2
  clk1:start_sync(g1)
  clk2:start_sync(g2)
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
end

function redraw()
  screen.clear()
  screen.update()
end

function cleanup()
  stop()
end