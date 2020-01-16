require "/scripts/ivrpgutil.lua"

function init()
  self.critBonusId = effect.addStatModifierGroup({})
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  self.id = effect.sourceEntity()
  self.adeptTimer = 0
  self.ruinFound = false
end


function update(dt)

  if nighttimeCheck() or undergroundCheck() then
    effect.setStatModifierGroup(self.critBonusId, {
      {stat = "ivrpgBleedChance", amount = 0.1},
      {stat = "ivrpgBleedLength", amount = 0.5}
    })
    animator.setParticleEmitterActive("embers", true)
  else
    effect.setStatModifierGroup(self.critBonusId, {})
    animator.setParticleEmitterActive("embers", false)
  end

  if not status.statPositive("ivrpgclassability") then
    effect.setParentDirectives("border=1;d8111120;59050500")
  else
    effect.setParentDirectives()
  end

  --Adept Check
  if world.entityCurrency(self.id, "experienceorb") >= 122500 and status.statusProperty("ivrpgsuadept") ~= true and world.entityCurrency(self.id, "intelligencepoint") > 40 and world.entityCurrency(self.id, "agilitypoint") > 40 then
    local targetEntities = world.monsterQuery(mcontroller.position(), 8, {
      withoutEntityId = self.id,
      includedTypes = {"creature"}
    })
    self.ruinFound = false
    if targetEntities then
      for _,v in ipairs(targetEntities) do
        if world.entityTypeName(v) == "eyeboss" then
          self.ruinFound = true
          break
        end
      end
    end

    if not self.ruinFound then
      self.adeptTimer = 0
    else
      self.adeptTimer = self.adeptTimer + dt
    end

    if self.adeptTimer >= 30 then
      status.setStatusProperty("ivrpgsuadept", true)
      world.sendEntityMessage(self.id, "sendRadioMessage", "Adept Unlocked!")
    end
  end
  
  if world.entityCurrency(self.id, "classtype") ~= 3 then
    effect.expire()
  end
end

function uninit()

end

function nighttimeCheck()
  return world.timeOfDay() > 0.5 -- true if night
end

function undergroundCheck()
  return world.underground(mcontroller.position()) 
end