include('sky/lib/prelude')
sky.use('sky/lib/io/arc')

a = arc.connect()

chain = sky.Chain{
  sky.ArcDialGesture{},
  sky.Logger{},
  sky.ArcDisplay{
    arc = a,
    sky.ArcDialRender{ mode = 'pointer' },
    sky.ArcDialRender{ mode = 'segment' },
    sky.ArcDialRender{ mode = 'range', width = 0.5 },
  }
}

in1 = sky.ArcInput{
  arc = a,
  chain = chain,
}


