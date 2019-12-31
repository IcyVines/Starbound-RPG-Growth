require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0
  self.aimPosition = mcontroller.position()

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
      config = { rotation = 180}
    }
  }

  local pillarDuration = 1
  local breakChain = false
  local chainStarted = false
  local projectileCount = 20

  for i = 0, (projectileCount - 1) do
    projectileParameters.timeToLive = i * 0.02
    projectileParameters.actionOnTimeout[1].config.timeToLive = pillarDuration - (2 * projectileParameters.timeToLive)
    local yPosition = math.floor(mcontroller.yPosition()) - i
    local isEmpty = not world.pointTileCollision({mcontroller.xPosition(), yPosition}, {"Null", "Block", "Dynamic"})
    if isEmpty and not chainStarted and not world.pointTileCollision({mcontroller.xPosition(), yPosition - 1}, {"Null", "Block", "Dynamic"}) then
      --breakChain = true
    end
    if isEmpty and not breakChain then
      world.spawnProjectile("pillarspawner", {mcontroller.xPosition(), yPosition}, projectile.sourceEntity(), {0, -1}, false, projectileParameters)
      if not chainStarted then self.delayTimer = projectileParameters.actionOnTimeout[1].config.timeToLive end
      chainStarted = true
    end
  end

  --projectile.processAction(projectile.getParameter("explosionAction"))
end

function rotateTo(position, dt)

end
