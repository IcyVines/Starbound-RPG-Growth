require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = effect.sourceEntity()
  self.includedMonsters = config.getParameter("includedMonsters", {})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  local near = false
  local targets = friendlyQuery(mcontroller.position(), 20, {includedTypes = {"monster"}}, self.id, true)
  if targets then
    for _,id in ipairs(targets) do
      if world.monsterType(id) and self.includedMonsters[world.monsterType(id)] then
        world.sendEntityMessage(id, "addEphemeralEffect", "regeneration2", 1, self.id)
        near = true
      end
    end
  end

  status.setPersistentEffects("ivrpgfortify", {
    {stat = "protection", amount = near and 30 or 0},
    {stat = "maxEnergy", baseMultiplier = near and 1.5 or 1}
  })

  animator.setParticleEmitterActive("embers", near)
  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 1 or world.entityCurrency(self.id, "classtype") ~= 4 then
    effect.expire()
  end

end

function uninit()
  status.clearPersistentEffects("ivrpgfortify")
end
