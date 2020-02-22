--
-- NornsInput
--
local NornsInput = {}
NornsInput.__index = NornsInput
NornsInput.KEY_EVENT = 'KEY'
NornsInput.ENC_EVENT = 'ENC'

local Singleton = nil

function NornsInput.new(props)
  local o = setmetatable(props, NornsInput)
  -- note this (re)defined script global handlers
  function key(...) o:on_key_event(...) end
  function enc(...) o:on_enc_event(...) end
  return o
end

function NornsInput:on_key_event(num, z)
  if self.chain then
    self.chain:process({
      type = NornsInput.KEY_EVENT,
      num = num,
      z = z,
    })
  end
end

function NornsInput:on_enc_event(num, delta)
  if self.chain then
    self.chain:process({
      type = NornsInput.ENC_EVENT,
      num = num,
      delta = delta,
    })
  end
end

local function shared_instance(props)
  if Singleton == nil then
    Singleton = NornsInput.new(props)
  end
  return Singleton
end

return {
  NornsInput = shared_instance,
  KEY_EVENT = KEY_EVENT,
  ENC_EVENT = ENC_EVENT,
}




