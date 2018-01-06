require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
  self.damageUpdate = 1
  self.damageGivenUpdate = 1
  self.challengeDamageGivenUpdate = 1
  
  self.level = -1

  --Versioning if necessary
  --if not status.statPositive("ivrpgupdate13") then
    --status.addPersistentEffect("ivrpgupdate13", {stat = "ivrpgupdate13", amount = 1})
  --end

end

function update(dt)
  
  self.id = entity.id()
  updateXPPulse()
  self.xp = world.entityCurrency(self.id, "experienceorb")
  self.level = self.level == -1 and math.floor(math.sqrt(self.xp/100)) or self.level
  self.classType = world.entityCurrency(self.id, "classtype")

  self.strengthBonus = self.classType == 1 and 1.15 or 1
  self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
  self.vitalityBonus = self.classType == 4 and 1.05 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.15 or 1))
  self.vigorBonus = self.classType == 4 and 1.15 or (self.classType == 2 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.05 or 1)))
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
  if not status.statPositive("activeMovementAbilities") or mcontroller.canJump() or status.statPositive("ninjaVanishSphere") then
    mcontroller.controlModifiers({
      speedModifier = 1 + self.agility*.02,
      airJumpModifier = 1 + self.agility*.01
    })
  end

  self.heldItem = world.entityHandItem(self.id, "primary")
  self.heldItem2 = world.entityHandItem(self.id, "alt")
  self.itemConf = self.heldItem and root.itemConfig(self.heldItem).config
  self.twoHanded = self.itemConf and self.itemConf.twoHanded or false
  self.category = self.itemConf and self.itemConf.category or false
  self.isBrokenBroadsword = self.heldItem == "brokenprotectoratebroadsword" and true or false
  self.weapon1 = self.heldItem and root.itemHasTag(self.heldItem, "weapon") or false
  self.weapon2 = self.heldItem2 and root.itemHasTag(self.heldItem2, "weapon") or false
  self.isBow = self.weapon1 and root.itemHasTag(self.heldItem, "bow") or false

  --Weapon Stat Bonuses
  if self.heldItem == "magnorbs" or self.heldItem == "evileye" then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.01 + self.intelligence*0.01}
    })
  elseif self.heldItem == "remotegrenadelauncher" then
    status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.015}
    })
  elseif self.heldItem == "erchiuseye" then
  	status.addPersistentEffects("ivrpgstatboosts",
    {
      {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.015}
    })
  elseif self.heldItem then
  	if root.itemHasTag(self.heldItem, "broadsword") or root.itemHasTag(self.heldItem, "spear") or root.itemHasTag(self.heldItem, "hammer") then
		status.addPersistentEffects("ivrpgstatboosts",
		{
		  {stat = "powerMultiplier", baseMultiplier = 1 + self.strength*0.02}
		})
	elseif root.itemHasTag(self.heldItem, "staff") then
		status.addPersistentEffects("ivrpgstatboosts",
		{
		  {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.02}
		})
	elseif self.isBow or root.itemHasTag(self.heldItem, "rifle") or root.itemHasTag(self.heldItem, "sniperrifle") or root.itemHasTag(self.heldItem, "assaultrifle") or root.itemHasTag(self.heldItem, "shotgun") or root.itemHasTag(self.heldItem, "rocketlauncher") then
		status.addPersistentEffects("ivrpgstatboosts",
		{
		  {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.015}
		})
	else
	    --Bonus for One-Handed Primary
	    if root.itemHasTag(self.heldItem,"wand") then
	      status.addPersistentEffects("ivrpgstatboosts",
	      {
	        {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.0075}
	      })
	    elseif self.weapon1 or root.itemHasTag(self.heldItem,"ninja") then
	      status.addPersistentEffects("ivrpgstatboosts",
	      {
	        {stat = "powerMultiplier", baseMultiplier = 1 + self.dexterity*0.0075}
	      })
	    end
	end
  end
  --Extra Bonus with One-Handed Secondary
  if self.heldItem2 then
    if root.itemHasTag(self.heldItem2,"wand") then
      status.addPersistentEffects("ivrpgstatboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1 + self.intelligence*0.0075}
      })
    elseif self.weapon2 or root.itemHasTag(self.heldItem2,"ninja") then
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
          {stat = "maxEnergy", effectiveMultiplier = 1 - 0.3*isInLiquid()}
        },
        { -- Venom --
          {stat = "poisonStatusImmunity", amount = 1},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "poisonResistance", amount = 3},
          {stat = "electricResistance", amount = -0.25},
          {stat = "maxHealth", effectiveMultiplier = 0.85}
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
    	    {stat = "maxHealth", effectiveMultiplier = 1 - 0.3*isInLiquid()}
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
          {stat = "maxEnergy", effectiveMultiplier = 1 - 0.3*isInLiquid()},

          {stat = "ffextremeheatImmunity", amount = 1},
          {stat = "lavaImmunity", amount = 1}
        },
        { -- Toxic --
          {stat = "poisonStatusImmunity", amount = 1},
          {stat = "tarStatusImmunity", amount = 1},
          {stat = "poisonResistance", amount = 3},
          {stat = "electricResistance", amount = -0.25},
          {stat = "maxHealth", effectiveMultiplier = 0.85},

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
          {stat = "maxHealth", effectiveMultiplier = 1 - 0.3*isInLiquid()},

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
          world.spawnProjectile(aestheticType[affinityMod+1].."trailIVRPG", {mcontroller.xPosition(), mcontroller.yPosition()-2}, self.id, {0,0}, false, {power = 0, knockback = 0, timeToLive = 0.3, damageKind = "applystatus"})
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

  self.dnotifications, self.damageGivenUpdate = status.inflictedHitsSince(self.damageGivenUpdate)
  if self.dnotifications then
    --sb.logInfo("Damage Taken!!!")
    for _,notification in pairs(self.dnotifications) do
      
      --Rogue Siphon
      if notification.damageSourceKind == "rogueelectricslash" then status.modifyResource("energy", 20)
      elseif notification.damageSourceKind == "roguepoisonslash" then status.modifyResource("health", 10)
      elseif notification.damageSourceKind == "rogueslash" then status.modifyResource("food", 3)
      end

    end
  end

  checkLevelUp()
  updateChallenges()
end

function checkLevelUp()
  local currXP = world.entityCurrency(self.id,"experienceorb")
  if currXP >= (self.level+1)^2*100 and self.level < 50 then
    self.level = self.level + 1
    if self.level == 1 then
      return
    end
    status.addEphemeralEffect("ivrpglevelup")
  elseif currXP < (self.level+1)^2*100 then
    self.level = math.floor(math.sqrt(currXP/100))
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
  local hardcore = status.statPositive("ivrpghardcore")
  local weaponsDisabled = false

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

    self.notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
    if self.notifications then
      --sb.logInfo("Damage Taken!!!")
      for _,notification in pairs(self.notifications) do
        if notification.hitType == "ShieldHit" then
          if status.resourcePositive("perfectBlock") then
            --increased damage after perfect blocks
            if self.heldItem and root.itemHasTag(self.heldItem, "vitalaegis") then
              status.addEphemeralEffect("regeneration4", 2)
            end
            status.addEphemeralEffect("knightblock")
            --sb.logInfo("Perfect Block: " .. tostring(status.resource("perfectBlock")) .. ", " .. tostring(status.resource("prefectBlockLimit")))
          end
        end
      end
    end

    if self.heldItem and root.itemHasTag(self.heldItem, "broadsword") then
      status.addPersistentEffects("ivrpgclassboosts",
          {
            {stat = "powerMultiplier", baseMultiplier = 1.2}
          })
    elseif self.heldItem and self.heldItem2 and not self.twoHanded then
      if (root.itemHasTag(self.heldItem, "shortsword") and root.itemHasTag(self.heldItem2, "shield")) or (root.itemHasTag(self.heldItem, "shield") and root.itemHasTag(self.heldItem2, "shortsword")) then
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
          {stat = "maxEnergy", effectiveMultiplier = 0.75}
        })
      mcontroller.controlModifiers({
        speedModifier = 0.9,
        airJumpModifier = 0.7
      })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow then
        if self.twoHanded then
          if self.weapon1 and not root.itemHasTag(self.heldItem, "melee") then weaponsDisabled = true end
        else
          if self.weapon1 then
            if not root.itemHasTag(self.heldItem, "melee") or self.weapon2 then
              weaponsDisabled = true
            end
          elseif self.weapon2 then
            if not root.itemHasTag(self.heldItem2, "melee") then
              weaponsDisabled = true
            end
          end
        end
      end

    end

  elseif classType == 2 then
    --Wizard
    status.setPersistentEffects("ivrpgclassboosts",
    {
      --purposefully left empty
    })
    --Arcane Chance Specified in monster.lua and npc.lua

    self.checkDualWield = true
    self.wizardaffinityAdded = false

    if self.heldItem and root.itemHasTag(self.heldItem, "staff") then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1.1},
      })
      status.addEphemeralEffect("wizardaffinity", math.huge)
      self.wizardaffinityAdded = true
    elseif (self.heldItem and root.itemHasTag(self.heldItem, "wand") and self.heldItem2 and root.itemHasTag(self.heldItem2,"wand")) then
      status.addPersistentEffects("ivrpgclassboosts",
      {
        {stat = "powerMultiplier", baseMultiplier = 1.1},
      })
      status.addEphemeralEffect("wizardaffinity", math.huge)
      self.wizardaffinityAdded = true
    elseif holdingWeaponsCheck(self.heldItem, self.heldItem2, true) then
      if (self.heldItem2 and root.itemHasTag(self.heldItem2, "wand")) or (self.heldItem and root.itemHasTag(self.heldItem, "wand")) then
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end

    if holdingWeaponsCheck(self.heldItem, self.heldItem2, false) then
      if (self.heldItem and root.itemHasTag(self.heldItem, "wand")) then
        self.checkDualWield = false
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
        status.addEphemeralEffect("wizardaffinity", math.huge)
        self.wizardaffinityAdded = true
      end
    end

    if holdingWeaponsCheck(self.heldItem2, self.heldItem, false) then
      if (self.heldItem2 and root.itemHasTag(self.heldItem2, "wand")) and self.checkDualWield then
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

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow and not (self.heldItem == "erchiuseye") and not (self.heldItem == "magnorbs") and not (self.heldItem == "evileye") then
        if self.twoHanded then
          if self.weapon1 and not root.itemHasTag(self.heldItem, "staff") then weaponsDisabled = true end
        else
          if self.weapon1 then
            if not root.itemHasTag(self.heldItem, "wand") then
              weaponsDisabled = true
            end
          end
          if self.weapon2 then
            if not root.itemHasTag(self.heldItem2, "wand") and not root.itemHasTag(self.heldItem2, "dagger") then
              weaponsDisabled = true
            end
          end
        end
      end

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
    --if self.heldItem and root.itemHasTag(self.heldItem, "bow") then
      --status.addPersistentEffects("ivrpgclassboosts",
      --{
        --{stat = "powerMultiplier", effectiveMultiplier = 1.1}
      --})
    --end
    if holdingWeaponsCheck(self.heldItem, self.heldItem2, false) then
      if (self.heldItem and root.itemHasTag(self.heldItem, "ninja")) then
        self.checkDualWield = false
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.2}
        })
      end
    end
    if holdingWeaponsCheck(self.heldItem2, self.heldItem, false) then
      if (self.heldItem2 and root.itemHasTag(self.heldItem2, "ninja")) and self.checkDualWield then
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
          {stat = "maxHealth", effectiveMultiplier = 0.5}
        })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow and not (self.heldItem == "adaptablecrossbow") and not (self.heldItem == "soluskatana") then
        if self.twoHanded then
          if self.weapon1 then weaponsDisabled = true end
        else
          if self.weapon1 then
            if root.itemHasTag(self.heldItem, "ranged") or root.itemHasTag(self.heldItem, "wand") then
              weaponsDisabled = true
            end
          end
          if self.weapon2 then
            if root.itemHasTag(self.heldItem2, "ranged") or root.itemHasTag(self.heldItem2, "wand") then
              weaponsDisabled = true
            end
          end
        end
      end

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
    elseif self.energy < self.maxEnergy*3/4 then
      status.removeEphemeralEffect("soldierdiscipline")
    end
    if self.heldItem and (root.itemHasTag(self.heldItem, "shotgun") or root.itemHasTag(self.heldItem, "sniperrifle") or root.itemHasTag(self.heldItem, "assaultrifle")) then
        status.addPersistentEffects("ivrpgclassboosts",
        {
          {stat = "powerMultiplier", baseMultiplier = 1.1}
        })
    elseif holdingWeaponsCheck(self.heldItem, self.heldItem2, true) then
      if (root.itemHasTag(self.heldItem,"soldier") and root.itemHasTag(self.heldItem2,"ranged")) or (root.itemHasTag(self.heldItem,"ranged") and root.itemHasTag(self.heldItem2,"soldier")) then
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
          {stat = "poisonResistance", amount = -.2},
          {stat = "fireResistance", amount = -.2},
          {stat = "electricResistance", amount = -.2},
          {stat = "iceResistance", amount = -.2}
        })
      mcontroller.controlModifiers({
        airJumpModifier = 0.9
      })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow then
        if self.twoHanded then
          if self.weapon1 and (not root.itemHasTag(self.heldItem, "ranged") or self.heldItem == "erchiuseye") then weaponsDisabled = true end
        else
          if self.weapon1 then
            if not root.itemHasTag(self.heldItem, "ranged") or self.weapon2 then
              weaponsDisabled = true
            end
          elseif self.weapon2 then
            if not root.itemHasTag(self.heldItem2, "ranged") then
              weaponsDisabled = true
            end
          end
        end
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
    if holdingWeaponsCheck(self.heldItem, self.heldItem2, true) then
      if self.weapon1 and self.weapon2 then
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
          {stat = "maxHealth", effectiveMultiplier = 0.8},
          {stat = "foodDelta", amount = -0.002}
        })

      --Weapon Checks
      if not self.isBrokenBroadsword and not self.isBow then
        if self.twoHanded and self.weapon1 then
          weaponsDisabled = true
        elseif (self.heldItem and root.itemHasTag(self.heldItem, "wand")) or (self.heldItem2 and root.itemHasTag(self.heldItem2, "wand")) then
          weaponsDisabled = true
        end
      end
    end
  elseif classType == 6 then
    --Explorer
    status.setPersistentEffects("ivrpgclassboosts",
    {
      {stat = "physicalResistance", amount = .1}
    })
    if (self.heldItem and root.itemHasTag(self.heldItem, "explorer")) or (self.heldItem2 and root.itemHasTag(self.heldItem2, "explorer")) then
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
          {stat = "powerMultiplier", effectiveMultiplier = 0.85}
        })
    end
  end

  if weaponsDisabled then
    status.setPersistentEffects("ivrpghardcoreweaponsdisabled", {
      {stat = "powerMultiplier", effectiveMultiplier = 0}
    })
  else
    status.clearPersistentEffects("ivrpghardcoreweaponsdisabled")
  end

end

function holdingWeaponsCheck(heldItem, heldItem2, dualWield)
  if heldItem then
    if heldItem2 then
      if dualWield then
        --Returning True only when two items are equipped and Dual-Wield is specified.
        return true
      else
        if root.itemHasTag(heldItem2, "weapon") then
          --Second Item is a weapon, and Dual-Wield is not specified, so we return False.
          return false
        else
        	--Second item is not a weapon, so we return True.
          return true
        end
      end
    else
      if dualWield then
        --Returning False because Dual-Wield is specified, but there is only one item equipped.
        return false
      else
        --Returning True because Dual-Wield is not specified, and only one item is equipped.
        return true
      end
    end
  else
    --Returning False because no items are equipped.
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

function updateChallenges()
  self.dnotifications, self.challengeDamageGivenUpdate = status.inflictedDamageSince(self.challengeDamageGivenUpdate)
  if self.dnotifications then
    --sb.logInfo("Damage Taken!!!")
    for _,notification in pairs(self.dnotifications) do
      --Challenges
      local challenge1 = status.stat("ivrpgchallenge1")
      local challenge2 = status.stat("ivrpgchallenge2")
      local challenge3 = status.stat("ivrpgchallenge3")

      if challenge1 then
        if challenge1 == 1 then
          if updateProgress(notification, "kill", 4) then
            status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
          end
        elseif challenge1 == 2 then
          if updateProgress(notification, "kill", 5) then
            status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
          end
        elseif challenge1 == 3 then
          if updateProgress(notification, "boss", 1, "kluexboss") then
            status.addPersistentEffect("ivrpgchallenge1progress", {stat = "ivrpgchallenge1progress", amount = 1})
          end
        end
      end

      if challenge2 then
        if challenge2 == 1 then
          if updateProgress(notification, "kill", 6) then
            status.addPersistentEffect("ivrpgchallenge2progress", {stat = "ivrpgchallenge2progress", amount = 1})
          end
        elseif challenge2 == 2 then
          if updateProgress(notification, "boss", 1, "dragonboss") then
            status.addPersistentEffect("ivrpgchallenge2progress", {stat = "ivrpgchallenge2progress", amount = 1})
          end
        end
      end

      if challenge3 then
        if challenge3 == 1 then
          if updateProgress(notification, "kill", 8) then
            status.addPersistentEffect("ivrpgchallenge3progress", {stat = "ivrpgchallenge3progress", amount = 1})
          end
        elseif challenge3 == 2 then
          if updateProgress(notification, "boss", 1, "vault") then
            status.addPersistentEffect("ivrpgchallenge3progress", {stat = "ivrpgchallenge3progress", amount = 1})
          end
        elseif challenge3 == 3 then
          if updateProgress(notification, "boss", 1, "eyeboss") then
            status.addPersistentEffect("ivrpgchallenge3progress", {stat = "ivrpgchallenge3progress", amount = 1})
          end
        end
      end

    end
  end
end

function updateProgress(notification, challengeKind, threatTarget, bossKind)
  local targetEntityId = notification.targetEntityId
  local entityAggressive = world.entityAggressive(targetEntityId)
  local isTarget = world.isMonster(targetEntityId) or world.isNpc(targetEntityId)
  local canDamage = world.entityCanDamage(targetEntityId, self.id)
  local monsterName = world.monsterType(targetEntityId)
  local health = world.entityHealth(notification.targetEntityId)
  local threat = world.threatLevel()
  local bosses = {"crystalboss", "apeboss", "cultistboss", "dragonboss", "eyeboss", "kluexboss", "penguinUfo", "spiderboss", "robotboss", "electricguardianboss", "fireguardianboss", "iceguardianboss", "poisonguardianboss"}
  local vaultGuardians = {"electricguardianboss", "fireguardianboss", "iceguardianboss", "poisonguardianboss"}

  if challengeKind == "kill" then
    if isTarget and (entityAggressive or canDamage) and (not health or notification.healthLost >= health[1] and notification.healthLost ~= 0) and threat >= threatTarget then
      return true 
    end
  elseif challengeKind == "bosses" then
    if (not health or notification.healthLost >= health[1] and notification.healthLost ~= 0) and threat >= threatTarget then
      for _,boss in pairs(bosses) do
        if boss == monsterName then
          return true
        end
      end 
    end
  elseif challengeKind == "boss" then
    if (not health or notification.healthLost >= health[1] and notification.healthLost ~= 0) and threat >= threatTarget then
      if bossKind == "vault" then
        for _,boss in pairs(vaultGuardians) do
          if boss == monsterName then
            return true
          end
        end
      else
        if bossKind == monsterName then
          return true
        end
      end
    end
  elseif challengeKind == "gather" then
    return false
  end

  return false
end

function updateXPPulse()
	if not self.xp then
		self.xp = world.entityCurrency(self.id, "experienceorb")
	else
		local new = world.entityCurrency(self.id, "experienceorb") - self.xp
		if new > 0 then
			if status.statPositive("ivrpgmultiplayerxp") then
				status.clearPersistentEffects("ivrpgmultiplayerxp")
			else
				world.spawnProjectile("multiplayerxppulse", mcontroller.position(), self.id, {0,0}, true, {power = 0, knockback = 0, timeToLive = 0.1, statusEffects = {{effect = "multiplayerxppulse", duration = new}}})
			end
		end
	end
end