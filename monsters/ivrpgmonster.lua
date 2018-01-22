local monsterOldInit = init

function init()
  monsterOldInit()
  self.effects = {"ivrpgsear", "ivrpgtoxify", "ivrpgembrittle", "ivrpgoverload"}
end

function damage(args)
-- IVRPGMod
  self.id = args.sourceId
  --sb.logInfo("Damage Taken!! ID: " .. self.id)
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
      -- sb.logInfo(50.0*self.damage/world.entityHealth(entity.id())[2])
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
      status.addEphemeralEffect(self.effects[(self.affinityType - 1)%4 + 1], 5, self.id)
    end
  end

  --Bleed Checks!
  if self.classType == 3 then
    self.dexterity = self.dexterity^1.2
    if nighttimeCheck() or undergroundCheck(world.entityPosition(self.id)) then
      self.dexterity = self.dexterity + 40
    end
  end
  if self.source == "alwaysbleed" then
    self.bleedBonus = 200
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
      damage = self.allDamage/2,
      sourceEntityId = self.id
    })
  end

  if world.entityHealth(entity.id())[1] <= 0 then
    --sb.logInfo("Health <= 0!")
    sendDyingMessage(self.id, monster.level())
  end
  --End IVRPGMod
end

function nighttimeCheck()
  return world.timeOfDay() > 0.5 -- true if night
end

function undergroundCheck(position)
  return world.underground(position) 
end

function sendDyingMessage(sourceId, monsterLevel)
  --sb.logInfo("Sending Message!")
  world.sendEntityMessage(sourceId, "addToChallengeCount", monsterLevel)
end
