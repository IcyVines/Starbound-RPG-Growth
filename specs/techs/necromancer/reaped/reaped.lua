function init()
  self.id = effect.sourceEntity()
  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;6E677C;463756")
  local intelligence = world.entityCurrency(self.id, "intelligencepoint")
  if status.resource("health") / status.resourceMax("health") < (intelligence/3+15)/100 then
    status.modifyResourcePercentage("health", -1)
  end
end

function update(dt)
  if status.resource("health") == 0 then effect.expire() end
end

function deathMist()
	world.spawnProjectile("reapeddamageprojectile", mcontroller.position(), self.id)
  world.spawnProjectile("reapedhealprojectile", mcontroller.position())
  world.sendEntityMessage(self.id, "enemyReaped")
end

function uninit()
  if status.resource("health") == 0 then deathMist() end
end