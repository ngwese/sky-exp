local pm = include('meso/lib/powermate')

DEFAULT_HID_DEVICE_NAME = 'Griffin PowerMate'

--
-- PowerMateInput
--
local PowerMateInput = {}
PowerMateInput.__index = PowerMateInput
PowerMateInput.KEY_EVENT = 'PM_KEY'
PowerMateInput.ENC_EVENT = 'PM_ENC'

function PowerMateInput.new(props)
  local o = setmetatable(props, PowerMateInput)

  if not o.device then
    o.name = props.name or DEFAULT_HID_DEVICE_NAME
    for i,v in ipairs(hid.vports) do
      if sky.starts_with(v.name, o.name) then
        o.device = pm.connect(i)
      end
    end
  end

  if o.device then
    o.device.key = function(...) o:on_key_event(...) end
    o.device.enc = function(...) o:on_enc_event(...) end
  end
end

function PowerMateInput:on_key_event(num, z)
  if self.chain then
    self.chain:process({
      type = PowerMateInput.KEY_EVENT,
      num = num,
      z = z,
    })
  end
end

function PowerMateInput:on_enc_event(num, delta)
  if self.chain then
    self.chain:process({
      type = PowerMateInput.ENC_EVENT,
      num = num,
      delta = delta,
    })
  end
end

return {
  PowerMateInput = PowerMateInput.new,
}




