local fuoldInit = init
local fuoldUpdate = update
local fuoldUninit = uninit

function init()
  fuoldInit()
  self.lastYPosition = 0
  self.lastYVelocity = 0
  self.fallDistance = 0
  local bounds = mcontroller.boundBox() --Mcontroller for movement
end

function update(dt)
  fuoldUpdate(dt)
  status.addEphemeralEffect("ivrpgstatboosts", math.huge)
end
