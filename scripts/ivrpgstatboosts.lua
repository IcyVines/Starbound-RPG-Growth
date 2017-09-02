require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
  self.damageUpdate = 1
end

function update(dt)
  
  --[[if status.statPositive("ivrpgremove") then
  	script.setUpdateDelta(0)
  	status.clearPersistentEffects("ivrpgstatboosts")
    status.clearPersistentEffects("ivrpgclassboosts")
    status.removeEphemeralEffect("explorerglow")
    status.removeEphemeralEffect("knightblock")
    status.removeEphemeralEffect("ninjacrit")
    status.removeEphemeralEffect("wizardaffinity")
    status.removeEphemeralEffect("roguepoison")
    status.removeEphemeralEffect("soldierdiscipline")
  	return
  end]]
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
    {stat = "fallDamageMultiplier", amount = -self.dexterity*.005},

    -- Endurance
    {stat = "physicalResistance", amount = self.endurance*.0075},
    {stat = "poisonResistance", amount = self.endurance*.005},
    {stat = "fireResistance", amount = self.endurance*.005},
    {stat = "electricResistance", amount = self.endurance*.005},
    {stat = "iceResistance", amount = self.endurance*.005},
    {stat = "shadowResistance", amount = self.endurance*.005},
    {stat = "cosmicResistance", amount = self.endurance*.005},
    {stat = "radioactiveResistance", amount = self.endurance*.005},
    {stat = "grit", amount = self.endurance*.01},

    --Agility
    {stat = "fallDamageMultiplier", amount = -self.agility*.01},

    -- Vitality
    {stat = "maxHealth", baseMultiplier = math.floor(100*(1 + self.vitality*.05))/100},
    {stat = "foodDelta", amount = self.vitality*.0002},

    -- Vigor
    {stat = "maxEnergy", baseMultiplier = math.floor(100*(1 + self.vigor*.05))/100},
    {stat = "energyRegenPercentageRate", amount = math.floor(.02*self.vigor)}

  })

  -- Agility
  mcontroller.controlModifiers({
    speedModifier = 1 + self.agility*.02,
    airJumpModifier = 1 + self.agility*.01
  })

  local heldItem = world.entityHandItem(self.id, "primary")
  local heldItem2 = world.entityHandItem(self.id, "alt")
  --two handed
  if heldItem and (root.itemHasTag(heldItem, "broadsword") or root.itemHasTag(heldItem, "spear") or root.itemHasTag(heldItem, "hammer")) then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.strength*0.02}
    })
  elseif heldItem and root.itemHasTag(heldItem, "staff") then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.02}
    })
  elseif heldItem and (root.itemHasTag(heldItem, "bow") or root.itemHasTag(heldItem, "sniperrifle") or root.itemHasTag(heldItem, "assaultrifle") or root.itemHasTag(heldItem, "shotgun") or root.itemHasTag(heldItem, "rocketlauncher")) then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.015}
    })
  else
    --one-handed primary
    if (heldItem and root.itemHasTag(heldItem,"wand")) then
      status.addPersistentEffects("ivrpgstatboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.0075}
      })
    elseif (heldItem and (root.itemHasTag(heldItem,"weapon") or root.itemHasTag(heldItem,"ninja"))) then
      status.addPersistentEffects("ivrpgstatboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.0075}
      })
    end
    --one-handed primary
    if (heldItem2 and root.itemHasTag(heldItem2,"wand")) then
      status.addPersistentEffects("ivrpgstatboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.0075}
      })
    elseif (heldItem2 and (root.itemHasTag(heldItem2,"weapon") or root.itemHasTag(heldItem2,"ninja"))) then
      status.addPersistentEffects("ivrpgstatboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.0075}
      })
    end
  end
  

  updateClassEffects(self.classType)
  
  -- Affinity Effects
  
  self.affinity = world.entityCurrency(self.id, "affinitytype")
  
  if self.affinity == 0 then
    status.clearPersistentEffects("ivrpgaffinityeffects")
  else
      local frost = hasEphemeralStat("frostslow")
      local wet = hasEphemeralStat("wet")
      local isSuborWet = isInLiquid() | wet
      --sb.logInfo("FROST: "..frost)
      --sb.logInfo("WET: "..wet)
      --sb.logInfo("ISSUBORWET: "..isSuborWet)
      effs = {
        { -- Flame --
          {stat = "fireStatusImmunity", amount = 1},
          {stat = "fireResistance", amount = 3},
          {stat = "biomeheatImmunity", amount = 1},
          {stat = "maxEnergy", baseMultiplier = 1 - 0.3*isInLiquid()}
        },
        { -- Venom --
          {stat = "poisonStatusImmunity", amount = 1},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "poisonResistance", amount = 3},
          {stat = "electricResistance", amount = -0.25},
          {stat = "maxHealth", baseMultiplier = 0.5}
        },
        { -- Frost --
          {stat = "iceStatusImmunity", amount = 1},
          {stat = "iceResistance", amount = 3},
          {stat = "wetImmunity", amount = 1},
          {stat = "snowslowImmunity", amount = 1},
          {stat = "iceslipImmunity", amount = 1},
          {stat = "biomecoldImmunity", amount = 1},
          {stat = "fireResistance", amount = -0.25}
        },
        { -- Shock --
          {stat = "electricStatusImmunity", amount = 1},
          {stat = "electricResistance", amount = 3},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "slimeImmunity", amount = 1},
          {stat = "fumudslowImmunity", amount = 1 },
          {stat = "jungleslowImmunity", amount = 1 },
          {stat = "spiderwebImmunity", amount = 1 },
          {stat = "sandstormImmunity", amount = 1 },
          {stat = "snowslowImmunity", amount = 1},
          {stat = "iceResistance", amount = -0.25},
    	    {stat = "maxHealth", baseMultiplier = 1 - 0.3*isInLiquid()}
        },
        --{ -- Aer --
        --  {stat = "breathprotectionvehicle", amount = 1},
        --  {stat = "jumpModifier", effectiveMultiplier = 1.5},
        --  {stat = "fallDamageMultiplier", effectiveMultiplier = 0.5},
        --},
        { -- Infernal --
          {stat = "fireStatusImmunity", amount = 1},
          {stat = "fireResistance", amount = 3},
          {stat = "biomeheatImmunity", amount = 1},
          {stat = "maxEnergy", baseMultiplier = 1 - 0.3*isInLiquid()},

          {stat = "ffextremeheatImmunity", amount = 1},
          {stat = "lavaImmunity", amount = 1}
        },
        { -- Toxic --
          {stat = "poisonStatusImmunity", amount = 1},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "poisonResistance", amount = 3},
          {stat = "electricResistance", amount = -0.25},
          {stat = "maxHealth", baseMultiplier = 0.5},

          {stat = "biomeradiationImmunity", amount = 1},
          {stat = "protoImmunity", amount = 1}
        },
        { -- Cryo --
          {stat = "iceStatusImmunity", amount = 1},
          {stat = "iceResistance", amount = 3},
          {stat = "wetImmunity", amount = 1},
          {stat = "snowslowImmunity", amount = 1},
          {stat = "iceslipImmunity", amount = 1},
          {stat = "biomecoldImmunity", amount = 1},
          {stat = "fireResistance", amount = -0.25},

          {stat = "ffextremecoldImmunity", amount = 1},
          {stat = "breathingProtection", amount = 1},
        },
        { -- Arc --
          {stat = "electricStatusImmunity", amount = 1},
          {stat = "electricResistance", amount = 3},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "slimeImmunity", amount = 1},
          {stat = "fumudslowImmunity", amount = 1 },
          {stat = "jungleslowImmunity", amount = 1 },
          {stat = "spiderwebImmunity", amount = 1 },
          {stat = "sandstormImmunity", amount = 1 },
          {stat = "snowslowImmunity", amount = 1},
          {stat = "iceResistance", amount = -0.25},
          {stat = "maxHealth", baseMultiplier = 1 - 0.3*isInLiquid()},

          {stat = "shadowResistance", amount = 3},
          {stat = "biomeradiationImmunity", amount = 1}
        }
        --{ -- Void --
        --  {stat = "breathprotectionvehicle", amount = 1},
        --  {stat = "jumpModifier", effectiveMultiplier = 1.5},
        --  {stat = "fallDamageMultiplier", effectiveMultiplier = 0.5},
        --  {stat = "biomeradiationImmunity", amount = 1},
        --}
      }
      status.setPersistentEffects("ivrpgaffinityeffects",effs[self.affinity])

      local aestheticType = {"fire", "poison", "ice", "electric"}
      if self.affinity > 0 then
        local affinityMod = (self.affinity-1)%4
        if status.statPositive("ivrpgaesthetics") and (mcontroller.xVelocity() > 1 or mcontroller.xVelocity() < -1) and not status.statPositive("activeMovementAbilities") then
          world.spawnProjectile(aestheticType[affinityMod+1].."trail", {mcontroller.xPosition(), mcontroller.yPosition()-2}, self.id, {0,0}, false, {power = 0, knockback = 0, timeToLive = 0.5, damagePoly = {}})
        end

        if isInLiquid() == 1 then
          if affinityMod == 0 then
            status.overConsumeResource("health", dt)
          elseif affinityMod == 3 then
            status.overConsumeResource("energy", dt)
          end
        end

        if affinityMod == 2 then
          mcontroller.controlModifiers({
            speedModifier = 0.85,
            airJumpModifier = 0.85
          })
        end
      end
  end
end

function hasEphemeralStat(stat)
  ephStats = util.map(status.activeUniqueStatusEffectSummary(),
    function (elem)
      return elem[1]
    end)
  for _,v in pairs(ephStats) do
    if v == stat then return 1 end
  end
  return 0
end

function isInLiquid()
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  local mouthful = world.liquidAt(mouthposition)
    if (world.liquidAt(mouthPosition)) and
	    ((mcontroller.liquidId()== 1) or 
	    (mcontroller.liquidId()== 5) or 
	    (mcontroller.liquidId()== 6) or 
	    (mcontroller.liquidId()== 12) or 
	    (mcontroller.liquidId()== 43) or 
	    (mcontroller.liquidId()== 55) or 
	    (mcontroller.liquidId()== 58) or
	    (mcontroller.liquidId()== 60) or 
	    (mcontroller.liquidId()== 69))
    then
      return 1
    end 
  return 0
end

function updateClassEffects(classType)
  local heldItem = world.entityHandItem(self.id, "primary")
  local heldItem2 = world.entityHandItem(self.id, "alt")
  local hardcore = status.statPositive("ivrpghardcore")
  if classType == 0 then
    --No Class
    status.clearPersistentEffects("ivrpgclassboosts")
    status.removeEphemeralEffect("explorerglow")
    status.removeEphemeralEffect("knightblock")
    status.removeEphemeralEffect("ninjacrit")
    status.removeEphemeralEffect("wizardaffinity")
    status.removeEphemeralEffect("roguepoison")
    status.removeEphemeralEffect("soldierdiscipline")
    status.removeEphemeralEffect("regeneration")
  elseif classType == 1 then
    --Knight
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "grit", amount = .2},
    })

    self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
    if self.notifications then
      --sb.logInfo("Damage Taken!!!")
      for _,notification in pairs(self.notifications) do
        if notification.hitType == "ShieldHit" then
          if status.resourcePositive("perfectBlock") then
            --increased damage after perfect blocks
            if heldItem and root.itemHasTag(heldItem, "vitalaegis") then
              status.addEphemeralEffect("regeneration4", 2)
            end
            status.addEphemeralEffect("knightblock")
            --sb.logInfo("Perfect Block: " .. tostring(status.resource("perfectBlock")) .. ", " .. tostring(status.resource("prefectBlockLimit")))
          end
        end
      end
    end

    if heldItem and root.itemHasTag(heldItem, "broadsword") then
      status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
    elseif holdingWeaponsCheck(heldItem, heldItem2, true) then
      if (root.itemHasTag(heldItem, "shortsword") and root.itemHasTag(heldItem2, "shield")) or (root.itemHasTag(heldItem, "shield") and root.itemHasTag(heldItem2, "shortsword")) then
        status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2 + self.strength*.015}
          })
      end
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "maxEnergy", baseMultiplier = 0.75}
        })
      mcontroller.controlModifiers({
        speedModifier = 0.9,
        airJumpModifier = 0.7
      })
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
        {stat = "powerMultiplier", baseMultiplier = 1.1},
      })
      status.addEphemeralEffect("wizardaffinity", math.huge)
      self.wizardaffinityAdded = true
    elseif (heldItem and root.itemHasTag(heldItem, "wand") and heldItem2 and root.itemHasTag(heldItem2,"wand")) then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1.1},
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
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end
    if holdingWeaponsCheck(heldItem2, heldItem, false) then
      if (heldItem2 and root.itemHasTag(heldItem2, "wand")) and self.checkDualWield then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end
    if not self.wizardaffinityAdded then
      status.removeEphemeralEffect("wizardaffinity")
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "physicalResistance", amount = -.2}
        })
      mcontroller.controlModifiers({
        speedModifier = 0.8,
        airJumpModifier = 0.8
      })
    end
  elseif classType == 3 then
    --Ninja
    --ThrowingStar, ThrowingKunai, SnowflakeShuriken, ThrowingKnife, ThrowingDagger
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "fallDamageMultiplier", amount = -.1}
    })
    nighttime = nighttimeCheck()
    underground = undergroundCheck()
    if nighttime or underground then
      status.addEphemeralEffect("ninjacrit", math.huge)
    else
      status.removeEphemeralEffect("ninjacrit")
    end
    self.checkDualWield = true
    --if heldItem and root.itemHasTag(heldItem, "bow") then
      --status.addPersistentEffects("ivrpgclassboosts",
      --{
        --{stat = "powerMultiplier", effectiveMultiplier = 1.1}
      --})
    --end
    if holdingWeaponsCheck(heldItem, heldItem2, false) then
      if (heldItem and root.itemHasTag(heldItem, "ninja")) then
        self.checkDualWield = false
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.2}
        })
      end
    end
    if holdingWeaponsCheck(heldItem2, heldItem, false) then
      if (heldItem2 and root.itemHasTag(heldItem2, "ninja")) and self.checkDualWield then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.2}
        })
      end
    end
    mcontroller.controlModifiers({
      speedModifier = 1.1,
      airJumpModifier = 1.1
    })

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "maxHealth", baseMultiplier = 0.5}
        })
    end
  elseif classType == 4 then
    --Soldier
    --Molotov, Thorn Grenade, Bomb
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --Purposefully Empty
    })
    self.energy = status.resource("energy")
    self.maxEnergy = status.stat("maxEnergy")
    if self.energy == self.maxEnergy then
      status.addEphemeralEffect("soldierdiscipline", math.huge)
    else
      status.removeEphemeralEffect("soldierdiscipline")
    end
    if heldItem and (root.itemHasTag(heldItem, "shotgun") or root.itemHasTag(heldItem, "sniperrifle") or root.itemHasTag(heldItem, "assaultrifle")) then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
    elseif holdingWeaponsCheck(heldItem, heldItem2, true) then
      if (root.itemHasTag(heldItem,"soldier") and root.itemHasTag(heldItem2,"ranged")) or (root.itemHasTag(heldItem,"ranged") and root.itemHasTag(heldItem2,"soldier")) then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
      end
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "poisonResistance", amount = -.2},
          {stat = "fireResistance", amount = -.2},
          {stat = "electricResistance", amount = -.2},
          {stat = "iceResistance", amount = -.2}
        })
      mcontroller.controlModifiers({
        airJumpModifier = 0.9
      })
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
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
      end
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "maxHealth", baseMultiplier = 0.8},
          {stat = "foodDelta", amount = -0.002}
        })
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
          {stat = "powerMultiplier", baseMultiplier = 1.1},
          {stat = "physicalResistance", amount = .1},
          {stat = "poisonResistance", amount = .1},
          {stat = "fireResistance", amount = .1},
          {stat = "electricResistance", amount = .1},
          {stat = "iceResistance", amount = .1},
          {stat = "shadowResistance", amount = .1},
          {stat = "cosmicResistance", amount = .1},
          {stat = "radioactiveResistance", amount = .1}
        })
    end
    self.health = world.entityHealth(self.id)
    if self.health[1] ~= 0 and self.health[2] ~= 0 and self.health[1]/self.health[2]*100 >= 50 and not status.statPositive("ivrpgclassability") then
      status.addEphemeralEffect("explorerglow", math.huge)
    else
      status.removeEphemeralEffect("explorerglow")
    end

    --Hardcore
    if hardcore then
      status.addPersistentEffects("ivrpgclassboosts", 
        {
          {stat = "powerMultiplier", baseMultiplier = 0.75}
        })
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
