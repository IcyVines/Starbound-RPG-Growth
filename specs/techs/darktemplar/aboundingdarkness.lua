require "/scripts/keybinds.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.id = entity.id()
  self.active = false
  self.timer = 0
  self.damageGivenUpdate = 5
  Bind.create("specialThree", toggle)
  message.setHandler("damageDealtDarkTemplar", function(_, _, damage, damageKind, bleedKind)
    if self.active and bleedKind then status.giveResource("health", damage / 4) end
  end)
  animator.setSoundPitch("burst2", 1.4)
  animator.setSoundPitch("burst3", 1.7)
end

function activate()
  self.sacrifice = self.maxHealth/3
  if status.resource("health") < self.sacrifice then
    return
  end
  self.active = true
  status.consumeResource("health", self.sacrifice)
  initialBurst()
  initialSounds()
  self.timer = 0
  self.damage = 0
end

function deactivate()
  status.clearPersistentEffects("ivrpgaboundingdarkness")
  self.active = false
  tech.setParentDirectives()
end

function toggle()
  if self.active then
    deactivate()
  else
    activate()
  end
end

function uninit()
  status.clearPersistentEffects("ivrpgaboundingdarkness")
  tech.setParentDirectives()
end

function update(args)
  self.maxHealth = status.stat("maxHealth")
  if self.active then
    self.timer = self.timer + args.dt
    local alpha = math.min(self.timer / 30, 0.95)
    tech.setParentDirectives("?fade=110000=" .. alpha)
    status.setPersistentEffects("ivrpgaboundingdarkness", {
      {stat = "healingStatusImmunity",  amount = 1 },
      {stat = "powerMultiplier", amount = 0.15 + math.min((self.timer / 30) * 0.85, 0.85)}
    })
    --updateDamageGiven()
    removeHealing()
    if not status.consumeResource("health", (2 + self.maxHealth * 0.005) * args.dt) then
      deactivate()
      return
    end
  end
end

function initialBurst()
  animator.setAnimationState("explosion", "on")
  local targetIds = enemyQuery(mcontroller.position(), 7, {includedTypes = {"creature"}}, self.id, true)
  for _,id in ipairs(targetIds) do
    world.sendEntityMessage(id, "applySelfDamageRequest", "IgnoresDef", "demonic", self.sacrifice, self.id)
  end
end

function initialSounds()
  for i=1,3 do
    animator.setSoundVolume("burst"..i, 1.0)
    animator.playSound("burst"..i)
    animator.setSoundVolume("burst"..i, 0, 3)
  end
end

function updateDamageGiven()
  local notifications = nil
  notifications, self.damageGivenUpdate = status.inflictedDamageSince(self.damageGivenUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.damageDealt > notification.healthLost and notification.healthLost > 0 then
        --status.giveResource("health", self.maxHealth * 0.01)
      end
    end
  end
end

function removeHealing()
  status.removeEphemeralEffect("bandageheal")
  status.removeEphemeralEffect("nanowrapheal")
  status.removeEphemeralEffect("bottledwaterheal")
  status.removeEphemeralEffect("medkitheal")
  status.removeEphemeralEffect("salveheal")
end