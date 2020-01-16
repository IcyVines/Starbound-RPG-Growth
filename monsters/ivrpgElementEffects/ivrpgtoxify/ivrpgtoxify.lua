require "/scripts/util.lua"

function init()
  effect.setParentDirectives("border=1;00AA0033;00AA0033")
  effect.addStatModifierGroup({
    {stat = "maxHealth", effectiveMultiplier = 0.75}
  })
  self.timer = 0.25
  self.sourceId = effect.sourceEntity()
  if self.sourceId then
    self.message = world.sendEntityMessage(self.sourceId, "hasStat", "ivrpguccontagion")
  end
end

function update(dt)
  status.addEphemeralEffect("weakpoison", effect.duration())
  if self.message:result() then
    contagionSpread(dt)
  end
end

function contagionSpread(dt)
  self.timer = self.timer - dt
  if self.timer <= 0 then
    self.timer = 0.25
    if math.random(1,20) < 2 then
      local targetIds = world.entityQuery(mcontroller.position(), 8, {
        withoutEntityId = entity.id(),
        includedTypes = {"creature"}
      })

      shuffle(targetIds)

      for i,id in ipairs(targetIds) do
        if world.entityCanDamage(self.sourceId, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
          spawnPoison()
          world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgtoxify", 5, self.sourceId)
          return
        end
      end
    end
  end
end

function spawnPoison()
  self.damageConfig = {power = 0, speed = 4, knockback = 0, bounces = 0, timeToLive = 1, damageKind = "applystatus"}
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {1,0}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {0.87,-0.5}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {0.5,-0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {0,-1}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {-0.5,-0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {-0.87,-0.5}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {-1,0}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {-0.87,0.5}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {-0.5,0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {0,1}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {0.5,0.87}, false, self.damageConfig)
  world.spawnProjectile("poisontrail", mcontroller.position(), entity.id(), {0.87,0.5}, false, self.damageConfig)
end

function uninit()

end
