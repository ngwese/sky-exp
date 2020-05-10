
-- setup the global sky module for devices use without having to redundently
-- require/include the core

local function import(target, module)
  for k, v in pairs(module) do
    target[k] = v
  end
end

sky = {
  __loaded = {},
}

function sky.use(path, reload)
  if sky.__loaded[path] == nil or reload then
    local module = include(path)
    sky.__loaded[path] = module
    import(sky, module)
  end
  return sky.__loaded[path]
end

sky.use('sky/lib/core/object')
sky.use('sky/lib/core/event')
sky.use('sky/lib/core/process')
sky.use('sky/lib/device/utility') -- needed by Chain
sky.use('sky/lib/device/virtual')

return sky

