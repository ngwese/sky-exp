T = dofile('lib/test/luaunit.lua')
Deque = dofile('lib/container/deque.lua')

function testPush()
  local d = Deque.new()
  d:push('a')
  T.assertEquals(d[d.first], 'a')
  T.assertEquals(d:count(), 1)
  d:push('b')
  T.assertEquals(d[d.first], 'b')
  T.assertEquals(d:count(), 2)
end

function testPop()
  local d = Deque.new()
  d:push('a')
  d:push('b')
  T.assertEquals(d:count(), 2)
  T.assertEquals(d:pop(), 'b')
  T.assertEquals(d:count(), 1)
  T.assertEquals(d:pop(), 'a')
  T.assertEquals(d:count(), 0)
end

function testPushBack()
  local d = Deque.new()
  d:push_back('a')
  T.assertEquals(d[d.last], 'a')
  T.assertEquals(d:count(), 1)
  d:push_back('b')
  T.assertEquals(d[d.last], 'b')
  T.assertEquals(d:count(), 2)
end

function testPopBack()
  local d = Deque.new()
  d:push('a')
  d:push('b')
  T.assertEquals(d:count(), 2)
  T.assertEquals(d:pop_back(), 'a')
  T.assertEquals(d:count(), 1)
  T.assertEquals(d:pop_back(), 'b')
  T.assertEquals(d:count(), 0)
end

function testDequeNewWithElements()
  local d = Deque.new({'a', 'b', 'c'})
  T.assertEquals(d[d.first], 'a')
  T.assertEquals(d[d.last], 'c')
end

function testClear()
  local d = Deque.new({'a', 'b', 'c'})
  T.assertEquals(d:count(), 3)
  d:clear()
  T.assertEquals(d:count(), 0)
  T.assertEquals(d:pop(), nil)
  T.assertEquals(d:pop_back(), nil)
end

function testExtendBackWithList()
  local d = Deque.new()
  d:extend_back(Deque.new({'a', 'b', 'c'}))
  T.assertEquals(d:count(), 3)
  d:extend_back(Deque.new({'z'}))
  T.assertEquals(d:count(), 4)
  T.assertEquals(d:pop_back(), 'z')
  T.assertEquals(d:pop_back(), 'c')
end

function testRemoveFront()
  local d = Deque.new({'a', 'b', 'c'})
  T.assertEquals(d:remove('a'), 'a')
  T.assertEquals(d:count(), 2)
  T.assertEquals(d:remove('b'), 'b')
  T.assertEquals(d:count(), 1)
end

function testRemoveBack()
  local d = Deque.new({'a', 'b', 'c'})
  T.assertEquals(d:remove('c'), 'c')
  T.assertEquals(d:count(), 2)
  T.assertEquals(d:remove('b'), 'b')
  T.assertEquals(d:count(), 1)
end

function testRemoveMiddle()
  local d = Deque.new({'a', 'b', 'c'})
  T.assertEquals(d:remove('b'), 'b')
  T.assertEquals(d:count(), 2)
  T.assertEquals(d:pop(), 'a')
  T.assertEquals(d:pop(), 'c')
  T.assertEquals(d:count(), 0)
end

function testRemoveWithDuplicatesInMiddle()
  local d = Deque.new({'a', 'a', 'b', 'c', 'b'})
  T.assertEquals(d:remove('a'), 'a')
  T.assertEquals(d:count(), 4)
  T.assertEquals(d:remove('b'), 'b')
  T.assertEquals(d:remove('b'), 'b')
  T.assertEquals(d:count(), 2)
  T.assertEquals(d:pop(), 'a')
  T.assertEquals(d:pop(), 'c')
end

function testIterEmpty()
  local d = Deque.new()
  for i, v in d:ipairs() do
    T.assertTrue(false) -- shouldn't get here
  end
end

function testIterSimple()
  local v = {'a', 'b', 'c'}
  local d = Deque.new(v)
  T.assertEquals(d:to_array(), v)
end

function testIterAfterPop()
  local d = Deque.new({'a', 'b', 'c'})
  d:pop()
  T.assertEquals(d:to_array(), {'b', 'c'})
  d:pop_back()
  T.assertEquals(d:to_array(), {'b'})
end

function testIterAfterRemove()
  local d = Deque.new({'a', 'b', 'b', 'c'})
  d:remove('b')
  d:remove('b')
  T.assertEquals(d:to_array(), {'a', 'c'})
end



os.exit(T.LuaUnit.run())