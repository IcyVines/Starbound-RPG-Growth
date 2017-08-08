require "/scripts/vec2.lua"

function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end

function update(dt)
  self.id = entity.id()
  self.classType = world.entityCurrency(self.id, "classtype")

  self.strengthBonus = self.classType == 1 and 1.15 or (self.classType == 5 and 1.1 or (self.classType == 4 and 1.05 or 1))
  self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
  self.vitalityBonus = self.classType == 4 and 1.15 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.05 or 1))
  self.vigorBonus = self.classType == 6 and 1.15 or (self.classType == 2 and 1.1 or 1)
  self.intelligenceBonus = self.classType == 2 and 1.2 or 1
  self.enduranceBonus = self.classType == 1 and 1.1 or (self.classType == 4 and 1.05 or (self.classType == 6 and 1.05 or 1))
  self.dexterityBonus = self.classType == 3 and 1.2 or (self.classType == 5 and 1.15 or (self.classType == 4 and 1.1 or 1))

  self.strength = world.entityCurrency(self.id, "strengthpoint")^self.strengthBonus
  self.agility = world.entityCurrency(self.id,"agilitypoint")^self.agilityBonus
  self.vitality = world.entityCurrency(self.id,"vitalitypoint")^self.vitalityBonus
  self.vigor = world.entityCurrency(self.id,"vigorpoint")^self.vigorBonus
  self.intelligence = world.entityCurrency(self.id,"intelligencepoint")^self.intelligenceBonus
  self.endurance = world.entityCurrency(self.id,"endurancepoint")^self.enduranceBonus
  self.dexterity = world.entityCurrency(self.id,"dexteritypoint")^self.dexterityBonus

  status.setPersistentEffects( "ivrpgstatboosts",
  {

    -- Strength
    --Increases Shield Health, Damage with melee weapons, and physical resistance
    {stat = "shieldHealth", effectiveMultiplier = 1 + self.strength*.05},
    {stat = "physicalResistance", amount = self.strength*.0025},

    -- Intelligence
    {stat = "energyRegenPercentageRate", amount = .05*self.intelligence},
    {stat = "energyRegenBlockTime", amount = -.01*self.intelligence},

    -- Dexterity
    {stat = "fallDamageMultiplier", amount = -self.dexterity*.01},

    -- Endurance
    {stat = "physicalResistance", amount = self.endurance*.005},
    {stat = "poisonResistance", amount = self.endurance*.005},
    {stat = "fireResistance", amount = self.endurance*.005},
    {stat = "electricResistance", amount = self.endurance*.005},
    {stat = "iceResistance", amount = self.endurance*.005},
    {stat = "shadowResistance", amount = self.endurance*.005},
    {stat = "cosmicResistance", amount = self.endurance*.005},
    {stat = "radioactiveResistance", amount = self.endurance*.005},
    {stat = "grit", amount = self.endurance*.01},

    --Agility
    {stat = "fallDamageMultiplier", amount = -self.agility*.005},

    -- Vitality
    {stat = "maxHealth", amount = math.floor(self.vitality*4)},
    {stat = "foodDelta", amount = self.vitality*.02},

    -- Vigor
    {stat = "maxEnergy", amount = math.floor(self.vigor*4)},
    {stat = "energyRegenPercentageRate", amount = math.floor(.02*self.vigor)}

  })

  -- Agility
  mcontroller.controlModifiers({
    speedModifier = 1 + self.agility*.02,
    airJumpModifier = 1 + self.agility*.01
  })

  local heldItem = world.entityHandItem(self.id, "primary")
  local heldItem2 = world.entityHandItem(self.id, "alt")

  if heldItem and (root.itemHasTag(heldItem, "broadsword") or root.itemHasTag(heldItem, "spear") or root.itemHasTag(heldItem, "hammer")) then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", effectiveMultiplier = 1 + self.strength*0.02}
    })
  elseif heldItem and root.itemHasTag(heldItem, "staff") then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", effectiveMultiplier = 1 + self.intelligence*0.02}
    })
  elseif heldItem and (root.itemHasTag(heldItem, "bow") or root.itemHasTag(heldItem, "sniperrifle") or root.itemHasTag(heldItem, "assaultrifle") or root.itemHasTag(heldItem, "shotgun") or root.itemHasTag(heldItem, "rocketlauncher")) then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", effectiveMultiplier = 1 + self.dexterity*0.01}
    })
  elseif (heldItem and root.itemHasTag(heldItem,"weapon")) or (heldItem2 and root.itemHasTag(heldItem2,"weapon")) then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", effectiveMultiplier = 1 + self.dexterity*0.01}
    })
  end
  
  updateClassEffects(self.classType)

end

function updateClassEffects(classType)
  local heldItem = world.entityHandItem(self.id, "primary")
  local heldItem2 = world.entityHandItem(self.id, "alt")
  
  if classType == 0 then
    --No Class
    status.clearPersistentEffects("ivrpgclassboosts")
    status.removeEphemeralEffect("explorerglow")
    status.removeEphemeralEffect("knightblock")
    status.removeEphemeralEffect("ninjacrit")
    status.removeEphemeralEffect("wizardaffinity")
    status.removeEphemeralEffect("roguepoison")
    status.removeEphemeralEffect("soldierdiscipline")
  elseif classType == 1 then
    --Knight
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "grit", amount = .2},
    })
    self.notifications = status.damageTakenSince(5)
    if self.notifications then
      --sb.logInfo("Damage Taken!!!")
      for _,notification in pairs(self.notifications) do
        if notification.hitType == "ShieldHit" then
          if status.resourcePositive("perfectBlock") then
            --increased damage after perfect blocks
            status.addEphemeralEffect("knightblock")
          end
        end
      end
    end
    if heldItem and root.itemHasTag(heldItem, "broadsword") then
      status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", effectiveMultiplier = 1.2}
          })
    elseif holdingWeaponsCheck(heldItem, heldItem2, true) then
      if (root.itemHasTag(heldItem, "shortsword") and root.itemHasTag(heldItem2, "shield")) or (root.itemHasTag(heldItem, "shield") and root.itemHasTag(heldItem2, "shortsword")) then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", effectiveMultiplier = 1.2}
          })
      end
    end
  elseif classType == 2 then
    --Wizard
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --purposefully left empty
    })
    --arcane chance in monster.lua
    self.checkDualWield = true
    self.wizardaffinityAdded = false
    if heldItem and root.itemHasTag(heldItem, "staff") then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", effectiveMultiplier = 1.1},
      })
      status.addEphemeralEffect("wizardaffinity", math.huge)
      self.wizardaffinityAdded = true
    elseif (heldItem and root.itemHasTag(heldItem, "wand") and heldItem2 and root.itemHasTag(heldItem2,"wand")) then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", effectiveMultiplier = 1.1 + self.intelligence*.0075},
      })
      status.addEphemeralEffect("wizardaffinity", math.huge)
      self.wizardaffinityAdded = true
    elseif holdingWeaponsCheck(heldItem, heldItem2, true) then
      if (heldItem2 and root.itemHasTag(heldItem2, "wand")) or (heldItem and root.itemHasTag(heldItem, "wand")) then
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end
    if holdingWeaponsCheck(heldItem, heldItem2, false) then
      if (heldItem and root.itemHasTag(heldItem, "wand")) then
        self.checkDualWield = false
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", effectiveMultiplier = 1.1 + self.intelligence*.0075}
        })
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end
    if holdingWeaponsCheck(heldItem2, heldItem, false) then
      if (heldItem2 and root.itemHasTag(heldItem2, "wand")) and self.checkDualWield then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", effectiveMultiplier = 1.1 + self.intelligence*.0075}
        })
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end
    if not self.wizardaffinityAdded then
      status.removeEphemeralEffect("wizardaffinity")
    end
  elseif classType == 3 then
    --Ninja
    --ThrowingStar, ThrowingKunai, SnowflakeShuriken, ThrowingKnife, ThrowingDagger
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "fallDamageMultiplier", amount = -.3}
    })
    nighttime = nighttimeCheck()
    underground = undergroundCheck()
    if nighttime or underground then
      status.addEphemeralEffect("ninjacrit", math.huge)
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "ninjaBleed", amount = 20}
      })
    else
      status.removeEphemeralEffect("ninjacrit")
    end
    self.checkDualWield = true
    if heldItem and root.itemHasTag(heldItem, "bow") then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", effectiveMultiplier = 1.1}
      })
    end
    if holdingWeaponsCheck(heldItem, heldItem2, false) then
      if (heldItem and root.itemHasTag(heldItem, "ninja")) then
        self.checkDualWield = false
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", effectiveMultiplier = 1.2}
        })
      end
    end
    if holdingWeaponsCheck(heldItem2, heldItem, false) then
      if (heldItem2 and root.itemHasTag(heldItem2, "ninja")) and self.checkDualWield then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", effectiveMultiplier = 1.2}
        })
      end
    end
    mcontroller.controlModifiers({
      speedModifier = 1.2,
      airJumpModifier = 1.2
    })
  elseif classType == 4 then
    --Soldier
    --Molotov, Thorn Grenade, Bomb
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --Purposefully Empty
    })
    self.health = world.entityHealth(self.id)
    if self.health[1] ~= 0 and self.health[2] ~= 0 and self.health[1]/self.health[2]*100 >= 50 then
      status.addEphemeralEffect("soldierdiscipline", math.huge)
    else
      status.removeEphemeralEffect("soldierdiscipline")
    end
    if heldItem and (root.itemHasTag(heldItem, "shotgun") or root.itemHasTag(heldItem, "sniperrifle") or root.itemHasTag(heldItem, "rocketlauncher") or root.itemHasTag(heldItem, "assaultrifle")) then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", effectiveMultiplier = 1.1}
        })
    elseif holdingWeaponsCheck(heldItem, heldItem2, true) then
      if (root.itemHasTag(heldItem,"soldier") and root.itemHasTag(heldItem2,"ranged")) or (root.itemHasTag(heldItem,"ranged") and root.itemHasTag(heldItem2,"soldier")) then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", effectiveMultiplier = 1.1}
        })
      end
    end
  elseif classType == 5 then
    --Rogue
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --Purposefully empty
    })
    self.foodValue = status.resource("food")
    if self.foodValue >= 34 then
      status.addEphemeralEffect("roguepoison",math.huge)
    else
      status.removeEphemeralEffect("roguepoison")
    end
    --poison is finished in monster.lua
    if holdingWeaponsCheck(heldItem, heldItem2, true) then
      if root.itemHasTag(heldItem, "weapon") and root.itemHasTag(heldItem2, "weapon") then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", effectiveMultiplier = 1.2}
          })
      end
    end
  elseif classType == 6 then
    --Explorer
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "physicalResistance", amount = .1}
    })
    if (heldItem and root.itemHasTag(heldItem, "explorer")) or (heldItem2 and root.itemHasTag(heldItem2, "explorer")) then
      status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "physicalResistance", amount = .05},
          {stat = "poisonResistance", amount = .05},
          {stat = "fireResistance", amount = .05},
          {stat = "electricResistance", amount = .05},
          {stat = "iceResistance", amount = .05},
          {stat = "shadowResistance", amount = .05},
          {stat = "cosmicResistance", amount = .05},
          {stat = "radioactiveResistance", amount = .05}
        })
    end
    self.energy = status.resource("energy")
    self.maxEnergy = status.stat("maxEnergy")
    if self.maxEnergy ~= 0 and self.energy/self.maxEnergy >= .5 then
      status.addEphemeralEffect("explorerglow", math.huge)
    else
      status.removeEphemeralEffect("explorerglow")
    end
  end 
end

function holdingWeaponsCheck(heldItem, heldItem2, dualWield)
  if heldItem then
    --first item exists
    if heldItem2 then
      --second item exists
      if dualWield then
        --bonus from two weapons
        return true
      else
        --bonus should only apply to single weapon
        if root.itemHasTag(heldItem2, "weapon") then
          return false
        else
          return true
        end
      end
    else
      --second item does not exist
      if dualWield then
        --bonus applies with only two weapons
        return false
      else
        --only one item is equipped and we might get a bonus
        return true
      end
    end
  else
    --no item
    return false
  end
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end

function nighttimeCheck()
  return world.timeOfDay() > 0.5 -- true if night
end

function daytimeCheck()
  return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
  return world.underground(mcontroller.position()) 
end

function uninit()
  status.clearPersistentEffects("ivrpgstatboosts")
  status.clearPersistentEffects("ivrpgclassboosts")
  status.removeEphemeralEffect("ninjaglow")
end
