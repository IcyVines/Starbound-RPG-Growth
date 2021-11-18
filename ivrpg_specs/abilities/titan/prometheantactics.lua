require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.armor = config.getParameter("armor", 10)
  self.allyRange = config.getParameter("allyRange", 10)
  self.allyStatus = config.getParameter("allyStatus", "ivrpgprometheantacticsarmorboost")
  self.statusLength = config.getParameter("statusLength", 5)
  _,self.damageUpdate = status.damageTakenSince()
  self.timer = 0
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
end


function update(dt)

  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")

  if self.heldItem and root.itemHasTag(self.heldItem, "shield") then
    status.setPersistentEffects("ivrpgprometheantactics", {
      {stat = "protection", amount = self.armor}
    })
    animator.setParticleEmitterActive("embers", true)
  elseif self.heldItem2 and root.itemHasTag(self.heldItem2, "shield") then
    status.setPersistentEffects("ivrpgprometheantactics", {
      {stat = "protection", amount = self.armor}
    })
    animator.setParticleEmitterActive("embers", true)
  else
    status.clearPersistentEffects("ivrpgprometheantactics")
    animator.setParticleEmitterActive("embers", false)
  end

  checkPerfectShields(dt)

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or world.entityCurrency(self.id, "classtype") ~= 4 then
    effect.expire()
  end
end

function checkPerfectShields(dt)

  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          allyArmor()
          animator.setParticleEmitterEmissionRate("embers", 10)
          self.timer = 1
        end
      end
    end
  end

  if self.timer > 0 then
    self.timer = math.max(self.timer - dt, 0)
    if self.timer == 0 then
      animator.setParticleEmitterEmissionRate("embers", 2)
    end
  end

end

function allyArmor()
  local targetIds = world.entityQuery(mcontroller.position(), self.allyRange, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })
  for i,id in ipairs(targetIds) do
    if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.id, id)) then
      world.sendEntityMessage(id, "addEphemeralEffect", self.allyStatus, self.statusLength, self.id)
    end
  end
end

function reset()
  animator.setParticleEmitterActive("embers", false)
  status.clearPersistentEffects("ivrpgprometheantactics")
  status.setPrimaryDirectives()
end

function uninit()
  reset()
end
