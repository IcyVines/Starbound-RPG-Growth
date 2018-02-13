local monsterOldInit = init

function init()
  monsterOldInit()
  self.effects = {"ivrpgsear", "ivrpgtoxify", "ivrpgembrittle", "ivrpgoverload"}
  message.setHandler("addEphemeralEffect", function(_, _, name, duration, sourceId)
    status.addEphemeralEffect(name, duration, sourceId)
  end)
  message.setHandler("hitByBloodAether", function(_, _)
    self.hitByBloodAether = true
  end)
end

function damage(args)
-- IVRPGMod
  self.id = args.sourceId
  if world.isMonster(self.id) or world.isNpc(self.id) then
    return
  end
  self.damage = args.damage
  self.allDamage = args.sourceDamage
  self.source = args.sourceKind
  self.bleedBonus = 0
  self.classType = world.entityCurrency(self.id, "classtype")
  self.affinityType = world.entityCurrency(self.id, "affinitytype")
  self.dexterity = world.entityCurrency(self.id, "dexteritypoint")
  if self.classType == 2 then
    if math.random(100) < 7 then
      status.addEphemeralEffect("electrified", 5, self.id)
    end
    if math.random(100) < 7 then
      status.addEphemeralEffect("frostslow", 5, self.id)
    end
    if math.random(100) < 7 then
      status.addEphemeralEffect("burning", 5, self.id)
    end
  elseif self.classType == 4 then
    self.dexterity = self.dexterity^1.1
    if math.random(10) < 2 then
      status.addEphemeralEffect("soldierstun", 5.0*self.damage/world.entityHealth(entity.id())[2], self.id)
    end
  elseif self.classType == 5 then
    self.dexterity = self.dexterity^1.15
    if math.random(10) < 3 then
      status.addEphemeralEffect("weakpoison", 5, self.id)
    end
  end

  --Affinity Checks
  if self.affinityType and self.affinityType > 0 then
    local effectChance = self.affinityType > 4 and 4 or 2
    if math.random(10) < effectChance then
      local effectName = self.effects[(self.affinityType - 1)%4 + 1]
      if effectName == "ivrpgoverload" then
        world.sendEntityMessage(self.id, "feedbackLoop")
      end
      local effectTime = 5
      status.addEphemeralEffect(effectName, effectTime, self.id)
    end
  end

  --Bleed Checks!
  if self.classType == 3 then
    self.dexterity = self.dexterity^1.2
    if nighttimeCheck() or undergroundCheck(world.entityPosition(self.id)) then
      self.dexterity = self.dexterity + 40
    end
  end

  self.bonusDamage = 1

  if self.source == "alwaysbleed" then
    self.bleedBonus = 200
  elseif self.source == "bloodaether" then
    self.bleedBonus = 200
    if self.hitByBloodAether then
      self.bonusDamage = 2
    end
  elseif self.source == "bluntforce" then
    self.bleedBonus = -100
  end
  if status.stat("bleedMultiplier") > 0 then
    self.allDamage = self.allDamage*status.stat("bleedMultiplier")
  end
  if self.dexterity == nil then
    return
  end
  if math.random(200) <= self.dexterity + self.bleedBonus then
    status.addEphemeralEffect("ivrpgweaken", (self.dexterity/25), self.id)
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = self.allDamage/2 * self.bonusDamage,
      sourceEntityId = self.id
    })
  end

  if world.entityHealth(entity.id())[1] <= 0 then
    --sb.logInfo("Health <= 0!")
    sendDyingMessage(self.id, self.source)
  end
  --End IVRPGMod
end

function nighttimeCheck()
  return world.timeOfDay() > 0.5 -- true if night
end

function undergroundCheck(position)
  return world.underground(position) 
end

function sendDyingMessage(sourceId, damageType)
  --sb.logInfo("Sending Message!")
  world.sendEntityMessage(sourceId, "killedMonster", monster.level(), mcontroller.position(), status.activeUniqueStatusEffectSummary(), damageType, monster.type())
end