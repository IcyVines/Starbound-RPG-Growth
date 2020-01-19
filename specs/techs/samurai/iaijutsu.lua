require "/scripts/keybinds.lua"

function init()
  self.id = entity.id()
  self.active = false
  self.timer = 0
  Bind.create("specialTwo", toggle)
end

function activate()
  self.sacrifice = self.maxHealth/3
  if status.resource("health") < self.sacrifice then
    return
  end
  self.active = true
  status.consumeResource("health", self.sacrifice)
  --world.spawnProjectile("ivrpgdemonicexplosion", mcontroller.position(), self.id, {0,0}, true, {power = 1.5*self.sacrifice})
  animator.setAnimationState("explosion", "on")
  self.timer = 0
  self.damage = 0
end

function deactivate()
  --[[self.scalar = 1.5 - 2.5*status.resource("health") / (self.maxHealth)
  if self.scalar <= 0 then
    self.scalar = 1
  else
    self.scalar = math.floor(self.scalar*100)/100
  end]]
  --status.setPersistentEffects("maxHealthMultiplier", {{stat = "maxHealth", effectiveMultiplier = self.scalar}})
  status.clearPersistentEffects("ivrpgaboundingdarkness")
  --status.giveResource("health", self.damage)
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
    local alpha = math.min(self.timer / 60, 0.95)
    tech.setParentDirectives("?fade=110000=" .. alpha)
    status.setPersistentEffects("ivrpgaboundingdarkness", {
      {stat = "healingStatusImmunity",  amount = 1 },
      {stat = "powerMultiplier", amount = 0.15 + math.min((self.timer / 60) * 0.85, 0.85)}
    })
    if not status.consumeResource("health", (2 + self.maxHealth * 0.05) * args.dt) then
      deactivate()
      return
    end
    --[[if self.timer > 0.5 then
      self.timer = 0
      for i,id in ipairs(world.entityQuery(mcontroller.position(), 7, {
        withoutEntityId = self.id,
        includedTypes = {"creature"}
      })) do
        if world.entityAggressive(id) then
            world.sendEntityMessage(id, "applySelfDamageRequest", "IgnoresDef", "demonic", 2, self.id)
            self.damage = self.damage + 2
        end
      end
    end]]
  end
end