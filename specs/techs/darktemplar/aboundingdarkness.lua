require "/scripts/keybinds.lua"

function init()
  self.id = entity.id()
  self.active = false
  Bind.create("Up", toggle)
end

function activate()
  self.maxHealth = status.stat("maxHealth")
  self.sacrifice = self.maxHealth/2
  if status.resource("health") < self.sacrifice then
    return
  end
  self.active = true
  status.consumeResource("health", self.sacrifice)
  world.spawnProjectile("ivrpgdemonicexplosion", mcontroller.position(), self.id, {0,0}, true, {power = 1.5*self.sacrifice})
  status.setPersistentEffects("healthRegenImmunity", {{stat = "healingStatusImmunity",  amount = 1 }})
  self.time = 0
  self.damage = 0
end

function deactivate()
  self.scalar = 1.5 - 2.5*status.resource("health") / (self.maxHealth)
  if self.scalar <= 0 then
    self.scalar = 1
  else
    self.scalar = math.floor(self.scalar*100)/100
  end
  status.setPersistentEffects("maxHealthMultiplier", {{stat = "maxHealth", effectiveMultiplier = self.scalar}})
  status.clearPersistentEffects("healthRegenImmunity")
  status.giveResource("health", self.damage)
  self.active = false
end

function toggle()
  if self.active then
    deactivate()
  else
    activate()
  end
end

function uninit()
  status.clearPersistentEffects("maxHealthMultiplier")
  status.clearPersistentEffects("healthRegenImmunity")
end

function update(args)
  if self.active then
    if not status.consumeResource("health", 5*args.dt) then
      deactivate()
      return
    end
    self.time = self.time + args.dt
    if self.time > 0.5 then
      self.time = 0
      for i,id in ipairs(world.entityQuery(mcontroller.position(), 7, {
        withoutEntityId = self.id,
        includedTypes = {"creature"}
      })) do
        if world.entityAggressive(id) then
            world.sendEntityMessage(id, "applySelfDamageRequest", "IgnoresDef", "demonic", 2, self.id)
            self.damage = self.damage + 2
        end
      end
    end
  end
end