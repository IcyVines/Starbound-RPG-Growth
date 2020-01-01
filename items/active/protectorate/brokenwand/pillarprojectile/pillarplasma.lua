require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0
  self.aimPosition = mcontroller.position()
  self.projectileCount = config.getParameter("projectileCount", 10)
  self.damageRepeatTimeout = config.getParameter("damageRepeatTimeout", 0.5)

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", projectile.die)
  message.setHandler("trigger", trigger)

  activate()
end

function update(dt)
  if self.delayTimer then
    self.delayTimer = self.delayTimer - dt
    if self.delayTimer <= 0 then
      projectile.die()
      self.delayTimer = nil
    end
  end

  mcontroller.setRotation(-math.pi/2)
end

function trigger(_, _, delayTime)
  --self.delayTimer = delayTime
end

function activate()

  local projectileParameters = {}
  projectileParameters.powerMultiplier = projectile.powerMultiplier()
  projectileParameters.power = projectile.power()
  projectileParameters.knockback = 10
  projectileParameters.actionOnTimeout = {
    {
      action = "projectile",
      inheritDamageFactor = 1,
      type = "ivrpgphysicalpillar",
      config = { rotation = 180, damageRepeatTimeout = self.damageRepeatTimeout }
    }
  }

  local pillarDuration = 1
  local chainStarted = false

  for i = 0, (self.projectileCount - 1) do
    projectileParameters.timeToLive = i * 0.02
    projectileParameters.actionOnTimeout[1].config.timeToLive = pillarDuration - (2 * projectileParameters.timeToLive)
    local yPosition = math.floor(mcontroller.yPosition()) - i
    local isEmpty = not world.pointTileCollision({mcontroller.xPosition(), yPosition}, {"Null", "Block", "Dynamic"})
    if isEmpty then
      world.spawnProjectile("pillarspawner", {mcontroller.xPosition(), yPosition}, projectile.sourceEntity(), {0, -1}, false, projectileParameters)
      if not chainStarted then self.delayTimer = projectileParameters.actionOnTimeout[1].config.timeToLive end
      chainStarted = true
    else
      return
    end
  end

  --projectile.processAction(projectile.getParameter("explosionAction"))
end

function rotateTo(position, dt)

end
