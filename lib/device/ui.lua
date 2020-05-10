--
-- Toggle
--
local Toggle = sky.Device:extend()

function Toggle:new(props)
  Toggle.super.new(self, props)
  self.state = props.state or false
  self.match = props.match or function(e) return false end
end

function Toggle:process(event, output, state)
  if self.match(event) and (event.z == 1) then
    self.state = not self.state
    if self.action then
      self.action(self.state)
    end
  elseif sky.is_type(event, sky.SCRIPT_INIT_EVENT) then
    -- call action with default initial state
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
  Toggle = Toggle,
}