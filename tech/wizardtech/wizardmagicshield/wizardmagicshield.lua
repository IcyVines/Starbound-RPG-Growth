require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
  script.setUpdateDelta(4)
  self.active = false
  self.damageUpdate = 5
  self.regenSpeed = config.getParameter("regenSpeed", 0.1)
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=80FC9FFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.rechargeEffectTimer = 0
  self.energyCooldownTimer = 0

  Bind.create("f", magicShield)
end

function magicShield()
  if self.active then
    self.active = false
    tech.setParentDirectives("")
    animator.playSound("deactivate")
  else
    self.active = true
    animator.playSound("activate")
  end
end

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
    local regenBonus = 1 + math.min((status.statusProperty("ivrpgintelligence", 0) + status.statusProperty("ivrpgvigor", 0)) / 100, 0.5)
    status.modifyResourcePercentage("energy", 5 * args.dt * self.regenSpeed * regenBonus * (self.energyCooldownTimer > 0 and 0.5 or 1))
    --sb.logInfo("Percent: " .. (self.regenSpeed * regenBonus * (self.energyCooldownTimer > 0 and 0.5 or 1)))
    tech.setParentDirectives("?border=2;34ED2A20;4E1D7000")
    updateDamageTaken()
  end

  if self.energyCooldownTimer > 0 then
    self.energyCooldownTimer = math.max(self.energyCooldownTimer - args.dt, 0)
  end

end

function uninit()
  self.active = false
  tech.setParentDirectives("")
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

