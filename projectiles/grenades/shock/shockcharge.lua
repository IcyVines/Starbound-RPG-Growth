require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = projectile.sourceEntity()
  --animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
  --animator.setParticleEmitterActive("sparks", true)

  script.setUpdateDelta(5)

  self.damageClampRange = {2,20}

  self.tickTime = config.getParameter("boltInterval", 1.0)
  self.tickTimer = self.tickTime
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  local boltPower = util.clamp(10, self.damageClampRange[1], self.damageClampRange[2])
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    local targetIds = world.entityQuery(mcontroller.position(), config.getParameter("jumpDistance", 8), {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })

    shuffle(targetIds)

    for i,id in ipairs(targetIds) do
      local sourceEntityId = self.id
      if world.entityCanDamage(sourceEntityId, id) and not world.lineTileCollision(mcontroller.position(), world.entityPosition(id)) then
        local sourceDamageTeam = world.entityDamageTeam(sourceEntityId)
        local directionTo = world.distance(world.entityPosition(id), mcontroller.position())
        world.spawnProjectile(
          "teslaboltsmall",
          mcontroller.position(),
          self.id,
          directionTo,
          false,
          {
            power = boltPower,
            damageTeam = sourceDamageTeam,
            statusEffects = {"ivrpgoverload"}
          }
        )
        --animator.playSound("bolt")
        return
      end
    end
  end

end
