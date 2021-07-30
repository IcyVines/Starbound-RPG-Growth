require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.ownerId = effect.sourceEntity()
  effect.addStatModifierGroup({
    {stat = "holyResistance", amount = -1}
  })
  self.ownerHealth = 0
  self.timer = 0
  if self.ownerId and world.entityExists(self.ownerId) then
    self.ownerHealth = world.entityHealth(self.ownerId)[1]
  end
  animator.setParticleEmitterOffsetRegion("smoke", {-1, -1, 1, 1})
  sb.logInfo(sb.printJson(mcontroller.boundBox()))
end

function update(dt)
  if self.timer > 0 then
    self.timer = math.max(self.timer - dt, 0)
    if self.timer == 0 then
      self.ownerHealth = world.entityHealth(self.ownerId)[1]
    end
    return
  end

  local ownerHealth = self.ownerHealth
  if self.ownerId and world.entityExists(self.ownerId) then
    ownerHealth = world.entityHealth(self.ownerId)[1]
  end
  if ownerHealth < self.ownerHealth then
    local damage = (self.ownerHealth - ownerHealth) / 10
    status.modifyResource("health", -damage)
    world.sendEntityMessage(self.ownerId, "bonePteropodTransfer", damage)
    animator.burstParticleEmitter("smoke")
    self.timer = 1
  end
end

function uninit()
  status.modifyResourcePercentage("health", -1)
  if self.ownerId then
    world.sendEntityMessage(self.ownerId, "bonePteropodDefeated")
  end
end
