function init()
  effect.setParentDirectives("?border=1;fdffa5;fdffa5")
  _,self.damageUpdate = status.damageTakenSince()
  self.sourceId = effect.sourceEntity()
  self.id = entity.id()
end

function update(dt)
  checkDamage()
end

function checkDamage()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in ipairs(notifications) do
      if string.find(notification.damageSourceKind, "holyspeargungnir") then
        local health = world.entityHealth(self.id)
        if notification.healthLost > 0 and health then
          if health[1] == 0 then
            explode()
            magicBoost()
          end
        end
      end
    end
  end
end

function magicBoost()
  local targetIds = world.entityQuery(mcontroller.position(), 15, {
    withoutEntityId = self.id,
    includedTypes = {"creature"}
  })

  if targetIds then
    for _,id in ipairs(targetIds) do
      if world.entityDamageTeam(id).type == "friendly" or (world.entityDamageTeam(id).type == "pvp" and not world.entityCanDamage(self.sourceId, id)) then
        world.sendEntityMessage(id, "addEphemeralEffect", "ivrpgodinsblessing", 7, self.sourceId)
      end
    end
  end
end

function explode()
  local projectileId = world.spawnProjectile(
      "ivrpgresurgenceexplosion",
      mcontroller.position(),
      self.sourceId,
      {0,0},
      false,
      {power = status.resourceMax("health") * 0.25}
    )
end

function uninit()
  effect.setParentDirectives()
end