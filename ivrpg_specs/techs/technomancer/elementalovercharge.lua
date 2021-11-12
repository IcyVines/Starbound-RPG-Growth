require "/scripts/keybinds.lua"
require "/tech/wizardtech/wizardmagicshield/wizardmagicshield.lua"

function update(args)
  self.health = status.resource("health")
  if self.active then
    if status.resource("energy") == 0 or self.energyCooldownTimer > 0 then
      status.setResourceLocked("energy", true)
      if self.energyCooldownTimer == 0 then
        self.energyCooldownTimer = 0.5
      end
    else
      status.setResourceLocked("energy", false)
    end
    status.setResourcePercentage("energyRegenBlock", 1.0)
    local regenBonus = calculateEnergyCost()
    status.modifyResourcePercentage("energy", args.dt * self.regenSpeed * regenBonus * (self.energyCooldownTimer > 0 and 0.5 or 1))
    tech.setParentDirectives("?border=2;34ED2A20;4E1D7000")
    updateDamageTaken()
  end

  status.setPersistentEffects("ivrpgelementalovercharge", {
    {stat = "fireResistance", amount = self.active and 3 or 0},
    {stat = "electricResistance", amount = self.active and 3 or 0},
    {stat = "iceResistance", amount = self.active and 3 or 0},
    {stat = "poisonResistance", amount = self.active and 3 or 0},
    {stat = "fireStatusImmunity", amount = self.active and 1 or 0},
    {stat = "electricStatusImmunity", amount = self.active and 1 or 0},
    {stat = "iceStatusImmunity", amount = self.active and 1 or 0},
    {stat = "poisonStatusImmunity", amount = self.active and 1 or 0},
    {stat = "powerMultiplier", amount = self.active and ((1 - status.resource("energy") / status.stat("maxEnergy")) * 0.2) or 0}
  })

  if self.energyCooldownTimer > 0 then
    self.energyCooldownTimer = math.max(self.energyCooldownTimer - args.dt, 0)
  end
end

function updateDamageTaken()
  self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  self.lastNotification = false
  if self.notifications then
    for _,notification in pairs(self.notifications) do
      local healthLost = notification.healthLost or 0
      local InitialHealth = (status.resource("health") or 0) + healthLost
      local damageDealt = notification.damageDealt or 0
      if damageDealt > 0 then
        -- For some reason, these damageKinds duplicate in damageTaken function
        if notification.damageSourceKind
          and (notification.damageSourceKind == "falling"
          or notification.damageSourceKind == "poison"
          or notification.damageSourceKind == "fire")
          then damageDealt = damageDealt/2 end
        local newHealth = InitialHealth - damageDealt
        local energy = status.resource("energy")
        status.overConsumeResource("energy", damageDealt)

        if notification.sourceEntityId and world.entityExists(notification.sourceEntityId) and world.entityCanDamage(entity.id(), notification.sourceEntityId) then
          local directionTo = world.distance(world.entityPosition(notification.sourceEntityId), mcontroller.position())
          world.spawnProjectile(
            "teslaboltsmall",
            mcontroller.position(),
            entity.id(),
            directionTo,
            false,
            {
              power = damageDealt,
              damageTeam = world.entityDamageTeam(entity.id()),
              damageKind = "nova",
              timeToLive = 3,
              statusEffects = {"ivrpgstarfall"}
            }
          )
          animator.playSound("bolt")
        end

        if damageDealt > energy then
          damageDealt = energy
        end
        if newHealth + (damageDealt / 2) <= 0 then
          --Tough Luck
          return
        end
        status.modifyResource("health", damageDealt / 2)
      end
    end
  end
end

function uninit()
  tech.setParentDirectives("")
  status.clearPersistentEffects("ivrpgelementalovercharge")
end

