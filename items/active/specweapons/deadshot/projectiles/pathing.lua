require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.playerId = projectile.sourceEntity()
  self.controlForce = config.getParameter("controlForce", 1000)
  self.maxSpeed = config.getParameter("speed", 60)
  --[[mcontroller.applyParameters({
    collisionEnabled = false
  })]]
end

function update(dt)
  self.velocity = mcontroller.velocity()
  self.nextPosition = mcontroller.position()
end