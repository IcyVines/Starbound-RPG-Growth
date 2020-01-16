function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  --animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

  script.setUpdateDelta(5)

  self.healthThreshold = config.getParameter("healthThreshold", 0.5)
  self.healingStatus = config.getParameter("healingStatus", "regeneration1")
  self.id = entity.id()

  --self.healingRate = 1.0 / config.getParameter("healTime", 60)
end

function update(dt)
  targetIds = world.entityQuery(mcontroller.position(), 10, {
    includedTypes = {"player", "npc"},
    withoutEntityId = self.id
  })

  if targetIds and status.resource("health") / status.stat("maxHealth") > self.healthThreshold then
    for _,id in ipairs(targetIds) do
      if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
        world.sendEntityMessage(id, "applyStatusEffect", self.healingStatus, 2, self.id)
      end
    end
  end

  if status.statusProperty("ivrpgprofessionpassiveactivation", false) then
    animator.playSound("heal")
    status.setStatusProperty("ivrpgprofessionpassiveactivation", false)
  end
end

function uninit()
  
end
