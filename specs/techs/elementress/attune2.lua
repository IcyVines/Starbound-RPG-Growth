require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.movementParams = mcontroller.baseParameters()
  self.elementMod = math.random(3)
  self.damageGivenUpdate = 5
  self.elementList = {"fire", "ice", "electric"}
  self.statusList = {"ivrpgsear", "ivrpgembrittle", "ivrpgoverload"}
  self.borderList = {"bb552233", "2288cc22", "88882233"}
  self.timer = 15
  for _,element in ipairs(self.elementList) do
    animator.setSoundVolume(element .. "Activate", 0.25)
    animator.setSoundVolume(element .. "Loop", element == "ice" and 0.5 or 0.25)
  end
  soundOn("fire")
end


function update(dt)
  self.timer = self.timer - dt
  local element = self.elementList[self.elementMod]
  status.setPersistentEffects("ivrpgelementalweave", {
    {stat =  element .. "Resistance", amount = 3},
    {stat =  element .. "StatusImmunity", amount = 1},
    {stat =  "lavaImmunity", amount = element == "fire" and 1 or 0}
  })

  status.setPrimaryDirectives("?border=1;" .. self.borderList[self.elementMod] .. ";" ..  self.borderList[self.elementMod])

  if self.timer <= 0 then
    local elementMod = math.random(3)
    self.timer = 10
    if self.elementMod ~= elementMod then
      self.elementMod = elementMod
      soundOn(element)
    end
  end

  updateDamageGiven()

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or world.entityCurrency(self.id, "classtype") ~= 2 then
    effect.expire()
  end
end

function soundOn(elementOff)
  animator.stopAllSounds(elementOff .. "Loop")
  animator.playSound(self.elementList[self.elementMod] .. "Activate")
  animator.playSound(self.elementList[self.elementMod] .. "Loop", -1)
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.setPrimaryDirectives()
end

function uninit()
  animator.stopAllSounds("fireLoop")
  animator.stopAllSounds("electricLoop")
  animator.stopAllSounds("iceLoop")
  reset()
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        world.sendEntityMessage(notification.targetEntityId, "addEphemeralEffect", self.statusList[self.elementMod], 3, self.id)
      end
    end
  end
end
