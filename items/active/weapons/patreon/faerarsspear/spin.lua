require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.direction = config.getParameter("direction", 1)
end

function update(dt)
  mcontroller.rotate(math.pi * dt * self.direction * -500)
  mcontroller.approachVelocity({0,0}, 100)
end