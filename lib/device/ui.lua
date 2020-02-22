--
-- Toggle
--
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(props)
  local o = setmetatable(props, Toggle)
  o.state = props.state or false
  o.match = props.match or function(e) return false end
  return o
end

function Toggle:process(event, output, state)
  if self.match(event) and (event.z == 1) then
    self.state = not self.state
    if self.action then
      self.action(self.state)
    end
  end
  output(event)
end

--
-- module
--

return {
  Toggle = Toggle.new,
}