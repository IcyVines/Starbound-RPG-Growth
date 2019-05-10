require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.allyRange = config.getParameter("allyRange", 10)
  self.allyStatus = config.getParameter("allyStatus", "rage")
  --animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)
  
  local numberOfAllies = nearbyAllies()

  status.setPersistentEffects("ivrpgbythepeople", {
    { stat = "ivrpgendurancescaling", amount = 0.05 * math.min(numberOfAllies - 3, 0) },
    { stat = "ivrpgagilityscaling", amount = 0.05 * math.min(numberOfAllies - 3, 0) },
    { stat = "ivrpgvigorscaling", amount = 0.05 * numberOfAllies },
    { stat = "ivrpgvitalityscaling", amount = 0.05 * numberOfAllies }
  })

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 3 or world.entityCurrency(self.id, "classtype") ~= 6 then
    effect.expire()
  end
end

function nearbyAllies()
  local numberOfAllies = 0
  local targetIds = world.entityQuery(mcontroller.position(), self.allyRange, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })
  for i,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
      world.sendEntityMessage(id, "addEphemeralEffect", self.allyStatus, 2, self.id)
      numberOfAllies = numberOfAllies + 1
    end
  end
  return numberOfAllies
end

function reset()
  --animator.setParticleEmitterActive("embers", false)
  status.clearPersistentEffects("ivrpgbythepeople")
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end